<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>账号已禁用</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
            color: white; text-align: center;
        }
        .box {
            background: rgba(255,255,255,0.1);
            padding: 40px; border-radius: 16px; max-width: 90vw;
        }
        .title { font-size: 28px; font-weight: 700; margin-bottom: 16px; }
        .msg { font-size: 16px; opacity: 0.9; margin-bottom: 30px; }
        a.back-btn {
            display: inline-block; padding: 12px 30px;
            background: white; color: #667eea; text-decoration: none;
            border-radius: 8px; font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="box">
        <div class="title">账号已被禁用</div>
        <div class="msg">您的账号已被管理员禁用，请联系管理员解除限制。</div>
        <a class="back-btn" href="${pageContext.request.contextPath}/login.jsp">返回登录</a>
    </div>
</body>
</html>
