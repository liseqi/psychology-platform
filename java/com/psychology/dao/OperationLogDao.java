package com.psychology.dao;

import com.psychology.entity.OperationLog;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 操作日志DAO - 数据隐私保护核心
 */
public class OperationLogDao {

    /**
     * 添加操作日志
     */
    public boolean add(OperationLog log) {
        String sql = "INSERT INTO operation_log (operator_id, operator_name, operator_role, " +
                "operation_type, target_type, target_id, target_description, detail, ip_address, user_agent) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, log.getOperatorId());
            ps.setString(2, log.getOperatorName());
            ps.setString(3, log.getOperatorRole());
            ps.setString(4, log.getOperationType());
            ps.setString(5, log.getTargetType());
            if (log.getTargetId() != null) {
                ps.setLong(6, log.getTargetId());
            } else {
                ps.setNull(6, Types.BIGINT);
            }
            ps.setString(7, log.getTargetDescription());
            ps.setString(8, log.getDetail());
            ps.setString(9, log.getIpAddress());
            ps.setString(10, log.getUserAgent());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 查询操作日志列表（管理员用）
     */
    public List<OperationLog> findList(int page, int pageSize, String operatorRole, 
                                        String operationType, String startDate, String endDate) {
        StringBuilder sql = new StringBuilder(
            "SELECT * FROM operation_log WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (operatorRole != null && !operatorRole.isEmpty() && !operatorRole.equals("ALL")) {
            sql.append("AND operator_role=? ");
            params.add(operatorRole);
        }
        if (operationType != null && !operationType.isEmpty() && !operationType.equals("ALL")) {
            sql.append("AND operation_type=? ");
            params.add(operationType);
        }
        if (startDate != null && !startDate.isEmpty()) {
            sql.append("AND created_at >=? ");
            params.add(startDate + " 00:00:00");
        }
        if (endDate != null && !endDate.isEmpty()) {
            sql.append("AND created_at <=? ");
            params.add(endDate + " 23:59:59");
        }

        sql.append("ORDER BY created_at DESC LIMIT ?,?");
        params.add((page - 1) * pageSize);
        params.add(pageSize);

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<OperationLog> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractLog(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 统计日志总数
     */
    public long countTotal(String operatorRole, String operationType, 
                           String startDate, String endDate) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM operation_log WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (operatorRole != null && !operatorRole.isEmpty() && !operatorRole.equals("ALL")) {
            sql.append("AND operator_role=? ");
            params.add(operatorRole);
        }
        if (operationType != null && !operationType.isEmpty() && !operationType.equals("ALL")) {
            sql.append("AND operation_type=? ");
            params.add(operationType);
        }
        if (startDate != null && !startDate.isEmpty()) {
            sql.append("AND created_at >=? ");
            params.add(startDate + " 00:00:00");
        }
        if (endDate != null && !endDate.isEmpty()) {
            sql.append("AND created_at <=? ");
            params.add(endDate + " 23:59:59");
        }

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getLong(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return 0;
    }

    private OperationLog extractLog(ResultSet rs) throws SQLException {
        OperationLog log = new OperationLog();
        log.setId(rs.getLong("id"));
        log.setOperatorId(rs.getInt("operator_id"));
        log.setOperatorName(rs.getString("operator_name"));
        log.setOperatorRole(rs.getString("operator_role"));
        log.setOperationType(rs.getString("operation_type"));
        log.setTargetType(rs.getString("target_type"));
        log.setTargetId(rs.getObject("target_id") != null ? rs.getLong("target_id") : null);
        log.setTargetDescription(rs.getString("target_description"));
        log.setDetail(rs.getString("detail"));
        log.setIpAddress(rs.getString("ip_address"));
        log.setUserAgent(rs.getString("user_agent"));
        log.setCreatedAt(rs.getTimestamp("created_at"));
        return log;
    }
}
