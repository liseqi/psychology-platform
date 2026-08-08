package com.psychology.entity;

import java.io.Serializable;

/**
 * 量表题目实体
 */
public class ScaleQuestion implements Serializable {
    private Integer id;
    private Integer scaleId;      // 所属量表ID
    private Integer questionNo;   // 题号
    private String content;       // 题目内容
    private String dimension;     // 所属维度/因子
    private Integer scoreType;    // 计分方式: 1正向, 0反向
    private Integer status;       // 状态: 1启用

    public ScaleQuestion() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getScaleId() { return scaleId; }
    public void setScaleId(Integer scaleId) { this.scaleId = scaleId; }

    public Integer getQuestionNo() { return questionNo; }
    public void setQuestionNo(Integer questionNo) { this.questionNo = questionNo; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getDimension() { return dimension; }
    public void setDimension(String dimension) { this.dimension = dimension; }

    public Integer getScoreType() { return scoreType; }
    public void setScoreType(Integer scoreType) { this.scoreType = scoreType; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
}
