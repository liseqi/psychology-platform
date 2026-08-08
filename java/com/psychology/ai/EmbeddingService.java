package com.psychology.ai;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import okhttp3.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * 文本Embedding服务 - 将文本转换为向量表示
 * 
 * 支持：
 * 1. 豆包(字节跳动) Embedding API
 * 2. DeepSeek Embedding API  
 * 3. OpenAI Embedding API
 * 
 * 用于：
 * - RAG知识库构建（文章向量化）
 * - 对话历史语义搜索
 * - 用户问题相似度匹配
 *
 * 技术特点：
 * - 支持批量embedding（提高效率）
 * - 本地缓存机制（避免重复计算）
 * - 多Provider无缝切换
 */
public class EmbeddingService {
    private static final Logger logger = LoggerFactory.getLogger(EmbeddingService.class);
    
    private static EmbeddingService instance;
    private final Properties config;
    private final OkHttpClient httpClient;
    private final Gson gson;
    
    // 配置
    private String provider;           // DOUBAO/DEEPSEEK/OPENAI
    private String apiUrl;
    private String apiKey;
    private String model;
    private int dimension;             // 向量维度
    
    // 查询缓存（避免重复计算同一文本的embedding）
    private Map<String, List<Float>> textEmbeddingCache = new LinkedHashMap<String, List<Float>>(1000, 0.75f, true) {
        @Override
        protected boolean removeEldestEntry(Map.Entry eldest) {
            return size() > 1000;  // 缓存最多1000条
        }
    };
    
    public synchronized static EmbeddingService getInstance() {
        if (instance == null) {
            instance = new EmbeddingService();
        }
        return instance;
    }
    
    private EmbeddingService() {
        this.gson = new Gson();
        this.config = loadConfig();
        
        this.httpClient = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .build();
        
        loadEmbeddingConfig();
        
        logger.info("EmbeddingService初始化完成 - Provider: {}, Model: {}, Dimension: {}", 
            provider, model, dimension);
    }
    
    /**
     * 加载配置文件
     */
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
     * 加载Embedding相关配置
     */
    private void loadEmbeddingConfig() {
        this.provider = config.getProperty("embedding.provider", "DOUBAO").toUpperCase();
        this.dimension = Integer.parseInt(config.getProperty("embedding.dimension", "768"));
        this.model = config.getProperty("embedding.model", "text-embedding-v1");
        
        String prefix = "ai." + provider.toLowerCase() + ".";
        
        if ("DOUBAO".equals(provider)) {
            // 豆包使用专用的Embedding端点
            this.apiUrl = config.getProperty("ai.doubao.embedding.url",
                "https://ark.cn-beijing.volces.com/api/v3/embeddings");
            this.apiKey = config.getProperty("ai.doubao.api.key", "");
            this.model = config.getProperty("ai.doubao.embedding.model", "ep-20240528174716-lzvrh");
        } else if ("DEEPSEEK".equals(provider)) {
            // DeepSeek暂不支持Embedding，回退到OpenAI兼容接口
            this.apiUrl = config.getProperty("embedding.custom.url",
                "https://api.openai.com/v1/embeddings");
            this.apiKey = config.getProperty("embedding.api.key",
                config.getProperty("ai.openai.api.key", ""));
            this.model = "text-embedding-ada-002";
            this.dimension = 1536;
        } else {
            // OPENAI或其他
            this.apiUrl = config.getProperty(prefix + "api.url",
                "https://api.openai.com/v1/embeddings").replace("/chat/completions", "/embeddings");
            this.apiKey = config.getProperty(prefix + "api.key", "");
            this.model = config.getProperty("embedding.model", "text-embedding-ada-002");
            this.dimension = Integer.parseInt(config.getProperty("embedding.dimension", "1536"));
        }
    }
    
    // =====================================================
    // 核心方法：获取文本的向量表示
    // =====================================================
    
    /**
     * 获取单个文本的embedding向量
     * 
     * @param text 输入文本
     * @return 浮点数列表表示的向量（维度由模型决定）
     * @throws AIException 如果API调用失败
     */
    public List<Float> embed(String text) throws AIException {
        if (text == null || text.trim().isEmpty()) {
            return null;
        }
        
        // 检查缓存
        String cacheKey = text.hashCode() + "_" + text.length();
        if (textEmbeddingCache.containsKey(cacheKey)) {
            logger.debug("命中Embedding缓存: {}", cacheKey.substring(0, Math.min(20, cacheKey.length())));
            return textEmbeddingCache.get(cacheKey);
        }
        
        try {
            List<String> texts = Collections.singletonList(text);
            List<List<Float>> embeddings = batchEmbed(texts);
            
            if (embeddings != null && !embeddings.isEmpty()) {
                List<Float> result = embeddings.get(0);
                
                // 加入缓存
                textEmbeddingCache.put(cacheKey, result);
                
                return result;
            }
            
            return null;
            
        } catch (Exception e) {
            logger.error("Embedding生成失败: {}", e.getMessage());
            throw new AIException("Embedding生成失败: " + e.getMessage(), e);
        }
    }
    
    /**
     * 批量获取多个文本的embedding（更高效）
     * 
     * @param texts 文本列表
     * @return 二维列表，每个子列表是一个文本的向量
     * @throws AIException 如果API调用失败
     */
    public List<List<Float>> batchEmbed(List<String> texts) throws AIException {
        if (texts == null || texts.isEmpty()) {
            return new ArrayList<>();
        }
        
        // 过滤空文本并限制单次请求数量
        List<String> validTexts = new ArrayList<>();
        for (String text : texts) {
            if (text != null && !text.trim().isEmpty()) {
                validTexts.add(text.trim());
            }
        }
        
        if (validTexts.isEmpty()) {
            return new ArrayList<>();
        }
        
        // 单次请求最多处理25条（API限制）
        int batchSize = 25;
        List<List<Float>> allEmbeddings = new ArrayList<>();
        
        for (int i = 0; i < validTexts.size(); i += batchSize) {
            int end = Math.min(i + batchSize, validTexts.size());
            List<String> batch = validTexts.subList(i, end);
            
            List<List<Float>> batchResult = callEmbeddingApi(batch);
            if (batchResult != null) {
                allEmbeddings.addAll(batchResult);
            }
            
            // 避免请求过快
            if (i + batchSize < validTexts.size()) {
                try {
                    Thread.sleep(100);  // 100ms间隔
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }
        
        return allEmbeddings;
    }
    
    /**
     * 调用Embedding API
     */
    private List<List<Float>> callEmbeddingApi(List<String> texts) throws AIException {
        try {
            // 构建请求体
            JsonObject requestBody = new JsonObject();
            requestBody.addProperty("model", model);
            
            JsonArray inputArray = new JsonArray();
            for (String text : texts) {
                inputArray.add(text);
            }
            requestBody.add("input", inputArray);
            
            // 构建HTTP请求
            MediaType JSON = MediaType.get("application/json; charset=utf-8");
            RequestBody body = RequestBody.create(requestBody.toString(), JSON);
            
            Request request = new Request.Builder()
                .url(apiUrl)
                .post(body)
                .addHeader("Authorization", "Bearer " + apiKey)
                .addHeader("Content-Type", "application/json")
                .build();
            
            logger.debug("调用Embedding API: {}, 文本数量: {}", apiUrl, texts.size());
            
            try (Response response = httpClient.newCall(request).execute()) {
                if (!response.isSuccessful()) {
                    String errorBody = response.body() != null ? response.body().string() : "";
                    logger.error("Embedding API错误 [{}]: {}", response.code(), errorBody);
                    throw new AIException("Embedding API失败 [" + response.code() + "]: " + errorBody);
                }
                
                String responseBody = response.body().string();
                return parseEmbeddingResponse(responseBody);
            }
            
        } catch (IOException e) {
            logger.error("Embedding网络请求异常", e);
            throw new AIException("网络异常: " + e.getMessage(), e);
        }
    }
    
    /**
     * 解析Embedding API响应
     */
    private List<List<Float>> parseEmbeddingResponse(String responseBody) {
        JsonObject json = gson.fromJson(responseBody, JsonObject.class);
        
        if (json.has("data")) {
            JsonArray dataArray = json.getAsJsonArray("data");
            List<List<Float>> embeddings = new ArrayList<>();
            
            for (int i = 0; i < dataArray.size(); i++) {
                JsonObject item = dataArray.get(i).getAsJsonObject();
                if (item.has("embedding")) {
                    JsonArray embeddingArray = item.getAsJsonArray("embedding");
                    List<Float> vector = new ArrayList<>();
                    
                    for (int j = 0; j < embeddingArray.size(); j++) {
                        vector.add(embeddingArray.get(j).getAsFloat());
                    }
                    
                    embeddings.add(vector);
                }
            }
            
            logger.debug("成功解析 {} 个embedding向量, 维度: {}", 
                embeddings.size(), embeddings.isEmpty() ? 0 : embeddings.get(0).size());
            
            return embeddings;
        }
        
        // 错误响应
        if (json.has("error")) {
            JsonObject error = json.getAsJsonObject("error");
            String errorMsg = error.has("message") ? error.get("message").getAsString() : "未知错误";
            logger.error("Embedding API返回错误: {}", errorMsg);
        }
        
        return new ArrayList<>();
    }
    
    // =====================================================
    // 工具方法
    // =====================================================
    
    /**
     * 计算两个向量的余弦相似度
     * 返回值范围 [-1, 1]，越接近1表示越相似
     */
    public static double cosineSimilarity(List<Float> vecA, List<Float> vecB) {
        if (vecA == null || vecB == null || vecA.size() != vecB.size()) {
            return 0.0;
        }
        
        double dotProduct = 0.0;
        double normA = 0.0;
        double normB = 0.0;
        
        for (int i = 0; i < vecA.size(); i++) {
            dotProduct += vecA.get(i) * vecB.get(i);
            normA += Math.pow(vecA.get(i), 2);
            normB += Math.pow(vecB.get(i), 2);
        }
        
        double denominator = Math.sqrt(normA) * Math.sqrt(normB);
        if (denominator == 0.0) {
            return 0.0;
        }
        
        return dotProduct / denominator;
    }
    
    /**
     * 计算欧氏距离（可选的距离度量方式）
     */
    public static double euclideanDistance(List<Float> vecA, List<Float> vecB) {
        if (vecA == null || vecB == null || vecA.size() != vecB.size()) {
            return Double.MAX_VALUE;
        }
        
        double sum = 0.0;
        for (int i = 0; i < vecA.size(); i++) {
            double diff = vecA.get(i) - vecB.get(i);
            sum += diff * diff;
        }
        
        return Math.sqrt(sum);
    }
    
    /**
     * 获取当前配置的维度
     */
    public int getDimension() {
        return dimension;
    }
    
    /**
     * 获取当前Provider
     */
    public String getProvider() {
        return provider;
    }
    
    /**
     * 获取当前模型名称
     */
    public String getModel() {
        return model;
    }
    
    /**
     * 清除缓存（在配置变更时调用）
     */
    public void clearCache() {
        textEmbeddingCache.clear();
        logger.info("Embedding缓存已清除");
    }
    
    /**
     * 测试连通性
     */
    public boolean testConnection() {
        try {
            List<Float> testVec = embed("测试连接");
            return testVec != null && !testVec.isEmpty();
        } catch (Exception e) {
            logger.error("Embedding服务连接测试失败", e);
            return false;
        }
    }

    /**
     * 内部异常类
     */
    public static class AIException extends Exception {
        public AIException(String message) { super(message); }
        public AIException(String message, Throwable cause) { super(message, cause); }
    }
}
