package com.psychology.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 用户实体类（支持三类角色：学生/咨询师-辅导员/管理员）
 */
public class User implements Serializable {
    private Integer id;
    private String username;
    private String password;
    private String salt;
    private String realName;
    private String role; // STUDENT, COUNSELOR, ADMIN
    private String email;
    private String phone;
    private String studentId; // 学号（仅学生角色）
    private String department; // 院系
    private String grade; // 年级
    private String className; // 班级
    private String gender; // MALE, FEMALE
    private String avatarUrl;
    private Integer status; // 0禁用,1正常
    private Date lastLoginTime;
    private String lastLoginIp;
    private Date createdAt;
    private Date updatedAt;

    public User() {}

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    
    public String getSalt() { return salt; }
    public void setSalt(String salt) { this.salt = salt; }
    
    public String getRealName() { return realName; }
    public void setRealName(String realName) { this.realName = realName; }
    
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    
    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }
    
    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }
    
    public String getGrade() { return grade; }
    public void setGrade(String grade) { this.grade = grade; }
    
    public String getClassName() { return className; }
    public void setClassName(String className) { this.className = className; }
    
    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
    
    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    
    public Date getLastLoginTime() { return lastLoginTime; }
    public void setLastLoginTime(Date lastLoginTime) { this.lastLoginTime = lastLoginTime; }
    
    public String getLastLoginIp() { return lastLoginIp; }
    public void setLastLoginIp(String lastLoginIp) { this.lastLoginIp = lastLoginIp; }
    
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
    
    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }

    /**
     * 是否是学生
     */
    public boolean isStudent() {
        return "STUDENT".equals(role);
    }

    /**
     * 是否是咨询师/辅导员
     */
    public boolean isCounselor() {
        return "COUNSELOR".equals(role);
    }

    /**
     * 是否是管理员
     */
    public boolean isAdmin() {
        return "ADMIN".equals(role);
    }

    /**
     * 获取脱敏后的姓名显示
     */
    public String getMaskedName() {
        return com.psychology.util.CommonUtil.maskName(realName);
    }
}
