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
 * 演示数据强制重置Servlet
 * 访问 /init/reset 即可清除旧数据并重新插入（自动匹配当前登录咨询师）
 */
@WebServlet("/init/reset")
public class DemoDataResetServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // 获取当前登录用户（必须是咨询师）
            Object userObj = req.getSession().getAttribute("currentUser");
            if (userObj == null) {
                JsonUtil.writeError(resp, "请先登录咨询师账号");
                return;
            }

            // 使用反射获取用户ID
            int counselorId = 0;
            String counselorName = "未知";
            try {
                java.lang.reflect.Field idField = userObj.getClass().getField("id");
                counselorId = (int) idField.get(userObj);
                
                java.lang.reflect.Field nameField = userObj.getClass().getField("realName");
                counselorName = (String) nameField.get(userObj);
            } catch (Exception e) {
                JsonUtil.writeError(resp, "无法获取当前用户信息");
                return;
            }

            // 获取学生ID
            int student1Id = getUserId("student1", "STUDENT");
            int student2Id = getUserId("student2", "STUDENT");

            if (student1Id == 0 || student2Id == 0) {
                result.put("warning", "未找到测试学生账户，将仅使用现有学生");
            }

            Connection conn = DBUtil.getConnection();
            
            // 1. 删除该咨询师的旧演示数据
            cleanupOldData(conn, counselorId, student1Id, student2Id);

            // 2. 插入新的排班、预警、预约数据
            insertAllDemoData(conn, counselorId, student1Id, student2Id);

            // 统计结果
            long alertCount = countRecords(conn, "alert_record", "assigned_counselor_id=" + counselorId);
            long scheduleCount = countRecords(conn, "counselor_schedule", 
                "counselor_id=" + counselorId + " AND schedule_date=CURDATE()");
            long appointmentCount = countRecords(conn, "appointment", "counselor_id=" + counselorId);

            result.put("message", "✅ 演示数据重置成功！");

            // Java 8 兼容：使用 HashMap 替代 Map.of()
            Map<String, Object> counselorInfo = new HashMap<>();
            counselorInfo.put("id", counselorId);
            counselorInfo.put("name", counselorName);
            result.put("counselorInfo", counselorInfo);

            Map<String, Object> statistics = new HashMap<>();
            statistics.put("预警记录", alertCount);
            statistics.put("今日排班", scheduleCount);
            statistics.put("预约数", appointmentCount);
            result.put("statistics", statistics);

            JsonUtil.writeSuccess(resp, result);

        } catch (Exception e) {
            e.printStackTrace();
            JsonUtil.writeError(resp, "重置失败: " + e.getMessage());
        }
    }

    private void cleanupOldData(Connection conn, int counselorId, int s1Id, int s2Id) throws SQLException {
        Statement stmt = conn.createStatement();

        // 删除预约（级联删除关联的咨询记录等）
        if (s1Id > 0 && s2Id > 0) {
            stmt.executeUpdate("DELETE FROM appointment WHERE counselor_id=" + counselorId + 
                " AND (student_id=" + s1Id + " OR student_id=" + s2Id + ")");
        }

        // 删除预警记录
        if (s1Id > 0 && s2Id > 0) {
            stmt.executeUpdate("DELETE FROM alert_record WHERE assigned_counselor_id=" + counselorId +
                " AND (student_id=" + s1Id + " OR student_id=" + s2Id + ")");
        }

        // 删除排班（保留未来的真实排班，只删今天及明天之前的）
        stmt.executeUpdate("DELETE FROM counselor_schedule WHERE counselor_id=" + counselorId + 
            " AND schedule_date <= DATE_ADD(CURDATE(), INTERVAL 1 DAY)");

        System.out.println("[DemoReset] 已清理咨询师 ID=" + counselorId + " 的旧数据");
    }

    private void insertAllDemoData(Connection conn, int counselorId, int s1Id, int s2Id) throws SQLException {
        LocalDate today = LocalDate.now();
        LocalDate tomorrow = today.plusDays(1);
        Timestamp now = new Timestamp(System.currentTimeMillis());

        // ========== 1. 插入排班 ==========
        PreparedStatement psSchedule = conn.prepareStatement(
            "INSERT INTO counselor_schedule (counselor_id, schedule_date, time_slot, max_appointments, current_appointments, status) " +
            "VALUES (?, ?, ?, ?, ?, ?)");

        // 今日3个时段
        setSchedule(psSchedule, counselorId, today, "09:00-10:00", 1, 0); psSchedule.addBatch();
        setSchedule(psSchedule, counselorId, today, "10:00-11:00", 1, 0); psSchedule.addBatch();
        setSchedule(psSchedule, counselorId, today, "14:00-15:00", 1, 1); psSchedule.addBatch();
        
        // 明日2个时段
        setSchedule(psSchedule, counselorId, tomorrow, "09:00-10:00", 1, 1); psSchedule.addBatch();
        setSchedule(psSchedule, counselorId, tomorrow, "14:00-15:00", 1, 0); psSchedule.addBatch();
        
        psSchedule.executeBatch();
        psSchedule.close();

        // ========== 2. 插入预警记录 ==========
        if (s1Id > 0 && s2Id > 0) {
            PreparedStatement psAlert = conn.prepareStatement(
                "INSERT INTO alert_record (student_id, alert_level, alert_type, trigger_reason, status, " +
                "assigned_counselor_id, intervention_record, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");

            // 预警1: 高风险待处理 - 学生1
            setAlert(psAlert, s1Id, "HIGH", "ASSESSMENT",
                "SCL-90测评显示抑郁维度得分较高，存在自伤风险，需要尽快干预。",
                "PENDING", counselorId, null, now); psAlert.addBatch();

            // 预警2: 中风险处理中 - 学生1
            setAlert(psAlert, s1Id, "MEDIUM", "CHAT",
                "AI树洞对话中多次表达学业压力和焦虑情绪，已初步安抚。",
                "PROCESSING", counselorId, "已电话安抚学生，准备安排咨询。",
                new Timestamp(now.getTime() - 172800000L)); // 2天前
            psAlert.addBatch();

            // 预警3: 低风险已解决 - 学生2
            setAlert(psAlert, s2Id, "LOW", "ASSESSMENT",
                "GAD-7测评显示轻度焦虑，建议关注。",
                "RESOLVED", counselorId, "已进行心理疏导，学生状态平稳。",
                new Timestamp(now.getTime() - 864000000L)); // 10天前
            psAlert.addBatch();

            // 预警4: 高风险待处理 - 学生2
            setAlert(psAlert, s2Id, "HIGH", "MANUAL",
                "辅导员上报：学生近期情绪异常，社交回避明显。",
                "PENDING", counselorId, null, now);
            psAlert.addBatch();

            psAlert.executeBatch();
            psAlert.close();
        }

        // ========== 3. 插入预约记录 ==========
        if (s1Id > 0 && s2Id > 0) {
            PreparedStatement psApt = conn.prepareStatement(
                "INSERT INTO appointment (student_id, counselor_id, appointment_date, time_slot, " +
                "status, consultation_topic, created_at, updated_at) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)");

            // 预约1: 待确认（学生1，明日）
            setAppointment(psApt, s1Id, counselorId, tomorrow, "09:00-10:00",
                "PENDING", "抑郁情绪咨询", now);
            psApt.addBatch();

            // 预约2: 已确认（学生2，今日）
            setAppointment(psApt, s2Id, counselorId, today, "14:00-15:00",
                "CONFIRMED", "焦虑情绪咨询",
                new Timestamp(now.getTime() - 86400000L));
            psApt.addBatch();

            // 预约3: 改期请求（学生2，后天）
            setAppointment(psApt, s2Id, counselorId, today.plusDays(2), "10:00-11:00",
                "PENDING", "社交回避咨询", now);
            psApt.addBatch();

            psApt.executeBatch();
            psApt.close();

            // 更新改期预约的详细信息
            PreparedStatement psUpdate = conn.prepareStatement(
                "UPDATE appointment SET cancel_reason=? WHERE student_id=? AND status='PENDING' LIMIT 1");
            psUpdate.setString(1, "[改期原因: 那天有课，希望能改到下午]");
            psUpdate.setInt(2, s2Id);
            psUpdate.executeUpdate();
            psUpdate.close();

            // ========== 4. 关联预警与预约 ==========
            linkAlertsToAppointments(conn, s1Id, s2Id);
        }

        System.out.println("[DemoReset] 已为咨询师 ID=" + counselorId + " 插入完整演示数据");
    }

    private void setSchedule(PreparedStatement ps, int cid, LocalDate date, String slot, int max, int curr) throws SQLException {
        ps.setInt(1, cid);
        ps.setDate(2, Date.valueOf(date));
        ps.setString(3, slot);
        ps.setInt(4, max);
        ps.setInt(5, curr);
        ps.setString(6, "AVAILABLE");
    }

    private void setAlert(PreparedStatement ps, int sid, String level, String type, 
                          String reason, String status, int cid, String record, Timestamp ts) throws SQLException {
        ps.setInt(1, sid);
        ps.setString(2, level);
        ps.setString(3, type);
        ps.setString(4, reason);
        ps.setString(5, status);
        ps.setInt(6, cid);
        if (record != null) ps.setString(7, record); else ps.setNull(7, Types.VARCHAR);
        ps.setTimestamp(8, ts);
    }

    private void setAppointment(PreparedStatement ps, int sid, int cid, LocalDate date, String slot,
                                String status, String topic, Timestamp created) throws SQLException {
        ps.setInt(1, sid);
        ps.setInt(2, cid);
        ps.setDate(3, Date.valueOf(date));
        ps.setString(4, slot);
        ps.setString(5, status);
        ps.setString(6, topic);
        ps.setTimestamp(7, created);
        ps.setTimestamp(8, created);  // updated = created
    }

    private void linkAlertsToAppointments(Connection conn, int s1Id, int s2Id) throws SQLException {
        // 学生1的高风险预警 -> 第一条待处理预约
        Statement stmt = conn.createStatement();
        stmt.executeUpdate(
            "UPDATE alert_record SET appointment_id = (" +
            "SELECT id FROM (SELECT id FROM appointment WHERE student_id=" + s1Id + 
            " AND status='PENDING' LIMIT 1) AS tmp" +
            ") WHERE student_id=" + s1Id + " AND status='PENDING' AND alert_level='HIGH' LIMIT 1"
        );

        // 学生2的高风险预警 -> 第二条待处理预约（或已确认的）
        stmt.executeUpdate(
            "UPDATE alert_record SET appointment_id = (" +
            "SELECT id FROM (SELECT id FROM appointment WHERE student_id=" + s2Id +
            " AND status IN ('PENDING', 'CONFIRMED') LIMIT 1) AS tmp" +
            ") WHERE student_id=" + s2Id + " AND status='PENDING' AND alert_level='HIGH' LIMIT 1"
        );
        stmt.close();
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
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return 0;
    }

    private long countRecords(Connection conn, String table, String condition) throws SQLException {
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM " + table + " WHERE " + condition);
        long cnt = rs.next() ? rs.getLong(1) : 0;
        rs.close();
        stmt.close();
        return cnt;
    }
}
