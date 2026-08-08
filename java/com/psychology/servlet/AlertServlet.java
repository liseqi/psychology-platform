package com.psychology.servlet;

import com.psychology.dao.AlertRecordDao;
import com.psychology.dao.AppointmentDao;
import com.psychology.dao.ConsultationRecordDao;
import com.psychology.dao.NotificationDao;
import com.psychology.dao.ScheduleDao;
import com.psychology.entity.AlertRecord;
import com.psychology.entity.Appointment;
import com.psychology.entity.ConsultationRecord;
import com.psychology.entity.Notification;
import com.psychology.entity.User;
import com.psychology.util.LogHelper;
import com.psychology.util.JsonUtil;


import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;


/**
 * 预警管理Servlet - 多级分流+干预跟踪
 */
@WebServlet("/alert/*")
public class AlertServlet extends HttpServlet {

    private AlertRecordDao alertDao = new AlertRecordDao();
    private AppointmentDao appointmentDao = new AppointmentDao();
    private ConsultationRecordDao consultationRecordDao = new ConsultationRecordDao();
    private NotificationDao notificationDao = new NotificationDao();
    private ScheduleDao scheduleDao = new ScheduleDao();



    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();

        if ("/list".equals(pathInfo)) {
            handleList(req, resp);              // 获取预警列表
        } else if ("/detail".equals(pathInfo)) {
            handleDetail(req, resp);             // 获取预警详情
        } else if ("/counselor/list".equals(pathInfo)) {
            handleCounselorList(req, resp);      // 咨询师查看名下预警
        } else if ("/statistics".equals(pathInfo)) {
            handleStatistics(req, resp);           // 咨询师预警统计
        }
    }

    /**
     * 咨询师预警统计（用于工作台概览）
     * 修改：显示所有预警统计（不再按咨询师过滤）
     */
    private void handleStatistics(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        // 统计所有预警记录，让每个咨询师都能看到全局情况
        Map<String, Object> levelDist = alertDao.countByLevel(null);
        Map<String, Object> data = new HashMap<>();
        data.put("levelDistribution", levelDist);
        JsonUtil.writeSuccess(resp, data);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();

        if ("/handle".equals(pathInfo)) {
            handleAlert(req, resp);              // 处理预警（录入干预记录）
        } else if ("/resolve".equals(pathInfo)) {
            resolveAlert(req, resp);             // 解决预警
        }
    }

    /**
     * 管理员查看预警列表
     */
    private void handleList(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        String pageStr = req.getParameter("page");
        String level = req.getParameter("level");       // 筛选级别
        String status = req.getParameter("status");     // 筛选状态
        String keyword = req.getParameter("keyword");     // 搜索学生姓名/学号

        int page = 1;
        try { page = Integer.parseInt(pageStr); } catch (Exception e) {}

        if (level == null) level = "ALL";
        if (status == null) status = "ALL";

        java.util.List<AlertRecord> alerts = alertDao.findList(page, 10, level, status, null, keyword);
        JsonUtil.writeSuccess(resp, alerts);

    }

    /**
     * 咨询师查看名下预警
     * 修改：显示所有预警记录（不再按当前咨询师过滤），实现"每个老师都要看见"
     */
    private void handleCounselorList(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String pageStr = req.getParameter("page");
        String level = req.getParameter("level");       // 筛选级别
        String status = req.getParameter("status");     // 筛选状态
        String keyword = req.getParameter("keyword");     // 搜索学生姓名/学号

        int page = 1;
        try { page = Integer.parseInt(pageStr); } catch (Exception e) {}

        if (level == null) level = "ALL";
        if (status == null) status = "ALL";

        // 传入null表示不按咨询师ID过滤，返回所有预警记录
        java.util.List<AlertRecord> allAlerts = alertDao.findList(page, 10, level, status, null, keyword);
        JsonUtil.writeSuccess(resp, allAlerts);
    }

    /**
     * 查看预警详情
     */
    private void handleDetail(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.isEmpty()) {
            JsonUtil.writeError(resp, "请指定预警记录");
            return;
        }

        AlertRecord alert = alertDao.findById(Long.parseLong(idStr));
        if (alert == null) {
            JsonUtil.writeError(resp, "记录不存在");
            return;
        }

        JsonUtil.writeSuccess(resp, alert);
    }

    /**
     * 处理预警（录入干预跟进记录）
     */
    private void handleAlert(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");

        String idStr = req.getParameter("id");
        String status = req.getParameter("status");           // 新状态
        String interventionRecord = req.getParameter("record");// 干预记录
        String appointmentDate = req.getParameter("appointmentDate"); // 咨询日期
        String timeSlot = req.getParameter("timeSlot");             // 咨询时段

        if (idStr == null || idStr.isEmpty()) {
            JsonUtil.writeParamError(resp, "请指定预警记录");
            return;
        }

        Long alertId = Long.parseLong(idStr);

        // 管理员只需记录干预信息，不强制预约排班
        if (user != null && user.isAdmin()) {
            boolean success = alertDao.updateStatus(
                alertId,
                status,
                interventionRecord,
                null,
                user.getId()
            );
            if (success) {
                LogHelper.logAlertHandle(req, user, "预警记录#" + idStr, status + " - " +
                        (interventionRecord != null ? interventionRecord.substring(0, Math.min(interventionRecord.length(), 50)) : ""));
                JsonUtil.writeSuccess(resp, "处理成功");
            } else {
                JsonUtil.writeError(resp, "处理失败");
            }
            return;
        }

        // 咨询师/辅导员必须选择预约时段
        if (appointmentDate == null || appointmentDate.isEmpty() ||
                timeSlot == null || timeSlot.isEmpty()) {
            JsonUtil.writeParamError(resp, "请选择预约咨询日期和时段");
            return;
        }

        java.sql.Date aptDate;
        try {
            aptDate = java.sql.Date.valueOf(appointmentDate);
        } catch (IllegalArgumentException e) {
            JsonUtil.writeParamError(resp, "预约日期格式不正确");
            return;
        }
        String slot = timeSlot.trim();

        // 先预约排班时段：必须已排班且可预约，否则拒绝处理预警
        Integer scheduleId = scheduleDao.bookAvailableSlot(user.getId(), aptDate, slot);
        if (scheduleId == null) {
            Map<String, Object> slotInfo = scheduleDao.findSlot(user.getId(), aptDate, slot);
            String msg;
            if (slotInfo == null) {
                msg = "所选日期时段未在排班表中设置，请先设置排班";
            } else if (!"AVAILABLE".equals(slotInfo.get("status"))) {
                msg = "所选时段为休息状态，不可预约";
            } else {
                msg = "所选时段预约已满，请选择其他时间";
            }
            JsonUtil.writeError(resp, msg);
            return;
        }

        boolean success = alertDao.updateStatus(
            alertId,
            status,
            interventionRecord,
            null,
            user.getId()
        );

        if (success) {
            // 同步生成/更新学生的咨询预约（使用咨询师选择的日期时段）
            AlertRecord alert = alertDao.findById(alertId);
            Long appointmentId = null;
            if (alert != null && alert.getStudentId() != null) {
                appointmentId = createOrUpdateConsultationFromAlert(user, alert, interventionRecord,
                        aptDate, slot, scheduleId);
                if (appointmentId == null || appointmentId <= 0) {
                    // 预约生成失败时释放已占用的排班名额
                    scheduleDao.releaseSlot(scheduleId);
                    JsonUtil.writeError(resp, "预约生成失败，请重试");
                    return;
                }
                // 将预约关联到预警记录
                alertDao.updateAppointmentId(alertId, appointmentId, user.getId());

                // 发送通知给学生：包含干预记录和预约时间
                try {
                    String msgContent = "咨询师为您安排了咨询预约：" + appointmentDate + " " + slot +
                            "。\n\n干预记录：" + (interventionRecord != null ? interventionRecord : "") +
                            "\n\n请点击“确认”或“申请改期”进行反馈。";
                    sendNotification(user.getId(), alert.getStudentId(),
                            "预警处理：咨询预约待确认", msgContent,
                            "APPOINTMENT_CHANGE", appointmentId);
                } catch (Exception e) {
                    e.printStackTrace(); // 通知失败不影响主流程
                }
            }

            // 记录预警处理日志
            LogHelper.logAlertHandle(req, user, "预警记录#" + idStr, status + " - " +
                    (interventionRecord != null ? interventionRecord.substring(0, Math.min(interventionRecord.length(), 50)) : ""));
            JsonUtil.writeSuccess(resp, "处理成功");
        } else {

            // 预警状态更新失败时释放排班名额
            scheduleDao.releaseSlot(scheduleId);
            JsonUtil.writeError(resp, "处理失败");
        }
    }


    /**
     * 根据预警生成或更新对应的咨询谈话记录
     * 同时把预约与排班表关联，占用排班名额
     * 生成的预约初始状态为 PENDING，等待学生确认
     *
     * @return 成功返回预约ID，失败返回 null
     */
    private Long createOrUpdateConsultationFromAlert(User user, AlertRecord alert,
            String interventionRecord, java.sql.Date aptDate, String timeSlot, int scheduleId) {
        try {
            Integer studentId = alert.getStudentId();

            // 1. 查找学生与该咨询师最新有效的预约
            Appointment appointment = appointmentDao.findLatestByStudentAndCounselor(
                    alert.getStudentId(), user.getId());
            Long appointmentId;

            if (appointment == null) {
                // 2. 没有有效预约时，创建由咨询师发起的待学生确认预约
                Appointment newApt = new Appointment();
                newApt.setStudentId(studentId);
                newApt.setCounselorId(user.getId());
                newApt.setScheduleId(scheduleId);
                newApt.setAppointmentDate(aptDate);
                newApt.setTimeSlot(timeSlot);
                newApt.setConsultationTopic("预警干预咨询：" +
                        (alert.getTriggerReason() != null ? alert.getTriggerReason() : ""));
                appointmentId = appointmentDao.addWithStatus(newApt, "PENDING");
            } else {
                // 3. 已有有效预约：更新为咨询师新选择的时间，并重新等待学生确认
                Integer oldScheduleId = appointment.getScheduleId();
                if (oldScheduleId != null && oldScheduleId.equals(scheduleId)) {
                    scheduleDao.releaseSlot(scheduleId);
                } else if (oldScheduleId != null) {
                    scheduleDao.releaseSlot(oldScheduleId);
                }
                scheduleDao.updateAppointmentSlot(appointment.getId(), scheduleId, aptDate, timeSlot);
                appointmentId = appointment.getId();
            }

            if (appointmentId == null || appointmentId <= 0) {
                System.err.println("[AlertHandle] 创建或获取预约失败，无法生成咨询记录");
                return null;
            }

            // 4. 查找是否已有该预约对应的咨询记录
            ConsultationRecord record = consultationRecordDao.findByAppointmentId(appointmentId);
            Date now = new Date();
            if (record == null) {
                record = new ConsultationRecord();
                record.setAppointmentId(appointmentId);
                record.setStudentId(studentId);
                record.setCounselorId(user.getId());
                record.setStatus("ONGOING");
            }
            record.setCheckInTime(now);
            record.setStartTime(now);
            record.setSummaryText(interventionRecord);
            record.setAssessment("预警等级：" + alert.getAlertLevel() +
                    "；触发原因：" + (alert.getTriggerReason() != null ? alert.getTriggerReason() : ""));
            consultationRecordDao.addOrUpdate(record);

            return appointmentId;
        } catch (Exception e) {
            System.err.println("[AlertHandle] 生成咨询谈话记录失败: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }





    /**
     * 解决预警
     */
    private void resolveAlert(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");

        String idStr = req.getParameter("id");
        String result = req.getParameter("result");  // 解决结果说明

        if (idStr == null || idStr.isEmpty()) {
            JsonUtil.writeParamError(resp, "参数不完整");
            return;
        }

        boolean success = alertDao.updateStatus(
            Long.parseLong(idStr),
            "RESOLVED",
            null,
            result,
            user.getId()
        );

        if (success) {
            // 记录预警解决日志
            LogHelper.logAlertHandle(req, user, "预警记录#" + idStr, "已解决 - " +
                    (result != null ? result.substring(0, Math.min(result.length(), 50)) : ""));
            JsonUtil.writeSuccess(resp, "预警已解决");
        } else {
            JsonUtil.writeError(resp, "操作失败");
        }
    }

    /**
     * 发送站内通知
     */
    private void sendNotification(Integer fromUserId, Integer toUserId,
                                    String title, String content, String type, Long relatedId) {
        Notification notification = new Notification();
        notification.setReceiverId(toUserId);
        notification.setSenderId(fromUserId);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setType(type);
        notification.setRelatedType(type.replace("_", ""));
        notification.setRelatedId(relatedId);
        notificationDao.add(notification);
    }
}
