package com.psychology.servlet;

import com.psychology.dao.ArticleDao;
import com.psychology.entity.Article;
import com.psychology.entity.User;
import com.psychology.service.ArticleFetchService;
import com.psychology.util.CommonUtil;
import com.psychology.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.*;

/**
 * 科普文章管理Servlet - 分类+留言+审核风控
 */
@WebServlet("/article/*")
public class ArticleServlet extends HttpServlet {

    private ArticleDao articleDao = new ArticleDao();
    private ArticleFetchService fetchService = new ArticleFetchService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();

        if ("/list".equals(pathInfo)) {
            handleList(req, resp);              // 文章列表（学生浏览）
        } else if ("/detail".equals(pathInfo)) {
            handleDetail(req, resp);             // 文章详情
        } else if ("/categories".equals(pathInfo)) {
            handleCategories(req, resp);          // 文章分类列表
        } else if ("/manage/list".equals(pathInfo)) {
            handleManageList(req, resp);          // 管理员文章管理列表
        } else if ("/manage/count".equals(pathInfo)) {
            handleManageCount(req, resp);         // 管理员统计各状态数量
        } else if ("/comments".equals(pathInfo)) {
            handleComments(req, resp);            // 文章评论列表
        } else if ("/sources".equals(pathInfo)) {
            handleSources(req, resp);             // 获取文章来源列表
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();

        if ("/create".equals(pathInfo)) {
            handleCreate(req, resp);              // 创建文章（管理员）
        } else if ("/comment".equals(pathInfo)) {
            handleComment(req, resp);             // 学生发表评论
        } else if ("/like".equals(pathInfo)) {
            handleLike(req, resp);                 // 点赞
        } else if ("/review".equals(pathInfo)) {
            handleReview(req, resp);               // 审核（管理员）
        } else if ("/fetch".equals(pathInfo)) {
            handleFetch(req, resp);                // 拉取外部文章
        } else if ("/batch-review".equals(pathInfo)) {
            handleBatchReview(req, resp);           // 批量审核
        } else if ("/delete".equals(pathInfo)) {
            handleDelete(req, resp);                // 删除文章
        }
    }

    /**
     * 学生浏览文章列表（只返回已发布的）
     */
    private void handleList(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String categoryStr = req.getParameter("categoryId");   // 按分类筛选
        String keyword = req.getParameter("keyword");          // 搜索关键词
        String pageStr = req.getParameter("page");
        String pageSizeStr = req.getParameter("pageSize");

        int page = 1;
        int pageSize = 10;
        try { page = Integer.parseInt(pageStr); } catch (Exception e) {}
        try { pageSize = Integer.parseInt(pageSizeStr); } catch (Exception e) {}

        Integer categoryId = null;
        if (categoryStr != null && !categoryStr.isEmpty()) {
            categoryId = Integer.parseInt(categoryStr);
        }

        List<Article> articles = articleDao.findPublished(page, pageSize, categoryId, keyword);
        JsonUtil.writeSuccess(resp, articles);
    }

    /**
     * 文章详情
     */
    private void handleDetail(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.isEmpty()) {
            JsonUtil.writeError(resp, "请指定文章");
            return;
        }

        Article article = articleDao.findById(Long.parseLong(idStr));
        if (article == null) {
            JsonUtil.writeError(resp, "文章不存在");
            return;
        }

        // 只有已发布的才能查看
        if (!"PUBLISHED".equals(article.getStatus())) {
            JsonUtil.writeError(resp, "文章尚未发布");
            return;
        }

        // 增加阅读量
        articleDao.incrementViewCount(article.getId());

        JsonUtil.writeSuccess(resp, article);
    }

    /**
     * 获取文章分类列表
     */
    private void handleCategories(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        java.util.List<Map<String, Object>> categories = articleDao.findAllCategories();
        JsonUtil.writeSuccess(resp, categories);
    }

    /**
     * 管理员文章管理列表（含所有状态）
     */
    private void handleManageList(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (!user.isAdmin()) {
            JsonUtil.writeForbidden(resp, "无权访问");
            return;
        }

        String status = req.getParameter("status");
        String source = req.getParameter("source");
        String pageStr = req.getParameter("page");

        int page = 1;
        try { page = Integer.parseInt(pageStr); } catch (Exception e) {}
        if (status == null) status = "ALL";

        List<Article> articles = articleDao.findForManage(page, 15, status, source);
        JsonUtil.writeSuccess(resp, articles);
    }

    /**
     * 管理员统计各状态文章数量
     */
    private void handleManageCount(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null || !user.isAdmin()) {
            JsonUtil.writeForbidden(resp, "无权访问");
            return;
        }

        Map<String, Integer> counts = articleDao.countByStatus();
        JsonUtil.writeSuccess(resp, counts);
    }

    /**
     * 创建文章（管理员用）
     */
    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (!user.isAdmin()) {
            JsonUtil.writeForbidden(resp, "只有管理员可以创建文章");
            return;
        }

        String title = req.getParameter("title");
        String categoryIdStr = req.getParameter("categoryId");
        String summary = req.getParameter("summary");
        String coverImage = req.getParameter("coverImage");
        String content = req.getParameter("content");
        String sourceUrl = req.getParameter("sourceUrl");
        String sourceName = req.getParameter("sourceName");
        String status = req.getParameter("status");

        if (CommonUtil.isEmpty(title) || CommonUtil.isEmpty(content)) {
            JsonUtil.writeParamError(resp, "标题和正文不能为空");
            return;
        }

        Article article = new Article();
        article.setTitle(CommonUtil.escapeHtml(title)); // XSS防护
        article.setCategoryId(categoryIdStr != null && !categoryIdStr.isEmpty()
            ? Integer.parseInt(categoryIdStr) : 1);
        article.setAuthorId(user.getId());
        article.setSummary(CommonUtil.escapeHtml(summary));
        article.setCoverImage(coverImage);
        article.setContent(CommonUtil.escapeHtml(content));
        article.setSourceUrl(sourceUrl);
        article.setSourceName(
            sourceName != null && !sourceName.isEmpty() ? sourceName : "自建");
        article.setStatus(status != null && !status.isEmpty() ? status : "PENDING_REVIEW");

        long articleId = articleDao.add(article);

        Map<String, Object> result = new HashMap<>();
        result.put("articleId", articleId);
        result.put("message", "文章已保存");
        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 学生发表评论
     */
    private void handleComment(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");

        String articleIdStr = req.getParameter("articleId");
        String parentIdStr = req.getParameter("parentId");  // 回复的父评论ID
        String content = req.getParameter("content");

        if (articleIdStr == null || CommonUtil.isEmpty(content)) {
            JsonUtil.writeParamError(resp, "参数不完整");
            return;
        }

        // 内容合规检查（简单敏感词过滤）
        if (!checkContentCompliance(content)) {
            JsonUtil.writeError(resp, "评论内容包含不当信息，请修改后重新提交");
            return;
        }

        boolean success = articleDao.addComment(Long.parseLong(articleIdStr), user.getId(),
            parentIdStr != null ? Long.parseLong(parentIdStr) : null,
            CommonUtil.escapeHtml(content));

        if (success) {
            JsonUtil.writeSuccess(resp, "评论发表成功，等待管理员审核后显示");
        } else {
            JsonUtil.writeError(resp, "评论失败");
        }
    }

    /**
     * 点赞
     */
    private void handleLike(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        String articleIdStr = req.getParameter("id");

        if (articleIdStr == null) {
            JsonUtil.writeParamError(resp, "请指定文章");
            return;
        }

        boolean success = articleDao.toggleLike(Long.parseLong(articleIdStr), user.getId());

        Map<String, Object> result = new HashMap<>();
        result.put("liked", success);
        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 管理员审核文章
     */
    private void handleReview(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (!user.isAdmin()) {
            JsonUtil.writeForbidden(resp, "无权操作");
            return;
        }

        String articleIdStr = req.getParameter("id");
        String action = req.getParameter("action"); // approve/reject
        String note = req.getParameter("note");

        if (articleIdStr == null || action == null) {
            JsonUtil.writeParamError(resp, "参数不完整");
            return;
        }

        boolean success = false;
        if ("approve".equals(action)) {
            success = articleDao.reviewArticle(Long.parseLong(articleIdStr),
                "PUBLISHED", user.getId(), note);
        } else if ("reject".equals(action)) {
            success = articleDao.reviewArticle(Long.parseLong(articleIdStr),
                "REJECTED", user.getId(), note);
        }

        if (success) {
            JsonUtil.writeSuccess(resp, "审核操作成功");
        } else {
            JsonUtil.writeError(resp, "操作失败");
        }
    }

    /**
     * 获取文章评论
     */
    private void handleComments(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String articleIdStr = req.getParameter("articleId");
        if (articleIdStr == null) {
            JsonUtil.writeParamError(resp, "请指定文章");
            return;
        }

        java.util.List<Map<String, Object>> comments = articleDao.findCommentsByArticle(Long.parseLong(articleIdStr));
        JsonUtil.writeSuccess(resp, comments);
    }

    /**
     * 拉取外部来源的最新文章
     */
    private void handleFetch(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null || !user.isAdmin()) {
            JsonUtil.writeForbidden(resp, "无权操作");
            return;
        }

        String source = req.getParameter("source");

        // 先检查数据库字段是否就绪
        if (!fetchService.checkSchema()) {
            Map<String, Object> errData = new HashMap<>();
            errData.put("details", new HashMap<String, Integer>());
            errData.put("total", 0);
            JsonUtil.writeError(resp, "数据库表字段未就绪：请先在 MySQL 中执行 sql/migration_add_article_source.sql，为 article 表添加 source_url 和 source_name 字段。", errData);
            return;
        }

        Map<String, Integer> results;
        if (source != null && !source.isEmpty() && !"ALL".equals(source)) {
            int count = fetchService.fetchFromSource(source);
            if (count == -1) {
                Map<String, Object> errData = new HashMap<>();
                errData.put("details", new HashMap<String, Integer>());
                errData.put("total", 0);
                JsonUtil.writeError(resp, "数据库表字段未就绪，请执行迁移脚本。", errData);
                return;
            }
            results = new LinkedHashMap<>();
            results.put(source, count);
        } else {
            results = fetchService.fetchAllSources();
        }

        int total = 0;
        for (int v : results.values()) total += v;

        Map<String, Object> result = new HashMap<>();
        result.put("details", results);
        result.put("total", total);
        result.put("message", total > 0 ? "成功拉取 " + total + " 篇新文章" : "没有发现新文章（可能已存在或无新内容）");

        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 批量审核文章
     */
    private void handleBatchReview(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (!user.isAdmin()) {
            JsonUtil.writeForbidden(resp, "无权操作");
            return;
        }

        String idsStr = req.getParameter("ids");  // 逗号分隔的ID列表
        String action = req.getParameter("action"); // approve/reject
        String note = req.getParameter("note");

        if (idsStr == null || idsStr.isEmpty() || action == null) {
            JsonUtil.writeParamError(resp, "参数不完整");
            return;
        }

        String[] idArray = idsStr.split(",");
        int success = 0;
        int fail = 0;
        String status = "approve".equals(action) ? "PUBLISHED" : "REJECTED";

        for (String idStr : idArray) {
            try {
                boolean ok = articleDao.reviewArticle(Long.parseLong(idStr.trim()),
                    status, user.getId(), note);
                if (ok) success++; else fail++;
            } catch (Exception e) {
                fail++;
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("fail", fail);
        result.put("message", "成功" + success + "篇, 失败" + fail + "篇");
        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 删除文章
     */
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (!user.isAdmin()) {
            JsonUtil.writeForbidden(resp, "无权操作");
            return;
        }

        String idStr = req.getParameter("id");
        if (idStr == null) {
            JsonUtil.writeParamError(resp, "请指定文章");
            return;
        }

        // 直接使用拒绝状态来"软删除"
        boolean success = articleDao.reviewArticle(Long.parseLong(idStr),
            "REJECTED", user.getId(), "管理员删除");
        if (success) {
            JsonUtil.writeSuccess(resp, "删除成功");
        } else {
            JsonUtil.writeError(resp, "删除失败");
        }
    }

    /**
     * 获取文章来源列表（含统计）
     */
    private void handleSources(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (!user.isAdmin()) {
            JsonUtil.writeForbidden(resp, "无权访问");
            return;
        }

        java.util.List<Map<String, Object>> sources = new ArrayList<>();
        for (String[] src : ArticleFetchService.SOURCES) {
            Map<String, Object> item = new HashMap<>();
            item.put("name", src[0]);
            item.put("url", src[1]);
            item.put("tags", src[2]);
            sources.add(item);
        }
        JsonUtil.writeSuccess(resp, sources);
    }

    /**
     * 内容合规性简单检查（敏感词过滤）
     * 生产环境应使用更完善的NLP方案
     */
    private boolean checkContentCompliance(String content) {
        // 简单的关键词过滤（实际应使用完整的敏感词库）
        String[] sensitiveWords = {"违禁词1", "违禁词2"}; // 示例
        String lowerContent = content.toLowerCase();
        for (String word : sensitiveWords) {
            if (lowerContent.contains(word.toLowerCase())) {
                return false;
            }
        }
        return true;
    }
}
