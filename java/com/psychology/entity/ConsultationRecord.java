package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 线下咨询记录实体类（签到+归档）
 */
public class ConsultationRecord implements Serializable {
    private Long id;
    private Long appointmentId;      // 关联预约ID
    private Integer studentId;       // 学生ID
    private Integer counselorId;     // 咨询师ID
    private Date checkInTime;        // 签到时间
    private Date startTime;          // 实际开始时间
    private Date endTime;            // 结束时间
    private String summaryText;      // 咨询复盘笔记(加密存储)
    private String assessment;       // 初步评估
    private String followUpPlan;     // 后续跟进计划
    private Integer isEncrypted;     // 是否已加密
    private String status;           // 记录状态: ONGOING/COMPLETED/CANCELLED
    private Date createdAt;
    private Date updatedAt;

    // --- 以下为非数据库字段，用于联表查询展示 ---
    private String studentName;      // 学生姓名
    private String counselorName;    // 咨询师姓名
    private Date appointmentDate;    // 预约日期
    private String timeSlot;         // 时段
    private String consultationTopic;// 咨询主题

    public ConsultationRecord() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getAppointmentId() { return appointmentId; }
    public void setAppointmentId(Long appointmentId) { this.appointmentId = appointmentId; }

    public Integer getStudentId() { return studentId; }
    public void setStudentId(Integer studentId) { this.studentId = studentId; }

    public Integer getCounselorId() { return counselorId; }
    public void setCounselorId(Integer counselorId) { this.counselorId = counselorId; }

    public Date getCheckInTime() { return checkInTime; }
    public void setCheckInTime(Date checkInTime) { this.checkInTime = checkInTime; }

    public Date getStartTime() { return startTime; }
    public void setStartTime(Date startTime) { this.startTime = startTime; }

    public Date getEndTime() { return endTime; }
    public void setEndTime(Date endTime) { this.endTime = endTime; }

    public String getSummaryText() { return summaryText; }
    public void setSummaryText(String summaryText) { this.summaryText = summaryText; }

    public String getAssessment() { return assessment; }
    public void setAssessment(String assessment) { this.assessment = assessment; }

    public String getFollowUpPlan() { return followUpPlan; }
    public void setFollowUpPlan(String followUpPlan) { this.followUpPlan = followUpPlan; }

    public Integer getEncrypted() { return isEncrypted; }
    public void setEncrypted(Integer isEncrypted) { this.isEncrypted = isEncrypted; }
    public Integer getIsEncrypted() { return isEncrypted; }
    public void setIsEncrypted(Integer isEncrypted) { this.isEncrypted = isEncrypted; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }

    // --- 非数据库字段 getter/setter ---
    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public String getCounselorName() { return counselorName; }
    public void setCounselorName(String counselorName) { this.counselorName = counselorName; }

    public Date getAppointmentDate() { return appointmentDate; }
    public void setAppointmentDate(Date appointmentDate) { this.appointmentDate = appointmentDate; }

    public String getTimeSlot() { return timeSlot; }
    public void setTimeSlot(String timeSlot) { this.timeSlot = timeSlot; }

    public String getConsultationTopic() { return consultationTopic; }
    public void setConsultationTopic(String consultationTopic) { this.consultationTopic = consultationTopic; }
}
