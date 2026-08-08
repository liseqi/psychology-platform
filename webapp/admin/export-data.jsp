<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%@ page import="com.psychology.entity.FileUpload" %>
<%@ page import="com.psychology.dao.FileUploadDao" %>
<%@ page import="com.psychology.util.CommonUtil" %>
<%@ page import="java.util.List" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"ADMIN".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
    // 从数据库加载所有用户的导出记录（最近20条）
    FileUploadDao fileUploadDao = new FileUploadDao();
    List<FileUpload> exportList = fileUploadDao.findByTypeAndUploader("EXPORT", null, 20);
%>
<%!
    String formatFileSize(Long size) {
        if (size == null) return "-";
        if (size < 1024) return size + " B";
        if (size < 1024 * 1024) return String.format("%.0f KB", size / 1024.0);
        return String.format("%.1f MB", size / (1024.0 * 1024));
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>数据导出 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .export-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; margin-top: 30px; }
        .export-card { background: white; border-radius: 12px; padding: 28px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .export-icon { font-size: 36px; margin-bottom: 16px; }
        .export-title { font-size: 18px; font-weight: 600; color: #333; margin-bottom: 10px; }
        .export-desc { color: #666; font-size: 14px; line-height: 1.6; margin-bottom: 20px; }
        .export-form { display: flex; flex-direction: column; gap: 12px; }
        .export-form label { font-size: 13px; color: #555; font-weight: 500; }
        .export-form input, .export-form select { padding: 10px 12px; border: 1px solid #ddd; border-radius: 6px; }
        .btn-export { padding: 12px 24px; background: linear-gradient(135deg,#667eea,#764ba2); color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; font-weight: 500; }
        .btn-export:hover { opacity: 0.9; transform: translateY(-1px); }
        .recent-exports { background: white; border-radius: 12px; padding: 24px; margin-top: 30px; }
        .recent-title { font-size: 18px; font-weight: 600; color: #333; margin-bottom: 16px; }
        .export-history { display: flex; flex-direction: column; gap: 10px; }
        .history-item { display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; background: #f8f9fa; border-radius: 8px; }
        .history-file { color: #333; font-size: 14px; }
        .history-time { color: #999; font-size: 13px; }
        .download-link { color: #667eea; text-decoration: none; font-size: 13px; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>📊 数据导出中心</h1>
            <p>导出系统统计报表与原始数据</p>
        </header>

        <div class="export-grid">
            <div class="export-card">
                <div class="export-icon">📈</div>
                <div class="export-title">测评数据报告</div>
                <div class="export-desc">导出指定时间范围内的学生心理测评数据，支持 Excel 格式</div>
                <div class="export-form" id="form-assessment">
                    <div><label>时间范围</label><input type="month" id="assess-month" value="2024-01"></div>
                    <div><label>量表类型</label><select id="assess-scale"><option value="">全部量表</option><option>SCL-90</option><option>PHQ-9</option><option>GAD-7</option></select></div>
                    <div><label>院系筛选</label><select id="assess-dept"><option value="">全部院系</option><option>计算机学院</option><option>文学院</option><option>理学院</option></select></div>
                    <button class="btn-export" onclick="doExport('assessment')">📥 导出测评报告</button>
                </div>
            </div>

            <div class="export-card">
                <div class="export-icon">🔔</div>
                <div class="export-title">预警数据汇总</div>
                <div class="export-desc">导出预警记录及处理情况统计表</div>
                <div class="export-form" id="form-alert">
                    <div><label>开始日期</label><input type="date" id="alert-start" value="2024-01-01"></div>
                    <div><label>结束日期</label><input type="date" id="alert-end" value="2024-01-31"></div>
                    <div><label>预警级别</label><select id="alert-level"><option value="">全部级别</option><option>HIGH</option><option>MEDIUM</option><option>LOW</option></select></div>
                    <button class="btn-export" onclick="doExport('alert')">📥 导出预警报告</button>
                </div>
            </div>

            <div class="export-card">
                <div class="export-icon">📅</div>
                <div class="export-title">预约咨询台账</div>
                <div class="export-desc">导出预约记录和咨询完成情况明细</div>
                <div class="export-form" id="form-appointment">
                    <div><label>月份</label><input type="month" id="appt-month" value="2024-01"></div>
                    <div><label>咨询师</label><select id="appt-counselor"><option value="">全部咨询师</option><option>王心理师</option><option>李辅导员</option></select></div>
                    <div><label>预约状态</label><select id="appt-status"><option value="">全部状态</option><option value="COMPLETED">已完成</option><option value="CANCELLED">已取消</option><option value="NO_SHOW">未到场</option></select></div>
                    <button class="btn-export" onclick="doExport('appointment')">📥 导出预约台账</button>
                </div>
            </div>

            <div class="export-card">
                <div class="export-icon">👥</div>
                <div class="export-title">用户基础数据</div>
                <div class="export-desc">导出注册用户的基本信息清单</div>
                <div class="export-form" id="form-user">
                    <div><label>角色筛选</label><select id="user-role"><option value="">所有角色</option><option value="STUDENT">仅学生</option><option value="COUNSELOR">仅咨询师</option></select></div>
                    <div><label>院系/部门</label><select id="user-dept"><option value="">全部</option><option>计算机学院</option><option>心理咨询中心</option></select></div>
                    <div><label>账号状态</label><select id="user-status"><option value="">全部</option><option value="1">正常</option><option value="0">禁用</option></select></div>
                    <button class="btn-export" onclick="doExport('user')">📥 导出用户数据</button>
                </div>
            </div>
        </div>

        <div class="recent-exports">
            <div class="recent-title">📁 最近导出记录</div>
            <div class="export-history">
                <% if (exportList.isEmpty()) { %>
                <div class="history-item" style="justify-content:center;color:#999;">
                    <span>暂无导出记录</span>
                </div>
                <% } else {
                    for (FileUpload fu : exportList) {
                        String icon = (fu.getFileName() != null && fu.getFileName().endsWith(".pdf")) ? "📄" : "📊";
                        String sizeStr = formatFileSize(fu.getFileSize());
                        String timeStr = (fu.getCreatedAt() != null)
                                ? new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm").format(fu.getCreatedAt()) : "-";
                %>
                <div class="history-item">
                    <div><span class="history-file"><%= icon %> <%= CommonUtil.escapeHtml(fu.getFileName()) %></span><span class="history-time"><%= timeStr %> · <%= sizeStr %></span></div>
                    <a class="download-link" href="../download?id=<%= fu.getId() %>">重新下载</a>
                </div>
                <% } } %>
            </div>
        </div>
    </main>

    <script>
        function doExport(type) {
            var params = [];
            if (type === 'assessment') {
                var m = document.getElementById('assess-month').value;
                if (m) {
                    params.push('startDate=' + encodeURIComponent(m + '-01'));
                    var date = new Date(m + '-01');
                    date.setMonth(date.getMonth() + 1);
                    date.setDate(0);
                    params.push('endDate=' + encodeURIComponent(date.toISOString().slice(0, 10)));
                }
                params.push('scaleType=' + encodeURIComponent(document.getElementById('assess-scale').value));
                params.push('department=' + encodeURIComponent(document.getElementById('assess-dept').value));
            } else if (type === 'alert') {
                params.push('startDate=' + encodeURIComponent(document.getElementById('alert-start').value));
                params.push('endDate=' + encodeURIComponent(document.getElementById('alert-end').value));
                params.push('level=' + encodeURIComponent(document.getElementById('alert-level').value));
            } else if (type === 'appointment') {
                var m = document.getElementById('appt-month').value;
                if (m) {
                    params.push('startDate=' + encodeURIComponent(m + '-01'));
                    var date = new Date(m + '-01');
                    date.setMonth(date.getMonth() + 1);
                    date.setDate(0);
                    params.push('endDate=' + encodeURIComponent(date.toISOString().slice(0, 10)));
                }
                params.push('counselor=' + encodeURIComponent(document.getElementById('appt-counselor').value));
                params.push('status=' + encodeURIComponent(document.getElementById('appt-status').value));
            } else if (type === 'user') {
                params.push('role=' + encodeURIComponent(document.getElementById('user-role').value));
                params.push('department=' + encodeURIComponent(document.getElementById('user-dept').value));
                params.push('status=' + encodeURIComponent(document.getElementById('user-status').value));
            }

            var url = '../statistics/export?type=' + encodeURIComponent(type) + '&' + params.join('&');
            window.open(url, '_blank');
        }
    </script>
</body>
</html>
