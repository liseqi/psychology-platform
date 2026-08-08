package com.psychology.servlet;

import com.google.gson.reflect.TypeToken;
import com.psychology.dao.AlertRecordDao;
import com.psychology.dao.AssessmentRecordDao;
import com.psychology.dao.ScaleDao;
import com.psychology.dao.ScaleQuestionDao;
import com.psychology.entity.AlertRecord;
import com.psychology.entity.AssessmentRecord;
import com.psychology.entity.ScaleQuestion;
import com.psychology.entity.User;
import com.psychology.util.CommonUtil;
import com.psychology.util.EncryptionUtil;
import com.psychology.util.JsonUtil;
import com.psychology.util.LogHelper;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.*;

/**
 * 测评模块Servlet - 答题+报告+历史对比+防作弊
 */
@WebServlet("/assessment/*")
public class AssessmentServlet extends HttpServlet {

    private ScaleDao scaleDao = new ScaleDao();
    private ScaleQuestionDao scaleQuestionDao = new ScaleQuestionDao();
    private AssessmentRecordDao recordDao = new AssessmentRecordDao();
    private AlertRecordDao alertDao = new AlertRecordDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        User user = (User) req.getSession().getAttribute("currentUser");

        if ("/list".equals(pathInfo)) {
            handleList(req, resp, user);
        } else if ("/favorites".equals(pathInfo)) {
            handleFavorites(req, resp, user);
        } else if ("/history".equals(pathInfo)) {
            handleHistory(req, resp, user);
        } else if ("/detail".equals(pathInfo)) {
            handleDetail(req, resp, user);
        } else if ("/questions".equals(pathInfo)) {
            handleQuestions(req, resp, user);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        User user = (User) req.getSession().getAttribute("currentUser");

        if ("/submit".equals(pathInfo)) {
            // 提交测评答案
            handleSubmit(req, resp, user);
        } else if ("/favorite".equals(pathInfo)) {
            // 收藏/取消收藏量表
            handleFavorite(req, resp, user);
        }
    }

    /**
     * 获取量表列表
     */
    private void handleList(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        List<Map<String, Object>> scales = new ArrayList<>();

        for (com.psychology.entity.Scale scale : scaleDao.findAllEnabled()) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", scale.getId());
            item.put("name", scale.getName());
            item.put("code", scale.getCode());
            item.put("description", scale.getDescription());
            item.put("category", scale.getCategory());
            item.put("timeLimit", scale.getTimeLimit());
            item.put("totalQuestions", scale.getTotalQuestions());

            // 检查当前用户是否已收藏
            if (user.isStudent()) {
                item.put("favorited", scaleDao.isFavorited(user.getId(), scale.getId()));
            }
            scales.add(item);
        }

        JsonUtil.writeSuccess(resp, scales);
    }

    /**
     * 获取收藏的量表
     */
    private void handleFavorites(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        List<com.psychology.entity.Scale> favorites = scaleDao.findFavorites(user.getId());
        JsonUtil.writeSuccess(resp, favorites);
    }

    /**
     * 获取测评历史数据（用于折线图对比）
     */
    private void handleHistory(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String scaleIdStr = req.getParameter("scaleId");
        if (CommonUtil.isEmpty(scaleIdStr)) {
            JsonUtil.writeError(resp, "请选择量表");
            return;
        }

        Integer scaleId;
        try {
            scaleId = Integer.parseInt(scaleIdStr);
        } catch (NumberFormatException e) {
            JsonUtil.writeParamError(resp, "量表ID格式错误");
            return;
        }
        List<AssessmentRecord> records = recordDao.findByUserAndScale(user.getId(), scaleId);

        // 组装前端需要的折线图数据格式
        List<Map<String, Object>> chartData = new ArrayList<>();
        for (AssessmentRecord record : records) {
            Map<String, Object> point = new HashMap<>();
            point.put("id", record.getId());
            point.put("date", CommonUtil.formatDate(record.getCreatedAt(), "yyyy-MM-dd"));
            point.put("totalScore", record.getTotalScore());
            point.put("riskLevel", record.getRiskLevel());
            
            // 解析维度分数
            if (CommonUtil.isNotEmpty(record.getDimensionScores())) {
                Map<String, Double> dimensions = JsonUtil.fromJson(
                    record.getDimensionScores(),
                    new TypeToken<Map<String, Double>>() {}
                );
                point.put("dimensions", dimensions);
            }
            chartData.add(point);
        }

        JsonUtil.writeSuccess(resp, chartData);
    }

    /**
     * 提交测评答案（包含防作弊检查）
     */
    private void handleSubmit(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String scaleIdStr = req.getParameter("scaleId");
        String answersJson = req.getParameter("answers");  // JSON格式的答案
        String startTimeStr = req.getParameter("startTime"); // 开始答题的时间戳

        if (CommonUtil.isEmpty(scaleIdStr) || CommonUtil.isEmpty(answersJson)) {
            JsonUtil.writeError(resp, "参数不完整");
            return;
        }

        Integer scaleId;
        try {
            scaleId = Integer.parseInt(scaleIdStr);
        } catch (NumberFormatException e) {
            JsonUtil.writeParamError(resp, "量表ID格式错误");
            return;
        }
        
        // ===== 防作弊策略检查 =====
        
        // 1. 检查短时间重复提交
        AssessmentRecord latestRecord = recordDao.findLatestByUserAndScale(user.getId(), scaleId);
        if (latestRecord != null) {
            long lastSubmitTime = latestRecord.getEndTime().getTime();
            long currentTime = System.currentTimeMillis();
            long intervalMs = currentTime - lastSubmitTime;
            // 默认限制10秒内不能重复提交同一份量表（可配置）
            long repeatInterval = 10000L; // 10秒
            
            if (intervalMs < repeatInterval) {
                JsonUtil.writeError(resp, "提交过于频繁，请在" + 
                    ((repeatInterval - intervalMs) / 60000) + "分钟后再试");
                return;
            }
        }

        // 2. 计算答题时长并检查是否异常短
        long startTime;
        try {
            startTime = Long.parseLong(startTimeStr);
        } catch (NumberFormatException e) {
            startTime = System.currentTimeMillis(); // 使用当前时间作为默认值
        }
        long endTime = System.currentTimeMillis();
        int durationSeconds = (int) ((endTime - startTime) / 1000);
        
        // 最小有效答题时长（秒），可从配置表读取
        int minDuration = 60; // 默认60秒
        
        boolean isSuspicious = false;
        String suspiciousReason = null;
        
        if (durationSeconds < minDuration) {
            isSuspicious = true;
            suspiciousReason = "答题时长过短(" + durationSeconds + "秒)，疑似乱填";
        }

        // ===== 评分计算（简化示例） =====
        double totalScore = calculateScore(scaleId, answersJson);
        String riskLevel = assessRiskLevel(scaleId, totalScore);
        String dimensionScores = calculateDimensions(scaleId, answersJson);

        // ===== 保存测评记录 =====
        AssessmentRecord record = new AssessmentRecord();
        record.setUserId(user.getId());
        record.setScaleId(scaleId);
        record.setStartTime(new Date(startTime));
        record.setEndTime(new Date(endTime));
        record.setDurationSeconds(durationSeconds);
        record.setTotalScore(java.math.BigDecimal.valueOf(totalScore));
        record.setDimensionScores(dimensionScores);
        record.setRiskLevel(riskLevel);
        record.setSuspicious(isSuspicious ? 1 : 0);
        record.setSuspiciousReason(suspiciousReason);
        record.setAnswersJson(EncryptionUtil.encrypt(answersJson)); // 加密存储答案

        long recordId = recordDao.add(record);

        // ===== 高风险自动触发预警 =====
        if ("HIGH".equals(riskLevel) || "MEDIUM".equals(riskLevel)) {
            createAlertFromAssessment(user, recordId, scaleId, riskLevel, totalScore);
            // 记录预警触发日志
            LogHelper.logAlertTrigger(req, user,
                    (int) totalScore, "HIGH".equals(riskLevel) ? "高" : "中");
        }

        // 记录测评提交日志
        LogHelper.logWithDetail(req, user, "ASSESSMENT_SUBMIT", "ASSESSMENT_RECORD",
                "完成量表#" + scaleId + "测评，得分" + (int)totalScore + "，风险等级：" + riskLevel,
                "{\"recordId\":" + recordId + ",\"scaleId\":" + scaleId +
                ",\"score\":" + totalScore + ",\"riskLevel\":\"" + riskLevel + "\"}");

        // 返回结果
        Map<String, Object> result = new HashMap<>();
        result.put("recordId", recordId);
        result.put("totalScore", totalScore);
        result.put("riskLevel", riskLevel);
        result.put("isSuspicious", isSuspicious);
        result.put("suspiciousReason", suspiciousReason);

        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 收藏/取消收藏
     */
    private void handleFavorite(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String scaleIdStr = req.getParameter("scaleId");
        if (CommonUtil.isEmpty(scaleIdStr)) {
            JsonUtil.writeParamError(resp, "请选择量表");
            return;
        }

        int scaleId;
        try {
            scaleId = Integer.parseInt(scaleIdStr);
        } catch (NumberFormatException e) {
            JsonUtil.writeParamError(resp, "量表ID格式错误");
            return;
        }
        boolean nowFavorited = scaleDao.toggleFavorite(user.getId(), scaleId);
        
        Map<String, Object> result = new HashMap<>();
        result.put("favorited", nowFavorited);
        result.put("message", nowFavorited ? "收藏成功" : "已取消收藏");
        
        JsonUtil.writeSuccess(resp, result);
    }

    /**
     * 简化的评分计算（实际应根据各量表规则实现）
     */
    private double calculateScore(Integer scaleId, String answersJson) {
        // 解析答案并计算总分
        // 这里简化处理，实际应按各量表的评分标准实现
        try {
            Map<String, Integer> answers = JsonUtil.fromJson(
                answersJson,
                new TypeToken<Map<String, Integer>>() {}
            );

            double total = 0;
            for (Integer value : answers.values()) {
                total += value;
            }
            return total;
        } catch (Exception e) {
            return 0.0;
        }
    }

    /**
     * 评估风险等级（根据各量表标准）
     */
    private String assessRiskLevel(Integer scaleId, double score) {
        String code = getScaleCode(scaleId);
        if (code == null) code = "";
        
        switch (code) {
            case "SCL90":
                if (score >= 250) return "HIGH";
                if (score >= 200) return "MEDIUM";
                return "LOW";
            case "SDS":
                // SDS标准分 = 原始分 × 1.25 (取整)，53-62轻度，63-72中度，73+重度
                double sdsStandard = score * 1.25;
                if (sdsStandard >= 73) return "HIGH";
                if (sdsStandard >= 63) return "MEDIUM";
                if (sdsStandard >= 53) return "MEDIUM"; // 轻度也归为MEDIUM
                return "LOW";
            case "SAS":
                // SAS标准分 = 原始分 × 1.25 (取整)，50-59轻度，60-69中度，69+重度
                double sasStandard = score * 1.25;
                if (sasStandard >= 70) return "HIGH";
                if (sasStandard >= 60) return "MEDIUM";
                if (sasStandard >= 50) return "MEDIUM";
                return "LOW";
            case "PHQ9":
                // PHQ-9: 0-4 无, 5-9 轻度, 10-14 中度, 15-19 中重度, 20-27 重度
                if (score >= 15) return "HIGH";
                if (score >= 10) return "MEDIUM";
                if (score >= 5) return "MEDIUM";
                return "LOW";
            case "GAD7":
                // GAD-7: 0-4 无, 5-9 轻度, 10-14 中度, 15-21 重度
                if (score >= 15) return "HIGH";
                if (score >= 10) return "MEDIUM";
                if (score >= 5) return "MEDIUM";
                return "LOW";
            default:
                return "LOW";
        }
    }

    private String getScaleCode(Integer scaleId) {
        com.psychology.entity.Scale scale = scaleDao.findById(scaleId);
        return scale != null ? scale.getCode() : "";
    }

    /**
     * 计算各维度分数
     */
    private String calculateDimensions(Integer scaleId, String answersJson) {
        // 简化实现，返回JSON字符串
        // 实际应根据量表维度定义计算
        return "{}";
    }

    /**
     * 从测评结果创建预警记录（仅学生角色触发）
     */
    private void createAlertFromAssessment(User user, long recordId, Integer scaleId, 
                                            String riskLevel, double score) {
        if (user == null || !"STUDENT".equals(user.getRole())) {
            return; // 只有学生测评才触发预警
        }
        AlertRecord alert = new AlertRecord();
        alert.setStudentId(user.getId());
        alert.setAssessmentRecordId(recordId);
        alert.setAlertLevel(riskLevel);
        alert.setAlertType("ASSESSMENT");
        alert.setTriggerReason("测评得分异常: " + scaleId + ", 总分=" + score + ", 风险等级=" + riskLevel);
        alert.setScoreValue(java.math.BigDecimal.valueOf(score));
        alert.setStatus("PENDING");
        
        alertDao.add(alert);
    }

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String recordIdStr = req.getParameter("recordId");
        if (CommonUtil.isEmpty(recordIdStr)) {
            JsonUtil.writeError(resp, "参数不完整");
            return;
        }

        long recordId;
        try {
            recordId = Long.parseLong(recordIdStr);
        } catch (NumberFormatException e) {
            JsonUtil.writeParamError(resp, "记录ID格式错误");
            return;
        }
        AssessmentRecord record = recordDao.findById(recordId);
        if (record == null) {
            JsonUtil.writeError(resp, "记录不存在");
            return;
        }

        // 权限检查：只能查看自己的或咨询师查看名下学生的
        if (user.isStudent() && !record.getUserId().equals(user.getId())) {
            JsonUtil.writeForbidden(resp, "无权查看此记录");
            return;
        }

        // 标记为已查看（咨询师视角）
        if (user.isCounselor()) {
            recordDao.markAsViewed(record.getId());
        }

        JsonUtil.writeSuccess(resp, record);
    }

    /**
     * 获取量表题目列表
     * GET /assessment/questions?scaleId=1
     */
    private void handleQuestions(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        String scaleIdStr = req.getParameter("scaleId");
        if (CommonUtil.isEmpty(scaleIdStr)) {
            JsonUtil.writeParamError(resp, "请指定量表ID");
            return;
        }

        Integer scaleId;
        try {
            scaleId = Integer.parseInt(scaleIdStr);
        } catch (NumberFormatException e) {
            JsonUtil.writeParamError(resp, "量表ID格式错误");
            return;
        }

        com.psychology.entity.Scale scale = scaleDao.findById(scaleId);
        if (scale == null) {
            JsonUtil.writeError(resp, "量表不存在");
            return;
        }

        List<ScaleQuestion> questions = scaleQuestionDao.findByScaleId(scaleId);

        Map<String, Object> result = new HashMap<>();
        result.put("scaleId", scaleId);
        result.put("scaleName", scale.getName());
        result.put("scaleCode", scale.getCode());
        result.put("instruction", scale.getInstruction());
        result.put("totalQuestions", scale.getTotalQuestions());
        result.put("timeLimit", scale.getTimeLimit());
        result.put("questions", questions);

        JsonUtil.writeSuccess(resp, result);
    }
}
