// 学生仪表板 - 初始化统计数据+消息中心 (Unicode版本 - 避免编码问题)
document.addEventListener('DOMContentLoaded', function() {
    loadStudentStats();
    loadNotifications();
});

async function loadStudentStats() {
    try {
        // 加载测评统计
        const assessmentResp = await fetch(`${getContextPath()}/assessment/history?scaleId=1`);
        if (assessmentResp.ok) {
            const data = await assessmentResp.json();
            document.getElementById('assessmentCount').textContent = 
                (data.data && data.data.length) ? data.data.length : 0;
        }

        // 加载预约统计
        const appointmentResp = await fetch(`${getContextPath()}/appointment/list?status=ALL`);
        if (appointmentResp.ok) {
            const result = await appointmentResp.json();
            document.getElementById('appointmentCount').textContent = 
                (result.data && result.data.length) ? result.data.length : 0;
        }

        // 加载未读消息
        const notificationResp = await fetch(`${getContextPath()}/notification/unread-count`);
        if (notificationResp.ok) {
            const result = await notificationResp.json();
            document.getElementById('unreadCount').textContent = result.data || 0;
        }
    } catch (e) {
        console.error('\u52a0\u8f7d\u6570\u636e\u5931\u8d25:', e);
    }
}

async function loadNotifications() {
    try {
        const resp = await fetch(`${getContextPath()}/notification/list?page=1&pageSize=10`);
        if (!resp.ok) return;
        const result = await resp.json();
        const list = (result.data || []).filter(n => n.isRead === 0);
        const unreadCount = list.length;
        const unreadEl = document.getElementById('unreadCount');
        if (unreadEl) unreadEl.textContent = unreadCount;

        // 未读消息卡片添加点击事件
        const statCard = unreadEl ? unreadEl.closest('.stat-card') : null;
        if (statCard) {
            statCard.style.cursor = 'pointer';
            statCard.title = '\u70b9\u51fb\u67e5\u770b\u672a\u8bfb\u6d88\u606f';  // 点击查看未读消息
            statCard.onclick = () => showNotificationModal(list);
        }
    } catch (e) {
        console.error('\u52a0\u8f7d\u6d88\u606f\u5931\u8d25:', e);
    }
}

// 使用Unicode常量定义所有中文文本
const NOTIFICATION_TEXTS = {
    TITLE: '\u672a\u8bfb\u6d88\u606f',           // 未读消息
    EMPTY: '\u6682\u65e0\u672a\u8bfb\u6d88\u606f',  // 暂无未读消息
    HANDLE: '\u53bb\u5904\u7406',              // 去处理
    VIEW_DETAIL: '\u67e5\u770b\u8be6\u60c5'     // 查看详情
};

function showNotificationModal(list) {
    let existing = document.getElementById('notificationModal');
    if (existing) existing.remove();

    let html = '<div style="max-height:400px;overflow-y:auto;">';
    if (!list || list.length === 0) {
        html += '<div style="padding:30px;text-align:center;color:#999;">' + NOTIFICATION_TEXTS.EMPTY + '</div>';
    } else {
        for (let i = 0; i < list.length; i++) {
            const n = list[i];
            html += '<div style="padding:14px;border-bottom:1px solid #eee;">' +
                '<div style="font-weight:600;color:#333;font-size:15px;">' + escapeHtml(n.title) + '</div>' +
                '<div style="color:#666;font-size:13px;margin-top:6px;line-height:1.5;">' + escapeHtml(n.content).replace(/\n/g, '<br>') + '</div>' +
                '<div style="margin-top:10px;display:flex;justify-content:space-between;align-items:center;">' +
                '<span style="color:#999;font-size:12px;">' + formatTime(n.createdAt) + '</span>' +
                `<a href="appointment.jsp" style="padding:4px 10px;background:#667eea;color:white;border-radius:4px;font-size:12px;text-decoration:none;">${NOTIFICATION_TEXTS.HANDLE}</a>` +
                '</div>' +
                '</div>';
        }
    }
    html += '</div>';

    const modal = document.createElement('div');
    modal.id = 'notificationModal';
    modal.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.45);z-index:9999;display:flex;align-items:center;justify-content:center;';
    modal.innerHTML = '<div style="background:white;border-radius:12px;width:90%;max-width:520px;max-height:80vh;overflow:hidden;box-shadow:0 10px 40px rgba(0,0,0,0.2);">' +
        '<div style="padding:16px 20px;border-bottom:1px solid #eee;display:flex;justify-content:space-between;align-items:center;">' +
        `<h3 style="margin:0;font-size:16px;color:#333;">${NOTIFICATION_TEXTS.TITLE}</h3>` +
        '<button onclick="document.getElementById(\'notificationModal\').remove()" style="background:none;border:none;font-size:22px;color:#999;cursor:pointer;">&times;</button>' +
        '</div>' +
        '<div style="padding:10px;">' + html + '</div>' +
        '</div>';
    document.body.appendChild(modal);
}

function escapeHtml(text) {
    if (!text) return '';
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function formatTime(d) {
    if (!d) return '--';
    return new Date(d).toLocaleString('zh-CN');
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
