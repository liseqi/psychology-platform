<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.dao.ArticleDao" %>
<%@ page import="com.psychology.entity.Article" %>
<%@ page import="com.psychology.entity.User" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User currentUser = (User) session.getAttribute("currentUser");

    String idStr = request.getParameter("id");
    Article article = null;
    String errorMsg = null;

    if (idStr != null && !idStr.isEmpty()) {
        try {
            ArticleDao articleDao = new ArticleDao();
            article = articleDao.findById(Long.parseLong(idStr));
            if (article == null) {
                errorMsg = "文章不存在";
            } else if (!"PUBLISHED".equals(article.getStatus())) {
                errorMsg = "文章尚未发布";
            } else {
                // 增加阅读量
                articleDao.incrementViewCount(article.getId());
            }
        } catch (Exception e) {
            errorMsg = "参数错误";
        }
    } else {
        errorMsg = "请指定文章ID";
    }

    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= article != null ? com.psychology.util.CommonUtil.escapeHtml(article.getTitle()) : "文章详情" %> - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .detail-container { max-width: 860px; margin: 30px auto; padding: 0 20px; }
        .breadcrumb { margin-bottom: 20px; font-size: 14px; color: #999; }
        .breadcrumb a { color: #667eea; text-decoration: none; }
        .breadcrumb a:hover { text-decoration: underline; }

        .article-header { background: white; border-radius: 16px; padding: 40px; margin-bottom: 24px; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
        .article-category { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 13px; margin-bottom: 16px; }
        .article-title { font-size: 28px; font-weight: 700; color: #1a1a2e; line-height: 1.4; margin-bottom: 16px; }
        .article-meta { display: flex; gap: 24px; flex-wrap: wrap; font-size: 14px; color: #999; align-items: center; }
        .article-meta span { display: flex; align-items: center; gap: 4px; }
        .source-tag { display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px; border-radius: 10px; font-size: 12px; background: #f0f5ff; color: #2f54eb; }
        .source-tag a { color: #2f54eb; text-decoration: none; max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .source-tag a:hover { text-decoration: underline; }

        .article-content { background: white; border-radius: 16px; padding: 40px; box-shadow: 0 2px 12px rgba(0,0,0,0.06); font-size: 16px; line-height: 1.9; color: #333; }
        .article-content p { margin-bottom: 20px; text-indent: 2em; }
        .article-content p:last-child { margin-bottom: 0; }
        .article-content h3 { font-size: 20px; margin: 28px 0 14px; color: #1a1a2e; }
        .article-summary { background: #f8f9ff; border-left: 4px solid #667eea; padding: 16px 20px; border-radius: 0 8px 8px 0; margin-bottom: 28px; font-size: 15px; color: #555; }

        .error-card { background: white; border-radius: 16px; padding: 60px 20px; text-align: center; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
        .error-icon { font-size: 64px; margin-bottom: 16px; }
        .error-msg { font-size: 18px; color: #666; margin-bottom: 24px; }
        .back-btn { display: inline-block; padding: 10px 24px; background: #667eea; color: white; border-radius: 8px; text-decoration: none; font-size: 14px; }
        .back-btn:hover { background: #5a6fd6; }

        .action-bar { display: flex; gap: 12px; margin-top: 24px; padding: 20px; background: white; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,0.06); align-items: center; }
        .action-btn { display: inline-flex; align-items: center; gap: 6px; padding: 8px 16px; border-radius: 8px; border: 1px solid #d9d9d9; background: white; cursor: pointer; font-size: 14px; color: #666; transition: all 0.2s; text-decoration: none; }
        .action-btn:hover { border-color: #667eea; color: #667eea; }
        .action-btn.like-btn.liked { background: #fff2f0; border-color: #ff4d4f; color: #ff4d4f; }
    </style>
</head>
<body>
    <jsp:include page="../components/navbar.jsp" />

    <main class="container">
        <div class="detail-container">
            <div class="breadcrumb">
                <a href="list.jsp">📚 科普文库</a> / 文章详情
            </div>

            <% if (errorMsg != null) { %>
                <div class="error-card">
                    <div class="error-icon">📄</div>
                    <div class="error-msg"><%= errorMsg %></div>
                    <a href="list.jsp" class="back-btn">← 返回文章列表</a>
                </div>
            <% } else { %>
                <%
                    String catColor = "background:#e6f7ff;color:#1890ff;";
                    String catName = article.getCategoryName() != null ? article.getCategoryName() : "心理科普";
                    if (catName.contains("焦虑") || catName.contains("情绪")) catColor = "background:#e6f7ff;color:#1890ff;";
                    else if (catName.contains("压力") || catName.contains("学业")) catColor = "background:#fffbe6;color:#faad14;";
                    else if (catName.contains("恋爱") || catName.contains("亲密")) catColor = "background:#e6fffb;color:#13c2c2;";
                    else if (catName.contains("人际")) catColor = "background:#f6ffed;color:#52c41a;";
                    else if (catName.contains("成长") || catName.contains("自我")) catColor = "background:#f9f0ff;color:#722ed1;";
                    else if (catName.contains("抑郁")) catColor = "background:#fff2f0;color:#ff4d4f;";
                %>

                <div class="article-header">
                    <span class="article-category" style="<%= catColor %>"><%= catName %></span>
                    <h1 class="article-title"><%= com.psychology.util.CommonUtil.escapeHtml(article.getTitle()) %></h1>
                    <div class="article-meta">
                        <% if (article.getSourceName() != null && !article.getSourceName().isEmpty()) { %>
                            <span class="source-tag">
                                📌 <%= com.psychology.util.CommonUtil.escapeHtml(article.getSourceName()) %>
                                <% if (article.getSourceUrl() != null && !article.getSourceUrl().isEmpty()) { %>
                                    <a href="<%= com.psychology.util.CommonUtil.escapeHtml(article.getSourceUrl()) %>" target="_blank" title="查看原文">🔗</a>
                                <% } %>
                            </span>
                        <% } %>
                        <% if (article.getPublishedAt() != null) { %>
                            <span>🕐 <%= sdf.format(article.getPublishedAt()) %></span>
                        <% } %>
                        <span>👁 <%= article.getViewCount() != null ? article.getViewCount() + 1 : 1 %> 阅读</span>
                    </div>
                </div>

                <div class="article-content">
                    <% if (article.getSummary() != null && !article.getSummary().isEmpty()) { %>
                        <div class="article-summary">
                            <strong>📖 摘要：</strong><%= com.psychology.util.CommonUtil.escapeHtml(article.getSummary()) %>
                        </div>
                    <% } %>

                    <%
                        String content = article.getContent();
                        if (content != null && !content.isEmpty()) {
                            // 将内容按段落拆分
                            String[] paragraphs = content.split("\n\n");
                            for (String para : paragraphs) {
                                String trimmed = para.trim();
                                if (!trimmed.isEmpty()) {
                                    // 检查是否已经包含HTML标签
                                    if (trimmed.startsWith("<")) {
                                        out.print(trimmed);
                                    } else {
                                        out.print("<p>" + com.psychology.util.CommonUtil.escapeHtml(trimmed) + "</p>");
                                    }
                                }
                            }
                        } else {
                    %>
                            <div class="error-card" style="box-shadow:none;padding:40px 20px;">
                                <div class="error-icon">📝</div>
                                <div class="error-msg">暂无正文内容</div>
                            </div>
                    <% } %>
                </div>

                <div class="action-bar">
                    <a href="list.jsp" class="action-btn">← 返回列表</a>
                    <button class="action-btn" onclick="window.print()">🖨 打印</button>
                    <% if (article.getSourceUrl() != null && !article.getSourceUrl().isEmpty()) { %>
                        <a href="<%= com.psychology.util.CommonUtil.escapeHtml(article.getSourceUrl()) %>" target="_blank" class="action-btn">🔗 查看原文</a>
                    <% } %>
                </div>
            <% } %>
        </div>
    </main>
</body>
</html>
