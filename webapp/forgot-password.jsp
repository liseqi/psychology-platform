<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>找回密码 - 心理健康管理系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; display: flex; align-items: center; justify-content: center;
        }
        .container {
            background: white; padding: 40px; border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3); width: 420px; max-width: 90vw;
        }
        .logo { text-align: center; margin-bottom: 30px; }
        .logo h1 { color: #667eea; font-size: 26px; }
        .form-group { margin-bottom: 18px; }
        .form-group label { display: block; margin-bottom: 6px; color: #333; font-weight: 500; }
        .form-group input {
            width: 100%; padding: 12px 16px; border: 2px solid #e0e0e0;
            border-radius: 8px; font-size: 15px;
        }
        .form-group input:focus { outline: none; border-color: #667eea; }
        .btn {
            width: 100%; padding: 14px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600;
            cursor: pointer;
        }
        .links { text-align: center; margin-top: 20px; font-size: 14px; }
        .links a { color: #667eea; text-decoration: none; }
        .error-msg, .success-msg {
            padding: 10px; border-radius: 6px; margin-bottom: 15px; font-size: 14px; display: none;
        }
        .error-msg { background: #fee; color: #c33; }
        .success-msg { background: #efe; color: #3a3; }
        .hidden { display: none; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo"><h1>🧠 找回密码</h1></div>

        <div id="errorMsg" class="error-msg"></div>
        <div id="successMsg" class="success-msg"></div>

        <!-- 第一步：输入邮箱 -->
        <form id="emailForm" onsubmit="handleVerifyEmail(event)">
            <div class="form-group">
                <label for="email">注册邮箱</label>
                <input type="email" id="email" placeholder="请输入注册时使用的邮箱" required>
            </div>
            <button type="submit" class="btn">发送验证码</button>
        </form>

        <!-- 第二步：重置密码 -->
        <form id="resetForm" class="hidden" onsubmit="handleResetPassword(event)">
            <div class="form-group">
                <label for="verifyCode">验证码</label>
                <input type="text" id="verifyCode" placeholder="请输入邮箱中的验证码" required>
            </div>
            <div class="form-group">
                <label for="newPassword">新密码</label>
                <input type="password" id="newPassword" placeholder="6-20位密码" required>
            </div>
            <div class="form-group">
                <label for="confirmPassword">确认新密码</label>
                <input type="password" id="confirmPassword" placeholder="再次输入新密码" required>
            </div>
            <button type="submit" class="btn">重置密码</button>
        </form>

        <div class="links"><a href="login.jsp">返回登录</a></div>
    </div>

    <script>
        const ctx = '${pageContext.request.contextPath}';

        function showError(msg) {
            const d = document.getElementById('errorMsg');
            d.textContent = msg; d.style.display = 'block';
            setTimeout(() => d.style.display = 'none', 5000);
        }
        function showSuccess(msg) {
            const d = document.getElementById('successMsg');
            d.textContent = msg; d.style.display = 'block';
        }

        async function handleVerifyEmail(e) {
            e.preventDefault();
            const email = document.getElementById('email').value.trim();
            if (!email) { showError('请输入邮箱地址'); return; }
            try {
                const resp = await fetch(ctx + '/forgot-password', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: 'step=verify-email&email=' + encodeURIComponent(email)
                });
                const result = await resp.json();
                if (result.code === 200) {
                    showSuccess(result.message || '验证码已发送');
                    document.getElementById('emailForm').classList.add('hidden');
                    document.getElementById('resetForm').classList.remove('hidden');
                } else {
                    showError(result.message || '验证失败');
                }
            } catch (err) {
                showError('网络错误，请稍后重试');
            }
        }

        async function handleResetPassword(e) {
            e.preventDefault();
            const verifyCode = document.getElementById('verifyCode').value.trim();
            const newPassword = document.getElementById('newPassword').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            if (!verifyCode || !newPassword) { showError('请填写完整信息'); return; }
            if (newPassword !== confirmPassword) { showError('两次输入的密码不一致'); return; }
            try {
                const resp = await fetch(ctx + '/forgot-password', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: 'step=reset-password&verifyCode=' + encodeURIComponent(verifyCode)
                        + '&newPassword=' + encodeURIComponent(newPassword)
                        + '&confirmPassword=' + encodeURIComponent(confirmPassword)
                });
                const result = await resp.json();
                if (result.code === 200) {
                    showSuccess(result.message || '密码重置成功');
                    setTimeout(() => { window.location.href = ctx + '/login.jsp'; }, 1500);
                } else {
                    showError(result.message || '重置失败');
                }
            } catch (err) {
                showError('网络错误，请稍后重试');
            }
        }
    </script>
</body>
</html>
