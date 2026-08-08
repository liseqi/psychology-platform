package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * AI树洞消息实体
 */
public class ChatMessage implements Serializable {
    private Long id;
    private Long sessionId;      // 会话ID
    private String senderType;   // 发送者: USER/AI
    private String content;      // 消息内容
    private String emotionTag;   // 情绪标签
    private Integer encrypted;   // 是否加密
    private Date createdAt;

    public ChatMessage() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getSessionId() { return sessionId; }
    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }
    public String getSenderType() { return senderType; }
    public void setSenderType(String senderType) { this.senderType = senderType; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public String getEmotionTag() { return emotionTag; }
    public void setEmotionTag(String emotionTag) { this.emotionTag = emotionTag; }
    public Integer getEncrypted() { return encrypted; }
    public void setEncrypted(Integer encrypted) { this.encrypted = encrypted; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
