package com.psychology.servlet;

import com.psychology.dao.AppointmentDao;
import com.psychology.dao.AppointmentReviewDao;
import com.psychology.dao.ConsultationRecordDao;
import com.psychology.dao.NotificationDao;
import com.psychology.dao.ScheduleDao;
import com.psychology.dao.UserDao;
import com.psychology.entity.*;
import com.psychology.util.CommonUtil;
import com.psychology.util.EncryptionUtil;
import com.psychology.util.JsonUtil;
import com.psychology.util.LogHelper;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.*;

/**
 * 预约咨询Servlet - 预约+签到+评价+改期取消
 */
@WebServlet("/appointment/*")
public class AppointmentServlet extends HttpServlet {

    private AppointmentDao appointmentDao = new AppointmentDao();
    private ConsultationRecordDao consultationRecordDao = new ConsultationRecordDao();
    private NotificationDao notificationDao = new NotificationDao();
    private ScheduleDao scheduleDao = new ScheduleDao();
    private UserDao userDao = new UserDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        User user = (User) req.getSession().getAttribute("currentUser");

        if ("/list".equals(pathInfo)) {
            handleList(req, resp, user);
        } else if ("/detail".equals(pathInfo)) {
            handleDetail(req, resp, user);
        } else if ("/counselor/list".equals(pathInfo)) {
            handleCounselorList(req, resp, user);
        } else if ("/student/available".equals(pathInfo)) {
            handleAvailableCounselors(req, resp, user);
        } else if ("/history".equals(pathInfo)) {
            handleHistory(req, resp, user); // 学生查看过往咨询记录
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        User user = (User) req.getSession().getAttribute("currentUser");

        if ("/create".equals(pathInfo)) {
            handleCreate(req, resp, user);           // 学生创建预约
        } else if ("/cancel".equals(pathInfo)) {
            handleCancel(req, resp, user);             // 取消预约
        } else if ("/reschedule".equals(pathInfo)) {
            handleReschedule(req, resp, user);          // 改期
        } else if ("/checkin".equals(pathInfo)) {
            handleCheckIn(req, resp, user);             // 咨询师签到
        } else if ("/reschedule-request".equals(pathInfo)) {
            handleRescheduleRequest(req, resp, user); // 学生申请改期，等待咨询师确认
        } else if ("/confirm-reschedule".equals(pathInfo)) {
            handleConfirmReschedule(req, resp, user); // 咨询师确认学生改期
        } else if ("/confirm".equals(pathInfo)) {
            handleConfirm(req, resp, user);             // 咨询师确认预约
        } else if ("/complete".equals(pathInfo)) {
            handleComplete(req, resp, user);            // 咨询完成归档
        } else if ("/review".equals(pathInfo)) {
            handleReview(req, resp, user);              // 学生评价
        }
    }

    /**
     * 学生查看自己的预约列表
     */
    private void handleList(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String status = req.getParameter("status");
        if (CommonUtil.isEmpty(status)) status = "ALL";

        List<Appointment> appointments = appointmentDao.findByStudent(user.getId(), status);
        JsonUtil.writeSuccess(resp, appointments);
    }

    /**
     * 咨询师查看排班下的预约列表
     */
    private void handleCounselorList(HttpServletRequest req, HttpServletResponse resp,
                                      User user) throws IOException {
        String status = req.getParameter("status");
        String dateStr = req.getParameter("date");

        if (CommonUtil.isEmpty(status)) status = "ALL";
        java.sql.Date date = null;
        if (CommonUtil.isNotEmpty(dateStr)) {
            date = java.sql.Date.valueOf(dateStr);
        }

        List<Appointment> appointments = appointmentDao.findByCounselor(
            user.getId(), status, date);

        // 对学生姓名做脱敏处理
        for (Appointment apt : appointments) {
            if (apt.getStudentName() != null) {
                apt.setStudentName(CommonUtil.maskName(apt.getStudentName()));
            }
        }

        JsonUtil.writeSuccess(resp, appointments);
    }

    /**
     * 获取可预约的咨询师列表（从 sys_user 查询 role=COUNSELOR）
     */
    private void handleAvailableCounselors(HttpServletRequest req, HttpServletResponse resp,
                                           User user) throws IOException {
        if (user == null) {
            resp.setStatus(401);
            JsonUtil.writeError(resp, "请先登录");
            return;
        }
        // 直接用 SQL 查咨询师
        java.util.List<Map<String, Object>> list = new java.util.ArrayList<>();
        try (java.sql.Connection conn = com.psychology.util.DBUtil.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(
                "SELECT id, real_name, department, email, phone FROM sys_user " +
                "WHERE role='COUNSELOR' AND status=1 ORDER BY id")) {
            java.sql.ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("id", rs.getInt("id"));
                item.put("name", rs.getString("real_name"));
                item.put("department", rs.getString("department"));
                item.put("email", rs.getString("email"));
                item.put("phone", rs.getString("phone"));
                list.add(item);
            }
        } catch (java.sql.SQLException e) {
            e.printStackTrace();
            JsonUtil.writeError(resp, "查询咨询师失败");
            return;
        }
        JsonUtil.writeSuccess(resp, list);
    }

    /**
     * 创建预约
     */
    private void handleCreate(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String counselorIdStr = req.getParameter("counselorId");
        String scheduleIdStr = req.getParameter("scheduleId");
        String appointmentDateStr = req.getParameter("appointmentDate");
        String timeSlot = req.getParameter("timeSlot");
        String topic = req.getParameter("consultationTopic");

        if (CommonUtil.isEmpty(counselorIdStr) || CommonUtil.isEmpty(appointmentDateStr)
                || CommonUtil.isEmpty(timeSlot)) {
            JsonUtil.writeError(resp, "请完整填写预约信息");
            return;
        }

        int counselorId;
        try {
            counselorId = Integer.parseInt(counselorIdStr);
        } catch (NumberFormatException e) {
            JsonUtil.writeError(resp, "咨询师ID不合法");
            return;
        }

        // 验证咨询师存在
        User counselor = userDao.findById(counselorId);
        if (counselor == null || !"COUNSELOR".equals(counselor.getRole())) {
            JsonUtil.writeError(resp, "咨询师不存在或不可预约");
            return;
        }

        // 检查该时段是否还有名额（scheduleId 可选）
        Integer scheduleId = null;
        if (CommonUtil.isNotEmpty(scheduleIdStr)) {
            try {
                scheduleId = Integer.parseInt(scheduleIdStr);
                if (!checkScheduleAvailability(scheduleId)) {
                    JsonUtil.writeError(resp, "该时段已满员，请选择其他时间");
                    return;
                }
            } catch (NumberFormatException e) {
                scheduleId = null;
            }
        }

        Appointment appointment = new Appointment();
        appointment.setStudentId(user.getId());
        appointment.setCounselorId(counselorId);
        appointment.setScheduleId(scheduleId);
        appointment.setAppointmentDate(java.sql.Date.valueOf(appointmentDateStr));
        appointment.setTimeSlot(timeSlot);
        appointment.setConsultationTopic(topic);

        long appointmentId;
        try {
            appointmentId = appointmentDao.add(appointment);
        } catch (RuntimeException e) {
            e.printStackTrace();
            JsonUtil.writeError(resp, "预约失败: " + e.getMessage());
            return;
        }

        if (appointmentId > 0) {
            // 扣减排班名额（如果有 scheduleId）
            if (scheduleId != null) {
                updateScheduleSlot(scheduleId, true);
            }

            // 发送通知给咨询师
            try {
                sendNotification(user.getId(), counselorId,
                    "新预约通知", "有学生预约了您的咨询服务，请及时确认",
                    "CONSULTATION_SCHEDULE", appointmentId);
            } catch (Exception e) {
                e.printStackTrace(); // 通知发送失败不影响主流程
            }

            // 记录预约创建日志
            try {
                LogHelper.log(req, user, "APPOINTMENT_CREATE", "APPOINTMENT",
                        user.getRealName() + " 预约了咨询师#" + counselorId +
                        (topic != null ? "，主题：" + topic : ""));
            } catch (Exception e) {
                e.printStackTrace(); // 日志记录失败不影响主流程
            }

            // 自动生成咨询谈话记录，便于咨询师跟进
            try {
                ConsultationRecord record = new ConsultationRecord();
                record.setAppointmentId(appointmentId);
                record.setStudentId(user.getId());
                record.setCounselorId(counselorId);
                record.setStatus("ONGOING");
                record.setSummaryText("学生已预约咨询，主题：" + (topic != null ? topic : ""));
                record.setAssessment("待咨询");
                record.setIsEncrypted(0);
                consultationRecordDao.addOrUpdate(record);
            } catch (Exception e) {
                System.err.println("[AppointmentCreate] 生成咨询记录失败: " + e.getMessage());
                e.printStackTrace(); // 不影响主流程
            }

            Map<String, Object> result = new HashMap<>();
            result.put("appointmentId", appointmentId);
            result.put("message", "预约成功，请准时参加");
            JsonUtil.writeSuccess(resp, result);
        } else {
            JsonUtil.writeError(resp, "预约写入返回0，请检查数据库表结构（appointment表是否存在、id是否自增）");
        }
    }

    /**
     * 学生取消预约
     */
    private void handleCancel(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String appointmentIdStr = req.getParameter("appointmentId");
        String reason = req.getParameter("reason");

        if (CommonUtil.isEmpty(appointmentIdStr)) {
            JsonUtil.writeParamError(resp, "请指定要取消的预约");
            return;
        }

        Long appointmentId = Long.parseLong(appointmentIdStr);
        Appointment appointment = appointmentDao.findById(appointmentId);

        // 权限检查：只能取消自己的预约
        if (appointment == null || !appointment.getStudentId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }

        // 检查是否可以取消（开始前才能取消）
        if (isAppointmentStarted(appointment)) {
            JsonUtil.writeError(resp, "咨询已开始，无法取消。如需改期请联系咨询师");
            return;
        }

        boolean success = appointmentDao.cancelOrReschedule(
            appointmentId, "CANCELLED", reason, user.getId(), null);

        if (success) {
            // 同步取消对应的咨询谈话记录
            try {
                ConsultationRecord record = consultationRecordDao.findByAppointmentId(appointmentId);
                if (record != null) {
                    record.setStatus("CANCELLED");
                    consultationRecordDao.addOrUpdate(record);
                }
            } catch (Exception e) {
                System.err.println("[AppointmentCancel] 取消咨询记录失败: " + e.getMessage());
                e.printStackTrace();
            }

            // 记录取消预约日志
            LogHelper.log(req, user, "APPOINTMENT_CANCEL", "APPOINTMENT",
                    user.getRealName() + " 取消了预约#" + appointmentId +
                    (reason != null ? "，原因：" + reason : ""));

            // 发送取消通知
            sendNotification(user.getId(), appointment.getCounselorId(),
                "预约已取消", "学生取消了预约: " + reason,
                "APPOINTMENT_CHANGE", appointmentId);

            JsonUtil.writeSuccess(resp, "预约已取消，名额已释放");
        } else {
            JsonUtil.writeError(resp, "操作失败");
        }
    }

    /**
     * 改期预约
     */
    private void handleReschedule(HttpServletRequest req, HttpServletResponse resp, 
                                   User user) throws IOException {
        String appointmentIdStr = req.getParameter("appointmentId");
        String newScheduleIdStr = req.getParameter("newScheduleId");
        String newDateStr = req.getParameter("newDate");
        String newTimeSlot = req.getParameter("newTimeSlot");
        String reason = req.getParameter("reason");

        if (CommonUtil.isEmpty(appointmentIdStr) || CommonUtil.isEmpty(newScheduleIdStr)) {
            JsonUtil.writeParamError(resp, "参数不完整");
            return;
        }

        Long oldAppointmentId = Long.parseLong(appointmentIdStr);
        Appointment oldAppointment = appointmentDao.findById(oldAppointmentId);

        if (oldAppointment == null || !oldAppointment.getStudentId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }

        if (isAppointmentStarted(oldAppointment)) {
            JsonUtil.writeError(resp, "咨询已开始，无法改期");
            return;
        }

        // 将原预约标记为RESCHEDULED，同时创建新的预约记录
        boolean success = appointmentDao.cancelOrReschedule(
            oldAppointmentId, "RESCHEDULED", reason, user.getId(), null);

        if (success) {
            // 创建新预约
            Appointment newAppointment = new Appointment();
            newAppointment.setStudentId(user.getId());
            newAppointment.setCounselorId(oldAppointment.getCounselorId());
            newAppointment.setScheduleId(Integer.parseInt(newScheduleIdStr));
            newAppointment.setAppointmentDate(java.sql.Date.valueOf(newDateStr));
            newAppointment.setTimeSlot(newTimeSlot);
            newAppointment.setConsultationTopic(oldAppointment.getConsultationTopic());
            newAppointment.setRescheduleFromId(oldAppointmentId);

            long newAppointmentId;
            try {
                newAppointmentId = appointmentDao.add(newAppointment);
            } catch (RuntimeException e) {
                e.printStackTrace();
                JsonUtil.writeError(resp, "改期失败: " + e.getMessage());
                return;
            }

            // 发送改期通知
            try {
                sendNotification(user.getId(), oldAppointment.getCounselorId(),
                    "预约改期通知", "学生将原预约改期为 " + newDateStr + " " + newTimeSlot,
                    "APPOINTMENT_CHANGE", newAppointmentId);
            } catch (Exception e) {
                e.printStackTrace();
            }

            JsonUtil.writeSuccess(resp, "改期成功");
        } else {
            JsonUtil.writeError(resp, "改期失败，请稍后重试");
        }
    }

    /**
     * 确认预约：学生确认 PENDING 预约，或咨询师确认 PENDING 预约
     */
    private void handleConfirm(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String appointmentIdStr = req.getParameter("appointmentId");

        if (CommonUtil.isEmpty(appointmentIdStr)) {
            JsonUtil.writeParamError(resp, "请指定预约");
            return;
        }

        Long appointmentId = Long.parseLong(appointmentIdStr);
        Appointment appointment = appointmentDao.findById(appointmentId);

        if (appointment == null) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }

        boolean isStudent = user.isStudent();
        boolean isCounselor = user.isCounselor();

        if (isStudent && !appointment.getStudentId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }
        if (isCounselor && !appointment.getCounselorId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }

        if (!"PENDING".equals(appointment.getStatus())) {
            JsonUtil.writeError(resp, "只有待确认状态的预约才能确认");
            return;
        }

        boolean success;
        if (isStudent) {
            success = appointmentDao.confirmByStudent(appointmentId);
        } else {
            success = appointmentDao.confirm(appointmentId);
        }

        if (success) {
            // 发送通知给对方
            Integer toUserId = isStudent ? appointment.getCounselorId() : appointment.getStudentId();
            sendNotification(user.getId(), toUserId,
                    "预约已确认", "预约 " + appointment.getAppointmentDate() + " " + appointment.getTimeSlot() + " 已确认。",
                    "APPOINTMENT_CHANGE", appointmentId);

            // 记录日志
            try {
                LogHelper.log(req, user, "APPOINTMENT_CONFIRM", "APPOINTMENT",
                        user.getRealName() + " 确认了预约#" + appointmentId);
            } catch (Exception e) {
                e.printStackTrace();
            }

            JsonUtil.writeSuccess(resp, "预约已确认");
        } else {
            JsonUtil.writeError(resp, "确认失败");
        }
    }


    /**
     * 学生申请改期（等待咨询师确认）
     */
    private void handleRescheduleRequest(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String appointmentIdStr = req.getParameter("appointmentId");
        String newDateStr = req.getParameter("newDate");
        String newTimeSlot = req.getParameter("newTimeSlot");
        String reason = req.getParameter("reason");

        if (CommonUtil.isEmpty(appointmentIdStr) || CommonUtil.isEmpty(newDateStr)
                || CommonUtil.isEmpty(newTimeSlot)) {
            JsonUtil.writeParamError(resp, "请完整填写改期信息");
            return;
        }

        Long appointmentId = Long.parseLong(appointmentIdStr);
        Appointment appointment = appointmentDao.findById(appointmentId);

        if (appointment == null || !appointment.getStudentId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }

        if (isAppointmentStarted(appointment)) {
            JsonUtil.writeError(resp, "咨询已开始，无法改期");
            return;
        }

        if (!"PENDING".equals(appointment.getStatus())) {
            JsonUtil.writeError(resp, "只有待确认状态的预约可以申请改期");
            return;
        }

        java.sql.Date newDate;
        try {
            newDate = java.sql.Date.valueOf(newDateStr);
        } catch (IllegalArgumentException e) {
            JsonUtil.writeParamError(resp, "改期日期格式不正确");
            return;
        }

        boolean success = appointmentDao.requestReschedule(
                appointmentId, reason, newDate, newTimeSlot);

        if (success) {
            sendNotification(user.getId(), appointment.getCounselorId(),
                    "学生申请改期", "学生申请将预约改期至 " + newDateStr + " " + newTimeSlot +
                            (reason != null ? "，原因：" + reason : "") + "，请确认。",
                    "APPOINTMENT_CHANGE", appointmentId);
            JsonUtil.writeSuccess(resp, "改期申请已提交，等待咨询师确认");
        } else {
            JsonUtil.writeError(resp, "改期申请失败");
        }
    }

    /**
     * 咨询师确认学生改期申请
     */
    private void handleConfirmReschedule(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String appointmentIdStr = req.getParameter("appointmentId");
        String newDateStr = req.getParameter("newDate");
        String newTimeSlot = req.getParameter("newTimeSlot");

        if (CommonUtil.isEmpty(appointmentIdStr) || CommonUtil.isEmpty(newDateStr)
                || CommonUtil.isEmpty(newTimeSlot)) {
            JsonUtil.writeParamError(resp, "请完整填写改期信息");
            return;
        }

        Long appointmentId = Long.parseLong(appointmentIdStr);
        Appointment appointment = appointmentDao.findById(appointmentId);

        if (appointment == null || !appointment.getCounselorId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }

        if (!"RESCHEDULE_REQUESTED".equals(appointment.getStudentConfirmationStatus())) {
            JsonUtil.writeError(resp, "该预约没有待确认的改期申请");
            return;
        }

        java.sql.Date newDate;
        try {
            String d = newDateStr.length() > 10 ? newDateStr.substring(0, 10) : newDateStr;
            newDate = java.sql.Date.valueOf(d);
        } catch (IllegalArgumentException e) {
            JsonUtil.writeParamError(resp, "改期日期格式不正确");
            return;
        }

        // 检查咨询师选择的新时段是否可预约（优先查找已有排班）
        Integer scheduleId = scheduleDao.bookAvailableSlot(user.getId(), newDate, newTimeSlot);
        if (scheduleId == null) {
            JsonUtil.writeError(resp, "所选时段不可预约，请重新选择");
            return;
        }

        // 释放旧排班名额
        if (appointment.getScheduleId() != null) {
            scheduleDao.releaseSlot(appointment.getScheduleId());
        }

        boolean success = appointmentDao.confirmReschedule(appointmentId, scheduleId, newDate, newTimeSlot);

        if (success) {
            sendNotification(user.getId(), appointment.getStudentId(),
                    "改期已确认", "您的改期申请已确认，新预约时间为 " + newDateStr + " " + newTimeSlot,
                    "APPOINTMENT_CHANGE", appointmentId);
            JsonUtil.writeSuccess(resp, "改期已确认");
        } else {
            scheduleDao.releaseSlot(scheduleId);
            JsonUtil.writeError(resp, "改期确认失败");
        }
    }

    /**
     * 咨询师签到
     */

    private void handleCheckIn(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String appointmentIdStr = req.getParameter("appointmentId");

        if (CommonUtil.isEmpty(appointmentIdStr)) {
            JsonUtil.writeParamError(resp, "请指定预约");
            return;
        }

        Long appointmentId = Long.parseLong(appointmentIdStr);
        Appointment appointment = appointmentDao.findById(appointmentId);

        if (appointment == null || !appointment.getCounselorId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }

        // 创建或更新咨询记录并签到
        boolean success;
        ConsultationRecord existingRecord = consultationRecordDao.findByAppointmentId(appointmentId);
        if (existingRecord != null) {
            existingRecord.setCheckInTime(new Date());
            existingRecord.setStartTime(new Date());
            existingRecord.setIsEncrypted(1);
            success = consultationRecordDao.addOrUpdate(existingRecord);
        } else {
            ConsultationRecord record = new ConsultationRecord();
            record.setAppointmentId(appointmentId);
            record.setStudentId(appointment.getStudentId());
            record.setCounselorId(user.getId());
            record.setCheckInTime(new Date());
            record.setEncrypted(1); // 默认加密存储
            success = consultationRecordDao.addOrUpdate(record);
        }

        if (success) {
            JsonUtil.writeSuccess(resp, "签到成功");
        } else {
            JsonUtil.writeError(resp, "签到失败");
        }
    }

    /**
     * 咨询完成归档（填写复盘笔记）
     */
    private void handleComplete(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String appointmentIdStr = req.getParameter("appointmentId");
        String summaryText = req.getParameter("summaryText");    // 复盘笔记
        String assessment = req.getParameter("assessment");        // 初步评估
        String followUpPlan = req.getParameter("followUpPlan");    // 跟进计划

        if (CommonUtil.isEmpty(appointmentIdStr)) {
            JsonUtil.writeParamError(resp, "请指定预约");
            return;
        }

        Long appointmentId = Long.parseLong(appointmentIdStr);
        Appointment appointment = appointmentDao.findById(appointmentId);

        if (appointment == null || !appointment.getCounselorId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权操作此预约");
            return;
        }

        // 更新咨询记录（加密存储敏感内容）
        ConsultationRecord existingRecord = consultationRecordDao.findByAppointmentId(appointmentId);
        if (existingRecord != null) {
            existingRecord.setEndTime(new Date());
            existingRecord.setSummaryText(EncryptionUtil.encrypt(summaryText)); // 加密
            existingRecord.setAssessment(EncryptionUtil.encrypt(assessment));    // 加密
            existingRecord.setFollowUpPlan(followUpPlan);                       // 可选加密
            existingRecord.setStatus("COMPLETED");
            existingRecord.setIsEncrypted(1);
            consultationRecordDao.addOrUpdate(existingRecord);
        } else {
            ConsultationRecord record = new ConsultationRecord();
            record.setAppointmentId(appointmentId);
            record.setStudentId(appointment.getStudentId());
            record.setCounselorId(user.getId());
            record.setEndTime(new Date());
            record.setSummaryText(EncryptionUtil.encrypt(summaryText)); // 加密
            record.setAssessment(EncryptionUtil.encrypt(assessment));    // 加密
            record.setFollowUpPlan(followUpPlan);                       // 可选加密
            record.setStatus("COMPLETED");
            record.setIsEncrypted(1);
            consultationRecordDao.addOrUpdate(record);
        }

        // 标记预约完成
        appointmentDao.markCompleted(appointmentId);

        JsonUtil.writeSuccess(resp, "咨询归档成功");
    }

    /**
     * 学生评价咨询
     */
    private void handleReview(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String appointmentIdStr = req.getParameter("appointmentId");
        String ratingStr = req.getParameter("rating");
        String feedbackContent = req.getParameter("feedbackContent");
        String isAnonymousStr = req.getParameter("isAnonymous");

        if (CommonUtil.isEmpty(appointmentIdStr) || CommonUtil.isEmpty(ratingStr)) {
            JsonUtil.writeParamError(resp, "请填写评分");
            return;
        }

        Long appointmentId = Long.parseLong(appointmentIdStr);
        Appointment appointment = appointmentDao.findById(appointmentId);

        if (appointment == null || !appointment.getStudentId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权评价此预约");
            return;
        }

        // 只有已完成的咨询才能评价
        if (!"COMPLETED".equals(appointment.getStatus())) {
            JsonUtil.writeError(resp, "只有已完成的咨询才能评价");
            return;
        }

        // 检查是否已评价过
        AppointmentReviewDao reviewDao = new AppointmentReviewDao();
        if (reviewDao.findByAppointmentId(appointmentId) != null) {
            JsonUtil.writeError(resp, "您已经评价过了");
            return;
        }

        AppointmentReview review = new AppointmentReview();
        review.setAppointmentId(appointmentId);
        review.setStudentId(user.getId());
        review.setCounselorId(appointment.getCounselorId());
        review.setRating(Integer.parseInt(ratingStr));
        review.setFeedbackContent(feedbackContent);
        review.setAnonymous("true".equals(isAnonymousStr) ? 1 : 0);

        boolean success = reviewDao.add(review);

        if (success) {
            JsonUtil.writeSuccess(resp, "评价提交成功，感谢您的反馈");
        } else {
            JsonUtil.writeError(resp, "评价提交失败");
        }
    }

    /**
     * 学生查看历史咨询记录（脱敏展示）
     */
    private void handleHistory(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        List<ConsultationRecord> records = consultationRecordDao.findByStudent(
            user.getId(), 1, 100);

        // 脱敏展示（只显示基本信息，不显示详细笔记内容给学生看）
        List<Map<String, Object>> result = new ArrayList<>();
        for (ConsultationRecord record : records) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", record.getId());
            item.put("appointmentDate", CommonUtil.formatDate(record.getCreatedAt(), "yyyy-MM-dd"));
            item.put("consultantName", ""); // 可以查询咨询师名称
            item.put("status", "completed");
            // 不返回summaryText等敏感内容
            result.add(item);
        }

        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 查看预约详情
     */
    private void handleDetail(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String idStr = req.getParameter("id");
        if (CommonUtil.isEmpty(idStr)) {
            JsonUtil.writeError(resp, "参数不完整");
            return;
        }

        Appointment appointment = appointmentDao.findById(Long.parseLong(idStr));
        if (appointment == null) {
            JsonUtil.writeError(resp, "预约不存在");
            return;
        }

        // 权限检查与脱敏
        if (user.isStudent() && !appointment.getStudentId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权查看");
            return;
        }

        if (user.isCounselor() && appointment.getStudentName() != null) {
            appointment.setStudentName(CommonUtil.maskName(appointment.getStudentName()));
        }

        JsonUtil.writeSuccess(resp, appointment);
    }

    /**
     * 检查排班是否有空余名额
     */
    private boolean checkScheduleAvailability(Integer scheduleId) {
        if (scheduleId == null) return true; // 没有 scheduleId 直接通过
        // 简化实现：没有排班表数据时直接通过，避免阻塞预约
        try (java.sql.Connection conn = com.psychology.util.DBUtil.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(
                "SELECT current_appointments, max_appointments FROM counselor_schedule WHERE id=? AND status='AVAILABLE'")) {
            ps.setInt(1, scheduleId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int current = rs.getInt("current_appointments");
                    int max = rs.getInt("max_appointments");
                    return current < max;
                }
                return true; // 排班不存在时也通过
            }
        } catch (java.sql.SQLException e) {
            e.printStackTrace();
            return true;
        }
    }

    /**
     * 更新排班名额
     */
    private void updateScheduleSlot(Integer scheduleId, boolean increment) {
        if (scheduleId == null) return; // 没有 scheduleId 直接跳过
        String sql = increment
            ? "UPDATE counselor_schedule SET current_appointments = current_appointments + 1 " +
              "WHERE id=? AND current_appointments < max_appointments"
            : "UPDATE counselor_schedule SET current_appointments = GREATEST(0, current_appointments - 1) WHERE id=?";
        try (java.sql.Connection conn = com.psychology.util.DBUtil.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, scheduleId);
            ps.executeUpdate();
        } catch (java.sql.SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * 判断预约是否已经开始
     */
    private boolean isAppointmentStarted(Appointment appointment) {
        if (appointment.getAppointmentDate() == null) return false;
        java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
        return appointment.getAppointmentDate().before(today) || 
               appointment.getAppointmentDate().equals(today);
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
