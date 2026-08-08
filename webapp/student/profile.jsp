<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"STUDENT".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>个人设置 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .profile-container { max-width: 800px; margin: 0 auto; }
        .page-header { margin: 30px 0 24px; }
        .page-header h1 { font-size: 28px; color: #333; margin-bottom: 8px; }

        .profile-card {
            background: white; border-radius: 16px; padding: 32px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.06);
            margin-bottom: 24px;
        }
        .profile-card h2 { font-size: 20px; color: #333; margin-bottom: 24px; padding-bottom: 12px; border-bottom: 1px solid #f0f0f0; }

        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; font-size: 13px; font-weight: 500; color: #555; margin-bottom: 6px; }
        .form-group input, .form-group select {
            width: 100%; padding: 10px 14px; border: 1px solid #e0e0e0;
            border-radius: 8px; font-size: 14px; color: #333; transition: border-color 0.2s;
            box-sizing: border-box; background: #fafafa;
        }
        .form-group input:focus, .form-group select:focus {
            outline: none; border-color: #667eea; background: white;
        }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

        .btn-save {
            width: 100%; padding: 12px; background: linear-gradient(135deg, #667eea, #764ba2);
            color: white; border: none; border-radius: 8px; font-size: 15px; font-weight: 500;
            cursor: pointer; transition: opacity 0.2s;
        }
        .btn-save:hover { opacity: 0.9; }

        .toast {
            position: fixed; top: 20px; left: 50%; transform: translateX(-50%);
            padding: 12px 28px; border-radius: 8px; font-size: 14px; font-weight: 500;
            z-index: 9999; transition: opacity 0.3s; opacity: 0; pointer-events: none;
        }
        .toast.show { opacity: 1; }
        .toast.success { background: #f6ffed; color: #52c41a; border: 1px solid #b7eb8f; }
        .toast.error { background: #fff2f0; color: #ff4d4f; border: 1px solid #ffccc7; }

        @media (max-width: 600px) {
            .form-row { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>

    <main class="container profile-container">
        <div class="page-header">
            <h1>个人设置</h1>
        </div>

        <div class="profile-card">
            <h2>基本信息</h2>
            <div class="form-row">
                <div class="form-group">
                    <label>用户名</label>
                    <input type="text" value="<%= user.getUsername() %>" readonly>
                </div>
                <div class="form-group">
                    <label>真实姓名</label>
                    <input type="text" id="realName" value="<%= user.getRealName() != null ? user.getRealName() : "" %>">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label>学号</label>
                    <input type="text" value="<%= user.getStudentId() != null ? user.getStudentId() : "" %>" readonly>
                </div>
                <div class="form-group">
                    <label>性别</label>
                    <select id="gender">
                        <option value="">请选择</option>
                        <option value="男" <%= "男".equals(user.getGender()) ? "selected" : "" %>>男</option>
                        <option value="女" <%= "女".equals(user.getGender()) ? "selected" : "" %>>女</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label>邮箱</label>
                    <input type="email" id="email" value="<%= user.getEmail() != null ? user.getEmail() : "" %>">
                </div>
                <div class="form-group">
                    <label>手机号</label>
                    <input type="tel" id="phone" value="<%= user.getPhone() != null ? user.getPhone() : "" %>">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label>院系</label>
                    <input type="text" value="<%= user.getDepartment() != null ? user.getDepartment() : "" %>" readonly>
                </div>
                <div class="form-group">
                    <label>班级</label>
                    <input type="text" value="<%= user.getClassName() != null ? user.getClassName() : "" %>" readonly>
                </div>
            </div>
            <button class="btn-save" onclick="saveProfile()">保存修改</button>
        </div>

        <div class="profile-card">
            <h2>修改密码</h2>
            <div class="form-group">
                <label>当前密码</label>
                <input type="password" id="oldPassword" placeholder="请输入当前密码">
            </div>
            <div class="form-group">
                <label>新密码</label>
                <input type="password" id="newPassword" placeholder="请输入新密码（至少6位）">
            </div>
            <div class="form-group">
                <label>确认新密码</label>
                <input type="password" id="confirmPassword" placeholder="请再次输入新密码">
            </div>
            <button class="btn-save" onclick="changePassword()">修改密码</button>
        </div>
    </main>

    <div class="toast" id="toast"></div>

    <script>
        function showToast(msg, type) {
            var t = document.getElementById('toast');
            t.textContent = msg;
            t.className = 'toast ' + type + ' show';
            setTimeout(function() { t.className = 'toast ' + type; }, 2000);
        }

        function saveProfile() {
            var data = {
                realName: document.getElementById('realName').value,
                gender: document.getElementById('gender').value,
                email: document.getElementById('email').value,
                phone: document.getElementById('phone').value
            };

            fetch('../user/updateProfile', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams(data).toString()
            })
            .then(res => res.json())
            .then(result => {
                if (result.success) {
                    showToast('个人资料更新成功', 'success');
                } else {
                    showToast(result.message || '更新失败', 'error');
                }
            })
            .catch(err => {
                showToast('网络错误，请稍后再试', 'error');
                console.error(err);
            });
        }

        function changePassword() {
            var oldPwd = document.getElementById('oldPassword').value;
            var newPwd = document.getElementById('newPassword').value;
            var confirmPwd = document.getElementById('confirmPassword').value;

            if (!oldPwd) { showToast('请输入当前密码', 'error'); return; }
            if (!newPwd) { showToast('请输入新密码', 'error'); return; }
            if (newPwd.length < 6) { showToast('新密码至少6位字符', 'error'); return; }
            if (newPwd !== confirmPwd) { showToast('两次输入的密码不一致', 'error'); return; }

            fetch('../user/changePassword', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({ oldPassword: oldPwd, newPassword: newPwd }).toString()
            })
            .then(res => res.json())
            .then(result => {
                if (result.success) {
                    showToast('密码修改成功', 'success');
                    document.getElementById('oldPassword').value = '';
                    document.getElementById('newPassword').value = '';
                    document.getElementById('confirmPassword').value = '';
                } else {
                    showToast(result.message || '密码修改失败', 'error');
                }
            })
            .catch(err => {
                showToast('网络错误，请稍后再试', 'error');
                console.error(err);
            });
        }
    </script>
</body>
</html>
