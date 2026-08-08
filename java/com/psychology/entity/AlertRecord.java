package com.psychology.entity;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

/**
 * 预警记录实体类 - 多级分流核心
 */
public class AlertRecord implements Serializable {
    private Long id;
    private Integer studentId;           // 预警学生ID
    private Long assessmentRecordId;     // 触发预警的测评记录ID
    private Long chatSessionId;          // 触发的树洞会话ID
    private String alertLevel;           // 预警级别: LOW/MEDIUM/HIGH
    private String alertType;            // 预警来源: ASSESSMENT/CHAT/MANUAL
    private String triggerReason;        // 触发原因描述
    private BigDecimal scoreValue;       // 触发分数值
    private String status;               // 处理状态: PENDING/PROCESSING/INTERVENING/RESOLVED/CLOSED
    private Integer assignedCounselorId; // 分配的咨询师ID
    private String assignedCounselorRole;// 分配对象角色(咨询师/辅导员)
    private String interventionRecord;   // 干预跟进记录
    private String interventionResult;   // 干预结果
    private Date resolvedAt;             // 解决时间
    private Integer resolvedBy;          // 解决操作人
    private Long appointmentId;          // 关联的预约ID
    private Date createdAt;
    private Date updatedAt;

    // 非数据库字段
    private String studentName;          // 学生姓名(脱敏)
    private Date appointmentDate;        // 关联预约日期
    private String appointmentTimeSlot;  // 关联预约时段
    private String appointmentStatus;    // 关联预约状态
    private String appointmentStudentConfirmationStatus; // 关联预约学生确认状态

    public AlertRecord() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getStudentId() { return studentId; }
    public void setStudentId(Integer studentId) { this.studentId = studentId; }

    public Long getAssessmentRecordId() { return assessmentRecordId; }
    public void setAssessmentRecordId(Long assessmentRecordId) { this.assessmentRecordId = assessmentRecordId; }

    public Long getChatSessionId() { return chatSessionId; }
    public void setChatSessionId(Long chatSessionId) { this.chatSessionId = chatSessionId; }

    public String getAlertLevel() { return alertLevel; }
    public void setAlertLevel(String alertLevel) { this.alertLevel = alertLevel; }

    public String getAlertType() { return alertType; }
    public void setAlertType(String alertType) { this.alertType = alertType; }

    public String getTriggerReason() { return triggerReason; }
    public void setTriggerReason(String triggerReason) { this.triggerReason = triggerReason; }

    public BigDecimal getScoreValue() { return scoreValue; }
    public void setScoreValue(BigDecimal scoreValue) { this.scoreValue = scoreValue; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getAssignedCounselorId() { return assignedCounselorId; }
    public void setAssignedCounselorId(Integer assignedCounselorId) { this.assignedCounselorId = assignedCounselorId; }

    public String getAssignedCounselorRole() { return assignedCounselorRole; }
    public void setAssignedCounselorRole(String assignedCounselorRole) { this.assignedCounselorRole = assignedCounselorRole; }

    public String getInterventionRecord() { return interventionRecord; }
    public void setInterventionRecord(String interventionRecord) { this.interventionRecord = interventionRecord; }

    public String getInterventionResult() { return interventionResult; }
    public void setInterventionResult(String interventionResult) { this.interventionResult = interventionResult; }

    public Date getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(Date resolvedAt) { this.resolvedAt = resolvedAt; }

    public Integer getResolvedBy() { return resolvedBy; }
    public void setResolvedBy(Integer resolvedBy) { this.resolvedBy = resolvedBy; }

    public Long getAppointmentId() { return appointmentId; }
    public void setAppointmentId(Long appointmentId) { this.appointmentId = appointmentId; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }

    // 非数据库字段：关联预约信息
    public Date getAppointmentDate() { return appointmentDate; }
    public void setAppointmentDate(Date appointmentDate) { this.appointmentDate = appointmentDate; }

    public String getAppointmentTimeSlot() { return appointmentTimeSlot; }
    public void setAppointmentTimeSlot(String appointmentTimeSlot) { this.appointmentTimeSlot = appointmentTimeSlot; }

    public String getAppointmentStatus() { return appointmentStatus; }
    public void setAppointmentStatus(String appointmentStatus) { this.appointmentStatus = appointmentStatus; }

    public String getAppointmentStudentConfirmationStatus() { return appointmentStudentConfirmationStatus; }
    public void setAppointmentStudentConfirmationStatus(String appointmentStudentConfirmationStatus) { this.appointmentStudentConfirmationStatus = appointmentStudentConfirmationStatus; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }
}
