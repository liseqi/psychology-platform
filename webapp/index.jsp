<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // 根据角色跳转到对应仪表板
    String redirectUrl = "student/dashboard.jsp";
    if ("COUNSELOR".equals(user.getRole())) {
        redirectUrl = "counselor/dashboard.jsp";
    } else if ("ADMIN".equals(user.getRole())) {
        redirectUrl = "admin/dashboard.jsp";
    }
    response.sendRedirect(redirectUrl);
%>
