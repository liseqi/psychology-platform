package com.psychology.servlet;

import com.psychology.util.DBUtil;
import com.psychology.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * 终极诊断工具 - 测试每一步SQL
 */
@WebServlet("/init/debug2")
public class DebugServlet2 extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        
        try {
            Connection conn = DBUtil.getConnection();
            
            out.println("{");
            out.println("  \"code\": 200,");
            out.println("  \"data\": {");
            
            // ===== 测试1: 直接查询 alert_record =====
            out.println("    \"test1_raw_count\": ");
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM alert_record");
            out.print(rs.next() ? rs.getLong(1) : 0);
            out.println(",");
            rs.close();
            
            // ===== 测试2: 查询前5条原始数据（不含JOIN）=====
            out.println("    \"test2_raw_data\": [");
            rs = stmt.executeQuery("SELECT id, student_id, alert_level, status, created_at FROM alert_record LIMIT 5");
            boolean first = true;
            while (rs.next()) {
                if (!first) out.println(",");
                first = false;
                out.printf("      {\"id\":%d,\"student_id\":%d,\"level\":\"%s\",\"status\":\"%s\"}",
                    rs.getLong("id"), rs.getInt("student_id"), 
                    rs.getString("alert_level"), rs.getString("status"));
            }
            out.println("\n    ],");
            rs.close();
            
            // ===== 测试3: LEFT JOIN sys_user（不JOIN appointment）=====
            out.println("    \"test3_join_user_count\": ");
            String sql3 = "SELECT COUNT(*) FROM alert_record ar LEFT JOIN sys_user u ON ar.student_id = u.id";
            rs = stmt.executeQuery(sql3);
            out.print(rs.next() ? rs.getLong(1) : 0);
            out.println(",");
            rs.close();
            
            // ===== 测试4: 完整的 findList SQL =====
            out.println("    \"test4_full_join_count\": ");
            String sql4 = 
                "SELECT ar.*, u.real_name as student_name, " +
                "a.appointment_date as apt_date, a.time_slot as apt_time_slot, a.status as apt_status, " +
                "a.student_confirmation_status as apt_student_confirmation_status " +
                "FROM alert_record ar " +
                "LEFT JOIN sys_user u ON ar.student_id = u.id " +
                "LEFT JOIN appointment a ON ar.appointment_id = a.id " +
                "WHERE 1=1 " +
                "ORDER BY ar.created_at DESC LIMIT 10";
            
            PreparedStatement ps = conn.prepareStatement(sql4);
            ResultSet rs4 = ps.executeQuery();
            int fullJoinCount = 0;
            while (rs4.next()) fullJoinCount++;
            out.print(fullJoinCount);
            out.println(",");
            rs4.close();
            ps.close();
            
            // ===== 测试5: 如果完整JOIN有数据，显示前3条详情 =====
            out.println("    \"test5_sample_records\": [");
            ps = conn.prepareStatement(sql4);
            rs4 = ps.executeQuery();
            first = true;
            int sampleIdx = 0;
            while (rs4.next() && sampleIdx < 3) {
                if (!first) out.println(",");
                first = false;
                sampleIdx++;
                
                long id = rs4.getLong("id");
                int studentId = rs4.getInt("student_id");
                String studentName = rs4.getString("student_name");
                String level = rs4.getString("alert_level");
                String status = rs4.getString("status");
                
                // 检查每个字段是否能读取
                StringBuilder fieldCheck = new StringBuilder();
                fieldCheck.append("\"id_readable\":true");
                
                try { int sid = rs4.getInt("student_id"); fieldCheck.append(",\"student_id_readable\":true"); } 
                catch (Exception e) { fieldCheck.append(",\"student_id_readable:false\":\"" + e.getMessage() + "\""); }
                
                try { String lvl = rs4.getString("alert_level"); fieldCheck.append(",\"level_readable\":true"); } 
                catch (Exception e) { fieldCheck.append(",\"level_readable:false\":\"" + e.getMessage() + "\""); }
                
                try { String st = rs4.getString("status"); fieldCheck.append(",\"status_readable\":true"); } 
                catch (Exception e) { fieldCheck.append(",\"status_readable:false\":\"" + e.getMessage() + "\""); }
                
                try { Timestamp ct = rs4.getTimestamp("created_at"); fieldCheck.append(",\"created_at_readable\":true"); } 
                catch (Exception e) { fieldCheck.append(",\"created_at_readable:false\":\"" + e.getMessage() + "\""); }
                
                out.printf("      {\"id\":%d,\"studentId\":%d,\"studentName\":\"%s\",\"level\":\"%s\",\"status\":\"%s\",\"fields\":{%s}}",
                    id, studentId, 
                    studentName != null ? studentName : "NULL",
                    level != null ? level : "NULL",
                    status != null ? status : "NULL",
                    fieldCheck.toString());
            }
            out.println("\n    ],");
            rs4.close();
            ps.close();
            
            // ===== 测试6: 检查sys_user表中的学生数据 =====
            out.println("    \"test6_student_check\": [");
            rs = stmt.executeQuery("SELECT DISTINCT ar.student_id, u.real_name, u.role FROM alert_record ar LEFT JOIN sys_user u ON ar.student_id = u.id LIMIT 10");
            first = true;
            while (rs.next()) {
                if (!first) out.println(",");
                first = false;
                int sid = rs.getInt("student_id");
                String name = rs.getString("real_name");
                String role = rs.getString("role");
                out.printf("      {\"student_id\":%d,\"name\":\"%s\",\"role\":\"%s\",\"existsInSysUser\":%b}",
                    sid, name != null ? name : "NULL", role != null ? role : "NULL", name != null);
            }
            out.println("\n   ]");
            rs.close();
            stmt.close();
            
            out.println("  },");
            out.println("  \"message\": \"终极诊断完成\"");
            out.println("}");
            
        } catch (Exception e) {
            e.printStackTrace(out);
        }
    }
}
