package com.psychology.ai;

import com.psychology.dao.*;
import com.psychology.entity.*;

import java.sql.Timestamp;
import java.util.*;

/**
 * 学生上下文构建器 - 聚合学生的多维业务数据
 */
public class StudentContextBuilder {
    
    private int studentId;
    
    // ---- 缓存的数据字段（懒加载）----
    private User studentProfile;
    private List<Map<String, Object>> recentAssessments;
    private int consultationCount;
    private String lastConsultationTopic;
    private boolean hasUpcomingAppointment;
    private String upcomingAppointmentDate;
    private String upcomingAppointmentTime;
    private String upcomingAppointmentTopic;
    
    public StudentContextBuilder(int studentId) {
        this.studentId = studentId;
    }
    
    public StudentContext build() {
        StudentContext context = new StudentContext();
        
        try {
            loadBasicProfile();
            context.grade = studentProfile.getGrade();
            context.department = studentProfile.getDepartment();
            context.lastLoginTime = studentProfile.getLastLoginTime() != null ? 
                new Timestamp(studentProfile.getLastLoginTime().getTime()) : null;
            
            if (isFeatureEnabled("data.enhancement.assessment.history")) {
                loadRecentAssessments();
                context.recentAssessments = recentAssessments;
            }
            
            if (isFeatureEnabled("data.enhancement.consultation.history")) {
                loadConsultationInfo();
                context.consultationCount = consultationCount;
                context.lastConsultationTopic = lastConsultationTopic;
            }
            
            if (isFeatureEnabled("data.enhancement.appointment.info")) {
                loadUpcomingAppointment();
                context.hasUpcomingAppointment = hasUpcomingAppointment;
                context.upcomingAppointmentDate = upcomingAppointmentDate;
                context.upcomingAppointmentTime = upcomingAppointmentTime;
                context.upcomingAppointmentTopic = upcomingAppointmentTopic;
            }
            
        } catch (Exception e) {
            System.err.println("[WARN] 构建学生上下文失败: " + e.getMessage());
        }
        
        return context;
    }
    
    private void loadBasicProfile() {
        UserDao userDao = new UserDao();
        this.studentProfile = userDao.findById(studentId);
        if (this.studentProfile == null) {
            throw new RuntimeException("未找到学生ID: " + studentId);
        }
    }
    
    /**
     * 加载最近的心理测评记录（最多3条）
     */
    private void loadRecentAssessments() {
        AssessmentRecordDao dao = new AssessmentRecordDao();
        List<AssessmentRecord> records = dao.findByUser(studentId, 1, 3);
        
        this.recentAssessments = new ArrayList<>();
        if (records != null) {
            for (AssessmentRecord record : records) {
                Map<String, Object> item = new HashMap<>();
                
                Scale scale = new ScaleDao().findById(record.getScaleId());
                item.put("scaleName", scale != null ? scale.getName() : "未知量表");
                
                if (record.getCreatedAt() != null) {
                    item.put("date", record.getCreatedAt().toString().substring(0, 10));
                } else {
                    item.put("date", "未知日期");
                }
                
                item.put("riskLevel", record.getRiskLevel() != null ? 
                    record.getRiskLevel() : "UNKNOWN");
                item.put("totalScore", record.getTotalScore() != null ? 
                    record.getTotalScore().toString() : "N/A");
                
                this.recentAssessments.add(item);
            }
        }
    }
    
    /**
     * 加载历史咨询统计信息
     */
    private void loadConsultationInfo() {
        ConsultationRecordDao dao = new ConsultationRecordDao();
        
        // 使用findByStudent获取最近记录，同时计算总数
        List<ConsultationRecord> allRecords = dao.findByStudent(studentId, 1, 100);
        this.consultationCount = allRecords != null ? allRecords.size() : 0;
        
        if (this.consultationCount > 0 && allRecords != null && !allRecords.isEmpty()) {
            ConsultationRecord lastRecord = allRecords.get(0);  // 最新的记录
            
            if (lastRecord.getAppointmentId() != null) {
                Appointment appointment = new AppointmentDao()
                    .findById(lastRecord.getAppointmentId());
                if (appointment != null) {
                    this.lastConsultationTopic = appointment.getConsultationTopic();
                } else {
                    this.lastConsultationTopic = lastRecord.getSummaryText() != null ?
                        (lastRecord.getSummaryText().length() > 30 ? 
                            lastRecord.getSummaryText().substring(0, 30) + "..." : 
                            lastRecord.getSummaryText()) : 
                        "常规咨询";
                }
            }
        }
    }
    
    /**
     * 加载即将到来的预约信息
     */
    private void loadUpcomingAppointment() {
        AppointmentDao dao = new AppointmentDao();
        
        // 查询状态为CONFIRMED的预约
        List<Appointment> confirmedAppointments = dao.findByStudent(studentId, "CONFIRMED");
        
        if (confirmedAppointments != null && !confirmedAppointments.isEmpty()) {
            // 找到最近的未来预约
            Date now = new Date();
            for (Appointment apt : confirmedAppointments) {
                if (apt.getAppointmentDate() != null && 
                    apt.getAppointmentDate().after(now)) {
                    this.hasUpcomingAppointment = true;
                    this.upcomingAppointmentDate = apt.getAppointmentDate().toString().substring(0, 10);
                    this.upcomingAppointmentTime = apt.getTimeSlot();
                    this.upcomingAppointmentTopic = apt.getConsultationTopic();
                    break;  // 只取最近的一个
                }
            }
        }
        
        if (!this.hasUpcomingAppointment) {
            this.hasUpcomingAppointment = false;
        }
    }
    
    private boolean isFeatureEnabled(String featureKey) {
        try {
            java.io.InputStream is = getClass().getClassLoader()
                .getResourceAsStream("ai.properties");
            if (is == null) return true;
            
            Properties props = new Properties();
            props.load(is);
            return Boolean.parseBoolean(props.getProperty(featureKey, "true"));
        } catch (Exception e) {
            return true;
        }
    }
    
    /**
     * 学生上下文数据对象
     */
    public static class StudentContext {
        public String grade;
        public String department;
        public Timestamp lastLoginTime;
        public List<Map<String, Object>> recentAssessments;
        public int consultationCount;
        public String lastConsultationTopic;
        public boolean hasUpcomingAppointment;
        public String upcomingAppointmentDate;
        public String upcomingAppointmentTime;
        public String upcomingAppointmentTopic;
        
        public boolean hasData() {
            return (recentAssessments != null && !recentAssessments.isEmpty())
                || consultationCount > 0
                || hasUpcomingAppointment;
        }
    }
}
