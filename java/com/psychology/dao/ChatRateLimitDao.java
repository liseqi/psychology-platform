package com.psychology.dao;

import com.psychology.util.DBUtil;

import java.sql.*;

/**
 * AI对话限流DAO - 防止高频刷对话消耗接口额度
 */
public class ChatRateLimitDao {

    // 每日对话次数上限
    private static final int DAILY_LIMIT = 50;

    /**
     * 检查并增加使用次数，返回是否允许继续使用
     */
    public boolean checkAndIncrement(Integer userId) {
        String date = java.time.LocalDate.now().toString();

        // 查询或创建今日记录
        String selectSql = "SELECT * FROM chat_rate_limit WHERE user_id=? AND date=?";
        String insertSql = "INSERT INTO chat_rate_limit (user_id, date, request_count, last_request_time) VALUES (?, ?, 1, NOW())";
        String updateSql = "UPDATE chat_rate_limit SET request_count=request_count+1, last_request_time=NOW() WHERE user_id=? AND date=?";

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            
            // 先查询今日记录
            ps = conn.prepareStatement(selectSql);
            ps.setInt(1, userId);
            ps.setString(2, date);
            rs = ps.executeQuery();

            if (rs.next()) {
                // 已有记录，检查是否超限
                int currentCount = rs.getInt("request_count");
                if (currentCount >= DAILY_LIMIT) {
                    return false; // 已达上限
                }
                
                // 未超限，增加计数
                DBUtil.closePS(ps);
                ps = conn.prepareStatement(updateSql);
                ps.setInt(1, userId);
                ps.setString(2, date);
                return ps.executeUpdate() > 0;
            } else {
                // 无记录，新建
                DBUtil.closePS(ps);
                ps = conn.prepareStatement(insertSql);
                ps.setInt(1, userId);
                ps.setString(2, date);
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return false;
    }

    /**
     * 获取今日已用次数
     */
    public int getTodayUsage(Integer userId) {
        String date = java.time.LocalDate.now().toString();
        String sql = "SELECT COALESCE(request_count, 0) as cnt FROM chat_rate_limit WHERE user_id=? AND date=?";
        
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setString(2, date);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt("cnt");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return 0;
    }

    /**
     * 获取剩余配额
     */
    public int getRemainingQuota(Integer userId) {
        return Math.max(0, DAILY_LIMIT - getTodayUsage(userId));
    }
}
