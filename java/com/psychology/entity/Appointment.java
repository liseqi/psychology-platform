package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 咨询预约实体类
 */
public class Appointment implements Serializable {
    private Long id;
    private Integer studentId;       // 学生ID
    private Integer counselorId;     // 咨询师ID
    private Integer scheduleId;      // 关联排班ID
    private Date appointmentDate;    // 预约日期
    private String timeSlot;         // 预约时段
    private String status;           // 状态: PENDING/CONFIRMED/COMPLETED/CANCELLED/NO_SHOW/RESCHEDULED
    private String consultationTopic;// 咨询主题
    private String cancelReason;     // 取消原因
    private Integer cancelledBy;     // 取消操作人ID
    private Date cancelTime;         // 取消时间
    private Long rescheduleFromId;   // 原预约记录ID(改期时)
    private String studentConfirmationStatus; // 学生确认状态: WAITING/CONFIRMED/RESCHEDULE_REQUESTED
    private Date studentConfirmedAt;            // 学生确认时间
    private String studentRescheduleReason;   // 学生申请改期原因
    private Date studentRescheduleDate;       // 学生期望改期日期
    private String studentRescheduleTimeSlot; // 学生期望改期时段
    private Date createdAt;
    private Date updatedAt;
    
    // 非数据库字段
    private String studentName;      // 学生姓名(脱敏)
    private String counselorName;    // 咨询师姓名

    public Appointment() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getStudentId() { return studentId; }
    public void setStudentId(Integer studentId) { this.studentId = studentId; }

    public Integer getCounselorId() { return counselorId; }
    public void setCounselorId(Integer counselorId) { this.counselorId = counselorId; }

    public Integer getScheduleId() { return scheduleId; }
    public void setScheduleId(Integer scheduleId) { this.scheduleId = scheduleId; }

    public Date getAppointmentDate() { return appointmentDate; }
    public void setAppointmentDate(Date appointmentDate) { this.appointmentDate = appointmentDate; }

    public String getTimeSlot() { return timeSlot; }
    public void setTimeSlot(String timeSlot) { this.timeSlot = timeSlot; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getConsultationTopic() { return consultationTopic; }
    public void setConsultationTopic(String consultationTopic) { this.consultationTopic = consultationTopic; }

    public String getCancelReason() { return cancelReason; }
    public void setCancelReason(String cancelReason) { this.cancelReason = cancelReason; }

    public Integer getCancelledBy() { return cancelledBy; }
    public void setCancelledBy(Integer cancelledBy) { this.cancelledBy = cancelledBy; }

    public Date getCancelTime() { return cancelTime; }
    public void setCancelTime(Date cancelTime) { this.cancelTime = cancelTime; }

    public Long getRescheduleFromId() { return rescheduleFromId; }
    public void setRescheduleFromId(Long rescheduleFromId) { this.rescheduleFromId = rescheduleFromId; }


    public String getStudentConfirmationStatus() { return studentConfirmationStatus; }
    public void setStudentConfirmationStatus(String studentConfirmationStatus) { this.studentConfirmationStatus = studentConfirmationStatus; }

    public Date getStudentConfirmedAt() { return studentConfirmedAt; }
    public void setStudentConfirmedAt(Date studentConfirmedAt) { this.studentConfirmedAt = studentConfirmedAt; }

    public String getStudentRescheduleReason() { return studentRescheduleReason; }
    public void setStudentRescheduleReason(String studentRescheduleReason) { this.studentRescheduleReason = studentRescheduleReason; }

    public Date getStudentRescheduleDate() { return studentRescheduleDate; }
    public void setStudentRescheduleDate(Date studentRescheduleDate) { this.studentRescheduleDate = studentRescheduleDate; }

    public String getStudentRescheduleTimeSlot() { return studentRescheduleTimeSlot; }
    public void setStudentRescheduleTimeSlot(String studentRescheduleTimeSlot) { this.studentRescheduleTimeSlot = studentRescheduleTimeSlot; }

    public Date getCreatedAt() { return createdAt; }

    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public String getCounselorName() { return counselorName; }
    public void setCounselorName(String counselorName) { this.counselorName = counselorName; }
}
