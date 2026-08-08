package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 文件上传记录实体
 */
public class FileUpload implements Serializable {
    private Long id;
    private String fileName;         // 原始文件名
    private String storedName;       // 存储文件名(UUID)
    private String filePath;          // 存储路径
    private Long fileSize;            // 文件大小(bytes)
    private String fileType;          // 文件类型(MIME)
    private Integer uploaderId;       // 上传者ID
    private String uploaderRole;      // 上传者角色: STUDENT/COUNSELOR/ADMIN
    private String relatedType;       // 关联类型
    private Long relatedId;           // 关联业务ID
    private Integer encrypted;        // 是否加密
    private String encryptionKey;     // 加密密钥
    private Integer downloadCount;    // 下载次数
    private Integer status;
    private Date createdAt;

    public FileUpload() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }
    public String getStoredName() { return storedName; }
    public void setStoredName(String storedName) { this.storedName = storedName; }
    public String getFilePath() { return filePath; }
    public void setFilePath(String filePath) { this.filePath = filePath; }
    public Long getFileSize() { return fileSize; }
    public void setFileSize(Long fileSize) { this.fileSize = fileSize; }
    public String getFileType() { return fileType; }
    public void setFileType(String fileType) { this.fileType = fileType; }
    public Integer getUploaderId() { return uploaderId; }
    public void setUploaderId(Integer uploaderId) { this.uploaderId = uploaderId; }
    public String getUploaderRole() { return uploaderRole; }
    public void setUploaderRole(String uploaderRole) { this.uploaderRole = uploaderRole; }
    public String getRelatedType() { return relatedType; }
    public void setRelatedType(String relatedType) { this.relatedType = relatedType; }
    public Long getRelatedId() { return relatedId; }
    public void setRelatedId(Long relatedId) { this.relatedId = relatedId; }
    public Integer getEncrypted() { return encrypted; }
    public void setEncrypted(Integer encrypted) { this.encrypted = encrypted; }
    public String getEncryptionKey() { return encryptionKey; }
    public void setEncryptionKey(String encryptionKey) { this.encryptionKey = encryptionKey; }
    public Integer getDownloadCount() { return downloadCount; }
    public void setDownloadCount(Integer downloadCount) { this.downloadCount = downloadCount; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
