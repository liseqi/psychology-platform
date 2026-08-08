package com.psychology.ai;

import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.sql.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * AI配置管理器 - 支持动态配置和热更新
 * 
 * 核心功能：
 * 1. **多层级配置**：数据库 > 配置文件 > 默认值（优先级递减）
 * 2. **热更新**：通过API动态修改配置，无需重启服务器
 * 3. **审计日志**：记录所有配置变更操作
 * 4. **敏感信息保护**：API Key等敏感信息自动脱敏显示
 * 
 * 使用场景：
 * - 管理员后台修改AI参数（模型、温度、限流等）
 * - 动态切换AI Provider（如从豆包切换到DeepSeek）
 * - 运行时调整RAG/记忆功能开关
 */
public class AIConfigManager {
    private static final Logger logger = LoggerFactory.getLogger(AIConfigManager.class);
    
    private static AIConfigManager instance;
    private final Gson gson = new Gson();
    
    // 运行时配置缓存（优先级最高）
    private Map<String, ConfigEntry> runtimeConfig = new ConcurrentHashMap<>();
    
    // 数据库连接
    private String dbUrl;
    private String dbUser;
    private String dbPassword;
    
    // 敏感字段名列表
    private static final Set<String> SENSITIVE_FIELDS = new HashSet<>(Arrays.asList(
        "api.key", "password", "secret", "token"
    ));
    
    public synchronized static AIConfigManager getInstance() {
        if (instance == null) {
            instance = new AIConfigManager();
        }
        return instance;
    }
    
    private AIConfigManager() {
        loadDatabaseConfig();
        // 从数据库加载配置到运行时缓存
        refreshFromDatabase();
        
        logger.info("AIConfigManager初始化完成，已加载{}条配置", runtimeConfig.size());
    }
    
    /**
     * 加载数据库连接配置
     */
    private void loadDatabaseConfig() {
        Properties props = new Properties();
        try {
            props.load(getClass().getClassLoader().getResourceAsStream("ai.properties"));
            this.dbUrl = props.getProperty("database.url", 
                "jdbc:mysql://localhost:3306/psychology?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai");
            this.dbUser = props.getProperty("database.username", "root");
            this.dbPassword = props.getProperty("database.password", "123456");
        } catch (Exception e) {
            logger.warn("加载数据库配置失败，使用默认值", e);
            this.dbUrl = "jdbc:mysql://localhost:3306/psychology?useUnicode=true&characterEncoding=utf8&useSSL=false";
            this.dbUser = "root";
            this.dbPassword = "123456";
        }
    }
    
    // =====================================================
    // 核心方法：配置读写
    // =====================================================
    
    /**
     * 获取配置值（按优先级：运行时 > 数据库 > 配置文件 > 默认值）
     * 
     * @param key 配置键（如 "ai.provider"）
     * @param defaultValue 默认值
     * @return 配置值
     */
    public String getConfig(String key, String defaultValue) {
        // 1. 检查运行时缓存
        if (runtimeConfig.containsKey(key)) {
            ConfigEntry entry = runtimeConfig.get(key);
            if (entry != null && entry.getValue() != null) {
                return entry.getValue();
            }
        }
        
        // 2. 检查数据库
        String dbValue = getFromDatabase(key);
        if (dbValue != null) {
            return dbValue;
        }
        
        // 3. 检查配置文件
        Properties fileProps = loadPropertiesFile();
        if (fileProps.containsKey(key)) {
            return fileProps.getProperty(key);
        }
        
        // 4. 返回默认值
        return defaultValue;
    }
    
    /**
     * 设置配置值（写入运行时缓存+数据库）
     * 
     * @param key 配置键
     * @param value 新值
     * @param adminUserId 操作管理员ID（用于审计）
     * @param remark 备注说明
     * @return 是否成功
     */
    public boolean setConfig(String key, String value, int adminUserId, String remark) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            // 获取旧值（用于审计）
            String oldValue = getFromDatabase(key);
            
            // 更新或插入数据库
            PreparedStatement pstmt = conn.prepareStatement(
                "INSERT INTO ai_config (config_key, config_value, config_type, description, updated_by, created_at, updated_at) " +
                "VALUES (?, ?, 'STRING', ?, ?, NOW(), NOW()) " +
                "ON DUPLICATE KEY UPDATE config_value = VALUES(config_value), " +
                "updated_by = VALUES(updated_by), updated_at = NOW()");
            
            pstmt.setString(1, key);
            pstmt.setString(2, value);
            pstmt.setString(3, remark != null ? remark : "管理员手动修改");
            pstmt.setInt(4, adminUserId);
            
            int rows = pstmt.executeUpdate();
            pstmt.close();
            
            // 更新运行时缓存
            ConfigEntry entry = new ConfigEntry();
            entry.setKey(key);
            entry.setValue(value);
            entry.setUpdatedAt(new Timestamp(System.currentTimeMillis()));
            runtimeConfig.put(key, entry);
            
            // 写入审计日志
            writeAuditLog(conn, adminUserId, key, oldValue, value, "UPDATE", remark);
            
            logger.info("配置已更新 - key: {}, 管理员: {}", key, adminUserId);
            
            // 如果是关键配置变更，触发相关服务重载
            triggerConfigReload(key);
            
            conn.commit();  // 假设开启了事务
            return true;
            
        } catch (Exception e) {
            logger.error("设置配置失败: {} = {}: {}", key, value, e.getMessage(), e);
            return false;
        } finally {
            closeConnection(conn);
        }
    }
    
    /**
     * 获取所有配置（分页）
     */
    public List<ConfigEntry> getAllConfigs(int page, int pageSize, String searchKeyword) {
        List<ConfigEntry> configs = new ArrayList<>();
        
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            StringBuilder sql = new StringBuilder(
                "SELECT id, config_key, config_value, config_type, description, is_sensitive, updated_by, created_at, updated_at " +
                "FROM ai_config WHERE 1=1 ");
            
            if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
                sql.append("AND (config_key LIKE ? OR description LIKE ?) ");
            }
            
            sql.append("ORDER BY config_key ASC LIMIT ? OFFSET ?");
            
            PreparedStatement pstmt = conn.prepareStatement(sql.toString());
            
            int paramIndex = 1;
            if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
                String keyword = "%" + searchKeyword.trim() + "%";
                pstmt.setString(paramIndex++, keyword);
                pstmt.setString(paramIndex++, keyword);
            }
            
            pstmt.setInt(paramIndex++, pageSize);
            pstmt.setInt(paramIndex++, (page - 1) * pageSize);
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                ConfigEntry entry = new ConfigEntry();
                entry.setId(rs.getLong("id"));
                entry.setKey(rs.getString("config_key"));
                entry.setValue(rs.getString("config_value"));
                entry.setConfigType(rs.getString("config_type"));
                entry.setDescription(rs.getString("description"));
                entry.setSensitive(rs.getBoolean("is_sensitive"));
                entry.setUpdatedBy(rs.getInt("updated_by"));
                entry.setCreatedAt(rs.getTimestamp("created_at"));
                entry.setUpdatedAt(rs.getTimestamp("updated_at"));
                configs.add(entry);
            }
            
            rs.close();
            pstmt.close();
            
        } catch (Exception e) {
            logger.error("获取配置列表失败: {}", e.getMessage(), e);
        } finally {
            closeConnection(conn);
        }
        
        return configs;
    }
    
    /**
     * 获取配置总数（用于分页）
     */
    public int getTotalConfigs(String searchKeyword) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            StringBuilder sql = new StringBuilder("SELECT COUNT(*) as cnt FROM ai_config WHERE 1=1");
            
            if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
                sql.append(" AND (config_key LIKE ? OR description LIKE ?)");
            }
            
            PreparedStatement pstmt = conn.prepareStatement(sql.toString());
            
            if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
                String keyword = "%" + searchKeyword.trim() + "%";
                pstmt.setString(1, keyword);
                pstmt.setString(2, keyword);
            }
            
            ResultSet rs = pstmt.executeQuery();
            rs.next();
            int count = rs.getInt("cnt");
            rs.close();
            pstmt.close();
            
            return count;
            
        } catch (Exception e) {
            logger.error("获取配置数量失败: {}", e.getMessage(), e);
            return 0;
        } finally {
            closeConnection(conn);
        }
    }

    // =====================================================
    // 特殊方法：批量操作
    // =====================================================
    
    /**
     * 批量更新配置（用于表单提交多个配置项）
     */
    public Map<String, Boolean> batchUpdateConfigs(Map<String, String> configMap, int adminUserId) {
        Map<String, Boolean> results = new HashMap<>();
        
        for (Map.Entry<String, String> entry : configMap.entrySet()) {
            boolean success = setConfig(entry.getKey(), entry.getValue(), adminUserId, null);
            results.put(entry.getKey(), success);
        }
        
        return results;
    }
    
    /**
     * 重置配置为默认值（从配置文件重新加载）
     */
    public boolean resetToDefault(String key, int adminUserId) {
        Properties defaultProps = loadPropertiesFile();
        String defaultValue = defaultProps.getProperty(key);
        
        if (defaultValue == null) {
            logger.warn("配置文件中不存在默认值: {}", key);
            return false;
        }
        
        return setConfig(key, defaultValue, adminUserId, "重置为默认值");
    }
    
    // =====================================================
    // 审计日志方法
    // =====================================================
    
    /**
     * 获取配置变更审计日志
     */
    public List<AuditLogEntry> getAuditLogs(int page, int pageSize) {
        List<AuditLogEntry> logs = new ArrayList<>();
        
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT al.*, u.username as admin_name FROM ai_config_audit_log al " +
                "LEFT JOIN user u ON al.admin_user_id = u.id " +
                "ORDER BY al.created_at DESC LIMIT ? OFFSET ?");
            
            pstmt.setInt(1, pageSize);
            pstmt.setInt(2, (page - 1) * pageSize);
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                AuditLogEntry log = new AuditLogEntry();
                log.setId(rs.getLong("id"));
                log.setAdminUserId(rs.getInt("admin_user_id"));
                log.setAdminName(rs.getString("admin_name"));
                log.setConfigKey(rs.getString("config_key"));
                log.setOldValue(maskIfSensitive(rs.getString("config_key"), rs.getString("old_value")));
                log.setNewValue(maskIfSensitive(rs.getString("config_key"), rs.getString("new_value")));
                log.setOperation(rs.getString("operation"));
                log.setRemark(rs.getString("remark"));
                log.setIpAddress(rs.getString("ip_address"));
                log.setCreatedAt(rs.getTimestamp("created_at"));
                logs.add(log);
            }
            
            rs.close();
            pstmt.close();
            
        } catch (Exception e) {
            logger.error("获取审计日志失败: {}", e.getMessage(), e);
        } finally {
            closeConnection(conn);
        }
        
        return logs;
    }
    
    // =====================================================
    // 私有辅助方法
    // =====================================================
    
    /**
     * 从数据库获取单个配置值
     */
    private String getFromDatabase(String key) {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT config_value FROM ai_config WHERE config_key = ?");
            pstmt.setString(1, key);
            ResultSet rs = pstmt.executeQuery();
            
            String value = null;
            if (rs.next()) {
                value = rs.getString("config_value");
            }
            
            rs.close();
            pstmt.close();
            return value;
            
        } catch (Exception e) {
            logger.debug("从数据库读取配置失败: {}", key);
            return null;
        } finally {
            closeConnection(conn);
        }
    }
    
    /**
     * 从配置文件加载属性
     */
    private Properties loadPropertiesFile() {
        Properties props = new Properties();
        try {
            InputStream is = getClass().getClassLoader().getResourceAsStream("ai.properties");
            if (is != null) {
                props.load(is);
            }
        } catch (Exception ignored) {}
        return props;
    }
    
    /**
     * 刷新运行时缓存（从数据库重新加载全部配置）
     */
    public void refreshFromDatabase() {
        Connection conn = null;
        try {
            conn = getDatabaseConnection();
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT config_key, config_value FROM ai_config");
            
            Map<String, ConfigEntry> newCache = new ConcurrentHashMap<>();
            while (rs.next()) {
                ConfigEntry entry = new ConfigEntry();
                entry.setKey(rs.getString("config_key"));
                entry.setValue(rs.getString("config_value"));
                entry.setUpdatedAt(new Timestamp(System.currentTimeMillis()));
                newCache.put(entry.getKey(), entry);
            }
            
            rs.close();
            stmt.close();
            
            this.runtimeConfig = newCache;
            logger.info("配置缓存已刷新，共{}条配置", newCache.size());
            
        } catch (Exception e) {
            logger.error("刷新配置缓存失败: {}", e.getMessage(), e);
        } finally {
            closeConnection(conn);
        }
    }
    
    /**
     * 写入审计日志
     */
    private void writeAuditLog(Connection conn, int adminUserId, String configKey,
                                String oldValue, String newValue, String operation, String remark) throws SQLException {
        PreparedStatement auditStmt = conn.prepareStatement(
            "INSERT INTO ai_config_audit_log (admin_user_id, config_key, old_value, new_value, operation, remark, ip_address, created_at) " +
            "VALUES (?, ?, ?, ?, ?, ?, NULL, NOW())");
        
        auditStmt.setInt(1, adminUserId);
        auditStmt.setString(2, configKey);
        auditStmt.setString(3, maskIfSensitive(configKey, oldValue));
        auditStmt.setString(4, maskIfSensitive(configKey, newValue));
        auditStmt.setString(5, operation);
        auditStmt.setString(6, remark);
        
        auditStmt.executeUpdate();
        auditStmt.close();
    }
    
    /**
     * 对敏感信息进行脱敏处理
     */
    private String maskIfSensitive(String key, String value) {
        if (value == null || value.isEmpty()) return value;
        
        for (String sensitiveField : SENSITIVE_FIELDS) {
            if (key.toLowerCase().contains(sensitiveField)) {
                // 显示前4位和后4位，中间用*代替
                if (value.length() <= 8) {
                    return "****";  // 太短直接隐藏
                }
                return value.substring(0, 4) + "****" + value.substring(value.length() - 4);
            }
        }
        
        return value;  // 非敏感字段原样返回
    }
    
    /**
     * 触发配置重载（当关键配置变更时通知相关服务）
     */
    private void triggerConfigReload(String changedKey) {
        try {
            // Provider变更 → 重载AIService
            if ("ai.provider".equals(changedKey)) {
                AIService.getInstance().reloadProviderConfig();
                logger.info("检测到Provider配置变更，已重载AIService");
            }
            
            // Embedding相关 → 清除EmbeddingService缓存
            if (changedKey.startsWith("embedding.") || changedKey.contains("model")) {
                EmbeddingService.getInstance().clearCache();
                logger.info("检测到Embedding配置变更，已清除向量缓存");
            }
            
            // RAG/Memory开关 → 仅记录日志（下次请求生效）
            if (changedKey.startsWith("rag.") || changedKey.startsWith("memory.")) {
                logger.info("RAG/Memory配置已变更: {} = {}", changedKey, getConfig(changedKey, ""));
            }
            
        } catch (Exception e) {
            logger.warn("触发配置重载失败: {}", e.getMessage(), e);
        }
    }
    
    /**
     * 获取数据库连接
     */
    private Connection getDatabaseConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            return DriverManager.getConnection(dbUrl, dbUser, dbPassword);
        } catch (ClassNotFoundException e) {
            throw new SQLException("数据库驱动未找到", e);
        }
    }
    
    /**
     * 关闭连接
     */
    private void closeConnection(Connection conn) {
        if (conn != null) {
            try { conn.close(); } catch (Exception ignored) {}
        }
    }

    // =====================================================
    // 内部数据结构
    // =====================================================

    /**
     * 配置条目
     */
    public static class ConfigEntry {
        private Long id;
        private String key;
        private String value;
        private String configType;
        private String description;
        private boolean sensitive;
        private Integer updatedBy;
        private Timestamp createdAt;
        private Timestamp updatedAt;
        
        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getKey() { return key; }
        public void setKey(String key) { this.key = key; }
        public String getValue() { return value; }
        public void setValue(String value) { this.value = value; }
        public String getConfigType() { return configType; }
        public void setConfigType(String configType) { this.configType = configType; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public boolean isSensitive() { return sensitive; }
        public void setSensitive(boolean sensitive) { this.sensitive = sensitive; }
        public Integer getUpdatedBy() { return updatedBy; }
        public void setUpdatedBy(Integer updatedBy) { this.updatedBy = updatedBy; }
        public Timestamp getCreatedAt() { return createdAt; }
        public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
        public Timestamp getUpdatedAt() { return updatedAt; }
        public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }
    }
    
    /**
     * 审计日志条目
     */
    public static class AuditLogEntry {
        private Long id;
        private Integer adminUserId;
        private String adminName;
        private String configKey;
        private String oldValue;
        private String newValue;
        private String operation;
        private String remark;
        private String ipAddress;
        private Timestamp createdAt;
        
        // Getters and Setters
        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public Integer getAdminUserId() { return adminUserId; }
        public void setAdminUserId(Integer adminUserId) { this.adminUserId = adminUserId; }
        public String getAdminName() { return adminName; }
        public void setAdminName(String adminName) { this.adminName = adminName; }
        public String getConfigKey() { return configKey; }
        public void setConfigKey(String configKey) { this.configKey = configKey; }
        public String getOldValue() { return oldValue; }
        public void setOldValue(String oldValue) { this.oldValue = oldValue; }
        public String getNewValue() { return newValue; }
        public void setNewValue(String newValue) { this.newValue = newValue; }
        public String getOperation() { return operation; }
        public void setOperation(String operation) { this.operation = operation; }
        public String getRemark() { return remark; }
        public void setRemark(String remark) { this.remark = remark; }
        public String getIpAddress() { return ipAddress; }
        public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }
        public Timestamp getCreatedAt() { return createdAt; }
        public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
    }
}
