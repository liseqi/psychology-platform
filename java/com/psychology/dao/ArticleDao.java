package com.psychology.dao;

import com.psychology.entity.Article;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.*;

/**
 * 科普文章DAO
 */
public class ArticleDao {

    /**
     * 查询所有已发布的文章（用于RAG知识库构建等场景）
     */
    public List<Article> findAllPublished() {
        String sql = "SELECT a.*, c.name as category_name, u.real_name as author_name FROM article a " +
                "LEFT JOIN article_category c ON a.category_id = c.id " +
                "LEFT JOIN sys_user u ON a.author_id = u.id " +
                "WHERE a.status='PUBLISHED' ORDER BY a.published_at DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Article> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractArticle(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 查询已发布的文章列表（学生浏览用）
     */
    public List<Article> findPublished(int page, int pageSize, Integer categoryId, String keyword) {
        StringBuilder sql = new StringBuilder(
            "SELECT a.*, c.name as category_name, u.real_name as author_name FROM article a " +
            "LEFT JOIN article_category c ON a.category_id = c.id " +
            "LEFT JOIN sys_user u ON a.author_id = u.id " +
            "WHERE a.status='PUBLISHED' ");
        
        List<Object> params = new ArrayList<>();
        
        if (categoryId != null) {
            sql.append("AND a.category_id=? ");
            params.add(categoryId);
        }
        if (keyword != null && !keyword.isEmpty()) {
            sql.append("AND (a.title LIKE ? OR a.summary LIKE ?) ");
            params.add("%" + keyword + "%");
            params.add("%" + keyword + "%");
        }

        sql.append("ORDER BY a.published_at DESC LIMIT ?,?");
        params.add((page - 1) * pageSize);
        params.add(pageSize);

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Article> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractArticle(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 管理员查询所有文章（含所有状态）
     */
    public List<Article> findForManage(int page, int pageSize, String status) {
        return findForManage(page, pageSize, status, null);
    }

    public List<Article> findForManage(int page, int pageSize, String status, String source) {
        StringBuilder sql = new StringBuilder(
            "SELECT a.*, c.name as category_name, u.real_name as author_name FROM article a " +
            "LEFT JOIN article_category c ON a.category_id = c.id " +
            "LEFT JOIN sys_user u ON a.author_id = u.id WHERE 1=1 ");

        List<Object> params = new ArrayList<>();

        if (!"ALL".equals(status)) {
            sql.append("AND a.status=? ");
            params.add(status);
        }

        if (source != null && !source.isEmpty() && !"ALL".equals(source)) {
            if ("自建".equals(source)) {
                sql.append("AND (a.source_name IS NULL OR a.source_name='' OR a.source_name='自建') ");
            } else {
                sql.append("AND a.source_name=? ");
                params.add(source);
            }
        }
        
        sql.append("ORDER BY a.created_at DESC LIMIT ?,?");
        params.add((page - 1) * pageSize);
        params.add(pageSize);
        
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Article> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractArticle(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    public Article findById(Long id) {
        String sql = "SELECT a.*, c.name as category_name, u.real_name as author_name FROM article a " +
                "LEFT JOIN article_category c ON a.category_id = c.id " +
                "LEFT JOIN sys_user u ON a.author_id = u.id WHERE a.id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractArticle(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    public long add(Article article) {
        String sql = "INSERT INTO article (title, category_id, author_id, summary, cover_image, " +
                "content, source_url, source_name, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, article.getTitle());
            ps.setInt(2, article.getCategoryId());
            if (article.getAuthorId() != null) {
                ps.setInt(3, article.getAuthorId());
            } else {
                ps.setNull(3, Types.INTEGER);
            }
            ps.setString(4, article.getSummary());
            ps.setString(5, article.getCoverImage());
            ps.setString(6, article.getContent());
            ps.setString(7, article.getSourceUrl());
            ps.setString(8, article.getSourceName());
            ps.setString(9, article.getStatus());

            int rows = ps.executeUpdate();
            if (rows > 0) {
                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    return generatedKeys.getLong(1);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return 0;
    }

    /**
     * 根据来源URL查重（避免重复抓取）
     */
    public boolean existsBySourceUrl(String sourceUrl) {
        if (sourceUrl == null || sourceUrl.isEmpty()) return false;
        String sql = "SELECT COUNT(*) FROM article WHERE source_url = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, sourceUrl);
            rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1) > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return false;
    }

    /**
     * 批量添加外部文章（去重后插入）
     */
    public int addExternalArticle(Article article) {
        if (article.getSourceUrl() != null && !article.getSourceUrl().isEmpty()) {
            if (existsBySourceUrl(article.getSourceUrl())) {
                return -1; // 已存在，跳过
            }
        }
        return (int) add(article);
    }

    public boolean reviewArticle(Long id, String status, Integer reviewerId, String note) {
        String sql = "UPDATE article SET status=?, reviewer_id=?, review_note=?, " +
                (status.equals("PUBLISHED") ? "published_at=NOW(), " : "") +
                "updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, status);
            ps.setInt(2, reviewerId);
            ps.setString(3, note);
            ps.setLong(4, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    public boolean incrementViewCount(Long id) {
        String sql = "UPDATE article SET view_count=view_count+1 WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    public boolean toggleLike(Long articleId, Integer userId) {
        // 简化实现：实际应使用点赞记录表
        return true;
    }

    public boolean addComment(Long articleId, Integer userId, Long parentId, String content) {
        String sql = "INSERT INTO article_comment (article_id, user_id, parent_id, content, status) " +
                "VALUES (?, ?, ?, ?, 'PENDING')";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, articleId);
            ps.setInt(2, userId);
            if (parentId != null) {
                ps.setLong(3, parentId);
            } else {
                ps.setNull(3, Types.BIGINT);
            }
            ps.setString(4, content);

            int rows = ps.executeUpdate();
            if (rows > 0) {
                // 更新文章评论数
                updateCommentCount(articleId, true);
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    private void updateCommentCount(Long articleId, boolean increment) {
        String sql = increment 
            ? "UPDATE article SET comment_count=comment_count+1 WHERE id=?"
            : "UPDATE article SET comment_count=GREATEST(0, comment_count-1) WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, articleId);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
    }

    public List<Map<String, Object>> findCommentsByArticle(Long articleId) {
        String sql = "SELECT ac.*, u.real_name as user_name FROM article_comment ac " +
                "LEFT JOIN sys_user u ON ac.user_id = u.id " +
                "WHERE ac.article_id=? AND ac.status='APPROVED' ORDER BY ac.created_at ASC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Map<String, Object>> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, articleId);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("id", rs.getLong("id"));
                item.put("userId", rs.getInt("user_id"));
                item.put("userName", rs.getString("user_name")); // 可脱敏
                item.put("parentId", rs.getObject("parent_id"));
                item.put("content", rs.getString("content"));
                item.put("likeCount", rs.getInt("like_count"));
                item.put("createdAt", rs.getTimestamp("created_at"));
                list.add(item);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    public List<Map<String, Object>> findAllCategories() {
        String sql = "SELECT * FROM article_category WHERE status=1 ORDER BY sort_order";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Map<String, Object>> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("id", rs.getInt("id"));
                item.put("name", rs.getString("name"));
                item.put("description", rs.getString("description"));
                list.add(item);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 统计各状态文章数量
     */
    public Map<String, Integer> countByStatus() {
        String sql = "SELECT status, COUNT(*) as cnt FROM article GROUP BY status";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Map<String, Integer> result = new HashMap<>();
        result.put("PENDING_REVIEW", 0);
        result.put("PUBLISHED", 0);
        result.put("REJECTED", 0);
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                String status = rs.getString("status");
                int count = rs.getInt("cnt");
                if (status != null) {
                    result.put(status, count);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return result;
    }

    private Article extractArticle(ResultSet rs) throws SQLException {
        Article a = new Article();
        a.setId(rs.getLong("id"));
        a.setTitle(rs.getString("title"));
        Object cid = rs.getObject("category_id");
        if (cid != null) a.setCategoryId(((Number) cid).intValue());
        Object aid = rs.getObject("author_id");
        if (aid != null) a.setAuthorId(((Number) aid).intValue());
        a.setSummary(rs.getString("summary"));
        a.setCoverImage(rs.getString("cover_image"));
        a.setContent(rs.getString("content"));
        try { a.setSourceUrl(rs.getString("source_url")); } catch (Exception e) {}
        try { a.setSourceName(rs.getString("source_name")); } catch (Exception e) {}
        Object vc = rs.getObject("view_count");
        if (vc != null) a.setViewCount(((Number) vc).intValue());
        Object lc = rs.getObject("like_count");
        if (lc != null) a.setLikeCount(((Number) lc).intValue());
        Object cc = rs.getObject("comment_count");
        if (cc != null) a.setCommentCount(((Number) cc).intValue());
        a.setStatus(rs.getString("status"));
        Object revId = rs.getObject("reviewer_id");
        if (revId != null) a.setReviewerId(((Number) revId).intValue());
        a.setReviewNote(rs.getString("review_note"));
        a.setPublishedAt(rs.getTimestamp("published_at"));
        a.setCreatedAt(rs.getTimestamp("created_at"));
        a.setUpdatedAt(rs.getTimestamp("updated_at"));

        try { a.setCategoryName(rs.getString("category_name")); } catch (Exception e) {}
        try { a.setAuthorName(rs.getString("author_name")); } catch (Exception e) {}

        return a;
    }
}
