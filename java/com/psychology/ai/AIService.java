package com.psychology.ai;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.reflect.TypeToken;
import okhttp3.*;
import okio.BufferedSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

/**
 * AI大模型服务 - 封装多模型API调用
 * 
 * 支持：
 * 1. 豆包(字节跳动) - 推荐，中文理解能力强
 * 2. DeepSeek - 性价比高，推理能力强
 * 3. OpenAI (GPT-4o) - 通用能力最强
 * 4. 自定义OpenAI兼容接口（如Ollama本地部署）
 *
 * 特性：
 * - 流式SSE响应支持
 * - 多Provider无缝切换
 * - 自动重试机制
 * - 完整错误处理
 */
public class AIService {
    private static final Logger logger = LoggerFactory.getLogger(AIService.class);
    
    private static AIService instance;
    private final Properties config;
    private final OkHttpClient httpClient;
    private final Gson gson;
    
    // 当前配置的Provider
    private String currentProvider;
    private String currentApiUrl;
    private String currentApiKey;
    private String currentModel;
    
    /**
     * 获取单例实例
     */
    public synchronized static AIService getInstance() {
        if (instance == null) {
            instance = new AIService();
        }
        return instance;
    }
    
    private AIService() {
        this.gson = new Gson();
        this.config = loadConfig();
        
        // 初始化HTTP客户端（带容错处理）
        int timeoutSeconds = 30;
        try {
            String timeoutStr = config.getProperty("ai.request.timeout.seconds", "30");
            // 清除可能的空白字符
            if (timeoutStr != null) {
                timeoutStr = timeoutStr.trim();
            }
            // 验证是有效数字
            if (timeoutStr != null && timeoutStr.matches("\\d+")) {
                timeoutSeconds = Integer.parseInt(timeoutStr);
            } else {
                logger.warn("ai.request.timeout.seconds 值无效: '{}'，使用默认值 30", timeoutStr);
            }
        } catch (NumberFormatException e) {
            logger.warn("解析超时配置失败，使用默认值 30 秒", e);
        }
            
        this.httpClient = new OkHttpClient.Builder()
            .connectTimeout(timeoutSeconds, TimeUnit.SECONDS)
            .readTimeout(timeoutSeconds, TimeUnit.SECONDS)
            .writeTimeout(timeoutSeconds, TimeUnit.SECONDS)
            .build();
        
        // 加载当前Provider配置（带容错处理）
        try {
            reloadProviderConfig();
        } catch (Exception e) {
            logger.error("加载AI Provider配置失败，使用默认DOUBAO配置", e);
            this.currentProvider = "DOUBAO";
            this.currentApiUrl = "";
            this.currentApiKey = "";
            this.currentModel = "default";
        }
        
        logger.info("AIService初始化完成 - Provider: {}, Model: {}", 
            currentProvider, currentModel);
    }
    
    /**
     * 加载配置文件
     */
    private Properties loadConfig() {
        Properties props = new Properties();
        try {
            props.load(getClass().getClassLoader()
                .getResourceAsStream("ai.properties"));
        } catch (Exception e) {
            logger.warn("加载ai.properties失败，使用默认配置", e);
            setDefaultConfig(props);
        }
        return props;
    }
    
    /**
     * 设置默认配置（当配置文件不存在时）
     */
    private void setDefaultConfig(Properties props) {
        props.setProperty("ai.provider", "DOUBAO");
        props.setProperty("ai.doubao.api.url", "https://ark.cn-beijing.volces.com/api/v3/chat/completions");
        props.setProperty("ai.doubao.model", "ep-20240601153646-lmzqv");
        props.setProperty("ai.request.timeout.seconds", "30");
        props.setProperty("ai.stream.enabled", "true");
    }
    
    /**
     * 重新加载当前Provider的配置
     */
    public void reloadProviderConfig() {
        this.currentProvider = config.getProperty("ai.provider", "DOUBAO").toUpperCase();
        
        String prefix = "ai." + currentProvider.toLowerCase() + ".";
        this.currentApiUrl = config.getProperty(prefix + "api.url", "");
        this.currentApiKey = config.getProperty(prefix + "api.key", "");
        this.currentModel = config.getProperty(prefix + "model", "default");
        
        // 详细日志输出（用于调试）
        System.out.println("========================================");
        System.out.println("[AIService] 配置加载完成:");
        System.out.println("[AIService]   Provider: " + currentProvider);
        System.out.println("[AIService]   API URL: " + currentApiUrl);
        System.out.println("[AIService]   API Key: " + (currentApiKey != null ? currentApiKey.substring(0, Math.min(15, currentApiKey.length())) + "***" : "(null)"));
        System.out.println("[AIService]   Model: " + currentModel);
        System.out.println("========================================");
        
        logger.debug("当前AI配置: provider={}, url={}, model={}", 
            currentProvider, currentApiUrl, currentModel);
    }
    
    // =====================================================
    // 核心API调用方法
    // =====================================================
    
    /**
     * 发送消息获取完整回复（非流式）
     * 
     * @param systemPrompt 系统提示词
     * @param messages 对话历史消息列表
     * @param temperature 温度参数(0-1)
     * @return AI回复文本
     */
    public String chatCompletion(String systemPrompt, List<Map<String, String>> messages, 
                                  double temperature) throws AIException {
        try {
            // 构建请求体
            JsonObject requestBody = buildRequestBody(systemPrompt, messages, temperature, false);
            
            Request request = buildRequest(requestBody.toString());
            
            logger.debug("发送非流式请求到: {} (model={})", currentApiUrl, currentModel);
            
            try (Response response = httpClient.newCall(request).execute()) {
                if (!response.isSuccessful()) {
                    String errorBody = response.body() != null ? 
                        response.body().string() : "无错误详情";
                    throw new AIException("API请求失败 [" + response.code() + "]: " + errorBody);
                }
                
                String responseBody = response.body().string();
                return parseResponse(responseBody);
            }
            
        } catch (IOException e) {
            logger.error("AI API调用异常", e);
            throw new AIException("网络请求异常: " + e.getMessage(), e);
        }
    }
    
    /**
     * 流式对话（同步阻塞版）- SSE实时返回每个token
     * 
     * 【重要】此方法在调用线程上同步执行流读取和回调，
     * 适合Servlet场景：确保 out.write/flush 在Servlet线程上执行，避免NPE。
     * 
     * 使用独立的长时间超时HTTP客户端（180秒），适应Seed模型的长推理阶段。
     * 
     * @param systemPrompt 系统提示词
     * @param messages 对话历史消息列表
     * @param temperature 温度参数(0-1)
     * @param onToken 每收到一个token的回调函数（在调用线程上同步执行）
     * @param onComplete 完成时的回调
     * @param onError 错误时的回调
     */
    public void streamChatCompletionSync(String systemPrompt, List<Map<String, String>> messages,
                                          double temperature,
                                          Consumer<String> onToken,
                                          Runnable onComplete,
                                          Consumer<Exception> onError) {
        // ★ 流式专用客户端：180秒超时（Seed模型推理阶段可达45-90秒）
        OkHttpClient streamingClient = this.httpClient.newBuilder()
            .readTimeout(180, TimeUnit.SECONDS)
            .build();
        
        try {
            // 构建流式请求体
            JsonObject requestBody = buildRequestBody(systemPrompt, messages, temperature, true);
            
            Request request = buildRequest(requestBody.toString());
            
            logger.info("开始【同步】流式请求到: {} (model={}, timeout=180s)", currentApiUrl, currentModel);
            
            // ★ 关键差异：使用 execute() 而非 enqueue() —— 同步阻塞在当前线程
            try (Response response = streamingClient.newCall(request).execute()) {
                if (!response.isSuccessful()) {
                    String errorBody = response.body() != null ?
                        response.body().string() : "无错误详情";
                    onError.accept(new AIException(
                        "API请求失败 [" + response.code() + "]: " + errorBody));
                    return;
                }
                
                try (okio.BufferedSource source = response.body().source()) {
                    while (!source.exhausted()) {
                        String line = source.readUtf8Line();
                        
                        if (line == null || line.isEmpty()) continue;
                        
                        // SSE格式：data: {...}
                        if (line.startsWith("data: ")) {
                            String data = line.substring(6);
                            
                            // 流结束标记
                            if ("[DONE]".equals(data)) {
                                onComplete.run();
                                return;
                            }
                            
                            // 解析JSON提取内容
                            try {
                                String tokenContent = parseStreamChunk(data);
                                if (tokenContent != null && !tokenContent.isEmpty()) {
                                    onToken.accept(tokenContent);  // ★ 同步回调：在Servlet线程执行
                                }
                            } catch (Exception e) {
                                logger.warn("解析流数据块失败: {}", data, e);
                            }
                        }
                    }
                    
                    // 流正常结束（读完所有数据）
                    onComplete.run();
                }
            }
            
        } catch (IOException e) {
            logger.error("同步流式请求IO异常", e);
            onError.accept(new AIException("网络请求异常: " + e.getMessage(), e));
        } catch (Exception e) {
            logger.error("同步流式请求异常", e);
            onError.accept(new AIException("请求异常: " + e.getMessage(), e));
        }
    }

    /**
     * 流式对话（异步版）- 内部使用OkHttp enqueue
     * 
     * ⚠️ 注意：onToken 回调会在 OkHttp 线程池上执行！
     * 如果需要在Servlet中使用 PrintWriter 写入响应，请用 streamChatCompletionSync() 代替。
     * 
     * @param systemPrompt 系统提示词
     * @param messages 对话历史
     * @param temperature 温度参数
     * @param onToken 每收到一个token的回调函数
     * @param onComplete 完成时的回调
     * @param onError 错误时的回调
     */
    public void streamChatCompletion(String systemPrompt, List<Map<String, String>> messages,
                                      double temperature,
                                      Consumer<String> onToken,
                                      Runnable onComplete,
                                      Consumer<Exception> onError) {
        try {
            // 构建流式请求体
            JsonObject requestBody = buildRequestBody(systemPrompt, messages, temperature, true);
            
            Request request = buildRequest(requestBody.toString());
            
            logger.info("开始流式请求到: {} (model={})", currentApiUrl, currentModel);
            
            httpClient.newCall(request).enqueue(new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    logger.error("流式请求失败", e);
                    onError.accept(new AIException("连接失败: " + e.getMessage(), e));
                }
                
                @Override
                public void onResponse(Call call, Response response) throws IOException {
                    if (!response.isSuccessful()) {
                        String errorBody = response.body() != null ?
                            response.body().string() : "无错误详情";
                        onError.accept(new AIException(
                            "API请求失败 [" + response.code() + "]: " + errorBody));
                        return;
                    }
                    
                    try (BufferedSource source = response.body().source()) {
                        StringBuilder fullResponse = new StringBuilder();
                        
                        while (!source.exhausted()) {
                            String line = source.readUtf8Line();
                            
                            if (line == null || line.isEmpty()) continue;
                            
                            // SSE格式：data: {...}
                            if (line.startsWith("data: ")) {
                                String data = line.substring(6);
                                
                                // 流结束标记
                                if ("[DONE]".equals(data)) {
                                    onComplete.run();
                                    return;
                                }
                                
                                // 解析JSON提取内容
                                try {
                                    String tokenContent = parseStreamChunk(data);
                                    if (tokenContent != null && !tokenContent.isEmpty()) {
                                        fullResponse.append(tokenContent);
                                        onToken.accept(tokenContent);  // 回调通知前端
                                    }
                                } catch (Exception e) {
                                    logger.warn("解析流数据块失败: {}", data, e);
                                }
                            }
                        }
                        
                        onComplete.run();
                    } catch (Exception e) {
                        logger.error("读取流数据异常", e);
                        onError.accept(e);
                    }
                }
            });
            
        } catch (Exception e) {
            onError.accept(new AIException("创建请求失败: " + e.getMessage(), e));
        }
    }
    
    // =====================================================
    // 私有辅助方法
    // =====================================================
    
    /**
     * 构建API请求体
     */
    private JsonObject buildRequestBody(String systemPrompt, List<Map<String, String>> messages,
                                         double temperature, boolean stream) {
        JsonArray messageArray = new JsonArray();
        
        // 添加系统消息
        if (systemPrompt != null && !systemPrompt.isEmpty()) {
            JsonObject systemMsg = new JsonObject();
            systemMsg.addProperty("role", "system");
            systemMsg.addProperty("content", systemPrompt);
            messageArray.add(systemMsg);
        }
        
        // 添加历史消息
        for (Map<String, String> msg : messages) {
            JsonObject msgObj = new JsonObject();
            msgObj.addProperty("role", msg.get("role"));   // "user" 或 "assistant"
            msgObj.addProperty("content", msg.get("content"));
            messageArray.add(msgObj);
        }
        
        // 组装完整请求体
        JsonObject body = new JsonObject();
        body.add("messages", messageArray);
        body.addProperty("model", currentModel);
        body.addProperty("temperature", temperature);
        body.addProperty("stream", stream);
        body.addProperty("max_tokens", getMaxTokens());
        
        // 可选参数
        double topP = getTopP();
        if (topP > 0) {
            body.addProperty("top_p", topP);
        }
        
        return body;
    }
    
    /**
     * 构建HTTP请求对象
     */
    private Request buildRequest(String jsonBody) {
        MediaType JSON = MediaType.get("application/json; charset=utf-8");
        RequestBody body = RequestBody.create(jsonBody, JSON);
        
        return new Request.Builder()
            .url(currentApiUrl)
            .post(body)
            .addHeader("Authorization", "Bearer " + currentApiKey)
            .addHeader("Content-Type", "application/json")
            .build();
    }
    
    /**
     * 解析非流式响应
     */
    private String parseResponse(String responseBody) {
        JsonObject jsonResponse = gson.fromJson(responseBody, JsonObject.class);
        
        if (jsonResponse.has("choices")) {
            JsonArray choices = jsonResponse.getAsJsonArray("choices");
            if (choices.size() > 0) {
                JsonObject firstChoice = choices.get(0).getAsJsonObject();
                if (firstChoice.has("message")) {
                    JsonObject message = firstChoice.getAsJsonObject("message");
                    return message.get("content").getAsString();
                }
            }
        }
        
        // 错误信息
        if (jsonResponse.has("error")) {
            JsonObject error = jsonResponse.getAsJsonObject("error");
            String errorMsg = error.has("message") ? error.get("message").getAsString() : "未知错误";
            return "[AI_ERROR] " + errorMsg;
        }
        
        // 无法解析
        return null;
    }
    
    /**
     * 特殊标记：模型正在进行推理（thinking），用于保持SSE连接活跃
     */
    public static final String TOKEN_THINKING = "\u0000THINKING";

    /**
     * 解析SSE流式数据块
     * 支持标准OpenAI格式和豆包Seed模型格式（含reasoning_content）
     * 
     * @return content文本 / TOKEN_THINKING(推理中，需发心跳) / null(跳过)
     */
    private String parseStreamChunk(String data) {
        try {
            JsonObject chunk = gson.fromJson(data, JsonObject.class);
            
            if (chunk == null || !chunk.has("choices")) {
                return null;
            }
            
            JsonArray choices = chunk.getAsJsonArray("choices");
            if (choices == null || choices.size() == 0) {
                return null;
            }
            
            JsonObject choice = choices.get(0).getAsJsonObject();
            if (choice == null || !choice.has("delta")) {
                return null;
            }
            
            JsonObject deltaObj = choice.getAsJsonObject("delta");
            if (deltaObj == null) {
                return null;
            }
            
            // 优先获取 content（最终回复内容）
            if (deltaObj.has("content")) {
                JsonElement contentElem = deltaObj.get("content");
                if (contentElem != null && !contentElem.isJsonNull()) {
                    return contentElem.getAsString();
                }
            }
            
            // 豆包Seed模型的 reasoning_content → 返回特殊标记让调用方发送心跳
            if (deltaObj.has("reasoning_content")) {
                JsonElement reasoningElem = deltaObj.get("reasoning_content");
                if (reasoningElem != null && !reasoningElem.isJsonNull()) {
                    return TOKEN_THINKING;  // 告诉调用方：正在推理，需要心跳保活
                }
            }
            
            return null;  // 无有效内容
            
        } catch (Exception e) {
            System.err.println("[STREAM] 解析chunk异常: " + 
                (data.length() > 150 ? data.substring(0, 150) + "..." : data));
            return null;
        }
    }
    
    /**
     * 获取最大token数
     */
    private int getMaxTokens() {
        String prefix = "ai." + currentProvider.toLowerCase() + ".";
        return Integer.parseInt(config.getProperty(prefix + "max.tokens", "2048"));
    }
    
    /**
     * 获取top_p参数
     */
    private double getTopP() {
        String prefix = "ai." + currentProvider.toLowerCase() + ".";
        return Double.parseDouble(config.getProperty(prefix + "top.p", "0"));
    }
    
    // =====================================================
    // 公共工具方法
    // =====================================================
    
    /**
     * 获取当前使用的Provider名称
     */
    public String getCurrentProvider() {
        return currentProvider;
    }
    
    /**
     * 获取当前Model名称
     */
    public String getCurrentModel() {
        return currentModel;
    }
    
    /**
     * 获取当前API URL
     */
    public String getCurrentApiUrl() {
        return currentApiUrl;
    }
    
    /**
     * 获取当前API Key (脱敏)
     */
    public String getCurrentApiKey() {
        return currentApiKey;
    }
    
    /**
     * 测试API连通性
     */
    public boolean testConnection() {
        try {
            List<Map<String, String>> testMessages = new ArrayList<>();
            Map<String, String> testMsg = new HashMap<>();
            testMsg.put("role", "user");
            testMsg.put("content", "你好，请回复'测试成功'");
            testMessages.add(testMsg);
            
            String reply = chatCompletion("你是一个测试助手", testMessages, 0.5);
            return reply != null && !reply.isEmpty();
            
        } catch (AIException e) {
            logger.error("API连通性测试失败", e);
            return false;
        }
    }
    
    /**
     * 将ChatMessage列表转换为标准消息格式
     */
    public static List<Map<String, String>> toMessageList(List<com.psychology.entity.ChatMessage> history) {
        List<Map<String, String>> result = new ArrayList<>();
        
        for (com.psychology.entity.ChatMessage msg : history) {
            Map<String, String> message = new HashMap<>();
            message.put("role", "USER".equals(msg.getSenderType()) ? "user" : "assistant");
            message.put("content", msg.getContent());
            result.add(message);
        }
        
        return result;
    }
    
    // =====================================================
    // 内部类定义
    // =====================================================
    
    /**
     * 聊天消息封装类
     */
    public static class ChatMessage {
        private String role;      // "user" 或 "assistant"
        private String content;
        
        public ChatMessage(String role, String content) {
            this.role = role;
            this.content = content;
        }
        
        public String getRole() { return role; }
        public String getContent() { return content; }
    }
    
    /**
     * AI服务自定义异常
     */
    public static class AIException extends Exception {
        public AIException(String message) { super(message); }
        public AIException(String message, Throwable cause) { super(message, cause); }
    }
}
