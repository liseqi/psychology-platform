package com.psychology.dao;

import com.psychology.util.DBUtil;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;


import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 咨询师排班DAO
 * 
 * 功能说明：
 * - 依赖 counselor_schedule 表存储排班数据
 * - 自动检测并修复 status 字段类型（ENUM → VARCHAR）
 * - 每次查询时自动补全缺失的时段（保证7天×4时段=28条）
 * - 关联 appointment 表显示实时预约信息
 */
public class ScheduleDao {

    private static final String[] TIME_SLOTS = {"09:00", "10:00", "14:00", "15:00"};
    
    // 标记是否已尝试修复过表结构，避免重复修复
    private static volatile boolean tableFixed = false;

    /**
     * 检查表是否存在
     */
    public boolean tableExists() {
        try (Connection conn = DBUtil.getConnection();
             ResultSet rs = conn.getMetaData().getTables(null, null, "counselor_schedule", null)) {
            return rs.next();
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 获取咨询师某周的排班数据（包含预约信息）
     */
    public List<Map<String, Object>> findByCounselorAndWeek(int counselorId, String mondayStr) {
        List<Map<String, Object>> list = new ArrayList<>();

        if (!tableExists()) {
            System.err.println("❌ counselor_schedule 表不存在");
            return list;
        }

        try (Connection conn = DBUtil.getConnection()) {
            // 步骤0：确保表结构正确（ENUM → VARCHAR）
            ensureColumnTypeFixed(conn);
            
            // 步骤1：补全该周缺失的时段（确保28条）
            ensureCompleteWeek(conn, counselorId, mondayStr);

            // 步骤2：查询排班 + 预约信息
            list = queryWithAppointments(conn, counselorId, mondayStr);
            
            System.out.println("✅ 排班查询完成: " + list.size() + " 条记录");
        } catch (Exception e) {
            System.err.println("❌ 获取排班数据异常: " + e.getMessage());
            e.printStackTrace();
        }

        return list;
    }
    
    /**
     * 确保status字段类型正确
     * 如果检测到ENUM类型，自动修改为VARCHAR(20)
     * 只执行一次（使用静态标记避免重复）
     */
    private void ensureColumnTypeFixed(Connection conn) throws SQLException {
        if (tableFixed) {
            return;  // 已修复过，跳过
        }
        
        try {
            // 查询 status 字段的类型
            String checkSql = "SELECT DATA_TYPE, COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS " +
                    "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'counselor_schedule' AND COLUMN_NAME = 'status'";
            
            boolean isEnum = false;
            try (PreparedStatement ps = conn.prepareStatement(checkSql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String dataType = rs.getString("DATA_TYPE");
                    String columnType = rs.getString("COLUMN_TYPE");
                    isEnum = "enum".equalsIgnoreCase(dataType) || 
                              (columnType != null && columnType.toLowerCase().contains("enum"));
                    
                    System.out.println("[DB] status字段类型: DATA_TYPE=" + dataType + ", COLUMN_TYPE=" + columnType);
                }
            }
            
            if (isEnum) {
                System.out.println("🔧 检测到 status 字段是 ENUM 类型，正在转换为 VARCHAR...");
                
                // 执行 ALTER TABLE 将 ENUM 改为 VARCHAR
                try (Statement stmt = conn.createStatement()) {
                    stmt.execute("ALTER TABLE counselor_schedule MODIFY COLUMN status VARCHAR(20) DEFAULT 'OFF' COMMENT '状态: AVAILABLE=可预约, OFF=休息'");
                }
                
                // 清理可能的脏数据
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE counselor_schedule SET status='OFF' WHERE status IS NULL OR status='' OR status NOT IN ('AVAILABLE','OFF')")) {
                    ps.executeUpdate();
                }
                
                System.out.println("✅ status 字段已成功转换为 VARCHAR(20)");
            } else {
                System.out.println("✅ status 字段类型正常（非ENUM），无需修复");
            }
            
            tableFixed = true;  // 标记已处理
            
        } catch (SQLException e) {
            System.err.println("⚠️ 检查/修复字段类型时出错: " + e.getMessage());
            // 即使失败也标记为已尝试，避免无限重试
            tableFixed = true;
        }
    }

    /**
     * 确保该周有完整的28条记录（7天 × 4时段）
     * 只插入缺失的，不删除已有数据
     */
    private void ensureCompleteWeek(Connection conn, int counselorId, String mondayStr) throws SQLException {
        LocalDate monday = LocalDate.parse(mondayStr);
        
        // 统计现有记录数
        String countSQL = "SELECT COUNT(*) as cnt FROM counselor_schedule " +
                "WHERE counselor_id = ? AND schedule_date >= ? AND schedule_date < DATE_ADD(?, INTERVAL 7 DAY)";
        
        int existingCount = 0;
        try (PreparedStatement ps = conn.prepareStatement(countSQL)) {
            ps.setInt(1, counselorId);
            ps.setDate(2, Date.valueOf(mondayStr));
            ps.setDate(3, Date.valueOf(mondayStr));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    existingCount = rs.getInt("cnt");
                }
            }
        }

        // 如果已有28条，直接返回
        if (existingCount >= 28) {
            System.out.println("✅ [" + mondayStr + "] 数据完整: " + existingCount + " 条");
            return;
        }

        System.out.println("📅 [" + mondayStr + "] 数据不完整 (" + existingCount + "/28)，开始补全...");

        // 使用 INSERT IGNORE 补充缺失的时段（不覆盖已有数据）
        String insertSQL = "INSERT IGNORE INTO counselor_schedule " +
                "(counselor_id, schedule_date, time_slot, status, max_appointments, created_at) " +
                "VALUES (?, ?, ?, ?, 1, NOW())";

        int inserted = 0;
        try (PreparedStatement ps = conn.prepareStatement(insertSQL)) {
            for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
                LocalDate date = monday.plusDays(dayOffset);
                DayOfWeek dow = date.getDayOfWeek();
                boolean isWeekend = (dow == DayOfWeek.SATURDAY || dow == DayOfWeek.SUNDAY);
                String status = isWeekend ? "OFF" : "AVAILABLE";

                for (String slot : TIME_SLOTS) {
                    ps.setInt(1, counselorId);
                    ps.setDate(2, Date.valueOf(date));
                    ps.setString(3, slot);
                    ps.setString(4, status);
                    ps.addBatch();
                }
            }
            
            int[] results = ps.executeBatch();
            for (int r : results) {
                if (r > 0) inserted++;
            }
        }

        System.out.println("✅ 补全完成: 新增 " + inserted + " 条，总计应达 28 条");
    }

    /**
     * 查询排班数据 + 关联 appointment 表获取预约信息
     */
    private List<Map<String, Object>> queryWithAppointments(Connection conn, int counselorId, String mondayStr) 
            throws SQLException {

        List<Map<String, Object>> list = new ArrayList<>();

        String sql = "SELECT s.*, " +
                "(SELECT COALESCE(COUNT(*), 0) FROM appointment a " +
                " WHERE (a.schedule_id = s.id " +
                " OR (a.schedule_id IS NULL AND a.counselor_id = s.counselor_id " +
                " AND a.appointment_date = s.schedule_date " +
                " AND SUBSTRING(a.time_slot, 1, 5) = s.time_slot)) " +
                " AND a.status IN ('PENDING', 'CONFIRMED')) as booked_count, " +

                "(SELECT GROUP_CONCAT(DISTINCT u.real_name SEPARATOR ', ') FROM appointment a " +
                " LEFT JOIN sys_user u ON a.student_id = u.id " +
                " WHERE (a.schedule_id = s.id " +
                " OR (a.schedule_id IS NULL AND a.counselor_id = s.counselor_id " +
                " AND a.appointment_date = s.schedule_date " +
                " AND SUBSTRING(a.time_slot, 1, 5) = s.time_slot)) " +
                " AND a.status IN ('PENDING', 'CONFIRMED')) as student_names " +

                "FROM counselor_schedule s " +
                "WHERE s.counselor_id = ? " +
                "AND s.schedule_date >= ? " +
                "AND s.schedule_date < DATE_ADD(?, INTERVAL 7 DAY) " +
                "ORDER BY s.schedule_date, FIELD(s.time_slot, '09:00', '10:00', '14:00', '15:00')";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, counselorId);
            ps.setDate(2, Date.valueOf(mondayStr));
            ps.setDate(3, Date.valueOf(mondayStr));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new HashMap<>();
                    
                    item.put("id", rs.getInt("id"));
                    item.put("counselorId", counselorId);
                    item.put("scheduleDate", rs.getDate("schedule_date").toString());
                    item.put("timeSlot", rs.getString("time_slot"));
                    item.put("maxAppointments", Math.max(rs.getInt("max_appointments"), 1));
                    item.put("status", rs.getString("status"));
                    item.put("bookedCount", rs.getInt("booked_count"));
                    item.put("studentNames", rs.getString("student_names"));

                    // 计算显示状态
                    String dbStatus = rs.getString("status");
                    if (dbStatus == null || dbStatus.isEmpty()) dbStatus = "OFF";
                    dbStatus = dbStatus.toUpperCase();
                    
                    int booked = rs.getInt("booked_count");
                    int max = Math.max(rs.getInt("max_appointments"), 1);
                    
                    String displayStatus;
                    if (booked >= max) {
                        displayStatus = "FULL";
                    } else if (booked > 0) {
                        displayStatus = "PARTIAL";
                    } else if ("AVAILABLE".equals(dbStatus)) {
                        displayStatus = "AVAILABLE";
                    } else {
                        displayStatus = "OFF";
                    }
                    item.put("displayStatus", displayStatus);

                    list.add(item);
                }
            }
        }

        return list;
    }

    /**
     * 获取本周统计数据
     */
    public Map<String, Object> getWeeklyStats(int counselorId, String mondayStr) {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalSlots", 0);
        stats.put("offSlots", 0);
        stats.put("availableSlots", 0);
        stats.put("bookedCount", 0);
        stats.put("pendingCount", 0);

        if (!tableExists()) return stats;

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();

            // 确保字段类型正确
            ensureColumnTypeFixed(conn);

            // 统计排班状态分布
            String countSql = "SELECT " +
                    "COUNT(*) as total, " +
                    "SUM(CASE WHEN status='OFF' OR status IS NULL OR status='' THEN 1 ELSE 0 END) as off_count, " +
                    "SUM(CASE WHEN status='AVAILABLE' THEN 1 ELSE 0 END) as available_count " +
                    "FROM counselor_schedule " +
                    "WHERE counselor_id = ? AND schedule_date >= ? AND schedule_date < DATE_ADD(?, INTERVAL 7 DAY)";

            ps = conn.prepareStatement(countSql);
            ps.setInt(1, counselorId);
            ps.setDate(2, Date.valueOf(mondayStr));
            ps.setDate(3, Date.valueOf(mondayStr));
            rs = ps.executeQuery();
            if (rs.next()) {
                stats.put("totalSlots", rs.getInt("total"));
                stats.put("offSlots", rs.getInt("off_count"));
                stats.put("availableSlots", rs.getInt("available_count"));
            }

            DBUtil.closePS(ps);
            if (rs != null) rs.close();

            // 统计有效预约数
            String aptSql = "SELECT COUNT(*) as booked, " +
                    "SUM(CASE WHEN status='PENDING' THEN 1 ELSE 0 END) as pending " +
                    "FROM appointment a " +
                    "INNER JOIN counselor_schedule s ON (a.schedule_id = s.id " +
                    " OR (a.schedule_id IS NULL AND a.counselor_id = s.counselor_id " +
                    " AND a.appointment_date = s.schedule_date " +
                    " AND SUBSTRING(a.time_slot, 1, 5) = s.time_slot)) " +
                    "WHERE s.counselor_id = ? " +
                    "AND s.schedule_date >= ? AND s.schedule_date < DATE_ADD(?, INTERVAL 7 DAY) " +
                    "AND a.status IN ('PENDING', 'CONFIRMED')";
            
            ps = conn.prepareStatement(aptSql);
            ps.setInt(1, counselorId);
            ps.setDate(2, Date.valueOf(mondayStr));
            ps.setDate(3, Date.valueOf(mondayStr));
            rs = ps.executeQuery();
            if (rs.next()) {
                stats.put("bookedCount", rs.getInt("booked"));
                stats.put("pendingCount", rs.getInt("pending"));
            }

        } catch (SQLException e) {
            System.err.println("❌ 统计查询异常: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }

        return stats;
    }

    /**
     * 更新单个时段状态
     */
    public boolean updateStatus(int scheduleId, String newStatus) throws SQLException {
        // 校验状态值
        String validStatus = validateStatus(newStatus);
        if (validStatus == null) {
            throw new SQLException("无效的状态值: " + newStatus + " (只允许 AVAILABLE 或 OFF)");
        }

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            
            // 确保字段类型正确（防止ENUM类型报错）
            ensureColumnTypeFixed(conn);
            
            // 检查是否有有效预约
            String checkSql = "SELECT id, status, " +
                    "(SELECT COUNT(*) FROM appointment a WHERE a.schedule_id=? AND a.status IN ('PENDING','CONFIRMED')) as booked " +
                    "FROM counselor_schedule WHERE id=?";
            
            ps = conn.prepareStatement(checkSql);
            ps.setInt(1, scheduleId);
            ps.setInt(2, scheduleId);
            rs = ps.executeQuery();
            
            if (!rs.next()) {
                System.out.println("❌ 记录不存在: id=" + scheduleId);
                return false;
            }
            
            int bookedCount = rs.getInt("booked");
            DBUtil.closePS(ps);
            if (rs != null) rs.close();
            
            if (bookedCount > 0) {
                throw new SQLException("该时段已有 " + bookedCount + " 个预约，请先取消预约后再修改");
            }
            
            // 执行更新
            String sql = "UPDATE counselor_schedule SET status=? WHERE id=?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, validStatus);
            ps.setInt(2, scheduleId);
            
            int rows = ps.executeUpdate();
            System.out.println("✅ 更新状态: id=" + scheduleId + ", status=" + validStatus + ", rows=" + rows);
            return rows > 0;
            
        } finally {
            DBUtil.close(conn, ps, rs);
        }
    }

    /**
     * 批量更新状态
     */
    public int batchUpdateStatus(int counselorId, String mondayStr, String fromStatus, String toStatus) {
        String validFrom = validateStatus(fromStatus);
        String validTo = validateStatus(toStatus);
        
        if (validFrom == null || validTo == null) {
            System.err.println("❌ 无效的状态值: from=" + fromStatus + ", to=" + toStatus);
            return 0;
        }
        
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            
            // 确保字段类型正确
            ensureColumnTypeFixed(conn);
            
            String sql = "UPDATE counselor_schedule SET status=? " +
                    "WHERE counselor_id=? " +
                    "AND schedule_date >= ? AND schedule_date < DATE_ADD(?, INTERVAL 7 DAY) " +
                    "AND status=? " +
                    "AND NOT EXISTS (SELECT 1 FROM appointment a WHERE a.schedule_id=counselor_schedule.id AND a.status IN ('PENDING','CONFIRMED'))";
            
            ps = conn.prepareStatement(sql);
            ps.setString(1, validTo);
            ps.setInt(2, counselorId);
            ps.setDate(3, Date.valueOf(mondayStr));
            ps.setDate(4, Date.valueOf(mondayStr));
            ps.setString(5, validFrom);
            
            int rows = ps.executeUpdate();
            System.out.println("✅ 批量更新: " + validFrom + " → " + validTo + ", 影响行数=" + rows);
            return rows;
            
        } catch (SQLException e) {
            System.err.println("❌ 批量更新失败: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return 0;
    }
    
    /**
     * 根据咨询师、日期、时段查询排班
     * timeSlot 支持 "09:00" 或 "09:00-10:00" 格式
     */
    public Map<String, Object> findSlot(int counselorId, java.sql.Date scheduleDate, String timeSlot) {
        Map<String, Object> result = null;
        String startTime = normalizeTimeSlot(timeSlot);

        String sql = "SELECT id, status, max_appointments, current_appointments " +
                "FROM counselor_schedule " +
                "WHERE counselor_id=? AND schedule_date=? AND time_slot=?";

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, counselorId);
            ps.setDate(2, scheduleDate);
            ps.setString(3, startTime);
            rs = ps.executeQuery();
            if (rs.next()) {
                result = new HashMap<>();
                result.put("id", rs.getInt("id"));
                result.put("status", rs.getString("status"));
                result.put("maxAppointments", rs.getInt("max_appointments"));
                result.put("currentAppointments", rs.getInt("current_appointments"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return result;
    }

    /**
     * 查找并占用一个可用排班名额
     * 返回 scheduleId；若无可排班或已满则返回 null
     * 会基于实际有效预约数判断是否已满，并校准 current_appointments
     */
    public Integer bookAvailableSlot(int counselorId, java.sql.Date scheduleDate, String timeSlot) {
        String startTime = normalizeTimeSlot(timeSlot);
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            // 查找并锁定行
            String findSql = "SELECT id, status, max_appointments, current_appointments " +
                    "FROM counselor_schedule " +
                    "WHERE counselor_id=? AND schedule_date=? AND time_slot=? " +
                    "FOR UPDATE";
            ps = conn.prepareStatement(findSql);
            ps.setInt(1, counselorId);
            ps.setDate(2, scheduleDate);
            ps.setString(3, startTime);
            rs = ps.executeQuery();
            if (!rs.next()) {
                System.out.println("[bookSlot] 未找到排班: counselorId=" + counselorId +
                        ", date=" + scheduleDate + ", slot=" + startTime);
                return null;
            }
            int scheduleId = rs.getInt("id");
            String status = rs.getString("status");
            int max = rs.getInt("max_appointments");
            DBUtil.closePS(ps);
            rs.close();

            if (!"AVAILABLE".equals(status)) {
                System.out.println("[bookSlot] 时段非可预约状态: scheduleId=" + scheduleId + ", status=" + status);
                return null;
            }

            // 统计实际有效预约数（含历史无 schedule_id 的记录）
            int realCount = countActualAppointments(conn, scheduleId, counselorId, scheduleDate, startTime);
            if (realCount >= max) {
                // 校准 current_appointments 为真实数
                calibrateCurrentAppointments(conn, scheduleId, realCount);
                System.out.println("[bookSlot] 时段已满: scheduleId=" + scheduleId + ", real=" + realCount + "/" + max);
                return null;
            }

            // 占用名额：校准为真实数 + 1
            String updateSql = "UPDATE counselor_schedule SET current_appointments=? WHERE id=?";
            ps = conn.prepareStatement(updateSql);
            ps.setInt(1, realCount + 1);
            ps.setInt(2, scheduleId);
            int rows = ps.executeUpdate();
            if (rows == 0) {
                System.out.println("[bookSlot] 并发冲突，未能占用: scheduleId=" + scheduleId);
                return null;
            }
            System.out.println("[bookSlot] 成功占用: scheduleId=" + scheduleId + ", " + (realCount + 1) + "/" + max);
            return scheduleId;
        } catch (SQLException e) {
            System.err.println("[bookSlot] 异常: " + e.getMessage());
            e.printStackTrace();
            return null;
        } finally {
            DBUtil.close(conn, ps, rs);
        }
    }

    /**
     * 统计某排班时段的实际有效预约数
     */
    private int countActualAppointments(Connection conn, int scheduleId, int counselorId,
                                         java.sql.Date scheduleDate, String startTime) throws SQLException {
        String sql = "SELECT COUNT(*) as cnt FROM appointment a " +
                "WHERE a.status IN ('PENDING', 'CONFIRMED') AND " +
                "(a.schedule_id=? OR (a.schedule_id IS NULL AND a.counselor_id=? AND a.appointment_date=? AND SUBSTRING(a.time_slot,1,5)=?))";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, scheduleId);
            ps.setInt(2, counselorId);
            ps.setDate(3, scheduleDate);
            ps.setString(4, startTime);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("cnt");
                }
            }
        }
        return 0;
    }

    /**
     * 校准 current_appointments 为实际数
     */
    private void calibrateCurrentAppointments(Connection conn, int scheduleId, int realCount) throws SQLException {
        String sql = "UPDATE counselor_schedule SET current_appointments=? WHERE id=?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, realCount);
            ps.setInt(2, scheduleId);
            ps.executeUpdate();
        }
    }


    /**
     * 释放排班名额
     */
    public void releaseSlot(int scheduleId) {
        if (scheduleId <= 0) return;
        String sql = "UPDATE counselor_schedule " +
                "SET current_appointments = GREATEST(0, current_appointments - 1) " +
                "WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, scheduleId);
            ps.executeUpdate();
            System.out.println("[releaseSlot] 释放名额: scheduleId=" + scheduleId);
        } catch (SQLException e) {
            System.err.println("[releaseSlot] 异常: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
    }

    /**
     * 更新预约关联的排班/时间/状态
     */
    public boolean updateAppointmentSlot(Long appointmentId, Integer scheduleId,
                                          java.sql.Date appointmentDate, String timeSlot) {
        String sql = "UPDATE appointment SET schedule_id=?, appointment_date=?, time_slot=?, " +
                "status='PENDING', updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            if (scheduleId != null) {
                ps.setInt(1, scheduleId);
            } else {
                ps.setNull(1, Types.INTEGER);
            }
            ps.setDate(2, appointmentDate);
            ps.setString(3, timeSlot);
            ps.setLong(4, appointmentId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 标准化时段为开始时间
     */
    private String normalizeTimeSlot(String timeSlot) {
        if (timeSlot == null || timeSlot.isEmpty()) {
            return timeSlot;
        }
        String trimmed = timeSlot.trim();
        if (trimmed.length() > 5 && trimmed.charAt(5) == '-') {
            return trimmed.substring(0, 5);
        }
        return trimmed;
    }

    /**
     * 校验并规范化状态值
     */
    private String validateStatus(String status) {
        if (status == null || status.trim().isEmpty()) {
            return null;
        }
        String upper = status.trim().toUpperCase();
        if ("AVAILABLE".equals(upper) || "OFF".equals(upper)) {
            return upper;
        }
        return null;
    }
}
