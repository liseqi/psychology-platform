<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User currentUser = (User) session.getAttribute("currentUser");
    String roleLabel = "学生";
    String roleClass = "";
    if (currentUser != null) {
        switch(currentUser.getRole()) {
            case "COUNSELOR": roleLabel = "咨询师"; break;
            case "ADMIN": roleLabel = "管理员"; break;
            default: roleLabel = "学生"; break;
        }
    }
    // 获取当前请求URI用于判断激活状态
    String requestUri = request.getRequestURI();
%>
<nav class="navbar">
    <div class="navbar-inner">
        <a href="${pageContext.request.contextPath}/index.jsp" class="navbar-brand">
            🧠 心理健康系统
        </a>
        
        <ul class="navbar-nav">
            <% if (currentUser != null && "STUDENT".equals(currentUser.getRole())) { %>
                <li><a href="${pageContext.request.contextPath}/student/dashboard.jsp" class="nav-link <%= requestUri.contains("student/dashboard") ? "active" : "" %>">仪表板</a></li>
                <li><a href="${pageContext.request.contextPath}/student/assessment.jsp" class="nav-link <%= requestUri.contains("student/assessment") ? "active" : "" %>">心理测评</a></li>
                <li><a href="${pageContext.request.contextPath}/student/appointment.jsp" class="nav-link <%= requestUri.contains("student/appointment") ? "active" : "" %>">预约咨询</a></li>
                <li><a href="${pageContext.request.contextPath}/student/chat.jsp" class="nav-link <%= requestUri.contains("student/chat") ? "active" : "" %>">AI树洞</a></li>
                <li><a href="${pageContext.request.contextPath}/article-pages/list.jsp" class="nav-link <%= requestUri.contains("article-pages") ? "active" : "" %>">科普文章</a></li>
            <% } else if (currentUser != null && "COUNSELOR".equals(currentUser.getRole())) { %>
                <li><a href="${pageContext.request.contextPath}/counselor/dashboard.jsp" class="nav-link <%= requestUri.contains("counselor/dashboard") ? "active" : "" %>">工作台</a></li>
                <li><a href="${pageContext.request.contextPath}/counselor/alerts.jsp" class="nav-link <%= requestUri.contains("counselor/alerts") ? "active" : "" %>">预警管理</a></li>
                <li><a href="${pageContext.request.contextPath}/counselor/schedule.jsp" class="nav-link <%= requestUri.contains("counselor/schedule") ? "active" : "" %>">排班管理</a></li>
                <li><a href="${pageContext.request.contextPath}/counselor/records.jsp" class="nav-link <%= requestUri.contains("counselor/records") ? "active" : "" %>">咨询记录</a></li>
                <li><a href="${pageContext.request.contextPath}/counselor/export.jsp" class="nav-link <%= requestUri.contains("counselor/export") ? "active" : "" %>">台账导出</a></li>
            <% } else if (currentUser != null && "ADMIN".equals(currentUser.getRole())) { %>
                <li><a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-link <%= requestUri.contains("admin/dashboard") || requestUri.endsWith("/index.jsp") || requestUri.equals("/") ? "active" : "" %>">数据大屏</a></li>
                <li><a href="${pageContext.request.contextPath}/admin/alert-manage.jsp" class="nav-link <%= requestUri.contains("admin/alert-manage") ? "active" : "" %>">预警管理</a></li>
                <li><a href="${pageContext.request.contextPath}/admin/scale-manage.jsp" class="nav-link <%= requestUri.contains("admin/scale-manage") ? "active" : "" %>">量表题库</a></li>
                <li><a href="${pageContext.request.contextPath}/admin/article-manage.jsp" class="nav-link <%= requestUri.contains("admin/article-manage") ? "active" : "" %>">文章审核</a></li>
                <li><a href="${pageContext.request.contextPath}/admin/user-manage.jsp" class="nav-link <%= requestUri.contains("admin/user-manage") ? "active" : "" %>">账号管理</a></li>
                <li><a href="${pageContext.request.contextPath}/admin/log-audit.jsp" class="nav-link <%= requestUri.contains("admin/log-audit") ? "active" : "" %>">操作审计</a></li>
            <% } %>
            
            <li class="nav-user-info" style="flex-wrap:nowrap;white-space:nowrap;gap:8px;">
                <div class="nav-user-avatar">👤</div>
                <span class="nav-user-name" style="display:inline;white-space:nowrap;"><%= currentUser != null ? currentUser.getRealName() : "" %></span>
                <span class="nav-user-role" style="white-space:nowrap;"><%= roleLabel %></span>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/logout" class="nav-link" title="退出登录">退出</a>
            </li>
        </ul>
    </div>
</nav>
