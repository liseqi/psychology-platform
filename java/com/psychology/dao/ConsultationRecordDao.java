package com.psychology.dao;

import com.psychology.entity.ConsultationRecord;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 线下咨询记录DAO - 带自动初始化功能
 */
public class ConsultationRecordDao {

    // 标记是否已初始化过
    private static boolean initialized = false;

    /**
     * 检查表是否存在
     */
    public boolean tableExists() {
        try (Connection conn = DBUtil.getConnection();
             ResultSet rs = conn.getMetaData().getTables(null, null, "consultation_record", null)) {
            return rs.next();
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 确保表已创建并包含测试数据（首次访问时调用一次）
     */
    public synchronized void ensureInitialized() {
        if (initialized) return;  // 只执行一次
        
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            
            // 步骤1：创建表（如果不存在）
            createTableIfNotExists(conn);
            
            // 步骤2：检查是否有数据，没有则插入测试数据
            int count = countRecords(conn);
            System.out.println("[ConsultationRecord] 现有记录数: " + count);
            
            if (count == 0) {
                System.out.println("[ConsultationRecord] 检测到无数据，正在插入测试数据...");
                insertTestData(conn);
                System.out.println("[ConsultationRecord] ✅ 测试数据插入完成");
            }
            
            initialized = true;
            
        } catch (SQLException e) {
            System.err.println("❌ 初始化consultation_record表失败: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * 创建表
     */
    private void createTableIfNotExists(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS consultation_record (" +
                "id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '记录ID', " +
                "appointment_id  BIGINT NOT NULL COMMENT '关联预约ID', " +
                "student_id      INT NOT NULL COMMENT '学生ID', " +
                "counselor_id    INT NOT NULL COMMENT '咨询师ID', " +
                "check_in_time   DATETIME DEFAULT NULL COMMENT '签到时间', " +
                "start_time      DATETIME DEFAULT NULL COMMENT '实际开始时间', " +
                "end_time        DATETIME DEFAULT NULL COMMENT '结束时间', " +
                "summary_text    TEXT DEFAULT NULL COMMENT '咨询复盘笔记', " +
                "assessment      VARCHAR(2000) DEFAULT NULL COMMENT '初步评估', " +
                "follow_up_plan  VARCHAR(2000) DEFAULT NULL COMMENT '后续跟进计划', " +
                "is_encrypted    TINYINT(1) DEFAULT 0 COMMENT '是否已加密', " +
                "status          VARCHAR(20) DEFAULT 'ONGOING' COMMENT '状态: ONGOING/COMPLETED/CANCELLED', " +
                "created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
                "INDEX idx_appointment (appointment_id), " +
                "INDEX idx_student (student_id), " +
                "INDEX idx_counselor (counselor_id), " +
                "INDEX idx_status (status)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='线下咨询记录表'";
        
        try (Statement stmt = conn.createStatement()) {
            stmt.execute(sql);
            System.out.println("[ConsultationRecord] 表检查/创建成功");
        }
    }

    /**
     * 统计现有记录数
     */
    private int countRecords(Connection conn) throws SQLException {
        String sql = "SELECT COUNT(*) as cnt FROM consultation_record";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("cnt");
        }
        return 0;
    }

    /**
     * 插入测试数据（包含学生、预约、咨询记录的完整链路）
     */
    private void insertTestData(Connection conn) throws SQLException {
        // 获取咨询师ID
        int counselorId = getCounselorId(conn);
        System.out.println("[ConsultationRecord] 使用咨询师ID: " + counselorId);

        // 1. 创建测试学生（如果不存在）
        createTestStudents(conn);

        // 2. 创建预约记录（如果不存在）并获取预约ID
        Map<String, Long> appointmentIds = createTestAppointments(conn, counselorId);
        
        // 3. 插入咨询记录
        createTestRecords(conn, appointmentIds, counselorId);
        
        System.out.println("[ConsultationRecord] 测试数据插入完成！");
    }

    /**
     * 获取咨询师ID
     */
    private int getCounselorId(Connection conn) throws SQLException {
        // 尝试找"林老师"
        String sql1 = "SELECT id FROM sys_user WHERE real_name LIKE '%林%' AND role = 'COUNSELOR' LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql1);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("id");
        }
        
        // 找任意一个咨询师
        String sql2 = "SELECT id FROM sys_user WHERE role = 'COUNSELOR' LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql2);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("id");
        }
        
        // 默认返回3
        return 3;
    }

    /**
     * 创建测试学生
     */
    private void createTestStudents(Connection conn) throws SQLException {
        Object[][] students = {
            {"zhangsan_test", "张三", "STUDENT", "2024001", "计算机科学与技术学院", "2024级", "软件工程2401班"},
            {"lisi_test", "李四", "STUDENT", "2023056", "心理学院", "2023级", "应用心理学2301班"},
            {"wangwu_test", "王五", "STUDENT", "2024089", "外国语学院", "2024级", "英语2402班"},
            {"zhaoliu_test", "赵六", "STUDENT", "2023012", "商学院", "2023级", "工商管理2301班"},
            {"sunqi_test", "孙七", "STUDENT", "2024078", "文学院", "2024级", "汉语言文学2401班"}
        };

        for (Object[] student : students) {
            // 使用 INSERT IGNORE 避免重复
            String sql = "INSERT IGNORE INTO sys_user (username, password, real_name, role, student_id, department, grade, class_name, status, created_at) VALUES (?, 'e10adc3949ba59abbe56e057f20f883e', ?, ?, ?, ?, ?, ?, 1, NOW())";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, (String)student[0]);
                ps.setString(2, (String)student[1]);
                ps.setString(3, (String)student[2]);
                ps.setString(4, (String)student[3]);
                ps.setString(5, (String)student[4]);
                ps.setString(6, (String)student[5]);
                ps.setString(7, (String)student[6]);
                ps.executeUpdate();
            }
        }
        System.out.println("[ConsultationRecord] 学生数据准备完成");
    }

    /**
     * 创建测试预约并返回预约ID映射
     */
    private Map<String, Long> createTestAppointments(Connection conn, int counselorId) throws SQLException {
        Map<String, Long> appointmentIds = new HashMap<>();
        
        // 每个学生的预约信息: [username标识, 主题, 日期偏移天数, 时段, 状态]
        Object[][] appointments = {
            {"zhangsan", "学习压力大、考试焦虑严重、睡眠质量差", -7, "09:00-10:00", "COMPLETED"},
            {"lisi", "宿舍人际关系紧张、与室友沟通困难", -3, "14:00-15:00", "COMPLETED"},
            {"wangwu", "情绪波动大、容易焦虑和低落", 0, "15:00-16:00", "CONFIRMED"},
            {"zhaoliu", "职业规划迷茫、对未来方向不确定", -30, "10:00-11:00", "COMPLETED"},
            {"sunqi", "适应困难、想了解如何融入新环境", -14, "09:00-10:00", "CANCELLED"}
        };

        for (Object[] apt : appointments) {
            String topic = (String)apt[1];
            
            // 先检查是否已有该主题的预约
            String checkSql = "SELECT id FROM appointment WHERE consultation_topic = ? LIMIT 1";
            Long aptId = null;
            try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
                checkPs.setString(1, topic);
                ResultSet rs = checkPs.executeQuery();
                if (rs.next()) {
                    aptId = rs.getLong("id");
                }
            }
            
            if (aptId == null) {
                // 获取学生ID
                int studentId = getStudentIdByUsername(conn, (String)apt[0]);
                
                // 计算日期
                String dateSql = "DATE_ADD(CURDATE(), INTERVAL ? DAY)";
                
                String insertSql = "INSERT INTO appointment (student_id, counselor_id, appointment_date, time_slot, status, consultation_topic, created_at, updated_at) VALUES (?, ?, " + dateSql + ", ?, ?, ?, NOW(), NOW())";
                try (PreparedStatement ps = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, studentId);
                    ps.setInt(2, counselorId);
                    ps.setInt(3, (Integer)apt[2]);  // 日期偏移
                    ps.setString(4, (String)apt[3]);   // 时段
                    ps.setString(5, (String)apt[4]);   // 状态
                    ps.setString(6, topic);
                    ps.executeUpdate();
                    
                    ResultSet keys = ps.getGeneratedKeys();
                    if (keys.next()) aptId = keys.getLong(1);
                }
            }
            
            if (aptId != null) {
                // 用主题关键词作为key
                appointmentIds.put(topic.substring(0, 5) + "_id", aptId);
            }
        }
        
        System.out.println("[ConsultationRecord] 预约数据准备完成，共" + appointmentIds.size() + "条");
        return appointmentIds;
    }

    /**
     * 通过用户名获取学生ID
     */
    private int getStudentIdByUsername(Connection conn, String username) throws SQLException {
        String sql = "SELECT id FROM sys_user WHERE username LIKE ? AND role = 'STUDENT' LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "%" + username + "%");
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt("id");
        }
        return 1;  // 默认值
    }

    /**
     * 创建测试咨询记录
     */
    private void createTestRecords(Connection conn, Map<String, Long> aptIds, int counselorId) throws SQLException {
        // 获取学生ID
        int zhangsanId = getStudentIdByUsername(conn, "zhangsan");
        int lisiId = getStudentIdByUsername(conn, "lisi");
        int wangwuId = getStudentIdByUsername(conn, "wangwu");
        int zhaoliuId = getStudentIdByUsername(conn, "zhaoliu");
        int sunqiId = getStudentIdByUsername(conn, "sunqi");

        // 获取预约ID（按顺序对应）
        Long[] ids = aptIds.values().toArray(new Long[0]);
        long apt1 = ids.length > 0 ? ids[0] : 100L;
        long apt2 = ids.length > 1 ? ids[1] : 101L;
        long apt3 = ids.length > 2 ? ids[2] : 102L;
        long apt4 = ids.length > 3 ? ids[3] : 103L;
        long apt5 = ids.length > 4 ? ids[4] : 104L;

        // 记录1：张三 - 进行中
        insertSingleRecord(conn, apt1, zhangsanId, counselorId,
            "ONGOING",
            "DATE_ADD(CURDATE(), INTERVAL -7 DAY)",
            "[测试数据] 学生自述近期学习压力明显增大。主要表现为：\n1. 入睡困难，每晚需要1-2小时才能入睡\n2. 白天注意力不集中，记忆力下降\n3. 对考试成绩过度担忧\n\n本次咨询重点讨论了压力源识别和时间管理技巧。",
            "[测试数据] 初步评估：轻度至中度焦虑状态。风险等级：低风险",
            "[测试数据] 1. 每日进行正念呼吸练习 2. 使用番茄工作法");

        // 记录2：李四 - 进行中
        insertSingleRecord(conn, apt2, lisiId, counselorId,
            "ONGOING",
            "DATE_ADD(CURDATE(), INTERVAL -3 DAY)",
            "[测试数据] 首次咨询。学生因宿舍矛盾前来求助。\n- 与室友生活习惯差异大\n- 曾尝试沟通但效果不佳\n- 感到被排斥，情绪低落",
            "[测试数据] 初步评估：适应性障碍伴随轻度抑郁情绪。风险等级：低风险",
            "[测试数据] 1. 学习非暴力沟通技巧 2. 尝试与室友正式谈话");

        // 记录3：王五 - 进行中
        insertSingleRecord(conn, apt3, wangwuId, counselorId,
            "ONGOING",
            "NOW()",
            "[测试数据] 学生刚完成签到，准备开始首次咨询。SAS标准分58分（中度焦虑），SDS标准分52分（轻度抑郁）。",
            "",
            "");

        // 记录4：赵六 - 已结案
        insertCompletedRecord(conn, apt4, zhaoliuId, counselorId,
            "DATE_SUB(NOW(), INTERVAL 30 DAY)",
            "DATE_SUB(NOW(), INTERVAL 25 DAY)",
            "[测试数据] 结案总结：共进行4次咨询。\n第1次：探索问题\n第2次：兴趣测评与价值观澄清\n第3次：制定行动计划\n第4次：回顾进展\n学生目前对考研vs就业有较清晰方向。",
            "[测试数据] 结案评估：来诊时SAS 62分 → 结案时48分。问题解决度：80%。",
            "[测试数据] 结案建议：继续执行职业规划方案，半年后随访评估");

        // 记录5：孙七 - 已取消
        insertSingleRecord(conn, apt5, sunqiId, counselorId,
            "CANCELLED",
            null,
            "[测试数据] 学生未按约定时间到场，事后联系得知因个人原因无法参加。预约已取消。",
            "",
            "");
    }

    private void insertSingleRecord(Connection conn, long aptId, int studentId, int counselorId,
                                     String status, String dateExpr, 
                                     String summary, String assessment, String followUp) throws SQLException {
        String sql = "INSERT INTO consultation_record (appointment_id, student_id, counselor_id, check_in_time, start_time, summary_text, assessment, follow_up_plan, status, is_encrypted, created_at, updated_at) " +
                     "VALUES (?, ?, ?, IFNULL(" + dateExpr + ", NOW()), IFNULL(" + dateExpr + ", NOW()), ?, ?, ?, ?, 0, IFNULL(" + dateExpr + ", NOW()), NOW())";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, aptId);
            ps.setInt(2, studentId);
            ps.setInt(3, counselorId);
            ps.setString(4, summary);
            ps.setString(5, assessment);
            ps.setString(6, followUp);
            ps.setString(7, status);
            ps.executeUpdate();
        }
    }

    private void insertCompletedRecord(Connection conn, long aptId, int studentId, int counselorId,
                                        String startDateExpr, String endDateExpr,
                                        String summary, String assessment, String followUp) throws SQLException {
        String sql = "INSERT INTO consultation_record (appointment_id, student_id, counselor_id, check_in_time, start_time, end_time, summary_text, assessment, follow_up_plan, status, is_encrypted, created_at, updated_at) " +
                     "VALUES (?, ?, ?, " + startDateExpr + ", " + startDateExpr + ", " + endDateExpr + ", ?, ?, ?, 'COMPLETED', 1, " + startDateExpr + ", " + endDateExpr + ")";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, aptId);
            ps.setInt(2, studentId);
            ps.setInt(3, counselorId);
            ps.setString(4, summary);
            ps.setString(5, assessment);
            ps.setString(6, followUp);
            ps.executeUpdate();
        }
    }

    // ==================== 业务方法 ====================

    /**
     * 查询咨询师的咨询记录列表（用于records.jsp页面）
     */
    public Map<String, Object> findCounselorRecords(Integer counselorId, String status) {
        return findCounselorRecords(counselorId, status, null);
    }

    /**
     * 查询咨询师的咨询记录列表（支持按学生ID筛选）
     */
    public Map<String, Object> findCounselorRecords(Integer counselorId, String status, Integer studentId) {
        // 确保已初始化
        ensureInitialized();
        
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> records = new ArrayList<>();
        
        result.put("total", 0);
        result.put("ongoing", 0);
        result.put("completed", 0);
        result.put("cancelled", 0);
        result.put("records", records);

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();

            // 1. 统计各状态数量
            StringBuilder countSql = new StringBuilder("SELECT " +
                    "COUNT(*) as total, " +
                    "SUM(CASE WHEN status='ONGOING' OR (status IS NULL AND end_time IS NULL) THEN 1 ELSE 0 END) as ongoing_cnt, " +
                    "SUM(CASE WHEN status='COMPLETED' OR (end_time IS NOT NULL AND status IS NULL) THEN 1 ELSE 0 END) as completed_cnt, " +
                    "SUM(CASE WHEN status='CANCELLED' THEN 1 ELSE 0 END) as cancelled_cnt " +
                    "FROM consultation_record WHERE counselor_id=?");
            if (studentId != null) {
                countSql.append(" AND student_id=?");
            }
            
            ps = conn.prepareStatement(countSql.toString());
            ps.setInt(1, counselorId);
            if (studentId != null) {
                ps.setInt(2, studentId);
            }
            rs = ps.executeQuery();
            if (rs.next()) {
                result.put("total", rs.getInt("total"));
                result.put("ongoing", rs.getInt("ongoing_cnt"));
                result.put("completed", rs.getInt("completed_cnt"));
                result.put("cancelled", rs.getInt("cancelled_cnt"));
            }
            DBUtil.closePS(ps);
            if (rs != null) rs.close();

            // 2. 查询详细记录列表
            StringBuilder sql = new StringBuilder(
                "SELECT cr.*, s.real_name as student_name, s.student_id as student_no, " +
                "s.department, s.grade, a.appointment_date, a.time_slot, a.consultation_topic, " +
                "(SELECT COUNT(*) FROM consultation_record c2 WHERE c2.student_id = cr.student_id AND c2.counselor_id = cr.counselor_id) as session_count " +
                "FROM consultation_record cr " +
                "LEFT JOIN sys_user s ON cr.student_id = s.id " +
                "LEFT JOIN appointment a ON cr.appointment_id = a.id " +
                "WHERE cr.counselor_id=? "
            );
            if (studentId != null) {
                sql.append("AND cr.student_id=? ");
            }

            if ("ONGOING".equals(status)) {
                sql.append("AND (cr.status='ONGOING' OR (cr.status IS NULL AND cr.end_time IS NULL)) ");
            } else if ("COMPLETED".equals(status)) {
                sql.append("AND (cr.status='COMPLETED' OR (cr.end_time IS NOT NULL)) ");
            } else if ("CANCELLED".equals(status)) {
                sql.append("AND cr.status='CANCELLED' ");
            }
            
            sql.append("ORDER BY cr.created_at DESC");

            ps = conn.prepareStatement(sql.toString());
            ps.setInt(1, counselorId);
            int paramIndex = 2;
            if (studentId != null) {
                ps.setInt(paramIndex++, studentId);
            }
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                
                item.put("id", rs.getLong("id"));
                item.put("appointmentId", rs.getLong("appointment_id"));
                item.put("studentId", rs.getInt("student_id"));
                item.put("studentName", rs.getString("student_name"));
                item.put("studentNo", rs.getString("student_no"));
                item.put("department", rs.getString("department"));
                item.put("grade", rs.getString("grade"));
                item.put("sessionCount", rs.getInt("session_count"));
                item.put("checkInTime", rs.getTimestamp("check_in_time"));
                item.put("startTime", rs.getTimestamp("start_time"));
                item.put("endTime", rs.getTimestamp("end_time"));
                item.put("lastDate", rs.getDate("appointment_date"));
                item.put("timeSlot", rs.getString("time_slot"));
                item.put("summaryText", rs.getString("summary_text"));
                item.put("assessment", rs.getString("assessment"));
                item.put("followUpPlan", rs.getString("follow_up_plan"));
                item.put("topic", rs.getString("consultation_topic"));

                String dbStatus = rs.getString("status");
                Timestamp endTime = rs.getTimestamp("end_time");
                String displayStatus;
                if ("CANCELLED".equals(dbStatus)) {
                    displayStatus = "CANCELLED";
                } else if ("COMPLETED".equals(dbStatus) || (endTime != null && dbStatus == null)) {
                    displayStatus = "COMPLETED";
                } else {
                    displayStatus = "ONGOING";
                }
                item.put("status", displayStatus);
                item.put("createdAt", rs.getTimestamp("created_at"));

                records.add(item);
            }

            result.put("records", records);

        } catch (SQLException e) {
            System.err.println("❌ 查询咨询记录失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }

        return result;
    }

    /**
     * 根据预约ID查询咨询记录
     */
    public ConsultationRecord findByAppointmentId(Long appointmentId) {
        ensureInitialized();
        String sql = "SELECT cr.* FROM consultation_record cr WHERE cr.appointment_id = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, appointmentId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractFullRecord(rs);
            }
        } catch (SQLException e) {
            System.err.println("根据预约ID查询咨询记录失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 添加或更新咨询记录
     */
    public boolean addOrUpdate(ConsultationRecord record) {
        ensureInitialized();
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            if (record.getId() != null && record.getId() > 0) {
                // 更新已有记录
                String sql = "UPDATE consultation_record SET " +
                        "check_in_time=?, start_time=?, end_time=?, " +
                        "summary_text=?, assessment=?, follow_up_plan=?, " +
                        "status=?, is_encrypted=?, updated_at=NOW() WHERE id=?";
                ps = conn.prepareStatement(sql);
                ps.setTimestamp(1, record.getCheckInTime() != null ? new Timestamp(record.getCheckInTime().getTime()) : null);
                ps.setTimestamp(2, record.getStartTime() != null ? new Timestamp(record.getStartTime().getTime()) : null);
                ps.setTimestamp(3, record.getEndTime() != null ? new Timestamp(record.getEndTime().getTime()) : null);
                ps.setString(4, record.getSummaryText());
                ps.setString(5, record.getAssessment());
                ps.setString(6, record.getFollowUpPlan());
                ps.setString(7, record.getStatus());
                ps.setInt(8, record.getIsEncrypted() != null ? record.getIsEncrypted() : 0);
                ps.setLong(9, record.getId());
                return ps.executeUpdate() > 0;
            } else {
                // 新增记录
                String sql = "INSERT INTO consultation_record " +
                        "(appointment_id, student_id, counselor_id, check_in_time, start_time, end_time, " +
                        "summary_text, assessment, follow_up_plan, status, is_encrypted) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
                ps.setLong(1, record.getAppointmentId());
                ps.setInt(2, record.getStudentId());
                ps.setInt(3, record.getCounselorId());
                ps.setTimestamp(4, record.getCheckInTime() != null ? new Timestamp(record.getCheckInTime().getTime()) : null);
                ps.setTimestamp(5, record.getStartTime() != null ? new Timestamp(record.getStartTime().getTime()) : null);
                ps.setTimestamp(6, record.getEndTime() != null ? new Timestamp(record.getEndTime().getTime()) : null);
                ps.setString(7, record.getSummaryText());
                ps.setString(8, record.getAssessment());
                ps.setString(9, record.getFollowUpPlan());
                ps.setString(10, record.getStatus() != null ? record.getStatus() : "ONGOING");
                ps.setInt(11, record.getIsEncrypted() != null ? record.getIsEncrypted() : 0);
                int rows = ps.executeUpdate();
                if (rows > 0) {
                    ResultSet keys = ps.getGeneratedKeys();
                    if (keys.next()) {
                        record.setId(keys.getLong(1));
                    }
                    keys.close();
                    return true;
                }
            }
        } catch (SQLException e) {
            System.err.println("添加/更新咨询记录失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }
    
    /**
     * 按学生ID分页查询咨询记录
     */
    public List<ConsultationRecord> findByStudent(Integer studentId, int page, int pageSize) {
        ensureInitialized();
        List<ConsultationRecord> list = new ArrayList<>();
        String sql = "SELECT cr.*, u.real_name as counselor_name, " +
                "a.appointment_date, a.time_slot, a.consultation_topic " +
                "FROM consultation_record cr " +
                "LEFT JOIN sys_user u ON cr.counselor_id = u.id " +
                "LEFT JOIN appointment a ON cr.appointment_id = a.id " +
                "WHERE cr.student_id = ? " +
                "ORDER BY cr.created_at DESC LIMIT ?, ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, studentId);
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractFullRecord(rs));
            }
        } catch (SQLException e) {
            System.err.println("查询学生咨询记录失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }
    
    /**
     * 按咨询师ID分页查询咨询记录
     */
    public List<ConsultationRecord> findByCounselor(Integer counselorId, int page, int pageSize) {
        ensureInitialized();
        List<ConsultationRecord> list = new ArrayList<>();
        String sql = "SELECT cr.*, u.real_name as student_name, " +
                "a.appointment_date, a.time_slot, a.consultation_topic " +
                "FROM consultation_record cr " +
                "LEFT JOIN sys_user u ON cr.student_id = u.id " +
                "LEFT JOIN appointment a ON cr.appointment_id = a.id " +
                "WHERE cr.counselor_id = ? " +
                "ORDER BY cr.created_at DESC LIMIT ?, ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, counselorId);
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractFullRecord(rs));
            }
        } catch (SQLException e) {
            System.err.println("查询咨询师咨询记录失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }
    
    /**
     * 查询学生自己的咨询记录（用于学生端页面，返回完整信息）
     * 与findCounselorRecords格式保持一致
     */
    /**
     * 查询学生的咨询记录列表（学生端使用，支持按状态筛选）
     * 实现逻辑与findCounselorRecords保持一致
     * 
     * @param studentId 学生ID
     * @param status 状态筛选（ALL/ONGOING/COMPLETED/CANCELLED），为null或空时返回全部
     * @return 包含统计信息和记录列表的Map
     */
    public Map<String, Object> findStudentRecordsForView(Integer studentId, String status) {
        ensureInitialized();
        
        System.out.println("\n========== [StudentRecords] 开始查询 ==========");
        System.out.println("[DEBUG] 输入参数 - studentId: " + studentId + ", status: " + status);
        
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> records = new ArrayList<>();
        
        result.put("total", 0);
        result.put("ongoing", 0);
        result.put("completed", 0);
        result.put("cancelled", 0);  // 与咨询师端一致，增加cancelled字段
        result.put("records", records);

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            conn = DBUtil.getConnection();

            // 1. 统计各状态数量（与咨询师端的countSql保持一致）
            StringBuilder countSql = new StringBuilder("SELECT " +
                    "COUNT(*) as total, " +
                    "SUM(CASE WHEN status='ONGOING' OR (status IS NULL AND end_time IS NULL) THEN 1 ELSE 0 END) as ongoing_cnt, " +
                    "SUM(CASE WHEN status='COMPLETED' OR (end_time IS NOT NULL AND status IS NULL) THEN 1 ELSE 0 END) as completed_cnt, " +
                    "SUM(CASE WHEN status='CANCELLED' THEN 1 ELSE 0 END) as cancelled_cnt " +
                    "FROM consultation_record WHERE student_id=?");
            
            ps = conn.prepareStatement(countSql.toString());
            ps.setInt(1, studentId);
            rs = ps.executeQuery();
            
            int totalCount = 0;
            if (rs.next()) {
                totalCount = rs.getInt("total");
                result.put("total", totalCount);
                result.put("ongoing", rs.getInt("ongoing_cnt"));
                result.put("completed", rs.getInt("completed_cnt"));
                result.put("cancelled", rs.getInt("cancelled_cnt"));
                
                System.out.println("[DEBUG] 统计结果 - total=" + totalCount + 
                                   ", ongoing=" + rs.getInt("ongoing_cnt") + 
                                   ", completed=" + rs.getInt("completed_cnt") +
                                   ", cancelled=" + rs.getInt("cancelled_cnt"));
            }
            DBUtil.closePS(ps);
            if (rs != null) rs.close();

            // 2. 查询详细记录列表（与咨询师端的SQL结构保持一致）
            StringBuilder sql = new StringBuilder(
                "SELECT cr.id, cr.appointment_id, cr.student_id, cr.counselor_id, " +
                "cr.check_in_time, cr.start_time, cr.end_time, " +
                "cr.summary_text, cr.assessment, cr.follow_up_plan, cr.status, cr.created_at, " +
                "c.real_name as counselor_name, c.department as counselor_department, c.role as counselor_role, " +
                "a.appointment_date, a.time_slot, a.consultation_topic, " +
                "(SELECT COUNT(*) FROM consultation_record c2 WHERE c2.student_id = cr.student_id AND c2.counselor_id = cr.counselor_id) as session_count " +
                "FROM consultation_record cr " +
                "LEFT JOIN sys_user c ON cr.counselor_id = c.id " +
                "LEFT JOIN appointment a ON cr.appointment_id = a.id " +
                "WHERE cr.student_id=? "
            );

            // 添加状态过滤条件（与咨询师端完全一致）
            if ("ONGOING".equals(status)) {
                sql.append("AND (cr.status='ONGOING' OR (cr.status IS NULL AND cr.end_time IS NULL)) ");
            } else if ("COMPLETED".equals(status)) {
                sql.append("AND (cr.status='COMPLETED' OR (cr.end_time IS NOT NULL)) ");  // 修复：与咨询师端一致
            } else if ("CANCELLED".equals(status)) {
                sql.append("AND cr.status='CANCELLED' ");
            }
            // status为ALL或null时不加过滤条件，返回全部记录
            
            sql.append("ORDER BY cr.created_at DESC");
            
            System.out.println("[DEBUG] 主查询SQL: " + sql.toString());

            ps = conn.prepareStatement(sql.toString());
            ps.setInt(1, studentId);
            
            System.out.println("[DEBUG] 准备执行主查询...");
            rs = ps.executeQuery();
            System.out.println("[DEBUG] 主查询执行成功！");

            int recordCount = 0;
            while (rs.next()) {
                try {
                    Map<String, Object> item = new HashMap<>();
                    
                    item.put("id", rs.getLong("id"));
                    item.put("appointmentId", rs.getLong("appointment_id"));
                    item.put("studentId", rs.getInt("student_id"));
                    item.put("counselorId", rs.getInt("counselor_id"));
                    item.put("counselorName", rs.getString("counselor_name"));
                    item.put("counselorDepartment", rs.getString("counselor_department"));
                    item.put("counselorRole", rs.getString("counselor_role"));
                    item.put("sessionCount", rs.getInt("session_count"));
                    item.put("checkInTime", rs.getTimestamp("check_in_time"));
                    item.put("startTime", rs.getTimestamp("start_time"));
                    item.put("endTime", rs.getTimestamp("end_time"));
                    item.put("lastDate", rs.getDate("appointment_date"));
                    item.put("timeSlot", rs.getString("time_slot"));
                    item.put("summaryText", rs.getString("summary_text"));
                    item.put("assessment", rs.getString("assessment"));
                    item.put("followUpPlan", rs.getString("follow_up_plan"));
                    item.put("topic", rs.getString("consultation_topic"));

                    // 状态判断逻辑（与咨询师端完全一致）
                    String dbStatus = rs.getString("status");
                    java.sql.Timestamp endTime = rs.getTimestamp("end_time");
                    String displayStatus;
                    if ("CANCELLED".equals(dbStatus)) {
                        displayStatus = "CANCELLED";
                    } else if ("COMPLETED".equals(dbStatus) || (endTime != null && dbStatus == null)) {
                        displayStatus = "COMPLETED";
                    } else {
                        displayStatus = "ONGOING";
                    }
                    item.put("status", displayStatus);
                    item.put("createdAt", rs.getTimestamp("created_at"));

                    records.add(item);
                    recordCount++;
                    
                    System.out.println("[DEBUG] ✅ 找到记录 #" + recordCount + " - id=" + item.get("id") + 
                                       ", counselor=" + item.get("counselorName") + 
                                       ", status=" + displayStatus +
                                       ", topic=" + item.get("topic"));
                                       
                } catch (Exception innerEx) {
                    System.err.println("[DEBUG] ❌ 处理第" + (recordCount+1) + "条记录时出错: " + innerEx.getMessage());
                    innerEx.printStackTrace();
                }
            }

            result.put("records", records);
            
            System.out.println("[DEBUG] ========== 查询完成 ==========");
            System.out.println("[DEBUG] 总共返回 " + records.size() + " 条记录 (统计显示total=" + result.get("total") + ")");
            System.out.println("========== [StudentRecords] 查询结束 ==========\n");

        } catch (Exception e) {  // 🔴 修改：从SQLException改为Exception，捕获所有异常
            System.err.println("❌ [StudentRecords] 查询失败: " + e.getMessage());
            e.printStackTrace();
            
            // 🔴 新增：将错误信息放入返回值，方便前端调试
            result.put("error", "查询失败: " + e.getMessage());
            result.put("errorType", e.getClass().getSimpleName());
        } finally {
            DBUtil.close(conn, ps, rs);
        }

        return result;
    }

    /**
     * 调试方法：查询数据库中所有咨询记录（用于排查数据问题）
     */
    public Map<String, Object> findAllRecordsDebug() {
        ensureInitialized();
        
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> allRecords = new ArrayList<>();
        
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            conn = DBUtil.getConnection();
            
            // 查询所有记录，包含学生和咨询师姓名
            String sql = "SELECT cr.id, cr.student_id, cr.counselor_id, cr.status, " +
                    "s.real_name as student_name, s.username as student_username, " +
                    "c.real_name as counselor_name, " +
                    "a.appointment_date, a.consultation_topic " +
                    "FROM consultation_record cr " +
                    "LEFT JOIN sys_user s ON cr.student_id = s.id " +
                    "LEFT JOIN sys_user c ON cr.counselor_id = c.id " +
                    "LEFT JOIN appointment a ON cr.appointment_id = a.id " +
                    "ORDER BY cr.id";
            
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("id", rs.getLong("id"));
                item.put("studentId", rs.getInt("student_id"));
                item.put("studentName", rs.getString("student_name"));
                item.put("studentUsername", rs.getString("student_username"));
                item.put("counselorId", rs.getInt("counselor_id"));
                item.put("counselorName", rs.getString("counselor_name"));
                item.put("status", rs.getString("status"));
                item.put("appointmentDate", rs.getDate("appointment_date"));
                item.put("topic", rs.getString("consultation_topic"));
                allRecords.add(item);
                
                System.out.println("[DEBUG AllRecords] id=" + item.get("id") + 
                                   ", student_id=" + item.get("studentId") + 
                                   "(" + item.get("studentUsername") + "/" + item.get("studentName") + ")" +
                                   ", counselor=" + item.get("counselorName"));
            }
            
            result.put("allRecords", allRecords);
            result.put("totalCount", allRecords.size());
            
        } catch (SQLException e) {
            System.err.println("[DEBUG] 查询所有记录失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        
        return result;
    }

    /**
     * 根据ID查询咨询记录详情
     */
    public ConsultationRecord findById(Long id) {
        ensureInitialized();
        String sql = "SELECT cr.*, u.real_name as student_name, c.real_name as counselor_name, " +
                "a.appointment_date, a.time_slot, a.consultation_topic " +
                "FROM consultation_record cr " +
                "LEFT JOIN sys_user u ON cr.student_id = u.id " +
                "LEFT JOIN sys_user c ON cr.counselor_id = c.id " +
                "LEFT JOIN appointment a ON cr.appointment_id = a.id " +
                "WHERE cr.id = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractFullRecord(rs);
            }
        } catch (SQLException e) {
            System.err.println("查询咨询记录详情失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }
    
    /**
     * 更新咨询记录内容（编辑记录）
     */
    public boolean updateContent(Long id, String summaryText, String assessment, String followUpPlan) {
        ensureInitialized();
        StringBuilder sql = new StringBuilder("UPDATE consultation_record SET updated_at=NOW()");
        List<Object> params = new ArrayList<>();

        if (summaryText != null) {
            sql.append(", summary_text=?");
            params.add(summaryText);
        }
        if (assessment != null) {
            sql.append(", assessment=?");
            params.add(assessment);
        }
        if (followUpPlan != null) {
            sql.append(", follow_up_plan=?");
            params.add(followUpPlan);
        }

        sql.append(" WHERE id=?");
        params.add(id);

        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("更新咨询记录内容失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 查询学生的所有咨询记录（含关联咨询师/预约信息，用于历史查看）
     */
    public List<Map<String, Object>> findHistoryByStudent(Integer studentId) {
        ensureInitialized();
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT cr.*, s.real_name as student_name, s.student_id as student_no, " +
                "c.real_name as counselor_name, " +
                "a.appointment_date, a.time_slot, a.consultation_topic " +
                "FROM consultation_record cr " +
                "LEFT JOIN sys_user s ON cr.student_id = s.id " +
                "LEFT JOIN sys_user c ON cr.counselor_id = c.id " +
                "LEFT JOIN appointment a ON cr.appointment_id = a.id " +
                "WHERE cr.student_id=? " +
                "ORDER BY cr.created_at DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, studentId);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("id", rs.getLong("id"));
                item.put("appointmentId", rs.getLong("appointment_id"));
                item.put("studentId", rs.getInt("student_id"));
                item.put("studentName", rs.getString("student_name"));
                item.put("studentNo", rs.getString("student_no"));
                item.put("counselorName", rs.getString("counselor_name"));
                item.put("appointmentDate", rs.getDate("appointment_date"));
                item.put("timeSlot", rs.getString("time_slot"));
                item.put("topic", rs.getString("consultation_topic"));
                item.put("summaryText", rs.getString("summary_text"));
                item.put("assessment", rs.getString("assessment"));
                item.put("followUpPlan", rs.getString("follow_up_plan"));
                item.put("checkInTime", rs.getTimestamp("check_in_time"));
                item.put("startTime", rs.getTimestamp("start_time"));
                item.put("endTime", rs.getTimestamp("end_time"));
                item.put("createdAt", rs.getTimestamp("created_at"));
                item.put("updatedAt", rs.getTimestamp("updated_at"));

                String dbStatus = rs.getString("status");
                Timestamp endTime = rs.getTimestamp("end_time");
                String displayStatus;
                if ("CANCELLED".equals(dbStatus)) {
                    displayStatus = "CANCELLED";
                } else if ("COMPLETED".equals(dbStatus) || (endTime != null && dbStatus == null)) {
                    displayStatus = "COMPLETED";
                } else {
                    displayStatus = "ONGOING";
                }
                item.put("status", displayStatus);
                list.add(item);
            }
        } catch (SQLException e) {
            System.err.println("查询学生咨询历史失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 更新咨询记录状态和内容
     */
    public boolean updateStatus(Long id, String status, String summaryText, String assessment) {
        ensureInitialized();
        StringBuilder sql = new StringBuilder("UPDATE consultation_record SET status=?, updated_at=NOW()");
        List<Object> params = new ArrayList<>();
        params.add(status);

        if (summaryText != null) {
            sql.append(", summary_text=?");
            params.add(summaryText);
        }
        if (assessment != null) {
            sql.append(", assessment=?");
            params.add(assessment);
        }
        if ("COMPLETED".equals(status)) {
            sql.append(", end_time=NOW()");
        }

        sql.append(" WHERE id=?");
        params.add(id);

        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("更新咨询记录状态失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }
    
    /**
     * 从ResultSet提取完整的ConsultationRecord（含关联字段）
     */
    private ConsultationRecord extractFullRecord(ResultSet rs) throws SQLException {
        ConsultationRecord record = new ConsultationRecord();
        record.setId(rs.getLong("id"));
        record.setAppointmentId(rs.getLong("appointment_id"));
        record.setStudentId(rs.getInt("student_id"));
        record.setCounselorId(rs.getInt("counselor_id"));
        record.setCheckInTime(rs.getTimestamp("check_in_time"));
        record.setStartTime(rs.getTimestamp("start_time"));
        record.setEndTime(rs.getTimestamp("end_time"));
        record.setSummaryText(rs.getString("summary_text"));
        record.setAssessment(rs.getString("assessment"));
        record.setFollowUpPlan(rs.getString("follow_up_plan"));
        Object enc = rs.getObject("is_encrypted");
        if (enc != null) record.setIsEncrypted(((Number) enc).intValue());
        record.setStatus(rs.getString("status"));
        record.setCreatedAt(rs.getTimestamp("created_at"));
        record.setUpdatedAt(rs.getTimestamp("updated_at"));
        
        // 非数据库字段
        try { record.setStudentName(rs.getString("student_name")); } catch (Exception e) {}
        try { record.setCounselorName(rs.getString("counselor_name")); } catch (Exception e) {}
        try { record.setAppointmentDate(rs.getDate("appointment_date")); } catch (Exception e) {}
        try { record.setTimeSlot(rs.getString("time_slot")); } catch (Exception e) {}
        try { record.setConsultationTopic(rs.getString("consultation_topic")); } catch (Exception e) {}
        
        return record;
    }
}
