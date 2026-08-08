package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 咨询评价实体类
 */
public class AppointmentReview implements Serializable {
    private Long id;
    private Long appointmentId;      // 预约ID(唯一)
    private Integer studentId;       // 评价学生ID
    private Integer counselorId;     // 被评价咨询师ID
    private Integer rating;          // 评分:1-5分
    private String feedbackContent;  // 反馈内容
    private Integer isAnonymous;     // 是否匿名:0实名,1匿名
    private Date createdAt;

    public AppointmentReview() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getAppointmentId() { return appointmentId; }
    public void setAppointmentId(Long appointmentId) { this.appointmentId = appointmentId; }

    public Integer getStudentId() { return studentId; }
    public void setStudentId(Integer studentId) { this.studentId = studentId; }

    public Integer getCounselorId() { return counselorId; }
    public void setCounselorId(Integer counselorId) { this.counselorId = counselorId; }

    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }

    public String getFeedbackContent() { return feedbackContent; }
    public void setFeedbackContent(String feedbackContent) { this.feedbackContent = feedbackContent; }

    public Integer getAnonymous() { return isAnonymous; }
    public void setAnonymous(Integer isAnonymous) { this.isAnonymous = isAnonymous; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
