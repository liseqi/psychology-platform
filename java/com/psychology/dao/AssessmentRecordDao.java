package com.psychology.dao;

import com.psychology.entity.AssessmentRecord;
import com.psychology.util.DBUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 测评记录DAO - 包含防作弊逻辑
 */
public class AssessmentRecordDao {

    /**
     * 查询用户某量表最近的测评记录（用于防作弊检查）
     */
    public AssessmentRecord findLatestByUserAndScale(Integer userId, Integer scaleId) {
        String sql = "SELECT * FROM assessment_record WHERE user_id=? AND scale_id=? " +
                "ORDER BY created_at DESC LIMIT 1";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setInt(2, scaleId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractRecord(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 添加测评记录
     */
    public long add(AssessmentRecord record) {
        String sql = "INSERT INTO assessment_record (user_id, scale_id, start_time, end_time, " +
                "duration_seconds, total_score, dimension_scores, risk_level, " +
                "is_suspicious, suspicious_reason, answers_json, counselor_id) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, record.getUserId());
            ps.setInt(2, record.getScaleId());
            ps.setTimestamp(3, new Timestamp(record.getStartTime().getTime()));
            ps.setTimestamp(4, new Timestamp(record.getEndTime().getTime()));
            ps.setInt(5, record.getDurationSeconds());
            if (record.getTotalScore() != null) {
                ps.setBigDecimal(6, record.getTotalScore());
            } else {
                ps.setNull(6, Types.DECIMAL);
            }
            ps.setString(7, record.getDimensionScores());
            ps.setString(8, record.getRiskLevel());
            ps.setInt(9, record.getSuspicious() != null ? record.getSuspicious() : 0);
            ps.setString(10, record.getSuspiciousReason());
            ps.setString(11, record.getAnswersJson());
            if (record.getCounselorId() != null) {
                ps.setInt(12, record.getCounselorId());
            } else {
                ps.setNull(12, Types.INTEGER);
            }

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
     * 查询学生的测评历史（用于历史对比看板）
     */
    public List<AssessmentRecord> findByUserAndScale(Integer userId, Integer scaleId) {
        String sql = "SELECT * FROM assessment_record WHERE user_id=? AND scale_id=? " +
                "ORDER BY created_at ASC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<AssessmentRecord> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setInt(2, scaleId);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractRecord(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 查询学生的所有测评记录
     */
    public List<AssessmentRecord> findByUser(Integer userId, int page, int pageSize) {
        String sql = "SELECT ar.*, s.name as scale_name FROM assessment_record ar " +
                "LEFT JOIN scale s ON ar.scale_id = s.id " +
                "WHERE ar.user_id=? ORDER BY ar.created_at DESC LIMIT ?,?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<AssessmentRecord> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);
            rs = ps.executeQuery();
            while (rs.next()) {
                AssessmentRecord record = extractRecord(rs);
                list.add(record);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 咨询师查看名下学生记录
     */
    public List<AssessmentRecord> findByCounselor(Integer counselorId, String keyword, 
                                                   String riskLevel, int page, int pageSize) {
        StringBuilder sql = new StringBuilder(
            "SELECT ar.*, u.real_name as student_name, s.name as scale_name " +
            "FROM assessment_record ar " +
            "LEFT JOIN sys_user u ON ar.user_id = u.id " +
            "LEFT JOIN scale s ON ar.scale_id = s.id " +
            "WHERE ar.counselor_id=? ");
        
        if (keyword != null && !keyword.isEmpty()) {
            sql.append("AND (u.real_name LIKE ? OR u.student_id LIKE ?) ");
        }
        if (riskLevel != null && !"ALL".equals(riskLevel)) {
            sql.append("AND ar.risk_level=? ");
        }
        sql.append("ORDER BY ar.created_at DESC LIMIT ?,?");

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<AssessmentRecord> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            int idx = 1;
            ps.setInt(idx++, counselorId);

            if (keyword != null && !keyword.isEmpty()) {
                ps.setString(idx++, "%" + keyword + "%");
                ps.setString(idx++, "%" + keyword + "%");
            }
            if (riskLevel != null && !"ALL".equals(riskLevel)) {
                ps.setString(idx++, riskLevel);
            }
            ps.setInt(idx++, (page - 1) * pageSize);
            ps.setInt(idx++, pageSize);

            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractRecord(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 标记为已查看
     */
    public boolean markAsViewed(Long recordId) {
        String sql = "UPDATE assessment_record SET is_viewed=1 WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, recordId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 根据ID查询测评记录
     */
    public AssessmentRecord findById(Long id) {
        String sql = "SELECT * FROM assessment_record WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractRecord(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 统计用户的测评次数
     */
    public long countByUser(Integer userId) {
        String sql = "SELECT COUNT(*) FROM assessment_record WHERE user_id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
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

    /**
     * 统计总测评次数
     */
    public long countTotal() {
        String sql = "SELECT COUNT(*) FROM assessment_record";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
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

    /**
     * 统计今日测评次数
     */
    public long countToday() {
        String sql = "SELECT COUNT(*) FROM assessment_record WHERE DATE(created_at) = CURDATE()";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
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

    /**
     * 按风险等级统计
     */
    public Map<String, Object> countByRiskLevel() {
        String sql = "SELECT risk_level, COUNT(*) as cnt FROM assessment_record " +
                "GROUP BY risk_level";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Map<String, Object> result = new HashMap<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                String level = rs.getString("risk_level");
                long count = rs.getLong("cnt");
                result.put(level == null ? "unknown" : level.toLowerCase(), count);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return result;
    }

    /**
     * 按月统计测评数量
     */
    public long countByMonth(String month) {
        String sql = "SELECT COUNT(*) FROM assessment_record WHERE DATE_FORMAT(created_at, '%Y-%m')=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, month);
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

    private AssessmentRecord extractRecord(ResultSet rs) throws SQLException {
        AssessmentRecord record = new AssessmentRecord();
        record.setId(rs.getLong("id"));
        record.setUserId(rs.getInt("user_id"));
        record.setScaleId(rs.getInt("scale_id"));
        record.setStartTime(rs.getTimestamp("start_time"));
        record.setEndTime(rs.getTimestamp("end_time"));
        Object durationObj = rs.getObject("duration_seconds");
        if (durationObj != null) {
            record.setDurationSeconds(((Number) durationObj).intValue());
        }
        Object scoreObj = rs.getObject("total_score");
        if (scoreObj != null) {
            record.setTotalScore(new BigDecimal(scoreObj.toString()));
        }
        record.setDimensionScores(rs.getString("dimension_scores"));
        record.setRiskLevel(rs.getString("risk_level"));
        Object suspiciousObj = rs.getObject("is_suspicious");
        if (suspiciousObj != null) {
            record.setSuspicious(((Number) suspiciousObj).intValue());
        }
        record.setSuspiciousReason(rs.getString("suspicious_reason"));
        record.setAnswersJson(rs.getString("answers_json"));
        Object counselorObj = rs.getObject("counselor_id");
        if (counselorObj != null) {
            record.setCounselorId(((Number) counselorObj).intValue());
        }
        Object viewedObj = rs.getObject("is_viewed");
        if (viewedObj != null) {
            record.setViewed(((Number) viewedObj).intValue());
        }
        record.setCreatedAt(rs.getTimestamp("created_at"));
        return record;
    }
}
