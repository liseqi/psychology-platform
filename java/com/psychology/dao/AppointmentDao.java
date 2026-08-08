package com.psychology.dao;

import com.psychology.entity.Appointment;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 咨询预约DAO - 重写版：移除不存在的字段
 */
public class AppointmentDao {

    /**
     * 创建预约（简化版）
     */
    public long add(Appointment appointment) {
        String sql = "INSERT INTO appointment (student_id, counselor_id, schedule_id, " +
                "appointment_date, time_slot, status, consultation_topic, created_at, updated_at) " +
                "VALUES (?, ?, ?, ?, ?, 'PENDING', ?, NOW(), NOW())";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, appointment.getStudentId());
            ps.setInt(2, appointment.getCounselorId());
            if (appointment.getScheduleId() != null) {
                ps.setInt(3, appointment.getScheduleId());
            } else {
                ps.setNull(3, Types.INTEGER);
            }
            ps.setDate(4, new java.sql.Date(appointment.getAppointmentDate().getTime()));
            ps.setString(5, appointment.getTimeSlot());
            ps.setString(6, appointment.getConsultationTopic());

            int rows = ps.executeUpdate();
            if (rows > 0) {
                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    long id = generatedKeys.getLong(1);
                    generatedKeys.close();
                    return id;
                }
            }
            return 0;
        } catch (SQLException e) {
            e.printStackTrace();
            throw new RuntimeException("数据库写入失败: " + e.getMessage(), e);
        } finally {
            DBUtil.close(conn, ps);
        }
    }

    /**
     * 创建预约（指定状态）
     */
    public long addWithStatus(Appointment appointment, String status) {
        String sql = "INSERT INTO appointment (student_id, counselor_id, schedule_id, " +
                "appointment_date, time_slot, status, consultation_topic, created_at, updated_at) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, appointment.getStudentId());
            ps.setInt(2, appointment.getCounselorId());
            if (appointment.getScheduleId() != null) {
                ps.setInt(3, appointment.getScheduleId());
            } else {
                ps.setNull(3, Types.INTEGER);
            }
            ps.setDate(4, new java.sql.Date(appointment.getAppointmentDate().getTime()));
            ps.setString(5, appointment.getTimeSlot());
            ps.setString(6, status != null ? status : "PENDING");
            ps.setString(7, appointment.getConsultationTopic());

            int rows = ps.executeUpdate();
            if (rows > 0) {
                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    long id = generatedKeys.getLong(1);
                    generatedKeys.close();
                    return id;
                }
            }
            return 0;
        } catch (SQLException e) {
            e.printStackTrace();
            throw new RuntimeException("数据库写入失败: " + e.getMessage(), e);
        } finally {
            DBUtil.close(conn, ps);
        }
    }

    /**
     * 查询学生和咨询师之间最新有效的预约
     */
    public Appointment findLatestByStudentAndCounselor(Integer studentId, Integer counselorId) {
        String sql = "SELECT a.* FROM appointment a " +
                "WHERE a.student_id=? AND a.counselor_id=? AND a.status NOT IN ('CANCELLED', 'RESCHEDULED') " +
                "ORDER BY a.created_at DESC LIMIT 1";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, studentId);
            ps.setInt(2, counselorId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractAppointment(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 学生取消/改期预约
     */
    public boolean cancelOrReschedule(Long id, String newStatus, String cancelReason, 
                                       Integer cancelledBy, Long rescheduleFromId) {
        String sql = "UPDATE appointment SET status=?, cancel_reason=?, cancelled_by=?, " +
                "cancel_time=NOW(), reschedule_from_id=?, updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, newStatus);
            ps.setString(2, cancelReason);
            ps.setObject(3, cancelledBy, Types.INTEGER);
            if (rescheduleFromId != null) {
                ps.setLong(4, rescheduleFromId);
            } else {
                ps.setNull(4, Types.BIGINT);
            }
            ps.setLong(5, id);
            
            int rows = ps.executeUpdate();
            if (rows > 0 && ("CANCELLED".equals(newStatus) || "RESCHEDULED".equals(newStatus))) {
                releaseScheduleSlot(id);
            }
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 释放排班名额
     */
    private void releaseScheduleSlot(Long appointmentId) {
        String getScheduleSql = "SELECT schedule_id FROM appointment WHERE id=?";
        String updateScheduleSql = "UPDATE counselor_schedule SET current_appointments = " +
                "GREATEST(0, current_appointments - 1), " +
                "status = CASE WHEN current_appointments <= max_appointments THEN 'AVAILABLE' ELSE status END " +
                "WHERE id=?";

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            ps = conn.prepareStatement(getScheduleSql);
            ps.setLong(1, appointmentId);
            rs = ps.executeQuery();

            if (rs.next()) {
                Object scheduleObj = rs.getObject("schedule_id");
                if (scheduleObj != null) {
                    int scheduleId = ((Number) scheduleObj).intValue();
                    DBUtil.closePS(ps);

                    ps = conn.prepareStatement(updateScheduleSql);
                    ps.setInt(1, scheduleId);
                    ps.executeUpdate();
                }
            }

            conn.commit();
            conn.setAutoCommit(true);
        } catch (SQLException e) {
            DBUtil.rollbackTransaction(conn);
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
    }

    /**
     * 查询学生的预约列表
     */
    public List<Appointment> findByStudent(Integer studentId, String status) {
        StringBuilder sql = new StringBuilder(
            "SELECT a.*, c.real_name as counselor_name FROM appointment a " +
            "LEFT JOIN sys_user c ON a.counselor_id = c.id " +
            "WHERE a.student_id=? ");
        
        if (!"ALL".equals(status)) {
            sql.append("AND a.status=? ");
        }
        sql.append("ORDER BY a.appointment_date DESC, a.time_slot ASC");

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Appointment> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            ps.setInt(1, studentId);
            if (!"ALL".equals(status)) {
                ps.setString(2, status);
            }
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractAppointment(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 查询咨询师的预约列表
     */
    public List<Appointment> findByCounselor(Integer counselorId, String status, 
                                              java.sql.Date date) {
        StringBuilder sql = new StringBuilder(
            "SELECT a.*, s.real_name as student_name FROM appointment a " +
            "LEFT JOIN sys_user s ON a.student_id = s.id " +
            "WHERE a.counselor_id=? ");
        
        List<Object> params = new ArrayList<>();
        params.add(counselorId);

        if (!"ALL".equals(status)) {
            sql.append("AND a.status=? ");
            params.add(status);
        }
        if (date != null) {
            sql.append("AND a.appointment_date=? ");
            params.add(date);
        }

        sql.append("ORDER BY a.appointment_date DESC, a.time_slot ASC");

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Appointment> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractAppointment(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 根据ID查询预约详情
     */
    public Appointment findById(Long id) {
        String sql = "SELECT a.*, st.real_name as student_name, co.real_name as counselor_name " +
                "FROM appointment a " +
                "LEFT JOIN sys_user st ON a.student_id = st.id " +
                "LEFT JOIN sys_user co ON a.counselor_id = co.id " +
                "WHERE a.id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractAppointment(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 更新预约状态为已确认（学生确认）
     */
    public boolean confirmByStudent(Long id) {
        String sql = "UPDATE appointment SET status='CONFIRMED', updated_at=NOW() WHERE id=? AND status='PENDING'";
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

    /**
     * 更新预约状态为已确认（咨询师确认）
     */
    public boolean confirm(Long id) {
        String sql = "UPDATE appointment SET status='CONFIRMED', updated_at=NOW() WHERE id=? AND status='PENDING'";
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

    /**
     * 学生申请改期
     */
    public boolean requestReschedule(Long id, String reason, java.sql.Date newDate, String newTimeSlot) {
        // 简化：仅更新日期和时段，使用备注字段存储原因
        String sql = "UPDATE appointment SET appointment_date=?, time_slot=?, " +
                "cancel_reason=CONCAT(IFNULL(cancel_reason,''), ' [改期原因:', ?, ']'), " +
                "updated_at=NOW() WHERE id=? AND status='PENDING'";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setDate(1, newDate);
            ps.setString(2, newTimeSlot);
            ps.setString(3, reason);
            ps.setLong(4, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 咨询师确认学生改期申请
     */
    public boolean confirmReschedule(Long id, Integer scheduleId, java.sql.Date newDate, String newTimeSlot) {
        String sql = "UPDATE appointment SET schedule_id=?, appointment_date=?, time_slot=?, " +
                "status='CONFIRMED', updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            if (scheduleId != null) {
                ps.setInt(1, scheduleId);
            } else {
                ps.setNull(1, Types.INTEGER);
            }
            ps.setDate(2, newDate);
            ps.setString(3, newTimeSlot);
            ps.setLong(4, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 更新预约状态为已完成
     */
    public boolean markCompleted(Long id) {
        String sql = "UPDATE appointment SET status='COMPLETED', updated_at=NOW() WHERE id=?";
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

    /**
     * 统计预约数量（用于数据大屏）
     */
    public long countByStatusAndDateRange(String status, String startDate, String endDate) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM appointment WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (!"ALL".equals(status)) {
            sql.append("AND status=? ");
            params.add(status);
        }
        if (startDate != null && !startDate.isEmpty()) {
            sql.append("AND appointment_date >=? ");
            params.add(java.sql.Date.valueOf(startDate));
        }
        if (endDate != null && !endDate.isEmpty()) {
            sql.append("AND appointment_date <=? ");
            params.add(java.sql.Date.valueOf(endDate));
        }

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
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
     * 按日期和时段统计预约数量（用于热度图）
     */
    public List<Map<String, Object>> countByDateAndSlot(String startDate, String endDate) {
        StringBuilder sql = new StringBuilder(
            "SELECT appointment_date, time_slot, COUNT(*) as cnt FROM appointment " +
            "WHERE status IN ('PENDING', 'CONFIRMED', 'COMPLETED') ");
        
        List<Object> params = new ArrayList<>();
        
        if (startDate != null && !startDate.isEmpty()) {
            sql.append("AND appointment_date >=? ");
            params.add(java.sql.Date.valueOf(startDate));
        }
        if (endDate != null && !endDate.isEmpty()) {
            sql.append("AND appointment_date <=? ");
            params.add(java.sql.Date.valueOf(endDate));
        }
        
        sql.append("GROUP BY appointment_date, time_slot ORDER BY appointment_date, time_slot");

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Map<String, Object>> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("date", rs.getDate("appointment_date").toString());
                item.put("timeSlot", rs.getString("time_slot"));
                item.put("count", rs.getLong("cnt"));
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
     * 从ResultSet提取Appointment对象（只读取存在的字段）
     */
    private Appointment extractAppointment(ResultSet rs) throws SQLException {
        Appointment apt = new Appointment();
        
        // 基本字段
        apt.setId(rs.getLong("id"));
        
        Object sid = rs.getObject("student_id");
        if (sid != null) apt.setStudentId(((Number) sid).intValue());
        
        Object cid = rs.getObject("counselor_id");
        if (cid != null) apt.setCounselorId(((Number) cid).intValue());
        
        Object schid = rs.getObject("schedule_id");
        if (schid != null) apt.setScheduleId(((Number) schid).intValue());
        
        apt.setAppointmentDate(rs.getDate("appointment_date"));
        apt.setTimeSlot(rs.getString("time_slot"));
        apt.setStatus(rs.getString("status"));
        apt.setConsultationTopic(rs.getString("consultation_topic"));
        
        // 可选字段（可能为NULL）
        try { apt.setCancelReason(rs.getString("cancel_reason")); } catch (Exception e) {}
        
        Object cb = rs.getObject("cancelled_by");
        if (cb != null) apt.setCancelledBy(((Number) cb).intValue());
        
        try { apt.setCancelTime(rs.getTimestamp("cancel_time")); } catch (Exception e) {}
        
        Object rfi = rs.getObject("reschedule_from_id");
        if (rfi != null) apt.setRescheduleFromId(((Number) rfi).longValue());
        
        // 时间戳字段
        try { apt.setCreatedAt(rs.getTimestamp("created_at")); } catch (Exception e) {}
        try { apt.setUpdatedAt(rs.getTimestamp("updated_at")); } catch (Exception e) {}

        // 非数据库字段（来自JOIN）
        try { apt.setStudentName(rs.getString("student_name")); } catch (Exception e) {}
        try { apt.setCounselorName(rs.getString("counselor_name")); } catch (Exception e) {}

        return apt;
    }
}
