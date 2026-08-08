package com.psychology.dao;

import com.psychology.entity.ChatMessage;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * AI树洞消息DAO
 */
public class ChatMessageDao {

    public long add(ChatMessage message) {
        String sql = "INSERT INTO chat_message (session_id, sender_type, content, emotion_tag) " +
                "VALUES (?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, message.getSessionId());
            ps.setString(2, message.getSenderType());
            ps.setString(3, message.getContent());
            ps.setString(4, message.getEmotionTag());

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

    public List<ChatMessage> findBySessionId(Long sessionId) {
        String sql = "SELECT * FROM chat_message WHERE session_id=? ORDER BY created_at ASC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<ChatMessage> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, sessionId);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractMessage(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    private ChatMessage extractMessage(ResultSet rs) throws SQLException {
        ChatMessage m = new ChatMessage();
        m.setId(rs.getLong("id"));
        m.setSessionId(rs.getLong("session_id"));
        m.setSenderType(rs.getString("sender_type"));
        m.setContent(rs.getString("content"));
        m.setEmotionTag(rs.getString("emotion_tag"));
        Object enc = rs.getObject("is_encrypted");
        if (enc != null) m.setEncrypted(((Number) enc).intValue());
        m.setCreatedAt(rs.getTimestamp("created_at"));
        return m;
    }
}
