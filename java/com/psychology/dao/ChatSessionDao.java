package com.psychology.dao;

import com.psychology.entity.ChatSession;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * AI树洞会话DAO
 */
public class ChatSessionDao {

    public long add(ChatSession session) {
        String sql = "INSERT INTO chat_session (user_id, title) VALUES (?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, session.getUserId());
            ps.setString(2, session.getTitle());

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

    public List<ChatSession> findByUserId(Integer userId, int page, int pageSize) {
        String sql = "SELECT * FROM chat_session WHERE user_id=? ORDER BY updated_at DESC LIMIT ?,?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<ChatSession> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractSession(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    public ChatSession findById(Long id) {
        String sql = "SELECT * FROM chat_session WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractSession(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    public boolean updateEmotionTags(Long sessionId, String emotionTags, Integer isHighRisk) {
        String sql = "UPDATE chat_session SET emotion_tags=?, is_high_risk=?, " +
                "message_count=message_count+1, updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, emotionTags);
            ps.setInt(2, isHighRisk);
            ps.setLong(3, sessionId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    public boolean markAlertTriggered(Long sessionId) {
        String sql = "UPDATE chat_session SET alert_triggered=1 WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, sessionId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 更新会话标题
     */
    public boolean updateTitle(Long sessionId, String title) {
        String sql = "UPDATE chat_session SET title=?, updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, title);
            ps.setLong(2, sessionId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    private ChatSession extractSession(ResultSet rs) throws SQLException {
        ChatSession s = new ChatSession();
        s.setId(rs.getLong("id"));
        s.setUserId(rs.getInt("user_id"));
        s.setTitle(rs.getString("title"));
        s.setEmotionTags(rs.getString("emotion_tags"));
        Object hr = rs.getObject("is_high_risk");
        if (hr != null) s.setHighRisk(((Number) hr).intValue());
        Object at = rs.getObject("alert_triggered");
        if (at != null) s.setAlertTriggered(((Number) at).intValue());
        Object mc = rs.getObject("message_count");
        if (mc != null) s.setMessageCount(((Number) mc).intValue());
        s.setCreatedAt(rs.getTimestamp("created_at"));
        s.setUpdatedAt(rs.getTimestamp("updated_at"));
        return s;
    }
}
