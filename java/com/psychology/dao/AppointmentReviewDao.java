package com.psychology.dao;

import com.psychology.entity.AppointmentReview;
import com.psychology.util.DBUtil;

import java.sql.*;

/**
 * 咨询评价DAO
 */
public class AppointmentReviewDao {

    public boolean add(AppointmentReview review) {
        String sql = "INSERT INTO appointment_review (appointment_id, student_id, counselor_id, " +
                "rating, feedback_content, is_anonymous) VALUES (?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, review.getAppointmentId());
            ps.setInt(2, review.getStudentId());
            ps.setInt(3, review.getCounselorId());
            ps.setInt(4, review.getRating());
            ps.setString(5, review.getFeedbackContent());
            ps.setInt(6, review.getAnonymous() != null ? review.getAnonymous() : 0);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return false;
    }

    public AppointmentReview findByAppointmentId(Long appointmentId) {
        String sql = "SELECT * FROM appointment_review WHERE appointment_id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, appointmentId);
            rs = ps.executeQuery();
            if (rs.next()) {
                AppointmentReview r = new AppointmentReview();
                r.setId(rs.getLong("id"));
                r.setAppointmentId(rs.getLong("appointment_id"));
                r.setStudentId(rs.getInt("student_id"));
                r.setCounselorId(rs.getInt("counselor_id"));
                r.setRating(rs.getInt("rating"));
                r.setFeedbackContent(rs.getString("feedback_content"));
                Object anon = rs.getObject("is_anonymous");
                if (anon != null) r.setAnonymous(((Number) anon).intValue());
                r.setCreatedAt(rs.getTimestamp("created_at"));
                return r;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }
}
