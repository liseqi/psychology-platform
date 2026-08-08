package com.psychology.listener;

import com.psychology.util.DBUtil;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * 应用生命周期监听器
 */
@WebListener
public class ApplicationListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        System.out.println("=========================================");
        System.out.println("🧠 心理健康管理系统 启动成功");
        System.out.println("=========================================");
        
        // 预热数据库连接池并执行表结构修复
        try {
            Connection conn = DBUtil.getConnection();
            fixAppointmentTableSchema(conn);
            createCounselorScheduleTable(conn);  // 自动创建排班表
            conn.close();
            System.out.println("✅ 数据库连接池初始化完成");
        } catch (Exception e) {
            System.err.println("❌ 数据库连接池初始化失败: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * 自动修复 appointment 表结构（允许 schedule_id 和 consultation_topic 为 NULL）
     */
    private void fixAppointmentTableSchema(Connection conn) {
        try {
            // 检查 appointment 表是否存在
            ResultSet tableCheck = conn.getMetaData().getTables(null, null, "appointment", null);
            if (!tableCheck.next()) {
                System.out.println("⚠️  appointment 表不存在，跳过结构检查");
                return;
            }
            
            // 检查 schedule_id 列的 IS_NULLABLE 属性
            ResultSet columns = conn.getMetaData().getColumns(null, null, "appointment", "schedule_id");
            if (columns.next()) {
                String isNullable = columns.getString("IS_NULLABLE");
                if ("NO".equals(isNullable)) {
                    System.out.println("🔧 检测到 appointment.schedule_id 为 NOT NULL，正在修复...");
                    try (PreparedStatement ps = conn.prepareStatement(
                            "ALTER TABLE appointment MODIFY COLUMN schedule_id INT NULL")) {
                        ps.executeUpdate();
                        System.out.println("✅ 已将 appointment.schedule_id 修改为允许 NULL");
                    }
                }
            }
            columns.close();
            
            // 检查 consultation_topic 列的 IS_NULLABLE 属性
            columns = conn.getMetaData().getColumns(null, null, "appointment", "consultation_topic");
            if (columns.next()) {
                String isNullable = columns.getString("IS_NULLABLE");
                if ("NO".equals(isNullable)) {
                    System.out.println("🔧 检测到 appointment.consultation_topic 为 NOT NULL，正在修复...");
                    try (PreparedStatement ps = conn.prepareStatement(
                            "ALTER TABLE appointment MODIFY COLUMN consultation_topic VARCHAR(200) NULL")) {
                        ps.executeUpdate();
                        System.out.println("✅ 已将 appointment.consultation_topic 修改为允许 NULL");
                    }
                }
            }
            columns.close();
            
        } catch (Exception e) {
            System.err.println("⚠️  表结构自动修复失败（不影响系统运行）: " + e.getMessage());
        }
    }

    /**
     * 自动创建 counselor_schedule 排班表（如果不存在）
     */
    private void createCounselorScheduleTable(Connection conn) {
        try {
            ResultSet tableCheck = conn.getMetaData().getTables(null, null, "counselor_schedule", null);
            if (tableCheck.next()) {
                System.out.println("✅ counselor_schedule 表已存在");
                return;
            }
            tableCheck.close();
            
            System.out.println("🔧 正在创建 counselor_schedule 排班表...");
            
            String createTableSQL = "CREATE TABLE IF NOT EXISTS counselor_schedule (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "counselor_id INT NOT NULL COMMENT '咨询师ID', " +
                    "schedule_date DATE NOT NULL COMMENT '排班日期', " +
                    "time_slot VARCHAR(10) NOT NULL COMMENT '时段', " +
                    "max_appointments INT DEFAULT 1 COMMENT '最大预约人数', " +
                    "current_appointments INT DEFAULT 0 COMMENT '当前预约数', " +
                    "status VARCHAR(20) DEFAULT 'OFF' COMMENT '状态: AVAILABLE=可预约, OFF=休息', " +
                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
                    "UNIQUE KEY uk_counselor_datetime (counselor_id, schedule_date, time_slot), " +
                    "INDEX idx_counselor_date (counselor_id, schedule_date)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='咨询师排班表'";
            
            try (PreparedStatement ps = conn.prepareStatement(createTableSQL)) {
                ps.executeUpdate();
                System.out.println("✅ counselor_schedule 表创建成功");
            }
            
        } catch (Exception e) {
            System.err.println("⚠️  创建 counselor_schedule 表失败: " + e.getMessage());
        }
    }
    
    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        System.out.println("正在关闭系统资源...");
        DBUtil.shutdown();
        System.out.println("✅ 心理健康管理系统 已安全停止");
    }
}
