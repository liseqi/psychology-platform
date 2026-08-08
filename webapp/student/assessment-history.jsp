<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User currentUser = (User) session.getAttribute("currentUser");
    if (currentUser == null || !currentUser.isStudent()) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>测评历史记录</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        :root { --primary: #667eea; --success: #48bb78; --warning: #ed8936; --danger: #f56565; }
        body { font-family: 'Segoe UI', 'Microsoft YaHei', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .header { background: rgba(255,255,255,0.15); backdrop-filter: blur(10px); color: white; padding: 15px 30px; display: flex; justify-content: space-between; align-items: center; position: fixed; width: 100%; top: 0; z-index: 100; box-sizing: border-box; }
        .header h1 { font-size: 1.2rem; margin: 0; }
        .header a { color: white; text-decoration: none; opacity: 0.8; transition: 0.2s; }
        .header a:hover { opacity: 1; }
        main { padding: 80px 20px 30px; max-width: 900px; margin: 0 auto; }
        .card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .card-title { font-size: 1.1rem; font-weight: 600; color: #333; margin-bottom: 16px; display: flex; align-items: center; gap: 8px; }
        .scale-selector { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 16px; }
        .scale-btn { padding: 8px 16px; border: 1px solid #ddd; border-radius: 20px; background: #fff; cursor: pointer; transition: all 0.2s; font-size: 0.9rem; }
        .scale-btn:hover { border-color: var(--primary); color: var(--primary); }
        .scale-btn.active { background: var(--primary); color: white; border-color: var(--primary); }
        .empty-state { text-align: center; padding: 40px 20px; color: #999; }
        .empty-state .icon { font-size: 3rem; margin-bottom: 12px; }
        .record-table { width: 100%; border-collapse: collapse; }
        .record-table th, .record-table td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
        .record-table th { color: #888; font-weight: 500; font-size: 0.85rem; }
        .record-table tr:hover { background: #f8f9ff; }
        .record-table td { font-size: 0.95rem; color: #444; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 600; }
        .badge-low { background: #e6f7ed; color: #2f855a; }
        .badge-medium { background: #fff3e0; color: #c05621; }
        .badge-high { background: #ffe6e6; color: #c53030; }
        .chart-container { height: 220px; margin-top: 10px; position: relative; }
        .chart-canvas { width: 100%; height: 100%; }
        .btn-detail { padding: 4px 12px; border: 1px solid var(--primary); color: var(--primary); background: transparent; border-radius: 4px; cursor: pointer; font-size: 0.85rem; }
        .btn-detail:hover { background: var(--primary); color: white; }
        .modal-overlay { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 200; justify-content: center; align-items: center; }
        .modal-overlay.active { display: flex; }
        .modal { background: white; border-radius: 12px; width: 90%; max-width: 500px; max-height: 80vh; overflow-y: auto; padding: 24px; }
        .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .modal-header h3 { margin: 0; }
        .modal-close { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: #999; }
        .modal-close:hover { color: #333; }
        .detail-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #f0f0f0; }
        .detail-row:last-child { border-bottom: none; }
        .detail-label { color: #888; font-size: 0.9rem; }
        .detail-value { font-weight: 600; color: #333; }
        .score-highlight { font-size: 2rem; color: var(--primary); font-weight: 700; text-align: center; margin: 16px 0; }
        .advice-box { background: #f8f9ff; border-radius: 8px; padding: 16px; margin-top: 16px; color: #555; font-size: 0.9rem; line-height: 1.6; }
        .loading { text-align: center; padding: 20px; color: #999; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 测评历史记录</h1>
        <a href="dashboard.jsp">返回首页</a>
    </div>

    <main>
        <!-- 量表选择 -->
        <div class="card">
            <div class="card-title">📋 选择量表</div>
            <div class="scale-selector" id="scaleSelector">
                <div class="loading">加载中...</div>
            </div>
        </div>

        <!-- 趋势图 -->
        <div class="card" id="chartCard" style="display:none;">
            <div class="card-title">📈 得分趋势</div>
            <div class="chart-container">
                <canvas id="trendChart" class="chart-canvas"></canvas>
            </div>
        </div>

        <!-- 历史记录列表 -->
        <div class="card" id="historyCard" style="display:none;">
            <div class="card-title">📝 历史测评记录</div>
            <div id="historyList"></div>
        </div>
    </main>

    <!-- 详情弹窗 -->
    <div class="modal-overlay" id="modal">
        <div class="modal">
            <div class="modal-header">
                <h3>📋 测评详情</h3>
                <button class="modal-close" onclick="closeModal()">&times;</button>
            </div>
            <div id="modalContent"></div>
        </div>
    </div>

    <script>
        var CONTEXT_PATH = '${pageContext.request.contextPath}';
        var currentScaleId = null;
        var scaleList = [];
        var historyData = [];

        // 页面加载时获取量表列表
        document.addEventListener('DOMContentLoaded', function() {
            loadScaleList();
        });

        async function loadScaleList() {
            try {
                var resp = await fetch(CONTEXT_PATH + '/assessment/list');
                var result = await resp.json();
                if (result.code !== 200) {
                    document.getElementById('scaleSelector').innerHTML = '<div class="empty-state">加载量表失败</div>';
                    return;
                }
                scaleList = result.data || [];
                renderScaleSelector();
                // 默认加载第一个量表的历史
                if (scaleList.length > 0) {
                    selectScale(scaleList[0].id);
                } else {
                    document.getElementById('scaleSelector').innerHTML = '<div class="empty-state">暂无量表</div>';
                }
            } catch (e) {
                console.error(e);
                document.getElementById('scaleSelector').innerHTML = '<div class="empty-state">加载失败</div>';
            }
        }

        function renderScaleSelector() {
            var html = '';
            for (var i = 0; i < scaleList.length; i++) {
                var s = scaleList[i];
                html += '<button class="scale-btn" id="scaleBtn' + s.id + '" onclick="selectScale(' + s.id + ')">' + s.name + '</button>';
            }
            document.getElementById('scaleSelector').innerHTML = html;
        }

        async function selectScale(scaleId) {
            currentScaleId = scaleId;
            // 更新选中样式
            var btns = document.querySelectorAll('.scale-btn');
            for (var i = 0; i < btns.length; i++) {
                btns[i].classList.remove('active');
            }
            var btn = document.getElementById('scaleBtn' + scaleId);
            if (btn) btn.classList.add('active');

            // 加载历史记录
            document.getElementById('historyList').innerHTML = '<div class="loading">加载历史记录...</div>';
            document.getElementById('historyCard').style.display = 'block';
            document.getElementById('chartCard').style.display = 'block';

            try {
                var resp = await fetch(CONTEXT_PATH + '/assessment/history?scaleId=' + scaleId);
                var result = await resp.json();
                if (result.code !== 200) {
                    document.getElementById('historyList').innerHTML = '<div class="empty-state">' + (result.message || '加载失败') + '</div>';
                    document.getElementById('chartCard').style.display = 'none';
                    return;
                }
                historyData = result.data || [];
                renderHistoryList();
                renderChart();
            } catch (e) {
                console.error(e);
                document.getElementById('historyList').innerHTML = '<div class="empty-state">加载失败，请稍后重试</div>';
                document.getElementById('chartCard').style.display = 'none';
            }
        }

        function renderHistoryList() {
            if (historyData.length === 0) {
                document.getElementById('historyList').innerHTML =
                    '<div class="empty-state">' +
                    '<div class="icon">📝</div>' +
                    '<div>该量表暂无测评记录</div>' +
                    '<div style="font-size:0.85rem; margin-top:8px;">完成测评后，记录将显示在这里</div>' +
                    '</div>';
                document.getElementById('chartCard').style.display = 'none';
                return;
            }

            var html = '<table class="record-table"><thead><tr>' +
                '<th>日期</th><th>总分</th><th>风险等级</th><th>操作</th>' +
                '</tr></thead><tbody>';

            for (var i = 0; i < historyData.length; i++) {
                var r = historyData[i];
                var badgeClass = r.riskLevel === 'HIGH' ? 'badge-high' : (r.riskLevel === 'MEDIUM' ? 'badge-medium' : 'badge-low');
                var badgeText = r.riskLevel === 'HIGH' ? '高风险' : (r.riskLevel === 'MEDIUM' ? '中风险' : '低风险');
                html += '<tr>' +
                    '<td>' + (r.date || '-') + '</td>' +
                    '<td>' + (r.totalScore !== undefined ? r.totalScore : '-') + '</td>' +
                    '<td><span class="badge ' + badgeClass + '">' + badgeText + '</span></td>' +
                    '<td><button class="btn-detail" onclick="showDetail(' + r.id + ')">查看详情</button></td>' +
                    '</tr>';
            }
            html += '</tbody></table>';
            document.getElementById('historyList').innerHTML = html;
        }

        function renderChart() {
            if (historyData.length < 2) {
                document.getElementById('chartCard').style.display = 'none';
                return;
            }
            var canvas = document.getElementById('trendChart');
            var ctx = canvas.getContext('2d');
            var dpr = window.devicePixelRatio || 1;
            var rect = canvas.getBoundingClientRect();
            canvas.width = rect.width * dpr;
            canvas.height = rect.height * dpr;
            ctx.scale(dpr, dpr);
            var w = rect.width, h = rect.height;
            var pad = { top: 20, right: 20, bottom: 30, left: 40 };
            var chartW = w - pad.left - pad.right;
            var chartH = h - pad.top - pad.bottom;

            var scores = historyData.map(function(r) { return r.totalScore; });
            var minScore = Math.min.apply(null, scores) - 5;
            var maxScore = Math.max.apply(null, scores) + 5;
            if (minScore < 0) minScore = 0;
            var range = maxScore - minScore || 1;

            ctx.clearRect(0, 0, w, h);
            ctx.fillStyle = '#666'; ctx.font = '12px sans-serif'; ctx.textAlign = 'right';
            for (var i = 0; i <= 4; i++) {
                var y = pad.top + chartH - (i / 4) * chartH;
                var val = minScore + (i / 4) * range;
                ctx.fillText(Math.round(val), pad.left - 8, y + 4);
                ctx.strokeStyle = '#eee'; ctx.beginPath(); ctx.moveTo(pad.left, y); ctx.lineTo(pad.left + chartW, y); ctx.stroke();
            }
            ctx.strokeStyle = '#ccc'; ctx.lineWidth = 1;
            ctx.beginPath(); ctx.moveTo(pad.left, pad.top); ctx.lineTo(pad.left, pad.top + chartH); ctx.lineTo(pad.left + chartW, pad.top + chartH); ctx.stroke();

            ctx.strokeStyle = '#667eea'; ctx.lineWidth = 2; ctx.beginPath();
            for (var i = 0; i < historyData.length; i++) {
                var x = pad.left + (i / (historyData.length - 1)) * chartW;
                var y = pad.top + chartH - ((historyData[i].totalScore - minScore) / range) * chartH;
                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            }
            ctx.stroke();
            ctx.fillStyle = '#667eea';
            for (var i = 0; i < historyData.length; i++) {
                var x = pad.left + (i / (historyData.length - 1)) * chartW;
                var y = pad.top + chartH - ((historyData[i].totalScore - minScore) / range) * chartH;
                ctx.beginPath(); ctx.arc(x, y, 4, 0, Math.PI * 2); ctx.fill();
            }
            ctx.fillStyle = '#888'; ctx.textAlign = 'center'; ctx.font = '10px sans-serif';
            for (var i = 0; i < historyData.length; i++) {
                var x = pad.left + (i / (historyData.length - 1)) * chartW;
                ctx.fillText(historyData[i].date.substring(5), x, pad.top + chartH + 16);
            }
        }

        async function showDetail(recordId) {
            var modal = document.getElementById('modal');
            var content = document.getElementById('modalContent');
            content.innerHTML = '<div class="loading">加载中...</div>';
            modal.classList.add('active');

            try {
                var resp = await fetch(CONTEXT_PATH + '/assessment/detail?recordId=' + recordId);
                var result = await resp.json();
                if (result.code !== 200) {
                    content.innerHTML = '<div class="empty-state">' + (result.message || '加载失败') + '</div>';
                    return;
                }
                var r = result.data;
                var scaleName = '-';
                for (var i = 0; i < scaleList.length; i++) {
                    if (scaleList[i].id == r.scaleId) { scaleName = scaleList[i].name; break; }
                }
                var badgeClass = r.riskLevel === 'HIGH' ? 'badge-high' : (r.riskLevel === 'MEDIUM' ? 'badge-medium' : 'badge-low');
                var badgeText = r.riskLevel === 'HIGH' ? '高风险' : (r.riskLevel === 'MEDIUM' ? '中风险' : '低风险');
                var advice = '';
                if (r.riskLevel === 'HIGH') {
                    advice = '您的心理健康评分较高，建议尽快联系心理咨询师进行专业评估。可以通过预约咨询功能寻求帮助。';
                } else if (r.riskLevel === 'MEDIUM') {
                    advice = '您存在一定的心理困扰，建议关注自身情绪变化，适当放松，必要时可预约咨询。';
                } else {
                    advice = '您的心理健康状态良好，请继续保持积极的生活方式和心态。';
                }
                content.innerHTML =
                    '<div class="score-highlight">' + r.totalScore + '</div>' +
                    '<div style="text-align:center; margin-bottom:16px;"><span class="badge ' + badgeClass + '">' + badgeText + '</span></div>' +
                    '<div class="detail-row"><span class="detail-label">量表</span><span class="detail-value">' + scaleName + '</span></div>' +
                    '<div class="detail-row"><span class="detail-label">测评日期</span><span class="detail-value">' + (r.createdAt ? r.createdAt.substring(0, 10) : '-') + '</span></div>' +
                    '<div class="detail-row"><span class="detail-label">答题时长</span><span class="detail-value">' + (r.durationSeconds ? Math.round(r.durationSeconds / 60) + '分钟' : '-') + '</span></div>' +
                    '<div class="detail-row"><span class="detail-label">完成题数</span><span class="detail-value">' + (r.totalQuestions || '-') + '</span></div>' +
                    '<div class="advice-box"><strong>💡 建议：</strong>' + advice + '</div>';
            } catch (e) {
                console.error(e);
                content.innerHTML = '<div class="empty-state">加载失败</div>';
            }
        }

        function closeModal() {
            document.getElementById('modal').classList.remove('active');
        }

        // 点击遮罩关闭弹窗
        document.getElementById('modal').addEventListener('click', function(e) {
            if (e.target === this) closeModal();
        });

        // 窗口大小变化时重绘图表
        window.addEventListener('resize', function() {
            if (historyData.length >= 2) renderChart();
        });
    </script>
</body>
</html>
