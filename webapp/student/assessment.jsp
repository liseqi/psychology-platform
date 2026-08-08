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
    <title>心理测评 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .scale-list { display: grid; gap: 20px; margin-top: 24px; }
        .scale-card { background: white; border-radius: 12px; padding: 28px; display: flex; gap: 24px; align-items: flex-start; box-shadow: 0 2px 12px rgba(0,0,0,0.08); transition: all 0.2s; }
        .scale-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,0.12); }
        .scale-icon { font-size: 48px; width: 80px; height: 80px; display: flex; align-items: center; justify-content: center; background: #f0f5ff; border-radius: 16px; flex-shrink: 0; }
        .scale-info { flex: 1; }
        .scale-name { font-size: 20px; font-weight: 600; color: #333; margin-bottom: 8px; }
        .scale-desc { color: #666; line-height: 1.7; margin-bottom: 12px; }
        .scale-meta { display: flex; gap: 20px; color: #999; font-size: 14px; margin-bottom: 16px; }
        .btn-start { padding: 10px 32px; background: linear-gradient(135deg,#667eea,#764ba2); color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; font-weight: 500; transition: transform 0.2s; }
        .btn-start:hover { transform: scale(1.05); }
        .btn-disabled { background: #ccc; cursor: not-allowed; }
        .history-section { background: white; border-radius: 12px; padding: 24px; margin-top: 30px; }
        .history-title { font-size: 18px; font-weight: 600; margin-bottom: 16px; }
        .history-item { display: flex; justify-content: space-between; padding: 14px 0; border-bottom: 1px solid #eee; }
        .history-item:last-child { border-bottom: none; }
        .score-badge { padding: 4px 12px; border-radius: 12px; font-size: 13px; }
        .score-normal { background: #f6ffed; color: #52c41a; }
        .score-warning { background: #fff7e6; color: #d48806; }
        .score-danger { background: #fff2f0; color: #ff4d4f; }
        .loading { text-align: center; padding: 40px; color: #999; }
        .empty { text-align: center; padding: 40px; color: #999; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>📋 心理测评</h1>
            <p>定期进行心理健康测评，了解自身心理状态</p>
        </header>

        <div id="scaleList" class="scale-list">
            <div class="loading">正在加载量表...</div>
        </div>

        <div class="history-section">
            <div class="history-title">📊 我的测评记录</div>
            <div id="historyList">
                <div class="loading">正在加载记录...</div>
            </div>
        </div>
    </main>

    <script>
        var CONTEXT_PATH = '${pageContext.request.contextPath}';

        async function loadScales() {
            try {
                var resp = await fetch(CONTEXT_PATH + '/assessment/list');
                var result = await resp.json();
                if (result.code !== 200) {
                    document.getElementById('scaleList').innerHTML = '<div class="empty">加载失败</div>';
                    return;
                }
                var scales = result.data || [];
                if (scales.length === 0) {
                    document.getElementById('scaleList').innerHTML = '<div class="empty">暂无可用量表</div>';
                    return;
                }
                var html = '';
                for (var i = 0; i < scales.length; i++) {
                    var s = scales[i];
                    var icons = {'SCL90':'🧩', 'PHQ9':'😔', 'GAD7':'😰', 'SDS':'😔', 'SAS':'😰'};
                    var icon = icons[s.code] || '📝';
                    html += '<div class="scale-card">' +
                        '<div class="scale-icon">' + icon + '</div>' +
                        '<div class="scale-info">' +
                            '<div class="scale-name">' + (s.name || '未命名量表') + '</div>' +
                            '<div class="scale-desc">' + (s.description || '') + '</div>' +
                            '<div class="scale-meta">' +
                                '<span>📝 题目数：' + (s.totalQuestions || '--') + '题</span>' +
                                '<span>⏱️ 预计用时：' + (s.timeLimit ? s.timeLimit + '分钟' : '15-20分钟') + '</span>' +
                                '<span>🔄 建议周期：每月一次</span>' +
                            '</div>' +
                            '<button class="btn-start" onclick="startAssessment(' + s.id + ', \'' + s.code + '\')">开始测评 →</button>' +
                        '</div>' +
                    '</div>';
                }
                document.getElementById('scaleList').innerHTML = html;
            } catch (e) {
                console.error(e);
                document.getElementById('scaleList').innerHTML = '<div class="empty">加载失败</div>';
            }
        }

        async function loadHistory() {
            try {
                // 获取最近几条记录（简化展示，通过后端获取历史记录）
                var resp = await fetch(CONTEXT_PATH + '/assessment/history?scaleId=1');
                var result = await resp.json();
                var html = '';
                if (result.code === 200 && result.data && result.data.length > 0) {
                    var records = result.data.slice(-3).reverse(); // 最近3条
                    for (var i = 0; i < records.length; i++) {
                        var r = records[i];
                        var badgeClass = r.riskLevel === 'HIGH' ? 'score-danger' : (r.riskLevel === 'MEDIUM' ? 'score-warning' : 'score-normal');
                        var badgeText = r.riskLevel === 'HIGH' ? '高风险' : (r.riskLevel === 'MEDIUM' ? '中风险' : '低风险');
                        html += '<div class="history-item">' +
                            '<div><strong>SCL-90症状自评量表</strong></div>' +
                            '<div style="display:flex;align-items:center;gap:12px;">' +
                                '<span style="color:#999;">' + r.date + '</span>' +
                                '<span class="score-badge ' + badgeClass + '">' + badgeText + ' (' + r.totalScore + '分)</span>' +
                            '</div>' +
                        '</div>';
                    }
                } else {
                    html = '<div class="empty">暂无测评记录</div>';
                }
                document.getElementById('historyList').innerHTML = html;
            } catch (e) {
                document.getElementById('historyList').innerHTML = '<div class="empty">加载失败</div>';
            }
        }

        function startAssessment(scaleId, code) {
            var tips = {
                'SCL90': '请根据最近一周的实际感受回答以下90个问题，预计用时15-20分钟。',
                'PHQ9': '请根据最近两周的实际感受回答以下9个问题，预计用时2-3分钟。',
                'GAD7': '请根据最近两周的实际感受回答以下7个问题，预计用时2分钟。'
            };
            var tip = tips[code] || '请根据实际感受回答以下问题。';
            if (confirm(tip + ' 请确保环境安静、时间充足。确定开始吗？')) {
                location.href = 'assessment-do.jsp?scaleId=' + scaleId;
            }
        }

        loadScales();
        loadHistory();
    </script>
</body>
</html>
