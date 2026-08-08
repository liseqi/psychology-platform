<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"COUNSELOR".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>排班管理 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .schedule-container { display: grid; grid-template-columns: 280px 1fr; gap: 24px; margin-top: 24px; }
        @media(max-width:900px){ .schedule-container{grid-template-columns:1fr;} }
        .week-nav { display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; }
        .calendar-grid { display:grid; grid-template-columns:60px repeat(7,1fr); gap:2px; background:white; border-radius:12px; overflow:hidden; box-shadow:0 2px 12px rgba(0,0,0,0.08); min-height:300px;}
        .cell-header { background:#f8f9fa; padding:14px 8px; text-align:center; font-size:13px; font-weight:600; color:#555; }
        .cell-header.today { background:#fffbe6; }
        .time-cell { padding:12px 8px; text-align:center; font-size:13px; color:#666; display:flex;align-items:center;justify-content:center; }
        .slot-cell { min-height:70px; padding:6px; border-top:1px solid #f0f0f0; position:relative; cursor:pointer; transition:background 0.2s; }
        .slot-cell:hover { background:#e6f7ff; }
        .slot-cell.today { background:#fffbe6; }
        .slot-block { padding:6px 8px; border-radius:6px; font-size:12px; margin-bottom:4px; text-align:center; cursor:pointer; white-space:nowrap; overflow:hidden;text-overflow:ellipsis; }
        .booked { background:#e6f7ff; color:#1890ff; border:1px solid #91d5ff; }
        .available { background:#f6ffed; color:#52c41a; border:1px dashed #b7eb8f; cursor:pointer; }
        .available:hover { background:#d9f7be; }
        .off { background:#f5f5f5; color:#ccc; }
        .empty-hint { grid-column:1/-1;padding:60px;text-align:center;color:#999;font-size:14px; }
        .legend { display:flex; gap:20px; margin-top:16px; justify-content:center; }
        .legend-item { display:flex; align-items:center; gap:6px; font-size:13px; color:#666; }
        .dot { width:14px; height:14px; border-radius:4px; }
        .stat-num { font-size:24px;font-weight:bold; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>📅 排班管理</h1>
            <p>设置可预约时段 · 管理咨询日程</p>
        </header>

        <div class="schedule-container">
            <aside>
                <div style="background:white;border-radius:12px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,0.08);">
                    <h3 style="margin-bottom:16px;">快速操作</h3>
                    <button onclick="batchSet('available')" id="btnBatchAvailable" style="width:100%;padding:12px;background:#52c41a;color:white;border:none;border-radius:8px;margin-bottom:10px;cursor:pointer;">✓ 设为可预约</button>
                    <button onclick="batchSet('off')" id="btnBatchOff" style="width:100%;padding:12px;background:#999;color:white;border:none;border-radius:8px;cursor:pointer;">✗ 设为休息</button>
                    
                    <h3 style="margin:20px 0 12px;">本周统计</h3>
                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;" id="statsContainer">
                        <div style="text-align:center;padding:14px;background:#e6f7ff;border-radius:8px;">
                            <div class="stat-num" id="statBooked" style="color:#1890ff;">0</div>
                            <div style="color:#666;font-size:13px;">已预约</div>
                        </div>
                        <div style="text-align:center;padding:14px;background:#f6ffed;border-radius:8px;">
                            <div class="stat-num" id="statAvailable" style="color:#52c41a;">0</div>
                            <div style="color:#666;font-size:13px;">空余时段</div>
                        </div>
                        <div style="text-align:center;padding:14px;background:#fff7e6;border-radius:8px;">
                            <div class="stat-num" id="statPending" style="color:#faad14;">0</div>
                            <div style="color:#666;font-size:13px;">待确认</div>
                        </div>
                        <div style="text-align:center;padding:14px;background:#f5f5f5;border-radius:8px;">
                            <div class="stat-num" id="statOff" style="color:#999;">0</div>
                            <div style="color:#666;font-size:13px;">休息日</div>
                        </div>
                    </div>
                </div>
            </aside>

            <div>
                <div class="week-nav">
                    <h3 id="weekLabel">本周排班</h3>
                    <div>
                        <button onclick="changeWeek(-1)" style="padding:8px 16px;border:1px solid #ddd;background:white;border-radius:6px;cursor:pointer;">◀ 上周</button>
                        <button onclick="changeWeek(1)" style="padding:8px 16px;border:1px solid #ddd;background:white;border-radius:6px;cursor:pointer;margin-left:8px;">下周 ▶</button>
                    </div>
                </div>

                <div class="calendar-grid" id="calendarGrid"></div>

                <div class="legend">
                    <div class="legend-item"><div class="dot" style="background:#e6f7ff;border:1px solid #91d5ff;"></div>已预约</div>
                    <div class="legend-item"><div class="dot" style="background:#f6ffed;border:1px dashed #b7eb8f;"></div>可预约</div>
                    <div class="legend-item"><div class="dot" style="background:#f5f5f5;"></div>休息</div>
                </div>
            </div>
        </div>
    </main>

    <script>
        // 先初始化默认视图（不依赖 API）
        var mondayDate = getThisMonday();
        const TIME_SLOTS = ['09:00', '10:00', '14:00', '15:00'];
        const DAY_NAMES = ['周一','周二','周三','周四','周五','周六','周日'];
        
        document.addEventListener('DOMContentLoaded', function() {
            renderEmptyCalendar();  // 立即显示空日历
            loadScheduleData();     // 异步加载数据
        });

        function getThisMonday() {
            var now = new Date();
            var day = now.getDay() || 7;
            if (day !== 1) {
                now.setDate(now.getDate() - (day - 1));
            }
            return now.toISOString().split('T')[0];
        }

        function changeWeek(dir) {
            var d = new Date(mondayDate);
            d.setDate(d.getDate() + (dir * 7));
            mondayDate = d.toISOString().split('T')[0];
            renderEmptyCalendar();   // 切换周时先显示空
            loadScheduleData();      // 再异步加载
        }

        // 显示空的日历框架（保证页面始终有内容）
        function renderEmptyCalendar() {
            var todayStr = new Date().toISOString().split('T')[0];
            var monday = new Date(mondayDate);
            
            // 更新标题
            var sunday = new Date(monday);
            sunday.setDate(sunday.getDate() + 6);
            document.getElementById('weekLabel').textContent = 
                monday.getFullYear() + '年' + (monday.getMonth() + 1) + '月 第' + getWeekOfMonth(monday) + 
                '周 (' + (monday.getMonth() + 1) + '月' + monday.getDate() + '日 - ' +
                (sunday.getMonth() + 1) + '月' + sunday.getDate() + '日)';

            var html = '';

            // 表头行
            html += '<div class="cell-header"></div>';
            for (var d = 0; d < 7; d++) {
                var date = new Date(monday);
                date.setDate(date.getDate() + d);
                var dateStr = date.toISOString().split('T')[0];
                var isToday = dateStr === todayStr;
                html += '<div class="cell-header' + (isToday ? ' today' : '') + '">' + 
                        DAY_NAMES[d] + '<br><small style="font-weight:normal;color:#999;">' + date.getDate() + '</small></div>';
            }

            // 时间行 - 全部显示空白
            TIME_SLOTS.forEach(function(slot) {
                html += '<div class="time-cell">' + slot + '</div>';
                for (var d = 0; d < 7; d++) {
                    var date = new Date(monday);
                    date.setDate(date.getDate() + d);
                    var dateStr = date.toISOString().split('T')[0];
                    var isToday = dateStr === todayStr;
                    html += '<div class="slot-cell' + (isToday ? ' today' : '') + '"><div style="height:28px;"></div></div>';
                }
            });

            // 提示信息
            html += '<div class="empty-hint" id="gridHint">加载中...</div>';

            document.getElementById('calendarGrid').innerHTML = html;
        }

        async function loadScheduleData() {
            showGridHint('📅 正在加载数据...');
            
            // 调试：打印请求URL
            var requestUrl = CONTEXT_PATH + '/schedule/stats?monday=' + mondayDate;
            console.log('[DEBUG] 正在请求统计接口:', requestUrl);
            console.log('[DEBUG] CONTEXT_PATH:', CONTEXT_PATH);
            console.log('[DEBUG] mondayDate:', mondayDate);
            
            try {
                var [statsResp, scheduleResp] = await Promise.all([
                    fetch(requestUrl),
                    fetch(CONTEXT_PATH + '/schedule/week?monday=' + mondayDate)
                ]);

                console.log('[DEBUG] 统计接口状态:', statsResp.status);
                console.log('[DEBUG] 排班接口状态:', scheduleResp.status);

                if (statsResp.ok) {
                    var statsResult = await statsResp.json();
                    updateStats(statsResult.data || {});
                } else {
                    console.error('❌ 统计接口返回异常:', statsResp.status);
                    var statsErrorText = '';
                    try {
                        var statsErrorResult = await statsResp.json();
                        statsErrorText = statsErrorResult.message;
                    } catch (e) {}
                    console.error('   错误详情:', statsErrorText || '无法解析响应');
                }

                if (scheduleResp.ok) {
                    var scheduleResult = await scheduleResp.json();
                    var schedules = scheduleResult.data || [];
                    
                    console.log('[DEBUG] 排班数据条数:', schedules.length);
                    
                    // 检查是否需要初始化（首次访问时可能为空）
                    if (schedules.length === 0) {
                        console.log('[INFO] 无排班数据，尝试自动初始化...');
                        showGridHint('⏳ 首次使用，正在初始化排班数据（约需2-3秒）...');
                        
                        // 尝试调用初始化接口
                        try {
                            var initResp = await fetch(CONTEXT_PATH + '/schedule/init', {
                                method: 'POST',
                                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                            });
                            console.log('[DEBUG] 初始化接口状态:', initResp.status);
                            
                            if (initResp.ok) {
                                var initResult = await initResp.json();
                                console.log('[SUCCESS] 初始化成功:', initResult);
                                
                                // 重新加载数据
                                showGridHint('✅ 初始化成功！正在刷新数据...');
                                scheduleResp = await fetch(CONTEXT_PATH + '/schedule/week?monday=' + mondayDate);
                                if (scheduleResp.ok) {
                                    scheduleResult = await scheduleResp.json();
                                    schedules = scheduleResult.data || [];
                                    console.log('[DEBUG] 重新加载后排班数据条数:', schedules.length);
                                }
                            } else {
                                var initError = '';
                                try { 
                                    initError = (await initResp.json()).message; 
                                } catch(e) { 
                                    initError = 'HTTP ' + initResp.status; 
                                }
                                console.error('❌ 初始化失败:', initError);
                                showGridHint('❌ 初始化失败: ' + initError);
                            }
                        } catch (initErr) {
                            console.error('❌ 初始化异常:', initErr);
                            showGridHint('❌ 网络异常: ' + initErr.message);
                        }
                    }
                    
                    if (schedules.length > 0) {
                        renderCalendar(schedules);  // 有数据显示真实数据
                        
                        // 显示操作提示
                        var availableCount = schedules.filter(function(s) { 
                            return s.status === 'AVAILABLE'; 
                        }).length;
                        var offCount = schedules.filter(function(s) { 
                            return s.status === 'OFF'; 
                        }).length;
                        
                        if (offCount === schedules.length && availableCount === 0) {
                            showGridHint('💡 当前所有时段都是"休息"状态<br>点击任意时段设为"可预约"，或使用左侧批量设置按钮');
                        } else {
                            hideGridHint();  // 有混合状态时隐藏提示
                        }
                    } else {
                        showGridHint('⚠️ 暂无排班数据<br><br>请点击左侧 <b>✓ 设为可预约</b> 按钮初始化');
                        renderEmptyCalendar();  // 显示空日历框架
                    }
                } else {
                    var errorText = '';
                    try {
                        var errorResult = await scheduleResp.json();
                        errorText = errorResult.message || '未知错误';
                    } catch (e) {
                        errorText = '服务器响应异常 (' + scheduleResp.status + ')';
                    }
                    console.error('❌ 加载失败:', errorText);
                    showGridHint('⚠️ 加载失败：' + errorText + '\n\n💡 可能原因：未登录、权限不足或服务异常\n📞 请联系管理员或刷新页面重试');
                }
            } catch (e) {
                console.error('❌ 网络异常:', e);
                showGridHint('⚠️ 网络连接失败\n\n💡 请检查：\n1. 网络是否正常\n2. 服务器是否启动\n3. 是否已登录系统\n\n🔗 点击此处 <a href="javascript:location.reload()" style="color:#1890ff;">刷新页面</a>');
            }
        }

        function showGridHint(msg) {
            var hint = document.getElementById('gridHint');
            if (hint) {
                hint.innerHTML = msg.replace(/\n/g, '<br>');  // 支持换行显示
                hint.style.display = 'block';
                hint.style.color = '#1890ff';  // 信息用蓝色
            }
        }

        function hideGridHint() {
            var hint = document.getElementById('gridHint');
            if (hint) {
                hint.style.display = 'none';
            }
        }

        function updateStats(stats) {
            console.log('[STATS] 接收到的统计数据:', JSON.stringify(stats));
            
            // 使用显式转换确保数字显示（防止undefined/null显示问题）
            var booked = stats.bookedCount !== undefined ? stats.bookedCount : 0;
            var available = stats.availableSlots !== undefined ? stats.availableSlots : 0;
            var pending = stats.pendingCount !== undefined ? stats.pendingCount : 0;
            var off = stats.offSlots !== undefined ? stats.offSlots : 0;
            
            console.log('[STATS] 显示: booked=' + booked + ', available=' + available + ', pending=' + pending + ', off=' + off);
            
            document.getElementById('statBooked').textContent = booked;
            document.getElementById('statAvailable').textContent = available;
            document.getElementById('statPending').textContent = pending;
            document.getElementById('statOff').textContent = off;
        }

        function renderCalendar(schedules) {
            var todayStr = new Date().toISOString().split('T')[0];
            var monday = new Date(mondayDate);

            // 构建数据映射
            var map = {};
            schedules.forEach(function(s) {
                map[s.scheduleDate + '_' + s.timeSlot] = s;
            });

            var html = '';
            
            // 表头
            html += '<div class="cell-header"></div>';
            for (var d = 0; d < 7; d++) {
                var date = new Date(monday);
                date.setDate(date.getDate() + d);
                var dateStr = date.toISOString().split('T')[0];
                var isToday = dateStr === todayStr;
                html += '<div class="cell-header' + (isToday ? ' today' : '') + '">' + 
                        DAY_NAMES[d] + '<br><small style="font-weight:normal;color:#999;">' + date.getDate() + '</small></div>';
            }

            // 时间行 - 根据displayStatus渲染每个时段
            TIME_SLOTS.forEach(function(slot) {
                html += '<div class="time-cell">' + slot + '</div>';
                
                for (var d = 0; d < 7; d++) {
                    var date = new Date(monday);
                    date.setDate(date.getDate() + d);
                    var dateStr = date.toISOString().split('T')[0];
                    var key = dateStr + '_' + slot;
                    var sched = map[key];  // 获取该时段的数据对象
                    var isToday = dateStr === todayStr;

                    html += '<div class="slot-cell' + (isToday ? ' today' : '') + '">';

                    if (sched) {
                        // 使用后端计算好的displayStatus字段
                        var displayStatus = sched.displayStatus || 'OFF';
                        var bookedCount = sched.bookedCount || 0;
                        var maxApt = sched.maxAppointments || 1;
                        var dbStatus = sched.status || 'OFF';  // 数据库原始状态
                        
                        console.log('[RENDER] ' + dateStr + ' ' + slot + 
                                   ': db=' + dbStatus + ', display=' + displayStatus + 
                                   ', booked=' + bookedCount + '/' + maxApt);
                        
                        switch(displayStatus) {
                            case 'FULL':
                                // 已满 - 红色，显示学生姓名
                                var names = sched.studentNames || '';
                                var nameTitle = names ? ('预约学生: ' + names) : '已满';
                                html += '<div class="slot-block" style="background:#fff1f0;color:#cf1322;border:1px solid #ffa39e;" title="' + nameTitle + '">' + 
                                        (names ? names : '已满') + '</div>';
                                break;
                                
                            case 'PARTIAL':
                                // 部分预约 - 蓝色，显示预约数和学生姓名
                                var partNames = sched.studentNames || '';
                                var partTitle = '已预约 ' + bookedCount + '/' + maxApt + ' 人';
                                if (partNames) partTitle += '\n学生: ' + partNames;
                                html += '<div class="slot-block booked" title="' + partTitle + '">' + 
                                        bookedCount + '/' + maxApt + 
                                        (partNames ? '<br><small style="color:#666;font-size:10px;">' + partNames + '</small>' : '') + '</div>';
                                break;
                                
                            case 'AVAILABLE':
                                // 可预约且无预约 - 绿色可点击 → 切换为休息
                                html += '<div class="slot-block available" onclick="toggleSlot(this,' + sched.id + ',\'AVAILABLE\')" title="点击设为休息">空闲</div>';
                                break;
                                
                            case 'OFF':
                            default:
                                // 休息状态 - 灰色可点击 → 切换为可预约
                                var weekendHint = (d >= 5) ? ' [周末]' : '';
                                html += '<div class="slot-block off" onclick="toggleSlot(this,' + sched.id + ',\'OFF\')" title="点击设为可预约' + weekendHint + '">休息</div>';
                                break;
                        }
                    } else {
                        // 无数据（理论上不会出现）
                        html += '<div style="height:28px;"></div>';
                    }
                    
                    html += '</div>';
                }
            });

            document.getElementById('calendarGrid').innerHTML = html;
        }

        function toggleSlot(el, scheduleId, currentStatus) {
            // 状态切换逻辑
            var action, confirmMsg;
            
            if (currentStatus === 'OFF') {
                // 休息 → 可预约
                action = 'AVAILABLE';
                confirmMsg = '✅ 设为"可预约"？\n\n学生将可以看到并预约此时段';
            } else if (currentStatus === 'AVAILABLE') {
                // 可预约 → 休息
                action = 'OFF';
                confirmMsg = '❌ 设为"休息"？\n\n学生将无法看到此时段';
            } else {
                alert('⚠️ 无法修改！\n\n该时段当前状态异常或已有预约。\n如需修改请先取消相关预约。');
                return;
            }
            
            if (!confirm(confirmMsg)) return;

            console.log('[TOGGLE] scheduleId=' + scheduleId + ': ' + currentStatus + ' → ' + action);
            
            // 显示加载状态
            el.style.opacity = '0.5';
            el.textContent = '...';
            
            fetch(CONTEXT_PATH + '/schedule/update', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'scheduleId=' + scheduleId + '&status=' + action
            }).then(function(resp) { 
                console.log('[TOGGLE] 响应状态:', resp.status);
                return resp.json(); 
            })
              .then(function(result) {
                  console.log('[TOGGLE] 响应数据:', result);
                  
                  if (result.code === 200) {
                      // ✅ 成功 - 刷新整个页面数据
                      showSaveTip('💾 状态已更新为：' + (action === 'AVAILABLE' ? '可预约' : '休息'));
                      loadScheduleData();
                  } else {
                      // ❌ 失败 - 恢复原始状态
                      el.style.opacity = '1';
                      el.textContent = action === 'AVAILABLE' ? '休息' : '空闲';
                      alert('❌ 操作失败\n\n' + (result.message || '服务器错误'));
                  }
              })
              .catch(function(err) {
                  console.error('[TOGGLE] 异常:', err);
                  el.style.opacity = '1';
                  el.textContent = action === 'AVAILABLE' ? '休息' : '空闲';
                  alert('❌ 网络异常\n\n请检查网络连接后重试');
              });
        }

        function showSaveTip(msg) {
            var tip = document.createElement('div');
            tip.style.cssText = 'position:fixed;top:20px;left:50%;transform:translateX(-50%);background:#52c41a;color:white;padding:12px 24px;border-radius:8px;z-index:1000;box-shadow:0 4px 12px rgba(0,0,0,0.15);';
            tip.textContent = msg || '💾 排班信息已更新';
            document.body.appendChild(tip);
            setTimeout(function() { 
                tip.style.transition = 'opacity 0.3s';
                tip.style.opacity = '0';
                setTimeout(function() { tip.remove(); }, 300); 
            }, 2000);
        }

        function batchSet(type) {
            var actionName = type === 'available' ? '设为所有空闲时段为可预约' : '设为所有可预约时段为休息';
            if (!confirm('⚠️ 批量操作：' + actionName + '\n\n确定继续吗？')) return;

            fetch(CONTEXT_PATH + '/schedule/batch', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'action=' + type + '&monday=' + mondayDate
            }).then(function(resp) { return resp.json(); })
              .then(function(result) {
                  if (result.code === 200) {
                      alert('✅ 批量设置成功！更新了 ' + ((result.data && result.data.updated) || 0) + ' 个时段');
                      loadScheduleData();
                  } else {
                      alert('操作失败: ' + result.message);
                  }
              })
              .catch(function(err) {
                  alert('操作失败: 网络错误');
                  console.error(err);
              });
        }

        function getWeekOfMonth(date) {
            var firstOfMonth = new Date(date.getFullYear(), date.getMonth(), 1);
            var firstDay = firstOfMonth.getDay() || 7;
            var dayOfMonth = date.getDate();
            var offset = firstDay - 1;
            return Math.ceil((dayOfMonth + offset) / 7);
        }

        var CONTEXT_PATH = window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1));
    </script>
</body>
</html>
