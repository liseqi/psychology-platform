package com.psychology.dao;

import com.psychology.entity.AlertRecord;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 预警记录DAO - 重写版：确保数据正确读取
 */
public class AlertRecordDao {

    /**
     * 分页查询预警列表 - 简化版：先查主表，再补充关联数据
     */
    public List<AlertRecord> findList(int page, int pageSize, String level,
                                       String status, Integer counselorId, String keyword) {
        
        // 第一步：构建基础查询（只查alert_record主表）
        StringBuilder sql = new StringBuilder(
            "SELECT * FROM alert_record WHERE 1=1 ");
        
        List<Object> params = new ArrayList<>();
        
        if (!"ALL".equals(level) && level != null && !level.isEmpty()) {
            sql.append("AND alert_level=? ");
            params.add(level);
        }
        
        if (!"ALL".equals(status) && status != null && !status.isEmpty()) {
            sql.append("AND status=? ");
            params.add(status);
        }
        
        if (counselorId != null) {
            sql.append("AND assigned_counselor_id=? ");
            params.add(counselorId);
        }
        
        sql.append("ORDER BY created_at DESC LIMIT ?,?");
        params.add((page - 1) * pageSize);
        params.add(pageSize);

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<AlertRecord> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            
            // 绑定参数
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            
            System.out.println("[DEBUG] findList SQL: " + sql.toString());
            System.out.println("[DEBUG] findList Params: " + params);
            
            rs = ps.executeQuery();
            
            while (rs.next()) {
                AlertRecord alert = extractFromMainTable(rs);
                
                // 第二步：单独查询学生姓名（如果student_id存在）
                if (alert.getStudentId() > 0) {
                    String studentName = getStudentName(conn, alert.getStudentId());
                    alert.setStudentName(studentName);
                }
                
                list.add(alert);
            }
            
            System.out.println("[DEBUG] findList Result count: " + list.size());
            
        } catch (SQLException e) {
            System.err.println("[ERROR] findList failed: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 从alert_record主表提取数据（不依赖JOIN）
     */
    private AlertRecord extractFromMainTable(ResultSet rs) throws SQLException {
        AlertRecord alert = new AlertRecord();
        
        try { alert.setId(rs.getLong("id")); } catch (Exception e) {}
        try { alert.setStudentId(rs.getInt("student_id")); } catch (Exception e) {}
        
        try {
            Object obj = rs.getObject("assessment_record_id");
            if (obj != null) alert.setAssessmentRecordId(((Number) obj).longValue());
        } catch (Exception e) {}
        
        try {
            Object obj = rs.getObject("chat_session_id");
            if (obj != null) alert.setChatSessionId(((Number) obj).longValue());
        } catch (Exception e) {}
        
        try { alert.setAlertLevel(rs.getString("alert_level")); } catch (Exception e) {}
        try { alert.setAlertType(rs.getString("alert_type")); } catch (Exception e) {}
        try { alert.setTriggerReason(rs.getString("trigger_reason")); } catch (Exception e) {}
        
        try { alert.setScoreValue(rs.getBigDecimal("score_value")); } catch (Exception e) {}
        try { alert.setStatus(rs.getString("status")); } catch (Exception e) {}
        
        try {
            Object obj = rs.getObject("assigned_counselor_id");
            if (obj != null) alert.setAssignedCounselorId(((Number) obj).intValue());
        } catch (Exception e) {}
        
        try { alert.setInterventionRecord(rs.getString("intervention_record")); } catch (Exception e) {}
        try { alert.setInterventionResult(rs.getString("intervention_result")); } catch (Exception e) {}
        
        try { alert.setResolvedAt(rs.getTimestamp("resolved_at")); } catch (Exception e) {}
        
        try {
            Object obj = rs.getObject("resolved_by");
            if (obj != null) alert.setResolvedBy(((Number) obj).intValue());
        } catch (Exception e) {}
        
        try {
            Object obj = rs.getObject("appointment_id");
            if (obj != null) alert.setAppointmentId(((Number) obj).longValue());
        } catch (Exception e) {}
        
        try { alert.setCreatedAt(rs.getTimestamp("created_at")); } catch (Exception e) {}
        try { alert.setUpdatedAt(rs.getTimestamp("updated_at")); } catch (Exception e) {}
        
        return alert;
    }

    /**
     * 单独查询学生姓名（避免JOIN失败影响整体查询）
     */
    private String getStudentName(Connection conn, int studentId) {
        String sql = "SELECT real_name FROM sys_user WHERE id=?";
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = conn.prepareStatement(sql);
            ps.setInt(1, studentId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getString("real_name");
            }
        } catch (Exception e) {
            // 学生不存在时返回null，不影响主查询
        } finally {
            DBUtil.close(null, ps, rs);
        }
        return null;
    }

    /**
     * 根据ID查询预警详情 - 简化版
     */
    public AlertRecord findById(Long id) {
        String sql = "SELECT * FROM alert_record WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                AlertRecord alert = extractFromMainTable(rs);
                if (alert.getStudentId() > 0) {
                    alert.setStudentName(getStudentName(conn, alert.getStudentId()));
                }
                return alert;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 新增预警记录
     */
    public long add(AlertRecord alert) {
        String sql = "INSERT INTO alert_record (student_id, assessment_record_id, chat_session_id, " +
                "alert_level, alert_type, trigger_reason, score_value, status, " +
                "assigned_counselor_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING',?, NOW())";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, alert.getStudentId());
            
            if (alert.getAssessmentRecordId() != null) {
                ps.setLong(2, alert.getAssessmentRecordId());
            } else {
                ps.setNull(2, Types.BIGINT);
            }
            
            if (alert.getChatSessionId() != null) {
                ps.setLong(3, alert.getChatSessionId());
            } else {
                ps.setNull(3, Types.BIGINT);
            }
            
            ps.setString(4, alert.getAlertLevel());
            ps.setString(5, alert.getAlertType());
            ps.setString(6, alert.getTriggerReason());
            
            if (alert.getScoreValue() != null) {
                ps.setBigDecimal(7, alert.getScoreValue());
            } else {
                ps.setNull(7, Types.DECIMAL);
            }
            
            if (alert.getAssignedCounselorId() != null) {
                ps.setInt(8, alert.getAssignedCounselorId());
            } else {
                ps.setNull(8, Types.INTEGER);
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
     * 更新预警关联的预约ID
     */
    public boolean updateAppointmentId(Long alertId, Long appointmentId, Integer operatorId) {
        String sql = "UPDATE alert_record SET appointment_id=?, updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            if (appointmentId != null) {
                ps.setLong(1, appointmentId);
            } else {
                ps.setNull(1, Types.BIGINT);
            }
            ps.setLong(2, alertId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 更新预警状态（处理/解决）
     */
    public boolean updateStatus(Long id, String status, String interventionRecord,
                                 String result, Integer operatorId) {
        StringBuilder sql = new StringBuilder(
            "UPDATE alert_record SET status=?, updated_at=NOW()");
        
        List<Object> params = new ArrayList<>();
        params.add(status);
        
        if (interventionRecord != null && !interventionRecord.isEmpty()) {
            sql.append(", intervention_record=?, assigned_counselor_id=?, resolved_by=?");
            params.add(interventionRecord);
            params.add(operatorId);
            params.add(operatorId);
        }
        
        if (result != null && !result.isEmpty()) {
            sql.append(", intervention_result=?, resolved_at=NOW(), resolved_by=?");
            params.add(result);
            params.add(operatorId);
        }
        
        sql.append(" WHERE id=?");
        params.add(id);

        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
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
     * 按级别统计数量（用于大屏展示）
     */
    public Map<String, Object> countByLevel(Integer counselorId, String status) {
        StringBuilder sql = new StringBuilder(
            "SELECT alert_level, COUNT(*) as cnt FROM alert_record WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (status != null && !"ALL".equals(status) && !status.isEmpty()) {
            sql.append("AND status=? ");
            params.add(status);
        } else if (status == null) {
            sql.append("AND status IN ('PENDING', 'PROCESSING', 'INTERVENING') ");
        }

        if (counselorId != null) {
            sql.append("AND assigned_counselor_id=? ");
            params.add(counselorId);
        }
        sql.append("GROUP BY alert_level");
        
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Map<String, Object> result = new HashMap<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            rs = ps.executeQuery();
            while (rs.next()) {
                String level = rs.getString("alert_level");
                long count = rs.getLong("cnt");
                result.put(level.toUpperCase(), count);
            }
            // 确保三个级别都有值
            if (!result.containsKey("HIGH")) result.put("HIGH", 0L);
            if (!result.containsKey("MEDIUM")) result.put("MEDIUM", 0L);
            if (!result.containsKey("LOW")) result.put("LOW", 0L);
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return result;
    }

    /**
     * 按级别统计数量（活跃状态，全量）
     */
    public Map<String, Object> countByLevel() {
        return countByLevel(null, null);
    }

    /**
     * 按级别统计数量（活跃状态，按咨询师过滤）
     */
    public Map<String, Object> countByLevel(Integer counselorId) {
        return countByLevel(counselorId, null);
    }

    /**
     * 按院系统计风险人数分布（用于饼图）
     */
    public Map<String, Object> countByDepartment() {
        String sql = "SELECT u.department, COUNT(DISTINCT ar.student_id) as risk_count " +
                "FROM alert_record ar " +
                "LEFT JOIN sys_user u ON ar.student_id = u.id " +
                "WHERE ar.status IN ('PENDING', 'PROCESSING', 'INTERVENING') " +
                "GROUP BY u.department " +
                "ORDER BY risk_count DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> departments = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("department", rs.getString("department"));
                item.put("count", rs.getLong("risk_count"));
                departments.add(item);
            }
            result.put("departments", departments);
            result.put("totalRiskStudents", departments.stream()
                    .mapToLong(m -> (Long) m.get("count")).sum());
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return result;
    }

    /**
     * 统计今日新增预警数
     */
    public long countToday() {
        String sql = "SELECT COUNT(*) FROM alert_record WHERE DATE(created_at) = CURDATE()";
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
}
