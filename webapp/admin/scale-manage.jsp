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
    <title>量表题库管理 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .btn-add { padding: 10px 24px; background: #52c41a; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 14px; }
        .btn-add:hover { background: #49b177; }
        .scale-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
        .scale-card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); transition: transform 0.2s; position: relative; }
        .scale-card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.12); }
        .scale-card.disabled { opacity: 0.6; }
        .status-tag { position: absolute; top:16px; right:16px; padding:3px 10px; border-radius:10px; font-size:11px; font-weight:600; }
        .status-active { background:#f6ffed;color:#52c41a;border:1px solid #b7eb8f; }
        .status-inactive { background:#fff2f0;color:#ff4d4f;border:1px solid #ffccc7; }
        .scale-name { font-size: 18px; font-weight: 600; color: #333; margin-bottom: 8px; padding-right:60px; }
        .scale-desc { color: #666; font-size: 14px; line-height: 1.6; margin-bottom: 16px; max-height:60px; overflow:hidden; text-overflow:ellipsis; }
        .scale-meta { display: flex; gap: 16px; color: #999; font-size: 13px; margin-bottom: 16px; }
        .scale-actions { display: flex; gap: 8px; flex-wrap: wrap; }
        .btn-card { padding: 6px 14px; border-radius: 5px; font-size: 13px; cursor: pointer; border: 1px solid #ddd; background: white; transition: all 0.2s; }
        .btn-edit:hover { border-color: #667eea; color: #667eea; }
        .btn-delete:hover { border-color: #ff4d4f; color: #ff4d4f; }
        .btn-preview:hover { border-color: #1890ff; color: #1890ff; }
        .modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: none; justify-content: center; align-items: center; z-index: 1000; }
        .modal { background: white; border-radius: 12px; padding: 30px; width: 500px; max-width: 90vw; }
        .modal h3 { margin-bottom: 20px; }
        .form-group { margin-bottom: 16px; }
        .form-group label { display: block; margin-bottom: 6px; color: #333; font-weight: 500; }
        .form-group input, .form-group textarea, .form-group select { width: 100%; padding: 10px 12px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box; }
        .modal-actions { display: flex; justify-content: flex-end; gap: 12px; margin-top: 20px; }
        .empty-state { text-align:center;padding:80px 20px;color:#999;grid-column:1/-1; }
        .empty-icon { font-size:48px;margin-bottom:16px;opacity:0.5; }
        .pagination { display:flex;justify-content:center;gap:8px;margin-top:24px; }
        .page-btn { padding:8px 16px;border:1px solid #ddd;border-radius:6px;cursor:pointer;background:white; }
        .page-btn.active, .page-btn:hover:not(:disabled) { background:#667eea;color:white;border-color:#667eea; }
        .page-btn:disabled { opacity:0.45;cursor:not-allowed; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>📋 量表题库管理</h1>
            <p>管理心理测评量表题目配置</p>
        </header>

        <div class="toolbar">
            <input type="text" id="searchInput" placeholder="搜索量表名称/描述..." style="padding: 10px 16px; border: 1px solid #ddd; border-radius: 8px; width: 260px;" onkeydown="if(event.key==='Enter')loadScales()">
            <div style="display:flex;gap:10px;">
                <button onclick="showAddModal()" class="btn-add">+ 新增量表</button>
            </div>
        </div>

        <div class="scale-grid" id="scaleGrid">
            <div style="grid-column:1/-1;text-align:center;padding:40px;color:#999;">
                正在加载量表数据...
            </div>
        </div>

        <div class="pagination" id="pagination"></div>
    </main>

    <!-- 新增/编辑模态框 -->
    <div class="modal-overlay" id="scaleModal" onclick="closeModal(event)">
        <div class="modal" onclick="event.stopPropagation()">
            <h3 id="modalTitle">新增量表</h3>
            <input type="hidden" id="editScaleId">
            <div class="form-group"><label>量表名称 *</label><input type="text" id="scaleName" placeholder="如：SCL-90症状自评量表"></div>
            <div class="form-group"><label>分类</label><select id="scaleCategory">
                <option value="心理健康">心理健康</option>
                <option value="抑郁筛查">抑郁筛查</option>
                <option value="焦虑评估">焦虑评估</option>
                <option value="压力测量">压力测量</option>
                <option value="人格测试">人格测试</option>
                <option value="其他">其他</option>
            </select></div>
            <div class="form-group"><label>描述说明</label><textarea rows="3" id="scaleDesc" placeholder="输入量表的用途和描述..."></textarea></div>
            <div style="display:flex;gap:16px;">
                <div class="form-group" style="flex:1;"><label>题目数量</label><input type="number" id="scaleQuestions" placeholder="如：90"></div>
                <div class="form-group" style="flex:1;"><label>预计用时(分钟)</label><input type="number" id="scaleTime" placeholder="如：20"></div>
            </div>
            <div class="form-group"><label>指导语</label><textarea rows="2" id="scaleInstruction" placeholder="填写前的指导说明（选填）"></textarea></div>
            <div class="modal-actions">
                <button class="btn-card" style="padding:8px 20px;" onclick="closeModal()">取消</button>
                <button class="btn-add" id="saveBtn" onclick="saveScale()">保存</button>
            </div>
        </div>
    </div>

    <!-- 预览模态框 -->
    <div class="modal-overlay" id="previewModal" onclick="closePreview(event)">
        <div class="modal" onclick="event.stopPropagation()" style="width:600px;">
            <h3 id="previewTitle">量表预览</h3>
            <div id="previewContent" style="color:#555;line-height:1.8;"></div>
            <div class="modal-actions">
                <button class="btn-card" style="padding:8px 20px;" onclick="closePreview()">关闭</button>
            </div>
        </div>
    </div>

    <script>
    var CTX = "<%=ctx%>";
    var currentPage = 1;
    var pageSize = 12;

    window.onload = function() {
        loadScales();
    };

    function loadScales() {
        var container = document.getElementById('scaleGrid');
        container.innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:40px;color:#999;">正在加载...</div>';

        var keyword = document.getElementById('searchInput').value;
        var url = CTX + '/scale/list?page=' + currentPage + '&pageSize=' + pageSize;
        if (keyword) url += '&keyword=' + encodeURIComponent(keyword);

        fetch(url).then(function(r){return r.json();}).then(renderScales).catch(function(e){
            console.error(e);
            container.innerHTML = '<div class="empty-state"><div class="empty-icon">!</div><span>加载失败，请刷新重试</span></div>';
        });
    }

    function renderScales(res) {
        var container = document.getElementById('scaleGrid');
        var pg = document.getElementById('pagination');

        if(!res || res.code !== 200 || !res.data) {
            container.innerHTML = '<div class="empty-state"><div class="empty-icon">-</div><span>暂无量表数据</span></div>';
            pg.innerHTML = '';
            return;
        }

        var d = res.data;
        var list = d.list || [];
        var total = d.total || 0;
        var tp = d.totalPages || 1;

        if(list.length === 0) {
            container.innerHTML = '<div class="empty-state"><div class="empty-icon">~</div><span>暂无符合条件的量表</span></div>';
            pg.innerHTML = '';
            return;
        }

        var html = '';
        for(var i=0;i<list.length;i++){
            var s = list[i];
            var isActive = s.status === 1;
            var qCount = s.totalQuestions || '-';
            var timeLimit = (s.timeLimit != null && s.timeLimit > 0) ? s.timeLimit : Math.max(1, Math.ceil((s.totalQuestions || 0) * 0.5));
            var timeStr = timeLimit + '分钟';
            
            html += '<div class="scale-card' + (!isActive?' disabled':'') + '">' +
                '<span class="status-tag '+(isActive?'status-active':'status-inactive')+'">' + (isActive?'启用中':'已停用') + '</span>' +
                '<div class="scale-name">' + esc(s.name) + '</div>' +
                '<div class="scale-desc">' + esc(s.description||'暂无描述') + '</div>' +
                '<div class="scale-meta"><span>&#128196; ' + qCount + '题</span><span>&#9203; 约' + timeStr + '</span><span>&#128214; ' + (s.category||'未分类') + '</span></div>' +
                '<div class="scale-actions">' +
                    '<button class="btn-card btn-edit" onclick="editScale('+s.id+')">&#9998; 编辑</button>' +
                    '<button class="btn-card btn-delete" onclick="deleteScale('+s+',\''+esc(s.name)+'\')">删除</button>' +
                    '<button class="btn-card btn-preview" onclick="previewScale('+s.id+')">&#128065; 预览</button>' +
                    '<button class="btn-card" onclick="toggleStatus('+s+','+isActive+')" style="color:'+(isActive?'#ff4d4f':'#52c41a')+'">'+(isActive?'停用':'启用')+'</button>' +
                '</div></div>';
        }
        container.innerHTML = html;

        // 分页
        if(tp > 1) {
            var p = '<button class="page-btn"'+(currentPage<=1?' disabled':'')+' onclick="goPage(1)">首页</button>';
            p += '<button class="page-btn"'+(currentPage<=1?' disabled':'')+' onclick="goPage('+(currentPage-1)+')">&lt;</button>';
            for(var j=Math.max(1,currentPage-2);j<=Math.min(tp,currentPage+2);j++){
                p += '<button class="page-btn'+(j===currentPage?' active':'')+'" onclick="goPage('+j+')">'+j+'</button>';
            }
            p += '<button class="page-btn"'+(currentPage>=tp?' disabled':'')+' onclick="goPage('+(currentPage+1)+')">&gt;</button>';
            p += '<button class="page-btn"'+(currentPage>=tp?' disabled':'')+' onclick="goPage('+tp+')">末页</button>';
            p += '<span style="margin-left:12px;color:#999;font-size:13px;">共'+total+'个量表</span>';
            pg.innerHTML = p;
        } else {
            pg.innerHTML = '';
        }
    }

    function goPage(p){currentPage=p;loadScales();document.querySelector('.container').scrollIntoView({behavior:'smooth'});}

    // 新增
    function showAddModal(){
        document.getElementById('modalTitle').textContent = '新增量表';
        document.getElementById('editScaleId').value = '';
        document.getElementById('scaleName').value = '';
        document.getElementById('scaleDesc').value = '';
        document.getElementById('scaleCategory').value = '其他';
        document.getElementById('scaleQuestions').value = '';
        document.getElementById('scaleTime').value = '';
        document.getElementById('scaleInstruction').value = '';
        document.getElementById('scaleModal').style.display = 'flex';
    }

    function closeModal(e){
        if(!e || e.target === e.currentTarget){
            document.getElementById('scaleModal').style.display = 'none';
        }
    }

    function saveScale(){
        var name = document.getElementById('scaleName').value.trim();
        var editId = document.getElementById('editScaleId').value;

        if(!name){
            alert('请输入量表名称！');
            return;
        }

        var btn = document.getElementById('saveBtn');
        btn.disabled=true;
        btn.textContent='提交中...';

        var form = new FormData();
        form.append('name', name);
        form.append('description', document.getElementById('scaleDesc').value);
        form.append('category', document.getElementById('scaleCategory').value);
        form.append('totalQuestions', document.getElementById('scaleQuestions').value);
        form.append('timeLimit', document.getElementById('scaleTime').value);
        form.append('instruction', document.getElementById('scaleInstruction').value);

        var url = editId ? (CTX+'/scale/update?id='+editId) : (CTX+'/scale/add');

        fetch(url, {method:'POST', body:form}).then(function(r){return r.json();}).then(function(d){
            btn.disabled=false;
            btn.textContent='保存';
            if(d.code===200){
                alert(editId?'✅ 更新成功！':'✅ 创建成功！');
                closeModal();
                loadScales();
            } else{
                alert('❌ 操作失败：'+(d.message||'未知错误'));
            }
        }).catch(function(){
            btn.disabled=false;
            btn.textContent='保存';
            alert('网络错误，请重试');
        });
    }

    // 编辑
    function editScale(id){
        fetch(CTX+'/scale/detail?id='+id).then(function(r){return r.json();}).then(function(d){
            if(d.code===200 && d.data){
                var s = d.data;
                document.getElementById('modalTitle').textContent = '编辑量表';
                document.getElementById('editScaleId').value = s.id;
                document.getElementById('scaleName').value = s.name||'';
                document.getElementById('scaleDesc').value = s.description||'';
                document.getElementById('scaleCategory').value = s.category||'其他';
                document.getElementById('scaleQuestions').value = s.totalQuestions||'';
                document.getElementById('scaleTime').value = s.timeLimit||'';
                document.getElementById('scaleInstruction').value = s.instruction||'';
                document.getElementById('scaleModal').style.display = 'flex';
            }
        }).catch(function(e){console.error(e)});
    }

    // 删除
    function deleteScale(id, name){
        if(confirm('⚠️ 确认删除量表【'+name+'】吗？\n\n此操作不可恢复，相关测评记录可能受影响！')){
            var form = new FormData();
            form.append('id', id);
            fetch(CTX+'/scale/delete', {method:'POST', body:form}).then(function(r){return r.json();}).then(function(d){
                if(d.code===200){
                    alert('✅ 已删除');
                    loadScales();
                } else{
                    alert('❌ 删除失败：'+(d.message||'未知错误'));
                }
            });
        }
    }

    // 启用/停用
    function toggleStatus(scaleObj, isActive){
        var action = isActive ? '停用' : '启用';
        if(!confirm('确认要'+action+'该量表吗？')) return;

        var form = new FormData();
        form.append('id', scaleObj.id);
        form.append('status', isActive ? 0 : 1);

        fetch(CTX+'/scale/toggleStatus', {method:'POST', body:form}).then(function(r){return r.json();}).then(function(d){
            if(d.code===200){
                alert('✅ 已'+action);
                loadScales();
            } else{
                alert('❌ 操作失败');
            }
        });
    }

    // 预览
    function previewScale(id){
        fetch(CTX+'/scale/detail?id='+id).then(function(r){return r.json();}).then(function(d){
            if(d.code===200 && d.data){
                var s = d.data;
                document.getElementById('previewTitle').textContent = '📋 '+esc(s.name);
                document.getElementById('previewContent').innerHTML =
                    '<p><strong>分类：</strong>'+esc(s.category||'-')+'</p>'+
                    '<p><strong>题目数量：</strong>'+(s.totalQuestions||'-')+' 题</p>'+
                    '<p><strong>预计用时：</strong>'+(s.timeLimit?s.timeLimit+'分钟':'-')+'</p>'+
                    '<p><strong>描述：</strong></p>'+
                    '<div style="background:#f8f9fa;padding:12px;border-radius:6px;margin-top:8px;">'+esc(s.description||'暂无详细描述')+'</div>'+
                    (s.instruction?'<p style="margin-top:12px;"><strong>指导语：</strong></p><div style="background:#e6f7ff;padding:12px;border-radius:6px;">'+esc(s.instruction)+'</div>':'');
                document.getElementById('previewModal').style.display = 'flex';
            }
        });
    }

    function closePreview(e){if(!e||e.target===e.currentTarget) document.getElementById('previewModal').style.display='none';}
    function esc(s){if(!s)return '';return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}
    </script>
</body>
</html>
