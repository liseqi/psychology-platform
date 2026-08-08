<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"COUNSELOR".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>咨询师工作台 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css?v=2">
    <style>
        .alert-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .alert-card { background: white; border-radius: 12px; padding: 20px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.08); border-left: 4px solid; }
        .alert-card.high { border-color: #ff4d4f; background: linear-gradient(to right, #fff1f0, white); }
        .alert-card.medium { border-color: #faad14; background: linear-gradient(to right, #fffbe6, white); }
        .alert-card.low { border-color: #52c41a; background: linear-gradient(to right, #f6ffed, white); }
        .alert-count { font-size: 36px; font-weight: bold; margin: 8px 0; }
        .alert-card.high .alert-count { color: #ff4d4f; }
        .alert-card.medium .alert-count { color: #faad14; }
        .alert-card.low .alert-count { color: #52c41a; }

        .table-container { background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08); margin-top: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #fafafa; padding: 14px 16px; text-align: left; font-weight: 600; color: #333; border-bottom: 2px solid #e8e8e8; }
        td { padding: 12px 16px; border-bottom: 1px solid #f0f0f0; color: #555; }
        tr:hover { background: #fafafa; }
        .status-tag {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
        }
        .status-pending { background: #e6f7ff; color: #1890ff; }
        .status-processing { background: #fff7e6; color: #fa8c16; }
        .status-resolved { background: #f6ffed; color: #52c41a; }
        .risk-high { color: #ff4d4f; font-weight: bold; }
        .risk-medium { color: #faad14; font-weight: bold; }
        .risk-low { color: #52c41a; }
        
        /* 按钮样式 */
        .btn { padding: 6px 14px; border-radius: 6px; font-size: 13px; cursor: pointer; border: none; transition: all 0.2s; }
        .btn-primary { background: #667eea; color: white; }
        .btn-primary:hover { opacity: 0.9; }
        .btn-success { background: #52c41a; color: white; }
        .btn-success:hover { opacity: 0.9; }
        .btn-sm { padding: 4px 10px; font-size: 12px; }
        
        .tag { padding: 3px 10px; border-radius: 10px; font-size: 12px; }
        .tag-blue { background: #e6f7ff; color: #1890ff; }
        .tag-green { background: #f6ffed; color: #52c41a; }
        .tag-orange { background: #fff7e6; color: #fa8c16; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>咨询师工作台 - <%= user.getRealName() %></h1>
            <p>管理您的预警学生、预约排班和咨询记录</p>
        </header>

        <!-- 预警统计 -->
        <section>
            <h2 style="margin-bottom:16px;">🔔 预警概览</h2>
            <div class="alert-cards">
                <div class="alert-card high">
                    <div>高风险预警</div>
                    <div class="alert-count" id="highRiskCount">--</div>
                    <div style="color:#999;font-size:12px;">需立即处理</div>
                </div>
                <div class="alert-card medium">
                    <div>中风险预警</div>
                    <div class="alert-count" id="mediumRiskCount">--</div>
                    <div style="color:#999;font-size:12px;">需要关注</div>
                </div>
                <div class="alert-card low">
                    <div>低风险提醒</div>
                    <div class="alert-count" id="lowRiskCount">--</div>
                    <div style="color:#999;font-size:12px;">平台已提醒</div>
                </div>
                <div class="alert-card" style="border-color:#667eea;">
                    <div>今日预约</div>
                    <div class="alert-count" id="todayAppointments" style="color:#667eea;">--</div>
                    <div style="color:#999;font-size:12px;">待接待</div>
                </div>
            </div>
        </section>

        <!-- 预警列表 -->
        <section>
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
                <h2>⚠️ 名下预警学生</h2>
                <a href="alerts.jsp" style="color:#667eea;text-decoration:none;">查看全部 →</a>
            </div>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>学生（脱敏）</th>
                            <th>预警级别</th>
                            <th>触发原因</th>
                            <th>状态</th>
                            <th>创建时间</th>
                            <th>操作</th>
                        </tr>
                    </thead>
                    <tbody id="alertTableBody">
                        <tr><td colspan="6" style="text-align:center;padding:40px;">加载中...</td></tr>
                    </tbody>
                </table>
            </div>
        </section>

        <!-- 今日排班 -->
        <section style="margin-top:24px;">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
                <h2>📅 今日排班安排</h2>
                <a href="schedule.jsp" style="color:#667eea;text-decoration:none;">管理排班 →</a>
            </div>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>时段</th>
                            <th>学生（脱敏）</th>
                            <th>状态</th>
                            <th>操作</th>
                        </tr>
                    </thead>
                    <tbody id="scheduleBody">
                        <tr><td colspan="4" style="text-align:center;padding:40px;">加载中...</td></tr>
                    </tbody>
                </table>
            </div>
        </section>
    </main>

    <!-- Load JS with cache-busting version -->
    <script src="../js/counselor-dashboard.js?v=20260715j" charset="UTF-8"></script>
</body>
</html>
