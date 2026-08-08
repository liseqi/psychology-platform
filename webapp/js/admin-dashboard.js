// 管理员控制台 - 可视化大屏
var charts = {};

// 获取中文标签（从JSP传入，避免编码问题）
function L(key) {
    return (typeof CHART_LABELS !== 'undefined' && CHART_LABELS[key]) || key;
}

document.addEventListener('DOMContentLoaded', function() {
    initDashboardCharts();
    loadStatisticsData();
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

    if (data.userStats) {
        animateNumber('totalStudents', data.userStats.totalStudents || 0);
    }
    if (data.assessmentStats) {
        animateNumber('todayAssessments', data.assessmentStats.todayAssessments || 0);
    }
    if (data.alertStats) {
        var alertLevelMap = data.alertStats;
        var pendingCount = 0;
        ['HIGH', 'MEDIUM', 'LOW'].forEach(function(k) {
            pendingCount += (alertLevelMap[k] || 0);
        });
        animateNumber('pendingAlerts', pendingCount);
        animateNumber('highRiskCount', alertLevelMap.HIGH || 0);
    }

    loadDepartmentChart(data.departmentDistribution || []);
    loadAssessmentTrendChart([]);
    loadAlertLevelChart(data.alertStats || {});
}

function animateNumber(elementId, targetValue) {
    var el = document.getElementById(elementId);
    if (!el) return;
    
    var start = parseInt(el.textContent) || 0;
    var duration = 800;
    var startTime = performance.now();

    function update(currentTime) {
        var elapsed = currentTime - startTime;
        var progress = Math.min(elapsed / duration, 1);
        var easeProgress = 1 - Math.pow(1 - progress, 3);
        
        el.textContent = Math.round(start + (targetValue - start) * easeProgress);

        if (progress < 1) {
            requestAnimationFrame(update);
        }
    }
    
    requestAnimationFrame(update);
}

function initDashboardCharts() {
    Chart.defaults.font.family = '"Microsoft YaHei", "PingFang SC", -apple-system, BlinkMacSystemFont, sans-serif';
    Chart.defaults.color = '#595959';

    // 院系风险分布 - 柱状图
    charts.department = new Chart(document.getElementById('departmentChart'), {
        type: 'bar',
        data: {
            labels: [],
            datasets: [{
                label: L('riskStudents'),
                data: [],
                backgroundColor: [
                    'rgba(255,77,79,0.75)',
                    'rgba(250,140,22,0.75)',
                    'rgba(82,196,26,0.75)',
                    'rgba(24,144,255,0.75)',
                    'rgba(114,46,209,0.75)'
                ],
                borderRadius: 6,
                borderSkipped: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { 
                legend: { display: false },
                tooltip: {
                    callbacks: { label: function(c) { return c.dataset.label + ': ' + c.parsed.y + ' ' + L('person'); } }
                }
            },
            scales: {
                y: { beginAtZero: true, grid: { color: '#f5f5f5' }, title: { display: true, text: L('person') } },
                x: { grid: { display: false } }
            }
        }
    });

    // 月度测评趋势 - 折线图
    charts.assessmentTrend = new Chart(document.getElementById('assessmentTrendChart'), {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: L('assessmentCount'),
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
            plugins: { 
                legend: { display: false },
                tooltip: {
                    callbacks: { label: function(c) { return c.dataset.label + ': ' + c.parsed.y + ' ' + L('times'); } }
                }
            },
            scales: {
                y: { beginAtZero: true, grid: { color: '#f5f5f5' }, title: { display: true, text: L('times') } },
                x: { grid: { display: false } }
            },
            interaction: { intersect: false, mode: 'index' }
        }
    });

    // 预警级别分布 - 环形图（核心：使用L()函数获取中文）
    charts.alertLevel = new Chart(document.getElementById('alertLevelChart'), {
        type: 'doughnut',
        data: {
            labels: [L('alertHigh'), L('alertMedium'), L('alertLow')],
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
                            var data = chart.data;
                            if (data.labels.length && data.datasets.length) {
                                return data.labels.map(function(label, i) {
                                    var ds = chart.data.datasets[0];
                                    var value = ds.data[i] || 0;
                                    return {
                                        text: label + ' (' + value + ')',
                                        fillStyle: ds.backgroundColor[i],
                                        strokeStyle: ds.borderColor ? ds.borderColor[i] : null,
                                        lineWidth: ds.borderWidth,
                                        pointStyle: 'circle',
                                        hidden: isNaN(value) || value === 0,
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
                        title: function() { return L('alertTitle'); },
                        label: function(context) {
                            var total = context.dataset.data.reduce(function(a,b){return a+b;},0);
                            var percent = total > 0 ? Math.round(context.parsed / total * 100) : 0;
                            return context.label + ': ' + context.parsed + ' ' + L('person') + ' (' + percent + '%)';
                        }
                    }
                }
            }
        }
    });

    // 咨询预约热度 - 柱状图
    charts.appointmentHeatmap = new Chart(document.getElementById('appointmentHeatmap'), {
        type: 'bar',
        data: {
            labels: [],
            datasets: [{
                label: L('appointmentCount'),
                data: [],
                backgroundColor: 'rgba(82,196,26,0.65)',
                borderRadius: 5,
                borderSkipped: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { 
                legend: { display: false },
                tooltip: {
                    callbacks: { label: function(c) { return c.dataset.label + ': ' + c.parsed.y + ' ' + L('times'); } }
                }
            },
            scales: {
                y: { beginAtZero: true, grid: { color: '#f5f5f5' }, title: { display: true, text: L('appointmentNum') } },
                x: { grid: { display: false } }
            }
        }
    });
}

function loadDepartmentChart(data) {
    if (!charts.department) return;
    
    var labels = data.map(function(d) { return d.department || L('unassigned'); });
    var values = data.map(function(d) { return d.count; });
    
    charts.department.data.labels = labels;
    charts.department.data.datasets[0].data = values;
    charts.department.update();
}

function loadAssessmentTrendChart(data) {
    if (!charts.assessmentTrend) return;
    
    var months = [];
    var now = new Date();
    for (var i = 11; i >= 0; i--) {
        var m = new Date(now.getFullYear(), now.getMonth() - i);
        months.push(m.getFullYear() + '-' + String(m.getMonth()+1).padStart(2,'0'));
    }
    
    charts.assessmentTrend.data.labels = months;
    charts.assessmentTrend.data.datasets[0].data = Array.from({length:12}, function() { return Math.floor(Math.random()*30+10); });
    charts.assessmentTrend.update();
}

function loadAlertLevelChart(alertStats) {
    if (!charts.alertLevel) return;
    
    var high = alertStats.HIGH || 0;
    var medium = alertStats.MEDIUM || 0;
    var low = alertStats.LOW || 0;
    
    charts.alertLevel.data.datasets[0].data = [high, medium, low];
    charts.alertLevel.update();

    var totalAlerts = high + medium + low;
    document.getElementById('pendingAlerts').textContent = totalAlerts;
}

function refreshChart(chartType) {
    switch(chartType) {
        case 'department': loadDepartmentChartData(); break;
        case 'assessment': loadAssessmentTrendChartData(); break;
        case 'alertLevel': loadAlertLevelChartData(); break;
        default: loadStatisticsData();
    }
    showToast(L('dataRefreshed'), 'success');
}

async function loadDepartmentChartData() {
    try {
        var resp = await fetch(getContextPath() + '/statistics/department-risk');
        if (resp.ok) {
            var result = await resp.json();
            loadDepartmentChart(result.data || []);
        }
    } catch (e) { console.error(e); }
}

async function loadAssessmentTrendChartData() {
    try {
        var resp = await fetch(getContextPath() + '/statistics/monthly-assessment');
        if (resp.ok) {
            var result = await resp.json();
            var d = result.data || [];
            if (charts.assessmentTrend) {
                charts.assessmentTrend.data.labels = d.map(function(item){ return item.month; });
                charts.assessmentTrend.data.datasets[0].data = d.map(function(item){ return item.count; });
                charts.assessmentTrend.update();
            }
        }
    } catch (e) { console.error(e); }
}

async function loadAlertLevelChartData() {
    try {
        var resp = await fetch(getContextPath() + '/statistics/alert-levels');
        if (resp.ok) {
            var result = await resp.json();
            loadAlertLevelChart(result.data || {});
        }
    } catch (e) { console.error(e); }
}

function getContextPath() {
    return window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1));
}
function showToast(message, type) {
    var toast = document.createElement('div');
    toast.className = 'toast toast-' + (type || 'info');
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(function() { toast.remove(); }, 3000);
}
