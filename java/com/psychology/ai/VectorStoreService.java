package com.psychology.ai;

import com.google.gson.Gson;
import com.psychology.dao.ArticleDao;
import com.psychology.entity.Article;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 向量存储服务层 - 管理向量数据的存取
 * 
 * 支持两种模式：
 * 1. **MySQL原生模式**（默认）：将向量存储为JSON字段，应用层计算相似度
 *    - 优点：无需额外基础设施，部署简单
 *    - 缺点：大数据量时性能有限
 * 
 * 2. **专业向量数据库模式**（Milvus/Pinecone）：
 *    - 优点：高性能、支持百万级向量、近似搜索
 *    - 缺点：需要额外部署和维护
 *
 * 核心功能：
 * - 文章向量CRUD（用于RAG知识库）
 * - 对话消息向量存储（用于历史问题语义搜索）
 * - 余弦相似度计算和Top-K检索
 */
public class VectorStoreService {
    private static final Logger logger = LoggerFactory.getLogger(VectorStoreService.class);
    
    private static VectorStoreService instance;
    private final Gson gson = new Gson();
    private final EmbeddingService embeddingService;
    private Properties config;
    
    // 存储模式
    private String storageMode;  // MYSQL/MILVUS/PINECONE
    
    public synchronized static VectorStoreService getInstance() {
        if (instance == null) {
            instance = new VectorStoreService();
        }
        return instance;
    }
    
    private VectorStoreService() {
        this.embeddingService = EmbeddingService.getInstance();
        this.config = loadConfig();
        this.storageMode = config.getProperty("vector.db.type", "MYSQL").toUpperCase();
        
        logger.info("VectorStoreService初始化完成 - 存储模式: {}", storageMode);
    }
    
    private Properties loadConfig() {
        Properties props = new Properties();
        try {
            props.load(getClass().getClassLoader().getResourceAsStream("ai.properties"));
        } catch (Exception e) {
            logger.warn("加载配置失败", e);
        }
        return props;
    }
    
    // =====================================================
    // 文章向量管理（RAG知识库）
    // =====================================================
    
    /**
     * 为单个文章创建向量嵌入并存储
     * 
     * @param article 文章对象
     * @return 是否成功
     */
    public boolean indexArticle(Article article) {
        if (article == null || article.getId() == null) {
            return false;
        }
        
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            // 检查是否已存在
            if (isArticleIndexed(conn, article.getId())) {
                logger.info("文章{}已存在向量，跳过", article.getId());
                return true;
            }
            
            // 准备文本内容（标题+摘要+正文前2000字）
            String textContent = prepareArticleText(article);
            
            // 文本分块（每块不超过500token约等于750字符）
            List<String> chunks = splitTextIntoChunks(textContent, 750);
            
            // 批量生成embedding
            List<List<Float>> embeddings = embeddingService.batchEmbed(chunks);
            
            if (embeddings == null || embeddings.size() != chunks.size()) {
                logger.error("文章{} embedding生成数量不匹配", article.getId());
                return false;
            }
            
            // 插入向量数据
            PreparedStatement pstmt = conn.prepareStatement(
                "INSERT INTO article_vector (article_id, chunk_index, chunk_text, embedding, embedding_model) " +
                "VALUES (?, ?, ?, ?, ?)");
            
            for (int i = 0; i < chunks.size(); i++) {
                pstmt.setLong(1, article.getId());
                pstmt.setInt(2, i);
                pstmt.setString(3, chunks.get(i));
                pstmt.setString(4, gson.toJson(embeddings.get(i)));
                pstmt.setString(5, embeddingService.getProvider() + "-" + embeddingService.getModel());
                pstmt.addBatch();
            }
            
            pstmt.executeBatch();
            pstmt.close();
            
            logger.info("文章{}向量化完成，共 {} 个分块", article.getId(), chunks.size());
            return true;
            
        } catch (Exception e) {
            logger.error("文章向量化失败: {}", e.getMessage(), e);
            return false;
        } finally {
            closeConnection(conn);
        }
    }
    
    /**
     * 批量索引所有已发布的文章（用于首次初始化或全量重建）
     * 
     * @return 统计信息Map
     */
    public Map<String, Object> indexAllArticles() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("total", 0);
        stats.put("success", 0);
        stats.put("failed", 0);
        stats.put("skipped", 0);
        
        ArticleDao articleDao = new ArticleDao();
        List<Article> articles = articleDao.findAllPublished();
        
        stats.put("total", articles.size());
        
        for (Article article : articles) {
            try {
                if (indexArticle(article)) {
                    stats.put("success", (Integer)stats.get("success") + 1);
                } else {
                    stats.put("failed", (Integer)stats.get("failed") + 1);
                }
            } catch (Exception e) {
                stats.put("failed", (Integer)stats.get("failed") + 1);
                logger.error("索引文章{}失败: {}", article.getId(), e.getMessage());
            }
        }
        
        logger.info("全量文章向量化完成 - 总计:{}, 成功:{}, 失败:{}, 跳过:{}", 
            stats.get("total"), stats.get("success"), stats.get("failed"), stats.get("skipped"));
        
        return stats;
    }
    
    /**
     * 从向量库中删除某篇文章的向量数据
     */
    public boolean removeArticle(Long articleId) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            PreparedStatement pstmt = conn.prepareStatement(
                "DELETE FROM article_vector WHERE article_id = ?");
            pstmt.setLong(1, articleId);
            int rows = pstmt.executeUpdate();
            pstmt.close();
            
            logger.info("删除文章{}的向量数据，影响行数: {}", articleId, rows);
            return true;
            
        } catch (Exception e) {
            logger.error("删除文章向量失败: {}", e.getMessage());
            return false;
        } finally {
            closeConnection(conn);
        }
    }
    
    // =====================================================
    // 对话消息向量（语义搜索历史问题）
    // =====================================================
    
    /**
     * 为聊天消息创建向量并存储
     * 
     * @param userId 用户ID
     * @param sessionId 会话ID
     * @param messageId 消息ID
     * @param messageText 消息文本
     * @param senderType 发送者类型(USER/AI)
     * @return 是否成功
     */
    public boolean indexChatMessage(int userId, long sessionId, long messageId, 
                                     String messageText, String senderType) {
        if (messageText == null || messageText.trim().isEmpty()) {
            return false;
        }
        
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            // 生成embedding
            List<Float> embedding = embeddingService.embed(messageText);
            if (embedding == null) {
                return false;
            }
            
            // 存储
            PreparedStatement pstmt = conn.prepareStatement(
                "INSERT INTO chat_message_vector (message_id, user_id, session_id, message_text, sender_type, embedding, embedding_model) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?) " +
                "ON DUPLICATE KEY UPDATE message_text=?, embedding=?");
            
            pstmt.setLong(1, messageId);
            pstmt.setInt(2, userId);
            pstmt.setLong(3, sessionId);
            pstmt.setString(4, messageText);
            pstmt.setString(5, senderType);
            pstmt.setString(6, gson.toJson(embedding));
            pstmt.setString(7, embeddingService.getProvider() + "-" + embeddingService.getModel());
            pstmt.setString(8, messageText);
            pstmt.setString(9, gson.toJson(embedding));
            
            pstmt.executeUpdate();
            pstmt.close();
            
            return true;
            
        } catch (Exception e) {
            logger.error("索引聊天消息向量失败: {}", e.getMessage());
            return false;
        } finally {
            closeConnection(conn);
        }
    }
    
    /**
     * 语义搜索用户的历史问题（找到相似的历史提问）
     * 
     * @param userId 用户ID
     * @param query 查询文本
     * @param topK 返回最相似的K个结果
     * @param threshold 相似度阈值（0-1，低于此值不返回）
     * @return 按相似度降序排列的搜索结果列表
     */
    public List<SimilarityResult> searchSimilarUserMessages(int userId, String query, int topK, double threshold) {
        List<SimilarityResult> results = new ArrayList<>();
        
        try {
            // 1. 生成查询向量
            List<Float> queryVector = embeddingService.embed(query);
            if (queryVector == null) {
                return results;
            }
            
            Connection conn = getDatabaseConnection();
            
            // 2. 查询该用户的所有消息向量（仅用户消息）
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(
                "SELECT message_id, session_id, message_text, sender_type, embedding " +
                "FROM chat_message_vector " +
                "WHERE user_id = " + userId + " AND sender_type = 'USER' " +
                "ORDER BY created_at DESC LIMIT 500");  // 限制最近500条
            
            // 3. 计算相似度并排序
            List<SimilarityResult> allResults = new ArrayList<>();
            while (rs.next()) {
                String embeddingJson = rs.getString("embedding");
                List<Float> storedVector = gson.fromJson(embeddingJson, 
                    new com.google.gson.reflect.TypeToken<List<Float>>(){}.getType());
                
                double similarity = EmbeddingService.cosineSimilarity(queryVector, storedVector);
                
                if (similarity >= threshold) {
                    SimilarityResult result = new SimilarityResult();
                    result.setId(rs.getLong("message_id"));
                    result.setSessionId(rs.getLong("session_id"));
                    result.setContent(rs.getString("message_text"));
                    result.setSimilarity(similarity);
                    allResults.add(result);
                }
            }
            
            rs.close();
            stmt.close();
            
            // 4. 排序并截取Top-K
            allResults.sort((a, b) -> Double.compare(b.getSimilarity(), a.getSimilarity()));
            results = allResults.subList(0, Math.min(topK, allResults.size()));
            
            closeConnection(conn);
            
        } catch (Exception e) {
            logger.error("语义搜索历史消息失败: {}", e.getMessage(), e);
        }
        
        return results;
    }
    
    // =====================================================
    // RAG语义检索（从知识库中检索相关文章）
    // =====================================================
    
    /**
     * 基于用户查询检索最相关的文章片段（用于RAG增强）
     * 
     * @param query 用户问题或描述
     * @param topK 返回最相关的K个片段
     * @param threshold 相似度阈值
     * @return RAG检索结果列表
     */
    public List<RAGResult> searchRelevantArticles(String query, int topK, double threshold) {
        List<RAGResult> results = new ArrayList<>();
        
        try {
            // 1. 生成查询向量
            List<Float> queryVector = embeddingService.embed(query);
            if (queryVector == null) {
                return results;
            }
            
            Connection conn = getDatabaseConnection();
            
            // 2. 查询所有文章向量
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(
                "SELECT av.article_id, av.chunk_index, av.chunk_text, a.title, a.summary, av.embedding " +
                "FROM article_vector av " +
                "LEFT JOIN article a ON av.article_id = a.id " +
                "WHERE a.status = 'PUBLISHED' " +
                "ORDER BY av.created_at DESC LIMIT 2000");  // 限制数量避免内存爆炸
            
            // 3. 计算相似度
            List<RAGResult> allResults = new ArrayList<>();
            while (rs.next()) {
                String embeddingJson = rs.getString("embedding");
                List<Float> storedVector = gson.fromJson(embeddingJson, 
                    new com.google.gson.reflect.TypeToken<List<Float>>(){}.getType());
                
                double similarity = EmbeddingService.cosineSimilarity(queryVector, storedVector);
                
                if (similarity >= threshold) {
                    RAGResult result = new RAGResult();
                    result.setArticleId(rs.getLong("article_id"));
                    result.setChunkIndex(rs.getInt("chunk_index"));
                    result.setChunkText(rs.getString("chunk_text"));
                    result.setArticleTitle(rs.getString("title"));
                    result.setSummary(rs.getString("summary"));
                    result.setSimilarity(similarity);
                    allResults.add(result);
                }
            }
            
            rs.close();
            stmt.close();
            
            // 4. 按相似度降序排列，取Top-K
            allResults.sort((a, b) -> Double.compare(b.getSimilarity(), a.getSimilarity()));
            results = allResults.subList(0, Math.min(topK, allResults.size()));
            
            closeConnection(conn);
            
            logger.info("RAG检索完成 - 查询:'{}...', 命中: {} 片段", 
                query.substring(0, Math.min(20, query.length())), results.size());
            
        } catch (Exception e) {
            logger.error("RAG文章检索失败: {}", e.getMessage(), e);
        }
        
        return results;
    }
    
    // =====================================================
    // 私有辅助方法
    // =====================================================
    
    /**
     * 准备文章文本内容（用于embedding）
     */
    private String prepareArticleText(Article article) {
        StringBuilder sb = new StringBuilder();
        
        sb.append("标题：").append(article.getTitle()).append("\n\n");
        
        if (article.getSummary() != null && !article.getSummary().isEmpty()) {
            sb.append("摘要：").append(article.getSummary()).append("\n\n");
        }
        
        if (article.getContent() != null && !article.getContent().isEmpty()) {
            // 正文截取前2000字（避免超长文本）
            String content = article.getContent().replaceAll("<[^>]+>", "");  // 去除HTML标签
            if (content.length() > 2000) {
                content = content.substring(0, 2000);
            }
            sb.append("正文：").append(content);
        }
        
        return sb.toString();
    }
    
    /**
     * 将长文本分割成多个chunk
     * 按段落分割，确保每个chunk不超过maxLength
     */
    private List<String> splitTextIntoChunks(String text, int maxLength) {
        List<String> chunks = new ArrayList<>();
        
        if (text == null || text.isEmpty()) {
            return chunks;
        }
        
        // 先按段落分割
        String[] paragraphs = text.split("\n+");
        
        StringBuilder currentChunk = new StringBuilder();
        for (String paragraph : paragraphs) {
            if (currentChunk.length() + paragraph.length() > maxLength) {
                if (currentChunk.length() > 0) {
                    chunks.add(currentChunk.toString().trim());
                    currentChunk = new StringBuilder();
                }
                
                // 如果单个段落就超过maxLength，按句子强制分割
                if (paragraph.length() > maxLength) {
                    String[] sentences = paragraph.split("[。！？!?.]");
                    for (String sentence : sentences) {
                        if (currentChunk.length() + sentence.length() > maxLength && currentChunk.length() > 0) {
                            chunks.add(currentChunk.toString().trim());
                            currentChunk = new StringBuilder();
                        }
                        currentChunk.append(sentence).append("。");
                    }
                } else {
                    currentChunk.append(paragraph).append("\n");
                }
            } else {
                currentChunk.append(paragraph).append("\n");
            }
        }
        
        // 最后一个chunk
        if (currentChunk.length() > 0) {
            chunks.add(currentChunk.toString().trim());
        }
        
        return chunks;
    }
    
    /**
     * 检查文章是否已经被索引
     */
    private boolean isArticleIndexed(Connection conn, Long articleId) throws SQLException {
        PreparedStatement pstmt = conn.prepareStatement(
            "SELECT COUNT(*) FROM article_vector WHERE article_id = ?");
        pstmt.setLong(1, articleId);
        ResultSet rs = pstmt.executeQuery();
        rs.next();
        int count = rs.getInt(1);
        rs.close();
        pstmt.close();
        return count > 0;
    }
    
    /**
     * 获取数据库连接
     */
    private Connection getDatabaseConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            String url = "jdbc:mysql://localhost:3306/psychology?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true";
            String username = "root";
            String password = "123456";  // TODO: 从配置文件读取
            return DriverManager.getConnection(url, username, password);
        } catch (ClassNotFoundException e) {
            throw new SQLException("数据库驱动未找到", e);
        }
    }
    
    /**
     * 关闭数据库连接
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
     * 相似度搜索结果
     */
    public static class SimilarityResult {
        private Long id;
        private Long sessionId;
        private String content;
        private double similarity;
        
        // Getters and Setters
        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public Long getSessionId() { return sessionId; }
        public void setSessionId(Long sessionId) { this.sessionId = sessionId; }
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        public double getSimilarity() { return similarity; }
        public void setSimilarity(double similarity) { this.similarity = similarity; }
        
        @Override
        public String toString() {
            return String.format("SimilarityResult{similarity=%.3f, content=%s...}", 
                similarity, content != null ? content.substring(0, Math.min(30, content.length())) : "null");
        }
    }
    
    /**
     * RAG检索结果
     */
    public static class RAGResult {
        private Long articleId;
        private int chunkIndex;
        private String chunkText;
        private String articleTitle;
        private String summary;
        private double similarity;
        
        // Getters and Setters
        public Long getArticleId() { return articleId; }
        public void setArticleId(Long articleId) { this.articleId = articleId; }
        public int getChunkIndex() { return chunkIndex; }
        public void setChunkIndex(int chunkIndex) { this.chunkIndex = chunkIndex; }
        public String getChunkText() { return chunkText; }
        public void setChunkText(String chunkText) { this.chunkText = chunkText; }
        public String getArticleTitle() { return articleTitle; }
        public void setArticleTitle(String articleTitle) { this.articleTitle = articleTitle; }
        public String getSummary() { return summary; }
        public void setSummary(String summary) { this.summary = summary; }
        public double getSimilarity() { return similarity; }
        public void setSimilarity(double similarity) { this.similarity = similarity; }
        
        /**
         * 格式化为可注入Prompt的文本
         */
        public String toContextText() {
            return String.format("【参考资料：%s】(相似度:%.2f)\n%s\n", 
                articleTitle, similarity, chunkText);
        }
    }
}
