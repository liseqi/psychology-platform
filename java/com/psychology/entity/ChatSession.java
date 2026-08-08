package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * AI树洞会话实体类
 */
public class ChatSession implements Serializable {
    private Long id;
    private Integer userId;           // 学生用户ID
    private String title;             // 会话标题(自动生成)
    private String emotionTags;       // AI识别的情绪标签(JSON)
    private Integer isHighRisk;       // 是否包含高风险内容
    private Integer alertTriggered;   // 是否已触发预警
    private Integer messageCount;     // 消息总数
    private Date createdAt;
    private Date updatedAt;

    public ChatSession() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getEmotionTags() { return emotionTags; }
    public void setEmotionTags(String emotionTags) { this.emotionTags = emotionTags; }

    public Integer getHighRisk() { return isHighRisk; }
    public void setHighRisk(Integer isHighRisk) { this.isHighRisk = isHighRisk; }

    public Integer getAlertTriggered() { return alertTriggered; }
    public void setAlertTriggered(Integer alertTriggered) { this.alertTriggered = alertTriggered; }

    public Integer getMessageCount() { return messageCount; }
    public void setMessageCount(Integer messageCount) { this.messageCount = messageCount; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }
}
