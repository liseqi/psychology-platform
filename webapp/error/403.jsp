<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>403 - 禁止访问</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
            color: white; text-align: center;
        }
        .error-code { font-size: 96px; font-weight: 800; margin-bottom: 10px; }
        .error-msg { font-size: 20px; margin-bottom: 30px; opacity: 0.9; }
        a.back-btn {
            display: inline-block; padding: 12px 30px;
            background: white; color: #667eea; text-decoration: none;
            border-radius: 8px; font-weight: 600;
        }
    </style>
</head>
<body>
    <div>
        <div class="error-code">403</div>
        <div class="error-msg">抱歉，您没有权限访问此页面</div>
        <a class="back-btn" href="${pageContext.request.contextPath}/login.jsp">返回登录</a>
    </div>
</body>
</html>
