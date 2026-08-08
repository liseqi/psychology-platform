<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.dao.ArticleDao" %>
<%@ page import="com.psychology.entity.Article" %>
<%@ page import="com.psychology.entity.User" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Arrays" %>
<%
    User user = (User) session.getAttribute("currentUser");

    // 服务器端直接查询已发布文章，避免 JS 渲染失败导致白屏
    ArticleDao articleDao = new ArticleDao();
    String keyword = request.getParameter("keyword");
    String categoryIdStr = request.getParameter("categoryId");
    Integer categoryId = null;
    if (categoryIdStr != null && !categoryIdStr.isEmpty()) {
        try { categoryId = Integer.parseInt(categoryIdStr); } catch (Exception e) {}
    }
    List<Article> articles = articleDao.findPublished(1, 100, categoryId, keyword);

    // 查询分类列表
    List<Map<String, Object>> categories = articleDao.findAllCategories();

    // 定义分类颜色映射
    Map<String, String> catColorMap = new HashMap<>();
    catColorMap.put("情绪疏导", "background:#e6f7ff;color:#1890ff;");
    catColorMap.put("焦虑管理", "background:#e6f7ff;color:#1890ff;");
    catColorMap.put("压力缓解", "background:#fffbe6;color:#faad14;");
    catColorMap.put("学业压力", "background:#fffbe6;color:#faad14;");
    catColorMap.put("恋爱心理", "background:#e6fffb;color:#13c2c2;");
    catColorMap.put("人际交往", "background:#f6ffed;color:#52c41a;");
    catColorMap.put("人际关系", "background:#f6ffed;color:#52c41a;");
    catColorMap.put("自我成长", "background:#f9f0ff;color:#722ed1;");
    catColorMap.put("抑郁情绪", "background:#fff2f0;color:#ff4d4f;");

    List<String> emojis = Arrays.asList("😰","😴","🤝","😔","🧘","💕","📚","🌟","💪","🎯","🌈","🌿","🎓","💡","❤️","🏠");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>科普文章 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .hero-banner { background: linear-gradient(135deg,#667eea 0%,#764ba2 100%); border-radius: 16px; padding: 40px; color: white; margin-bottom: 30px; }
        .hero-title { font-size: 28px; font-weight: bold; margin-bottom: 10px; }
        .hero-desc { opacity: 0.9; font-size: 16px; }
        .category-tabs { display: flex; gap: 12px; margin-bottom: 24px; flex-wrap: wrap; }
        .cat-tab { padding: 10px 20px; border-radius: 20px; cursor: pointer; font-size: 14px; transition: all 0.2s; background: white; color: #666; box-shadow: 0 1px 4px rgba(0,0,0,0.08); border: none; text-decoration: none; }
        .cat-tab:hover, .cat-tab.active { background: #667eea; color: white; }
        .article-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 24px; }
        .article-card { background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.08); transition: transform 0.2s, box-shadow 0.2s; cursor: pointer; }
        .article-card:hover { transform: translateY(-4px); box-shadow: 0 12px 28px rgba(0,0,0,0.15); }
        .article-cover { height: 160px; display: flex; align-items: center; justify-content: center; font-size: 48px; position: relative; }
        .source-badge { position: absolute; top: 12px; right: 12px; padding: 3px 10px; border-radius: 10px; font-size: 11px; background: rgba(255,255,255,0.9); color: #555; }
        .article-body { padding: 20px; }
        .article-category { display: inline-block; padding: 3px 10px; border-radius: 10px; font-size: 12px; margin-bottom: 10px; }
        .article-title { font-size: 17px; font-weight: 600; color: #333; line-height: 1.5; margin-bottom: 10px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .article-excerpt { color: #666; font-size: 14px; line-height: 1.6; margin-bottom: 16px; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
        .article-meta { display: flex; justify-content: space-between; align-items: center; color: #999; font-size: 13px; }
        .read-more { color: #667eea; font-weight: 500; }
        .loading-text, .empty-text { text-align: center; padding: 60px 20px; color: #999; font-size: 16px; grid-column: 1 / -1; }

        .search-box { display: flex; gap: 8px; margin-bottom: 20px; }
        .search-input { flex: 1; padding: 10px 16px; border: 1px solid #d9d9d9; border-radius: 8px; font-size: 14px; outline: none; }
        .search-input:focus { border-color: #667eea; }
        .search-btn { padding: 10px 20px; background: #667eea; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 14px; }
        .search-btn:hover { background: #5a6fd6; }

        .cover-0 { background: linear-gradient(135deg,#e6f7ff,#bae7ff); }
        .cover-1 { background: linear-gradient(135deg,#fff7e6,#ffe7ba); }
        .cover-2 { background: linear-gradient(135deg,#f6ffed,#d9f7be); }
        .cover-3 { background: linear-gradient(135deg,#fff2f0,#ffccc7); }
        .cover-4 { background: linear-gradient(135deg,#f9f0ff,#efdbff); }
        .cover-5 { background: linear-gradient(135deg,#e6fffb,#b5f5ec); }
        .cover-6 { background: linear-gradient(135deg,#fffbe6,#fff1b8); }
        .cover-7 { background: linear-gradient(135deg,#fcffe6,#eaff8f); }

        .emoji-list { position: absolute; font-size: 48px; }
        .admin-hint { background: #fff7e6; border: 1px solid #ffd591; color: #d46b08; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-size: 13px; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>

    <main class="container">
        <div class="hero-banner">
            <div class="hero-title">📚 心理科普文库</div>
            <div class="hero-desc">精选壹心理、简单心理、高校心理等平台优质内容 · 助你了解自我、关爱心灵</div>
        </div>

        <form class="search-box" action="list.jsp" method="get">
            <input type="text" class="search-input" name="keyword" value="<%= keyword != null ? com.psychology.util.CommonUtil.escapeHtml(keyword) : "" %>" placeholder="🔍 搜索文章...">
            <input type="hidden" name="categoryId" value="<%= categoryId != null ? categoryId : "" %>">
            <button type="submit" class="search-btn">搜索</button>
            <% if (keyword != null && !keyword.isEmpty()) { %>
                <a href="list.jsp" class="search-btn" style="background:#999;text-decoration:none;">重置</a>
            <% } %>
        </form>

        <div class="category-tabs">
            <a href="list.jsp" class="cat-tab <%= categoryId == null ? "active" : "" %>">全部</a>
            <% for (Map<String, Object> cat : categories) { %>
                <a href="list.jsp?categoryId=<%= cat.get("id") %>" class="cat-tab <%= categoryId != null && categoryId.equals(cat.get("id")) ? "active" : "" %>"><%= cat.get("name") %></a>
            <% } %>
        </div>

        <% if (articles == null || articles.isEmpty()) { %>
            <% if (user != null && "ADMIN".equals(user.getRole())) { %>
                <div class="admin-hint">💡 当前暂无已发布文章。请进入「心理文章管理」→ 点击「拉取最新文章」获取内容，并将文章审核通过。</div>
            <% } %>
            <div class="empty-text">
                📭 <%= (keyword != null && !keyword.isEmpty()) ? "没有找到匹配的文章" : "暂无科普文章，敬请期待" %>
            </div>
        <% } else { %>
            <div class="article-grid" id="articleGrid">
                <% for (int i = 0; i < articles.size(); i++) {
                    Article a = articles.get(i);
                    String coverClass = "cover-" + (i % 8);
                    String emoji = emojis.get(i % emojis.size());
                    String title = a.getTitle() != null ? a.getTitle() : "未命名文章";
                    String summary = a.getSummary() != null ? a.getSummary() : "";
                    String category = a.getCategoryName() != null ? a.getCategoryName() : "心理科普";
                    String source = a.getSourceName() != null ? a.getSourceName() : "校内";
                    String sourceUrl = a.getSourceUrl() != null ? a.getSourceUrl() : "";
                    String time = a.getPublishedAt() != null ? new java.text.SimpleDateFormat("yyyy-MM-dd").format(a.getPublishedAt()) : "";
                    String catStyle = catColorMap.getOrDefault(category, "background:#f5f5f5;color:#666;");
                %>
                <div class="article-card" onclick="viewArticle(<%= a.getId() %>)">
                    <div class="article-cover <%= coverClass %>">
                        <span class="emoji-list"><%= emoji %></span>
                        <% if (source != null && !source.isEmpty()) { %>
                            <span class="source-badge">📌 <%= com.psychology.util.CommonUtil.escapeHtml(source) %></span>
                        <% } %>
                    </div>
                    <div class="article-body">
                        <span class="article-category" style="<%= catStyle %>"><%= category %></span>
                        <div class="article-title"><%= com.psychology.util.CommonUtil.escapeHtml(title) %></div>
                        <% if (!summary.isEmpty()) { %>
                            <div class="article-excerpt"><%= com.psychology.util.CommonUtil.escapeHtml(summary) %></div>
                        <% } %>
                        <div class="article-meta">
                            <span><%= time %></span>
                            <span class="read-more">阅读全文 →</span>
                        </div>
                    </div>
                </div>
                <% } %>
            </div>
        <% } %>
    </main>

    <script>
        function viewArticle(id) {
            window.open('detail.jsp?id=' + id, '_blank');
        }
    </script>
</body>
</html>
