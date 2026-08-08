<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"COUNSELOR".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>咨询记录 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        /* ===== 页面布局 ===== */
        .records-page { margin-top: 24px; }
        
        /* ===== 统计概览卡片 ===== */
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 28px; }
        .stat-card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); display: flex; align-items: center; gap: 16px; transition: transform 0.2s, box-shadow 0.2s; }
        .stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 24px rgba(0,0,0,0.12); }
        .stat-icon { width: 56px; height: 56px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 26px; flex-shrink: 0; }
        .stat-icon.total { background: linear-gradient(135deg,#667eea,#764ba2); }
        .stat-icon.ongoing { background: linear-gradient(135deg,#faad14,#ffc53d); }
        .stat-icon.completed { background: linear-gradient(135deg,#52c41a,#73d13d); }
        .stat-icon.cancelled { background: linear-gradient(135deg,#8c8c8c,#bfbfbf); }
        .stat-info h3 { font-size: 13px; color: #888; font-weight: 500; margin: 0 0 4px 0; }
        .stat-info .stat-number { font-size: 32px; font-weight: 700; color: #333; line-height: 1; }
        
        /* ===== Tab 导航 ===== */
        .tabs-container { background: white; border-radius: 12px; padding: 4px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); margin-bottom: 24px; }
        .tabs { display: flex; gap: 4px; }
        .tab { flex: 1; padding: 12px 16px; text-align: center; cursor: pointer; color: #666; font-size: 14px; font-weight: 500; border-radius: 8px; transition: all 0.25s ease; position: relative; }
        .tab:hover { background: #f5f5f5; color: #667eea; }
        .tab.active { background: linear-gradient(135deg,#667eea,#764ba2); color: white; box-shadow: 0 4px 12px rgba(102,126,234,0.35); }
        .tab .tab-count { font-size: 12px; opacity: 0.85; margin-left: 4px; }
        
        /* ===== 记录列表 ===== */
        .records-list { display: flex; flex-direction: column; gap: 18px; }
        .record-card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); transition: transform 0.2s, box-shadow 0.2s; border-left: 4px solid transparent; }
        .record-card:hover { transform: translateY(-2px); box-shadow: 0 6px 24px rgba(0,0,0,0.12); }
        .record-card.status-ongoing { border-left-color: #faad14; }
        .record-card.status-completed { border-left-color: #52c41a; }
        .record-card.status-cancelled { border-left-color: #d9d9d9; }
        
        /* 卡片头部 */
        .record-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; flex-wrap: wrap; gap: 16px; }
        .student-info { display: flex; align-items: center; gap: 14px; }
        .student-avatar { width: 52px; height: 52px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-size: 22px; font-weight: bold; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
        .student-name { font-size: 18px; font-weight: 600; color: #333; }
        .student-id { color: #999; font-size: 13px; margin-top: 3px; }
        .record-status-badge { padding: 6px 16px; border-radius: 20px; font-size: 13px; font-weight: 600; }
        .badge-ongoing { background: #fff7e6; color: #d48806; }
        .badge-completed { background: #f6ffed; color: #389e0d; }
        .badge-cancelled { background: #f5f5f5; color: #8c8c8c; }
        
        /* 元数据行 */
        .meta-row { display: flex; gap: 28px; flex-wrap: wrap; margin-bottom: 18px; padding: 14px 16px; background: #fafafa; border-radius: 10px; }
        .meta-item { display: flex; align-items: center; gap: 8px; font-size: 13px; }
        .meta-item .meta-label { color: #999; }
        .meta-item .meta-value { color: #555; font-weight: 500; }
        
        /* 内容区 */
        .record-body { }
        .section-title { font-size: 14px; font-weight: 600; color: #333; margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
        .section-content { color: #555; line-height: 1.75; font-size: 14px; background: linear-gradient(135deg,#f8f9ff,#fafbff); padding: 16px 18px; border-radius: 10px; border: 1px solid #f0f0f5; white-space: pre-wrap; word-break: break-word; }
        
        /* 标签 */
        .tag-list { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 14px; }
        .tag { padding: 5px 14px; background: #e6f7ff; color: #1890ff; border-radius: 15px; font-size: 12px; font-weight: 500; cursor: default; transition: transform 0.15s; }
        .tag:hover { transform: scale(1.05); }
        .tag.warning { background: #fff7e6; color: #d48806; }
        .tag.danger { background: #fff1f0; color: #cf1322; }
        .tag.success { background: #f6ffed; color: #52c41a; }
        
        /* 操作按钮 */
        .action-btns { display: flex; gap: 10px; margin-top: 18px; padding-top: 16px; border-top: 1px solid #f0f0f0; flex-wrap: wrap; }
        .btn-sm { padding: 9px 20px; border-radius: 8px; font-size: 13px; font-weight: 500; cursor: pointer; border: none; transition: all 0.2s; display: inline-flex; align-items: center; gap: 6px; }
        .btn-sm:hover { opacity: 0.88; transform: translateY(-1px); box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
        .btn-primary { background: linear-gradient(135deg,#667eea,#764ba2); color: white; }
        .btn-success { background: linear-gradient(135deg,#52c41a,#73d13d); color: white; }
        .btn-outline { background: white; border: 1px solid #d9d9d9; color: #555; }
        .btn-outline:hover { border-color: #667eea; color: #667eea; background: #f8f9ff; }
        
        /* ===== 空状态 ===== */
        .empty-state { text-align: center; padding: 80px 20px; background: white; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
        .empty-icon { font-size: 64px; margin-bottom: 20px; opacity: 0.8; }
        .empty-text { font-size: 16px; color: #999; margin-bottom: 8px; }
        .empty-hint { font-size: 13px; color: #bbb; }
        
        /* ===== 加载状态 ===== */
        .loading-state { text-align: center; padding: 60px; background: white; border-radius: 12px; }
        @keyframes spin { to { transform: rotate(360deg); } }
        .spinner { display: inline-block; width: 32px; height: 32px; border: 4px solid #f0f0f0; border-top: 4px solid #667eea; border-radius: 50%; animation: spin 0.8s linear infinite; }
        .loading-text { margin-top: 16px; color: #999; font-size: 14px; }
        
        /* ===== 响应式 ===== */
        .modal-backdrop { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.45); z-index: 1000; align-items: center; justify-content: center; padding: 20px; backdrop-filter: blur(2px); }
        .modal-backdrop.active { display: flex; }
        .modal { background: white; border-radius: 14px; width: 100%; max-width: 720px; max-height: 90vh; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.2); animation: modalIn 0.25s ease; display: flex; flex-direction: column; }
        @keyframes modalIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
        .modal-header { padding: 20px 24px; border-bottom: 1px solid #f0f0f0; display: flex; justify-content: space-between; align-items: center; background: linear-gradient(135deg,#667eea,#764ba2); color: white; }
        .modal-title { font-size: 17px; font-weight: 600; }
        .modal-close { background: none; border: none; color: white; font-size: 22px; cursor: pointer; padding: 0; width: 32px; height: 32px; border-radius: 50%; transition: background 0.2s; line-height: 32px; }
        .modal-close:hover { background: rgba(255,255,255,0.2); }
        .modal-body { padding: 24px; overflow-y: auto; flex: 1; }
        .form-group { margin-bottom: 18px; }
        .form-label { display: block; font-size: 13px; font-weight: 500; color: #555; margin-bottom: 8px; }
        .form-label .required { color: #cf1322; margin-left: 2px; }
        .form-input, .form-textarea, .form-select { width: 100%; padding: 11px 14px; border: 1px solid #d9d9d9; border-radius: 8px; font-size: 14px; font-family: inherit; box-sizing: border-box; transition: border-color 0.2s, box-shadow 0.2s; }
        .form-input:focus, .form-textarea:focus, .form-select:focus { outline: none; border-color: #667eea; box-shadow: 0 0 0 3px rgba(102,126,234,0.12); }
        .form-textarea { resize: vertical; min-height: 120px; line-height: 1.7; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .modal-footer { padding: 16px 24px; border-top: 1px solid #f0f0f0; display: flex; justify-content: flex-end; gap: 12px; }
        .btn { padding: 10px 22px; border-radius: 8px; font-size: 14px; font-weight: 500; cursor: pointer; border: none; transition: all 0.2s; }
        .btn:hover { opacity: 0.88; transform: translateY(-1px); }
        .btn-primary { background: linear-gradient(135deg,#667eea,#764ba2); color: white; }
        .btn-default { background: #f5f5f5; color: #555; }

        /* 历史弹窗 */
        .history-list { display: flex; flex-direction: column; gap: 14px; }
        .history-item { padding: 16px; border-radius: 10px; background: #fafafa; border-left: 4px solid #667eea; }
        .history-item.status-ongoing { border-left-color: #faad14; }
        .history-item.status-completed { border-left-color: #52c41a; }
        .history-item.status-cancelled { border-left-color: #d9d9d9; }
        .history-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; flex-wrap: wrap; gap: 8px; }
        .history-title { font-size: 15px; font-weight: 600; color: #333; }
        .history-meta { font-size: 12px; color: #888; }
        .history-section { margin-top: 10px; }
        .history-section-title { font-size: 12px; font-weight: 600; color: #667eea; margin-bottom: 4px; }
        .history-section-content { font-size: 13px; color: #555; line-height: 1.6; white-space: pre-wrap; background: white; padding: 10px; border-radius: 6px; }

        @media (max-width: 768px) {
            .stats-grid { grid-template-columns: repeat(2, 1fr); }
            .record-header { flex-direction: column; align-items: flex-start; }
            .meta-row { flex-direction: column; gap: 10px; }
            .form-row { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>📋 咨询记录</h1>
            <p>管理与追踪心理咨询全过程，记录来访者成长轨迹</p>
        </header>

        <!-- 统计概览 -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon total">📊</div>
                <div class="stat-info">
                    <h3>全部记录</h3>
                    <div class="stat-number" id="countTotal">-</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon ongoing">🔄</div>
                <div class="stat-info">
                    <h3>进行中</h3>
                    <div class="stat-number" id="countOngoing">-</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon completed">✅</div>
                <div class="stat-info">
                    <h3>已结案</h3>
                    <div class="stat-number" id="countCompleted">-</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon cancelled">❌</div>
                <div class="stat-info">
                    <h3>已取消</h3>
                    <div class="stat-number" id="countCancelled">-</div>
                </div>
            </div>
        </div>

        <!-- 当前筛选提示 -->
        <div id="studentFilterHint" style="display:none; margin-bottom:16px; background:#e6f7ff; border:1px solid #91d5ff; color:#1890ff; padding:12px 16px; border-radius:8px; justify-content:space-between; align-items:center;">
            <span>当前仅展示 <b id="studentFilterName"></b> 的咨询记录</span>
            <a href="records.jsp" style="color:#1890ff; text-decoration:none;">清除筛选</a>
        </div>

        <!-- Tab 导航 -->
        <div class="tabs-container">
            <div class="tabs">
                <div class="tab active" data-status="ALL">全部记录<span class="tab-count" id="tabTotal">(-)</span></div>
                <div class="tab" data-status="ONGOING">进行中<span class="tab-count" id="tabOngoing">(-)</span></div>
                <div class="tab" data-status="COMPLETED">已结案<span class="tab-count" id="tabCompleted">(-)</span></div>
                <div class="tab" data-status="CANCELLED">已取消<span class="tab-count" id="tabCancelled">(-)</span></div>
            </div>
        </div>

        <!-- 记录列表 -->
        <div class="records-list" id="recordsList">
            <div class="loading-state">
                <div class="spinner"></div>
                <p class="loading-text">正在加载咨询记录...</p>
            </div>
        </div>
    </main>

    <!-- 编辑记录模态框 -->
    <div class="modal-backdrop" id="editModal">
        <div class="modal">
            <div class="modal-header">
                <div class="modal-title">✏️ 编辑咨询记录</div>
                <button class="modal-close" onclick="closeModal('editModal')">&times;</button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="editRecordId">
                <div class="form-group">
                    <label class="form-label">📋 咨询摘要</label>
                    <textarea class="form-textarea" id="editSummary" placeholder="记录本次咨询的重点内容、学生反馈、干预措施等..."></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">🩺 初步评估</label>
                    <textarea class="form-textarea" id="editAssessment" placeholder="对学生的初步评估、风险等级、心理状态描述..."></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">📌 后续跟进计划</label>
                    <textarea class="form-textarea" id="editFollowUp" placeholder="下次咨询安排、家庭作业、转介建议等..."></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-default" onclick="closeModal('editModal')">取消</button>
                <button class="btn btn-primary" onclick="submitEdit()">保存修改</button>
            </div>
        </div>
    </div>

    <!-- 新增会话模态框 -->
    <div class="modal-backdrop" id="sessionModal">
        <div class="modal">
            <div class="modal-header">
                <div class="modal-title">➕ 新增咨询会话</div>
                <button class="modal-close" onclick="closeModal('sessionModal')">&times;</button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="sessionRecordId">
                <input type="hidden" id="sessionStudentId">
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">📅 咨询日期<span class="required">*</span></label>
                        <input type="date" class="form-input" id="sessionDate">
                    </div>
                    <div class="form-group">
                        <label class="form-label">⏰ 咨询时段<span class="required">*</span></label>
                        <select class="form-select" id="sessionTimeSlot">
                            <option value="">请选择时段</option>
                            <option value="09:00-10:00">09:00-10:00</option>
                            <option value="10:00-11:00">10:00-11:00</option>
                            <option value="11:00-12:00">11:00-12:00</option>
                            <option value="14:00-15:00">14:00-15:00</option>
                            <option value="15:00-16:00">15:00-16:00</option>
                            <option value="16:00-17:00">16:00-17:00</option>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">💬 咨询主题</label>
                    <input type="text" class="form-input" id="sessionTopic" placeholder="本次咨询主题，如：焦虑干预跟进">
                </div>
                <div class="form-group">
                    <label class="form-label">📝 本次摘要</label>
                    <textarea class="form-textarea" id="sessionSummary" placeholder="记录本次会话的要点..."></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-default" onclick="closeModal('sessionModal')">取消</button>
                <button class="btn btn-primary" onclick="submitSession()">确认新增</button>
            </div>
        </div>
    </div>

    <!-- 查看历史模态框 -->
    <div class="modal-backdrop" id="historyModal">
        <div class="modal" style="max-width: 800px;">
            <div class="modal-header">
                <div class="modal-title" id="historyModalTitle">📖 咨询历史</div>
                <button class="modal-close" onclick="closeModal('historyModal')">&times;</button>
            </div>
            <div class="modal-body" id="historyModalBody">
                <div class="loading-state"><div class="spinner"></div><p class="loading-text">加载历史中...</p></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-default" onclick="closeModal('historyModal')">关闭</button>
            </div>
        </div>
    </div>

    <script>
        var currentStatus = 'ALL';
        var recordsData = [];
        var currentStudentId = '';
        var currentStudentName = '';
        var CONTEXT_PATH = '${pageContext.request.contextPath}' || 
                           window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1));
        
        // 页面加载时获取数据
        document.addEventListener('DOMContentLoaded', function() {
            var params = new URLSearchParams(window.location.search);
            currentStudentId = params.get('studentId') || '';
            currentStudentName = params.get('studentName') || '';
            if (currentStudentId) {
                var hintEl = document.getElementById('studentFilterHint');
                var nameEl = document.getElementById('studentFilterName');
                if (hintEl) hintEl.style.display = 'flex';
                if (nameEl) nameEl.textContent = decodeURIComponent(currentStudentName) || '该学生';
            }
            loadRecords('ALL', currentStudentId);
            
            // Tab切换事件
            document.querySelectorAll('.tab').forEach(function(tab) {
                tab.addEventListener('click', function() {
                    var status = this.getAttribute('data-status');
                    switchTab(this);
                    loadRecords(status, currentStudentId);
                });
            });
        });

        function switchTab(activeTab) {
            document.querySelectorAll('.tab').forEach(function(t) { t.classList.remove('active'); });
            activeTab.classList.add('active');
            currentStatus = activeTab.getAttribute('data-status');
        }

        function loadRecords(status, studentId) {
            var container = document.getElementById('recordsList');
            container.innerHTML = '<div class="loading-state"><div class="spinner"></div><p class="loading-text">加载中...</p></div>';
            
            var url = CONTEXT_PATH + '/record/list?status=' + status;
            if (studentId) {
                url += '&studentId=' + encodeURIComponent(studentId);
            }
            
            fetch(url)
                .then(function(resp) { return resp.json(); })
                .then(function(result) {
                    if (result.code === 200) {
                        renderRecords(result.data || {});
                    } else {
                        container.innerHTML = '<div class="empty-state"><div class="empty-icon">⚠️</div><div class="empty-text">加载失败</div><div class="empty-hint">' + (result.message || '未知错误') + '</div></div>';
                    }
                })
                .catch(function(err) {
                    console.error(err);
                    container.innerHTML = '<div class="empty-state"><div class="empty-icon">🔌</div><div class="empty-text">网络连接失败</div><div class="empty-hint">请检查网络后刷新重试</div></div>';
                });
        }

        function renderRecords(data) {
            // 更新所有统计数据
            updateStatCount('countTotal', data.total || 0);
            updateStatCount('countOngoing', data.ongoing || 0);
            updateStatCount('countCompleted', data.completed || 0);
            updateStatCount('countCancelled', data.cancelled || 0);
            
            // 更新Tab中的计数
            updateTabCount('tabTotal', data.total || 0);
            updateTabCount('tabOngoing', data.ongoing || 0);
            updateTabCount('tabCompleted', data.completed || 0);
            updateTabCount('tabCancelled', data.cancelled || 0);

            var records = data.records || [];
            var container = document.getElementById('recordsList');

            if (records.length === 0) {
                var emptyMsg = getEmptyMessage(currentStatus);
                container.innerHTML = '<div class="empty-state"><div class="empty-icon">' + emptyMsg.icon + '</div><div class="empty-text">' + emptyMsg.text + '</div><div class="empty-hint">' + emptyMsg.hint + '</div></div>';
                return;
            }

            var html = '';
            records.forEach(function(record) {
                html += buildRecordCard(record);
            });

            container.innerHTML = html;
        }

        function getEmptyMessage(status) {
            switch(status) {
                case 'ONGOING': return { icon: '📋', text: '暂无进行中的咨询记录', hint: '当前没有正在进行的咨询案例' };
                case 'COMPLETED': return { icon: '✅', text: '暂无已结案的咨询记录', hint: '完成的案例会显示在这里' };
                case 'CANCELLED': return { icon: '❌', text: '暂无已取消的咨询记录', hint: '取消的预约会显示在这里' };
                default: return { icon: '📝', text: '暂无咨询记录', hint: '学生预约并完成签到后，记录将自动显示在这里' };
            }
        }

        function buildRecordCard(r) {
            // 状态配置
            var statusConfig = {
                'ONGOING': { text: '进行中', badgeClass: 'badge-ongoing', cardClass: 'status-ongoing' },
                'COMPLETED': { text: '已结案', badgeClass: 'badge-completed', cardClass: 'status-completed' },
                'CANCELLED': { text: '已取消', badgeClass: 'badge-cancelled', cardClass: 'status-cancelled' }
            };
            var statusCfg = statusConfig[r.status] || { text: '待接待', badgeClass: '', cardClass: '' };

            // 学生信息
            var studentName = r.studentName || '未知学生';
            var initial = studentName.charAt(studentName.length - 1) || '学';
            var studentInfo = [];
            if (r.studentNo) studentInfo.push('<span class="meta-label">学号:</span><span class="meta-value">' + escapeHtml(r.studentNo) + '</span>');
            if (r.department) studentInfo.push('<span class="meta-label">学院:</span><span class="meta-value">' + escapeHtml(r.department) + '</span>');
            if (r.grade) studentInfo.push('<span class="meta-label">年级:</span><span class="meta-value">' + escapeHtml(r.grade) + '</span>');

            // 咨询次数
            var sessionText = r.sessionCount > 0 ? ('第 ' + r.sessionCount + ' 次') : '首次咨询';

            // 时间格式化
            var lastDate = formatDate(r.lastDate || r.createdAt);
            var createDate = formatDate(r.createdAt);

            // 头像颜色方案
            var colors = [
                'linear-gradient(135deg,#667eea,#764ba2)',
                'linear-gradient(135deg,#f093fb,#f5576c)',
                'linear-gradient(135deg,#4facfe,#00f2fe)',
                'linear-gradient(135deg,#43e97b,#38f9d7)',
                'linear-gradient(135deg,#fa709a,#fee140)',
                'linear-gradient(135deg,#a18cd1,#fbc2eb)'
            ];
            var colorIndex = Math.abs(hashCode(studentName)) % colors.length;

            // 构建卡片HTML
            var html = '<div class="record-card ' + statusCfg.cardClass + '">';
            
            // 头部：学生信息 + 状态标签
            html += '<div class="record-header">';
            html += '<div class="student-info">';
            html += '<div class="student-avatar" style="background:' + colors[colorIndex] + '">' + initial + '</div>';
            html += '<div>';
            html += '<div class="student-name">' + escapeHtml(studentName) + '</div>';
            html += '<div class="student-id">';
            if (r.studentNo) html += escapeHtml(r.studentNo) + ' · ';
            if (r.department) html += escapeHtml(r.department);
            if (r.grade) html += ' · ' + escapeHtml(r.grade);
            html += '</div>';
            html += '</div></div>'; // student-info
            
            html += '<span class="record-status-badge ' + statusCfg.badgeClass + '">' + statusCfg.text + '</span>';
            html += '</div>'; // record-header

            // 元数据行
            html += '<div class="meta-row">';
            html += '<div class="meta-item"><span class="meta-label">💬 咨询次数:</span><span class="meta-value">' + sessionText + '</span></div>';
            html += '<div class="meta-item"><span class="meta-label">📅 上次咨询:</span><span class="meta-value">' + lastDate + '</span></div>';
            html += '<div class="meta-item"><span class="meta-label">📝 创建时间:</span><span class="meta-value">' + createDate + '</span></div>';
            html += '</div>'; // meta-row

            // 主体内容
            html += '<div class="record-body">';

            // 咨询主题/主诉问题
            var topic = r.topic || r.assessment || '';
            if (topic && topic.trim().length > 0) {
                html += '<div class="section-title">📌 咨询主题</div>';
                html += '<div class="section-content">' + escapeHtml(topic) + '</div>';
                
                // 从内容中提取标签
                var tags = extractTags(topic);
                if (tags.length > 0) {
                    html += '<div class="section-title" style="margin-top:14px;">🏷️ 关键词标签</div>';
                    html += '<div class="tag-list">';
                    tags.forEach(function(t) {
                        var tagClass = isWarningTag(t) ? (isDangerTag(t) ? 'tag danger' : 'tag warning') : 'tag';
                        html += '<span class="' + tagClass + '">' + t + '</span>';
                    });
                    html += '</div>';
                }
            }

            // 摘要（如果有）
            var summary = r.summaryText || '';
            if (summary && summary.trim().length > 10) {
                html += '<div class="section-title" style="margin-top:16px;">📋 咨询摘要</div>';
                html += '<div class="section-content">' + escapeHtml(summary.substring(0, 350)) + (summary.length > 350 ? '...' : '') + '</div>';
            }

            // 操作按钮
            html += '<div class="action-btns">';
            
            if (r.status === 'ONGOING') {
                html += '<button class="btn-sm btn-primary" onclick="editRecord(' + r.id + ')">✏️ 编辑记录</button>';
                html += '<button class="btn-sm btn-primary" onclick="newSession(' + r.id + ', ' + r.studentId + ')">➕ 新增会话</button>';
                html += '<button class="btn-sm btn-outline" onclick="viewHistory(' + r.studentId + ')">📖 查看历史</button>';
                html += '<button class="btn-sm btn-success" onclick="closeCase(' + r.id + ',\'' + escapeHtml(studentName).replace(/'/g, "\\'") + '\')">🔒 结案归档</button>';
            } else if (r.status === 'COMPLETED') {
                html += '<button class="btn-sm btn-primary" onclick="viewHistory(' + r.studentId + ')">📖 查看完整档案</button>';
                html += '<button class="btn-sm btn-outline" onclick="exportRecord(' + r.id + ')">📥 导出报告</button>';
            } else {
                html += '<button class="btn-sm btn-outline" onclick="viewDetail(' + r.id + ')">👁️ 查看详情</button>';
            }
            
            html += '</div></div></div>'; // action-btns, record-body, record-card

            return html;
        }

        function formatDate(dateStr) {
            if (!dateStr) return '-';
            var d = new Date(dateStr);
            if (isNaN(d.getTime())) return '-';
            return d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0');
        }

        function hashCode(str) {
            var hash = 0;
            for (var i = 0; i < str.length; i++) {
                hash = ((hash << 5) - hash) + str.charCodeAt(i);
                hash |= 0;
            }
            return hash;
        }

        function escapeHtml(text) {
            if (!text) return '';
            var div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        function extractTags(text) {
            if (!text) return [];
            var keywords = ['学习压力', '焦虑', '抑郁', '人际关系', '睡眠障碍', '情绪管理', 
                          '时间管理', '适应困难', '家庭关系', '恋爱关系', '学业规划',
                          '自我认知', '创伤', '成瘾行为', '进食障碍', '社交恐惧',
                          '考试焦虑', '职业规划'];
            var found = [];
            keywords.forEach(function(kw) {
                if (text.indexOf(kw) !== -1) found.push(kw);
            });
            return found.slice(0, 6);
        }

        function isWarningTag(tag) {
            var warningWords = ['焦虑', '抑郁', '睡眠障碍', '情绪管理', '创伤', '成瘾', '进食障碍', '社交恐惧'];
            for (var i = 0; i < warningWords.length; i++) {
                if (tag.indexOf(warningWords[i]) !== -1) return true;
            }
            return false;
        }

        function isDangerTag(tag) {
            var dangerWords = ['抑郁', '自杀', '自残', '成瘾', '进食障碍'];
            for (var i = 0; i < dangerWords.length; i++) {
                if (tag.indexOf(dangerWords[i]) !== -1) return true;
            }
            return false;
        }

        function updateStatCount(id, value) {
            var el = document.getElementById(id);
            if (el) el.textContent = value;
        }

        function updateTabCount(id, value) {
            var el = document.getElementById(id);
            if (el) el.textContent = '(' + value + ')';
        }
        
        // ========== 操作函数 ==========

        function openModal(modalId) {
            document.getElementById(modalId).classList.add('active');
        }

        function closeModal(modalId) {
            document.getElementById(modalId).classList.remove('active');
        }

        // 点击模态框背景关闭
        document.querySelectorAll('.modal-backdrop').forEach(function(backdrop) {
            backdrop.addEventListener('click', function(e) {
                if (e.target === this) closeModal(this.id);
            });
        });

        function editRecord(id) {
            document.getElementById('editRecordId').value = id;
            document.getElementById('editSummary').value = '';
            document.getElementById('editAssessment').value = '';
            document.getElementById('editFollowUp').value = '';

            fetch(CONTEXT_PATH + '/record/detail?id=' + id)
                .then(function(resp) { return resp.json(); })
                .then(function(result) {
                    if (result.code === 200 && result.data) {
                        var r = result.data;
                        document.getElementById('editSummary').value = r.summaryText || '';
                        document.getElementById('editAssessment').value = r.assessment || '';
                        document.getElementById('editFollowUp').value = r.followUpPlan || '';
                    }
                    openModal('editModal');
                })
                .catch(function(err) {
                    console.error(err);
                    openModal('editModal');
                });
        }

        function submitEdit() {
            var id = document.getElementById('editRecordId').value;
            var summary = document.getElementById('editSummary').value;
            var assessment = document.getElementById('editAssessment').value;
            var followUp = document.getElementById('editFollowUp').value;

            fetch(CONTEXT_PATH + '/record/update', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'id=' + encodeURIComponent(id) +
                      '&summaryText=' + encodeURIComponent(summary) +
                      '&assessment=' + encodeURIComponent(assessment) +
                      '&followUpPlan=' + encodeURIComponent(followUp)
            }).then(function(resp) { return resp.json(); })
              .then(function(result) {
                  if (result.code === 200) {
                      alert('✅ 保存成功');
                      closeModal('editModal');
                      loadRecords(currentStatus);
                  } else {
                      alert('❌ 保存失败: ' + result.message);
                  }
              })
              .catch(function(err) {
                  alert('❌ 网络错误: ' + err.message);
              });
        }

        function newSession(recordId, studentId) {
            document.getElementById('sessionRecordId').value = recordId;
            document.getElementById('sessionStudentId').value = studentId;
            document.getElementById('sessionDate').value = '';
            document.getElementById('sessionTimeSlot').value = '';
            document.getElementById('sessionTopic').value = '';
            document.getElementById('sessionSummary').value = '';
            openModal('sessionModal');
        }

        function submitSession() {
            var recordId = document.getElementById('sessionRecordId').value;
            var date = document.getElementById('sessionDate').value;
            var timeSlot = document.getElementById('sessionTimeSlot').value;
            var topic = document.getElementById('sessionTopic').value;
            var summary = document.getElementById('sessionSummary').value;

            if (!date || !timeSlot) {
                alert('请选择咨询日期和时段');
                return;
            }

            fetch(CONTEXT_PATH + '/record/session', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'recordId=' + encodeURIComponent(recordId) +
                      '&appointmentDate=' + encodeURIComponent(date) +
                      '&timeSlot=' + encodeURIComponent(timeSlot) +
                      '&consultationTopic=' + encodeURIComponent(topic) +
                      '&summaryText=' + encodeURIComponent(summary)
            }).then(function(resp) { return resp.json(); })
              .then(function(result) {
                  if (result.code === 200) {
                      alert('✅ 新增会话成功');
                      closeModal('sessionModal');
                      loadRecords(currentStatus);
                  } else {
                      alert('❌ 新增失败: ' + result.message);
                  }
              })
              .catch(function(err) {
                  alert('❌ 网络错误: ' + err.message);
              });
        }

        function viewHistory(studentId) {
            document.getElementById('historyModalTitle').textContent = '📖 咨询历史';
            document.getElementById('historyModalBody').innerHTML = '<div class="loading-state"><div class="spinner"></div><p class="loading-text">加载历史中...</p></div>';
            openModal('historyModal');

            fetch(CONTEXT_PATH + '/record/history?studentId=' + studentId)
                .then(function(resp) { return resp.json(); })
                .then(function(result) {
                    if (result.code === 200) {
                        renderHistory(result.data || []);
                    } else {
                        document.getElementById('historyModalBody').innerHTML = '<div class="empty-state"><div class="empty-icon">⚠️</div><div class="empty-text">加载失败</div><div class="empty-hint">' + (result.message || '') + '</div></div>';
                    }
                })
                .catch(function(err) {
                    console.error(err);
                    document.getElementById('historyModalBody').innerHTML = '<div class="empty-state"><div class="empty-icon">🔌</div><div class="empty-text">加载失败</div><div class="empty-hint">请检查网络后重试</div></div>';
                });
        }

        function renderHistory(list) {
            if (!list || list.length === 0) {
                document.getElementById('historyModalBody').innerHTML = '<div class="empty-state"><div class="empty-icon">📋</div><div class="empty-text">暂无历史记录</div><div class="empty-hint">该学生还没有其他咨询记录</div></div>';
                return;
            }

            var html = '<div class="history-list">';
            list.forEach(function(r) {
                var statusClass = (r.status || 'ONGOING').toLowerCase();
                var statusText = { ongoing: '进行中', completed: '已结案', cancelled: '已取消' }[statusClass] || r.status;
                var date = formatDate(r.appointmentDate || r.createdAt);
                html += '<div class="history-item status-' + statusClass + '">';
                html += '<div class="history-header">';
                html += '<div class="history-title">' + escapeHtml(r.topic || '心理咨询') + '</div>';
                html += '<span class="record-status-badge badge-' + statusClass + '">' + statusText + '</span>';
                html += '</div>';
                html += '<div class="history-meta">📅 ' + date + ' · ⏰ ' + escapeHtml(r.timeSlot || '-') + ' · 👤 ' + escapeHtml(r.counselorName || '咨询师') + '</div>';
                if (r.summaryText) {
                    html += '<div class="history-section"><div class="history-section-title">📋 咨询摘要</div><div class="history-section-content">' + escapeHtml(r.summaryText) + '</div></div>';
                }
                if (r.assessment) {
                    html += '<div class="history-section"><div class="history-section-title">🩺 初步评估</div><div class="history-section-content">' + escapeHtml(r.assessment) + '</div></div>';
                }
                if (r.followUpPlan) {
                    html += '<div class="history-section"><div class="history-section-title">📌 后续跟进</div><div class="history-section-content">' + escapeHtml(r.followUpPlan) + '</div></div>';
                }
                html += '</div>';
            });
            html += '</div>';
            document.getElementById('historyModalBody').innerHTML = html;
        }

        function viewDetail(id) {
            document.getElementById('historyModalTitle').textContent = '📋 记录详情';
            document.getElementById('historyModalBody').innerHTML = '<div class="loading-state"><div class="spinner"></div><p class="loading-text">加载详情中...</p></div>';
            openModal('historyModal');

            fetch(CONTEXT_PATH + '/record/detail?id=' + id)
                .then(function(resp) { return resp.json(); })
                .then(function(result) {
                    if (result.code === 200) {
                        renderDetail(result.data);
                    } else {
                        document.getElementById('historyModalBody').innerHTML = '<div class="empty-state"><div class="empty-icon">⚠️</div><div class="empty-text">加载失败</div><div class="empty-hint">' + (result.message || '') + '</div></div>';
                    }
                })
                .catch(function(err) {
                    document.getElementById('historyModalBody').innerHTML = '<div class="empty-state"><div class="empty-icon">🔌</div><div class="empty-text">加载失败</div><div class="empty-hint">请检查网络后重试</div></div>';
                });
        }

        function renderDetail(r) {
            var statusClass = (r.status || 'ONGOING').toLowerCase();
            var statusText = { ongoing: '进行中', completed: '已结案', cancelled: '已取消' }[statusClass] || r.status;
            var html = '<div class="history-list">';
            html += '<div class="history-item status-' + statusClass + '">';
            html += '<div class="history-header">';
            html += '<div class="history-title">' + escapeHtml(r.consultationTopic || '心理咨询') + '</div>';
            html += '<span class="record-status-badge badge-' + statusClass + '">' + statusText + '</span>';
            html += '</div>';
            html += '<div class="history-meta">📅 ' + formatDate(r.appointmentDate || r.createdAt) + ' · ⏰ ' + escapeHtml(r.timeSlot || '-') + '</div>';
            if (r.summaryText) {
                html += '<div class="history-section"><div class="history-section-title">📋 咨询摘要</div><div class="history-section-content">' + escapeHtml(r.summaryText) + '</div></div>';
            }
            if (r.assessment) {
                html += '<div class="history-section"><div class="history-section-title">🩺 初步评估</div><div class="history-section-content">' + escapeHtml(r.assessment) + '</div></div>';
            }
            if (r.followUpPlan) {
                html += '<div class="history-section"><div class="history-section-title">📌 后续跟进</div><div class="history-section-content">' + escapeHtml(r.followUpPlan) + '</div></div>';
            }
            html += '</div></div>';
            document.getElementById('historyModalBody').innerHTML = html;
        }

        function exportRecord(id) {
            // 调用 ExportServlet 生成并下载单条咨询记录的 PDF 报告
            var url = CONTEXT_PATH + '/counselor/export/record?id=' + encodeURIComponent(id);
            window.open(url, '_blank');
        }

        function closeCase(id, studentName) {
            if (!confirm('确定要对【' + studentName + '】进行结案操作吗？\n\n结案后该案例将被归档，无法再次编辑。')) return;

            fetch(CONTEXT_PATH + '/record/close', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'id=' + id
            }).then(function(resp) { return resp.json(); })
              .then(function(result) {
                  if (result.code === 200) {
                      alert('✅ 结案成功！');
                      loadRecords(currentStatus);
                  } else {
                      alert('❌ 操作失败: ' + result.message);
                  }
              })
              .catch(function(err) {
                  alert('❌ 网络错误: ' + err.message);
              });
        }
    </script>
</body>
</html>
