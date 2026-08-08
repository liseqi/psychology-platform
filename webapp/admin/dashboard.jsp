<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"ADMIN".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>管理控制台 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css?v=2">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .stat-card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); position: relative; overflow: hidden; }
        .stat-card::before { content:'';position:absolute;top:0;left:0;width:100%;height:4px; }
        .stat-card.blue::before { background: #667eea; }
        .stat-card.green::before { background: #52c41a; }
        .stat-card.orange::before { background: #faad14; }
        .stat-card.red::before { background: #ff4d4f; }
        .stat-value { font-size: 36px; font-weight: bold; color: #333; margin: 12px 0 8px; }
        .stat-label { color: #666; font-size: 14px; }
        
        .charts-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px; margin-top: 24px; }
        @media (max-width: 900px) { .charts-grid { grid-template-columns: 1fr; } }

        .chart-card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        .chart-title { font-size: 18px; font-weight: 600; color: #333; margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between; }
        .chart-container { height: 300px; }

        .admin-actions { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); 
            gap: 16px;
            margin-top: 30px;
        }
        .admin-btn {
            background: white;
            border: 2px solid #e8e8e8;
            border-radius: 10px;
            padding: 20px;
            cursor: pointer;
            transition: all 0.2s;
            text-align: center;
            text-decoration: none;
            color: #333;
        }
        .admin-btn:hover { border-color: #667eea; color: #667eea; transform: translateY(-2px); }
        .admin-btn-icon { font-size: 32px; margin-bottom: 8px; display: block; }
        .admin-btn-text { font-size: 15px; font-weight: 500; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>数据大屏</h1>
            <p>全校心理健康数据概览 · 实时监控预警态势</p>
        </header>

        <!-- 核心数据指标 -->
        <section class="stats-grid" id="statsGrid">
            <div class="stat-card blue">
                <div class="stat-label">注册学生总数</div>
                <div class="stat-value" id="totalStudents">--</div>
                <div style="color:#999;font-size:12px;">活跃用户统计</div>
            </div>
            <div class="stat-card green">
                <div class="stat-label">今日测评完成数</div>
                <div class="stat-value" id="todayAssessments">--</div>
                <div style="color:#999;font-size:12px;">较昨日 +12%</div>
            </div>
            <div class="stat-card orange">
                <div class="stat-label">待处理预警</div>
                <div class="stat-value" id="pendingAlerts">--</div>
                <div style="color:#999;font-size:12px;">需及时跟进处理</div>
            </div>
            <div class="stat-card red">
                <div class="stat-label">高风险学生数</div>
                <div class="stat-value" id="highRiskCount">--</div>
                <div style="color:#999;font-size:12px;">需重点关注干预</div>
            </div>
        </section>

        <!-- 可视化图表 -->
        <section class="charts-grid">
            <div class="chart-card">
                <h3 class="chart-title">
                    院系风险分布
                    <button onclick="refreshChart('department')" style="background:none;border:none;cursor:pointer;font-size:18px;">&#8635;</button>
                </h3>
                <div class="chart-container">
                    <canvas id="departmentChart"></canvas>
                </div>
            </div>

            <div class="chart-card">
                <h3 class="chart-title">
                    月度测评趋势
                    <button onclick="refreshChart('assessment')" style="background:none;border:none;cursor:pointer;font-size:18px;">&#8635;</button>
                </h3>
                <div class="chart-container">
                    <canvas id="assessmentTrendChart"></canvas>
                </div>
            </div>

            <div class="chart-card">
                <h3 class="chart-title">
                    预警级别分布
                    <button onclick="refreshChart('alertLevel')" style="background:none;border:none;cursor:pointer;font-size:18px;">&#8635;</button>
                </h3>
                <div class="chart-container">
                    <canvas id="alertLevelChart"></canvas>
                </div>
            </div>

            <div class="chart-card">
                <h3 class="chart-title">
                    咨询预约热度
                    <button onclick="refreshChart('appointment')" style="background:none;border:none;cursor:pointer;font-size:18px;">&#8635;</button>
                </h3>
                <div class="chart-container">
                    <canvas id="appointmentHeatmap"></canvas>
                </div>
            </div>
        </section>

        <!-- 管理功能入口 -->
        <section>
            <h2 style="margin:30px 0 16px;color:#333;">管理功能</h2>
            <div class="admin-actions">
                <a href="scale-manage.jsp" class="admin-btn">
                    <span class="admin-btn-icon">&#128203;</span>
                    <span class="admin-btn-text">量表管理</span>
                </a>
                <a href="article-manage.jsp" class="admin-btn">
                    <span class="admin-btn-icon">&#128240;</span>
                    <span class="admin-btn-text">文章审核</span>
                </a>
                <a href="alert-manage.jsp" class="admin-btn">
                    <span class="admin-btn-icon">&#128276;</span>
                    <span class="admin-btn-text">预警配置</span>
                </a>
                <a href="user-manage.jsp" class="admin-btn">
                    <span class="admin-btn-icon">&#128101;</span>
                    <span class="admin-btn-text">账号管理</span>
                </a>
                <a href="log-audit.jsp" class="admin-btn">
                    <span class="admin-btn-icon">&#128269;</span>
                    <span class="admin-btn-text">操作审计</span>
                </a>
                <a href="export-data.jsp" class="admin-btn">
                    <span class="admin-btn-icon">&#128202;</span>
                    <span class="admin-btn-text">数据导出</span>
                </a>
            </div>
        </section>
    </main>

    <!-- 图表初始化脚本（直接内嵌，确保中文正确显示） -->
    <script>
    var charts = {};

    // 中文标签定义（解决编码问题）
    var CHART_LABELS = {
        highRisk: '\u9ad8\u98ce\u9669',
        medRisk: '\u4e2d\u98ce\u9669',
        lowRisk: '\u4f4e\u98ce\u9669',
        riskCount: '\u98ce\u9669\u5b66\u751f\u6570',
        person: '\u4eba',
        noData: '\u6682\u65e0\u6570\u636e',
        alertDist: '\u9884\u8b66\u7ea7\u522b\u5206\u5e03'
    };

    // 获取ContextPath
    function getContextPath() {
        return window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1));
    }

    document.addEventListener('DOMContentLoaded', function() {
        initDashboardCharts();
        loadStatisticsData();  // 加载统计卡片和部分图表
        loadAllChartData();   // 并行加载月度测评和预约热度
    });

    async function loadStatisticsData() {
        try {
            var resp = await fetch(getContextPath() + '/statistics/dashboard');
            if (resp.ok) {
                var result = await resp.json();
                updateStatCards(result.data);
            }
        } catch (e) { console.error(e); }
    }

    function updateStatCards(data) {
        if (!data) return;
        if (data.userStats) animateNumber('totalStudents', data.userStats.totalStudents || 0);
        if (data.assessmentStats) animateNumber('todayAssessments', data.assessmentStats.todayAssessments || 0);
        if (data.alertStats) {
            // DAO返回小写key: high/medium/low，兼容大小写
            var m = data.alertStats;
            var h = m.HIGH || m.high || 0;
            var med = m.MEDIUM || m.medium || 0;
            var l = m.LOW || m.low || 0;
            var pending = h + med + l;
            animateNumber('pendingAlerts', pending);
            animateNumber('highRiskCount', h);
        }
        loadAlertLevelChart(data.alertStats || {});
    }

    async function loadAllChartData() {
        try {
            var ctx = getContextPath();
            var [assessResp, aptResp, deptResp] = await Promise.all([
                fetch(ctx + '/statistics/monthly-assessment'),
                fetch(ctx + '/statistics/appointment-heatmap'),
                fetch(ctx + '/statistics/department-risk')
            ]);
            if (assessResp.ok) {
                var assessData = (await assessResp.json()).data || [];
                loadAssessmentTrendChart(assessData);
            }
            if (aptResp.ok) {
                var aptData = (await aptResp.json()).data || [];
                loadAppointmentChart(aptData);
            }
            if (deptResp.ok) {
                var deptData = (await deptResp.json()).data || {};
                loadDepartmentChart(deptData.departments || []);
            }
        } catch(e) { console.error(e); }
    }

    function loadAppointmentChart(data) {
        if (!charts.appointmentHeatmap) return;
        if (data && data.length > 0) {
            charts.appointmentHeatmap.data.labels = data.map(function(x){ return x.date || x.slot || ''; });
            charts.appointmentHeatmap.data.datasets[0].data = data.map(function(x){ return x.count || 0; });
        } else {
            charts.appointmentHeatmap.data.labels = [CHART_LABELS.noData];
            charts.appointmentHeatmap.data.datasets[0].data = [0];
        }
        charts.appointmentHeatmap.update();
    }

    function animateNumber(id, target) {
        var el = document.getElementById(id);
        if (!el) return;
        var start = parseInt(el.textContent) || 0;
        var t0 = performance.now();
        function step(t) {
            var p = Math.min((t - t0) / 800, 1);
            el.textContent = Math.round(start + (target - start) * (1-Math.pow(1-p,3)));
            if (p < 1) requestAnimationFrame(step);
        }
        requestAnimationFrame(step);
    }

    function initDashboardCharts() {
        Chart.defaults.font.family = '"Microsoft YaHei", "PingFang SC", sans-serif';
        Chart.defaults.color = '#595959';

        // 1. 院系风险分布（柱状图）
        charts.department = new Chart(document.getElementById('departmentChart'), {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: CHART_LABELS.riskCount,
                    data: [],
                    backgroundColor: ['rgba(255,77,79,0.75)','rgba(250,140,22,0.75)','rgba(82,196,26,0.75)','rgba(24,144,255,0.75)','rgba(114,46,209,0.75)'],
                    borderRadius: 6,
                    borderSkipped: false
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false }, tooltip: { callbacks: { label: function(c){ return c.dataset.label + ': ' + c.parsed.y + ' 人'; }}}},
                scales: { y: { beginAtZero: true, grid: { color:'#f5f5f5' }, title: { display:true, text:'人数' }}, x: { grid:{display:false} }}
            }
        });

        // 2. 月度测评趋势（折线图）
        charts.assessmentTrend = new Chart(document.getElementById('assessmentTrendChart'), {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: '测评完成次数',
                    data: [],
                    borderColor: '#667eea',
                    backgroundColor: 'rgba(102,126,234,0.12)',
                    fill: true,
                    tension: 0.4,
                    pointRadius: 4,
                    pointHoverRadius: 7,
                    pointBackgroundColor: '#667eea',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false }, tooltip: { callbacks: { label: function(c){ return c.dataset.label + ': ' + c.parsed.y + ' 次'; }}}},
                scales: { y: { beginAtZero: true, grid:{color:'#f5f5f5'}, title:{display:true,text:'次数'}}, x: {grid:{display:false}}},
                interaction: { intersect: false, mode: 'index' }
            }
        });

        // 3. 预警级别分布（环形图）
        charts.alertLevel = new Chart(document.getElementById('alertLevelChart'), {
            type: 'doughnut',
            data: {
                labels: [CHART_LABELS.highRisk, CHART_LABELS.medRisk, CHART_LABELS.lowRisk],
                datasets: [{
                    data: [0, 0, 0],
                    backgroundColor: ['#ff4d4f', '#fa8c16', '#52c41a'],
                    borderWidth: 3,
                    borderColor: '#ffffff',
                    hoverOffset: 10
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '60%',
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            padding: 18,
                            usePointStyle: true,
                            pointStyle: 'circle',
                            font: { size: 13, weight: '500' },
                            generateLabels: function(chart) {
                                var d = chart.data;
                                if (d.labels.length && d.datasets.length) {
                                    return d.labels.map(function(lbl, i) {
                                        var ds = d.datasets[0];
                                        var v = ds.data[i] || 0;
                                        return {
                                            text: lbl + ' (' + v + ')',
                                            fillStyle: ds.backgroundColor[i],
                                            strokeStyle: ds.borderColor ? ds.borderColor[i] : null,
                                            lineWidth: ds.borderWidth,
                                            pointStyle: 'circle',
                                            hidden: isNaN(v) || v === 0,
                                            index: i
                                        };
                                    });
                                }
                                return [];
                            }
                        }
                    },
                    tooltip: {
                        callbacks: {
                            title: function() { return CHART_LABELS.alertDist; },
                            label: function(ctx) {
                                var total = ctx.dataset.data.reduce(function(a,b){return a+b;},0);
                                var pct = total > 0 ? Math.round(ctx.parsed / total * 100) : 0;
                                return ctx.label + ': ' + ctx.parsed + ' ' + CHART_LABELS.person + ' (' + pct + '%)';
                            }
                        }
                    }
                }
            }
        });

        // 4. 咨询预约热度（柱状图）
        charts.appointmentHeatmap = new Chart(document.getElementById('appointmentHeatmap'), {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: '预约数量',
                    data: [],
                    backgroundColor: 'rgba(82,196,26,0.65)',
                    borderRadius: 5,
                    borderSkipped: false
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false }, tooltip: { callbacks: { label: function(c){ return c.dataset.label + ': ' + c.parsed.y + ' 次'; }}}},
                scales: { y: { beginAtZero: true, grid:{color:'#f5f5f5'}, title:{display:true,text:'预约数'}}, x: {grid:{display:false}}}
            }
        });
    }

    function loadDepartmentChart(data) {
        if (!charts.department) return;
        charts.department.data.labels = data.map(function(d){ return d.department || '未分配'; });
        charts.department.data.datasets[0].data = data.map(function(d){ return d.count; });
        charts.department.update();
    }

    function loadAssessmentTrendChart(data) {
        if (!charts.assessmentTrend) return;
        // 从API获取的真实数据格式: [{month:'2025-08', count:15}, ...]
        if (data && data.length > 0) {
            charts.assessmentTrend.data.labels = data.map(function(x){ return x.month; });
            charts.assessmentTrend.data.datasets[0].data = data.map(function(x){ return x.count || 0; });
        } else {
            // 无数据时显示空状态
            charts.assessmentTrend.data.labels = [CHART_LABELS.noData];
            charts.assessmentTrend.data.datasets[0].data = [0];
        }
        charts.assessmentTrend.update();
    }

    function loadAlertLevelChart(stats) {
        if (!charts.alertLevel) return;
        // 兼容DAO返回的小写key
        var h = stats.HIGH || stats.high || 0;
        var med = stats.MEDIUM || stats.medium || 0;
        var l = stats.LOW || stats.low || 0;
        charts.alertLevel.data.datasets[0].data = [h, med, l];
        charts.alertLevel.update();
        document.getElementById('pendingAlerts').textContent = h + med + l;
    }

    function refreshChart(type) {
        switch(type) {
            case 'department': loadDepartmentChartData(); break;
            case 'assessment': loadAssessmentTrendChartData(); break;
            case 'alertLevel': loadAlertLevelChartData(); break;
            default: loadStatisticsData();
        }
        showToast('数据已刷新', 'success');
    }

    async function loadDepartmentChartData() {
        try {
            var r = await fetch(getContextPath() + '/statistics/department-risk');
            if (r.ok) loadDepartmentChart((await r.json()).data || []);
        } catch(e) { console.error(e); }
    }

    async function loadAssessmentTrendChartData() {
        try {
            var r = await fetch(getContextPath() + '/statistics/monthly-assessment');
            if (r.ok) { var d = (await r.json()).data || []; charts.assessmentTrend.data.labels = d.map(function(x){return x.month;}); charts.assessmentTrend.data.datasets[0].data = d.map(function(x){return x.count;}); charts.assessmentTrend.update(); }
        } catch(e) { console.error(e); }
    }

    async function loadAlertLevelChartData() {
        try {
            var r = await fetch(getContextPath() + '/statistics/alert-levels');
            if (r.ok) loadAlertLevelChart((await r.json()).data || {});
        } catch(e) { console.error(e); }
    }

    function showToast(msg, type) {
        var t = document.createElement('div');
        t.className = 'toast toast-' + (type || 'info');
        t.textContent = msg;
        document.body.appendChild(t);
        setTimeout(function(){ t.remove(); }, 3000);
    }
    </script>
</body>
</html>
