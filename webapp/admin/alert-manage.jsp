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
    <title>预警管理 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .filter-bar { background: white; padding: 16px 24px; border-radius: 10px; margin-bottom: 20px; display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
        .filter-bar select, .filter-bar input { padding: 8px 12px; border: 1px solid #ddd; border-radius: 6px; }
        .filter-bar button { padding: 8px 20px; background: #667eea; color: white; border: none; border-radius: 6px; cursor: pointer; }
        .alert-list { display: flex; flex-direction: column; gap: 12px; }
        .alert-item { background: white; padding: 20px; border-radius: 10px; display: flex; align-items: flex-start; gap: 16px; }
        .alert-level { width: 4px; height: 60px; border-radius: 2px; flex-shrink: 0; }
        .level-high { background: #ff4d4f; }
        .level-medium { background: #faad14; }
        .level-low { background: #52c41a; }
        .alert-content { flex: 1; }
        .alert-title { font-weight: 600; color: #333; margin-bottom: 6px; }
        .alert-desc { color: #666; font-size: 14px; }
        .alert-meta { color: #999; font-size: 12px; margin-top: 8px; }
        .alert-actions { display: flex; gap: 8px; }
        .btn-sm { padding: 6px 14px; border-radius: 5px; font-size: 13px; cursor: pointer; border: none; }
        .btn-primary { background: #667eea; color: white; }
        .btn-success { background: #52c41a; color: white; }
        
        /* 详情模态框样式 */
        .detail-modal { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; justify-content: center; align-items: center; }
        .detail-content { background: white; border-radius: 12px; padding: 30px; width: 600px; max-width: 90vw; max-height: 80vh; overflow-y: auto; }
        .detail-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 16px; border-bottom: 2px solid #f0f0f0; }
        .detail-title { font-size: 20px; font-weight: 600; color: #333; }
        .close-btn { font-size: 24px; cursor: pointer; color: #999; background: none; border: none; }
        .detail-section { margin-bottom: 20px; }
        .detail-label { font-weight: 600; color: #667eea; margin-bottom: 8px; font-size: 14px; }
        .detail-value { color: #333; line-height: 1.8; font-size: 14px; }
        .detail-row { display: flex; gap: 20px; margin-bottom: 12px; }
        .detail-item { flex: 1; }
        .handle-form { background: #f8f9fa; padding: 16px; border-radius: 8px; margin-top: 16px; }
        .form-group { margin-bottom: 12px; }
        .form-group label { display: block; margin-bottom: 4px; font-size: 13px; color: #555; }
        .form-group select, .form-group textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>🔔 预警管理</h1>
            <p>监控学生心理健康预警 · 及时干预处理</p>
        </header>

        <div class="filter-bar">
            <select id="levelFilter"><option value="">全部级别</option><option value="HIGH">高风险</option><option value="MEDIUM">中风险</option><option value="LOW">低风险</option></select>
            <select id="statusFilter"><option value="">全部状态</option><option value="PENDING">待处理</option><option value="PROCESSING">处理中</option><option value="RESOLVED">已解决</option></select>
            <input type="text" id="searchInput" placeholder="搜索学生姓名/学号...">
            <button onclick="loadAlerts()">筛选</button>
        </div>

        <div class="alert-list" id="alertList"></div>

        <div class="pagination" id="pagination"></div>
    </main>

    <!-- 预警详情模态框 -->
    <div class="detail-modal" id="detailModal" onclick="closeDetail(event)">
        <div class="detail-content" onclick="event.stopPropagation()">
            <div class="detail-header">
                <div class="detail-title">🔔 预警详情</div>
                <button class="close-btn" onclick="closeDetail()">&times;</button>
            </div>
            
            <div class="detail-section">
                <div class="detail-label">👤 学生信息</div>
                <div id="modalStudent" class="detail-value"></div>
            </div>
            
            <div class="detail-row">
                <div class="detail-item">
                    <div class="detail-label">📊 测评结果</div>
                    <div id="modalScore" class="detail-value"></div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">⚠️ 风险等级</div>
                    <div id="modalLevel" class="detail-value"></div>
                </div>
            </div>
            
            <div class="detail-section">
                <div class="detail-label">📝 详细描述</div>
                <div id="modalDesc" class="detail-value"></div>
            </div>
            
            <div class="detail-section">
                <div class="detail-label">⏱️ 时间线</div>
                <div id="modalTimeline" class="detail-value"></div>
            </div>
            
            <div class="handle-form">
                <div class="detail-label">📌 处理操作</div>
                <div class="form-group">
                    <label>处理方式</label>
                    <select id="handleType">
                        <option value="">请选择处理方式</option>
                        <option value="contact">联系学生谈话</option>
                        <option value="counselor">转介心理咨询</option>
                        <option value="parent">通知家长/辅导员</option>
                        <option value="hospital">建议就医</option>
                        <option value="monitor">持续观察</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>处理备注</label>
                    <textarea id="handleNote" rows="3" placeholder="输入处理过程和后续计划..."></textarea>
                </div>
                <div style="display:flex;gap:12px;justify-content:flex-end;">
                    <button class="btn-sm" style="background:#999;color:white;" onclick="closeDetail()">关闭</button>
                    <button class="btn-sm btn-primary" style="padding:10px 24px;" onclick="submitHandle()">✅ 提交处理</button>
                </div>
            </div>
        </div>
    </div>

    <script>
    var CTX = "<%=ctx%>";
    var currentPage = 1;
    var currentAlertId = null;
    var alertDataCache = [];

    window.onload = function() { loadAlerts(); };

    function loadAlerts() {
        var list = document.getElementById('alertList');
        list.innerHTML = '<div style="text-align:center;padding:40px;color:#999;">正在加载预警数据...</div>';

        var level = document.getElementById('levelFilter').value;
        var status = document.getElementById('statusFilter').value;

        var url = CTX + '/alert/list?page=' + currentPage + '&pageSize=10';
        if (level) url += '&level=' + level;
        if (status) url += '&status=' + status;

        fetch(url).then(function(r){return r.json();}).then(function(res){
            renderAlertList(res);
        }).catch(function(e){
            console.error(e);
            list.innerHTML = '<div style="text-align:center;padding:40px;color:#ff4d4f;">加载失败，请刷新重试</div>';
        });
    }

    function renderAlertList(res) {
        var list = document.getElementById('alertList');

        if(!res || res.code !== 200 || !res.data) {
            list.innerHTML = '<div style="text-align:center;padding:40px;color:#999;">暂无预警数据</div>';
            return;
        }

        var alerts = res.data;
        if(!Array.isArray(alerts)) alerts = [];
        alertDataCache = alerts;

        if(alerts.length === 0) {
            list.innerHTML = '<div style="text-align:center;padding:40px;color:#999;">暂无符合条件的预警记录</div>';
            return;
        }

        var html = '';
        for(var i=0;i<alerts.length;i++){
            var a = alerts[i];
            var levelClass = (a.alertLevel||'').toLowerCase();
            var levelText = {HIGH:'高风险',MEDIUM:'中风险',LOW:'低风险'}[a.alertLevel] || a.alertLevel;
            var statusText = {PENDING:'待处理',PROCESSING:'处理中',INTERVENING:'干预中',RESOLVED:'已解决'}[a.status] || a.status;
            
            html += '<div class="alert-item">' +
                '<div class="alert-level level-' + levelClass + '"></div>' +
                '<div class="alert-content">' +
                    '<div class="alert-title">[' + levelText + '] ' + esc(a.triggerReason||'预警') + '</div>' +
                    '<div class="alert-desc">学生：' + esc(a.studentName||'未知') + (a.scoreValue ? ' | 测评分：' + a.scoreValue : '') + '</div>' +
                    '<div class="alert-meta">' + formatTime(a.createdAt) + ' | 状态：' + statusText + '</div>' +
                '</div>' +
                '<div class="alert-actions">' +
                    (a.status === 'PENDING' ? '<button class="btn-sm btn-primary" onclick="handleAlert(this,'+a.id+')">立即处理</button>' : '') +
                    '<button class="btn-sm btn-success" onclick="viewDetail('+i+')">查看详情</button>' +
                '</div></div>';
        }
        list.innerHTML = html;
    }

    function handleAlert(btn, alertId) {
        btn.textContent = '已分配';
        btn.disabled = true;
        btn.style.background = '#999';
        viewDetailBy(alertId);
    }

    function viewDetail(index) {
        if(index >= 0 && index < alertDataCache.length){
            currentAlertId = alertDataCache[index].id;
            showDetailModal(alertDataCache[index]);
        }
    }

    function viewDetailBy(id) {
        currentAlertId = id;
        fetch(CTX+'/alert/detail?id='+id).then(function(r){return r.json();}).then(function(res){
            if(res.code===200 && res.data){ showDetailModal(res.data); }
        });
    }

    function showDetailModal(a){
        var levelText = {HIGH:'高风险',MEDIUM:'中风险',LOW:'低风险'}[a.alertLevel]||a.alertLevel;
        var statusText = {PENDING:'待处理',PROCESSING:'处理中',RESOLVED:'已解决'}[a.status]||a.status;
        
        document.getElementById('modalStudent').innerHTML = 
            '学生姓名：' + esc(a.studentName||'-') + '<br>预警类型：' + esc(a.alertType||'-') + '<br>当前状态：' + statusText;
        
        document.getElementById('modalScore').innerHTML = 
            '测评分值：' + (a.scoreValue?esc(String(a.scoreValue)):'-') + '<br>风险等级：' + levelText;
        
        var levelColorMap = {HIGH:'#ff4d4f',MEDIUM:'#faad14',LOW:'#52c41a'};
        var levelIconMap = {HIGH:'\uD83D\uDD34',MEDIUM:'\uD83D\uDFE1',LOW:'\uD83D\uDFE2'};
        document.getElementById('modalLevel').innerHTML = 
            '<span style="display:inline-block;padding:6px 16px;background:#fff2f0;color:'+(levelColorMap[a.alertLevel]||'#666')+';border-radius:6px;font-weight:600;">'+ 
            (levelIconMap[a.alertLevel]||'\u26A0\uFE0F')+' '+levelText+'预警</span>';
        
        document.getElementById('modalDesc').innerHTML = esc(a.triggerReason||'暂无详细描述');
        
        var timeline = '\u23F0\uFE0F ' + formatTime(a.createdAt) + ' \u9884\u8B66\u89E6\u53D1<br>';
        if(a.updatedAt) timeline += '\u23F0\uFE0F ' + formatTime(a.updatedAt) + ' \u6700\u540E\u66F4\u65B0';
        if(a.interventionRecord) timeline += '<br><br>\uD83D\uDDDD\uFE0F \u5904\u7406\u8BB0\u5F55：<br>' + esc(a.interventionRecord);
        document.getElementById('modalTimeline').innerHTML = timeline;
        
        document.getElementById('detailModal').style.display = 'flex';
    }

    function closeDetail(e) {
        if(!e || e.target === e.currentTarget) { document.getElementById('detailModal').style.display = 'none'; }
    }

    function submitHandle() {
        var handleType = document.getElementById('handleType').value;
        var note = document.getElementById('handleNote').value;
        var typeNames = {'contact':'联系学生谈话','counselor':'转介心理咨询','parent':'通知家长/辅导员','hospital':'建议就医','monitor':'持续观察'};

        if(!currentAlertId) { alert('请先选择要处理的预警记录'); return; }
        if(!handleType) { alert('请选择处理方式！'); return; }

        var recordText = '处理方式：' + (typeNames[handleType] || handleType);
        if(note) recordText += '\n处理备注：' + note;

        var body = 'id=' + currentAlertId +
                   '&status=PROCESSING' +
                   '&record=' + encodeURIComponent(recordText);

        fetch(CTX+'/alert/handle', {
            method:'POST',
            headers: {'Content-Type':'application/x-www-form-urlencoded'},
            body: body
        }).then(function(r){return r.json();}).then(function(d){
            if(d.code===200){
                alert('\u2705 \u5904\u7406\u8BB0\u5F55\u5DF2\u63D0\u4EA4!\n\n\u9884\u8B66ID\uFF1A' + currentAlertId + '\n' + recordText);
                closeDetail(); loadAlerts();
            } else{ alert('\u274C \u63D0\u4EA4\u5931\u8D25\uFF1A'+(d.message||'\u672A\u77E5\u9519\u8BEF')); }
        }).catch(function(){alert('\u7F51\u7EDC\u9519\u8BEF\uFF0C\u8BF7\u91CD\u8BD5');});
    }

    function formatTime(ts) {
        try {
            if(typeof ts==="string") return ts.substring(0,16).replace('T',' ');
            if(ts&&ts.year)return new Date(ts.year,ts.month-1,ts.dayOfMonth,ts.hourOfDay,ts.minute).toLocaleString("zh-CN",{year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'});
            if(ts instanceof Date) return ts.toLocaleString("zh-CN");
            return String(ts);
        }catch(e){return String(ts);}
    }
    function esc(s){if(!s)return '';return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}
    </script>
</body>
</html>