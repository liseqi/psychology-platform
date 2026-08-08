package com.psychology.dao;

import com.psychology.entity.User;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 用户数据访问对象
 */
public class UserDao {

    /**
     * 根据邮箱查询用户
     */
    public User findByEmail(String email) {
        String sql = "SELECT * FROM sys_user WHERE email = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, email);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractUser(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 根据用户名查询用户
     */
    public User findByUsername(String username) {
        String sql = "SELECT * FROM sys_user WHERE username = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractUser(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 根据ID查询用户
     */
    public User findById(Integer id) {
        String sql = "SELECT * FROM sys_user WHERE id = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractUser(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 新增用户
     */
    public int add(User user) {
        String sql = "INSERT INTO sys_user (username, password, salt, real_name, role, email, phone, " +
                "student_id, department, grade, class_name, gender) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, user.getUsername());
            ps.setString(2, user.getPassword());
            ps.setString(3, user.getSalt());
            ps.setString(4, user.getRealName());
            ps.setString(5, user.getRole());
            ps.setString(6, user.getEmail());
            ps.setString(7, user.getPhone());
            ps.setString(8, user.getStudentId());
            ps.setString(9, user.getDepartment());
            ps.setString(10, user.getGrade());
            ps.setString(11, user.getClassName());
            ps.setString(12, user.getGender());
            
            int rows = ps.executeUpdate();
            if (rows > 0) {
                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    return generatedKeys.getInt(1);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return 0;
    }

    /**
     * 更新用户信息
     */
    public boolean update(User user) {
        String sql = "UPDATE sys_user SET real_name=?, role=?, email=?, phone=?, department=?, avatar_url=? WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, user.getRealName());
            ps.setString(2, user.getRole());
            ps.setString(3, user.getEmail());
            ps.setString(4, user.getPhone());
            ps.setString(5, user.getDepartment());
            ps.setString(6, user.getAvatarUrl());
            ps.setInt(7, user.getId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 更新最后登录信息
     */
    public boolean updateLoginInfo(Integer id, String ip) {
        String sql = "UPDATE sys_user SET last_login_time=NOW(), last_login_ip=? WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, ip);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 更新密码
     */
    public boolean updatePassword(Integer id, String newPassword, String salt) {
        String sql = "UPDATE sys_user SET password=?, salt=? WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, newPassword);
            ps.setString(2, salt);
            ps.setInt(3, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 分页查询学生（咨询师查看名下学生）
     */
    public List<User> findStudentsByCounselor(Integer counselorId, int page, int pageSize) {
        // 这里简化实现，实际应根据业务规则关联查询
        String sql = "SELECT u.* FROM sys_user u WHERE u.role='STUDENT' AND u.status=1 ORDER BY u.id DESC LIMIT ?,?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<User> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, (page - 1) * pageSize);
            ps.setInt(2, pageSize);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractUser(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 统计用户数量（按角色）
     */
    public long countByRole(String role) {
        String sql = "SELECT COUNT(*) FROM sys_user WHERE role=?";
        if ("ALL".equals(role)) {
            sql = "SELECT COUNT(*) FROM sys_user";
        }
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            if (!"ALL".equals(role)) {
                ps.setString(1, role);
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

    /**
     * 分页查询用户列表（支持多条件筛选）
     */
    public List<User> findList(int page, int pageSize, String role, String status, String keyword) {
        StringBuilder sql = new StringBuilder("SELECT * FROM sys_user WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (role != null && !role.isEmpty() && !"ALL".equals(role)) {
            sql.append(" AND role=?");
            params.add(role);
        }
        if (status != null && !status.isEmpty() && !"ALL".equals(status)) {
            int s = "enabled".equalsIgnoreCase(status) || "正常".equals(status) ? 1 : 0;
            sql.append(" AND status=?");
            params.add(s);
        }
        if (keyword != null && !keyword.isEmpty()) {
            sql.append(" AND (username LIKE ? OR real_name LIKE ? OR student_id LIKE ?)");
            String kw = "%" + keyword + "%";
            params.add(kw);
            params.add(kw);
            params.add(kw);
        }

        sql.append(" ORDER BY id DESC LIMIT ?,?");
        params.add((page - 1) * pageSize);
        params.add(pageSize);

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<User> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractUser(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 统计符合条件的用户数量
     */
    public long countByCondition(String role, String status, String keyword) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM sys_user WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (role != null && !role.isEmpty() && !"ALL".equals(role)) {
            sql.append(" AND role=?");
            params.add(role);
        }
        if (status != null && !status.isEmpty() && !"ALL".equals(status)) {
            int s = "enabled".equalsIgnoreCase(status) || "正常".equals(status) ? 1 : 0;
            sql.append(" AND status=?");
            params.add(s);
        }
        if (keyword != null && !keyword.isEmpty()) {
            sql.append(" AND (username LIKE ? OR real_name LIKE ? OR student_id LIKE ?)");
            String kw = "%" + keyword + "%";
            params.add(kw);
            params.add(kw);
            params.add(kw);
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

    /**
     * 更新用户状态（启用/禁用）
     */
    public boolean updateStatus(Integer id, Integer status) {
        String sql = "UPDATE sys_user SET status=?, updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, status);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 更新用户角色
     */
    public boolean updateRole(Integer id, String role) {
        String sql = "UPDATE sys_user SET role=?, updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, role);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 删除用户（软删除，更新状态为-1）
     */
    public boolean delete(Integer id) {
        String sql = "UPDATE sys_user SET status=-1, updated_at=NOW() WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    /**
     * 从ResultSet提取User对象
     */
    private User extractUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getInt("id"));
        user.setUsername(rs.getString("username"));
        user.setPassword(rs.getString("password"));
        user.setSalt(rs.getString("salt"));
        user.setRealName(rs.getString("real_name"));
        user.setRole(rs.getString("role"));
        user.setEmail(rs.getString("email"));
        user.setPhone(rs.getString("phone"));
        user.setStudentId(rs.getString("student_id"));
        user.setDepartment(rs.getString("department"));
        user.setGrade(rs.getString("grade"));
        user.setClassName(rs.getString("class_name"));
        user.setGender(rs.getString("gender"));
        user.setAvatarUrl(rs.getString("avatar_url"));
        user.setStatus(rs.getInt("status"));
        user.setLastLoginTime(rs.getTimestamp("last_login_time"));
        user.setLastLoginIp(rs.getString("last_login_ip"));
        user.setCreatedAt(rs.getTimestamp("created_at"));
        user.setUpdatedAt(rs.getTimestamp("updated_at"));
        return user;
    }
}
