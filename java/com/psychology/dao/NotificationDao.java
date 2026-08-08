package com.psychology.dao;

import com.psychology.entity.Notification;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 站内消息通知DAO
 */
public class NotificationDao {

    /**
     * 添加通知
     */
    public boolean add(Notification notification) {
        String sql = "INSERT INTO notification (receiver_id, sender_id, title, content, " +
                "type, related_type, related_id) VALUES (?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, notification.getReceiverId());
            if (notification.getSenderId() != null) {
                ps.setInt(2, notification.getSenderId());
            } else {
                ps.setNull(2, Types.INTEGER);
            }
            ps.setString(3, notification.getTitle());
            ps.setString(4, notification.getContent());
            ps.setString(5, notification.getType());
            ps.setString(6, notification.getRelatedType());
            if (notification.getRelatedId() != null) {
                ps.setLong(7, notification.getRelatedId());
            } else {
                ps.setNull(7, Types.BIGINT);
            }
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 查询用户的通知列表
     */
    public List<Notification> findByReceiver(Integer receiverId, int page, int pageSize) {
        String sql = "SELECT * FROM notification WHERE receiver_id=? " +
                "ORDER BY created_at DESC LIMIT ?,?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Notification> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, receiverId);
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractNotification(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 标记为已读
     */
    public boolean markAsRead(Long id, Integer receiverId) {
        String sql = "UPDATE notification SET is_read=1, read_at=NOW() WHERE id=? AND receiver_id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            ps.setInt(2, receiverId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 标记全部已读
     */
    public boolean markAllAsRead(Integer receiverId) {
        String sql = "UPDATE notification SET is_read=1, read_at=NOW() " +
                "WHERE receiver_id=? AND is_read=0";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, receiverId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 统计未读数量
     */
    public long countUnread(Integer receiverId) {
        String sql = "SELECT COUNT(*) FROM notification WHERE receiver_id=? AND is_read=0";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, receiverId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getLong(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return 0;
    }

    private Notification extractNotification(ResultSet rs) throws SQLException {
        Notification n = new Notification();
        n.setId(rs.getLong("id"));
        n.setReceiverId(rs.getInt("receiver_id"));
        Object sid = rs.getObject("sender_id");
        if (sid != null) n.setSenderId(((Number) sid).intValue());
        n.setTitle(rs.getString("title"));
        n.setContent(rs.getString("content"));
        n.setType(rs.getString("type"));
        Object readObj = rs.getObject("is_read");
        if (readObj != null) n.setRead(((Number) readObj).intValue());
        n.setRelatedType(rs.getString("related_type"));
        Object rid = rs.getObject("related_id");
        if (rid != null) n.setRelatedId(((Number) rid).longValue());
        n.setCreatedAt(rs.getTimestamp("created_at"));
        n.setReadAt(rs.getTimestamp("read_at"));
        return n;
    }
}
