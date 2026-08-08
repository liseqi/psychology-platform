<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>500 - 服务器错误详情</title>
    <style>
        body { font-family: monospace; padding: 20px; background: #f5f5f5; }
        .error-box { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 1200px; margin: 20px auto; }
        pre { background: #fff3cd; padding: 15px; border-radius: 4px; overflow-x: auto; font-size: 12px; line-height: 1.5; white-space: pre-wrap; }
        h1 { color: #dc3545; }
        a { display: inline-block; margin-top: 15px; color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="error-box">
        <h1>🔴 500 - 服务器内部错误</h1>
        
        <% if (exception != null) { %>
            <h2>异常类型:</h2>
            <p><%= exception.getClass().getName() %></p>
            
            <h2>异常消息:</h2>
            <p style="color:red;font-weight:bold;"><%= exception.getMessage() %></p>
            
            <h2>堆栈跟踪:</h2>
            <pre><% 
                java.io.StringWriter sw = new java.io.StringWriter();
                java.io.PrintWriter pw = new java.io.PrintWriter(sw);
                exception.printStackTrace(pw);
                out.print(sw.toString());
            %></pre>
            
            <% if (exception.getCause() != null) { %>
                <h2>根本原因:</h2>
                <pre><%= exception.getCause().getClass().getName() %>: <%= exception.getCause().getMessage() %></pre>
            <% } %>
        <% } else { %>
            <p>没有捕获到异常对象</p>
        <% } %>
        
        <a href="${pageContext.request.contextPath}/login.jsp">← 返回登录页</a>
    </div>
</body>
</html>
