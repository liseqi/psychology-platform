package com.psychology.filter;

import com.psychology.entity.User;
import com.psychology.util.JsonUtil;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * 认证与权限过滤器 - 三类角色权限控制核心
 * 
 * 权限规则：
 * - 学生: 测评作答、个人报告、预约咨询、树洞、科普文章浏览
 * - 咨询师: 名下预警学生、预约排班管理、咨询记录填写、台账导出
 * - 管理员: 全部功能权限
 */
@WebFilter("/*")
public class AuthFilter implements Filter {
    
    // 不需要登录即可访问的路径
    private static final Set<String> PUBLIC_PATHS = new HashSet<>(Arrays.asList(
            "/login.jsp", "/login", "/register.jsp", "/register", "/forgot-password.jsp",
            "/forgot-password", "/logout", "/css/", "/js/", "/images/", "/fonts/", "/assets/",
            // 错误页面和静态页面
            "/index.jsp", "/error/", "/disabled.jsp"
    ));

    // 学生可访问的路径前缀
    private static final Set<String> STUDENT_PATHS = new HashSet<>(Arrays.asList(
            "/student/", "/assessment/", "/appointment/",
            "/chat/", "/article/", "/article-pages/", "/notification/",
            // 学生查看自己的咨询记录（只读）
            "/record/list", "/record/history"
    ));

    // 咨询师可访问的路径前缀
    private static final Set<String> COUNSELOR_PATHS = new HashSet<>(Arrays.asList(
            "/counselor/", "/appointment/counselor/",
            "/alert/counselor/", "/alert/statistics",
            "/alert/handle", "/alert/detail",   // 处理预警与查看详情
            "/consultation/",
            "/schedule/",   // 排班管理接口
            "/record/",     // 咨询记录接口
            "/download",    // 下载导出的文件
            "/init/"        // 数据初始化和诊断工具
    ));

    // 管理员可访问的路径前缀
    private static final Set<String> ADMIN_PATHS = new HashSet<>(Arrays.asList(
            "/admin/", "/scale/", "/alert/", "/user/", 
            "/statistics/", "/article/manage/"
    ));

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        
        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();
        
        // 静态资源和公开页面放行
        if (isPublicPath(path)) {
            chain.doFilter(request, response);
            return;
        }

        // 获取当前登录用户
        User user = (User) req.getSession().getAttribute("currentUser");
        
        if (user == null) {
            // 未登录处理
            if (isAjaxRequest(req)) {
                JsonUtil.writeJsonResponse(resp, JsonUtil.unauthorized("请先登录"));
            } else {
                resp.sendRedirect(req.getContextPath() + "/login.jsp");
            }
            return;
        }

        // 检查用户状态
        if (user.getStatus() == null || user.getStatus() != 1) {
            if (isAjaxRequest(req)) {
                JsonUtil.writeJsonResponse(resp, JsonUtil.forbidden("账号已被禁用，请联系管理员"));
            } else {
                resp.sendRedirect(req.getContextPath() + "/disabled.jsp");
            }
            return;
        }

        // 角色权限校验
        if (!hasPermission(user.getRole(), path)) {
            if (isAjaxRequest(req)) {
                JsonUtil.writeJsonResponse(resp, JsonUtil.forbidden("无权访问此功能"));
            } else {
                resp.sendError(403, "无权访问此功能");
            }
            return;
        }

        // 记录敏感数据访问日志
        if (isSensitiveDataAccess(path, method)) {
            logSensitiveAccess(user, req, path);
        }

        chain.doFilter(request, response);
    }

    /**
     * 判断是否为公开路径
     */
    private boolean isPublicPath(String path) {
        // 根目录首页
        if ("/".equals(path) || "".equals(path)) {
            return true;
        }
        
        // 静态资源（按扩展名判断）
        String lower = path.toLowerCase();
        if (lower.endsWith(".css") || lower.endsWith(".js") || lower.endsWith(".png") 
            || lower.endsWith(".jpg") || lower.endsWith(".gif") || lower.endsWith(".ico")
            || lower.endsWith(".woff") || lower.endsWith(".woff2") || lower.endsWith(".ttf")) {
            return true;
        }
        
        // 检查白名单路径
        for (String publicPath : PUBLIC_PATHS) {
            if (path.equals(publicPath) || path.startsWith(publicPath)) {
                return true;
            }
        }
        
        // 其他所有路径都需要登录验证
        return false;
    }

    /**
     * 判断是否有权限访问
     */
    private boolean hasPermission(String role, String path) {
        // 管理员拥有全部权限
        if ("ADMIN".equals(role)) {
            return true;
        }

        // 咨询师权限检查
        if ("COUNSELOR".equals(role)) {
            for (String counselorPath : COUNSELOR_PATHS) {
                if (path.startsWith(counselorPath)) {
                    return true;
                }
            }
            // 咨询师也可以访问部分公共功能
            for (String studentPath : STUDENT_PATHS) {
                if (path.startsWith(studentPath)) {
                    return true;
                }
            }
            return false;
        }

        // 学生权限检查
        if ("STUDENT".equals(role)) {
            for (String studentPath : STUDENT_PATHS) {
                if (path.startsWith(studentPath)) {
                    return true;
                }
            }
            return false;
        }

        return false;
    }

    /**
     * 判断是否为敏感数据操作（需要审计）
     */
    private boolean isSensitiveDataAccess(String path, String method) {
        String lowerPath = path.toLowerCase();
        return lowerPath.contains("/export") || lowerPath.contains("/view-record") 
                || lowerPath.contains("/consultation-record") || lowerPath.contains("/student-detail")
                || (lowerPath.contains("/alert") && "GET".equalsIgnoreCase(method));
    }

    /**
     * 记录敏感数据访问日志
     */
    private void logSensitiveAccess(User user, HttpServletRequest req, String path) {
        // 异步记录到数据库
        new Thread(() -> {
            try {
                com.psychology.dao.OperationLogDao dao = new com.psychology.dao.OperationLogDao();
                com.psychology.entity.OperationLog log = new com.psychology.entity.OperationLog();
                log.setOperatorId(user.getId());
                log.setOperatorName(user.getRealName());
                log.setOperatorRole(user.getRole());
                log.setOperationType("VIEW_SENSITIVE_DATA");
                
                // 根据路径判断目标类型
                if (path.contains("/export")) {
                    log.setTargetType("REPORT_EXPORT");
                } else if (path.contains("/assessment")) {
                    log.setTargetType("ASSESSMENT_RECORD");
                } else if (path.contains("/consultation")) {
                    log.setTargetType("CONSULTATION_RECORD");
                } else if (path.contains("/alert")) {
                    log.setTargetType("ALERT_RECORD");
                } else {
                    log.setTargetType("OTHER");
                }
                
                log.setTargetDescription("访问" + path);
                log.setIpAddress(com.psychology.util.CommonUtil.getClientIP(req));
                log.setUserAgent(req.getHeader("User-Agent"));
                dao.add(log);
            } catch (Exception e) {
                // 日志记录失败不影响主流程
            }
        }).start();
    }

    /**
     * 判断是否为AJAX请求
     */
    private boolean isAjaxRequest(HttpServletRequest request) {
        String accept = request.getHeader("Accept");
        String xRequestedWith = request.getHeader("X-Requested-With");
        return (accept != null && accept.contains("application/json")) 
                || "XMLHttpRequest".equals(xRequestedWith);
    }

    @Override
    public void destroy() {
    }
}
