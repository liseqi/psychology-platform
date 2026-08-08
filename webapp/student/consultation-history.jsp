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
        .section-content { color: #555; line-height: 1.75; font-size: 14px; background: linear-gradient(135deg,#f0f5ff,#fafbff); padding: 16px 18px; border-radius: 10px; border: 1px solid #f0f0f5; white-space: pre-wrap; word-break: break-word; }
        
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
        .btn-outline:hover { border-color: #667eea; color: #667eea; background: #f0f5ff; }
        
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
            <h1>📋 我的咨询记录</h1>
            <p>查看您的心理咨询记录，追踪个人成长轨迹</p>
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

    <!-- 查看详情模态框 -->
    <div class="modal-backdrop" id="detailModal">
        <div class="modal" style="max-width: 800px;">
            <div class="modal-header">
                <div class="modal-title" id="detailModalTitle">📋 记录详情</div>
                <button class="modal-close" onclick="closeModal('detailModal')">&times;</button>
            </div>
            <div class="modal-body" id="detailModalBody">
                <div class="loading-state"><div class="spinner"></div><p class="loading-text">加载详情中...</p></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-default" onclick="closeModal('detailModal')">关闭</button>
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
        // ========== 全局变量 ==========
        var currentStatus = 'ALL';
        var recordsData = [];
        // 获取当前登录学生的ID（用于API调用和权限控制）
        var currentStudentId = <%= user.getId() %>;
        var CONTEXT_PATH = '${pageContext.request.contextPath}' || 
                           window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1));
        
        // ========== 页面初始化 ==========
        document.addEventListener('DOMContentLoaded', function() {
            console.log('[Student] 页面加载完成，学生ID:', currentStudentId);
            
            // 初始加载数据
            loadRecords('ALL');
            
            // Tab切换事件绑定
            document.querySelectorAll('.tab').forEach(function(tab) {
                tab.addEventListener('click', function() {
                    var status = this.getAttribute('data-status');
                    switchTab(this);
                    loadRecords(status);
                });
            });
        });

        // ========== Tab切换 ==========
        function switchTab(activeTab) {
            document.querySelectorAll('.tab').forEach(function(t) { t.classList.remove('active'); });
            activeTab.classList.add('active');
            currentStatus = activeTab.getAttribute('data-status');
        }

        // ========== 数据加载核心函数 ==========
        function loadRecords(status) {
            var container = document.getElementById('recordsList');
            container.innerHTML = '<div class="loading-state"><div class="spinner"></div><p class="loading-text">加载中...</p></div>';
            
            // 构建请求URL（与咨询师端保持一致的API调用方式）
            var url = CONTEXT_PATH + '/record/list?status=' + encodeURIComponent(status);
            
            console.log('[Student] 请求URL:', url);
            console.log('[Student] 当前状态:', status);
            
            fetch(url, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            })
            .then(function(resp) {
                console.log('[Student] 响应状态:', resp.status);
                if (!resp.ok) {
                    throw new Error('HTTP ' + resp.status);
                }
                return resp.json();
            })
            .then(function(result) {
                console.log('[Student] 返回数据:', result);
                
                if (result.code === 200) {
                    renderRecords(result.data || {});
                } else {
                    container.innerHTML = '<div class="empty-state">' +
                        '<div class="empty-icon">⚠️</div>' +
                        '<div class="empty-text">加载失败</div>' +
                        '<div class="empty-hint">' + (result.message || '未知错误') + '</div>' +
                        '</div>';
                }
            })
            .catch(function(err) {
                console.error('[Student] 请求失败:', err);
                container.innerHTML = '<div class="empty-state">' +
                    '<div class="empty-icon">🔌</div>' +
                    '<div class="empty-text">网络连接失败</div>' +
                    '<div class="empty-hint">请检查网络后刷新重试</div>' +
                    '</div>';
            });
        }

        // ========== 渲染记录列表 ==========
        function renderRecords(data) {
            try {
                // 更新统计数据（与咨询师端完全一致）
            updateStatCount('countTotal', data.total || 0);
            updateStatCount('countOngoing', data.ongoing || 0);
            updateStatCount('countCompleted', data.completed || 0);
            updateStatCount('countCancelled', data.cancelled || 0);
            
            // 更新Tab计数
            updateTabCount('tabTotal', data.total || 0);
            updateTabCount('tabOngoing', data.ongoing || 0);
            updateTabCount('tabCompleted', data.completed || 0);
            updateTabCount('tabCancelled', data.cancelled || 0);

            var records = data.records || [];
            var container = document.getElementById('recordsList');

            console.log('[Student] 渲染记录，共', records.length, '条');

            if (records.length === 0) {
                var emptyMsg = getEmptyMessage(currentStatus);
                container.innerHTML = '<div class="empty-state">' +
                    '<div class="empty-icon">' + emptyMsg.icon + '</div>' +
                    '<div class="empty-text">' + emptyMsg.text + '</div>' +
                    '<div class="empty-hint">' + emptyMsg.hint + '</div>' +
                    '</div>';
                return;
            }

            // 构建记录卡片HTML
            var html = '';
            records.forEach(function(record) {
                html += buildRecordCard(record);
            });

            container.innerHTML = html;
            } catch(e) {
                console.error('[DEBUG] renderRecords错误:', e);
                alert('[DEBUG ERROR] ' + e.message + '\n\n原始数据:\n' + JSON.stringify(data, null, 2));
            }
        }

        // ========== 空状态消息 ==========
        function getEmptyMessage(status) {
            switch(status) {
                case 'ONGOING': 
                    return { icon: '🔄', text: '暂无进行中的咨询记录', hint: '当前没有正在进行的咨询' };
                case 'COMPLETED': 
                    return { icon: '✅', text: '暂无已结案的咨询记录', hint: '完成的咨询会显示在这里' };
                case 'CANCELLED': 
                    return { icon: '❌', text: '暂无已取消的咨询记录', hint: '取消的预约会显示在这里' };
                default: 
                    return { icon: '📝', text: '暂无咨询记录', hint: '您还没有任何咨询记录，预约咨询后将在这里显示' };
            }
        }

        // ========== 构建记录卡片（学生端版本）==========
        function buildRecordCard(r) {
            // 状态配置（与咨询师端一致）
            var statusConfig = {
                'ONGOING': { text: '进行中', badgeClass: 'badge-ongoing', cardClass: 'status-ongoing' },
                'COMPLETED': { text: '已结案', badgeClass: 'badge-completed', cardClass: 'status-completed' },
                'CANCELLED': { text: '已取消', badgeClass: 'badge-cancelled', cardClass: 'status-cancelled' }
            };
            var statusCfg = statusConfig[r.status] || { text: '待接待', badgeClass: '', cardClass: '' };

            // 【学生端特殊】展示咨询师信息（而非学生信息）
            var counselorName = r.counselorName || '未知咨询师';
            var initial = counselorName.charAt(counselorName.length - 1) || '师';

            // 咨询次数
            var sessionText = r.sessionCount > 0 ? ('第 ' + r.sessionCount + ' 次') : '首次咨询';

            // 时间格式化（与咨询师端一致）
            var lastDate = formatDate(r.lastDate || r.createdAt);
            var createDate = formatDate(r.createdAt);

            // 头像颜色方案（与咨询师端一致）
            var colors = [
                'linear-gradient(135deg,#667eea,#764ba2)',
                'linear-gradient(135deg,#f093fb,#f5576c)',
                'linear-gradient(135deg,#4facfe,#00f2fe)',
                'linear-gradient(135deg,#43e97b,#38f9d7)',
                'linear-gradient(135deg,#fa709a,#fee140)',
                'linear-gradient(135deg,#764ba2,#667eea)'
            ];
            var colorIndex = Math.abs(hashCode(counselorName)) % colors.length;

            // 开始构建卡片HTML
            var html = '<div class="record-card ' + statusCfg.cardClass + '">';
            
            // 头部：【学生端】显示咨询师信息 + 状态标签
            html += '<div class="record-header">';
            html += '<div class="student-info">';
            html += '<div class="student-avatar" style="background:' + colors[colorIndex] + '">' + initial + '</div>';
            html += '<div>';
            html += '<div class="student-name">' + escapeHtml(counselorName) + '</div>';  // 显示咨询师姓名
            html += '<div class="student-id">';
            // 【学生端】显示咨询师角色和部门
            if (r.counselorRole) {
                var roleText = r.counselorRole === 'COUNSELOR' ? '心理咨询师' : r.counselorRole;
                html += escapeHtml(roleText) + ' · ';
            }
            if (r.counselorDepartment) html += escapeHtml(r.counselorDepartment);
            html += '</div>';
            html += '</div></div>'; 
            
            html += '<span class="record-status-badge ' + statusCfg.badgeClass + '">' + statusCfg.text + '</span>';
            html += '</div>';

            // 元数据行（与咨询师端一致）
            html += '<div class="meta-row">';
            html += '<div class="meta-item"><span class="meta-label">💬 咨询次数:</span><span class="meta-value">' + sessionText + '</span></div>';
            html += '<div class="meta-item"><span class="meta-label">📅 上次咨询:</span><span class="meta-value">' + lastDate + '</span></div>';
            html += '<div class="meta-item"><span class="meta-label">📝 创建时间:</span><span class="meta-value">' + createDate + '</span></div>';
            html += '</div>';

            // 主体内容
            html += '<div class="record-body">';

            // 咨询主题/主诉问题（与咨询师端一致）
            var topic = r.topic || r.consultationTopic || '';
            if (topic && topic.trim().length > 0) {
                html += '<div class="section-title">📌 咨询主题</div>';
                html += '<div class="section-content">' + escapeHtml(topic) + '</div>';
                
                // 关键词标签提取（与咨询师端一致）
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

            // 摘要内容（与咨询师端一致）
            var summary = r.summaryText || '';
            if (summary && summary.trim().length > 10) {
                html += '<div class="section-title" style="margin-top:16px;">📋 咨询摘要</div>';
                html += '<div class="section-content">' + escapeHtml(summary.substring(0, 350)) + (summary.length > 350 ? '...' : '') + '</div>';
            }

            // 【学生端】操作按钮 - 只提供查看功能（无编辑权限）
            html += '<div class="action-btns">';
            
            if (r.status === 'ONGOING') {
                // 进行中的咨询：可查看历史、查看详情
                html += '<button class="btn-sm btn-outline" onclick="viewHistory(' + currentStudentId + ')">📖 查看历史</button>';
                html += '<button class="btn-sm btn-outline" onclick="viewDetail(' + r.id + ')">👁️ 查看详情</button>';
            } else if (r.status === 'COMPLETED') {
                // 已结案的咨询：可查看完整档案、查看详情
                html += '<button class="btn-sm btn-primary" onclick="viewHistory(' + currentStudentId + ')">📖 查看完整档案</button>';
                html += '<button class="btn-sm btn-outline" onclick="viewDetail(' + r.id + ')">👁️ 查看详情</button>';
            } else {
                // 其他状态：仅查看详情
                html += '<button class="btn-sm btn-outline" onclick="viewDetail(' + r.id + ')">👁️ 查看详情</button>';
            }
            
            html += '</div></div></div>';

            return html;
        }

        // ========== 工具函数（与咨询师端完全一致）==========
        
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

        // 关键词标签提取（与咨询师端完全一致）
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

        // 警告标签判断（与咨询师端完全一致）
        function isWarningTag(tag) {
            var warningWords = ['焦虑', '抑郁', '睡眠障碍', '情绪管理', '创伤', '成瘾', '进食障碍', '社交恐惧'];
            for (var i = 0; i < warningWords.length; i++) {
                if (tag.indexOf(warningWords[i]) !== -1) return true;
            }
            return false;
        }

        // 危险标签判断（与咨询师端完全一致）
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
        
        // ========== 操作函数（学生端只读版本）==========

        function openModal(modalId) {
            document.getElementById(modalId).classList.add('active');
        }

        function closeModal(modalId) {
            document.getElementById(modalId).classList.remove('active');
        }

        // 点击模态框背景关闭（与咨询师端一致）
        document.querySelectorAll('.modal-backdrop').forEach(function(backdrop) {
            backdrop.addEventListener('click', function(e) {
                if (e.target === this) closeModal(this.id);
            });
        });

        /**
         * 查看咨询历史（调用相同的后端API）
         * @param {number} studentIdParam 学生ID
         */
        function viewHistory(studentIdParam) {
            document.getElementById('historyModalTitle').textContent = '📖 我的咨询历史';
            document.getElementById('historyModalBody').innerHTML = '<div class="loading-state"><div class="spinner"></div><p class="loading-text">加载历史中...</p></div>';
            openModal('historyModal');

            console.log('[Student] 请求历史数据，studentId:', studentIdParam);

            fetch(CONTEXT_PATH + '/record/history?studentId=' + studentIdParam)
                .then(function(resp) { return resp.json(); })
                .then(function(result) {
                    console.log('[Student] 历史数据返回:', result);
                    if (result.code === 200) {
                        renderHistory(result.data || []);
                    } else {
                        document.getElementById('historyModalBody').innerHTML = '<div class="empty-state">' +
                            '<div class="empty-icon">⚠️</div>' +
                            '<div class="empty-text">加载失败</div>' +
                            '<div class="empty-hint">' + (result.message || '') + '</div>' +
                            '</div>';
                    }
                })
                .catch(function(err) {
                    console.error('[Student] 加载历史失败:', err);
                    document.getElementById('historyModalBody').innerHTML = '<div class="empty-state">' +
                        '<div class="empty-icon">🔌</div>' +
                        '<div class="empty-text">加载失败</div>' +
                        '<div class="empty-hint">请检查网络后重试</div>' +
                        '</div>';
                });
        }

        /**
         * 渲染历史记录列表（与咨询师端的renderHistory逻辑一致）
         * @param {Array} list 历史记录数组
         */
        function renderHistory(list) {
            if (!list || list.length === 0) {
                document.getElementById('historyModalBody').innerHTML = '<div class="empty-state">' +
                    '<div class="empty-icon">📋</div>' +
                    '<div class="empty-text">暂无历史记录</div>' +
                    '<div class="empty-hint">您还没有其他咨询记录</div>' +
                    '</div>';
                return;
            }

            var html = '<div class="history-list">';
            list.forEach(function(r) {
                var statusClass = (r.status || 'ONGOING').toLowerCase();
                var statusText = { ongoing: '进行中', completed: '已结案', cancelled: '已取消' }[statusClass] || r.status;
                var date = formatDate(r.appointmentDate || r.createdAt);
                
                html += '<div class="history-item status-' + statusClass + '">';
                html += '<div class="history-header">';
                html += '<div class="history-title">' + escapeHtml(r.topic || r.consultationTopic || '心理咨询') + '</div>';
                html += '<span class="record-status-badge badge-' + statusClass + '">' + statusText + '</span>';
                html += '</div>';
                // 【学生端】显示咨询师信息
                html += '<div class="history-meta">📅 ' + date + ' · ⏰ ' + escapeHtml(r.timeSlot || '-') + ' · 👤 ' + escapeHtml(r.counselorName || '咨询师') + '</div>';
                
                if (r.summaryText) {
                    html += '<div class="history-section"><div class="history-section-title">📋 咨询摘要</div><div class="history-section-content">' + escapeHtml(r.summaryText) + '</div></div>';
                }
                if (r.assessment) {
                    html += '<div class="history-section"><div class="history-section-title">🩺 初步评估</div><div class="history-section-content">' + escapeHtml(r.assessment) + '</div></div>';
                }
                if (r.followUpPlan) {
                    html += '<div class="history-section"><div class="history-section-title">📌 后续跟进计划</div><div class="history-section-content">' + escapeHtml(r.followUpPlan) + '</div></div>';
                }
                html += '</div>';
            });
            html += '</div>';
            document.getElementById('historyModalBody').innerHTML = html;
        }

        /**
         * 查看单条记录详情（调用相同的后端API）
         * @param {number} recordId 记录ID
         */
        function viewDetail(recordId) {
            document.getElementById('detailModalTitle').textContent = '📋 记录详情';
            document.getElementById('detailModalBody').innerHTML = '<div class="loading-state"><div class="spinner"></div><p class="loading-text">加载详情中...</p></div>';
            openModal('detailModal');

            console.log('[Student] 请求记录详情，id:', recordId);

            fetch(CONTEXT_PATH + '/record/detail?id=' + recordId)
                .then(function(resp) { return resp.json(); })
                .then(function(result) {
                    console.log('[Student] 详情数据返回:', result);
                    if (result.code === 200) {
                        renderDetail(result.data);
                    } else {
                        document.getElementById('detailModalBody').innerHTML = '<div class="empty-state">' +
                            '<div class="empty-icon">⚠️</div>' +
                            '<div class="empty-text">加载失败</div>' +
                            '<div class="empty-hint">' + (result.message || '') + '</div>' +
                            '</div>';
                    }
                })
                .catch(function(err) {
                    console.error('[Student] 加载详情失败:', err);
                    document.getElementById('detailModalBody').innerHTML = '<div class="empty-state">' +
                        '<div class="empty-icon">🔌</div>' +
                        '<div class="empty-text">加载失败</div>' +
                        '<div class="empty-hint">请检查网络后重试</div>' +
                        '</div>';
                });
        }

        /**
         * 渲染记录详情（与咨询师端的renderDetail逻辑一致，但展示咨询师信息）
         * @param {Object} r 记录对象
         */
        function renderDetail(r) {
            var statusClass = (r.status || 'ONGOING').toLowerCase();
            var statusText = { ongoing: '进行中', completed: '已结案', cancelled: '已取消' }[statusClass] || r.status;
            
            var html = '<div class="history-list">';
            html += '<div class="history-item status-' + statusClass + '">';
            html += '<div class="history-header">';
            html += '<div class="history-title">' + escapeHtml(r.consultationTopic || r.topic || '心理咨询') + '</div>';
            html += '<span class="record-status-badge badge-' + statusClass + '">' + statusText + '</span>';
            html += '</div>';
            
            // 【学生端】显示咨询师详细信息
            if (r.counselorName) {
                html += '<div class="history-meta">👤 咨询师: ' + escapeHtml(r.counselorName);
                if (r.counselorTitle) html += ' (' + escapeHtml(r.counselorTitle) + ')';
                if (r.counselorDepartment) html += ' - ' + escapeHtml(r.counselorDepartment);
                html += '</div>';
            }
            
            html += '<div class="history-meta">📅 ' + formatDate(r.appointmentDate || r.createdAt) + ' · ⏰ ' + escapeHtml(r.timeSlot || '-') + '</div>';
            
            if (r.summaryText) {
                html += '<div class="history-section"><div class="history-section-title">📋 咨询摘要</div><div class="history-section-content">' + escapeHtml(r.summaryText) + '</div></div>';
            }
            if (r.assessment) {
                html += '<div class="history-section"><div class="history-section-title">🩺 初步评估</div><div class="history-section-content">' + escapeHtml(r.assessment) + '</div></div>';
            }
            if (r.followUpPlan) {
                html += '<div class="history-section"><div class="history-section-title">📌 后续跟进计划</div><div class="history-section-content">' + escapeHtml(r.followUpPlan) + '</div></div>';
            }
            html += '</div></div>';
            
            document.getElementById('detailModalBody').innerHTML = html;
        }
    </script>
</body>
</html>
