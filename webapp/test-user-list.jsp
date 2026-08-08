<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    // 设置响应类型
    response.setContentType("application/json;charset=UTF-8");
    response.setHeader("Cache-Control", "no-cache");
    
    request.setCharacterEncoding("UTF-8");
    
    String action = request.getParameter("action");
    StringBuilder json = new StringBuilder();
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/psychology?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true",
            "root", "123456"
        );
        
        // 默认 action 是 list
        if (action == null || action.isEmpty() || "list".equals(action)) {
            // 接收查询参数
            String roleFilter = request.getParameter("role");
            String statusFilter = request.getParameter("status");
            String keyword = request.getParameter("keyword");
            String pageStr = request.getParameter("page");
            String pageSizeStr = request.getParameter("pageSize");
            
            int pg = 1;
            int pgSz = 10;
            try { pg = Integer.parseInt(pageStr); } catch (Exception e) {}
            if (pg < 1) pg = 1;
            try { pgSz = Integer.parseInt(pageSizeStr); } catch (Exception e) {}
            if (pgSz < 1) pgSz = 10;
            
            // 构建 WHERE 条件
            StringBuilder where = new StringBuilder("WHERE 1=1");
            boolean hasRole = roleFilter != null && !roleFilter.isEmpty();
            boolean hasStatus = statusFilter != null && !statusFilter.isEmpty();
            boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
            String k = hasKeyword ? "%" + keyword.trim() + "%" : null;
            
            if (hasRole) where.append(" AND role=?");
            if (hasStatus) where.append(" AND status=?");
            if (hasKeyword) where.append(" AND (username LIKE ? OR real_name LIKE ? OR student_id LIKE ?)");
            
            // 先查总数
            PreparedStatement countPs = conn.prepareStatement("SELECT COUNT(*) FROM sys_user " + where.toString());
            int idx = 1;
            if (hasRole) countPs.setString(idx++, roleFilter);
            if (hasStatus) countPs.setInt(idx++, Integer.parseInt(statusFilter));
            if (hasKeyword) { countPs.setString(idx++, k); countPs.setString(idx++, k); countPs.setString(idx++, k); }
            ResultSet countRs = countPs.executeQuery();
            int total = 0;
            if (countRs.next()) total = countRs.getInt(1);
            countRs.close();
            countPs.close();
            
            int totalPages = (int) Math.ceil((double) total / pgSz);
            if (totalPages < 1) totalPages = 1;
            if (pg > totalPages) pg = totalPages;
            int offset = (pg - 1) * pgSz;
            
            // 查询分页数据
            PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM sys_user " + where.toString() + " ORDER BY id DESC LIMIT ? OFFSET ?"
            );
            idx = 1;
            if (hasRole) ps.setString(idx++, roleFilter);
            if (hasStatus) ps.setInt(idx++, Integer.parseInt(statusFilter));
            if (hasKeyword) { ps.setString(idx++, k); ps.setString(idx++, k); ps.setString(idx++, k); }
            ps.setInt(idx++, pgSz);
            ps.setInt(idx++, offset);
            ResultSet rs = ps.executeQuery();
            
            StringBuilder listJson = new StringBuilder("[");
            boolean first = true;
            
            while (rs.next()) {
                if (!first) listJson.append(",");
                first = false;
                
                int id = rs.getInt("id");
                String username = rs.getString("username");
                String realName = rs.getString("real_name");
                String role = rs.getString("role");
                String studentId = rs.getString("student_id");
                String dept = rs.getString("department");
                Timestamp lastLogin = rs.getTimestamp("last_login_time");
                int status = rs.getInt("status");
                
                username = username.replace("\\", "\\\\").replace("\"", "\\\"");
                realName = (realName != null ? realName.replace("\\", "\\\\").replace("\"", "\\\"") : "");
                role = role.replace("\\", "\\\\").replace("\"", "\\\"");
                dept = (dept != null ? dept.replace("\\", "\\\\").replace("\"", "\\\"") : "");
                studentId = (studentId != null ? studentId.replace("\\", "\\\\").replace("\"", "\\\"") : "");
                String lastLoginStr = (lastLogin != null ? lastLogin.toString().substring(0, 16) : "");
                
                listJson.append("{")
                    .append("\"id\":").append(id).append(",")
                    .append("\"username\":\"").append(username).append("\",")
                    .append("\"realName\":\"").append(realName).append("\",")
                    .append("\"role\":\"").append(role).append("\",")
                    .append("\"studentId\":\"").append(studentId).append("\",")
                    .append("\"department\":\"").append(dept).append("\",")
                    .append("\"lastLoginTime\":\"").append(lastLoginStr).append("\",")
                    .append("\"status\":").append(status)
                    .append("}");
            }
            
            listJson.append("]");
            
            rs.close();
            ps.close();
            
            json.append("{\"code\":200,\"message\":\"success\",\"data\":{\"list\":").append(listJson)
                .append(",\"total\":").append(total).append(",\"page\":").append(pg)
                .append(",\"pageSize\":").append(pgSz).append(",\"totalPages\":").append(totalPages).append("}}");
                
        } else if ("toggleStatus".equals(action)) {
            // 切换禁用/启用状态
            String idStr = request.getParameter("id");
            String statusStr = request.getParameter("status");
            
            if (idStr == null || idStr.isEmpty()) {
                out.print("{\"code\":400,\"message\":\"缺少ID参数\",\"data\":null}");
                return;
            }
            
            int newStatus = "0".equals(statusStr) ? 0 : 1;
            
            PreparedStatement ps = conn.prepareStatement(
                "UPDATE sys_user SET status=?, updated_at=NOW() WHERE id=?"
            );
            ps.setInt(1, newStatus);
            ps.setInt(2, Integer.parseInt(idStr));
            int rows = ps.executeUpdate();
            ps.close();
            
            if (rows > 0) {
                json.append("{\"code\":200,\"message\":\"").append(newStatus == 1 ? "已启用" : "已禁用").append("\",\"data\":null}");
            } else {
                json.append("{\"code\":500,\"message\":\"操作失败\",\"data\":null}");
            }
            
        } else if ("detail".equals(action)) {
            // 获取用户详情
            String idStr = request.getParameter("id");
            
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM sys_user WHERE id=?");
            ps.setInt(1, Integer.parseInt(idStr));
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                String username = rs.getString("username").replace("\\", "\\\\").replace("\"", "\\\"");
                String rName = rs.getString("real_name");
                rName = (rName != null ? rName.replace("\\", "\\\\").replace("\"", "\\\"") : "");
                String uRole = rs.getString("role");
                String uEmail = rs.getString("email");
                uEmail = (uEmail != null ? uEmail.replace("\\", "\\\\").replace("\"", "\\\"") : "");
                String uDept = rs.getString("department");
                uDept = (uDept != null ? uDept.replace("\\", "\\\\").replace("\"", "\\\"") : "");
                
                json.append("{\"code\":200,\"message\":\"success\",\"data\":{")
                   .append("\"id\":").append(rs.getInt("id")).append(",")
                   .append("\"username\":\"").append(username).append("\",")
                   .append("\"realName\":\"").append(rName).append("\",")
                   .append("\"role\":\"").append(uRole).append("\",")
                   .append("\"email\":\"").append(uEmail).append("\",")
                   .append("\"department\":\"").append(uDept).append("\"}}");
            } else {
                json.append("{\"code\":404,\"message\":\"用户不存在\",\"data\":null}");
            }
            rs.close();
            ps.close();
            
        } else if ("update".equals(action)) {
            // 更新用户信息
            String idStr = request.getParameter("id");
            String realName = request.getParameter("realName");
            String role = request.getParameter("role");
            String email = request.getParameter("email");
            String department = request.getParameter("department");
            
            PreparedStatement ps = conn.prepareStatement(
                "UPDATE sys_user SET real_name=?, role=?, email=?, department=?, updated_at=NOW() WHERE id=?"
            );
            ps.setString(1, realName);
            ps.setString(2, role);
            ps.setString(3, email != null && !email.isEmpty() ? email : "");
            ps.setString(4, department != null ? department : "");
            ps.setInt(5, Integer.parseInt(idStr));
            int rows = ps.executeUpdate();
            ps.close();
            
            if (rows > 0) {
                json.append("{\"code\":200,\"message\":\"更新成功\",\"data\":null}");
            } else {
                json.append("{\"code\":500,\"message\":\"更新失败\",\"data\":null}");
            }
            
        } else if ("add".equals(action)) {
            // 添加新用户
            String username = request.getParameter("username");
            String realName = request.getParameter("realName");
            String role = request.getParameter("role");
            String password = request.getParameter("password");
            String email = request.getParameter("email");
            String department = request.getParameter("department");
            
            if (username == null || username.isEmpty() || realName == null || realName.isEmpty() || role == null) {
                out.print("{\"code\":400,\"message\":\"请填写必填项：用户名、姓名、角色\",\"data\":null}");
                return;
            }
            
            // 检查用户名是否存在
            PreparedStatement checkPs = conn.prepareStatement("SELECT COUNT(*) FROM sys_user WHERE username=?");
            checkPs.setString(1, username);
            ResultSet checkRs = checkPs.executeQuery();
            boolean exists = false;
            if (checkRs.next() && checkRs.getInt(1) > 0) exists = true;
            checkRs.close();
            checkPs.close();
            
            if (exists) {
                json.append("{\"code\":400,\"message\":\"用户名已存在\",\"data\":null}");
            } else {
                // MD5密码加密
                String md5Pwd = password != null ? password : "123456";
                try {
                    java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
                    byte[] digest = md.digest(md5Pwd.getBytes("UTF-8"));
                    StringBuilder sb = new StringBuilder();
                    for (byte b : digest) sb.append(String.format("%02x", b));
                    md5Pwd = sb.toString();
                } catch (Exception e) {}
                
                PreparedStatement insertPs = conn.prepareStatement(
                    "INSERT INTO sys_user (username, password, salt, real_name, role, email, department, status, created_at) VALUES (?, ?, '', ?, ?, ?, ?, 1, NOW())",
                    Statement.RETURN_GENERATED_KEYS
                );
                insertPs.setString(1, username);
                insertPs.setString(2, md5Pwd);
                insertPs.setString(3, realName);
                insertPs.setString(4, role.toUpperCase());
                insertPs.setString(5, email != null ? email : "");
                insertPs.setString(6, department != null ? department : "");
                int rows = insertPs.executeUpdate();
                
                if (rows > 0) {
                    ResultSet keys = insertPs.getGeneratedKeys();
                    int newId = 0;
                    if (keys.next()) newId = keys.getInt(1);
                    keys.close();
                    insertPs.close();
                    
                    json.append("{\"code\":200,\"message\":\"用户创建成功\",\"data\":{\"userId\":").append(newId).append("}}");
                } else {
                    insertPs.close();
                    json.append("{\"code\":500,\"message\":\"用户创建失败\",\"data\":null}");
                }
            }
        } else {
            json.append("{\"code\":400,\"message\":\"未知操作类型:" + action + "\",\"data\":null}");
        }
        
        conn.close();
    } catch (Exception e) {
        json.append("{\"code\":500,\"message\":\"").append(e.getMessage().replace("\"", "\\\"")).append("\",\"data\":null}");
        e.printStackTrace();
    }
    
    out.print(json.toString());
%>
