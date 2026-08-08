package com.psychology.servlet;

import com.psychology.ai.*;
import com.psychology.dao.*;
import com.psychology.entity.*;
import com.psychology.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;

/**
 * AI树洞机器人Servlet - 基于大模型API的智能心理咨询助手
 * 
 * 核心能力（V3.0升级）：
 * ✅ 接入真实AI大模型API（豆包/DeepSeek/OpenAI）
 * ✅ 专业心理咨询Prompt工程引擎
 * ✅ 学生画像数据增强（测评、咨询记录、预约信息）
 * ✅ 流式SSE响应支持（打字机效果）
 * ✅ RAG检索增强生成（查询心理学科普知识库）
 * ✅ 多轮记忆持久化（跨会话记住用户偏好和进展）
 * ✅ 向量化语义搜索历史问题
 * ✅ AI情绪分析替代关键词匹配
 * ✅ 完善的高危预警联动机制
 *
 * @version 3.0 - 2026年RAG/向量/记忆增强
 */
@WebServlet("/chat/*")
public class ChatServlet extends HttpServlet {

    private ChatMessageDao messageDao = new ChatMessageDao();
    private ChatRateLimitDao rateLimitDao = new ChatRateLimitDao();
    private AIService aiService;
    
    // V3.0新增服务
    private KnowledgeBaseService knowledgeBaseService;   // RAG知识库服务
    private MemoryService memoryService;                // 长期记忆服务
    private VectorStoreService vectorStoreService;      // 向量存储服务
    
    // 配置参数
    private static final int DAILY_CHAT_LIMIT = 50;           // 每日对话上限
    private static final int CONTEXT_WINDOW_SIZE = 10;        // 发送给AI的历史消息数
    
    // 危机关键词列表
    private static final String[] CRISIS_KEYWORDS = {
        "自杀", "想死", "不想活", "结束生命", "自残", 
        "割腕", "跳楼", "服药过量", "了结自己"
    };

    @Override
    public void init() throws ServletException {
        super.init();
        
        // 初始化所有AI相关服务单例（带容错处理）
        try {
            this.aiService = AIService.getInstance();
            System.out.println("[ChatServlet] AIService 初始化成功");
        } catch (Exception e) {
            System.err.println("[ChatServlet] AIService 初始化失败: " + e.getMessage());
            e.printStackTrace();
        }
        
        try {
            this.knowledgeBaseService = KnowledgeBaseService.getInstance();
            System.out.println("[ChatServlet] KnowledgeBaseService 初始化成功");
        } catch (Exception e) {
            System.err.println("[ChatServlet] KnowledgeBaseService 初始化失败: " + e.getMessage());
        }
        
        try {
            this.memoryService = MemoryService.getInstance();
            System.out.println("[ChatServlet] MemoryService 初始化成功");
        } catch (Exception e) {
            System.err.println("[ChatServlet] MemoryService 初始化失败: " + e.getMessage());
        }
        
        try {
            this.vectorStoreService = VectorStoreService.getInstance();
            System.out.println("[ChatServlet] VectorStoreService 初始化成功");
        } catch (Exception e) {
            System.err.println("[ChatServlet] VectorStoreService 初始化失败: " + e.getMessage());
        }
        
        System.out.println("✅ ChatServlet V3.0初始化完成");
        if (aiService != null) {
            System.out.println("   - AI Provider: " + aiService.getCurrentProvider());
        } else {
            System.out.println("   - AI Provider: 未初始化（将使用降级模式）");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();

        if ("/sessions".equals(pathInfo)) {
            handleGetSessions(req, resp);
        } else if ("/messages".equals(pathInfo)) {
            handleGetMessages(req, resp);
        } else if ("/limit-info".equals(pathInfo)) {
            handleLimitInfo(req, resp);
        } else if ("/stream".equals(pathInfo)) {
            handleStreamRequest(req, resp);  // SSE流式端点
        } else if ("/semantic-search".equals(pathInfo)) {
            handleSemanticSearch(req, resp);  // V3.0: 语义搜索历史问题
        } else if ("/memory-stats".equals(pathInfo)) {
            handleMemoryStats(req, resp);     // V3.0: 记忆统计
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();

        if ("/send".equals(pathInfo)) {
            handleSendMessage(req, resp);          // 非流式发送（兼容）
        } else if ("/session/create".equals(pathInfo)) {
            handleCreateSession(req, resp);
        }
    }

    /**
     * 核心功能：发送消息 + 获取AI回复（非流式）
     * 完整流程：限流 → 保存消息 → 数据增强 → 调用AI → 情绪分析 → 高危检测 → 返回结果
     */
    private void handleSendMessage(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        
        String sessionIdStr = req.getParameter("sessionId");
        String content = req.getParameter("message");

        // 参数校验
        if (sessionIdStr == null || content == null || content.trim().isEmpty()) {
            JsonUtil.writeParamError(resp, "请输入消息内容");
            return;
        }

        Long sessionId = Long.parseLong(sessionIdStr);

        try {
            // ===== 1. 限流检查 =====
            if (!rateLimitDao.checkAndIncrement(user.getId())) {
                JsonUtil.writeError(resp, "今日对话次数已达上限（" + DAILY_CHAT_LIMIT + "次）。" +
                    "如需帮助请联系心理老师或拨打400-161-9995");
                return;
            }

            // ===== 2. 保存用户消息到数据库 =====
            ChatMessage userMsg = new ChatMessage();
            userMsg.setSessionId(sessionId);
            userMsg.setSenderType("USER");
            userMsg.setContent(content);
            long userMsgId = messageDao.add(userMsg);

            // ===== 3. 构建AI请求（数据增强 + RAG + 记忆） =====
            // 3a. 加载学生上下文
            StudentContextBuilder.StudentContext studentContext = null;
            try {
                StudentContextBuilder contextBuilder = new StudentContextBuilder(user.getId());
                studentContext = contextBuilder.build();
            } catch (Exception e) {
                System.err.println("[WARN] 加载学生上下文失败: " + e.getMessage() + 
                    " (将使用基础模式)");
            }

            // 3b. 【V3.0新增】加载长期记忆（跨会话持久化）
            String longTermMemoryContext = memoryService.getUserMemoryContext(user.getId());

            // 3c. 【V3.0新增】RAG检索 - 从知识库查询相关科普文章
            String ragContext = "";
            if (knowledgeBaseService.shouldTriggerRAG(content)) {
                ragContext = knowledgeBaseService.retrieveRelevantContext(content);
                if (ragContext != null && !ragContext.isEmpty()) {
                    System.out.println("[RAG] 命中知识库，上下文长度: " + ragContext.length() + "字符");
                }
            }

            // 3d. 加载历史对话（用于上下文连续性）
            List<ChatMessage> recentMessages = loadRecentHistory(sessionId, CONTEXT_WINDOW_SIZE);
            
            // 3e. 将当前用户消息加入历史
            List<Map<String, String>> messagesForAI = AIService.toMessageList(recentMessages);
            Map<String, String> currentMsg = new HashMap<>();
            currentMsg.put("role", "user");
            currentMsg.put("content", content);
            messagesForAI.add(currentMsg);

            // 3f. 构建系统提示词（基础Prompt + 数据增强 + 长期记忆 + RAG上下文）
            String baseSystemPrompt = PsychologyPromptEngine.buildSystemPrompt(
                studentContext, buildConversationSummary(recentMessages));
            
            // 注入长期记忆和RAG上下文
            String enhancedSystemPrompt = baseSystemPrompt;
            if (longTermMemoryContext != null && !longTermMemoryContext.isEmpty()) {
                enhancedSystemPrompt += "\n" + longTermMemoryContext;
            }
            if (ragContext != null && !ragContext.isEmpty()) {
                enhancedSystemPrompt += "\n" + ragContext;
            }

            // ===== 4. 调用AI大模型获取回复 =====
            long startTime = System.currentTimeMillis();
            String aiReply = aiService.chatCompletion(enhancedSystemPrompt, messagesForAI, 0.7);
            long responseTime = System.currentTimeMillis() - startTime;
            
            System.out.println(String.format("[AI] 回复耗时: %dms, 长度: %d字符, RAG:%s, Memory:%s", 
                responseTime, aiReply.length(), 
                ragContext.isEmpty() ? "未命中" : "已命中",
                longTermMemoryContext.isEmpty() ? "无" : "已注入"));

            // ===== 5. AI情绪分析（基于回复内容智能判断） =====
            EmotionAnalysisResult analysis = analyzeEmotionWithAI(content, aiReply);

            // ===== 6. 保存AI回复到数据库 =====
            ChatMessage aiMsg = new ChatMessage();
            aiMsg.setSessionId(sessionId);
            aiMsg.setSenderType("AI");
            aiMsg.setContent(aiReply);
            aiMsg.setEmotionTag(analysis.getPrimaryEmotion());
            long aiMsgId = messageDao.add(aiMsg);

            // ===== 7. 【V3.0新增】异步索引向量（用于语义搜索历史问题）=====
            indexMessageVectorAsync(user.getId(), sessionId, userMsgId, content, "USER");
            indexMessageVectorAsync(user.getId(), sessionId, aiMsgId, aiReply, "AI");

            // ===== 8. 【V3.0新增】提取并存储长期记忆 =====
            List<ChatMessage> currentConversation = new ArrayList<>();
            currentConversation.addAll(recentMessages);
            
            ChatMessage userMsgRecord = new ChatMessage();
            userMsgRecord.setSenderType("USER");
            userMsgRecord.setContent(content);
            currentConversation.add(userMsgRecord);
            
            ChatMessage aiMsgRecord = new ChatMessage();
            aiMsgRecord.setSenderType("AI");
            aiMsgRecord.setContent(aiReply);
            currentConversation.add(aiMsgRecord);
            
            int extractedCount = memoryService.extractAndStoreMemories(user.getId(), sessionId, currentConversation);
            if (extractedCount > 0) {
                System.out.println("[Memory] 从本次对话提取了 " + extractedCount + " 条长期记忆");
            }

            // ===== 9. 更新会话元数据 =====
            updateSessionMetadata(sessionId, analysis, content);

            // ===== 8. 高危内容自动触发预警 =====
            if (analysis.isHighRisk()) {
                triggerHighRiskAlert(user, sessionId, content, analysis);
            }

            // ===== 10. 构建返回结果 =====
            Map<String, Object> result = new HashMap<>();
            result.put("userMessageId", userMsgId);
            result.put("aiMessageId", aiMsgId);
            result.put("aiMessage", aiReply);
            result.put("emotionTag", analysis.getPrimaryEmotion());
            result.put("isHighRisk", analysis.isHighRisk());
            result.put("responseTimeMs", responseTime);
            result.put("remainingQuota", rateLimitDao.getRemainingQuota(user.getId()));
            result.put("hasDataEnhancement", studentContext != null && studentContext.hasData());
            
            // V3.0新增字段：RAG和记忆状态
            result.put("hasRAGContext", ragContext != null && !ragContext.isEmpty());
            result.put("hasLongTermMemory", longTermMemoryContext != null && !longTermMemoryContext.isEmpty());

            JsonUtil.writeSuccess(resp, result);

        } catch (AIService.AIException e) {
            System.err.println("========================================");
            System.err.println("[ERROR] AI调用失败: " + e.getMessage());
            System.err.println("[ERROR] 当前Provider: " + aiService.getCurrentProvider());
            System.err.println("[ERROR] 当前Model: " + aiService.getCurrentModel());
            System.err.println("[ERROR] API URL: " + aiService.getCurrentApiUrl().substring(0, 
                Math.min(50, aiService.getCurrentApiUrl().length())) + "...");
            System.err.println("[ERROR] API Key: " + (aiService.getCurrentApiKey() != null && 
                !aiService.getCurrentApiKey().isEmpty() ? 
                aiService.getCurrentApiKey().substring(0, 10) + "***" : "(空!)"));
            System.err.println("========================================");
            
            // AI服务异常时返回友好提示
            Map<String, Object> errorResult = new HashMap<>();
            errorResult.put("fallbackMessage", generateFallbackReply(content));
            errorResult.put("errorType", "AI_SERVICE_ERROR");
            errorResult.put("errorMessage", "AI服务暂时不可用，已切换到基础模式");
            
            JsonUtil.writeError(resp, "AI服务暂时繁忙，请稍后再试", errorResult);
            
        } catch (Exception e) {
            System.err.println("[ERROR] 处理消息时发生未预期异常: " + e.getMessage());
            e.printStackTrace();
            JsonUtil.writeError(resp, "服务器内部错误，请联系管理员");
        }
    }

    /**
     * SSE流式响应端点 - 实时推送AI生成的每个token
     */
    private void handleStreamRequest(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        
        // 设置SSE响应头
        resp.setContentType("text/event-stream;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache");
        resp.setHeader("Connection", "keep-alive");
        
        User user = (User) req.getSession().getAttribute("currentUser");
        String sessionIdStr = req.getParameter("sessionId");
        String content = req.getParameter("message");
        
        PrintWriter out = resp.getWriter();
        
        try {
            // 参数校验
            if (sessionIdStr == null || content == null || content.trim().isEmpty()) {
                out.write("data: {\"error\":\"参数错误\"}\n\n");
                return;
            }
            
            Long sessionId = Long.parseLong(sessionIdStr);
            
            // 限流检查
            if (!rateLimitDao.checkAndIncrement(user.getId())) {
                out.write("data: {\"error\":\"今日对话次数已达上限\"}\n\n");
                return;
            }
            
            // 保存用户消息
            ChatMessage userMsg = new ChatMessage();
            userMsg.setSessionId(sessionId);
            userMsg.setSenderType("USER");
            userMsg.setContent(content);
            messageDao.add(userMsg);
            
            // 构建AI请求（与handleSendMessage相同的逻辑）
            StudentContextBuilder.StudentContext studentContext = null;
            try {
                StudentContextBuilder contextBuilder = new StudentContextBuilder(user.getId());
                studentContext = contextBuilder.build();
            } catch (Exception ignored) {}
            
            List<ChatMessage> recentMessages = loadRecentHistory(sessionId, CONTEXT_WINDOW_SIZE);
            List<Map<String, String>> messagesForAI = AIService.toMessageList(recentMessages);
            Map<String, String> currentMsg = new HashMap<>();
            currentMsg.put("role", "user");
            currentMsg.put("content", content);
            messagesForAI.add(currentMsg);
            
            String systemPrompt = PsychologyPromptEngine.buildSystemPrompt(
                studentContext, buildConversationSummary(recentMessages));
            
            final StringBuilder fullResponse = new StringBuilder();
            final AtomicLong lastKeepAlive = new AtomicLong(System.currentTimeMillis());
            
            System.out.println("[STREAM] 开始【同步】流式请求, 准备调用AI...");
            
            // ★ 使用同步版流式调用：所有回调在当前Servlet线程执行，避免NPE
            aiService.streamChatCompletionSync(systemPrompt, messagesForAI, 0.7,
                
                // onToken - 收到每个token时推送给前端（在Servlet线程执行）
                token -> {
                    try {
                        // 处理推理心跳：Seed模型推理阶段返回TOKEN_THINKING
                        if (AIService.TOKEN_THINKING.equals(token)) {
                            long now = System.currentTimeMillis();
                            // 每5秒发送一次心跳注释，保持SSE连接不断开
                            if (now - lastKeepAlive.get() > 5000) {
                                String heartbeat = ": AI正在思考中...\n\n";
                                out.write(heartbeat);
                                out.flush();
                                lastKeepAlive.set(now);
                                System.out.println("[STREAM] 发送心跳保活");
                            }
                            return;  // 不追加到回复内容中
                        }
                        
                        // 正常内容token：推送给前端
                        // SSE格式：data: {"content":"token文本"}
                        String escaped = escapeJson(token);
                        String jsonToken = "{\"content\":\"" + escaped + "\"}";
                        out.write("data: " + jsonToken + "\n\n");
                        out.flush();  // 立即刷新缓冲区
                        fullResponse.append(token);
                    } catch (Exception e) {
                        System.err.println("[STREAM] token写入异常: " + e.getClass().getSimpleName() 
                            + " - " + e.getMessage());
                        e.printStackTrace(System.err);
                    }
                },
                
                // onComplete - 流结束时
                () -> {
                    try {
                        // 保存完整AI回复到数据库
                        String aiReply = fullResponse.toString();
                        
                        ChatMessage aiMsg = new ChatMessage();
                        aiMsg.setSessionId(sessionId);
                        aiMsg.setSenderType("AI");
                        aiMsg.setContent(aiReply);
                        aiMsg.setEmotionTag(analyzeEmotionSimple(content).getPrimaryEmotion());
                        messageDao.add(aiMsg);
                        
                        // 更新会话
                        EmotionAnalysisResult analysis = analyzeEmotionSimple(content);
                        updateSessionMetadata(sessionId, analysis, content);
                        
                        if (analysis.isHighRisk()) {
                            triggerHighRiskAlert(user, sessionId, content, analysis);
                        }
                        
                        // 发送完成标记
                        out.write("data: [DONE]\n\n");
                        out.flush();
                        
                    } catch (Exception e) {
                        System.err.println("[STREAM ERROR] 完成处理失败: " + e.getMessage());
                        try {
                            out.write("data: {\"error\":\"保存失败\"}\n\n");
                            out.flush();
                        } catch (Exception ignored) {}
                    }
                },
                
                // onError - 错误处理
                error -> {
                    System.err.println("========================================");
                    System.err.println("[STREAM ERROR] 流式AI调用失败: " + error.getMessage());
                    System.err.println("[STREAM ERROR] Provider: " + aiService.getCurrentProvider());
                    System.err.println("[STREAM ERROR] Model: " + aiService.getCurrentModel());
                    System.err.println("[STREAM ERROR] URL: " + aiService.getCurrentApiUrl().substring(0, 
                        Math.min(50, aiService.getCurrentApiUrl().length())) + "...");
                    System.err.println("========================================");
                    try {
                        out.write("data: {\"error\":\"" + escapeJson(error.getMessage()) + "\"}\n\n");
                        out.flush();
                    } catch (Exception ignored) {}
                }
            );
            
        } catch (Exception e) {
            out.write("data: {\"error\":\"" + escapeJson(e.getMessage()) + "\"}\n\n");
            out.flush();
        }
    }

    /**
     * 创建新会话
     */
    private void handleCreateSession(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");

        ChatSession session = new ChatSession();
        session.setUserId(user.getId());
        session.setTitle("新对话");  // 首次发送消息后会更新标题

        long sessionId = new ChatSessionDao().add(session);

        Map<String, Object> result = new HashMap<>();
        result.put("sessionId", sessionId);
        result.put("welcomeMessage", PsychologyPromptEngine.generateWelcomeMessage());
        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 获取会话列表
     */
    private void handleGetSessions(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");

        int page = 1;
        if (req.getParameter("page") != null) {
            page = Integer.parseInt(req.getParameter("page"));
        }

        List<ChatSession> sessions = new ChatSessionDao().findByUserId(user.getId(), page, 10);
        JsonUtil.writeSuccess(resp, sessions);
    }

    /**
     * 获取消息历史
     */
    private void handleGetMessages(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String sessionIdStr = req.getParameter("sessionId");
        if (sessionIdStr == null || sessionIdStr.isEmpty()) {
            JsonUtil.writeParamError(resp, "请指定会话ID");
            return;
        }

        List<ChatMessage> messages = messageDao.findBySessionId(Long.parseLong(sessionIdStr));
        JsonUtil.writeSuccess(resp, messages);
    }

    /**
     * 获取今日限流信息
     */
    private void handleLimitInfo(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");

        Map<String, Object> info = new HashMap<>();
        info.put("used", rateLimitDao.getTodayUsage(user.getId()));
        info.put("limit", DAILY_CHAT_LIMIT);
        info.put("remaining", DAILY_CHAT_LIMIT - rateLimitDao.getTodayUsage(user.getId()));
        info.put("aiProvider", aiService.getCurrentProvider());

        JsonUtil.writeSuccess(resp, info);
    }

    // =====================================================
    // 私有辅助方法
    // =====================================================

    /**
     * 加载最近N条历史消息（用于构建上下文）
     */
    private List<ChatMessage> loadRecentHistory(long sessionId, int limit) {
        List<ChatMessage> allMessages = messageDao.findBySessionId(sessionId);
        
        if (allMessages == null || allMessages.isEmpty()) {
            return new ArrayList<>();
        }
        
        // 取最近limit条消息（如果总数超过limit）
        if (allMessages.size() > limit) {
            return allMessages.subList(allMessages.size() - limit, allMessages.size());
        }
        
        return allMessages;
    }

    /**
     * 从历史消息中提取摘要（用于系统提示词）
     */
    private String buildConversationSummary(List<ChatMessage> messages) {
        if (messages == null || messages.isEmpty()) {
            return "这是本次对话的第一条消息";
        }
        
        StringBuilder summary = new StringBuilder();
        summary.append("近期对话主题:\n");
        
        // 只提取用户的消息内容作为摘要
        int count = 0;
        for (int i = messages.size() - 1; i >= 0 && count < 3; i--) {
            ChatMessage msg = messages.get(i);
            if ("USER".equals(msg.getSenderType())) {
                String preview = msg.getContent().length() > 50 ?
                    msg.getContent().substring(0, 50) + "..." : msg.getContent();
                summary.append("- ").append(preview.replace("\n", " ")).append("\n");
                count++;
            }
        }
        
        return summary.toString();
    }

    /**
     * AI情绪分析 - 结合用户输入和AI回复综合判断
     * （比纯关键词匹配更准确）
     */
    private EmotionAnalysisResult analyzeEmotionWithAI(String userInput, String aiReply) {
        EmotionAnalysisResult result = new EmotionAnalysisResult();
        String combinedText = userInput + " " + aiReply;
        
        // 1. 危机检测（优先级最高）
        for (String keyword : CRISIS_KEYWORDS) {
            if (userInput.contains(keyword)) {
                result.setPrimaryEmotion("危机");
                result.setHighRisk(true);
                result.setRiskReason("检测到可能的自伤/自杀倾向关键词: " + keyword);
                return result;
            }
        }
        
        // 2. 基于AI回复推断情绪类别（更准确）
        if (aiReply.contains("焦虑") || aiReply.contains("担心") || aiReply.contains("紧张")) {
            result.setPrimaryEmotion("焦虑");
        } else if (aiReply.contains("抑郁") || aiReply.contains("低落") || aiReply.contains("难过")) {
            result.setPrimaryEmotion("抑郁");
        } else if (aiReply.contains("压力") || aiReply.contains("学业") || aiReply.contains("学习")) {
            result.setPrimaryEmotion("学业压力");
        } else if (aiReply.contains("人际") || aiReply.contains("关系") || aiReply.contains("室友")) {
            result.setPrimaryEmotion("人际矛盾");
        } else if (aiReply.contains("恋爱") || aiReply.contains("感情") || aiReply.contains("分手")) {
            result.setPrimaryEmotion("恋爱困扰");
        } else if (aiReply.contains("迷茫") || aiReply.contains("内耗") || aiReply.contains("困惑")) {
            result.setPrimaryEmotion("自我认同");
        } else {
            result.setPrimaryEmotion("一般倾诉");
        }
        
        return result;
    }

    /**
     * 简化版情绪分析（仅基于输入，用于流式场景）
     */
    private EmotionAnalysisResult analyzeEmotionSimple(String userInput) {
        EmotionAnalysisResult result = new EmotionAnalysisResult();
        
        for (String keyword : CRISIS_KEYWORDS) {
            if (userInput.contains(keyword)) {
                result.setPrimaryEmotion("危机");
                result.setHighRisk(true);
                result.setRiskReason("检测到高危关键词");
                return result;
            }
        }
        
        result.setPrimaryEmotion("一般倾诉");
        return result;
    }

    /**
     * 更新会话元数据和情绪标签
     */
    private void updateSessionMetadata(long sessionId, EmotionAnalysisResult analysis, 
                                        String firstMessageContent) {
        ChatSessionDao sessionDao = new ChatSessionDao();
        
        // 如果是第一条消息，更新会话标题
        List<ChatMessage> messages = messageDao.findBySessionId(sessionId);
        if (messages != null && messages.size() <= 2) {  // 用户消息+AI欢迎语
            String title = PsychologyPromptEngine.generateSessionTitle(firstMessageContent);
            sessionDao.updateTitle(sessionId, title);
        }
        
        // 更新情绪标签和高危标记
        sessionDao.updateEmotionTags(sessionId, 
            "[\"" + analysis.getPrimaryEmotion() + "\"]", 
            analysis.isHighRisk() ? 1 : 0);
    }

    /**
     * 触发高危预警
     */
    private void triggerHighRiskAlert(User user, Long sessionId, String content,
                                       EmotionAnalysisResult analysis) {
        if (user == null || !"STUDENT".equals(user.getRole())) {
            return; // 只有学生角色触发预警
        }
        
        AlertRecord alert = new AlertRecord();
        alert.setStudentId(user.getId());
        alert.setChatSessionId(sessionId);
        alert.setAlertLevel("HIGH");
        alert.setAlertType("CHAT");
        alert.setTriggerReason("树洞对话检测到高危内容: " + analysis.getRiskReason());
        alert.setStatus("PENDING");
        
        new AlertRecordDao().add(alert);
        new ChatSessionDao().markAlertTriggered(sessionId);
        
        System.out.println("⚠️ [高危预警] 已触发 - 学生ID: " + user.getId() + 
            ", 会话ID: " + sessionId + ", 原因: " + analysis.getRiskReason());
    }

    /**
     * AI服务不可用时的降级回复
     */
    private String generateFallbackReply(String userInput) {
        if (userInput.contains("焦虑") || userInput.contains("压力")) {
            return "我理解你现在感到焦虑。虽然我的AI大脑暂时在休息，但我想告诉你：\n\n" +
                   "1. 深呼吸练习：吸气4秒-屏息7秒-呼气8秒，重复3次\n" +
                   "2. 写下担忧的事情，区分\"可控\"和\"不可控\"\n" +
                   "3. 如果持续感到困扰，建议预约学校心理咨询中心\n\n" +
                   "稍后你可以再试试和我聊天，我会恢复正常的～";
        }
        
        return "抱歉，我的AI核心暂时在休息 🤖\n\n" +
               "不过别担心，这里有一些通用的建议：\n" +
               "- 你的感受是真实且重要的\n" +
               "- 寻求专业帮助是勇敢的表现\n" +
               "- 学校心理咨询中心随时为你敞开\n\n" +
               "你可以过一会儿再来找我聊天！";
    }

    // =====================================================
    // V3.0新增：向量和记忆相关方法
    // =====================================================

    /**
     * 异步索引消息向量（不阻塞主流程）
     */
    private void indexMessageVectorAsync(int userId, long sessionId, long messageId, 
                                          String messageText, String senderType) {
        // 使用新线程异步执行，避免阻塞HTTP响应
        new Thread(() -> {
            try {
                boolean success = vectorStoreService.indexChatMessage(
                    userId, sessionId, messageId, messageText, senderType);
                
                if (success) {
                    System.out.println("[Vector] 消息向量索引成功 - ID: " + messageId);
                }
            } catch (Exception e) {
                System.err.println("[Vector] 异步向量索引失败: " + e.getMessage());
            }
        }).start();
    }

    /**
     * 语义搜索用户的历史问题（新API端点）
     */
    private void handleSemanticSearch(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        String query = req.getParameter("query");
        int topK = 5;
        
        if (req.getParameter("topK") != null) {
            topK = Integer.parseInt(req.getParameter("topK"));
        }
        
        if (query == null || query.trim().isEmpty()) {
            JsonUtil.writeParamError(resp, "请输入搜索关键词");
            return;
        }
        
        try {
            List<VectorStoreService.SimilarityResult> results = 
                vectorStoreService.searchSimilarUserMessages(user.getId(), query, topK, 0.5);
            
            Map<String, Object> resultData = new HashMap<>();
            resultData.put("query", query);
            resultData.put("results", results);
            resultData.put("count", results.size());
            
            JsonUtil.writeSuccess(resp, resultData);
            
        } catch (Exception e) {
            JsonUtil.writeError(resp, "语义搜索失败: " + e.getMessage(), e);
        }
    }

    /**
     * 获取用户的AI记忆统计（新API端点）
     */
    private void handleMemoryStats(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        
        Map<String, Object> stats = memoryService.getUserMemoryStats(user.getId());
        JsonUtil.writeSuccess(resp, stats);
    }

    /**
     * JSON特殊字符转义（用于SSE）
     */
    private String escapeJson(String text) {
        return text.replace("\\", "\\\\")
                   .replace("\"", "\\\"")
                   .replace("\n", "\\n")
                   .replace("\r", "\\r")
                   .replace("\t", "\\t");
    }

    // =====================================================
    // 内部类
    // =====================================================

    private static class EmotionAnalysisResult {
        private String primaryEmotion;
        private boolean highRisk;
        private String riskReason;

        public String getPrimaryEmotion() { return primaryEmotion; }
        public void setPrimaryEmotion(String primaryEmotion) { this.primaryEmotion = primaryEmotion; }
        public boolean isHighRisk() { return highRisk; }
        public void setHighRisk(boolean highRisk) { this.highRisk = highRisk; }
        public String getRiskReason() { return riskReason; }
        public void setRiskReason(String riskReason) { this.riskReason = riskReason; }
    }
}
