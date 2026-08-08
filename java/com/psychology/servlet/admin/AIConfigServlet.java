package com.psychology.servlet.admin;

import com.psychology.ai.*;
import com.psychology.entity.User;
import com.psychology.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.*;

/**
 * AI配置管理Servlet - 管理员后台动态修改AI参数
 * 
 * 功能列表：
 * 1. 查看/编辑AI配置（Provider、API Key、参数等）
 * 2. RAG知识库管理（构建/重建/统计）
 * 3. 长期记忆管理（查看/删除）
 * 4. 向量数据库状态监控
 * 5. 配置变更审计日志
 *
 * 权限要求：仅管理员可访问
 */
@WebServlet("/admin/ai-config/*")
public class AIConfigServlet extends HttpServlet {

    private AIConfigManager configManager;
    private KnowledgeBaseService knowledgeBaseService;
    private MemoryService memoryService;

    @Override
    public void init() throws ServletException {
        super.init();
        this.configManager = AIConfigManager.getInstance();
        this.knowledgeBaseService = KnowledgeBaseService.getInstance();
        this.memoryService = MemoryService.getInstance();
        
        System.out.println("✅ AIConfigServlet初始化完成");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        // 权限检查：仅允许管理员访问
        User currentUser = (User) req.getSession().getAttribute("currentUser");
        if (currentUser == null || !"ADMIN".equals(currentUser.getRole())) {
            resp.sendError(403, "权限不足，仅限管理员访问");
            return;
        }

        String pathInfo = req.getPathInfo();
        if (pathInfo == null) pathInfo = "";

        if (pathInfo.endsWith("/page")) {
            // 返回配置页面
            req.getRequestDispatcher("/admin/ai-config.jsp").forward(req, resp);
            
        } else if (pathInfo.endsWith("/list")) {
            // 获取配置列表（分页）
            handleGetConfigList(req, resp);
            
        } else if (pathInfo.endsWith("/kb-stats")) {
            // 知识库统计
            handleGetKBStats(req, resp);
            
        } else if (pathInfo.endsWith("/audit-log")) {
            // 审计日志
            handleGetAuditLog(req, resp);
            
        } else if (pathInfo.endsWith("/test-connection")) {
            // 测试AI连接
            handleTestConnection(req, resp);
            
        } else if (pathInfo.endsWith("/test-rag")) {
            // 测试RAG功能
            handleTestRAG(req, resp);
            
        } else if (pathInfo.endsWith("/memory-list")) {
            // 查看用户记忆列表
            handleGetMemoryList(req, resp);
            
        } else {
            // 默认返回页面
            req.getRequestDispatcher("/admin/ai-config.jsp").forward(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        // 权限检查
        User currentUser = (User) req.getSession().getAttribute("currentUser");
        if (currentUser == null || !"ADMIN".equals(currentUser.getRole())) {
            JsonUtil.writeError(resp, "权限不足", null);
            return;
        }

        String pathInfo = req.getPathInfo();
        if (pathInfo == null) pathInfo = "";

        if (pathInfo.endsWith("/update")) {
            // 更新单个配置
            handleUpdateConfig(req, resp, currentUser.getId());
            
        } else if (pathInfo.endsWith("/batch-update")) {
            // 批量更新配置
            handleBatchUpdate(req, resp, currentUser.getId());
            
        } else if (pathInfo.endsWith("/reset")) {
            // 重置为默认值
            handleResetConfig(req, resp, currentUser.getId());
            
        } else if (pathInfo.endsWith("/build-kb")) {
            // 构建知识库
            handleBuildKnowledgeBase(req, resp);
            
        } else if (pathInfo.endsWith("/delete-memory")) {
            // 删除记忆
            handleDeleteMemory(req, resp);
            
        } else {
            JsonUtil.writeParamError(resp, "未知的操作: " + pathInfo);
        }
    }

    // =====================================================
    // 配置CRUD操作
    // =====================================================

    /**
     * 获取配置列表（分页+搜索）
     */
    private void handleGetConfigList(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int page = parseIntParam(req, "page", 1);
        int pageSize = parseIntParam(req, "pageSize", 20);
        String keyword = req.getParameter("keyword");

        List<AIConfigManager.ConfigEntry> configs = configManager.getAllConfigs(page, pageSize, keyword);
        int total = configManager.getTotalConfigs(keyword);

        Map<String, Object> result = new HashMap<>();
        result.put("list", configs);
        result.put("total", total);
        result.put("page", page);
        result.put("pageSize", pageSize);

        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 更新单个配置
     */
    private void handleUpdateConfig(HttpServletRequest req, HttpServletResponse resp, int adminUserId)
            throws IOException {
        String key = req.getParameter("key");
        String value = req.getParameter("value");
        String remark = req.getParameter("remark");

        if (key == null || key.trim().isEmpty() || value == null) {
            JsonUtil.writeParamError(resp, "请提供完整的key和value");
            return;
        }

        boolean success = configManager.setConfig(key.trim(), value, adminUserId, remark);

        if (success) {
            Map<String, Object> result = new HashMap<>();
            result.put("key", key);
            result.put("newValue", value);
            result.put("message", "配置已更新");
            JsonUtil.writeSuccess(resp, result);
        } else {
            JsonUtil.writeError(resp, "配置更新失败", null);
        }
    }

    /**
     * 批量更新配置
     */
    private void handleBatchUpdate(HttpServletRequest req, HttpServletResponse resp, int adminUserId)
            throws IOException {
        // 从请求体读取JSON格式的配置Map
        Map<String, String> configMap = new HashMap<>();
        
        // 遍历所有以"config."开头的参数
        Enumeration<String> params = req.getParameterNames();
        while (params.hasMoreElements()) {
            String paramName = params.nextElement();
            if (paramName.startsWith("config.")) {
                String configKey = paramName.substring(7);  // 去掉"config."前缀
                configMap.put(configKey, req.getParameter(paramName));
            }
        }

        if (configMap.isEmpty()) {
            JsonUtil.writeParamError(resp, "没有要更新的配置项");
            return;
        }

        Map<String, Boolean> results = configManager.batchUpdateConfigs(configMap, adminUserId);

        int successCount = 0;
        for (boolean success : results.values()) {
            if (success) successCount++;
        }

        Map<String, Object> resultData = new HashMap<>();
        resultData.put("updated", successCount);
        resultData.put("total", configMap.size());
        resultData.put("results", results);
        resultData.put("message", "批量更新完成");

        JsonUtil.writeSuccess(resp, resultData);
    }

    /**
     * 重置为默认值
     */
    private void handleResetConfig(HttpServletRequest req, HttpServletResponse resp, int adminUserId)
            throws IOException {
        String key = req.getParameter("key");

        if (key == null || key.trim().isEmpty()) {
            JsonUtil.writeParamError(resp, "请提供配置键");
            return;
        }

        boolean success = configManager.resetToDefault(key.trim(), adminUserId);

        if (success) {
            JsonUtil.writeSuccess(resp, "配置已重置为默认值");
        } else {
            JsonUtil.writeError(resp, "重置失败（可能不存在默认值）", null);
        }
    }

    // =====================================================
    // 知识库管理
    // =====================================================

    /**
     * 获取知识库统计信息
     */
    private void handleGetKBStats(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Map<String, Object> stats = knowledgeBaseService.getKnowledgeBaseStats();
        JsonUtil.writeSuccess(resp, stats);
    }

    /**
     * 构建/重建知识库
     */
    private void handleBuildKnowledgeBase(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        try {
            // 异步执行（可能耗时较长）
            new Thread(() -> {
                try {
                    Map<String, Object> buildResult = knowledgeBaseService.buildKnowledgeBase();
                    System.out.println("[KB] 知识库构建完成: " + buildResult);
                } catch (Exception e) {
                    System.err.println("[KB] 知识库构建失败: " + e.getMessage());
                    e.printStackTrace();
                }
            }).start();

            JsonUtil.writeSuccess(resp, "知识库构建任务已启动（异步执行），请稍后查看统计信息");

        } catch (Exception e) {
            JsonUtil.writeError(resp, "启动构建任务失败: " + e.getMessage(), e);
        }
    }

    // =====================================================
    // 测试功能
    // =====================================================

    /**
     * 测试AI连接
     */
    private void handleTestConnection(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        AIService aiService = AIService.getInstance();
        boolean connected = aiService.testConnection();

        EmbeddingService embeddingService = EmbeddingService.getInstance();
        boolean embeddingOk = embeddingService.testConnection();

        Map<String, Object> result = new HashMap<>();
        result.put("aiConnected", connected);
        result.put("embeddingOk", embeddingOk);
        result.put("provider", aiService.getCurrentProvider());
        result.put("embeddingModel", embeddingService.getProvider() + "/" + embeddingService.getModel());

        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 测试RAG功能
     */
    private void handleTestRAG(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String testQuery = req.getParameter("query");
        if (testQuery == null || testQuery.trim().isEmpty()) {
            testQuery = "如何缓解考试焦虑";
        }

        long startTime = System.currentTimeMillis();
        String context = knowledgeBaseService.retrieveRelevantContext(testQuery);
        long duration = System.currentTimeMillis() - startTime;

        Map<String, Object> result = new HashMap<>();
        result.put("testQuery", testQuery);
        result.put("hasResult", context != null && !context.isEmpty());
        result.put("contextLength", context != null ? context.length() : 0);
        result.put("contextPreview", context != null && !context.isEmpty() ? 
            context.substring(0, Math.min(200, context.length())) : "");
        result.put("durationMs", duration);
        result.put("ragEnabled", true);  // TODO: 从配置读取

        JsonUtil.writeSuccess(resp, result);
    }

    // =====================================================
    // 记忆管理
    // =====================================================

    /**
     * 获取审计日志
     */
    private void handleGetAuditLog(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int page = parseIntParam(req, "page", 1);
        int pageSize = parseIntParam(req, "pageSize", 20);

        List<AIConfigManager.AuditLogEntry> logs = configManager.getAuditLogs(page, pageSize);

        Map<String, Object> result = new HashMap<>();
        result.put("logs", logs);
        result.put("page", page);
        result.put("pageSize", pageSize);

        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 查看用户的记忆列表
     */
    private void handleGetMemoryList(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int userId = parseIntParam(req, "userId", 0);
        int page = parseIntParam(req, "page", 1);
        int pageSize = parseIntParam(req, "pageSize", 20);

        if (userId <= 0) {
            JsonUtil.writeParamError(resp, "请提供用户ID");
            return;
        }

        List<MemoryService.MemoryRecord> memories = memoryService.getUserMemories(userId, page, pageSize);
        Map<String, Object> userStats = memoryService.getUserMemoryStats(userId);

        Map<String, Object> result = new HashMap<>();
        result.put("memories", memories);
        result.put("stats", userStats);
        result.put("page", page);

        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 删除某条记忆
     */
    private void handleDeleteMemory(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        long memoryId = Long.parseLong(req.getParameter("memoryId"));

        boolean success = memoryService.deactivateMemory(memoryId);

        if (success) {
            JsonUtil.writeSuccess(resp, "记忆已禁用");
        } else {
            JsonUtil.writeError(resp, "操作失败", null);
        }
    }

    // =====================================================
    // 工具方法
    // =====================================================

    private int parseIntParam(HttpServletRequest req, String name, int defaultValue) {
        String param = req.getParameter(name);
        if (param != null && !param.trim().isEmpty()) {
            try {
                return Integer.parseInt(param.trim());
            } catch (NumberFormatException ignored) {}
        }
        return defaultValue;
    }
}
