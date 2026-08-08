<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%@ page import="com.psychology.entity.FileUpload" %>
<%@ page import="com.psychology.dao.FileUploadDao" %>
<%@ page import="java.util.List" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"COUNSELOR".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
    FileUploadDao fileUploadDao = new FileUploadDao();
    List<FileUpload> exportList = fileUploadDao.findByTypeAndUploader("EXPORT", user.getId(), 20);
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>台账导出 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .export-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 24px; margin-top: 24px; }
        .export-card { background: white; border-radius: 12px; padding: 28px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .card-icon { font-size: 36px; margin-bottom: 16px; }
        .card-title { font-size: 18px; font-weight: 600; color: #333; margin-bottom: 10px; }
        .card-desc { color: #666; font-size: 14px; line-height: 1.6; margin-bottom: 20px; }
        .form-group { margin-bottom: 14px; }
        .form-group label { display: block; font-size: 13px; color: #555; margin-bottom: 6px; font-weight: 500; }
        .form-group select, .form-group input { width: 100%; padding: 10px 12px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box; }
        .btn-export { width: 100%; padding: 12px; background: linear-gradient(135deg,#667eea,#764ba2); color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; font-weight: 500; }
        .btn-export:hover { opacity: 0.92; }
        .recent-section { background: white; border-radius: 12px; padding: 24px; margin-top: 30px; }
        .recent-title { font-size: 18px; font-weight: 600; margin-bottom: 16px; }
        .history-table { width: 100%; border-collapse: collapse; }
        .history-table th { background: #f8f9fa; padding: 12px; text-align: left; font-size: 13px; color: #555; }
        .history-table td { padding: 12px; border-top: 1px solid #eee; font-size: 14px; color: #555; }
        .download-link { color: #667eea; text-decoration: none; cursor: pointer; }
        .download-link:hover { text-decoration: underline; }
    </style>
    <%!
        String formatFileSize(Long size) {
            if (size == null) return "-";
            if (size < 1024) return size + " B";
            if (size < 1024 * 1024) return String.format("%.0f KB", size / 1024.0);
            return String.format("%.1f MB", size / (1024.0 * 1024));
        }
    %>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-page-header">
            <h1>📊 台账导出</h1>
            <p>导出个人工作台账与统计数据报表</p>
        </header>

        <div class="export-cards">
            <div class="export-card">
                <div class="card-icon">📋</div>
                <div class="card-title">咨询记录台账</div>
                <div class="card-desc">导出指定时间段内的所有咨询记录明细，包含来访者信息、咨询内容摘要、处置建议等。</div>
                <div class="form-group">
                    <label>开始日期</label>
                    <input type="date" value="2024-01-01">
                </div>
                <div class="form-group">
                    <label>结束日期</label>
                    <input type="date" value="2024-01-31">
                </div>
                <div class="form-group">
                    <label>记录状态</label>
                    <select><option value="ALL">全部</option><option value="ONGOING">进行中</option><option value="COMPLETED">已结案</option></select>
                </div>
                <button class="btn-export" onclick="doExport('records')">📥 导出咨询台账</button>
            </div>

            <div class="export-card">
                <div class="card-icon">⚠️</div>
                <div class="card-title">预警处理记录</div>
                <div class="card-desc">导出负责处理的预警事件及跟进情况汇总表。</div>
                <div class="form-group">
                    <label>月份</label>
                    <input type="month" value="2024-01">
                </div>
                <div class="form-group">
                    <label>预警级别</label>
                    <select><option value="ALL">全部</option><option value="HIGH">高风险</option><option value="MEDIUM">中风险</option><option value="LOW">低风险</option></select>
                </div>
                <div class="form-group">
                    <label>处理状态</label>
                    <select><option value="ALL">全部</option><option value="PENDING">待处理</option><option value="PROCESSING">处理中</option><option value="RESOLVED">已完结</option></select>
                </div>
                <button class="btn-export" onclick="doExport('alerts')">📥 导出预警台账</button>
            </div>

            <div class="export-card">
                <div class="card-icon">📈</div>
                <div class="card-title">工作量统计报告</div>
                <div class="card-desc">生成个人月度/季度工作量统计图表报告，含咨询人次、时长、满意度等数据。</div>
                <div class="form-group">
                    <label>统计周期</label>
                    <select><option value="2024-01">2024年1月</option><option value="2024-Q1">2024年第1季度</option><option value="2024">2024年度</option></select>
                </div>
                <div class="form-group">
                    <label>包含内容</label>
                    <select><option value="ALL">全部指标</option><option value="ONLY_COUNT">仅咨询量</option><option value="WITH_SATISFACTION">含满意度评分</option></select>
                </div>
                <div class="form-group">
                    <label>输出格式</label>
                    <select><option value="excel">Excel (.xlsx)</option><option value="pdf">PDF报告</option></select>
                </div>
                <button class="btn-export" onclick="doExport('stats')">📥 导出统计报告</button>
            </div>
        </div>

        <div class="recent-section">
            <div class="recent-title">📁 最近导出记录</div>
            <table class="history-table">
                <thead>
                    <tr><th>文件名</th><th>导出时间</th><th>大小</th><th>操作</th></tr>
                </thead>
                <tbody>
                <% if (exportList.isEmpty()) { %>
                <tr><td colspan="4" style="text-align:center;color:#999;padding:24px;">暂无导出记录</td></tr>
                <% } else { %>
                    <% for (FileUpload fu : exportList) {
                        String icon = fu.getFileName().endsWith(".pdf") ? "📄" : "📊";
                        String sizeStr = formatFileSize(fu.getFileSize());
                        String timeStr = (fu.getCreatedAt() != null)
                                ? new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm").format(fu.getCreatedAt()) : "-";
                    %>
                    <tr>
                        <td><%= icon %> <%= com.psychology.util.CommonUtil.escapeHtml(fu.getFileName()) %></td>
                        <td><%= timeStr %></td>
                        <td><%= sizeStr %></td>
                        <td><a class="download-link" href="../download?id=<%= fu.getId() %>">重新下载</a></td>
                    </tr>
                    <% } %>
                <% } %>
            </tbody>
            </table>
        </div>
    </main>

    <script>
        var CTX = '${pageContext.request.contextPath}';
        
        function doExport(type) {
            var names = {'records':'咨询记录台账','alerts':'预警处理记录','stats':'工作量统计报告'};
            if(!confirm('确认导出【' + (names[type] || '数据') + '】吗？\n\n格式：Excel (.xlsx)\n预计等待时间：10-30秒')) return;
            
            var url = CTX + '/counselor/export/';
            var params = [];
            
            if (type === 'records') {
                url += 'records';
                // 收集表单参数
                var cards = document.querySelectorAll('.export-card');
                if (cards.length >= 1) {
                    var inputs = cards[0].querySelectorAll('input, select');
                    if (inputs.length >= 2) params.push('startDate=' + encodeURIComponent(inputs[0].value));
                    if (inputs.length >= 2) params.push('endDate=' + encodeURIComponent(inputs[1].value));
                    if (inputs.length >= 3) params.push('status=' + encodeURIComponent(inputs[2].value));
                }
            } else if (type === 'alerts') {
                url += 'alerts';
                var cards = document.querySelectorAll('.export-card');
                if (cards.length >= 2) {
                    var inputs = cards[1].querySelectorAll('input, select');
                    if (inputs.length >= 1) params.push('month=' + encodeURIComponent(inputs[0].value));
                    if (inputs.length >= 2) params.push('level=' + encodeURIComponent(inputs[1].value));
                    if (inputs.length >= 3) params.push('status=' + encodeURIComponent(inputs[2].value));
                }
            } else if (type === 'stats') {
                url += 'stats';
                var cards = document.querySelectorAll('.export-card');
                if (cards.length >= 3) {
                    var inputs = cards[2].querySelectorAll('input, select');
                    if (inputs.length >= 1) params.push('period=' + encodeURIComponent(inputs[0].value));
                    if (inputs.length >= 2) params.push('content=' + encodeURIComponent(inputs[1].value));
                    if (inputs.length >= 3) {
                        params.push('format=' + encodeURIComponent(inputs[2].value));
                    }
                }
            }
            
            if (params.length > 0) url += '?' + params.join('&');
            
            // 直接触发浏览器下载（ExportServlet 返回 Content-Disposition: attachment）
            window.open(url, '_blank');
            
            // 3秒后刷新页面以显示最新导出记录
            setTimeout(function() { location.reload(); }, 3000);
        }

        // 下载链接不再拦截，直接使用真实下载链接（DownloadServlet）
        // 原有拦截代码已移除
    </script>
</body>
</html>
