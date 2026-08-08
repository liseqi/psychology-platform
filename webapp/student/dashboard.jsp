<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"STUDENT".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学生中心 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css?v=2">
    <style>
        .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin-top: 20px; }
        .card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); cursor: pointer; transition: all 0.3s; }
        .card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.12); }
        .card-icon { font-size: 48px; margin-bottom: 16px; }
        .card h3 { color: #333; margin-bottom: 8px; }
        .card p { color: #666; font-size: 14px; line-height: 1.5; }
        .quick-actions { display: flex; gap: 12px; margin-top: 30px; flex-wrap: wrap; }
        .btn-action {
            padding: 12px 24px;
            border-radius: 8px;
            border: none;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.2s;
        }
        .btn-primary { background: #667eea; color: white; }
        .btn-primary:hover { background: #5a6fd6; }
        .btn-success { background: #52c41a; color: white; }
        .btn-success:hover { background: #49b017; }
        .btn-warning { background: #faad14; color: white; }
        .btn-warning:hover { background: #e09c12; }
        .btn-info { background: #13c2c2; color: white; }
        .btn-info:hover { background: #11aeae; }
        
        .stats-row { display: flex; gap: 20px; margin-bottom: 24px; }
        .stat-card { flex: 1; background: white; border-radius: 12px; padding: 20px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        .stat-number { font-size: 32px; font-weight: bold; color: #667eea; }
        .stat-label { color: #666; margin-top: 4px; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>欢迎回来，<%= user.getRealName() %>同学 👋</h1>
            <p>今天也要好好照顾自己的心情哦~</p>
        </header>

        <div class="stats-row">
            <div class="stat-card">
                <div class="stat-number" id="assessmentCount">--</div>
                <div class="stat-label">测评次数</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="appointmentCount">--</div>
                <div class="stat-label">预约次数</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="unreadCount">--</div>
                <div class="stat-label">未读消息</div>
            </div>
        </div>

        <section>
            <h2 style="margin-bottom:16px;color:#333;">快捷功能</h2>
            <div class="dashboard">
                <div class="card" onclick="location.href='assessment.jsp'">
                    <div class="card-icon">📋</div>
                    <h3>心理测评</h3>
                    <p>完成专业量表测试，了解心理健康状态</p>
                </div>
                <div class="card" onclick="location.href='assessment-history.jsp'">
                    <div class="card-icon">📈</div>
                    <h3>历史报告</h3>
                    <p>查看历史测评对比，追踪心理健康趋势</p>
                </div>
                <div class="card" onclick="location.href='appointment.jsp'">
                    <div class="card-icon">📅</div>
                    <h3>预约咨询</h3>
                    <p>预约心理咨询师进行一对一交流</p>
                </div>
                <div class="card" onclick="location.href='chat.jsp'">
                    <div class="card-icon">💬</div>
                    <h3>AI树洞</h3>
                    <p>与AI倾诉心声，获取心理支持建议</p>
                </div>
                <div class="card" onclick="location.href='../article-pages/list.jsp'">
                    <div class="card-icon">📚</div>
                    <h3>科普文章</h3>
                    <p>阅读心理科普知识，提升自我认知</p>
                </div>
                <div class="card" onclick="location.href='consultation-history.jsp'">
                    <div class="card-icon">📁</div>
                    <h3>咨询记录</h3>
                    <p>查看过往咨询记录（脱敏展示）</p>
                </div>
            </div>
        </section>

        <div class="quick-actions">
            <button class="btn-action btn-primary" onclick="location.href='assessment.jsp'">
                🎯 开始测评
            </button>
            <button class="btn-action btn-success" onclick="location.href='appointment.jsp'">
                📅 预约咨询师
            </button>
            <button class="btn-action btn-info" onclick="location.href='chat.jsp'">
                💬 和AI聊聊天
            </button>
            <button class="btn-action btn-warning" onclick="location.href='profile.jsp'">
                ⚙️ 个人设置
            </button>
        </div>
    </main>

    <script src="../js/student-dashboard.js?v=20260715c-unicode-fix"></script>
</body>
</html>

