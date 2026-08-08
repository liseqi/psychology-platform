<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    response.setCharacterEncoding("UTF-8");
    
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
    <title id="pageTitle">Loading...</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .stats-row{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-bottom:24px}
        .stat-card{background:white;border-radius:12px;padding:24px;box-shadow:0 2px 12px rgba(0,0,0,.08);text-align:center}
        .stat-value{font-size:36px;font-weight:bold;margin:8px 0}
        .stat-label{color:#666;font-size:14px}
        .alert-list-container{background:white;border-radius:12px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.08)}
        .alert-item{background:white;border-radius:10px;padding:18px;margin-bottom:14px;display:flex;gap:16px;align-items:flex-start;
            box-shadow:0 2px 8px rgba(0,0,0,.06);border-left:4px solid #667eea;transition:transform .2s}
        .alert-item:hover{transform:translateX(4px);box-shadow:0 4px 16px rgba(0,0,0,.12)}
        .alert-high{border-color:#ff4d4f!important}.alert-medium{border-color:#faad14!important}.alert-low{border-color:#52c41a!important}
        .alert-info{flex:1}
        .alert-student{font-weight:600;font-size:15px;color:#333;margin-bottom:6px}
        .alert-detail{color:#555;font-size:13px;line-height:1.6;margin-bottom:6px}
        .alert-time{color:#999;font-size:12px}
        .alert-actions{display:flex;gap:8px;flex-shrink:0}
        .btn-action{padding:7px 16px;border-radius:6px;font-size:13px;cursor:pointer;border:none;font-weight:500;transition:all .2s}
        .btn-handle{background:#667eea;color:white}.btn-handle:hover{background:#5568d3}
        .btn-view{background:#f0f2f5;color:#333}.btn-view:hover{background:#e0e0e0}
        .filter-bar{display:flex;gap:12px;margin-bottom:20px;flex-wrap:wrap;background:#fafafa;padding:16px;border-radius:10px}
        .filter-bar select,.filter-bar input{padding:9px 14px;border:1px solid #ddd;border-radius:8px;font-size:13px}
        .filter-bar input{flex:1;max-width:300px}
        .empty-state{text-align:center;padding:60px 20px;color:#999}
        .empty-state-icon{font-size:48px;margin-bottom:12px}
        .status-badge{display:inline-block;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:500}
        .status-pending{background:#fff7e6;color:#fa8c16}
        .status-processing{background:#e6f7ff;color:#1890ff}
        .status-resolved{background:#f6ffed;color:#52c41a}
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="container">
        <header class="page-header">
            <h1 id="headerTitle"></h1>
            <p id="headerDesc"></p>
        </header>

        <div class="stats-row">
            <div class="stat-card">
                <div class="stat-label" id="labelPending"></div>
                <div class="stat-value" id="pendingCount" style="color:#ff4d4f;">--</div>
            </div>
            <div class="stat-card">
                <div class="stat-label" id="labelProcessing"></div>
                <div class="stat-value" id="processingCount" style="color:#faad14;">--</div>
            </div>
            <div class="stat-card">
                <div class="stat-label" id="labelResolved"></div>
                <div class="stat-value" id="resolvedCount" style="color:#52c41a;">--</div>
            </div>
        </div>

        <div class="filter-bar">
            <select id="levelFilter" onchange="loadAlertList()"></select>
            <select id="statusFilter" onchange="loadAlertList()"></select>
            <input type="text" id="searchInput" onkeyup="if(event.keyCode===13)loadAlertList()">
            <button onclick="loadAlertList()" style="padding:9px 24px;background:#667eea;color:white;border:none;border-radius:8px;cursor:pointer;font-weight:500;" id="filterBtn"></button>
        </div>

        <div class="alert-list-container" id="alertListContainer">
            <div class="empty-state">
                <div class="empty-state-icon" id="emptyIcon"></div>
                <div style="font-size:16px;margin-bottom:8px;" id="emptyText"></div>
            </div>
        </div>
    </main>

    <!-- Handle Modal -->
    <div id="handleModal" class="modal" style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.45);z-index:9999;align-items:center;justify-content:center;">
        <div class="modal-content" style="background:white;border-radius:12px;width:90%;max-width:520px;max-height:90vh;overflow:auto;box-shadow:0 10px 40px rgba(0,0,0,0.2);">
            <div class="modal-header" style="padding:18px 24px;border-bottom:1px solid #eee;display:flex;justify-content:space-between;align-items:center;">
                <h3 id="modalTitle" style="margin:0;font-size:17px;color:#333;">处理预警</h3>
                <button onclick="closeModal()" style="background:none;border:none;font-size:22px;color:#999;cursor:pointer;">&times;</button>
            </div>
            <div class="modal-body" style="padding:24px;">
                <div style="margin-bottom:16px;">
                    <div style="font-size:13px;color:#888;margin-bottom:4px;">学生</div>
                    <div id="modalStudent" style="font-size:15px;font-weight:600;color:#333;">--</div>
                </div>
                <div style="margin-bottom:16px;">
                    <div style="font-size:13px;color:#888;margin-bottom:4px;">预警级别</div>
                    <div id="modalLevel" style="font-size:15px;font-weight:500;">--</div>
                </div>
                <div style="margin-bottom:16px;">
                    <div style="font-size:13px;color:#888;margin-bottom:4px;">触发原因</div>
                    <div id="modalReason" style="font-size:14px;color:#555;line-height:1.6;background:#f7f8fa;padding:12px;border-radius:8px;">--</div>
                </div>
                <div style="margin-bottom:16px;">
                    <div style="font-size:13px;color:#888;margin-bottom:6px;">预约咨询时间 <span style="color:#ff4d4f;">*</span></div>
                    <div style="display:flex;gap:12px;">
                        <input type="date" id="modalAppointmentDate" style="flex:1;padding:10px 14px;border:1px solid #ddd;border-radius:8px;font-size:14px;" min="">
                        <select id="modalTimeSlot" style="flex:1;padding:10px 14px;border:1px solid #ddd;border-radius:8px;font-size:14px;">
                            <option value="">请选择时段</option>
                            <option value="09:00-10:00">09:00-10:00</option>
                            <option value="10:00-11:00">10:00-11:00</option>
                            <option value="14:00-15:00">14:00-15:00</option>
                            <option value="15:00-16:00">15:00-16:00</option>
                        </select>
                    </div>
                </div>
                <div style="margin-bottom:8px;">
                    <div style="font-size:13px;color:#888;margin-bottom:4px;">干预记录 <span style="color:#ff4d4f;">*</span></div>
                    <textarea id="modalRecord" rows="4" style="width:100%;padding:12px;border:1px solid #ddd;border-radius:8px;font-size:14px;resize:vertical;" placeholder="请填写已采取的干预措施、与学生沟通的情况等..."></textarea>
                </div>
            </div>
            <div class="modal-footer" style="padding:14px 24px;border-top:1px solid #eee;display:flex;justify-content:flex-end;gap:10px;">
                <button onclick="closeModal()" style="padding:8px 18px;border:1px solid #ddd;background:white;color:#555;border-radius:6px;cursor:pointer;font-size:13px;">取消</button>
                <button id="modalSubmitBtn" style="padding:8px 18px;background:#667eea;color:white;border:none;border-radius:6px;cursor:pointer;font-size:13px;font-weight:500;">提交处理</button>
            </div>
        </div>
    </div>

    <!-- Load text resource FIRST, then load app JS -->
    <script src="../js/alerts-text.js?v=20260715j"></script>
    <script src="../js/counselor-alerts.js?v=20260715j"></script>

</body>
</html>
