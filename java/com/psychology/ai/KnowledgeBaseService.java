package com.psychology.ai;

import com.psychology.dao.ArticleDao;
import com.psychology.entity.Article;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.ResultSet;
import java.util.*;
import java.util.stream.Collectors;

/**
 * RAG (Retrieval-Augmented Generation) 知识库服务
 * 
 * 核心功能：
 * 1. **知识库构建**：将科普文章向量化并存储到向量数据库
 * 2. **语义检索**：根据用户问题从知识库中找到最相关的文章片段
 * 3. **上下文注入**：将检索结果格式化为可理解的Prompt补充内容
 * 
 * 工作流程：
 * 用户提问 → 向量化查询 → 相似度搜索 → 取Top-K结果 → 格式化为参考文本 → 注入系统提示词
 *
 * 业务价值：
 * - 让AI回答基于权威的心理学科普文章，而非"幻觉"
 * - 支持回答具体的心理学术语解释、症状识别、应对策略等专业知识问题
 * - 提高AI回复的可信度和专业度
 */
public class KnowledgeBaseService {
    private static final Logger logger = LoggerFactory.getLogger(KnowledgeBaseService.class);
    
    private static KnowledgeBaseService instance;
    private final VectorStoreService vectorStore;
    private final Properties config;
    
    // RAG配置参数
    private boolean ragEnabled;          // 是否启用RAG
    private int ragTopK;                 // 返回最相关的K个结果
    private double similarityThreshold;   // 相似度阈值
    private int maxContextLength;         // 注入Prompt的最大字符数
    
    public synchronized static KnowledgeBaseService getInstance() {
        if (instance == null) {
            instance = new KnowledgeBaseService();
        }
        return instance;
    }
    
    private KnowledgeBaseService() {
        this.vectorStore = VectorStoreService.getInstance();
        this.config = loadConfig();
        loadRAGConfig();
        
        logger.info("KnowledgeBaseService初始化完成 - RAG:{}, TopK: {}, 阈值: {}", 
            ragEnabled, ragTopK, similarityThreshold);
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
    
    /**
     * 加载RAG相关配置
     */
    private void loadRAGConfig() {
        this.ragEnabled = Boolean.parseBoolean(config.getProperty("rag.enabled", "true"));
        this.ragTopK = Integer.parseInt(config.getProperty("rag.top_k", "3"));
        this.similarityThreshold = Double.parseDouble(config.getProperty("rag.similarity_threshold", "0.6"));
        this.maxContextLength = Integer.parseInt(config.getProperty("rag.max_context_length", "1500"));
    }
    
    // =====================================================
    // 核心方法：RAG检索增强
    // =====================================================
    
    /**
     * 根据用户输入检索相关知识库内容，生成增强的上下文文本
     * 
     * @param userQuery 用户的问题或描述
     * @return 增强的上下文文本（如果未命中返回空字符串）
     */
    public String retrieveRelevantContext(String userQuery) {
        if (!ragEnabled || userQuery == null || userQuery.trim().isEmpty()) {
            return "";
        }
        
        try {
            long startTime = System.currentTimeMillis();
            
            // 1. 从向量库中搜索相关文章
            List<VectorStoreService.RAGResult> results = vectorStore.searchRelevantArticles(
                userQuery, ragTopK, similarityThreshold);
            
            if (results.isEmpty()) {
                logger.debug("RAG未命中 - 查询: '{}...'", 
                    userQuery.substring(0, Math.min(30, userQuery.length())));
                return "";
            }
            
            // 2. 格式化为上下文文本
            String contextText = formatResultsAsContext(results);
            
            long duration = System.currentTimeMillis() - startTime;
            logger.info("RAG检索完成 - 耗时:{}ms, 命中:{}片, 上下文长度:{}字符", 
                duration, results.size(), contextText.length());
            
            return contextText;
            
        } catch (Exception e) {
            logger.error("RAG检索异常: {}", e.getMessage(), e);
            return "";  // RAG失败不影响主流程
        }
    }
    
    /**
     * 将RAG检索结果格式化为可注入Prompt的上下文文本
     */
    private String formatResultsAsContext(List<VectorStoreService.RAGResult> results) {
        StringBuilder contextBuilder = new StringBuilder();
        contextBuilder.append("\n【以下是从心理咨询知识库中检索到的相关参考资料，请结合这些信息进行回答】\n");
        
        int totalLength = 0;
        for (VectorStoreService.RAGResult result : results) {
            String formattedResult = result.toContextText() + "\n";
            
            // 控制总长度不超过maxContextLength
            if (totalLength + formattedResult.length() > maxContextLength) {
                logger.debug("达到最大上下文长度限制({}字符), 截断后续结果", maxContextLength);
                break;
            }
            
            contextBuilder.append(formattedResult);
            totalLength += formattedResult.length();
        }
        
        return contextBuilder.toString();
    }
    
    /**
     * 智能判断是否需要触发RAG检索
     * 
     * 判断依据：
     * - 包含心理学术语/症状关键词
     * - 明确的知识性问题（什么是xxx, xxx是什么）
     * - 寻求具体建议或方法
     * 
     * @param userInput 用户输入文本
     * @return 是否需要RAG增强
     */
    public boolean shouldTriggerRAG(String userInput) {
        if (!ragEnabled || userInput == null) {
            return false;
        }
        
        // 触发关键词列表（心理学术语、常见问题类型等）
        String[] triggerKeywords = {
            "什么是", "什么叫", "如何", "怎样", "怎么",
            "症状", "表现", "原因", "治疗", "方法", "技巧",
            "焦虑症", "抑郁症", "强迫症", "恐惧症", "社交恐惧",
            "失眠", "压力", "创伤", "PTSD", "ADHD", "多动",
            "自我调节", "放松", "冥想", "呼吸", "认知行为",
            "CBT", "心理咨询", "心理治疗"
        };
        
        for (String keyword : triggerKeywords) {
            if (userInput.contains(keyword)) {
                logger.debug("检测到RAG触发关键词: {}", keyword);
                return true;
            }
        }
        
        // 问题长度超过20字且包含问号的也触发
        if (userInput.length() > 20 && userInput.contains("?") || userInput.contains("？")) {
            return true;
        }
        
        return false;
    }
    
    // =====================================================
    // 知识库管理方法
    // =====================================================
    
    /**
     * 构建或重建完整的文章知识库
     * 通常在系统启动或管理员手动触发时调用
     * 
     * @return 构建统计信息
     */
    public Map<String, Object> buildKnowledgeBase() {
        logger.info("========== 开始构建RAG知识库 ==========");
        
        long startTime = System.currentTimeMillis();
        Map<String, Object> stats = vectorStore.indexAllArticles();
        long duration = System.currentTimeMillis() - startTime;
        
        stats.put("durationMs", duration);
        stats.put("status", "COMPLETED");
        stats.put("timestamp", new Date());
        
        logger.info("========== 知识库构建完成 - 耗时{}ms ==========", duration);
        
        return stats;
    }
    
    /**
     * 添加单篇文章到知识库
     */
    public boolean addArticleToKB(Long articleId) {
        ArticleDao articleDao = new ArticleDao();
        Article article = articleDao.findById(articleId);
        
        if (article == null) {
            logger.warn("文章{}不存在，无法添加到知识库", articleId);
            return false;
        }
        
        if (!"PUBLISHED".equals(article.getStatus())) {
            logger.info("文章{}状态为{}，跳过索引", articleId, article.getStatus());
            return true;
        }
        
        return vectorStore.indexArticle(article);
    }
    
    /**
     * 从知识库移除文章
     */
    public boolean removeArticleFromKB(Long articleId) {
        return vectorStore.removeArticle(articleId);
    }
    
    /**
     * 获取知识库统计信息
     */
    public Map<String, Object> getKnowledgeBaseStats() {
        Map<String, Object> stats = new HashMap<>();
        
        try {
            java.sql.Connection conn = getDatabaseConnection();
            java.sql.Statement stmt = conn.createStatement();
            
            // 文章向量数量
            ResultSet rs1 = stmt.executeQuery("SELECT COUNT(*) as cnt FROM article_vector");
            if (rs1.next()) stats.put("totalVectors", rs1.getInt("cnt"));
            rs1.close();
            
            // 涉及的文章数量
            ResultSet rs2 = stmt.executeQuery("SELECT COUNT(DISTINCT article_id) as cnt FROM article_vector");
            if (rs2.next()) stats.put("totalArticles", rs2.getInt("cnt"));
            rs2.close();
            
            // 对话消息向量数量
            ResultSet rs3 = stmt.executeQuery("SELECT COUNT(*) as cnt FROM chat_message_vector");
            if (rs3.next()) stats.put("totalMessageVectors", rs3.getInt("cnt"));
            rs3.close();
            
            stmt.close();
            conn.close();
            
        } catch (Exception e) {
            logger.error("获取知识库统计失败: {}", e.getMessage());
        }
        
        stats.put("ragEnabled", ragEnabled);
        stats.put("topK", ragTopK);
        stats.put("similarityThreshold", similarityThreshold);
        stats.put("embeddingModel", EmbeddingService.getInstance().getProvider() + 
            "/" + EmbeddingService.getInstance().getModel());
        
        return stats;
    }
    
    /**
     * 测试RAG功能是否正常
     */
    public boolean testRAGFunctionality() {
        try {
            String testResult = retrieveRelevantContext("如何缓解考试焦虑");
            return testResult != null && !testResult.isEmpty();
        } catch (Exception e) {
            logger.error("RAG功能测试失败", e);
            return false;
        }
    }

    /**
     * 获取数据库连接
     */
    private java.sql.Connection getDatabaseConnection() throws java.sql.SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            String url = "jdbc:mysql://localhost:3306/psychology?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai";
            return java.sql.DriverManager.getConnection(url, "root", "123456");
        } catch (ClassNotFoundException e) {
            throw new java.sql.SQLException("数据库驱动未找到", e);
        }
    }
    
    // =====================================================
    // 公开工具方法
    // =====================================================
    
    /**
     * 判断RAG是否已启用
     */
    public boolean isRagEnabled() {
        return ragEnabled;
    }
    
    /**
     * 获取文章数量（用于知识库管理）
     */
    public int getArticleCount() {
        ArticleDao articleDao = new ArticleDao();
        List<Article> articles = articleDao.findAllPublished();
        return articles != null ? articles.size() : 0;
    }
    
    /**
     * 获取当前配置的相似度阈值
     */
    public double getSimilarityThreshold() {
        return similarityThreshold;
    }
}
