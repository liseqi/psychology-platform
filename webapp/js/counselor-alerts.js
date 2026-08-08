/**
 * Alerts Management - Main Logic
 * Depends on: alerts-text.js (must load first)
 * Version: 20260715f

 */

document.addEventListener('DOMContentLoaded', function() {
    console.log('[ALERTS] Page ready, loading data...');
    loadAlertStats();
    loadAlertList();
});

// ==================== Statistics ====================

async function loadAlertStats() {
    try {
        const listResp = await fetch(getContextPath() + '/alert/counselor/list?page=1&pageSize=1000');
        if (listResp.ok) {
            const result = await listResp.json();
            const alerts = result.data || [];

            let p = 0, pr = 0, r = 0;
            for (let i = 0; i < alerts.length; i++) {
                const s = alerts[i].status;
                if (s === 'PENDING') p++;
                else if (s === 'PROCESSING' || s === 'INTERVENING') pr++;
                else if (s === 'RESOLVED' || s === 'CLOSED') r++;
            }

            document.getElementById('pendingCount').textContent = p;
            document.getElementById('processingCount').textContent = pr;
            document.getElementById('resolvedCount').textContent = r;
        }
    } catch(e) { console.error('[STATS] Error:', e); }
}

// ==================== Alert List ====================

async function loadAlertList() {
    try {
        const level = document.getElementById('levelFilter').value;
        const status = document.getElementById('statusFilter').value;
        const keyword = document.getElementById('searchInput').value.trim();
        
        let url = getContextPath() + '/alert/counselor/list?page=1&pageSize=50';
        if (level) url += '&level=' + level;
        if (status) url += '&status=' + status;
        if (keyword) url += '&keyword=' + encodeURIComponent(keyword);
        
        const resp = await fetch(url);
        if (resp.ok) {
            const result = await resp.json();
            renderAlertList(result.data || []);
        }
    } catch(e) { console.error('[LIST] Error:', e); }
}

// ==================== Render ====================

function renderAlertList(alerts) {
    const c = document.getElementById('alertListContainer');
    
    if (!alerts.length) {
        c.innerHTML =
            '<div class="empty-state">' +
                '<div class="empty-state-icon">' + TEXTS.EMPTY_ICON + '</div>' +
                '<div style="font-size:16px;margin-bottom:8px;">' + TEXTS.EMPTY_TITLE + '</div>' +
                '<div style="font-size:13px;color:#bbb;">' + TEXTS.EMPTY_HINT + '</div>' +
            '</div>';
        return;
    }
    
    let h = '';
    for (let i = 0; i < alerts.length; i++) {
        h += buildCard(alerts[i]);
    }
    c.innerHTML = h;
}

function buildCard(a) {
    // Level
    const lc = a.alertLevel === 'HIGH' ? 'alert-high' : 
               a.alertLevel === 'MEDIUM' ? 'alert-medium' : 'alert-low';
    const lt = a.alertLevel === 'HIGH' ? TEXTS.LEVEL_TEXT_HIGH :
               a.alertLevel === 'MEDIUM' ? TEXTS.LEVEL_TEXT_MEDIUM : TEXTS.LEVEL_TEXT_LOW;
    
    // Type
    const tt = a.alertType === 'ASSESSMENT' ? TEXTS.TYPE_ASSESSMENT :
               a.alertType === 'CHAT' ? TEXTS.TYPE_CHAT :
               a.alertType === 'COUNSELOR' ? TEXTS.TYPE_COUNSELOR :
               a.alertType === 'SYSTEM' ? TEXTS.TYPE_SYSTEM : a.alertType;
    
    // Status
    const stMap = { PENDING: TEXTS.ST_PENDING, PROCESSING: TEXTS.ST_PROCESSING,
                   INTERVENING: TEXTS.ST_INTERVENING, RESOLVED: TEXTS.ST_RESOLVED,
                   CLOSED: TEXTS.ST_CLOSED };
    const stText = stMap[a.status] || a.status;
    const sc = a.status === 'PENDING' ? 'status-pending' :
               (a.status === 'PROCESSING' || a.status === 'INTERVENING') ? 'status-processing' :
               'status-resolved';
    
    const name = a.studentName || TEXTS.UNKNOWN_STUDENT;
    const reason = (a.triggerReason || '').substring(0, 100);
    const date = formatDate(a.createdAt);
    
    // 学生确认状态（基于关联的预约）
    let confirmStatusText = '';
    if (a.appointmentId || a.appointmentStudentConfirmationStatus) {
        const cs = a.appointmentStudentConfirmationStatus || 'WAITING';
        const aptDate = a.appointmentDate || '--';
        const aptSlot = a.appointmentTimeSlot || '--';
        if (cs === 'WAITING') {
            confirmStatusText = '<span style="color:#faad14;font-size:12px;margin-left:8px;">预约待学生确认 (' + aptDate + ' ' + aptSlot + ')</span>';
        } else if (cs === 'CONFIRMED') {
            confirmStatusText = '<span style="color:#52c41a;font-size:12px;margin-left:8px;">学生已确认 (' + aptDate + ' ' + aptSlot + ')</span>';
        } else if (cs === 'RESCHEDULE_REQUESTED') {
            confirmStatusText = '<span style="color:#ff4d4f;font-size:12px;margin-left:8px;">学生申请改期 (' + aptDate + ' ' + aptSlot + ')</span>';
        }
    }
    
    let btn = '';
    if (a.status === 'PENDING') {
        btn = '<button class="btn-action btn-handle" onclick="handleAlert(' + a.id + ')">' + TEXTS.BTN_HANDLE + '</button>';
    } else if (a.status === 'PROCESSING' || a.status === 'INTERVENING') {
        btn = '<span class="btn-action" style="background:#e6f7ff;color:#1890ff;cursor:default;">' + TEXTS.BTN_PROCESSING + '</span>';
    }
    
    return '<div class="alert-item ' + lc + '">' +
        '<div class="alert-info">' +
            '<div class="alert-student">' + lt + ' - ' + name + confirmStatusText + '</div>' +
            '<div class="alert-detail"><b>' + tt + ':</b> ' + reason + '</div>' +
            '<div class="alert-time">' + date + ' &middot; <span class="status-badge ' + sc + '">' + stText + '</span></div>' +
        '</div>' +
        '<div class="alert-actions">' + btn +
            '<button class="btn-action btn-view" onclick="viewStudentRecords(' + a.studentId + ', \'' + (a.studentName || '').replace(/'/g, "\\'") + '\')">' + TEXTS.BTN_VIEW + '</button>' +
        '</div></div>';
}

// ==================== Helpers ====================

function formatDate(d) {
    if (!d) return '--';
    return new Date(d).toLocaleString('zh-CN');
}

// ==================== Actions ====================

let currentHandleId = null;

function handleAlert(id) {
    currentHandleId = id;
    const modal = document.getElementById('handleModal');
    const record = document.getElementById('modalRecord');
    record.value = '';
    document.getElementById('modalStudent').textContent = TEXTS.UNKNOWN_STUDENT;
    document.getElementById('modalLevel').textContent = '--';
    document.getElementById('modalReason').textContent = '--';
    document.getElementById('modalLevel').className = '';
    // 初始化日期和时段
    const dateInput = document.getElementById('modalAppointmentDate');
    const today = new Date().toISOString().split('T')[0];
    dateInput.value = today;
    dateInput.min = today;
    document.getElementById('modalTimeSlot').value = '';

    fetch(getContextPath() + '/alert/detail?id=' + id)
        .then(r => r.json())
        .then(res => {
            if (res.code === 200 && res.data) {
                const a = res.data;
                document.getElementById('modalStudent').textContent = a.studentName || TEXTS.UNKNOWN_STUDENT;
                const levelEl = document.getElementById('modalLevel');
                levelEl.textContent = a.alertLevel === 'HIGH' ? TEXTS.LEVEL_TEXT_HIGH :
                                      a.alertLevel === 'MEDIUM' ? TEXTS.LEVEL_TEXT_MEDIUM : TEXTS.LEVEL_TEXT_LOW;
                levelEl.className = a.alertLevel === 'HIGH' ? 'level-high' :
                                    a.alertLevel === 'MEDIUM' ? 'level-medium' : 'level-low';
                document.getElementById('modalReason').textContent = a.triggerReason || TEXTS.NO_REASON;
            }
        })
        .catch(() => {});

    modal.style.display = 'flex';
    record.focus();
}

function closeModal() {
    document.getElementById('handleModal').style.display = 'none';
    currentHandleId = null;
}

function submitHandle() {
    if (!currentHandleId) return;

    const record = document.getElementById('modalRecord').value.trim();
    if (!record) {
        toast(TEXTS.ERR_EMPTY_RECORD, 'error');
        return;
    }

    const appointmentDate = document.getElementById('modalAppointmentDate').value;
    const timeSlot = document.getElementById('modalTimeSlot').value;
    if (!appointmentDate) {
        toast('\u8bf7\u9009\u62e9\u54a8\u8be2\u65e5\u671f', 'error');
        return;
    }
    if (!timeSlot) {
        toast('\u8bf7\u9009\u62e9\u54a8\u8be2\u65f6\u6bb5', 'error');
        return;
    }

    const btn = document.getElementById('modalSubmitBtn');
    btn.disabled = true;
    btn.textContent = TEXTS.BTN_SUBMITTING;

    fetch(getContextPath() + '/alert/handle', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'id=' + currentHandleId + '&status=PROCESSING&record=' + encodeURIComponent(record) +
              '&appointmentDate=' + encodeURIComponent(appointmentDate) +
              '&timeSlot=' + encodeURIComponent(timeSlot)
    })
    .then(r => r.json())
    .then(res => {
        btn.disabled = false;
        btn.textContent = TEXTS.BTN_SUBMIT;
        if (res.code === 200) {
            closeModal();
            toast(TEXTS.TOAST_HANDLED, 'success');
            setTimeout(() => location.reload(), 800);
        } else {
            toast(res.message || TEXTS.TOAST_FAILED, 'error');
        }
    })
    .catch(() => {
        btn.disabled = false;
        btn.textContent = TEXTS.BTN_SUBMIT;
        toast(TEXTS.TOAST_NETWORK, 'error');
    });
}

document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('modalSubmitBtn').addEventListener('click', submitHandle);
    document.getElementById('handleModal').addEventListener('click', function(e) {
        if (e.target === this) closeModal();
    });
    document.getElementById('modalRecord').addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.key === 'Enter') submitHandle();
    });
});

function viewStudentRecords(studentId, studentName) {
    location.href = getContextPath() + '/counselor/records.jsp?studentId=' + studentId + '&studentName=' + encodeURIComponent(studentName || '');
}

function getContextPath() {
    return window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1));
}

// Toast
function toast(msg, type) {
    const el = document.createElement('div');
    const colors = {success:'#52c41a',error:'#ff4d4f',info:'#1890ff'};
    el.style.cssText = 'position:fixed;top:20px;right:20px;padding:12px 24px;background:' +
        (colors[type]||colors.info) + ';color:#fff;border-radius:8px;z-index:9999;';
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 3000);
}
