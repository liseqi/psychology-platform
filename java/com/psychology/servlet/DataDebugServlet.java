package com.psychology.servlet;

import com.psychology.util.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.*;

/**
 * 数据库数据诊断工具
 * 访问 /init/debug 查看当前数据和问题原因
 */
@WebServlet("/init/debug")
public class DataDebugServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        
        out.println("<!DOCTYPE html><html><head><title>数据诊断</title>");
        out.println("<style>body{font-family:Arial;padding:20px;} table{border-collapse:collapse;margin:10px 0;width:100%;}");
        out.println("th,td{border:1px solid #ddd;padding:8px;text-align:left;}");
        out.println("th{background:#f5f5f5;}.error{color:red;}.ok{color:green;}.warn{color:orange;}</style></head><body>");
        out.println("<h1>🔍 心理健康系统 - 数据诊断报告</h1>");
        out.println("<p>生成时间: " + new java.util.Date() + "</p>");

        try {
            Connection conn = DBUtil.getConnection();
            
            // 1. 显示所有用户
            out.println("<h2>📋 1. 系统用户列表</h2>");
            printTable(out, conn, "SELECT id, username, real_name, role FROM sys_user ORDER BY role, id");
            
            // 2. 当前登录用户信息（如果有的话）
            Object userObj = req.getSession().getAttribute("currentUser");
            if (userObj != null) {
                // 尝试获取用户信息（简化版）
                out.println("<h2 class='ok'>✅ 2. 当前登录用户</h2>");
                out.println("<p>Session中有 currentUser 对象</p>");
                
                // 通过反射获取用户ID（如果User对象可用）
                try {
                    java.lang.reflect.Field idField = userObj.getClass().getField("id");
                    int currentUserId = (int) idField.get(userObj);
                    out.println("<p>当前用户ID: <b>" + currentUserId + "</b></p>");
                    
                    // 查询该用户名下的预警记录
                    out.println("<h3>该用户的预警记录 (assigned_counselor_id=" + currentUserId + ")</h3>");
                    printTable(out, conn, 
                        "SELECT ar.id, ar.student_id, u.real_name as student_name, ar.alert_level, " +
                        "ar.status, ar.assigned_counselor_id FROM alert_record ar " +
                        "LEFT JOIN sys_user u ON ar.student_id = u.id WHERE ar.assigned_counselor_id=" + currentUserId);
                    
                    // 查询该用户的排班
                    out.println("<h3>该用户的今日排班 (counselor_id=" + currentUserId + ", 今天)</h3>");
                    printTable(out, conn,
                        "SELECT * FROM counselor_schedule WHERE counselor_id=" + currentUserId + 
                        " AND schedule_date=CURDATE()");
                    
                    // 查询该用户的预约
                    out.println("<h3>该用户的预约 (counselor_id=" + currentUserId + ")</h3>");
                    printTable(out, conn,
                        "SELECT a.id, a.student_id, u.real_name as student_name, a.appointment_date, " +
                        "a.time_slot, a.status FROM appointment a " +
                        "LEFT JOIN sys_user u ON a.student_id = u.id WHERE a.counselor_id=" + currentUserId);
                        
                } catch (Exception e) {
                    out.println("<p class='error'>无法获取用户详情: " + e.getMessage() + "</p>");
                }
            } else {
                out.println("<h2 class='warn'>⚠️ 2. 未登录</h2>");
                out.println("<p>请先登录咨询师账号后再访问此页面</p>");
            }

            // 3. 所有预警记录
            out.println("<h2>📊 3. 所有预警记录</h2>");
            long alertCount = getCount(conn, "SELECT COUNT(*) FROM alert_record");
            out.println("<p>总记录数: <b>" + alertCount + "</b></p>");
            if (alertCount > 0) {
                printTable(out, conn,
                    "SELECT ar.id, ar.student_id, u.real_name as student_name, ar.alert_level, " +
                    "ar.status, ar.assigned_counselor_id, ar.created_at FROM alert_record ar " +
                    "LEFT JOIN sys_user u ON ar.student_id = u.id ORDER BY ar.created_at DESC LIMIT 10");
            } else {
                out.println("<p class='warn'>⚠️ 预警表为空！需要初始化演示数据。</p>");
            }

            // 4. 所有排班
            out.println("<h2>📅 4. 排班数据</h2>");
            long scheduleCount = getCount(conn, "SELECT COUNT(*) FROM counselor_schedule WHERE schedule_date=CURDATE()");
            out.println("<p>今日排班数: <b>" + scheduleCount + "</b></p>");
            printTable(out, conn,
                "SELECT cs.*, u.real_name as counselor_name FROM counselor_schedule cs " +
                "LEFT JOIN sys_user u ON cs.counselor_id = u.id WHERE cs.schedule_date >= CURDATE() LIMIT 15");

            // 5. 所有预约
            out.println("<h2>📝 5. 预约数据</h2>");
            long appointmentCount = getCount(conn, "SELECT COUNT(*) FROM appointment");
            out.println("<p>总预约数: <b>" + appointmentCount + "</b></p>");
            if (appointmentCount > 0) {
                printTable(out, conn,
                    "SELECT a.id, a.student_id, s.real_name as student_name, a.counselor_id, " +
                    "c.real_name as counselor_name, a.appointment_date, a.time_slot, a.status " +
                    "FROM appointment a " +
                    "LEFT JOIN sys_user s ON a.student_id = s.id " +
                    "LEFT JOIN sys_user c ON a.counselor_id = c.id " +
                    "ORDER BY a.appointment_date ASC LIMIT 10");
            }

            // 6. 问题诊断建议
            out.println("<h2>💡 6. 问题诊断</h2>");
            diagnoseIssues(out, conn, req);

            out.println("</body></html>");
            
        } catch (Exception e) {
            out.println("<div class='error'>错误: " + e.getMessage() + "</div>");
            e.printStackTrace(out);
        }
    }

    private void printTable(PrintWriter out, Connection conn, String sql) throws SQLException {
        Statement stmt = null;
        ResultSet rs = null;
        try {
            stmt = conn.createStatement();
            rs = stmt.executeQuery(sql);
            ResultSetMetaData meta = rs.getMetaData();
            int colCount = meta.getColumnCount();

            out.println("<table><tr>");
            for (int i = 1; i <= colCount; i++) {
                out.println("<th>" + meta.getColumnName(i) + "</th>");
            }
            out.println("</tr>");

            boolean hasData = false;
            while (rs.next()) {
                hasData = true;
                out.println("<tr>");
                for (int i = 1; i <= colCount; i++) {
                    Object val = rs.getObject(i);
                    String display = val == null ? "<i style='color:#999'>NULL</i>" : val.toString();
                    out.println("<td>" + display + "</td>");
                }
                out.println("</tr>");
            }

            if (!hasData) {
                out.println("<tr><td colspan='" + colCount + "' class='warn' style='text-align:center'>无数据</td></tr>");
            }
            out.println("</table>");
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
        }
    }

    private long getCount(Connection conn, String sql) throws SQLException {
        Statement stmt = null;
        ResultSet rs = null;
        try {
            stmt = conn.createStatement();
            rs = stmt.executeQuery(sql);
            return rs.next() ? rs.getLong(1) : 0;
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
        }
    }

    private void diagnoseIssues(PrintWriter out, Connection conn, HttpServletRequest req) throws SQLException {
        List<String> issues = new ArrayList<>();
        List<String> suggestions = new ArrayList<>();

        // 检查1: 是否有预警记录
        long alertCount = getCount(conn, "SELECT COUNT(*) FROM alert_record");
        if (alertCount == 0) {
            issues.add("❌ 预警表完全为空");
            suggestions.add("→ 访问 /init/demo 初始化演示数据");
        }

        // 检查2: 预警是否关联了正确的咨询师
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(
            "SELECT DISTINCT assigned_counselor_id, COUNT(*) as cnt FROM alert_record GROUP BY assigned_counselor_id");
        Map<Integer, Long> counselorAlerts = new HashMap<>();
        while (rs.next()) {
            counselorAlerts.put(rs.getInt(1), rs.getLong(2));
        }

        // 获取当前登录用户ID
        try {
            Object userObj = req.getSession().getAttribute("currentUser");
            if (userObj != null) {
                java.lang.reflect.Field idField = userObj.getClass().getField("id");
                int currentId = (int) idField.get(userObj);
                
                if (!counselorAlerts.containsKey(currentId)) {
                    issues.add("❌ 当前用户(ID:" + currentId + ")没有分配任何预警记录");
                    suggestions.add("→ 预警记录关联的咨询师ID: " + counselorAlerts.keySet());
                    suggestions.add("→ 可能是初始化数据时使用了错误的咨询师ID");
                } else {
                    out.println("<p class='ok'>✅ 当前用户有 " + counselorAlerts.get(currentId) + " 条预警记录</p>");
                }
            }
        } catch (Exception e) {}

        // 检查3: 排班
        long todaySchedule = getCount(conn, 
            "SELECT COUNT(*) FROM counselor_schedule WHERE schedule_date=CURDATE() AND status='AVAILABLE'");
        if (todaySchedule == 0) {
            issues.add("❌ 今日无排班设置");
            suggestions.add("→ 排班需要提前在排班管理中设置");
        } else {
            out.println("<p class='ok'>✅ 今日有 " + todaySchedule + " 个可预约时段</p>");
        }

        // 输出问题列表
        if (!issues.isEmpty()) {
            out.println("<div style='background:#fff3f3;border-left:4px solid #ff4d4f;padding:15px;margin:10px 0;'>");
            for (String issue : issues) {
                out.println("<p class='error'>" + issue + "</p>");
            }
            out.println("<hr><strong>解决方案:</strong><ul>");
            for (String suggestion : suggestions) {
                out.println("<li>" + suggestion + "</li>");
            }
            out.println("</ul></div>");
        } else {
            out.println("<div class='ok'><h3>✅ 未发现明显问题</h3>");
            out.println("<p>如果仍然看不到数据，请检查浏览器控制台(F12)是否有JavaScript错误</p>");
            out.println("<p>或查看Network标签页，确认API请求返回的数据</p></div>");
        }
    }
}
