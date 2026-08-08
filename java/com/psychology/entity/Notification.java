package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 站内消息通知实体类
 */
public class Notification implements Serializable {
    private Long id;
    private Integer receiverId;       // 接收者ID
    private Integer senderId;         // 发送者ID(系统消息为NULL)
    private String title;             // 消息标题
    private String content;           // 消息内容
    private String type;              // 消息类型: APPOINTMENT_CHANGE/ALERT_REMINDER/CONSULTATION_SCHEDULE/SYSTEM/ASSESSMENT_RESULT/OTHER
    private Integer isRead;           // 是否已读:0未读,1已读
    private String relatedType;       // 关联业务类型
    private Long relatedId;           // 关联业务ID
    private Date createdAt;
    private Date readAt;              // 阅读时间

    public Notification() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getReceiverId() { return receiverId; }
    public void setReceiverId(Integer receiverId) { this.receiverId = receiverId; }

    public Integer getSenderId() { return senderId; }
    public void setSenderId(Integer senderId) { this.senderId = senderId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public Integer getRead() { return isRead; }
    public void setRead(Integer isRead) { this.isRead = isRead; }

    public String getRelatedType() { return relatedType; }
    public void setRelatedType(String relatedType) { this.relatedType = relatedType; }

    public Long getRelatedId() { return relatedId; }
    public void setRelatedId(Long relatedId) { this.relatedId = relatedId; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getReadAt() { return readAt; }
    public void setReadAt(Date readAt) { this.readAt = readAt; }
}
