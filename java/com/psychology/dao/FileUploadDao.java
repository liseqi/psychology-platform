package com.psychology.dao;

import com.psychology.entity.FileUpload;
import com.psychology.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 文件上传DAO
 */
public class FileUploadDao {

    public long add(FileUpload fileUpload) {
        String sql = "INSERT INTO file_upload (file_name, stored_name, file_path, file_size, " +
                "file_type, uploader_id, uploader_role, related_type, related_id, " +
                "is_encrypted, encryption_key, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, fileUpload.getFileName());
            ps.setString(2, fileUpload.getStoredName());
            ps.setString(3, fileUpload.getFilePath());
            if (fileUpload.getFileSize() != null) {
                ps.setLong(4, fileUpload.getFileSize());
            } else {
                ps.setNull(4, Types.BIGINT);
            }
            ps.setString(5, fileUpload.getFileType());
            ps.setInt(6, fileUpload.getUploaderId());
            ps.setString(7, fileUpload.getUploaderRole());
            ps.setString(8, fileUpload.getRelatedType());
            if (fileUpload.getRelatedId() != null) {
                ps.setLong(9, fileUpload.getRelatedId());
            } else {
                ps.setNull(9, Types.BIGINT);
            }
            ps.setInt(10, fileUpload.getEncrypted() != null ? fileUpload.getEncrypted() : 0);
            ps.setString(11, fileUpload.getEncryptionKey());

            int rows = ps.executeUpdate();
            if (rows > 0) {
                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    return generatedKeys.getLong(1);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
        return 0;
    }

    public FileUpload findById(Long id) {
        String sql = "SELECT * FROM file_upload WHERE id=? AND status=1";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractFile(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return null;
    }

    public List<FileUpload> findByUploader(Integer uploaderId) {
        String sql = "SELECT * FROM file_upload WHERE uploader_id=? AND status=1 ORDER BY created_at DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<FileUpload> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, uploaderId);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractFile(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 按关联类型和操作者查询文件记录（用于导出记录等场景）
     */
    public List<FileUpload> findByTypeAndUploader(String relatedType, Integer uploaderId, int limit) {
        StringBuilder sql = new StringBuilder(
                "SELECT * FROM file_upload WHERE related_type=? AND status=1");
        if (uploaderId != null) {
            sql.append(" AND uploader_id=?");
        }
        sql.append(" ORDER BY created_at DESC LIMIT ?");
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<FileUpload> list = new ArrayList<>();
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql.toString());
            ps.setString(1, relatedType);
            int idx = 2;
            if (uploaderId != null) {
                ps.setInt(idx++, uploaderId);
            }
            ps.setInt(idx, limit);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractFile(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps, rs);
        }
        return list;
    }

    /**
     * 增加下载次数
     */
    public void incrementDownloadCount(Long id) {
        String sql = "UPDATE file_upload SET download_count = COALESCE(download_count,0)+1 WHERE id=?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(conn, ps);
        }
    }

    private FileUpload extractFile(ResultSet rs) throws SQLException {
        FileUpload f = new FileUpload();
        f.setId(rs.getLong("id"));
        f.setFileName(rs.getString("file_name"));
        f.setStoredName(rs.getString("stored_name"));
        f.setFilePath(rs.getString("file_path"));
        Object fsz = rs.getObject("file_size");
        if (fsz != null) f.setFileSize(((Number) fsz).longValue());
        f.setFileType(rs.getString("file_type"));
        f.setUploaderId(rs.getInt("uploader_id"));
        f.setUploaderRole(rs.getString("uploader_role"));
        f.setRelatedType(rs.getString("related_type"));
        Object rid = rs.getObject("related_id");
        if (rid != null) f.setRelatedId(((Number) rid).longValue());
        Object enc = rs.getObject("is_encrypted");
        if (enc != null) f.setEncrypted(((Number) enc).intValue());
        f.setEncryptionKey(rs.getString("encryption_key"));
        Object dc = rs.getObject("download_count");
        if (dc != null) f.setDownloadCount(((Number) dc).intValue());
        f.setStatus(rs.getInt("status"));
        f.setCreatedAt(rs.getTimestamp("created_at"));
        return f;
    }
}
