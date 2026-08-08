<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%@ page import="java.util.Calendar" %>
<%
    // 禁用浏览器缓存
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"STUDENT".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }

    // 服务端预计算当前年月，用于日历初始渲染（即使 JS 失败也能显示）
    Calendar now = Calendar.getInstance();
    int initYear = now.get(Calendar.YEAR);
    int initMonth = now.get(Calendar.MONTH); // 0-11
    int initToday = now.get(Calendar.DAY_OF_MONTH);
    int startWeekday = now.get(Calendar.DAY_OF_WEEK) - 1; // 周日为0
    int daysInMonth = now.getActualMaximum(Calendar.DAY_OF_MONTH);
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <title>预约咨询 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css?v=<%= System.currentTimeMillis() %>">
    <style>
        .appointment-container { display: grid; grid-template-columns: 340px 1fr; gap: 24px; margin-top: 24px; }
        @media(max-width: 900px) { .appointment-container { grid-template-columns: 1fr; } }
        .sidebar-card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .sidebar-title { font-size: 18px; font-weight: 600; color: #333; margin-bottom: 16px; display: flex; align-items: center; gap: 8px; }
        .counselor-list { display: flex; flex-direction: column; gap: 12px; max-height: 400px; overflow-y: auto; }
        .counselor-item { padding: 14px; border: 2px solid transparent; border-radius: 10px; cursor: pointer; transition: all 0.2s; }
        .counselor-item:hover, .counselor-item.selected { border-color: #667eea; background: #f0f5ff; }
        .counselor-name { font-weight: 600; color: #333; margin-bottom: 4px; }
        .counselor-specialty { color: #666; font-size: 13px; }
        .calendar-area { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .calendar-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .calendar-nav button { padding: 8px 16px; border: 1px solid #ddd; background: white; border-radius: 6px; cursor: pointer; }
        .weekdays { display: grid; grid-template-columns: repeat(7, 1fr); text-align: center; padding: 10px 0; border-bottom: 2px solid #eee; }
        .weekday { font-weight: 600; color: #666; font-size: 13px; }
        .days-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; margin-top: 8px; }
        .day-cell { aspect-ratio: 1; display: flex; align-items: center; justify-content: center; border-radius: 8px; cursor: pointer; font-size: 14px; transition: all 0.2s; position: relative; }
        .day-cell:hover:not(.disabled):not(.selected) { background: #e6f7ff; }
        /* today 默认高亮，选中其他日期后通过 JS 移除此类 */
        .day-cell.today-active { background: #667eea; color: white; font-weight: bold; box-shadow: 0 0 0 2px #667eea, inset 0 0 0 3px white; }
        .day-cell.today-active::after { content: '今'; position: absolute; top: 2px; right: 4px; font-size: 9px; line-height: 1; opacity: 0.9; }
        /* selected 覆盖 */
        .day-cell.selected { background: #1890ff; color: white; font-weight: bold; box-shadow: 0 0 0 2px #1890ff, inset 0 0 0 3px white; }
        .day-cell.disabled { color: #ccc; cursor: default; }
        .slots-section { margin-top: 24px; }
        .slots-title { font-size: 16px; font-weight: 600; color: #333; margin-bottom: 16px; }
        .slots-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 10px; }
        .slot-btn { padding: 12px; border: 1px solid #ddd; border-radius: 8px; background: white; cursor: pointer; text-align: center; transition: all 0.2s; }
        .slot-btn:hover:not(.taken) { border-color: #667eea; color: #667eea; }
        .slot-btn.selected { background: #667eea; color: white; border-color: #667eea; }
        .slot-btn.taken { background: #f5f5f5; color: #ccc; cursor: not-allowed; text-decoration: line-through; }
        .confirm-bar { position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%); background: white; padding: 16px 32px; border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.15); display: none; align-items: center; gap: 20px; z-index: 100; }
        .confirm-text { color: #555; font-size: 14px; }
        .btn-confirm { padding: 12px 32px; background: #52c41a; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; font-weight: 600; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1>📅 预约心理咨询</h1>
            <p>选择咨询师和时间段，预约面对面咨询服务</p>
        </header>

        <div class="appointment-container">
            <aside>
                <div class="sidebar-card">
                    <div class="sidebar-title">👨‍⚕️ 选择咨询师</div>
                    <div class="counselor-list" id="counselorList">
                        <div style="padding:16px;color:#999;text-align:center;font-size:13px;">加载中...</div>
                    </div>
                </div>
                
                <div class="sidebar-card" style="margin-top:20px;">
                    <div class="sidebar-title">📌 我的预约</div>
                    <div id="myAppointmentList">
                        <div style="padding:16px;color:#999;text-align:center;font-size:13px;">暂无预约记录</div>
                    </div>
                </div>
            </aside>

            <div class="calendar-area">
                <div class="calendar-header">
                    <h3 id="currentMonth"><%= initYear %>年<%= initMonth + 1 %>月</h3>
                    <div><button onclick="changeMonth(-1)">◀ 上月</button><button onclick="changeMonth(1)">下月 ▶</button></div>
                </div>
                <div class="weekdays"><div class="weekday">日</div><div class="weekday">一</div><div class="weekday">二</div><div class="weekday">三</div><div class="weekday">四</div><div class="weekday">五</div><div class="weekday">六</div></div>
                <div class="days-grid" id="daysGrid">
                <%
                    // 服务端预渲染当月日历（即使 JS 不执行也能正常显示）
                    for (int i = 0; i < startWeekday; i++) {
                        out.print("<div class=\"day-cell disabled\"></div>");
                    }
                    for (int d = 1; d <= daysInMonth; d++) {
                        String cls = "day-cell";
                        boolean isToday = (d == initToday);
                        boolean isPast = false;
                        Calendar cell = Calendar.getInstance();
                        cell.set(initYear, initMonth, d, 0, 0, 0);
                        cell.set(Calendar.MILLISECOND, 0);
                        Calendar today0 = Calendar.getInstance();
                        today0.set(Calendar.HOUR_OF_DAY, 0);
                        today0.set(Calendar.MINUTE, 0);
                        today0.set(Calendar.SECOND, 0);
                        today0.set(Calendar.MILLISECOND, 0);
                        isPast = cell.before(today0);
                        if (isToday && !isPast) {
                            cls += " today-active";
                        }
                        if (isPast) {
                            cls += " disabled";
                            out.print("<div class=\"" + cls + "\">" + d + "</div>");
                        } else {
                            out.print("<div class=\"" + cls + "\" onclick=\"selectDate(" + d + ")\">" + d + "</div>");
                        }
                    }
                %>
                </div>

                <div class="slots-section">
                    <div class="slots-title" id="selectedDateText">选择日期后显示可用时段</div>
                    <div class="slots-grid" id="slotsGrid">
                        <div class="slot-btn" onclick="selectSlot(this)">09:00-09:50</div>
                        <div class="slot-btn" onclick="selectSlot(this)">10:00-10:50</div>
                        <div class="slot-btn taken">11:00-11:50</div>
                        <div class="slot-btn" onclick="selectSlot(this)">14:00-14:50</div>
                        <div class="slot-btn" onclick="selectSlot(this)">15:00-15:50</div>
                        <div class="slot-btn taken">16:00-16:50</div>
                        <div class="slot-btn" onclick="selectSlot(this)">17:00-17:50</div>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <div class="confirm-bar" id="confirmBar">
        <span class="confirm-text" id="confirmText">已选择：--</span>
        <button class="btn-confirm" onclick="submitAppointment()">确认预约</button>
    </div>

    <!-- 学生改期申请弹窗 -->
    <div id="rescheduleModal" class="modal" style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.45);z-index:9999;align-items:center;justify-content:center;">
        <div style="background:white;border-radius:12px;width:90%;max-width:400px;padding:24px;box-shadow:0 10px 40px rgba(0,0,0,0.2);">
            <h3 style="margin:0 0 16px 0;font-size:17px;color:#333;">申请改期</h3>
            <div style="margin-bottom:14px;">
                <div style="font-size:13px;color:#888;margin-bottom:6px;">新日期</div>
                <input type="date" id="rescheduleDate" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;">
            </div>
            <div style="margin-bottom:14px;">
                <div style="font-size:13px;color:#888;margin-bottom:6px;">新时段</div>
                <select id="rescheduleSlot" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;">
                    <option value="">请选择时段</option>
                    <option value="09:00-10:00">09:00-10:00</option>
                    <option value="10:00-11:00">10:00-11:00</option>
                    <option value="14:00-15:00">14:00-15:00</option>
                    <option value="15:00-16:00">15:00-16:00</option>
                </select>
            </div>
            <div style="margin-bottom:20px;">
                <div style="font-size:13px;color:#888;margin-bottom:6px;">改期原因</div>
                <textarea id="rescheduleReason" rows="3" style="width:100%;padding:10px;border:1px solid #ddd;border-radius:8px;resize:vertical;" placeholder="请填写改期原因..."></textarea>
            </div>
            <div style="display:flex;justify-content:flex-end;gap:10px;">
                <button onclick="closeRescheduleModal()" style="padding:8px 18px;border:1px solid #ddd;background:white;color:#555;border-radius:6px;cursor:pointer;">取消</button>
                <button onclick="submitReschedule()" style="padding:8px 18px;background:#667eea;color:white;border:none;border-radius:6px;cursor:pointer;font-weight:500;">提交申请</button>
            </div>
        </div>
    </div>

    <script>

        var CONTEXT_PATH = '${pageContext.request.contextPath}';
        var selectedDate = null, selectedSlot = null;
        var selectedCounselorId = null;
        var myAppointments = []; // 本次会话的预约列表
        // 基于当前真实日期初始化
        var now = new Date();
        var calYear = now.getFullYear();
        var calMonth = now.getMonth(); // 0-11
        var todayDay = now.getDate();

        // 月份中文映射
        var monthNames = ['1','2','3','4','5','6','7','8','9','10','11','12'];
        var defaultSpecialties = ['情绪管理、人际关系', '学业压力、职业规划', '情感困扰、家庭关系'];

        // 加载咨询师列表
        async function loadCounselors() {
            try {
                var resp = await fetch(CONTEXT_PATH + '/appointment/student/available');
                if (!resp.ok) throw new Error('HTTP ' + resp.status);
                var result = await resp.json();
                var container = document.getElementById('counselorList');
                if (result.code !== 200 || !result.data || result.data.length === 0) {
                    container.innerHTML = '<div style="padding:16px;color:#999;text-align:center;font-size:13px;">暂无可预约的咨询师<br><br><a href="javascript:location.reload()" style="color:#667eea;">点击刷新</a></div>';
                    return;
                }
                var html = '';
                for (var i = 0; i < result.data.length; i++) {
                    var c = result.data[i];
                    var sp = defaultSpecialties[i % defaultSpecialties.length];
                    html += '<div class="counselor-item" data-id="' + c.id + '" onclick="selectCounselor(this)">' +
                        '<div class="counselor-name">' + c.name + '</div>' +
                        '<div class="counselor-specialty">擅长：' + sp + (c.department ? ' · ' + c.department : '') + '</div>' +
                        '</div>';
                }
                container.innerHTML = html;
                // 默认选中第一个
                var first = container.querySelector('.counselor-item');
                if (first) {
                    first.classList.add('selected');
                    selectedCounselorId = parseInt(first.getAttribute('data-id'));
                }
            } catch (e) {
                console.error('加载咨询师失败:', e);
                document.getElementById('counselorList').innerHTML =
                    '<div style="padding:16px;color:#f5222d;text-align:center;font-size:13px;">加载失败，请刷新</div>';
            }
        }
        var weekDays = ['日','一','二','三','四','五','六'];

        function renderCalendar() {
            var grid = document.getElementById('daysGrid');
            var header = document.getElementById('currentMonth');

            // 更新月份标题
            header.textContent = calYear + '年' + monthNames[calMonth] + '月';

            // 计算当月信息
            var firstDay = new Date(calYear, calMonth, 1);
            var lastDay = new Date(calYear, calMonth + 1, 0);
            var daysInMonth = lastDay.getDate();
            // 当月第一天是周几 (0=周日)
            var startWeekday = firstDay.getDay();

            var html = '';

            // 填充月初空白
            for (var i = 0; i < startWeekday; i++) {
                html += '<div class="day-cell disabled"></div>';
            }

            // 渲染每一天
            for (var d = 1; d <= daysInMonth; d++) {
                var cls = 'day-cell';
                var isToday = (calYear === now.getFullYear() && calMonth === now.getMonth() && d === todayDay);

                if (isToday) {
                    cls += ' today-active';
                }

                // 过去的日期禁用（统一 0 点对比，避免当天被误判为过去）
                var cellDate = new Date(calYear, calMonth, d);
                cellDate.setHours(0, 0, 0, 0);
                var today0 = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                today0.setHours(0, 0, 0, 0);
                if (cellDate < today0) {
                    cls += ' disabled';
                    html += '<div class="' + cls + '">' + d + '</div>';
                } else {
                    // 未来日期可点击
                    html += '<div class="' + cls + '" onclick="selectDate(' + d + ')">' + d + '</div>';
                }
            }

            grid.innerHTML = html;
        }

        function changeMonth(dir) {
            calMonth += dir;
            if (calMonth > 11) { calMonth = 0; calYear++; }
            if (calMonth < 0) { calMonth = 11; calYear--; }
            selectedDate = null;
            selectedSlot = null;
            document.querySelectorAll('.slot-btn').forEach(function(s){ s.classList.remove('selected'); });
            document.getElementById('selectedDateText').textContent = '选择日期后显示可用时段';
            document.getElementById('confirmBar').style.display = 'none';
            renderCalendar();
        }

        function selectCounselor(el) {
            document.querySelectorAll('.counselor-item').forEach(function(item){ item.classList.remove('selected'); });
            el.classList.add('selected');
            selectedCounselorId = parseInt(el.getAttribute('data-id'));
        }

        function selectDate(day) {
            var todayCell = document.querySelector('.today-active');

            // 如果点击的是已选中日期 → 取消选中，恢复 today 显示
            if (selectedDate === day) {
                selectedDate = null;
                document.querySelectorAll('.day-cell').forEach(function(d){ d.classList.remove('selected'); });
                if (todayCell) todayCell.classList.add('today-active');
                document.getElementById('selectedDateText').textContent = '选择日期后显示可用时段';
                document.getElementById('confirmBar').style.display = 'none';
                return;
            }

            // 选中新日期：隐藏 today 标记
            if (todayCell) todayCell.classList.remove('today-active');

            selectedDate = day;
            document.querySelectorAll('.day-cell').forEach(function(d){ d.classList.remove('selected'); });
            var cells = document.querySelectorAll('.day-cell');
            for (var i = 0; i < cells.length; i++) {
                if (parseInt(cells[i].textContent) === day) {
                    cells[i].classList.add('selected');
                    break;
                }
            }
            document.getElementById('selectedDateText').textContent = monthNames[calMonth] + '月' + day + '日 可用时段';
        }

        function selectSlot(el) {
            if (el.classList.contains('taken')) return;
            document.querySelectorAll('.slot-btn').forEach(function(s){ s.classList.remove('selected'); });
            el.classList.add('selected');
            selectedSlot = el.textContent.trim();
            showConfirmBar();
        }

        function showConfirmBar() {
            if (selectedDate !== null && selectedSlot) {
                var counselorEl = document.querySelector('.counselor-item.selected');
                var counselorName = counselorEl ? counselorEl.querySelector('.counselor-name').textContent : '咨询师';
                document.getElementById('confirmBar').style.display = 'flex';
                document.getElementById('confirmText').textContent = '已选择：' + counselorName + ' / ' + monthNames[calMonth] + '月' + selectedDate + '日 / ' + selectedSlot;
            }
        }

        async function submitAppointment() {
            var counselorEl = document.querySelector('.counselor-item.selected');
            if (!counselorEl) {
                alert('请选择咨询师');
                return;
            }
            var counselorName = counselorEl.querySelector('.counselor-name').textContent;
            var counselorId = parseInt(counselorEl.getAttribute('data-id'));
            var dateText = calYear + '年' + monthNames[calMonth] + '月' + selectedDate + '日';
            var dateShort = monthNames[calMonth] + '月' + selectedDate + '日';
            var dateISO = calYear + '-' + monthNames[calMonth].padStart(2,'0') + '-' + String(selectedDate).padStart(2,'0');
            var weekdayNames = ['周日','周一','周二','周三','周四','周五','周六'];
            var weekday = weekdayNames[new Date(calYear, calMonth, selectedDate).getDay()];

            var confirmMsg = '✅ 预约确认信息\n\n' +
                '咨询师：' + counselorName + '\n' +
                '日期：' + dateText + '（' + weekday + '）\n' +
                '时段：' + selectedSlot + '\n\n' +
                '请确认以上信息无误？\n\n' +
                '💡 请在预约时间前10分钟到达心理咨询中心（行政楼302室）';

            if (!confirm(confirmMsg)) return;

            // 禁用按钮防重复提交
            var confirmBtn = document.querySelector('#confirmBar .btn-confirm');
            if (confirmBtn) { confirmBtn.disabled = true; confirmBtn.textContent = '提交中...'; }

            try {
                // 真正提交到后端
                var resp = await fetch(CONTEXT_PATH + '/appointment/create', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'counselorId=' + counselorId +
                          '&scheduleId=' +    // 留空，后端允许 NULL
                          '&appointmentDate=' + dateISO +
                          '&timeSlot=' + encodeURIComponent(selectedSlot)
                });
                if (!resp.ok) {
                    var errText = await resp.text();
                    throw new Error('HTTP ' + resp.status + ': ' + errText.substring(0, 200));
                }
                var result = await resp.json();

                if (result.code !== 200) {
                    alert('❌ 预约失败：' + (result.message || '未知错误'));
                    if (confirmBtn) { confirmBtn.disabled = false; confirmBtn.textContent = '确认预约'; }
                    return;
                }

                var appointment = {
                    id: result.data.appointmentId,
                    counselor: counselorName,
                    date: dateShort,
                    weekday: weekday,
                    slot: selectedSlot,
                    status: 'PENDING',
                    createTime: new Date().toLocaleString('zh-CN')
                };
                myAppointments.unshift(appointment);
                renderMyAppointments();

                alert('🎉 预约成功！\n\n预约编号：' + result.data.appointmentId + '\n状态：待确认\n\n系统将发送短信通知您预约结果。');
                document.getElementById('confirmBar').style.display = 'none';
                if (confirmBtn) { confirmBtn.disabled = false; confirmBtn.textContent = '确认预约'; }
                selectedDate = null;
                selectedSlot = null;
                renderCalendar();
            } catch (e) {
                console.error('提交失败:', e);
                alert('❌ 网络错误，请稍后重试');
                if (confirmBtn) { confirmBtn.disabled = false; confirmBtn.textContent = '确认预约'; }
            }
        }

        function renderMyAppointments() {
            var container = document.getElementById('myAppointmentList');
            if (myAppointments.length === 0) {
                container.innerHTML = '<div style="padding:16px;color:#999;text-align:center;font-size:13px;">暂无预约记录</div>';
                return;
            }
            var html = '';
            for (var i = 0; i < myAppointments.length; i++) {
                var a = myAppointments[i];
                var statusText = a.status === 'PENDING' ? '待确认' :
                                 (a.status === 'CONFIRMED' ? '已确认' :
                                 (a.status === 'COMPLETED' ? '已完成' : '已取消'));
                var statusColor = a.status === 'PENDING' ? '#faad14' :
                                  (a.status === 'CONFIRMED' ? '#52c41a' :
                                  (a.status === 'COMPLETED' ? '#1890ff' : '#999'));

                // 格式化日期
                var dateStr = a.appointmentDate || '';
                if (dateStr.indexOf('-') !== -1) {
                    var parts = dateStr.split('-');
                    dateStr = parseInt(parts[1]) + '月' + parseInt(parts[2]) + '日';
                }
                var weekdayNames = ['周日','周一','周二','周三','周四','周五','周六'];
                var weekday = weekdayNames[new Date(a.appointmentDate).getDay()] || '';

                // 学生确认状态提示
                var confirmTag = '';
                if (a.status === 'PENDING' && a.studentConfirmationStatus === 'WAITING') {
                    confirmTag = '<div style="margin-top:8px;font-size:12px;color:#faad14;">请确认是否可参加咨询</div>';
                } else if (a.studentConfirmationStatus === 'RESCHEDULE_REQUESTED') {
                    confirmTag = '<div style="margin-top:8px;font-size:12px;color:#faad14;">改期申请中：' +
                        (a.studentRescheduleDate || '') + ' ' + (a.studentRescheduleTimeSlot || '') + '</div>';
                }

                // 操作按钮
                var actionBtns = '';
                if (a.status === 'PENDING' && a.studentConfirmationStatus === 'WAITING') {
                    actionBtns = '<button onclick="confirmAppointment(' + a.id + ')" style="background:#52c41a;color:white;border:none;padding:4px 12px;border-radius:4px;cursor:pointer;font-size:12px;margin-right:6px;">确认</button>' +
                        '<button onclick="openRescheduleModal(' + a.id + ')" style="background:#faad14;color:white;border:none;padding:4px 12px;border-radius:4px;cursor:pointer;font-size:12px;">改时间</button>';
                } else if (a.status === 'PENDING' && a.studentConfirmationStatus === 'RESCHEDULE_REQUESTED') {
                    actionBtns = '<span style="color:#999;font-size:11px;">等待老师确认</span>';
                } else if (a.status === 'PENDING') {
                    actionBtns = '<span style="color:#faad14;font-size:11px;">等待老师确认</span>';
                } else {
                    actionBtns = '<span style="color:#999;font-size:11px;">#' + a.id + '</span>';
                }

                html += '<div style="padding:12px;background:#f6ffed;border-radius:8px;border-left:3px solid ' + statusColor + ';margin-bottom:8px;">' +
                    '<div style="font-weight:600;color:#333;">' + a.counselorName + ' · ' + dateStr + '</div>' +
                    '<div style="color:#666;font-size:13px;margin-top:4px;">' + weekday + ' ' + (a.timeSlot || '') + '</div>' +
                    confirmTag +
                    '<div style="margin-top:8px;display:flex;justify-content:space-between;align-items:center;">' +
                    '<span style="background:' + statusColor + ';color:white;padding:2px 8px;border-radius:10px;font-size:12px;">' + statusText + '</span>' +
                    actionBtns +
                    '</div>' +
                    '</div>';
            }
            container.innerHTML = html;
        }


    
        // 学生确认预约
        async function confirmAppointment(appointmentId) {
            if (!confirm('确认参加该咨询预约？')) return;
            try {
                var resp = await fetch(CONTEXT_PATH + '/appointment/confirm', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'appointmentId=' + appointmentId
                });
                if (!resp.ok) throw new Error('HTTP ' + resp.status);
                var result = await resp.json();
                if (result.code === 200) {
                    alert('✅ 已确认参加咨询');
                    loadMyAppointments();
                } else {
                    alert('❌ ' + (result.message || '确认失败'));
                }
            } catch (e) {
                console.error('确认预约失败:', e);
                alert('❌ 网络错误，请稍后重试');
            }
        }

        // 打开改期弹窗
        var currentRescheduleId = null;
        function openRescheduleModal(appointmentId) {
            currentRescheduleId = appointmentId;
            document.getElementById('rescheduleModal').style.display = 'flex';
            document.getElementById('rescheduleDate').value = '';
            document.getElementById('rescheduleSlot').value = '';
            document.getElementById('rescheduleReason').value = '';
        }
        function closeRescheduleModal() {
            document.getElementById('rescheduleModal').style.display = 'none';
            currentRescheduleId = null;
        }

        // 提交改期申请
        async function submitReschedule() {
            if (!currentRescheduleId) return;
            var newDate = document.getElementById('rescheduleDate').value;
            var newSlot = document.getElementById('rescheduleSlot').value;
            var reason = document.getElementById('rescheduleReason').value.trim();
            if (!newDate) { alert('请选择新日期'); return; }
            if (!newSlot) { alert('请选择新时段'); return; }

            try {
                var resp = await fetch(CONTEXT_PATH + '/appointment/reschedule-request', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'appointmentId=' + currentRescheduleId +
                          '&newDate=' + newDate +
                          '&newTimeSlot=' + encodeURIComponent(newSlot) +
                          '&reason=' + encodeURIComponent(reason)
                });
                if (!resp.ok) throw new Error('HTTP ' + resp.status);
                var result = await resp.json();
                if (result.code === 200) {
                    alert('✅ 改期申请已提交，等待老师确认');
                    closeRescheduleModal();
                    loadMyAppointments();
                } else {
                    alert('❌ ' + (result.message || '提交失败'));
                }
            } catch (e) {
                console.error('提交改期申请失败:', e);
                alert('❌ 网络错误，请稍后重试');
            }
        }

        // 从后端API加载学生的预约记录
        async function loadMyAppointments() {
            try {
                var resp = await fetch(CONTEXT_PATH + '/appointment/list?status=ALL');
                if (!resp.ok) throw new Error('HTTP ' + resp.status);
                var result = await resp.json();
                if (result.code === 200 && result.data && result.data.length > 0) {
                    myAppointments = [];
                    for (var i = 0; i < result.data.length; i++) {
                        var apt = result.data[i];
                        myAppointments.push({
                            id: apt.id,
                            counselorName: apt.counselorName || '咨询师',
                            appointmentDate: apt.appointmentDate,
                            timeSlot: apt.timeSlot,
                            status: apt.status,
                            studentConfirmationStatus: apt.studentConfirmationStatus || 'WAITING',
                            studentRescheduleDate: apt.studentRescheduleDate,
                            studentRescheduleTimeSlot: apt.studentRescheduleTimeSlot,
                            studentRescheduleReason: apt.studentRescheduleReason,
                            createTime: apt.createdAt
                        });
                    }
                } else {
                    myAppointments = [];
                }
                renderMyAppointments();
            } catch (e) {
                console.error('加载我的预约失败:', e);
                document.getElementById('myAppointmentList').innerHTML =
                    '<div style="padding:16px;color:#f5222d;text-align:center;font-size:13px;">加载失败，<a href="javascript:loadMyAppointments()" style="color:#f5222d;">点击重试</a></div>';
            }
        }

        // 取消预约
        async function cancelAppointment(appointmentId) {
            if (!confirm('确定要取消这个预约吗？')) return;
            
            try {
                var resp = await fetch(CONTEXT_PATH + '/appointment/cancel', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'appointmentId=' + appointmentId + '&reason=学生主动取消'
                });
                if (!resp.ok) throw new Error('HTTP ' + resp.status);
                var result = await resp.json();
                if (result.code === 200) {
                    alert('✅ 取消成功');
                    loadMyAppointments(); // 刷新预约列表
                } else {
                    alert('❌ 取消失败：' + (result.message || '未知错误'));
                }
            } catch (e) {
                console.error('取消预约失败:', e);
                alert('❌ 网络错误，请稍后重试');
            }
        }

        // 服务端已预渲染当月日历，此处仅在 JS 正常时做"切换月份"才重新渲染
        // 即使 JS 报错，页面也能正常显示当前月日历
        try { renderCalendar(); } catch(e) { console.error('init renderCalendar fail:', e); }
        // 异步加载咨询师列表和我的预约记录
        try { loadCounselors(); } catch(e) { console.error('loadCounselors fail:', e); }
        try { loadMyAppointments(); } catch(e) { console.error('loadMyAppointments fail:', e); }
    </script>
</body>
</html>
