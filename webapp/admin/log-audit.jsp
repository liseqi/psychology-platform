<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"ADMIN".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>操作审计 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        * { box-sizing: border-box; }
        
        body {
            background: #f0f2f5;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            margin: 0;
            padding: 0;
        }

        .main-container {
            max-width: 1400px;
            margin: 20px auto;
            padding: 0 24px;
        }

        .page-header {
            margin-bottom: 24px;
        }
        .page-header h1 {
            font-size: 22px;
            font-weight: 600;
            color: #1a1a2e;
            margin: 0 0 8px 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .page-header h1::before {
            content: "";
            display: inline-block;
            width: 4px;
            height: 22px;
            background: linear-gradient(135deg, #667eea, #764ba2);
            border-radius: 2px;
        }
        .page-header p {
            color: #8c8c8c;
            font-size: 14px;
            margin: 0;
        }

        /* 筛选栏 */
        .filter-card {
            background: #fff;
            border-radius: 12px;
            padding: 20px 24px;
            box-shadow: 0 1px 4px rgba(0,0,0,0.06);
            margin-bottom: 20px;
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 16px;
        }
        .filter-group {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .filter-group label {
            color: #595959;
            font-size: 13px;
            white-space: nowrap;
        }
        .filter-group input,
        .filter-group select {
            height: 36px;
            border: 1px solid #d9d9d9;
            border-radius: 6px;
            padding: 0 12px;
            font-size: 13px;
            outline: none;
            transition: all 0.3s;
            background: #fafafa;
        }
        .filter-group input:focus,
        .filter-group select:focus {
            border-color: #667eea;
            background: #fff;
            box-shadow: 0 0 0 3px rgba(102,126,234,0.1);
        }
        .btn-search {
            height: 36px;
            padding: 0 20px;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: #fff;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            transition: all 0.3s;
        }
        .btn-search:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(102,126,234,0.35); }
        .btn-reset {
            height: 36px;
            padding: 0 16px;
            background: #fff;
            color: #595959;
            border: 1px solid #d9d9d9;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            transition: all 0.3s;
        }
        .btn-reset:hover { border-color: #667eea; color: #667eea; }
        .btn-export {
            height: 36px;
            padding: 0 18px;
            background: linear-gradient(135deg, #11998e, #38ef7d);
            color: #fff;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            margin-left: auto;
            transition: all 0.3s;
        }
        .btn-export:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(17,153,142,0.35); }

        /* 统计卡片 */
        .stats-row {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: #fff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 1px 4px rgba(0,0,0,0.06);
            position: relative;
        }
        .stat-card::before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
        }
        .stat-card.blue::before { background: linear-gradient(90deg, #1890ff, #69c0ff); }
        .stat-card.green::before { background: linear-gradient(90deg, #52c41a, #95de64); }
        .stat-card.orange::before { background: linear-gradient(90deg, #fa8c16, #ffc53d); }
        .stat-card.red::before { background: linear-gradient(90deg, #ff4d4f, #ff7875); }
        .stat-body { padding: 20px 24px; }
        .stat-label { font-size: 13px; color: #8c8c8c; margin-bottom: 10px; }
        .stat-value {
            font-size: 32px;
            font-weight: 700;
            color: #262626;
            line-height: 1;
        }
        .stat-footer {
            margin-top: 12px;
            font-size: 12px;
            color: #bfbfbf;
        }

        /* 日志容器 */
        .log-container {
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 1px 4px rgba(0,0,0,0.06);
            min-height: 400px;
        }
        .log-header {
            padding: 18px 24px;
            border-bottom: 1px solid #f0f0f0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .log-header h3 {
            margin: 0;
            font-size: 15px;
            color: #262626;
            font-weight: 600;
        }
        .log-count {
            font-size: 13px;
            color: #8c8c8c;
        }

        /* 时间线样式 */
        .timeline-list { padding: 16px 24px; }
        .log-item {
            display: flex;
            padding: 18px 0;
            border-bottom: 1px solid #fafafa;
            transition: background 0.2s;
        }
        .log-item:hover { background: #fafafa; margin: 0 -24px; padding: 18px 24px; }
        .log-item:last-child { border-bottom: none; }

        .log-time {
            width: 160px;
            flex-shrink: 0;
            text-align: right;
            padding-right: 24px;
        }
        .log-date {
            font-size: 13px;
            color: #8c8c8c;
        }
        .log-clock {
            font-size: 15px;
            font-weight: 500;
            color: #595959;
            margin-top: 4px;
        }

        .log-dot-wrapper {
            position: relative;
            width: 32px;
            flex-shrink: 0;
            display: flex;
            justify-content: center;
        }
        .log-dot-line {
            position: absolute;
            left: 50%;
            top: 32px;
            bottom: -18px;
            width: 2px;
            background: #f0f0f0;
            transform: translateX(-50%);
        }
        .log-item:last-child .log-dot-line { display: none; }
        .log-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #d9d9d9;
            z-index: 1;
            margin-top: 6px;
            border: 2px solid #fff;
        }
        .dot-login { background: #52c41a; box-shadow: 0 0 0 3px rgba(82,196,26,0.15); }
        .dot-logout { background: #8c8c8c; box-shadow: 0 0 0 3px rgba(140,140,140,0.15); }
        .dot-alert { background: #ff4d4f; box-shadow: 0 0 0 3px rgba(255,77,79,0.15); }
        .dot-data { background: #1890ff; box-shadow: 0 0 0 3px rgba(24,144,255,0.15); }
        .dot-export { background: #722ed1; box-shadow: 0 0 0 3px rgba(114,46,209,0.15); }

        .log-content {
            flex: 1;
            padding-left: 16px;
            min-width: 0;
        }
        .log-title-row {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 6px;
        }
        .type-badge {
            display: inline-block;
            padding: 2px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        .badge-login { background: #f6ffed; color: #389e0d; border: 1px solid #b7eb8f; }
        .badge-logout { background: #f5f5f5; color: #595959; border: 1px solid #d9d9d9; }
        .badge-alert { background: #fff2f0; color: #cf1322; border: 1px solid #ffccc7; }
        .badge-handle { background: #e6fffb; color: #08979c; border: 1px solid #87e8de; }
        .badge-view { background: #fff7e6; color: #d46b08; border: 1px solid #ffd591; }
        .badge-export { background: #f9f0ff; color: #531dab; border: 1px solid #d3adf7; }

        .log-title {
            font-size: 14px;
            font-weight: 500;
            color: #262626;
        }
        .log-desc {
            font-size: 13px;
            color: #8c8c8c;
            line-height: 1.5;
            margin-top: 4px;
        }
        .log-meta {
            display: flex;
            gap: 16px;
            margin-top: 10px;
            font-size: 12px;
            color: #bfbfbf;
        }
        .meta-item { display: flex; align-items: center; gap: 4px; }

        .log-operator {
            width: 120px;
            flex-shrink: 0;
            text-align: center;
        }
        .operator-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 8px;
            font-size: 14px;
            font-weight: 600;
        }
        .avatar-admin { background: linear-gradient(135deg, #667eea, #764ba2); }
        .avatar-counselor { background: linear-gradient(135deg, #11998e, #38ef7d); }
        .avatar-student { background: linear-gradient(135deg, #fc4a1a, #f7b733); }
        .operator-name { font-size: 13px; color: #595959; font-weight: 500; }
        .operator-role { font-size: 11px; color: #bfbfbf; margin-top: 2px; }

        /* 分页 */
        .pagination-wrap {
            padding: 20px 24px;
            border-top: 1px solid #f0f0f0;
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
        }
        .page-btn {
            min-width: 36px;
            height: 36px;
            border: 1px solid #d9d9d9;
            border-radius: 6px;
            background: #fff;
            color: #595959;
            cursor: pointer;
            font-size: 13px;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .page-btn:hover:not(:disabled) { border-color: #667eea; color: #667eea; }
        .page-btn:disabled { opacity: 0.45; cursor: not-allowed; }
        .page-info { font-size: 13px; color: #8c8c8c; padding: 0 12px; }

        /* 加载状态 */
        .loading-state {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 80px 20px;
            color: #bfbfbf;
        }
        .loading-spinner {
            width: 40px;
            height: 40px;
            border: 3px solid #f0f0f0;
            border-top-color: #667eea;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
            margin-bottom: 16px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .empty-state {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 80px 20px;
            color: #bfbfbf;
        }
        .empty-icon {
            font-size: 48px;
            margin-bottom: 16px;
            opacity: 0.5;
        }

        @media (max-width: 1200px) {
            .stats-row { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 768px) {
            .stats-row { grid-template-columns: 1fr; }
            .filter-card { flex-direction: column; align-items: stretch; }
            .log-time { width: 100px; }
            .log-operator { width: 80px; }
        }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>

    <div class="main-container">
        <div class="page-header">
            <h1>操作审计日志</h1>
            <p>记录系统操作行为 · 追溯安全事件</p>
        </div>

        <!-- 筛选栏 -->
        <div class="filter-card">
            <div class="filter-group">
                <label>开始日期</label>
                <input type="date" id="startDate" style="width:150px;">
            </div>
            <div class="filter-group">
                <label>结束日期</label>
                <input type="date" id="endDate" style="width:150px;">
            </div>
            <div class="filter-group">
                <label>操作类型</label>
                <select id="logType" style="width:145px;">
                    <option value="">全部类型</option>
                    <option value="LOGIN">登录登出</option>
                    <option value="ALERT">预警操作</option>
                    <option value="EXPORT">数据导出</option>
                    <option value="VIEW">数据查看</option>
                </select>
            </div>
            <div class="filter-group">
                <label>角色</label>
                <select id="operatorRole" style="width:110px;">
                    <option value="">全部</option>
                    <option value="ADMIN">管理员</option>
                    <option value="COUNSELOR">咨询师</option>
                    <option value="STUDENT">学生</option>
                </select>
            </div>
            <button class="btn-search" onclick="doSearch()">查 询</button>
            <button class="btn-reset" onclick="resetFilters()">重 置</button>
            <button class="btn-export" onclick="doExport()">导出日志</button>
        </div>

        <!-- 统计卡片 -->
        <div class="stats-row">
            <div class="stat-card blue">
                <div class="stat-body">
                    <div class="stat-label">总记录数</div>
                    <div class="stat-value" id="totalCount">0</div>
                    <div class="stat-footer">累计操作日志</div>
                </div>
            </div>
            <div class="stat-card green">
                <div class="stat-body">
                    <div class="stat-label">登录操作</div>
                    <div class="stat-value" id="loginCount">0</div>
                    <div class="stat-footer">用户登录/退出</div>
                </div>
            </div>
            <div class="stat-card orange">
                <div class="stat-body">
                    <div class="stat-label">预警操作</div>
                    <div class="stat-value" id="alertCount">0</div>
                    <div class="stat-footer">预警触发/处理</div>
                </div>
            </div>
            <div class="stat-card red">
                <div class="stat-body">
                    <div class="stat-label">数据操作</div>
                    <div class="stat-value" id="exportCount">0</div>
                    <div class="stat-footer">导出/查看敏感数据</div>
                </div>
            </div>
        </div>

        <!-- 日志列表 -->
        <div class="log-container">
            <div class="log-header">
                <h3>日志记录</h3>
                <span class="log-count" id="recordInfo"></span>
            </div>
            <div id="logTimeline">
                <div class="loading-state">
                    <div class="loading-spinner"></div>
                    <span>正在加载...</span>
                </div>
            </div>
            <div class="pagination-wrap" id="pagination"></div>
        </div>
    </div>

    <script>
    var CTX = "<%=ctx%>";
    var currentPage = 1;
    var pageSize = 15;

    window.onload = function() { loadLogs(); };

    function loadLogs() {
        var el = document.getElementById("logTimeline");
        el.innerHTML = "<div class='loading-state'><div class='loading-spinner'></div><span>正在加载日志数据...</span></div>";

        var sd = document.getElementById("startDate").value || "";
        var ed = document.getElementById("endDate").value || "";
        var lt = document.getElementById("logType").value || "";
        var rl = document.getElementById("operatorRole").value || "";

        var url = CTX + "/log/list?page=" + currentPage + "&pageSize=" + pageSize;
        if (sd) url += "&startDate=" + encodeURIComponent(sd);
        if (ed) url += "&endDate=" + encodeURIComponent(ed);
        if (lt) url += "&type=" + encodeURIComponent(lt);
        if (rl) url += "&role=" + encodeURIComponent(rl);

        fetch(url).then(function(r){ return r.json(); }).then(renderData).catch(function(e){
            console.error(e);
            el.innerHTML = "<div class='empty-state'><span class='empty-icon'>!</span><span>加载失败，请刷新重试</span></div>";
        });
    }

    function renderData(data) {
        var el = document.getElementById("logTimeline");
        var pg = document.getElementById("pagination");

        if (!data || data.code !== 200 || !data.data) {
            el.innerHTML = "<div class='empty-state'><span class='empty-icon'>-</span><span>暂无日志数据</span></div>";
            pg.innerHTML = "";
            return;
        }

        var r = data.data;
        var list = r.list || [];
        var total = r.total || 0;
        var tp = r.totalPages || 1;

        // 更新统计
        animateNumber("totalCount", total);
        
        var s = {L:0,A:0,E:0};
        for (var i=0;i<list.length;i++) {
            var t = (list[i].operationType||"").toUpperCase();
            if (t.indexOf("LOGIN")>=0||t.indexOf("LOGOUT")>=0) s.L++;
            else if (t.indexOf("ALERT")>=0) s.A++;
            else if (t.indexOf("EXPORT")>=0) s.E++;
        }
        animateNumber("loginCount", s.L);
        animateNumber("alertCount", s.A);
        animateNumber("exportCount", s.E);
        document.getElementById("recordInfo").textContent = "共 " + total + " 条记录";

        if (list.length===0) {
            el.innerHTML = "<div class='empty-state'><span class='empty-icon'>~</span><span>暂无符合条件的日志记录</span></div>";
            pg.innerHTML = "";
            return;
        }

        var h = "<div class='timeline-list'>";
        for (var j=0;j<list.length;j++) {
            h += buildItem(list[j]);
        }
        h += "</div>";
        el.innerHTML = h;

        // 分页
        if (tp > 1) {
            var p = "";
            p += "<button class='page-btn' onclick='goPage(1)'"+(currentPage<=1?" disabled":"")+">&#8852;</button>";
            p += "<button class='page-btn' onclick='goPage("+(currentPage-1)+")'"+(currentPage<=1?" disabled":"")+">&lt;</button>";
            p += "<span class='page-info'>"+currentPage+" / "+tp+" 页</span>";
            p += "<button class='page-btn' onclick='goPage("+(currentPage+1)+")'"+(currentPage>=tp?" disabled":"")+">&gt;</button>";
            p += "<button class='page-btn' onclick='goPage("+tp+")'"+(currentPage>=tp?" disabled":"")+">&#8853;</button>";
            pg.innerHTML = p;
        } else {
            pg.innerHTML = "";
        }
    }

    function buildItem(it) {
        var t = (it.operationType||"").toUpperCase();
        var tm = it.createdAt ? fmtTime(it.createdAt) : "--";
        var parts = tm.split(" ");
        var datePart = parts[0] || "--";
        var timePart = parts[1] || "--";
        
        var role = (it.operatorRole||"").toUpperCase();
        var avatarCls = role === "ADMIN" ? "admin" : (role === "COUNSELOR" ? "counselor" : "student");
        var initial = (it.operatorName||"?").charAt(0).toUpperCase();
        
        var badgeInfo = getBadge(t);
        var dotClass = getDotClass(t);

        return "<div class='log-item'>" +
            "<div class='log-time'>" +
                "<div class='log-date'>"+datePart+"</div>" +
                "<div class='log-clock'>"+timePart+"</div>" +
            "</div>" +
            "<div class='log-dot-wrapper'>" +
                "<div class='log-dot "+dotClass+"'></div>" +
                "<div class='log-dot-line'></div>" +
            "</div>" +
            "<div class='log-content'>" +
                "<div class='log-title-row'>" +
                    "<span class='type-badge "+badgeInfo.cls+"'>"+badgeInfo.txt+"</span>" +
                    "<span class='log-title'>"+esc(getTitle(t))+"</span>" +
                "</div>" +
                "<div class='log-desc'>"+esc(it.targetDescription||it.detail||"无详细描述")+"</div>" +
                "<div class='log-meta'>" +
                    (it.ipAddress ? "<span class='meta-item'>IP: "+esc(it.ipAddress)+"</span>" : "") +
                "</div>" +
            "</div>" +
            "<div class='log-operator'>" +
                "<div class='operator-avatar avatar-"+avatarCls+"'>"+initial+"</div>" +
                "<div class='operator-name'>"+esc(it.operatorName||"--")+"</div>" +
                "<div class='operator-role'>"+getRoleName(it.operatorRole)+"</div>" +
            "</div>" +
        "</div>";
    }

    function getBadge(t) {
        if (t.indexOf("LOGIN")>=0) return {cls:"badge-login", txt:"登录"};
        if (t.indexOf("LOGOUT")>=0) return {cls:"badge-logout", txt:"退出"};
        if (t.indexOf("ALERT_TRIGGER")>=0) return {cls:"badge-alert", txt:"预警"};
        if (t.indexOf("ALERT_HANDLE")>=0) return {cls:"badge-handle", txt:"处理"};
        if (t.indexOf("VIEW")>=0) return {cls:"badge-view", txt:"查看"};
        if (t.indexOf("EXPORT")>=0) return {cls:"badge-export", txt:"导出"};
        return {cls:"", txt:t};
    }

    function getDotClass(t) {
        if (t.indexOf("LOGIN")>=0) return "dot-login";
        if (t.indexOf("LOGOUT")>=0) return "dot-logout";
        if (t.indexOf("ALERT")>=0) return "dot-alert";
        if (t.indexOf("VIEW")>=0) return "dot-data";
        if (t.indexOf("EXPORT")>=0) return "dot-export";
        return "";
    }

    function getTitle(t) {
        var m = {"LOGIN":"用户登录系统","LOGOUT":"用户退出系统","ALERT_TRIGGER":"触发高危预警","ALERT_HANDLE":"预警处理完成","EXPORT_SENSITIVE_DATA":"导出敏感数据","VIEW_SENSITIVE_DATA":"查看敏感信息","REPORT_EXPORT":"导出测评报告","ASSESSMENT_SUBMIT":"提交心理测评","APPOINTMENT_CREATE":"创建咨询预约","APPOINTMENT_CANCEL":"取消咨询预约"};
        return m[t] || t || "未知操作";
    }

    function getRoleName(r) {
        var m = {"ADMIN":"管理员","COUNSELOR":"咨询师","STUDENT":"学生"};
        return m[r] || r || "-";
    }

    function goPage(p) {
        currentPage = p;
        loadLogs();
        document.querySelector(".log-container").scrollIntoView({behavior:"smooth"});
    }

    function doSearch() { currentPage = 1; loadLogs(); }

    function resetFilters() {
        document.getElementById("startDate").value = "";
        document.getElementById("endDate").value = "";
        document.getElementById("logType").value = "";
        document.getElementById("operatorRole").value = "";
        currentPage = 1;
        loadLogs();
    }

    function doExport() {
        var sd = document.getElementById("startDate").value || "";
        var ed = document.getElementById("endDate").value || "";
        var lt = document.getElementById("logType").value || "";
        var rl = document.getElementById("operatorRole").value || "";
        var url = CTX+"/log/export?startDate="+encodeURIComponent(sd)+"&endDate="+encodeURIComponent(ed);
        if (lt) url += "&type="+encodeURIComponent(lt);
        if (rl) url += "&role="+encodeURIComponent(rl);
        fetch(url).then(function(r){return r.json();}).then(function(d){
            if (d.code===200 && d.data) {
                var list = d.data.exportData || [];
                if (list.length === 0) {
                    alert("没有可导出的数据");
                    return;
                }
                // 构建 CSV 内容（UTF-8 BOM 头确保 Excel 正确打开中文）
                var csv = "\uFEFF";
                csv += "操作时间,操作类型,操作者,角色,目标描述,IP地址\n";
                for (var i = 0; i < list.length; i++) {
                    var item = list[i];
                    var row = [
                        item.createdAt || "",
                        item.operationType || "",
                        item.operatorName || "",
                        item.operatorRole || "",
                        (item.targetDescription || item.detail || "").replace(/"/g, '""'),
                        item.ipAddress || ""
                    ];
                    csv += row.map(function(cell) { return '"' + cell + '"'; }).join(",") + "\n";
                }
                // 触发浏览器下载
                var blob = new Blob([csv], {type: "text/csv;charset=utf-8"});
                var a = document.createElement("a");
                a.href = URL.createObjectURL(blob);
                var now = new Date();
                a.download = "操作日志_" + now.getFullYear() + 
                    String(now.getMonth()+1).padStart(2,"0") + 
                    String(now.getDate()).padStart(2,"0") + "_" +
                    String(now.getHours()).padStart(2,"0") + 
                    String(now.getMinutes()).padStart(2,"0") + ".csv";
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(a.href);
            } else {
                alert("导出失败：" + (d.message||"未知错误"));
            }
        }).catch(function(e) {
            alert("导出失败：" + e.message);
        });
    }

    function fmtTime(ts) {
        try {
            if (typeof ts==="string") return ts;
            if (ts && ts.year) return new Date(ts.year,ts.month-1,ts.dayOfMonth,ts.hourOfDay,ts.minute,ts.second).toLocaleString("zh-CN",{year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'});
            if (ts instanceof Date) return ts.toLocaleString("zh-CN");
            return String(ts);
        } catch(e) { return String(ts); }
    }

    function esc(s) {
        if (!s) return "";
        return s.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
    }

    function animateNumber(id, val) {
        var el = document.getElementById(id);
        var cur = parseInt(el.textContent)||0;
        var diff = val - cur;
        var steps = 20;
        var stepVal = diff/steps;
        var i = 0;
        var timer = setInterval(function(){
            i++;
            if(i>=steps) {
                clearInterval(timer);
                el.textContent = val;
            } else {
                el.textContent = Math.round(cur + stepVal*i);
            }
        }, 25);
    }
    </script>
</body>
</html>
