package com.psychology.dao;

import com.psychology.entity.ScaleQuestion;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 量表题目DAO
 */
public class ScaleQuestionDao {

    /**
     * 根据量表ID查询所有启用的题目（按题号排序）
     */
    public List<ScaleQuestion> findByScaleId(Integer scaleId) {
        String sql = "SELECT * FROM scale_question WHERE scale_id=? AND status=1 ORDER BY question_no";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<ScaleQuestion> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, scaleId);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractQuestion(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 根据量表编码查询题目
     */
    public List<ScaleQuestion> findByScaleCode(String scaleCode) {
        String sql = "SELECT q.* FROM scale_question q " +
                "INNER JOIN scale s ON q.scale_id = s.id " +
                "WHERE s.code=? AND q.status=1 ORDER BY q.question_no";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<ScaleQuestion> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, scaleCode);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractQuestion(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 批量新增题目
     */
    public int[] batchAdd(List<ScaleQuestion> questions) {
        String sql = "INSERT INTO scale_question (scale_id, question_no, content, dimension, score_type, status) " +
                "VALUES (?, ?, ?, ?, ?, 1)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            for (ScaleQuestion q : questions) {
                ps.setInt(1, q.getScaleId());
                ps.setInt(2, q.getQuestionNo());
                ps.setString(3, q.getContent());
                ps.setString(4, q.getDimension());
                ps.setInt(5, q.getScoreType() != null ? q.getScoreType() : 1);
                ps.addBatch();
            }
            return ps.executeBatch();
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return new int[0];
    }

    private ScaleQuestion extractQuestion(ResultSet rs) throws SQLException {
        ScaleQuestion q = new ScaleQuestion();
        q.setId(rs.getInt("id"));
        q.setScaleId(rs.getInt("scale_id"));
        q.setQuestionNo(rs.getInt("question_no"));
        q.setContent(rs.getString("content"));
        q.setDimension(rs.getString("dimension"));
        q.setScoreType(rs.getInt("score_type"));
        q.setStatus(rs.getInt("status"));
        return q;
    }
}
