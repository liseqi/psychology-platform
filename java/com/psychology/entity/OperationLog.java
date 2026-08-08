package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 操作日志实体类（隐私审计核心）
 */
public class OperationLog implements Serializable {
    private Long id;
    private Integer operatorId;       // 操作人ID
    private String operatorName;      // 操作人姓名
    private String operatorRole;      // 操作人角色: STUDENT/COUNSELOR/ADMIN
    private String operationType;     // 操作类型: VIEW_SENSITIVE_DATA/EXPORT_SENSITIVE_DATA等
    private String targetType;        // 目标数据类型: ASSESSMENT_RECORD/STUDENT_INFO等
    private Long targetId;            // 目标数据ID
    private String targetDescription; // 目标描述（脱敏后）
    private String detail;            // 操作详情(JSON)
    private String ipAddress;         // 操作IP
    private String userAgent;         // 浏览器UA
    private Date createdAt;           // 创建时间

    public OperationLog() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getOperatorId() { return operatorId; }
    public void setOperatorId(Integer operatorId) { this.operatorId = operatorId; }

    public String getOperatorName() { return operatorName; }
    public void setOperatorName(String operatorName) { this.operatorName = operatorName; }

    public String getOperatorRole() { return operatorRole; }
    public void setOperatorRole(String operatorRole) { this.operatorRole = operatorRole; }

    public String getOperationType() { return operationType; }
    public void setOperationType(String operationType) { this.operationType = operationType; }

    public String getTargetType() { return targetType; }
    public void setTargetType(String targetType) { this.targetType = targetType; }

    public Long getTargetId() { return targetId; }
    public void setTargetId(Long targetId) { this.targetId = targetId; }

    public String getTargetDescription() { return targetDescription; }
    public void setTargetDescription(String targetDescription) { this.targetDescription = targetDescription; }

    public String getDetail() { return detail; }
    public void setDetail(String detail) { this.detail = detail; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public String getUserAgent() { return userAgent; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
