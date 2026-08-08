<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"ADMIN".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>账号管理 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .filter-bar { background: white; padding: 16px 24px; border-radius: 10px; margin-bottom: 20px; display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
        .filter-bar select, .filter-bar input { padding: 8px 12px; border: 1px solid #ddd; border-radius: 6px; }
        .user-table { width: 100%; background: white; border-radius: 10px; overflow: hidden; border-collapse: collapse; }
        .user-table th { background: #f8f9fa; padding: 14px 16px; text-align: left; color: #333; font-weight: 600; }
        .user-table td { padding: 14px 16px; border-top: 1px solid #eee; color: #555; }
        .user-table tr:hover { background: #fafafa; }
        .role-badge { padding: 4px 12px; border-radius: 12px; font-size: 12px; }
        .role-admin { background: #e6f7ff; color: #1890ff; }
        .role-counselor { background: #f6ffed; color: #52c41a; }
        .role-student { background: #fff7e6; color: #d48806; }
        .status-active { color: #52c41a; }
        .status-disabled { color: #ff4d4f; }
        .action-link { color: #667eea; cursor: pointer; text-decoration: none; margin-right: 12px; }
        .action-link:hover { text-decoration: underline; }
        .action-link.danger { color: #ff4d4f; }
        .pagination { display: flex; justify-content: center; gap: 8px; margin-top: 20px; }
        .page-btn { padding: 8px 16px; border: 1px solid #ddd; border-radius: 6px; cursor: pointer; background: white; }
        .page-btn.active, .page-btn:hover:not(:disabled) { background: #667eea; color: white; border-color: #667eea; }
        .page-btn:disabled { opacity: 0.45; cursor: not-allowed; }
        .loading-overlay { position: absolute; top:0;left:0;right:0;bottom:0;background:rgba(255,255,255,0.8);display:flex;justify-content:center;align-items:center;z-index:10;border-radius:10px; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>👥 账号管理</h1>
            <p>管理系统用户账号 · 分配角色权限</p>
        </header>

        <div class="filter-bar">
            <select id="roleFilter" onchange="searchUsers()">
                <option value="">全部角色</option>
                <option value="ADMIN">管理员</option>
                <option value="COUNSELOR">咨询师</option>
                <option value="STUDENT">学生</option>
            </select>
            <select id="statusFilter" onchange="searchUsers()">
                <option value="">全部状态</option>
                <option value="1">正常</option>
                <option value="0">禁用</option>
            </select>
            <input type="text" id="searchInput" placeholder="搜索用户名/姓名/学号..." style="flex:1;" onkeydown="if(event.key==='Enter')searchUsers()">
            <button onclick="searchUsers()" style="padding:8px 20px;background:#667eea;color:white;border:none;border-radius:6px;cursor:pointer;">🔍 搜索</button>
            <button onclick="showAddUser()" style="padding:8px 20px;background:#52c41a;color:white;border:none;border-radius:6px;cursor:pointer;">+ 添加用户</button>
        </div>

        <table class="user-table" style="position:relative;">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>用户名</th>
                    <th>姓名</th>
                    <th>角色</th>
                    <th>部门/学号</th>
                    <th>最后登录</th>
                    <th>状态</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody id="userTableBody">
                <tr><td colspan="8" style="text-align:center;padding:40px;color:#999;">正在加载...</td></tr>
            </tbody>
        </table>

        <div class="pagination" id="pagination"></div>

        <!-- 添加用户模态框 -->
        <div id="addUserModal" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:1000;justify-content:center;align-items:center;" onclick="closeModal(event)">
            <div style="background:white;border-radius:12px;padding:30px;width:450px;" onclick="event.stopPropagation()">
                <h3 style="margin-bottom:20px;color:#333">👤 添加新用户</h3>
                <div class="form-group"><label>用户名 *</label><input type="text" id="addUsername" placeholder="输入用户名" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"></div>
                <div class="form-group"><label>真实姓名 *</label><input type="text" id="addRealName" placeholder="输入真实姓名" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"></div>
                <div class="form-group"><label>角色 *</label><select id="addRole" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"><option value="">选择角色</option><option value="STUDENT">学生</option><option value="COUNSELOR">咨询师</option><option value="ADMIN">管理员</option></select></div>
                <div class="form-group"><label>邮箱</label><input type="email" id="addEmail" placeholder="输入邮箱（选填）" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"></div>
                <div class="form-group"><label>部门/学院</label><input type="text" id="addDept" placeholder="输入部门（选填）" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"></div>
                <div class="form-group"><label>初始密码</label><input type="password" value="123456" id="addPassword" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"><small style="color:#999">默认密码：123456</small></div>
                <div style="display:flex;gap:12px;justify-content:flex-end;margin-top:20px;">
                    <button onclick="closeModal()" style="padding:10px 24px;border:1px solid #ddd;background:white;border-radius:6px;cursor:pointer;">取消</button>
                    <button onclick="saveUser()" id="saveBtn" style="padding:10px 24px;background:#52c41a;color:white;border:none;border-radius:6px;cursor:pointer;">✓ 确认添加</button>
                </div>
            </div>
        </div>

        <!-- 编辑用户模态框 -->
        <div id="editUserModal" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:1000;justify-content:center;align-items:center;" onclick="closeEditModal(event)">
            <div style="background:white;border-radius:12px;padding:30px;width:450px;" onclick="event.stopPropagation()">
                <h3 style="margin-bottom:20px;color:#333">✏️ 编辑用户</h3>
                <input type="hidden" id="editUserId">
                <div class="form-group"><label>用户名</label><input type="text" id="editUsername" readonly style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;background:#f5f5f5;"></div>
                <div class="form-group"><label>真实姓名 *</label><input type="text" id="editRealName" placeholder="输入真实姓名" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"></div>
                <div class="form-group"><label>角色 *</label><select id="editRole" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"><option value="STUDENT">学生</option><option value="COUNSELOR">咨询师</option><option value="ADMIN">管理员</option></select></div>
                <div class="form-group"><label>邮箱</label><input type="email" id="editEmail" placeholder="输入邮箱" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"></div>
                <div class="form-group"><label>部门/学院</label><input type="text" id="editDept" placeholder="输入部门" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:6px;"></div>
                <div style="display:flex;gap:12px;justify-content:flex-end;margin-top:20px;">
                    <button onclick="closeEditModal()" style="padding:10px 24px;border:1px solid #ddd;background:white;border-radius:6px;cursor:pointer;">取消</button>
                    <button onclick="updateUser()" style="padding:10px 24px;background:#667eea;color:white;border:none;border-radius:6px;cursor:pointer;">💾 保存修改</button>
                </div>
            </div>
        </div>
    </main>

    <script>
    var CTX = "<%=ctx%>";
    var currentPage = 1;
    var pageSize = 10;

    window.onload = function() {
        loadUsers();
    };

    function loadUsers() {
        var tbody = document.getElementById('userTableBody');
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;"><div class="loading-spinner"></div> 正在加载...</td></tr>';

        var role = document.getElementById('roleFilter').value;
        var status = document.getElementById('statusFilter').value;
        var keyword = document.getElementById('searchInput').value;

        // 构建带查询参数的 URL
        var url = CTX + '/test-user-list.jsp?role=' + encodeURIComponent(role) +
                  '&status=' + encodeURIComponent(status) +
                  '&keyword=' + encodeURIComponent(keyword) +
                  '&page=' + currentPage +
                  '&pageSize=' + pageSize;
        
        fetch(url).then(function(r){ return r.json(); }).then(function(data){
            console.log('API返回:', data);
            renderUserTable(data);
        }).catch(function(err){
            console.error('加载错误:', err);
            tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#ff4d4f;">加载失败: ' + err.message + '</td></tr>';
        });
    }

    function renderUserTable(res) {
        var tbody = document.getElementById('userTableBody');
        var pg = document.getElementById('pagination');

        if (!res || res.code !== 200 || !res.data) {
            tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#999;">暂无数据</td></tr>';
            pg.innerHTML = '';
            return;
        }

        var d = res.data;
        var list = d.list || [];
        var total = d.total || 0;
        var tp = d.totalPages || 1;

        if (list.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#999;">暂无符合条件的用户</td></tr>';
            pg.innerHTML = '';
            return;
        }

        var html = '';
        for (var i = 0; i < list.length; i++) {
            var u = list[i];
            var roleClass = u.role === 'ADMIN' ? 'admin' : (u.role === 'COUNSELOR' ? 'counselor' : 'student');
            var roleName = u.role === 'ADMIN' ? '管理员' : (u.role === 'COUNSELOR' ? '咨询师' : '学生');
            var isActive = u.status === 1;
            var deptInfo = '';
            if (u.department) deptInfo += u.department;
            if (u.studentId) deptInfo += (deptInfo ? ' / ' : '') + u.studentId;
            if (!deptInfo) deptInfo = '-';
            
            var lastLogin = u.lastLoginTime ? formatTime(u.lastLoginTime) : '-';

            html += '<tr>' +
                '<td>' + u.id + '</td>' +
                '<td>' + esc(u.username) + '</td>' +
                '<td>' + esc(u.realName || '-') + '</td>' +
                '<td><span class="role-badge role-' + roleClass + '">' + roleName + '</span></td>' +
                '<td>' + esc(deptInfo) + '</td>' +
                '<td>' + lastLogin + '</td>' +
                '<td class="' + (isActive ? 'status-active' : 'status-disabled') + '">' + (isActive ? '&#10003; 正常' : '&#10007; 禁用') + '</td>' +
                '<td>' +
                    '<a class="action-link" onclick="editUser(' + u.id + ',\'' + esc(u.username) + '\')">编辑</a>' +
                    '<a class="action-link ' + (isActive ? 'danger' : '" style="color:#52c41a') + '" onclick="toggleStatus(' + u.id + ',' + isActive + ')">' + (isActive ? '禁用' : '启用') + '</a>' +
                '</td></tr>';
        }
        tbody.innerHTML = html;

        // 分页
        if (tp > 1) {
            var p = '<button class="page-btn" onclick="goPage(1)"' + (currentPage <= 1 ? ' disabled' : '') + '>首页</button>';
            p += '<button class="page-btn" onclick="goPage(' + (currentPage - 1) + ')"' + (currentPage <= 1 ? ' disabled' : '') + '>&lt;</button>';
            for (var j = Math.max(1, currentPage - 2); j <= Math.min(tp, currentPage + 2); j++) {
                p += '<button class="page-btn' + (j === currentPage ? ' active' : '') + '" onclick="goPage(' + j + ')">' + j + '</button>';
            }
            p += '<button class="page-btn" onclick="goPage(' + (currentPage + 1) + ')"' + (currentPage >= tp ? ' disabled' : '') + '>&gt;</button>';
            p += '<button class="page-btn" onclick="goPage(' + tp + ')"' + (currentPage >= tp ? ' disabled' : '') + '>末页</button>';
            p += '<span style="margin-left:12px;color:#999;font-size:13px;">共 ' + total + ' 条</span>';
            pg.innerHTML = p;
        } else {
            pg.innerHTML = '';
        }
    }

    function searchUsers() {
        currentPage = 1;
        loadUsers();
    }

    function goPage(p) {
        currentPage = p;
        loadUsers();
        document.querySelector('.user-table').scrollIntoView({behavior:'smooth'});
    }

    function showAddUser() {
        document.getElementById('addUserModal').style.display = 'flex';
        // 清空表单
        document.getElementById('addUsername').value = '';
        document.getElementById('addRealName').value = '';
        document.getElementById('addRole').value = '';
        document.getElementById('addEmail').value = '';
        document.getElementById('addDept').value = '';
        document.getElementById('addPassword').value = '123456';
    }
    
    function closeModal(e) {
        if(!e || e.target === e.currentTarget) {
            document.getElementById('addUserModal').style.display = 'none';
        }
    }

    function saveUser() {
        var username = document.getElementById('addUsername').value.trim();
        var realname = document.getElementById('addRealName').value.trim();
        var role = document.getElementById('addRole').value;
        
        if(!username || !realname || !role) {
            alert('请填写必填项：用户名、姓名、角色！');
            return;
        }

        var btn = document.getElementById('saveBtn');
        btn.disabled = true;
        btn.textContent = '提交中...';

        var form = new FormData();
        form.append('username', username);
        form.append('realName', realname);
        form.append('role', role);
        form.append('email', document.getElementById('addEmail').value);
        form.append('department', document.getElementById('addDept').value);
        form.append('password', document.getElementById('addPassword').value);

        form.append('action', 'add');

        fetch(CTX + '/test-user-list.jsp', {method:'POST', body:form}).then(function(r){return r.json();}).then(function(d){
            btn.disabled = false;
            btn.textContent = '✓ 确认添加';
            if(d.code === 200) {
                alert('✅ 用户创建成功！\n\n用户名：' + username + '\n默认密码：123456');
                closeModal();
                loadUsers();
            } else {
                alert('❌ 创建失败：' + (d.message || '未知错误'));
            }
        }).catch(function(err){
            btn.disabled = false;
            btn.textContent = '✓ 确认添加';
            alert('网络错误，请重试');
        });
    }

    function editUser(id, username) {
        fetch(CTX + '/test-user-list.jsp?action=detail&id=' + id).then(function(r){return r.json();}).then(function(d){
            if(d.code === 200 && d.data) {
                var u = d.data;
                document.getElementById('editUserId').value = u.id;
                document.getElementById('editUsername').value = u.username;
                document.getElementById('editRealName').value = u.realName || '';
                document.getElementById('editRole').value = u.role;
                document.getElementById('editEmail').value = u.email || '';
                document.getElementById('editDept').value = u.department || '';
                document.getElementById('editUserModal').style.display = 'flex';
            } else {
                alert('❌ 获取用户信息失败: ' + (d.message || ''));
            }
        }).catch(function(e){console.error(e); alert('网络错误: ' + e.message);});
    }

    function closeEditModal(e) {
        if(!e || e.target === e.currentTarget) {
            document.getElementById('editUserModal').style.display = 'none';
        }
    }

    function updateUser() {
        var id = document.getElementById('editUserId').value;
        var form = new FormData();
        form.append('action', 'update');
        form.append('id', id);
        form.append('realName', document.getElementById('editRealName').value.trim());
        form.append('role', document.getElementById('editRole').value);
        form.append('email', document.getElementById('editEmail').value);
        form.append('department', document.getElementById('editDept').value);

        fetch(CTX + '/test-user-list.jsp', {method:'POST', body:form}).then(function(r){return r.json();}).then(function(d){
            if(d.code === 200) {
                alert('✅ 更新成功！');
                closeEditModal();
                loadUsers();
            } else {
                alert('❌ 更新失败：' + (d.message || '未知错误'));
            }
        }).catch(function(e){alert('网络错误: ' + e.message);});
    }

    function toggleStatus(id, isCurrentlyActive) {
        var action = isCurrentlyActive ? '禁用' : '启用';
        if(!confirm('确认要【' + action + '】该账号吗？(ID:' + id + ')')) return;

        var newStatus = isCurrentlyActive ? 0 : 1;
        
        // 使用 test-user-list.jsp（已确认可访问）
        var url = CTX + '/test-user-list.jsp?action=toggleStatus&id=' + id + '&status=' + newStatus;
        
        fetch(url, {method: 'POST'}).then(function(r){return r.json();}).then(function(d){
            console.log('toggleStatus 响应:', d);
            if(d.code === 200) {
                alert('✅ 已' + action);
                loadUsers();
            } else {
                alert('❌ 操作失败：' + (d.message || '未知错误'));
            }
        }).catch(function(e){console.error(e); alert('网络错误: ' + e.message);});
    }

    function formatTime(ts) {
        try {
            if(typeof ts === "string") return ts.substring(0, 16).replace('T',' ');
            if(ts && ts.year) return new Date(ts.year,ts.month-1,ts.dayOfMonth,ts.hourOfDay,ts.minute).toLocaleString("zh-CN",{year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'});
            if(ts instanceof Date) return ts.toLocaleString("zh-CN",{year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'});
            return String(ts);
        } catch(e){ return String(ts); }
    }

    function esc(s) {
        if(!s) return "";
        return s.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
    }
    </script>
</body>
</html>
