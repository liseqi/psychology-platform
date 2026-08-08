<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>注册 - 心理健康管理系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; display: flex; align-items: center; justify-content: center;
        }
        .container {
            background: white; padding: 40px; border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3); width: 460px; max-width: 92vw;
        }
        .logo { text-align: center; margin-bottom: 24px; }
        .logo h1 { color: #667eea; font-size: 26px; }
        .form-group { margin-bottom: 16px; }
        .form-group label { display: block; margin-bottom: 6px; color: #333; font-weight: 500; }
        .form-group input, .form-group select {
            width: 100%; padding: 11px 14px; border: 2px solid #e0e0e0;
            border-radius: 8px; font-size: 15px;
        }
        .form-group input:focus, .form-group select:focus { outline: none; border-color: #667eea; }
        .row { display: flex; gap: 12px; }
        .row .form-group { flex: 1; }
        .btn {
            width: 100%; padding: 14px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600;
            cursor: pointer; margin-top: 8px;
        }
        .links { text-align: center; margin-top: 18px; font-size: 14px; }
        .links a { color: #667eea; text-decoration: none; }
        .error-msg {
            background: #fee; color: #c33; padding: 10px; border-radius: 6px;
            margin-bottom: 15px; font-size: 14px; display: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo"><h1>🧠 注册账号</h1></div>
        <div id="errorMsg" class="error-msg"></div>

        <form id="registerForm" onsubmit="handleRegister(event)">
            <div class="form-group">
                <label for="username">用户名</label>
                <input type="text" id="username" placeholder="请输入用户名" required>
            </div>
            <div class="form-group">
                <label for="realName">真实姓名</label>
                <input type="text" id="realName" placeholder="请输入真实姓名">
            </div>
            <div class="form-group">
                <label for="email">邮箱</label>
                <input type="email" id="email" placeholder="请输入邮箱">
            </div>
            <div class="row">
                <div class="form-group">
                    <label for="password">密码</label>
                    <input type="password" id="password" placeholder="6-20位" required>
                </div>
                <div class="form-group">
                    <label for="confirmPassword">确认密码</label>
                    <input type="password" id="confirmPassword" placeholder="再次输入密码" required>
                </div>
            </div>
            <div class="row">
                <div class="form-group">
                    <label for="studentId">学号</label>
                    <input type="text" id="studentId" placeholder="学号">
                </div>
                <div class="form-group">
                    <label for="gender">性别</label>
                    <select id="gender">
                        <option value="">未填写</option>
                        <option value="MALE">男</option>
                        <option value="FEMALE">女</option>
                    </select>
                </div>
            </div>
            <div class="form-group">
                <label for="department">院系</label>
                <input type="text" id="department" placeholder="院系">
            </div>
            <div class="row">
                <div class="form-group">
                    <label for="grade">年级</label>
                    <input type="text" id="grade" placeholder="如 2023级">
                </div>
                <div class="form-group">
                    <label for="className">班级</label>
                    <input type="text" id="className" placeholder="班级">
                </div>
            </div>
            <button type="submit" class="btn">注 册</button>
        </form>

        <div class="links"><a href="login.jsp">已有账号？返回登录</a></div>
    </div>

    <script>
        const ctx = '${pageContext.request.contextPath}';

        function showError(msg) {
            const d = document.getElementById('errorMsg');
            d.textContent = msg; d.style.display = 'block';
            setTimeout(() => d.style.display = 'none', 5000);
        }

        async function handleRegister(e) {
            e.preventDefault();
            const username = document.getElementById('username').value.trim();
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            if (!username || !password) { showError('请填写用户名和密码'); return; }
            if (password !== confirmPassword) { showError('两次输入的密码不一致'); return; }

            const params = new URLSearchParams();
            params.append('username', username);
            params.append('password', password);
            params.append('confirmPassword', confirmPassword);
            ['realName','email','studentId','gender','department','grade','className'].forEach(id => {
                const v = document.getElementById(id).value.trim();
                if (v) params.append(id, v);
            });

            try {
                const resp = await fetch(ctx + '/register', {
                    method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: params.toString()
                });
                const result = await resp.json();
                if (result.code === 200) {
                    window.location.href = ctx + (result.data || '/login.jsp');
                } else {
                    showError(result.message || '注册失败');
                }
            } catch (err) {
                showError('网络错误，请稍后重试');
            }
        }
    </script>
</body>
</html>
