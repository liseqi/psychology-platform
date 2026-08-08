package com.psychology.servlet;

import com.psychology.util.DBUtil;
import com.psychology.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

/**
 * 演示数据初始化Servlet
 * 访问 /init/demo 即可自动插入预警、预约、排班等演示数据
 */
@WebServlet("/init/demo")
public class DemoDataInitServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // 1. 获取用户ID
            int counselorId = getUserId("counselor1", "COUNSELOR");
            int student1Id = getUserId("student1", "STUDENT");
            int student2Id = getUserId("student2", "STUDENT");
            
            if (counselorId == 0 || student1Id == 0 || student2Id == 0) {
                JsonUtil.writeError(resp, "请先确保数据库中有 counselor1, student1, student2 用户");
                return;
            }
            
            // 2. 插入排班数据
            insertScheduleData(counselorId);
            
            // 3. 插入预警记录
            insertAlertData(counselorId, student1Id, student2Id);
            
            // 4. 插入预约记录
            insertAppointmentData(counselorId, student1Id, student2Id);
            
            // 5. 关联预警和预约
            linkAlertsAndAppointments(student1Id, student2Id);
            
            result.put("message", "✅ 演示数据插入成功！");
            result.put("counselorId", counselorId);
            Map<String, String> details = new HashMap<>();
            details.put("排班", "已为咨询师设置今日及明日排班");
            details.put("预警", "已插入4条不同状态/级别的预警");
            details.put("预约", "已插入3种状态的预约（待确认/已确认/改期）");
            result.put("details", details);
            
            JsonUtil.writeSuccess(resp, result);
            
        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeError(resp, "初始化失败: " + e.getMessage());
        }
    }

    private int getUserId(String username, String role) {
        String sql = "SELECT id FROM sys_user WHERE username=? AND role=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            ps.setString(2, role);
            rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return 0;
    }

    private void insertScheduleData(int counselorId) throws SQLException {
        LocalDate today = LocalDate.now();
        LocalDate tomorrow = today.plusDays(1);
        
        String sql = "INSERT INTO counselor_schedule (counselor_id, schedule_date, time_slot, max_appointments, current_appointments, status) " +
                     "VALUES (?, ?, ?, ?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE status=VALUES(status), current_appointments=VALUES(current_appointments)";
        
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            
            // 今日排班
            setScheduleParams(ps, counselorId, today, "09:00-10:00", 1, 0, "AVAILABLE"); ps.addBatch();
            setScheduleParams(ps, counselorId, today, "10:00-11:00", 1, 0, "AVAILABLE"); ps.addBatch();
            setScheduleParams(ps, counselorId, today, "14:00-15:00", 1, 1, "AVAILABLE"); ps.addBatch();
            
            // 明日排班
            setScheduleParams(ps, counselorId, tomorrow, "09:00-10:00", 1, 1, "AVAILABLE"); ps.addBatch();
            setScheduleParams(ps, counselorId, tomorrow, "14:00-15:00", 1, 0, "AVAILABLE"); ps.addBatch();
            
            ps.executeBatch();
        } finally {
            DBUtil.close(conn, ps);
        }
    }
    
    private void setScheduleParams(PreparedStatement ps, int counselorId, LocalDate date, 
                                   String slot, int max, int current, String status) throws SQLException {
        ps.setInt(1, counselorId);
        ps.setDate(2, Date.valueOf(date));
        ps.setString(3, slot);
        ps.setInt(4, max);
        ps.setInt(5, current);
        ps.setString(6, status);
    }

    private void insertAlertData(int counselorId, int student1Id, int student2Id) throws SQLException {
        String sql = "INSERT IGNORE INTO alert_record (student_id, alert_level, alert_type, trigger_reason, status, " +
                     "assigned_counselor_id, intervention_record, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            
            Timestamp now = new Timestamp(System.currentTimeMillis());
            
            // 高风险待处理 - 学生1
            setAlertParams(ps, student1Id, "HIGH", "ASSESSMENT", 
                "SCL-90测评显示抑郁维度得分较高，存在自伤风险，需要尽快干预。",
                "PENDING", counselorId, null, now); ps.addBatch();
            
            // 中风险处理中 - 学生1
            setAlertParams(ps, student1Id, "MEDIUM", "CHAT",
                "AI树洞对话中多次表达学业压力和焦虑情绪，已初步安抚。",
                "PROCESSING", counselorId, "已电话安抚学生，准备安排咨询。", 
                Timestamp.from(now.toInstant().minus(java.time.Duration.ofDays(2)))); ps.addBatch();
            
            // 低风险已解决 - 学生2
            setAlertParams(ps, student2Id, "LOW", "ASSESSMENT",
                "GAD-7测评显示轻度焦虑，建议关注。",
                "RESOLVED", counselorId, "已进行心理疏导，学生状态平稳。",
                Timestamp.from(now.toInstant().minus(java.time.Duration.ofDays(10)))); ps.addBatch();
            
            // 高风险待处理 - 学生2（辅导员上报）
            setAlertParams(ps, student2Id, "HIGH", "MANUAL",
                "辅导员上报：学生近期情绪异常，社交回避明显。",
                "PENDING", counselorId, null, now); ps.addBatch();
            
            ps.executeBatch();
        } finally {
            DBUtil.close(conn, ps);
        }
    }
    
    private void setAlertParams(PreparedStatement ps, int studentId, String level, String type,
                                String reason, String status, int counselorId, String record, 
                                Timestamp createdAt) throws SQLException {
        ps.setInt(1, studentId);
        ps.setString(2, level);
        ps.setString(3, type);
        ps.setString(4, reason);
        ps.setString(5, status);
        ps.setInt(6, counselorId);
        if (record != null) ps.setString(7, record); else ps.setNull(7, Types.VARCHAR);
        ps.setTimestamp(8, createdAt);
    }

    private void insertAppointmentData(int counselorId, int student1Id, int student2Id) throws SQLException {
        String sql = "INSERT IGNORE INTO appointment (student_id, counselor_id, appointment_date, time_slot, " +
                     "status, consultation_topic, created_at, updated_at) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);

            LocalDate today = LocalDate.now();
            Timestamp now = new Timestamp(System.currentTimeMillis());

            // 待确认的预约（学生1）
            setAppointmentParams(ps, student1Id, counselorId, today.plusDays(1), "09:00-10:00",
                "PENDING", "抑郁情绪咨询", now); ps.addBatch();

            // 已确认的预约（今日，学生2）
            setAppointmentParams(ps, student2Id, counselorId, today, "14:00-15:00",
                "CONFIRMED", "焦虑情绪咨询",
                Timestamp.from(now.toInstant().minus(java.time.Duration.ofDays(1)))); ps.addBatch();

            // 申请改期的预约（学生2）
            setAppointmentParams(ps, student2Id, counselorId, today.plusDays(2), "10:00-11:00",
                "PENDING", "社交回避咨询", now); ps.addBatch();

            ps.executeBatch();

            // 更新改期预约的备注信息
            String updateSql = "UPDATE appointment SET cancel_reason=? " +
                              "WHERE student_id=? AND status='PENDING' LIMIT 1";
            try (PreparedStatement updatePs = conn.prepareStatement(updateSql)) {
                updatePs.setString(1, "[改期原因: 那天有课，希望能改到下午]");
                updatePs.setInt(2, student2Id);
                updatePs.executeUpdate();
            }
        } finally {
            DBUtil.close(conn, ps);
        }
    }

    private void setAppointmentParams(PreparedStatement ps, int studentId, int counselorId,
                                      LocalDate date, String slot, String status, String topic,
                                      Timestamp created)
            throws SQLException {
        ps.setInt(1, studentId);
        ps.setInt(2, counselorId);
        ps.setDate(3, Date.valueOf(date));
        ps.setString(4, slot);
        ps.setString(5, status);
        ps.setString(6, topic);
        ps.setTimestamp(7, created);
        ps.setTimestamp(8, created);  // updated = created
    }

    private void linkAlertsAndAppointments(int student1Id, int student2Id) throws SQLException {
        // 更新学生1的高风险PENDING预警 -> 关联第一条待处理预约
        String sql1 = "UPDATE alert_record ar SET ar.appointment_id = (" +
                      "SELECT a.id FROM appointment a WHERE a.student_id=? AND a.status='PENDING' LIMIT 1" +
                      ") WHERE ar.student_id=? AND ar.status='PENDING' AND ar.alert_level='HIGH' LIMIT 1";

        // 更新学生2的高风险PENDING预警 -> 关联已确认或待处理预约
        String sql2 = "UPDATE alert_record ar SET ar.appointment_id = (" +
                      "SELECT a.id FROM appointment a WHERE a.student_id=? AND a.status IN ('PENDING', 'CONFIRMED') LIMIT 1" +
                      ") WHERE ar.student_id=? AND ar.status='PENDING' AND ar.alert_level='HIGH' LIMIT 1";
        
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql1);
            ps.setInt(1, student1Id);
            ps.setInt(2, student1Id);
            ps.executeUpdate();
            
            ps = conn.prepareStatement(sql2);
            ps.setInt(1, student2Id);
            ps.setInt(2, student2Id);
            ps.executeUpdate();
        } finally {
            DBUtil.close(conn, ps);
        }
    }
}
