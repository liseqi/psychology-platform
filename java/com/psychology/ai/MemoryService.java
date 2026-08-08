package com.psychology.ai;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.*;
import java.util.stream.Collectors;

/**
 * AI长期记忆服务 - 实现跨会话的多轮记忆持久化
 * 
 * 核心能力：
 * 1. **记忆提取**：自动从对话中提取关键信息（偏好、关注点、目标等）
 * 2. **记忆存储**：将结构化的长期记忆持久化到数据库
 * 3. **记忆检索**：在新对话开始时恢复用户的长期画像和上下文
 * 4. **记忆演化**：随着时间推移更新和优化记忆（置信度衰减、重要性提升）
 *
 * 记忆类型说明：
 * - PREFERENCE: 用户偏好（如喜欢什么样的回复风格、话题偏好）
 * - CONCERN: 长期关注的问题（如反复提到的焦虑源、压力点）
 * - GOAL: 用户目标（如想要改善的方向、期望达成的目标）
 * - TRIGGER: 触发因素（如什么情况会让情绪恶化、诱因）
 * - ACHIEVEMENT: 积极进展（如用户报告的好转迹象、突破）
 * - COPING_STRATEGY: 应对策略（如有效的减压方法、用户发现的有效技巧）
 *
 * 技术特点：
 * - 使用AI智能提取记忆（而非简单的关键词匹配）
 * - 支持记忆去重和合并（同一类记忆只保留最优版本）
 * - 置信度和重要性双维度评分
 * - 支持记忆过期机制（避免过时信息干扰）
 */
public class MemoryService {
    private static final Logger logger = LoggerFactory.getLogger(MemoryService.class);
    
    private static MemoryService instance;
    private final Gson gson = new Gson();
    private final AIService aiService;
    private final Properties config;
    
    // 记忆配置参数
    private boolean memoryEnabled;           // 是否启用记忆功能
    private int maxMemoryPerUser;            // 每个用户最大记忆数量
    private boolean autoExtractMemory;       // 是否自动从对话中提取记忆
    private double confidenceThreshold;      // 记忆提取置信度阈值
    private int expirationDays;              // 默认过期天数(0=永不过期)
    
    public synchronized static MemoryService getInstance() {
        if (instance == null) {
            instance = new MemoryService();
        }
        return instance;
    }
    
    private MemoryService() {
        this.aiService = AIService.getInstance();
        this.config = loadConfig();
        loadMemoryConfig();
        
        logger.info("MemoryService初始化完成 - 启用:{}, 自动提取:{}, 最大数量:{}", 
            memoryEnabled, autoExtractMemory, maxMemoryPerUser);
    }
    
    private Properties loadConfig() {
        Properties props = new Properties();
        try {
            props.load(getClass().getClassLoader().getResourceAsStream("ai.properties"));
        } catch (Exception e) {
            logger.warn("加载ai.properties失败", e);
        }
        return props;
    }
    
    private void loadMemoryConfig() {
        this.memoryEnabled = Boolean.parseBoolean(config.getProperty("memory.enabled", "true"));
        this.maxMemoryPerUser = Integer.parseInt(config.getProperty("memory.max_per_user", "100"));
        this.autoExtractMemory = Boolean.parseBoolean(config.getProperty("memory.auto_extract", "true"));
        this.confidenceThreshold = Double.parseDouble(config.getProperty("memory.confidence_threshold", "0.70"));
        this.expirationDays = Integer.parseInt(config.getProperty("memory.expiration_days", "180"));
    }
    
    // =====================================================
    // 核心方法：记忆提取与存储
    // =====================================================
    
    /**
     * 从当前对话中自动提取并存储长期记忆
     * 在每次对话结束后由ChatServlet调用
     * 
     * @param userId 用户ID
     * @param sessionId 当前会话ID
     * @param conversationMessages 对话消息列表（按时间顺序）
     * @return 提取到的记忆数量
     */
    public int extractAndStoreMemories(int userId, long sessionId, 
                                        List<com.psychology.entity.ChatMessage> conversationMessages) {
        if (!memoryEnabled || !autoExtractMemory) {
            return 0;
        }
        
        if (conversationMessages == null || conversationMessages.isEmpty()) {
            return 0;
        }
        
        try {
            // 1. 构建对话文本（用于AI分析）
            String conversationText = buildConversationText(conversationMessages);
            
            // 2. 调用AI提取记忆
            List<MemoryItem> extractedMemories = callAIToExtractMemories(userId, conversationText, conversationMessages);
            
            if (extractedMemories == null || extractedMemories.isEmpty()) {
                logger.debug("未从对话中提取到有效记忆 - 用户:{}, 会话:{}", userId, sessionId);
                return 0;
            }
            
            // 3. 存储或更新记忆（去重+合并）
            int storedCount = 0;
            for (MemoryItem memory : extractedMemories) {
                if (storeOrUpdateMemory(userId, sessionId, memory)) {
                    storedCount++;
                }
            }
            
            // 4. 清理过期记忆
            cleanupExpiredMemories(userId);
            
            // 5. 检查总数量限制
            enforceMemoryLimit(userId);
            
            logger.info("记忆提取完成 - 用户:{}, 提取:{}, 存储:{}", userId, extractedMemories.size(), storedCount);
            
            return storedCount;
            
        } catch (Exception e) {
            logger.error("记忆提取失败 - 用户:{}: {}", userId, e.getMessage(), e);
            return 0;
        }
    }
    
    /**
     * 调用AI从对话中提取结构化记忆
     */
    private List<MemoryItem> callAIToExtractMemories(int userId, String conversationText,
                                                       List<com.psychology.entity.ChatMessage> messages) {
        try {
            // 构建提示词
            String systemPrompt = buildMemoryExtractionPrompt();
            
            // 准备消息
            List<Map<String, String>> aiMessages = new ArrayList<>();
            Map<String, String> userMsg = new HashMap<>();
            userMsg.put("role", "user");
            userMsg.put("content", "请从以下对话中提取关于用户的重要长期记忆信息：\n\n" + conversationText);
            aiMessages.add(userMsg);
            
            // 调用AI（使用较低温度确保输出稳定）
            String aiResponse = aiService.chatCompletion(systemPrompt, aiMessages, 0.3);
            
            // 解析AI返回的JSON格式的记忆列表
            return parseMemoriesFromAIResponse(aiResponse, messages);
            
        } catch (AIService.AIException e) {
            logger.error("AI记忆提取调用失败: {}", e.getMessage());
            return new ArrayList<>();
        }
    }
    
    /**
     * 构建记忆提取的系统提示词
     */
    private String buildMemoryExtractionPrompt() {
        StringBuilder prompt = new StringBuilder();
        prompt.append("你是一个专业的记忆提取助手。你的任务是从心理咨询对话中提取用户的关键长期记忆。\n\n");
        prompt.append("你需要提取的记忆类型包括：\n");
        prompt.append("1. PREFERENCE（用户偏好）- 用户喜欢的交流方式、话题偏好、称呼习惯等\n");
        prompt.append("2. CONCERN（长期关注）- 反复提到的困扰、担忧、压力源\n");
        prompt.append("3. GOAL（用户目标）- 想要达成的改变、期望的状态\n");
        prompt.append("4. TRIGGER（触发因素）- 导致情绪变化的诱因、敏感话题\n");
        prompt.append("5. ACHIEVEMENT（积极进展）- 报告的好转、突破性进展\n");
        prompt.append("6. COPING_STRATEGY（应对策略）- 发现的有效减压或调节方法\n\n");
        prompt.append("请以JSON数组格式返回提取到的记忆，每个记忆包含：\n");
        prompt.append("- type: 记忆类型（必须为上述之一）\n");
        prompt.append("- key: 简短的记忆关键词（用于去重，如\"学业焦虑\"）\n");
        prompt.append("- content: 详细的记忆内容描述（100字以内）\n");
        prompt.append("- confidence: 置信度（0-1，基于明确程度打分）\n");
        prompt.append("- importance: 重要程度（0-1，对该用户的影响程度）\n\n");
        prompt.append("重要规则：\n");
        prompt.append("- 只提取明确表达的信息，不要猜测或假设\n");
        prompt.append("- 如果没有明确的可提取信息，返回空数组[]\n");
        prompt.append("- 避免记录临时性的情绪波动，聚焦长期模式\n");
        prompt.append("- 返回格式必须是合法JSON数组\n");
        prompt.append("- confidence低于").append(confidenceThreshold).append("的记忆不要返回\n\n");
        prompt.append("示例输出：\n");
        prompt.append("[{\"type\":\"CONCERN\",\"key\":\"学业压力\",\"content\":\"用户反复提到期末考试压力大，特别是数学和英语\",\"confidence\":0.9,\"importance\":0.85}]");
        
        return prompt.toString();
    }
    
    /**
     * 解析AI返回的记忆JSON
     */
    private List<MemoryItem> parseMemoriesFromAIResponse(String aiResponse, 
                                                          List<com.psychology.entity.ChatMessage> originalMessages) {
        List<MemoryItem> memories = new ArrayList<>();
        
        try {
            // 尝试从响应中提取JSON数组（处理可能的markdown包裹）
            String jsonStr = aiResponse.trim();
            if (jsonStr.startsWith("```")) {
                jsonStr = jsonStr.replaceAll("```json\\s*", "").replaceAll("```\\s*$", "");
            }
            
            JsonArray jsonArray = gson.fromJson(jsonStr, JsonArray.class);
            
            for (int i = 0; i < jsonArray.size(); i++) {
                JsonObject obj = jsonArray.get(i).getAsJsonObject();
                
                MemoryItem item = new MemoryItem();
                item.setType(obj.has("type") ? obj.get("type").getAsString() : "UNKNOWN");
                item.setKey(obj.has("key") ? obj.get("key").getAsString() : "memory_" + System.currentTimeMillis());
                item.setContent(obj.has("content") ? obj.get("content").getAsString() : "");
                item.setConfidence(obj.has("confidence") ? obj.get("confidence").getAsDouble() : 0.7);
                item.setImportance(obj.has("importance") ? obj.get("importance").getAsDouble() : 0.5);
                
                // 验证必要字段
                if (item.getType() != null && item.getContent() != null && !item.getContent().isEmpty()) {
                    memories.add(item);
                }
            }
            
        } catch (Exception e) {
            logger.warn("解析AI记忆响应失败: {} (原始响应前200字: {})", 
                e.getMessage(), aiResponse != null ? aiResponse.substring(0, Math.min(200, aiResponse.length())) : "null");
        }
        
        return memories;
    }
    
    // =====================================================
    // 核心方法：记忆检索与上下文恢复
    // =====================================================
    
    /**
     * 获取用户的完整长期记忆上下文（用于注入系统提示词）
     * 在新会话开始或每轮对话时调用
     * 
     * @param userId 用户ID
     * @return 格式化的记忆上下文文本
     */
    public String getUserMemoryContext(int userId) {
        if (!memoryEnabled) {
            return "";
        }
        
        try {
            List<MemoryRecord> memories = loadActiveMemories(userId);
            
            if (memories == null || memories.isEmpty()) {
                logger.debug("用户{}暂无活跃记忆", userId);
                return "";
            }
            
            // 按类型分组并格式化
            return formatMemoriesForContext(memories);
            
        } catch (Exception e) {
            logger.error("获取用户记忆上下文失败: {}", e.getMessage(), e);
            return "";
        }
    }
    
    /**
     * 加载用户所有活跃的记忆记录
     */
    private List<MemoryRecord> loadActiveMemories(int userId) {
        List<MemoryRecord> memories = new ArrayList<>();
        
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT id, memory_type, memory_key, memory_content, confidence, importance_score, " +
                "reference_count, last_referenced_at, created_at " +
                "FROM ai_longterm_memory " +
                "WHERE user_id = ? AND is_active = 1 " +
                "AND (expires_at IS NULL OR expires_at > NOW()) " +
                "ORDER BY importance_score DESC, last_referenced_at DESC NULLS LAST, created_at DESC " +
                "LIMIT ?");
            
            pstmt.setInt(1, userId);
            pstmt.setInt(2, maxMemoryPerUser);
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                MemoryRecord record = new MemoryRecord();
                record.setId(rs.getLong("id"));
                record.setMemoryType(rs.getString("memory_type"));
                record.setMemoryKey(rs.getString("memory_key"));
                record.setMemoryContent(rs.getString("memory_content"));
                record.setConfidence(rs.getDouble("confidence"));
                record.setImportanceScore(rs.getDouble("importance_score"));
                record.setReferenceCount(rs.getInt("reference_count"));
                record.setLastReferencedAt(rs.getTimestamp("last_referenced_at"));
                record.setCreatedAt(rs.getTimestamp("created_at"));
                memories.add(record);
            }
            
            rs.close();
            pstmt.close();
            
        } catch (Exception e) {
            logger.error("加载用户记忆失败: {}", e.getMessage(), e);
        } finally {
            closeConnection(conn);
        }
        
        return memories;
    }
    
    /**
     * 将记忆记录格式化为可注入Prompt的文本
     */
    private String formatMemoriesForContext(List<MemoryRecord> memories) {
        // 按类型分组
        Map<String, List<MemoryRecord>> grouped = memories.stream()
            .collect(Collectors.groupingBy(MemoryRecord::getMemoryType));
        
        StringBuilder context = new StringBuilder();
        context.append("\n【该用户的长期档案（来自历史对话的积累，请据此提供个性化回应）】\n");
        
        // 定义类型的中文标签
        Map<String, String> typeLabels = new HashMap<>();
        typeLabels.put("PREFERENCE", "📌 偏好习惯");
        typeLabels.put("CONCERN", "⚠️ 长期困扰");
        typeLabels.put("GOAL", "🎯 目标期待");
        typeLabels.put("TRIGGER", "💥 触发因素");
        typeLabels.put("ACHIEVEMENT", "✅ 积极进展");
        typeLabels.put("COPING_STRATEGY", "💡 有效策略");
        
        for (Map.Entry<String, List<MemoryRecord>> entry : grouped.entrySet()) {
            String typeLabel = typeLabels.getOrDefault(entry.getKey(), entry.getKey());
            context.append(typeLabel).append(":\n");
            
            for (MemoryRecord record : entry.getValue()) {
                context.append(String.format("  - %s (置信度:%.0f%%)\n", 
                    record.getMemoryContent(), record.getConfidence() * 100));
            }
        }
        
        // 更新引用次数
        updateReferenceCounts(memories);
        
        return context.toString();
    }
    
    /**
     * 更新记忆的引用次数和最后引用时间
     */
    private void updateReferenceCounts(List<MemoryRecord> memories) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            PreparedStatement pstmt = conn.prepareStatement(
                "UPDATE ai_longterm_memory SET reference_count = reference_count + 1, " +
                "last_referenced_at = NOW() WHERE id = ?");
            
            for (MemoryRecord record : memories) {
                pstmt.setLong(1, record.getId());
                pstmt.addBatch();
            }
            
            pstmt.executeBatch();
            pstmt.close();
            
        } catch (Exception ignored) {
        } finally {
            closeConnection(conn);
        }
    }
    
    // =====================================================
    // 记忆CRUD操作
    // =====================================================
    
    /**
     * 存储或更新一条记忆（如果已存在相同key则合并）
     */
    private boolean storeOrUpdateMemory(int userId, long sessionId, MemoryItem memory) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            // 检查是否已存在相同的记忆key
            PreparedStatement checkStmt = conn.prepareStatement(
                "SELECT id, content, confidence, importance_score FROM ai_longterm_memory " +
                "WHERE user_id = ? AND memory_key = ? AND is_active = 1 FOR UPDATE");
            
            checkStmt.setInt(1, userId);
            checkStmt.setString(2, memory.getKey());
            ResultSet rs = checkStmt.executeQuery();
            
            if (rs.next()) {
                // 已存在，采用置信度更高的版本（或合并内容）
                long existingId = rs.getLong("id");
                double existingConf = rs.getDouble("confidence");
                
                if (memory.getConfidence() > existingConf) {
                    // 新版本更可信，更新
                    PreparedStatement updateStmt = conn.prepareStatement(
                        "UPDATE ai_longterm_memory SET memory_content = ?, confidence = ?, " +
                        "importance_score = ?, source_session_ids = JSON_ARRAY_APPEND(IFNULL(source_session_ids,'[]'), ?), " +
                        "updated_at = NOW() WHERE id = ?");
                    
                    updateStmt.setString(1, memory.getContent());
                    updateStmt.setDouble(2, memory.getConfidence());
                    updateStmt.setDouble(3, memory.getImportance());
                    updateStmt.setLong(4, sessionId);
                    updateStmt.setLong(5, existingId);
                    
                    updateStmt.executeUpdate();
                    updateStmt.close();
                }
                
                rs.close();
                checkStmt.close();
                return true;
            }
            
            rs.close();
            checkStmt.close();
            
            // 不存在，插入新记忆
            PreparedStatement insertStmt = conn.prepareStatement(
                "INSERT INTO ai_longterm_memory (user_id, memory_type, memory_key, memory_content, " +
                "confidence, importance_score, source_session_ids, is_active, expires_at) " +
                "VALUES (?, ?, ?, ?, ?, ?, JSON_ARRAY(?), 1, DATE_ADD(NOW(), INTERVAL ? DAY))",
                Statement.RETURN_GENERATED_KEYS);
            
            insertStmt.setInt(1, userId);
            insertStmt.setString(2, memory.getType());
            insertStmt.setString(3, memory.getKey());
            insertStmt.setString(4, memory.getContent());
            insertStmt.setDouble(5, memory.getConfidence());
            insertStmt.setDouble(6, memory.getImportance());
            insertStmt.setLong(7, sessionId);
            
            // 设置过期时间（0表示永不过期）
            if (expirationDays > 0) {
                insertStmt.setInt(8, expirationDays);
            } else {
                insertStmt.setNull(8, Types.TIMESTAMP);
            }
            
            insertStmt.executeUpdate();
            insertStmt.close();
            
            return true;
            
        } catch (Exception e) {
            logger.error("存储记忆失败: {}", e.getMessage(), e);
            return false;
        } finally {
            closeConnection(conn);
        }
    }
    
    /**
     * 手动添加一条用户记忆（管理员或用户主动设置）
     */
    public boolean addMemoryManually(int userId, String type, String key, String content) {
        MemoryItem item = new MemoryItem();
        item.setType(type);
        item.setKey(key);
        item.setContent(content);
        item.setConfidence(0.95);  // 手动添加的高置信度
        item.setImportance(0.80);
        
        return storeOrUpdateMemory(userId, 0L, item);  // sessionId=0表示非会话产生
    }
    
    /**
     * 删除/禁用某条记忆
     */
    public boolean deactivateMemory(long memoryId) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            PreparedStatement pstmt = conn.prepareStatement(
                "UPDATE ai_longterm_memory SET is_active = 0, updated_at = NOW() WHERE id = ?");
            pstmt.setLong(1, memoryId);
            int rows = pstmt.executeUpdate();
            pstmt.close();
            
            return rows > 0;
        } catch (Exception e) {
            logger.error("禁用记忆失败: {}", e.getMessage());
            return false;
        } finally {
            closeConnection(conn);
        }
    }
    
    // =====================================================
    // 维护操作
    // =====================================================
    
    /**
     * 清理过期记忆
     */
    private void cleanupExpiredMemories(int userId) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            PreparedStatement pstmt = conn.prepareStatement(
                "UPDATE ai_longterm_memory SET is_active = 0, updated_at = NOW() " +
                "WHERE user_id = ? AND is_active = 1 AND expires_at IS NOT NULL AND expires_at <= NOW()");
            pstmt.setInt(1, userId);
            int rows = pstmt.executeUpdate();
            pstmt.close();
            
            if (rows > 0) {
                logger.debug("清理了{}条过期记忆 - 用户:{}", rows, userId);
            }
        } catch (Exception ignored) {
        } finally {
            closeConnection(conn);
        }
    }
    
    /**
     * 强制执行记忆数量上限（保留最重要的）
     */
    private void enforceMemoryLimit(int userId) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            // 查询当前活跃记忆数量
            PreparedStatement countStmt = conn.prepareStatement(
                "SELECT COUNT(*) as cnt FROM ai_longterm_memory WHERE user_id = ? AND is_active = 1");
            countStmt.setInt(1, userId);
            ResultSet rs = countStmt.executeQuery();
            rs.next();
            int count = rs.getInt("cnt");
            rs.close();
            countStmt.close();
            
            if (count > maxMemoryPerUser) {
                // 删除超出部分的最低优先级记忆
                int toDelete = count - maxMemoryPerUser;
                PreparedStatement deleteStmt = conn.prepareStatement(
                    "UPDATE ai_longterm_memory SET is_active = 0, updated_at = NOW() " +
                    "WHERE user_id = ? AND is_active = 1 AND id IN (" +
                    "SELECT id FROM ai_longterm_memory WHERE user_id = ? AND is_active = 1 " +
                    "ORDER BY importance_score ASC, last_referenced_at ASC NULLS FIRST LIMIT ?)");
                
                deleteStmt.setInt(1, userId);
                deleteStmt.setInt(2, userId);
                deleteStmt.setInt(3, toDelete);
                deleteStmt.executeUpdate();
                deleteStmt.close();
                
                logger.debug("强制删除了{}条低优先级记忆 - 用户:{}", toDelete, userId);
            }
            
        } catch (Exception ignored) {
        } finally {
            closeConnection(conn);
        }
    }
    
    // =====================================================
    // 统计与管理接口
    // =====================================================
    
    /**
     * 获取用户的记忆统计信息
     */
    public Map<String, Object> getUserMemoryStats(int userId) {
        Map<String, Object> stats = new HashMap<>();
        
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            // 总记忆数
            PreparedStatement countAll = conn.prepareStatement(
                "SELECT COUNT(*) as cnt FROM ai_longterm_memory WHERE user_id = ?");
            countAll.setInt(1, userId);
            ResultSet rs = countAll.executeQuery();
            if (rs.next()) stats.put("totalMemories", rs.getInt("cnt"));
            rs.close();
            countAll.close();
            
            // 活跃记忆数
            PreparedStatement countActive = conn.prepareStatement(
                "SELECT COUNT(*) as cnt FROM ai_longterm_memory WHERE user_id = ? AND is_active = 1");
            countActive.setInt(1, userId);
            rs = countActive.executeQuery();
            if (rs.next()) stats.put("activeMemories", rs.getInt("cnt"));
            rs.close();
            countActive.close();
            
            // 各类型分布
            PreparedStatement typeDist = conn.prepareStatement(
                "SELECT memory_type, COUNT(*) as cnt FROM ai_longterm_memory " +
                "WHERE user_id = ? AND is_active = 1 GROUP BY memory_type ORDER BY cnt DESC");
            typeDist.setInt(1, userId);
            rs = typeDist.executeQuery();
            Map<String, Integer> distribution = new LinkedHashMap<>();
            while (rs.next()) {
                distribution.put(rs.getString("memory_type"), rs.getInt("cnt"));
            }
            stats.put("typeDistribution", distribution);
            rs.close();
            typeDist.close();
            
        } catch (Exception e) {
            logger.error("获取记忆统计失败: {}", e.getMessage());
        } finally {
            closeConnection(conn);
        }
        
        stats.put("memoryEnabled", memoryEnabled);
        stats.put("maxPerUser", maxMemoryPerUser);
        return stats;
    }
    
    /**
     * 获取用户的所有记忆详情（分页）
     */
    public List<MemoryRecord> getUserMemories(int userId, int page, int pageSize) {
        List<MemoryRecord> records = new ArrayList<>();
        
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT id, memory_type, memory_key, memory_content, confidence, importance_score, " +
                "reference_count, last_referenced_at, is_active, created_at, updated_at " +
                "FROM ai_longterm_memory WHERE user_id = ? " +
                "ORDER BY importance_score DESC, created_at DESC LIMIT ? OFFSET ?");
            
            pstmt.setInt(1, userId);
            pstmt.setInt(2, pageSize);
            pstmt.setInt(3, (page - 1) * pageSize);
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                MemoryRecord record = new MemoryRecord();
                record.setId(rs.getLong("id"));
                record.setMemoryType(rs.getString("memory_type"));
                record.setMemoryKey(rs.getString("memory_key"));
                record.setMemoryContent(rs.getString("memory_content"));
                record.setConfidence(rs.getDouble("confidence"));
                record.setImportanceScore(rs.getDouble("importance_score"));
                record.setReferenceCount(rs.getInt("reference_count"));
                record.setLastReferencedAt(rs.getTimestamp("last_referenced_at"));
                record.setIsActive(rs.getBoolean("is_active"));
                record.setCreatedAt(rs.getTimestamp("created_at"));
                record.setUpdatedAt(rs.getTimestamp("updated_at"));
                records.add(record);
            }
            
            rs.close();
            pstmt.close();
            
        } catch (Exception e) {
            logger.error("获取用户记忆列表失败: {}", e.getMessage(), e);
        } finally {
            closeConnection(conn);
        }
        
        return records;
    }

    // =====================================================
    // 私有工具方法
    // =====================================================

    /**
     * 构建对话文本（用于AI分析）
     */
    private String buildConversationText(List<com.psychology.entity.ChatMessage> messages) {
        StringBuilder sb = new StringBuilder();
        sb.append("=== 对话记录 ===\n");
        
        for (com.psychology.entity.ChatMessage msg : messages) {
            String role = "USER".equals(msg.getSenderType()) ? "用户" : "AI助手";
            sb.append(role).append(": ").append(msg.getContent()).append("\n\n");
        }
        
        sb.append("=== 结束 ===");
        return sb.toString();
    }
    
    /**
     * 获取数据库连接
     */
    private Connection getDatabaseConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            String url = "jdbc:mysql://localhost:3306/psychology?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai";
            return DriverManager.getConnection(url, "root", "123456");
        } catch (ClassNotFoundException e) {
            throw new SQLException("数据库驱动未找到", e);
        }
    }
    
    /**
     * 关闭连接
     */
    private void closeConnection(Connection conn) {
        if (conn != null) {
            try { conn.close(); } catch (Exception ignored) {}
        }
    }

    // =====================================================
    // 内部数据结构
    // =====================================================

    /**
     * 从AI提取的记忆项（临时对象）
     */
    public static class MemoryItem {
        private String type;          // 记忆类型
        private String key;           // 关键词（去重用）
        private String content;       // 内容描述
        private double confidence;    // 置信度
        private double importance;    // 重要程度
        
        public String getType() { return type; }
        public void setType(String type) { this.type = type; }
        public String getKey() { return key; }
        public void setKey(String key) { this.key = key; }
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        public double getConfidence() { return confidence; }
        public void setConfidence(double confidence) { this.confidence = confidence; }
        public double getImportance() { return importance; }
        public void setImportance(double importance) { this.importance = importance; }
    }
    
    /**
     * 数据库中的记忆记录（持久化对象）
     */
    public static class MemoryRecord {
        private Long id;
        private String memoryType;
        private String memoryKey;
        private String memoryContent;
        private double confidence;
        private double importanceScore;
        private int referenceCount;
        private Timestamp lastReferencedAt;
        private Timestamp createdAt;
        private Timestamp updatedAt;
        private boolean isActive;
        
        // Getters and Setters
        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getMemoryType() { return memoryType; }
        public void setMemoryType(String memoryType) { this.memoryType = memoryType; }
        public String getMemoryKey() { return memoryKey; }
        public void setMemoryKey(String memoryKey) { this.memoryKey = memoryKey; }
        public String getMemoryContent() { return memoryContent; }
        public void setMemoryContent(String memoryContent) { this.memoryContent = memoryContent; }
        public double getConfidence() { return confidence; }
        public void setConfidence(double confidence) { this.confidence = confidence; }
        public double getImportanceScore() { return importanceScore; }
        public void setImportanceScore(double importanceScore) { this.importanceScore = importanceScore; }
        public int getReferenceCount() { return referenceCount; }
        public void setReferenceCount(int referenceCount) { this.referenceCount = referenceCount; }
        public Timestamp getLastReferencedAt() { return lastReferencedAt; }
        public void setLastReferencedAt(Timestamp lastReferencedAt) { this.lastReferencedAt = lastReferencedAt; }
        public Timestamp getCreatedAt() { return createdAt; }
        public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
        public Timestamp getUpdatedAt() { return updatedAt; }
        public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }
        public boolean isActive() { return isActive; }
        public void setIsActive(boolean isActive) { this.isActive = isActive; }
    }
}
