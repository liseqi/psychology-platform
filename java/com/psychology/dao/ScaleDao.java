package com.psychology.dao;

import com.psychology.entity.Scale;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 测评量表DAO
 */
public class ScaleDao {

    /**
     * 查询所有启用的量表
     */
    public List<Scale> findAllEnabled() {
        String sql = "SELECT * FROM scale WHERE status=1 ORDER BY id";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Scale> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractScale(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 统计总量表数量（不含已删除的）
     */
    public long countAll() {
        String sql = "SELECT COUNT(*) FROM scale WHERE status >= 0";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
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
     * 根据ID查询量表
     */
    public Scale findById(Integer id) {
        String sql = "SELECT * FROM scale WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractScale(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    /**
     * 管理员查询所有量表（含停用的）
     */
    public List<Scale> findAll(int page, int pageSize) {
        String sql = "SELECT * FROM scale ORDER BY id DESC LIMIT ?,?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Scale> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, (page - 1) * pageSize);
            ps.setInt(2, pageSize);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractScale(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 新增量表（管理员用）
     */
    public int add(Scale scale) {
        String sql = "INSERT INTO scale (name, code, description, instruction, category, " +
                "total_questions, time_limit, status, creator_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, scale.getName());
            ps.setString(2, scale.getCode());
            ps.setString(3, scale.getDescription());
            ps.setString(4, scale.getInstruction());
            ps.setString(5, scale.getCategory());
            ps.setInt(6, scale.getTotalQuestions());
            if (scale.getTimeLimit() != null) {
                ps.setInt(7, scale.getTimeLimit());
            } else {
                ps.setNull(7, Types.INTEGER);
            }
            ps.setInt(8, scale.getStatus() != null ? scale.getStatus() : 1);
            if (scale.getCreatorId() != null) {
                ps.setInt(9, scale.getCreatorId());
            } else {
                ps.setNull(9, Types.INTEGER);
            }

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
     * 更新量表状态（启用/停用）
     */
    public boolean updateStatus(Integer id, Integer status) {
        String sql = "UPDATE scale SET status=?, updated_at=NOW() WHERE id=?";
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
     * 收藏/取消收藏量表
     */
    public boolean toggleFavorite(Integer userId, Integer scaleId) {
        // 先检查是否已收藏
        String checkSql = "SELECT id FROM scale_favorite WHERE user_id=? AND scale_id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(checkSql);
            ps.setInt(1, userId);
            ps.setInt(2, scaleId);
            rs = ps.executeQuery();

            if (rs.next()) {
                // 已存在则删除（取消收藏）
                DBUtil.closePS(ps);
                String deleteSql = "DELETE FROM scale_favorite WHERE user_id=? AND scale_id=?";
                ps = conn.prepareStatement(deleteSql);
                ps.setInt(1, userId);
                ps.setInt(2, scaleId);
                ps.executeUpdate();
                return false;
            } else {
                // 不存在则新增（收藏）
                DBUtil.closePS(ps);
                String insertSql = "INSERT INTO scale_favorite (user_id, scale_id) VALUES (?, ?)";
                ps = conn.prepareStatement(insertSql);
                ps.setInt(1, userId);
                ps.setInt(2, scaleId);
                ps.executeUpdate();
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return false;
    }

    /**
     * 查询用户收藏的量表
     */
    public List<Scale> findFavorites(Integer userId) {
        String sql = "SELECT s.*, sf.id as favorite_id FROM scale s " +
                "INNER JOIN scale_favorite sf ON s.id = sf.scale_id " +
                "WHERE sf.user_id=? AND s.status=1 ORDER BY sf.created_at DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Scale> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            while (rs.next()) {
                Scale scale = extractScale(rs);
                scale.setFavorited(true);
                list.add(scale);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 查询用户是否收藏了某个量表
     */
    public boolean isFavorited(Integer userId, Integer scaleId) {
        String sql = "SELECT COUNT(*) FROM scale_favorite WHERE user_id=? AND scale_id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setInt(2, scaleId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return false;
    }

    private Scale extractScale(ResultSet rs) throws SQLException {
        Scale scale = new Scale();
        scale.setId(rs.getInt("id"));
        scale.setName(rs.getString("name"));
        scale.setCode(rs.getString("code"));
        scale.setDescription(rs.getString("description"));
        scale.setInstruction(rs.getString("instruction"));
        scale.setCategory(rs.getString("category"));
        Object qObj = rs.getObject("total_questions");
        if (qObj != null) scale.setTotalQuestions(((Number) qObj).intValue());
        Object tObj = rs.getObject("time_limit");
        if (tObj != null) scale.setTimeLimit(((Number) tObj).intValue());
        Object sObj = rs.getObject("status");
        if (sObj != null) scale.setStatus(((Number) sObj).intValue());
        Object cObj = rs.getObject("creator_id");
        if (cObj != null) scale.setCreatorId(((Number) cObj).intValue());
        scale.setCreatedAt(rs.getTimestamp("created_at"));
        scale.setUpdatedAt(rs.getTimestamp("updated_at"));
        return scale;
    }
}
