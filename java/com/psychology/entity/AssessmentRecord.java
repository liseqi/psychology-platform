package com.psychology.entity;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

/**
 * 测评记录实体类
 */
public class AssessmentRecord implements Serializable {
    private Long id;
    private Integer userId;           // 作答学生ID
    private Integer scaleId;          // 量表ID
    private Date startTime;           // 开始答题时间
    private Date endTime;             // 提交时间
    private Integer durationSeconds;  // 实际答题耗时(秒)
    private BigDecimal totalScore;    // 总分
    private String dimensionScores;   // 各维度分数(JSON)
    private String riskLevel;         // 风险等级: LOW/MEDIUM/HIGH
    private Integer isSuspicious;     // 是否疑似作弊
    private String suspiciousReason;  // 异常原因
    private String answersJson;       // 答案详情(JSON)
    private Integer counselorId;      // 分配的咨询师ID
    private Integer isViewed;         // 咨询师是否已查看
    private Date createdAt;

    public AssessmentRecord() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getScaleId() { return scaleId; }
    public void setScaleId(Integer scaleId) { this.scaleId = scaleId; }

    public Date getStartTime() { return startTime; }
    public void setStartTime(Date startTime) { this.startTime = startTime; }

    public Date getEndTime() { return endTime; }
    public void setEndTime(Date endTime) { this.endTime = endTime; }

    public Integer getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(Integer durationSeconds) { this.durationSeconds = durationSeconds; }

    public BigDecimal getTotalScore() { return totalScore; }
    public void setTotalScore(BigDecimal totalScore) { this.totalScore = totalScore; }

    public String getDimensionScores() { return dimensionScores; }
    public void setDimensionScores(String dimensionScores) { this.dimensionScores = dimensionScores; }

    public String getRiskLevel() { return riskLevel; }
    public void setRiskLevel(String riskLevel) { this.riskLevel = riskLevel; }

    public Integer getSuspicious() { return isSuspicious; }
    public void setSuspicious(Integer isSuspicious) { this.isSuspicious = isSuspicious; }

    public String getSuspiciousReason() { return suspiciousReason; }
    public void setSuspiciousReason(String suspiciousReason) { this.suspiciousReason = suspiciousReason; }

    public String getAnswersJson() { return answersJson; }
    public void setAnswersJson(String answersJson) { this.answersJson = answersJson; }

    public Integer getCounselorId() { return counselorId; }
    public void setCounselorId(Integer counselorId) { this.counselorId = counselorId; }

    public Integer getViewed() { return isViewed; }
    public void setViewed(Integer isViewed) { this.isViewed = isViewed; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
