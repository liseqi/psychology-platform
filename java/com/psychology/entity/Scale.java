package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 测评量表实体类
 */
public class Scale implements Serializable {
    private Integer id;
    private String name;              // 量表名称
    private String code;              // 量表编码(SCL90/SDS等)
    private String description;       // 量表说明
    private String instruction;       // 答题指导语
    private String category;          // 量表分类
    private Integer totalQuestions;   // 题目总数
    private Integer timeLimit;        // 建议完成时长(分钟)
    private Integer status;           // 状态:0停用,1启用
    private Integer creatorId;        // 创建者ID(管理员)
    private Date createdAt;
    private Date updatedAt;
    // 非数据库字段：用户是否已收藏
    private boolean favorited;

    public Scale() {}

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getInstruction() { return instruction; }
    public void setInstruction(String instruction) { this.instruction = instruction; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public Integer getTotalQuestions() { return totalQuestions; }
    public void setTotalQuestions(Integer totalQuestions) { this.totalQuestions = totalQuestions; }

    public Integer getTimeLimit() { return timeLimit; }
    public void setTimeLimit(Integer timeLimit) { this.timeLimit = timeLimit; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Integer getCreatorId() { return creatorId; }
    public void setCreatorId(Integer creatorId) { this.creatorId = creatorId; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }

    public boolean isFavorited() { return favorited; }
    public void setFavorited(boolean favorited) { this.favorited = favorited; }
}
