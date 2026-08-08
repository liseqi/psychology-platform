// Counselor Dashboard
document.addEventListener('DOMContentLoaded', function() {
    console.log('Dashboard loaded');
    loadAlertStats();
    loadAlertList();
    loadScheduleList();
});

async function loadAlertStats() {
    try {
        const resp = await fetch(`${getContextPath()}/alert/statistics`);
        console.log('[DIAG] Statistics response status:', resp.status);
        const result = await resp.json();
        console.log('[DIAG] Statistics full response:', JSON.stringify(result, null, 2));
        
        if (resp.ok) {
            const levelDist = result.data?.levelDistribution || {};
            
            document.getElementById('highRiskCount').textContent = levelDist.HIGH || 0;
            document.getElementById('mediumRiskCount').textContent = levelDist.MEDIUM || 0;
            document.getElementById('lowRiskCount').textContent = levelDist.LOW || 0;
        }
    } catch (e) { 
        console.error('[DIAG] Stats error:', e);
    }
}

async function loadAlertList() {
    try {
        const resp = await fetch(`${getContextPath()}/alert/counselor/list?page=1`);
        console.log('[DIAG] Alert list response status:', resp.status);
        const result = await resp.json();
        
        if (resp.ok) {
            renderAlertTable(result.data || []);
        }
    } catch (e) { 
        console.error('[DIAG] Alerts error:', e);
    }
}

function renderAlertTable(alerts) {
    const tbody = document.getElementById('alertTableBody');
    
    if (!alerts.length) {
        // 使用Unicode转义确保中文正确显示
        const emptyMsg = '\u6682\u65e0\u9884\u8b66\u8bb0\u5f55';  // "暂无预警记录"
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:#999;">' + emptyMsg + '</td></tr>';
        return;
    }

    tbody.innerHTML = alerts.map(a => {
        const isPending = a.status === 'PENDING';
        const btnText = isPending ? '\u5904\u7406' : '\u67e5\u770b\u8be6\u60c5';  // 处理 / 查看详情
        const btnClass = isPending ? 'btn-primary' : 'btn-success';
        const btnAction = isPending ? `handleAlert(${a.id})` : `viewStudentRecords(${a.studentId}, '${a.studentName ? a.studentName.replace(/'/g, "\\'") : ''}')`;
        return `
        <tr>
            <td>${a.studentName || '--'}</td>
            <td><span class="risk-${(a.alertLevel||'').toLowerCase()}">${getAlertLevelText(a.alertLevel)}</span></td>
            <td>${(a.triggerReason||'').substring(0,50)}...</td>
            <td><span class="status-tag status-${getStatusClass(a.status)}">${getStatusText(a.status)}</span></td>
            <td>${formatDate(a.createdAt)}</td>
            <td><button class="btn ${btnClass} btn-sm" onclick="${btnAction}">${btnText}</button></td>
        </tr>
    `}).join('');
}

function getAlertLevelText(level) {
    const map = { HIGH: '\u9ad8\u98ce\u9669', MEDIUM: '\u4e2d\u98ce\u9669', LOW: '\u4f4e\u98ce\u9669' };
    return map[level] || level;
}

function getStatusClass(status) {
    const map = { PENDING: 'pending', PROCESSING: 'processing', RESOLVED: 'resolved' };
    return map[status] || '';
}

function getStatusText(status) {
    const map = { PENDING: '\u5f85\u5904\u7406', PROCESSING: '\u5904\u7406\u4e2d', INTERVENING: '\u5e72\u9884\u4e2d', RESOLVED: '\u5df2\u89e3\u51b3', CLOSED: '\u5df2\u5173\u95ed' };
    return map[status] || status;
}

function formatDate(dateStr) {
    if (!dateStr) return '--';
    return new Date(dateStr).toLocaleString('zh-CN');
}

async function handleAlert(alertId) {
    location.href = `${getContextPath()}/counselor/alerts.jsp?id=${alertId}`;
}

function viewStudentRecords(studentId, studentName) {
    location.href = `${getContextPath()}/counselor/records.jsp?studentId=${studentId}&studentName=${encodeURIComponent(studentName || '')}`;
}

async function loadScheduleList() {
    try {
        const today = new Date().toISOString().split('T')[0];
        const resp = await fetch(`${getContextPath()}/appointment/counselor/list?date=${today}`);
        if (resp.ok) {
            const result = await resp.json();
            console.log('Schedule list response:', JSON.stringify(result));  // 调试日志
            renderScheduleTable(result.data || []);
        }
    } catch (e) { console.error(e); }
}

function renderScheduleTable(appointments) {
    const tbody = document.getElementById('scheduleBody');
    
    if (!appointments.length) {
        const emptyMsg = '\u4eca\u65e5\u65e0\u6392\u73ed\u5b89\u6392';  // "今日无排班安排"
        tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:40px;color:#999;">' + emptyMsg + '</td></tr>';
        document.getElementById('todayAppointments').textContent = '0';
        return;
    }

    document.getElementById('todayAppointments').textContent = appointments.filter(
        a => a.status === 'CONFIRMED' || a.status === 'PENDING'
    ).length;

    tbody.innerHTML = appointments.map(a => {
        let actionCell = '--';
        if (a.status === 'PENDING' && a.studentConfirmationStatus === 'RESCHEDULE_REQUESTED') {
            actionCell = `<button class="btn btn-warning btn-sm" onclick="confirmReschedule(${a.id}, '${a.studentRescheduleDate || ''}', '${a.studentRescheduleTimeSlot || ''}')">\u786e\u8ba4\u6539\u671f</button>`;
        } else if (a.status === 'PENDING' && a.studentConfirmationStatus === 'WAITING') {
            actionCell = `<span style="color:#faad14;font-size:12px;">\u5f85\u5b66\u751f\u786e\u8ba4</span>`;
        } else if (a.status === 'PENDING') {
            actionCell = `<button class="btn btn-success btn-sm" onclick="confirmAppointment(${a.id})">${'\u786e\u8ba4'}</button>`;
        }
        return `<tr>
            <td>${a.timeSlot}</td>
            <td>${a.studentName || '--'}</td>
            <td><span class="tag ${getAppointmentStatusTag(a.status)}">${getAppointmentStatusText(a.status)}</span></td>
            <td>${actionCell}</td>
        </tr>`;
    }).join('');
}



function getAppointmentStatusTag(status) {
    const map = { PENDING: 'tag-blue', CONFIRMED: 'tag-green', COMPLETED: 'tag-green', CANCELLED: 'tag-orange' };
    return map[status] || '';
}

function getAppointmentStatusText(status) {
    const map = { PENDING: '\u5f85\u786e\u8ba4', CONFIRMED: '\u5df2\u786e\u8ba4', COMPLETED: '\u5df2\u5b8c\u6210', CANCELLED: '\u5df2\u53d6\u6d88', NO_SHOW: '\u672a\u5230\u573a' };
    return map[status] || status;
}

async function confirmAppointment(appointmentId) {
    if (!confirm('\u786e\u8ba4\u63a5\u53d7\u8be5\u9884\u7ea6\uff1f')) return;

    try {
        const resp = await fetch(`${getContextPath()}/appointment/confirm`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: `appointmentId=${appointmentId}`
        });

        const result = await resp.json();
        if (result.code === 200) {
            showToast('\u9884\u7ea6\u5df2\u786e\u8ba4', 'success');
            loadScheduleList();
        } else {
            showToast(result.message, 'error');
        }
    } catch (e) {
        showToast('\u64cd\u4f5c\u5931\u8d25', 'error');
    }
}

async function confirmReschedule(appointmentId, studentDate, studentSlot) {
    if (!studentDate || !studentSlot) {
        showToast('\u5b66\u751f\u672a\u586b\u5199\u6539\u671f\u65f6\u95f4', 'error');
        return;
    }
    if (!confirm(`\u786e\u8ba4\u540c\u610f\u5b66\u751f\u7684\u6539\u671f\u7533\u8bf7\uff1a${studentDate} ${studentSlot}\uff1f`)) return;

    try {
        const resp = await fetch(`${getContextPath()}/appointment/confirm-reschedule`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: `appointmentId=${appointmentId}&newDate=${studentDate}&newTimeSlot=${encodeURIComponent(studentSlot)}`
        });

        const result = await resp.json();
        if (result.code === 200) {
            showToast('\u6539\u671f\u5df2\u786e\u8ba4', 'success');
            loadScheduleList();
        } else {
            showToast(result.message, 'error');
        }
    } catch (e) {
        showToast('\u64cd\u4f5c\u5931\u8d25', 'error');
    }
}

function getContextPath() {
    return window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1));
}

function showToast(message, type) {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type || 'info'}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
}
