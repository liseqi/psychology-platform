/**
 * Text Resource File for Alerts Page
 * All Chinese text defined here using standard JS unicode escapes
 * This file is loaded FIRST before any other logic
 * 
 * Version: 20260715f

 */

var TEXTS = {
    // Page Header
    PAGE_TITLE: '\u9884\u8b66\u7ba1\u7406',           // 预警管理
    PAGE_DESC: '\u5173\u6ce8\u5b66\u751f\u5fc3\u7406\u5065\u5eb7\u9884\u8b66 \u00b7 \u53ca\u65f6\u8ddf\u8fdb\u5e72\u9884',
    
    // Stat Cards
    LABEL_PENDING: '\u5f85\u5904\u7406\u9884\u8b66',   // 待处理预警
    LABEL_PROCESSING: '\u5904\u7406\u4e2d',           // 处理中
    LABEL_RESOLVED: '\u5df2\u89e3\u51b3',            // 已解决
    
    // Filter
    FILTER_BTN: '\u7b5b\u9009',                      // 筛选
    SEARCH_PLACEHOLDER: '\u641c\u7d22\u5b66\u751f\u59d3\u540d...', // 搜索学生姓名...
    
    // Level Options (value -> text)
    LEVEL_ALL: '\u5168\u90e8\u7ea7\u522b',          // 全部级别
    LEVEL_HIGH: '\u9ad8\u98ce\u9669',               // 高风险
    LEVEL_MEDIUM: '\u4e2d\u5ea6\u9884\u8b66',       // 中度预警
    LEVEL_LOW: '\u4f4e\u98ce\u9669',                // 低风险
    
    // Status Options
    STATUS_ALL: '\u5168\u90e8\u72b6\u6001',         // 全部状态
    STATUS_PENDING: '\u5f85\u5904\u7406',           // 待处理
    STATUS_PROCESSING: '\u5904\u7406\u4e2d',        // 处理中
    STATUS_INTERVENING: '\u5e72\u9884\u4e2d',       // 干预中
    STATUS_RESOLVED: '\u5df2\u89e3\u51b3',          // 已解决
    
    // Empty State
    EMPTY_ICON: '\uD83D\uDCCB',                       // 📋
    EMPTY_TITLE: '\u6682\u65e0\u9884\u8b66\u8bb0\u5f55',  // 暂无预警记录
    EMPTY_HINT: '\u5f53\u524d\u6ca1\u6709\u5206\u914d\u7ed9\u60a8\u7684\u9884\u8b66\u4fe1\u606f',
                                                    // 当前没有分配给您的预警信息
    LOADING: '\u52a0\u8f7d\u4e2d...',               // 加载中...
    
    // Alert Card
    UNKNOWN_STUDENT: '\u672a\u77e5\u5b66\u751f',    // 未知学生
    LEVEL_TEXT_HIGH: '\u26A0\uFE0F \u9ad8\u5371\u9884\u8b66',  // ⚠️ 高危预警
    LEVEL_TEXT_MEDIUM: '\U0001F534 \u4e2d\u5ea6\u9884\u8b66',   // 🔴 中度预警  
    LEVEL_TEXT_LOW: '\U0001F7E2 \u4f4e\u98ce\u9669',            // 🟢 低风险
    TYPE_ASSESSMENT: '\u6d4b\u8bc4\u5f02\u5e38',     // 测评异常
    TYPE_CHAT: '\u6811\u6d1e\u5173\u952e\u8bcd',      // 树洞关键词
    TYPE_COUNSELOR: '\u54a8\u8be2\u5e08\u4e0a\u62a5',   // 咨询师上报
    TYPE_SYSTEM: '\u7cfb\u7edf\u81ea\u52a8',          // 系统自动
    ST_PENDING: '\u5f85\u5904\u7406',                // 待处理
    ST_PROCESSING: '\u5904\u7406\u4e2d',             // 处理中
    ST_INTERVENING: '\u5e72\u9884\u4e2d',            // 干预中
    ST_RESOLVED: '\u5df2\u89e3\u51b3',              // 已解决
    ST_CLOSED: '\u5df2\u5173\u95ed',                 // 已关闭
    
    // Buttons
    BTN_HANDLE: '\u7acb\u5373\u5904\u7406',         // 立即处理
    BTN_PROCESSING: '\u6b63\u5728\u5904\u7406',     // 正在处理
    BTN_VIEW: '\u67e5\u770b\u8be6\u60c5',           // 查看详情
    BTN_SUBMIT: '\u63d0\u4ea4\u5904\u7406',         // 提交处理
    BTN_SUBMITTING: '\u63d0\u4ea4\u4e2d...',       // 提交中...
    
    // Modal
    NO_REASON: '\u6682\u65e0\u8be6\u7ec6\u8bf4\u660e', // 暂无详细说明
    ERR_EMPTY_RECORD: '\u8bf7\u586b\u5199\u5e72\u9884\u8bb0\u5f55', // 请填写干预记录
    
    // Toast Messages
    TOAST_ACCEPTED: '\u5df2\u63a5\u624b',           // 已接手
    TOAST_HANDLED: '\u5904\u7406\u5df2\u63d0\u4ea4', // 处理已提交
    TOAST_FAILED: '\u64cd\u4f5c\u5931\u8d25',        // 操作失败
    TOAST_NETWORK: '\u7f51\u7edc\u9519\u8bef',       // 网络错误
    CONFIRM_HANDLE: '\u786e\u8ba4\u63a5\u624b\u5904\u7406\u6b64\u9884\u8b66\uff1f'  // 确认接手处理此预警？
};

// Initialize all page text immediately when this script loads
(function() {
    try {
        document.title = TEXTS.PAGE_TITLE;
        document.getElementById('headerTitle').innerHTML = '&#9888;&#65039; ' + TEXTS.PAGE_TITLE;
        document.getElementById('headerDesc').textContent = TEXTS.PAGE_DESC;
        
        document.getElementById('labelPending').textContent = TEXTS.LABEL_PENDING;
        document.getElementById('labelProcessing').textContent = TEXTS.LABEL_PROCESSING;
        document.getElementById('labelResolved').textContent = TEXTS.LABEL_RESOLVED;
        
        document.getElementById('filterBtn').textContent = TEXTS.FILTER_BTN;
        document.getElementById('searchInput').placeholder = TEXTS.SEARCH_PLACEHOLDER;
        
        var levelSel = document.getElementById('levelFilter');
        levelSel.innerHTML = 
            '<option value="">' + TEXTS.LEVEL_ALL + '</option>' +
            '<option value="HIGH">' + TEXTS.LEVEL_HIGH + '</option>' +
            '<option value="MEDIUM">' + TEXTS.LEVEL_MEDIUM + '</option>' +
            '<option value="LOW">' + TEXTS.LEVEL_LOW + '</option>';
        
        var statusSel = document.getElementById('statusFilter');
        statusSel.innerHTML =
            '<option value="">' + TEXTS.STATUS_ALL + '</option>' +
            '<option value="PENDING">' + TEXTS.STATUS_PENDING + '</option>' +
            '<option value="PROCESSING">' + TEXTS.STATUS_PROCESSING + '</option>' +
            '<option value="INTERVENING">' + TEXTS.STATUS_INTERVENING + '</option>' +
            '<option value="RESOLVED">' + TEXTS.STATUS_RESOLVED + '</option>';
        
        document.getElementById('emptyIcon').textContent = TEXTS.EMPTY_ICON;
        document.getElementById('emptyText').textContent = TEXTS.LOADING;
        
        console.log('[TEXT] Page text initialized successfully');
    } catch(e) {
        console.error('[TEXT] Failed to initialize:', e);
    }
})();
