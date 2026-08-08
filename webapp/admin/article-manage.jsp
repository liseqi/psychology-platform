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
    <title>文章审核 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .tabs { display: flex; gap: 24px; border-bottom: 2px solid #eee; margin-bottom: 20px; }
        .tab-item { padding: 12px 4px; cursor: pointer; color: #666; position: relative; }
        .tab-item.active { color: #667eea; font-weight: 600; }
        .tab-item.active::after { content:'';position:absolute;bottom:-2px;left:0;right:0;height:2px;background:#667eea; }
        .article-table { width: 100%; background: white; border-radius: 10px; overflow: hidden; border-collapse: collapse; }
        .article-table th { background: #f8f9fa; padding: 14px 16px; text-align: left; color: #333; font-weight: 600; }
        .article-table td { padding: 14px 16px; border-top: 1px solid #eee; color: #555; }
        .article-table tr:hover { background: #fafafa; }
        .status-tag { padding: 4px 12px; border-radius: 12px; font-size: 12px; }
        .status-pending { background: #fff7e6; color: #d48806; }
        .status-approved { background: #f6ffed; color: #52c41a; }
        .status-rejected { background: #fff2f0; color: #ff4d4f; }
        .action-btns { display: flex; gap: 8px; }
        .btn-action { padding: 6px 14px; border-radius: 5px; font-size: 13px; cursor: pointer; border: none; }
        .btn-approve { background: #52c41a; color: white; }
        .btn-reject { background: #ff4d4f; color: white; }
        .btn-view { background: #667eea; color: white; }
        .toolbar { display: flex; justify-content: flex-end; margin-bottom: 16px; }
        .source-badge { color: #667eea; font-size: 12px; }
        .loading-row { text-align: center; padding: 40px; color: #999; }
        .empty-row { text-align: center; padding: 40px; color: #999; }
        .preview-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 2000; align-items: center; justify-content: center; }
        .preview-modal.show { display: flex; }
        .preview-box { background: white; border-radius: 12px; width: 90%; max-width: 800px; max-height: 90vh; overflow: hidden; display: flex; flex-direction: column; }
        .preview-header { padding: 16px 20px; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center; }
        .preview-header h3 { font-size: 18px; margin: 0; }
        .preview-body { padding: 20px; overflow-y: auto; line-height: 1.8; color: #444; }
        .preview-footer { padding: 12px 20px; border-top: 1px solid #eee; text-align: right; }
        .preview-close { background: none; border: none; font-size: 24px; cursor: pointer; color: #999; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>

    <main class="container">
        <header class="page-header">
            <h1>📰 文章审核管理</h1>
            <p>自动拉取壹心理、简单心理、高校心理最新内容 · 审核后发布</p>
        </header>

        <div class="toolbar">
            <button class="btn btn-primary" onclick="fetchLatest()" id="fetchBtn">
                <span>🔄</span> 拉取最新文章
            </button>
        </div>

        <div class="tabs">
            <div class="tab-item active" id="tab-pending" data-status="PENDING_REVIEW" onclick="switchTab('PENDING_REVIEW')">待审核 (0)</div>
            <div class="tab-item" id="tab-approved" data-status="PUBLISHED" onclick="switchTab('PUBLISHED')">已通过 (0)</div>
            <div class="tab-item" id="tab-rejected" data-status="REJECTED" onclick="switchTab('REJECTED')">已拒绝 (0)</div>
        </div>

        <table class="article-table">
            <thead>
                <tr>
                    <th>标题</th>
                    <th>来源</th>
                    <th>作者</th>
                    <th>分类</th>
                    <th>提交时间</th>
                    <th>状态</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody id="articleBody">
                <tr class="loading-row"><td colspan="7">正在加载文章...</td></tr>
            </tbody>
        </table>
    </main>

    <div class="preview-modal" id="previewModal" onclick="closePreview(event)">
        <div class="preview-box" onclick="event.stopPropagation()">
            <div class="preview-header">
                <h3 id="previewTitle">文章预览</h3>
                <button class="preview-close" onclick="closePreview()">&times;</button>
            </div>
            <div class="preview-body" id="previewContent"></div>
            <div class="preview-footer">
                <a id="previewSource" href="#" target="_blank" class="btn btn-default">查看原文</a>
                <button class="btn btn-primary" onclick="closePreview()">关闭</button>
            </div>
        </div>
    </div>

    <script>
        let currentStatus = 'PENDING_REVIEW';
        const statusText = {
            'PENDING_REVIEW': '待审核',
            'PUBLISHED': '已通过',
            'REJECTED': '已拒绝'
        };
        const statusClass = {
            'PENDING_REVIEW': 'status-pending',
            'PUBLISHED': 'status-approved',
            'REJECTED': 'status-rejected'
        };
        const tabMap = {
            'PENDING_REVIEW': 'tab-pending',
            'PUBLISHED': 'tab-approved',
            'REJECTED': 'tab-rejected'
        };
        let hasAutoFetched = false;

        function formatTime(dateStr) {
            if (!dateStr) return '-';
            const date = new Date(dateStr);
            if (isNaN(date)) return dateStr;
            return date.getFullYear() + '-' +
                String(date.getMonth() + 1).padStart(2, '0') + '-' +
                String(date.getDate()).padStart(2, '0') + ' ' +
                String(date.getHours()).padStart(2, '0') + ':' +
                String(date.getMinutes()).padStart(2, '0');
        }

        function switchTab(status) {
            currentStatus = status;
            document.querySelectorAll('.tab-item').forEach(function(t) { t.classList.remove('active'); });
            document.getElementById(tabMap[status]).classList.add('active');
            loadArticles(status);
            refreshAllCounts();
        }

        function loadArticles(status) {
            var tbody = document.getElementById('articleBody');
            tbody.innerHTML = '<tr class="loading-row"><td colspan="7">正在加载文章...</td></tr>';

            fetch('../article/manage/list?status=' + status + '&page=1&pageSize=100')
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    if (data.code !== 200 && data.success !== true) {
                        throw new Error(data.message || '加载失败');
                    }
                    var list = data.data || [];
                    renderTable(list, status);
                })
                .catch(function(err) {
                    tbody.innerHTML = '<tr class="empty-row"><td colspan="7">加载失败：' + err.message + '</td></tr>';
                    showToast('加载失败：' + err.message, 'error');
                });
        }

        function renderTable(list, status) {
            var tbody = document.getElementById('articleBody');
            if (!list || list.length === 0) {
                tbody.innerHTML = '<tr class="empty-row"><td colspan="7">暂无' + statusText[status] + '的文章</td></tr>';
                return;
            }

            var html = '';
            for (var i = 0; i < list.length; i++) {
                var a = list[i];
                var id = a.id;
                var title = a.title || '未命名';
                var source = a.sourceName || '自建';
                var author = a.authorName || '系统抓取';
                var category = a.categoryName || '-';
                var time = formatTime(a.createdAt || a.publishedAt);
                var buttons = '';

                if (status === 'PENDING_REVIEW') {
                    buttons = '<button class="btn-action btn-view" onclick="previewArticle(' + id + ')">预览</button>' +
                        '<button class="btn-action btn-approve" onclick="reviewArticle(' + id + ', \'approve\')">通过</button>' +
                        '<button class="btn-action btn-reject" onclick="reviewArticle(' + id + ', \'reject\')">拒绝</button>';
                } else if (status === 'PUBLISHED') {
                    buttons = '<button class="btn-action btn-view" onclick="previewArticle(' + id + ')">预览</button>' +
                        '<span style="color:#999;">已发布</span>';
                } else {
                    buttons = '<button class="btn-action btn-view" onclick="previewArticle(' + id + ')">预览</button>' +
                        '<span style="color:#999;">已拒绝</span>';
                }

                html += '<tr data-id="' + id + '">' +
                    '<td><strong>' + escapeHtml(title) + '</strong></td>' +
                    '<td><span class="source-badge">' + escapeHtml(source) + '</span></td>' +
                    '<td>' + escapeHtml(author) + '</td>' +
                    '<td>' + escapeHtml(category) + '</td>' +
                    '<td>' + time + '</td>' +
                    '<td><span class="status-tag ' + statusClass[status] + '">' + statusText[status] + '</span></td>' +
                    '<td class="action-btns">' + buttons + '</td>' +
                    '</tr>';
            }
            tbody.innerHTML = html;
        }

        function updateTabCount(status, count) {
            var tab = document.getElementById(tabMap[status]);
            if (tab) {
                tab.textContent = statusText[status] + ' (' + count + ')';
            }
        }

        function fetchLatest() {
            var btn = document.getElementById('fetchBtn');
            btn.disabled = true;
            btn.innerHTML = '<span>⏳</span> 拉取中...';
            showToast('正在自动拉取三个来源的最新文章...', 'info');

            fetch('../article/fetch', { method: 'POST' })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    btn.disabled = false;
                    btn.innerHTML = '<span>🔄</span> 拉取最新文章';
                    if (data.code !== 200 && data.success !== true) {
                        showToast('拉取失败：' + (data.message || '未知错误'), 'error');
                        return;
                    }
                    var msg = data.data && data.data.message ? data.data.message : '拉取完成';
                    var total = data.data && data.data.total ? data.data.total : 0;
                    showToast(msg, total > 0 ? 'success' : 'info');
                    loadArticles(currentStatus);
                    refreshAllCounts();
                })
                .catch(function(err) {
                    btn.disabled = false;
                    btn.innerHTML = '<span>🔄</span> 拉取最新文章';
                    showToast('拉取失败：' + err.message, 'error');
                });
        }

        function refreshAllCounts() {
            fetch('../article/manage/count')
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    if (data.code !== 200 && data.success !== true) {
                        throw new Error(data.message || '加载失败');
                    }
                    var counts = data.data || {};
                    ['PENDING_REVIEW', 'PUBLISHED', 'REJECTED'].forEach(function(s) {
                        updateTabCount(s, counts[s] || 0);
                    });
                })
                .catch(function(err) {
                    console.error('刷新数量失败：', err);
                });
        }

        function reviewArticle(id, action) {
            if (action === 'reject' && !confirm('确认拒绝该文章吗？')) {
                return;
            }
            var formData = 'id=' + id + '&action=' + action;
            fetch('../article/review', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: formData
            })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    if (data.code !== 200 && data.success !== true) {
                        showToast('操作失败：' + (data.message || ''), 'error');
                        return;
                    }
                    showToast(action === 'approve' ? '已通过' : '已拒绝', 'success');
                    loadArticles(currentStatus);
                    refreshAllCounts();
                })
                .catch(function(err) {
                    showToast('操作失败：' + err.message, 'error');
                });
        }

        function previewArticle(id) {
            fetch('../article/manage/list?status=ALL&page=1&pageSize=1000')
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    var list = data.data || [];
                    var article = null;
                    for (var i = 0; i < list.length; i++) {
                        if (list[i].id == id) { article = list[i]; break; }
                    }
                    if (!article) {
                        showToast('文章不存在', 'error');
                        return;
                    }
                    document.getElementById('previewTitle').textContent = article.title || '文章预览';
                    document.getElementById('previewContent').innerHTML = formatContent(article.content || '暂无内容');
                    var sourceLink = document.getElementById('previewSource');
                    if (article.sourceUrl) {
                        sourceLink.href = article.sourceUrl;
                        sourceLink.style.display = 'inline-flex';
                    } else {
                        sourceLink.style.display = 'none';
                    }
                    document.getElementById('previewModal').classList.add('show');
                });
        }

        function formatContent(content) {
            return escapeHtml(content)
                .replace(/\n/g, '<br>');
        }

        function closePreview(e) {
            if (!e || e.target.id === 'previewModal') {
                document.getElementById('previewModal').classList.remove('show');
            }
        }

        function escapeHtml(str) {
            if (!str) return '';
            return String(str)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#039;');
        }

        function showToast(message, type) {
            var existing = document.querySelector('.toast');
            if (existing) existing.remove();

            var toast = document.createElement('div');
            toast.className = 'toast toast-' + (type || 'info');
            toast.textContent = message;
            document.body.appendChild(toast);

            setTimeout(function() {
                toast.style.opacity = '0';
                toast.style.transform = 'translateX(50px)';
                setTimeout(function() { toast.remove(); }, 300);
            }, 3000);
        }

        // 页面加载时自动拉取最新文章，并加载待审核列表
        window.onload = function() {
            loadArticles('PENDING_REVIEW');
            refreshAllCounts();
            if (!hasAutoFetched) {
                hasAutoFetched = true;
                fetchLatest();
            }
        };
    </script>
</body>
</html>
