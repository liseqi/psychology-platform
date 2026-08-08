/*
 Navicat Premium Dump SQL

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80044 (8.0.44)
 Source Host           : localhost:3306
 Source Schema         : psychology

 Target Server Type    : MySQL
 Target Server Version : 80044 (8.0.44)
 File Encoding         : 65001

 Date: 16/07/2026 10:26:12
*/

CREATE DATABASE IF NOT EXISTS psychology DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE psychology;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `alert_config`;

-- ----------------------------
-- Table structure for alert_config
-- ----------------------------
CREATE TABLE `alert_config`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `config_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '配置键',
  `config_value` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '配置值',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '配置说明',
  `updated_by` int NULL DEFAULT NULL COMMENT '更新人ID',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `config_key`(`config_key` ASC) USING BTREE,
  INDEX `updated_by`(`updated_by` ASC) USING BTREE,
  CONSTRAINT `alert_config_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '预警配置表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of alert_config
-- ----------------------------
INSERT INTO `alert_config` VALUES (1, 'low_risk_threshold', '160', 'SCL-90低风险阈值(总分低于此值为低风险)', NULL, '2026-07-10 17:30:29');
INSERT INTO `alert_config` VALUES (2, 'medium_risk_threshold', '200', 'SCL-90中风险阈值(总分介于低和中之间为中风险)', NULL, '2026-07-10 17:30:29');
INSERT INTO `alert_config` VALUES (3, 'high_risk_threshold', '250', 'SCL-90高风险阈值(总分高于此值为高风险)', NULL, '2026-07-10 17:30:29');
INSERT INTO `alert_config` VALUES (4, 'sds_threshold', '53', 'SDS标准分临界值(高于此值需关注)', NULL, '2026-07-10 17:30:29');
INSERT INTO `alert_config` VALUES (5, 'sas_threshold', '50', 'SAS标准分临界值(高于此值需关注)', NULL, '2026-07-10 17:30:29');
INSERT INTO `alert_config` VALUES (6, 'min_answer_duration', '60', '最小有效答题时长(秒),短于此标记为疑似作弊', NULL, '2026-07-10 17:30:29');
INSERT INTO `alert_config` VALUES (7, 'repeat_submit_interval', '3600', '同一量表重复提交间隔(秒)', NULL, '2026-07-10 17:30:29');
INSERT INTO `alert_config` VALUES (8, 'daily_chat_limit', '50', '每日AI对话次数上限', NULL, '2026-07-10 17:30:29');

-- ----------------------------
-- Table structure for alert_record
-- ----------------------------
DROP TABLE IF EXISTS `alert_record`;
CREATE TABLE `alert_record`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL COMMENT '预警学生ID',
  `assessment_record_id` bigint NULL DEFAULT NULL COMMENT '触发预警的测评记录ID',
  `chat_session_id` bigint NULL DEFAULT NULL COMMENT '触发的树洞会话ID',
  `alert_level` enum('LOW','MEDIUM','HIGH') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '预警级别:低/中/高',
  `alert_type` enum('ASSESSMENT','CHAT','MANUAL') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '预警来源:测评/树洞/手动录入',
  `trigger_reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '触发原因描述',
  `score_value` decimal(10, 2) NULL DEFAULT NULL COMMENT '触发分数值',
  `status` enum('PENDING','PROCESSING','INTERVENING','RESOLVED','CLOSED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'PENDING' COMMENT '处理状态',
  `assigned_counselor_id` int NULL DEFAULT NULL COMMENT '分配的咨询师ID',
  `assigned_counselor_role` enum('COUNSELOR','ADMIN') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分配对象角色(咨询师/辅导员)',
  `intervention_record` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '干预跟进记录',
  `intervention_result` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '干预结果',
  `resolved_at` datetime NULL DEFAULT NULL COMMENT '解决时间',
  `resolved_by` int NULL DEFAULT NULL COMMENT '解决操作人',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_student_id`(`student_id` ASC) USING BTREE,
  INDEX `idx_alert_level`(`alert_level` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_assigned_counselor`(`assigned_counselor_id` ASC) USING BTREE,
  CONSTRAINT `alert_record_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `alert_record_ibfk_2` FOREIGN KEY (`assigned_counselor_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 65 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '预警记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of alert_record
-- ----------------------------
INSERT INTO `alert_record` VALUES (2, 4, 3, NULL, 'HIGH', 'ASSESSMENT', 'PHQ-9得分15分，重度抑郁倾向', 72.00, 'PENDING', 86, NULL, NULL, NULL, NULL, NULL, '2025-09-12 15:32:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (4, 4, 10, NULL, 'HIGH', 'ASSESSMENT', '连续两次高风险测评', 78.00, 'PENDING', 10, NULL, NULL, NULL, NULL, NULL, '2026-01-07 09:35:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (5, 5, 11, NULL, 'HIGH', 'ASSESSMENT', '抑郁指数持续上升', 73.00, 'PENDING', 2, NULL, NULL, NULL, NULL, NULL, '2026-02-08 14:36:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (6, 5, 4, NULL, 'MEDIUM', 'ASSESSMENT', '中度压力水平', 48.00, 'INTERVENING', 3, NULL, NULL, NULL, NULL, NULL, '2025-09-14 11:29:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (10, 5, 18, NULL, 'MEDIUM', 'ASSESSMENT', '考试焦虑倾向', 51.00, 'PROCESSING', 87, NULL, NULL, NULL, NULL, NULL, '2026-05-09 14:58:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (11, 6, 12, NULL, 'MEDIUM', 'ASSESSMENT', '睡眠质量下降', 62.00, 'INTERVENING', 10, NULL, NULL, NULL, NULL, NULL, '2026-03-03 10:00:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (12, 7, 13, NULL, 'MEDIUM', 'ASSESSMENT', '情绪管理困难', 67.00, 'PENDING', 2, NULL, NULL, NULL, NULL, NULL, '2026-03-10 10:31:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (15, 6, 5, NULL, 'LOW', 'ASSESSMENT', '偶发性紧张情绪', 65.00, 'RESOLVED', 21, NULL, NULL, NULL, NULL, NULL, '2025-10-10 14:32:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (16, 7, 20, NULL, 'LOW', 'ASSESSMENT', '轻度适应问题', 38.00, 'PENDING', 86, NULL, NULL, NULL, NULL, NULL, '2026-06-03 09:25:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (19, 4, 3, NULL, 'HIGH', 'ASSESSMENT', 'PHQ-9得分15分，重度抑郁倾向', 72.00, 'PENDING', 2, NULL, NULL, NULL, NULL, NULL, '2025-09-12 15:32:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (21, 4, 10, NULL, 'HIGH', 'ASSESSMENT', '连续两次高风险测评', 78.00, 'PENDING', 20, NULL, NULL, NULL, NULL, NULL, '2026-01-07 09:35:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (22, 5, 11, NULL, 'HIGH', 'ASSESSMENT', '抑郁指数持续上升', 73.00, 'PROCESSING', 21, NULL, '啊啊啊', NULL, NULL, 21, '2026-02-08 14:36:00', '2026-07-15 17:22:41');
INSERT INTO `alert_record` VALUES (23, 5, 4, NULL, 'MEDIUM', 'ASSESSMENT', '中度压力水平', 48.00, 'INTERVENING', 86, NULL, NULL, NULL, NULL, NULL, '2025-09-14 11:29:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (27, 5, 18, NULL, 'MEDIUM', 'ASSESSMENT', '考试焦虑倾向', 51.00, 'PROCESSING', 3, NULL, NULL, NULL, NULL, NULL, '2026-05-09 14:58:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (28, 6, 12, NULL, 'MEDIUM', 'ASSESSMENT', '睡眠质量下降', 62.00, 'INTERVENING', 20, NULL, NULL, NULL, NULL, NULL, '2026-03-03 10:00:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (29, 7, 13, NULL, 'MEDIUM', 'ASSESSMENT', '情绪管理困难', 67.00, 'PROCESSING', 21, NULL, 'mmm', NULL, NULL, 21, '2026-03-10 10:31:00', '2026-07-15 18:31:56');
INSERT INTO `alert_record` VALUES (32, 6, 5, NULL, 'LOW', 'ASSESSMENT', '偶发性紧张情绪', 65.00, 'RESOLVED', 10, NULL, NULL, NULL, NULL, NULL, '2025-10-10 14:32:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (33, 7, 20, NULL, 'LOW', 'ASSESSMENT', '轻度适应问题', 38.00, 'PENDING', 2, NULL, NULL, NULL, NULL, NULL, '2026-06-03 09:25:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (36, 4, 3, NULL, 'HIGH', 'ASSESSMENT', 'PHQ-9得分15分重度抑郁', 72.00, 'PENDING', 21, NULL, NULL, NULL, NULL, NULL, '2025-09-12 15:32:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (37, 6, 6, NULL, 'HIGH', 'ASSESSMENT', '焦虑自评量表显示严重焦虑', 65.00, 'PROCESSING', 86, NULL, NULL, NULL, NULL, NULL, '2025-10-10 14:32:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (38, 5, 17, NULL, 'HIGH', 'ASSESSMENT', '连续两次高风险测评', 75.00, 'PENDING', 87, NULL, NULL, NULL, NULL, NULL, '2026-01-07 09:35:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (39, 7, 26, NULL, 'HIGH', 'ASSESSMENT', '抑郁指数持续上升', 64.00, 'PENDING', 10, NULL, NULL, NULL, NULL, NULL, '2026-05-14 11:30:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (40, 5, 4, NULL, 'MEDIUM', 'ASSESSMENT', '中度压力水平', 48.00, 'INTERVENING', 2, NULL, NULL, NULL, NULL, NULL, '2025-09-14 11:29:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (41, 4, 13, NULL, 'MEDIUM', 'ASSESSMENT', '情绪波动较大', 58.00, 'PENDING', 3, NULL, NULL, NULL, NULL, NULL, '2025-12-05 14:31:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (44, 5, 24, NULL, 'MEDIUM', 'ASSESSMENT', '人际关系敏感', 56.00, 'PENDING', 86, NULL, NULL, NULL, NULL, NULL, '2026-04-10 14:00:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (46, 19, 32, NULL, 'MEDIUM', 'ASSESSMENT', '睡眠质量下降', 54.00, 'PENDING', 10, NULL, NULL, NULL, NULL, NULL, '2026-06-10 15:28:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (49, 7, 7, NULL, 'LOW', 'ASSESSMENT', '偶发性紧张情绪', 40.00, 'RESOLVED', 20, NULL, NULL, NULL, NULL, NULL, '2025-10-20 10:57:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (50, 19, 8, NULL, 'LOW', 'ASSESSMENT', '轻度适应问题', 38.00, 'RESOLVED', 21, NULL, NULL, NULL, NULL, NULL, '2025-10-25 16:24:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (51, 6, 30, NULL, 'LOW', 'ASSESSMENT', '季节性情绪低落', 38.00, 'PENDING', 86, NULL, NULL, NULL, NULL, NULL, '2026-06-03 09:55:00', '2026-07-15 16:31:27');
INSERT INTO `alert_record` VALUES (52, 17, 98, NULL, 'HIGH', 'ASSESSMENT', '测评得分异常: 2, 总分=100.0, 风险等级=HIGH', 100.00, 'PROCESSING', 21, NULL, '来', NULL, NULL, 21, '2026-07-14 01:52:03', '2026-07-16 01:17:10');
INSERT INTO `alert_record` VALUES (53, 12, 99, NULL, 'HIGH', 'ASSESSMENT', 'SCL-90总分245，抑郁维度3.8分，超过临床警戒线', 245.00, 'PENDING', 20, NULL, NULL, NULL, NULL, NULL, '2025-07-10 09:30:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (54, 12, 100, NULL, 'MEDIUM', 'ASSESSMENT', 'SDS标准分58，提示中度抑郁倾向', 58.00, 'PROCESSING', 20, NULL, NULL, NULL, NULL, NULL, '2025-07-12 14:10:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (55, 13, 102, NULL, 'MEDIUM', 'ASSESSMENT', 'SCL-90总分180，人际关系敏感偏高', 180.00, 'PENDING', 21, NULL, NULL, NULL, NULL, NULL, '2025-07-11 10:25:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (56, 14, 111, NULL, 'HIGH', 'ASSESSMENT', 'SCL-90总分280，多项维度严重超标，需立即启动危机干预', 280.00, 'PENDING', 20, NULL, NULL, NULL, NULL, NULL, '2025-07-14 08:30:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (57, 16, 114, NULL, 'HIGH', 'ASSESSMENT', 'PHQ-9总分22，提示重度抑郁，有自伤意念，需紧急关注', 22.00, 'PENDING', 21, NULL, NULL, NULL, NULL, NULL, '2025-07-12 09:08:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (58, 19, 119, NULL, 'HIGH', 'ASSESSMENT', 'SDS标准分72，提示重度抑郁', 72.00, 'PENDING', 86, NULL, NULL, NULL, NULL, NULL, '2025-07-14 10:12:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (59, 79, 122, NULL, 'HIGH', 'ASSESSMENT', 'SAS标准分65，提示重度焦虑', 65.00, 'PROCESSING', 21, NULL, '干涉', NULL, NULL, 21, '2025-07-13 08:10:00', '2026-07-15 17:50:06');
INSERT INTO `alert_record` VALUES (60, 15, 113, NULL, 'MEDIUM', 'ASSESSMENT', 'SAS标准分52，提示中度焦虑', 52.00, 'PROCESSING', 87, NULL, NULL, NULL, NULL, NULL, '2025-07-13 11:12:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (61, 16, 115, NULL, 'MEDIUM', 'ASSESSMENT', 'GAD-7总分16，提示中度广泛性焦虑', 16.00, 'PROCESSING', 21, NULL, NULL, NULL, NULL, NULL, '2025-07-12 09:18:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (62, 18, 118, NULL, 'MEDIUM', 'ASSESSMENT', 'SCL-90总分175，建议团体辅导', 175.00, 'RESOLVED', 20, NULL, '已安排团体心理辅导，每周三下午参加人际关系成长小组', NULL, '2025-07-10 16:00:00', 20, '2025-07-09 13:25:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (63, 12, 101, NULL, 'LOW', 'ASSESSMENT', 'SAS标准分42，轻度焦虑，系统自动记录', 42.00, 'CLOSED', 20, NULL, '无需干预，系统自动监测中', NULL, '2025-06-25 10:00:00', 20, '2025-06-20 10:10:00', '2026-07-15 16:19:16');
INSERT INTO `alert_record` VALUES (64, 14, NULL, 2, 'HIGH', 'CHAT', 'AI树洞检测到用户表达绝望情绪和自杀意念，触发高危预警', NULL, 'PENDING', 20, NULL, NULL, NULL, NULL, NULL, '2026-07-14 16:20:10', '2026-07-15 16:20:10');

-- ----------------------------
-- Table structure for appointment
-- ----------------------------
DROP TABLE IF EXISTS `appointment`;
CREATE TABLE `appointment`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL COMMENT '学生ID',
  `counselor_id` int NOT NULL COMMENT '咨询师ID',
  `schedule_id` int NULL DEFAULT NULL,
  `appointment_date` date NOT NULL COMMENT '预约日期',
  `time_slot` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '预约时段',
  `status` enum('PENDING','CONFIRMED','COMPLETED','CANCELLED','NO_SHOW','RESCHEDULED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'PENDING' COMMENT '状态:待确认/已确认/已完成/已取消/未到场/改期',
  `consultation_topic` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '咨询主题/问题描述',
  `cancel_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '取消原因',
  `cancelled_by` int NULL DEFAULT NULL COMMENT '取消操作人ID',
  `cancel_time` datetime NULL DEFAULT NULL COMMENT '取消时间',
  `reschedule_from_id` bigint NULL DEFAULT NULL COMMENT '原预约记录ID(改期时关联)',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `schedule_id`(`schedule_id` ASC) USING BTREE,
  INDEX `idx_student_id`(`student_id` ASC) USING BTREE,
  INDEX `idx_counselor_id`(`counselor_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_date`(`appointment_date` ASC) USING BTREE,
  CONSTRAINT `appointment_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `appointment_ibfk_2` FOREIGN KEY (`counselor_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `appointment_ibfk_3` FOREIGN KEY (`schedule_id`) REFERENCES `counselor_schedule` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 38 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '咨询预约表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of appointment
-- ----------------------------
INSERT INTO `appointment` VALUES (14, 17, 21, NULL, '2026-07-15', '10:00-10:50', 'CONFIRMED', NULL, NULL, NULL, NULL, NULL, '2026-07-14 11:02:19', '2026-07-15 19:21:55');
INSERT INTO `appointment` VALUES (15, 17, 21, NULL, '2026-07-16', '10:00-10:50', 'CANCELLED', NULL, '学生主动取消', 17, '2026-07-14 12:15:44', NULL, '2026-07-14 11:53:27', '2026-07-14 12:15:44');
INSERT INTO `appointment` VALUES (16, 18, 2, NULL, '2026-07-23', '10:00-10:50', 'PENDING', NULL, NULL, NULL, NULL, NULL, '2026-07-14 12:16:09', '2026-07-14 12:16:09');
INSERT INTO `appointment` VALUES (17, 17, 2, NULL, '2026-07-16', '10:00-10:50', 'CANCELLED', NULL, '学生主动取消', 17, '2026-07-14 19:18:33', NULL, '2026-07-14 19:18:05', '2026-07-14 19:18:33');
INSERT INTO `appointment` VALUES (18, 17, 21, NULL, '2026-07-16', '10:00-10:50', 'CANCELLED', NULL, '学生主动取消', 17, '2026-07-15 15:45:43', NULL, '2026-07-14 19:18:42', '2026-07-15 15:45:43');
INSERT INTO `appointment` VALUES (19, 33, 21, NULL, '2026-07-07', '09:00-10:00', 'COMPLETED', '学习压力大、考试焦虑严重、睡眠质量差', NULL, NULL, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `appointment` VALUES (20, 34, 21, NULL, '2026-07-11', '14:00-15:00', 'COMPLETED', '宿舍人际关系紧张、与室友沟通困难', NULL, NULL, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `appointment` VALUES (21, 35, 21, NULL, '2026-07-14', '15:00-16:00', 'CONFIRMED', '情绪波动大、容易焦虑和低落', NULL, NULL, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `appointment` VALUES (22, 36, 21, NULL, '2026-06-14', '10:00-11:00', 'COMPLETED', '职业规划迷茫、对未来方向不确定', NULL, NULL, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `appointment` VALUES (23, 37, 21, NULL, '2026-06-30', '09:00-10:00', 'CANCELLED', '适应困难、想了解如何融入新环境', NULL, NULL, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `appointment` VALUES (24, 17, 2, NULL, '2026-07-16', '10:00-10:50', 'CANCELLED', NULL, '学生主动取消', 17, '2026-07-15 19:22:16', NULL, '2026-07-15 15:45:39', '2026-07-15 19:22:16');
INSERT INTO `appointment` VALUES (25, 12, 20, 905, '2026-07-15', '09:00-10:00', 'PENDING', '学业压力过大，经常失眠，希望得到专业指导', NULL, NULL, NULL, NULL, '2026-07-15 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (26, 13, 21, 910, '2026-07-15', '10:00-11:00', 'CONFIRMED', '人际关系敏感，与室友相处困难', NULL, NULL, NULL, NULL, '2026-07-15 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (27, 14, 20, 907, '2026-07-15', '14:00-15:00', 'CONFIRMED', '近两周情绪非常低落，对什么都提不起兴趣', NULL, NULL, NULL, NULL, '2026-07-15 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (28, 16, 21, 911, '2026-07-15', '14:00-15:00', 'CONFIRMED', '最近总是控制不住地担忧，影响学习和生活', NULL, NULL, NULL, NULL, '2026-07-15 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (29, 15, 20, NULL, '2026-07-14', '09:00-10:00', 'COMPLETED', '学业压力和就业焦虑', NULL, NULL, NULL, NULL, '2026-07-14 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (30, 17, 21, 602, '2026-07-22', '10:00-11:00', 'PENDING', '情绪管理和自我认知', ' [改期原因:3]', NULL, NULL, NULL, '2026-07-14 16:19:17', '2026-07-16 01:17:48');
INSERT INTO `appointment` VALUES (31, 18, 20, NULL, '2026-07-13', '14:00-15:00', 'COMPLETED', '家庭关系问题', NULL, NULL, NULL, NULL, '2026-07-13 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (32, 78, 21, NULL, '2026-07-12', '09:00-10:00', 'COMPLETED', '社交焦虑和自信心提升', NULL, NULL, NULL, NULL, '2026-07-12 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (33, 12, 20, NULL, '2026-07-10', '10:00-11:00', 'CANCELLED', '考前焦虑缓解', NULL, NULL, NULL, NULL, '2026-07-10 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (34, 13, 21, NULL, '2026-07-08', '14:00-15:00', 'COMPLETED', '情感困扰咨询', NULL, NULL, NULL, NULL, '2026-07-08 16:19:17', '2026-07-15 16:19:17');
INSERT INTO `appointment` VALUES (35, 7, 21, 627, '2026-07-15', '14:00-15:00', 'CONFIRMED', '预警干预咨询：情绪管理困难', NULL, NULL, NULL, NULL, '2026-07-15 17:49:17', '2026-07-15 18:31:56');
INSERT INTO `appointment` VALUES (36, 79, 21, NULL, '2026-07-15', '09:00-10:00', 'CONFIRMED', '预警干预咨询：SAS标准分65，提示重度焦虑', NULL, NULL, NULL, NULL, '2026-07-15 17:50:06', '2026-07-15 17:50:06');
INSERT INTO `appointment` VALUES (37, 17, 10, NULL, '2026-07-16', '10:00-10:50', 'CONFIRMED', NULL, NULL, NULL, NULL, NULL, '2026-07-15 21:03:56', '2026-07-16 01:15:12');

-- ----------------------------
-- Table structure for appointment_review
-- ----------------------------
DROP TABLE IF EXISTS `appointment_review`;
CREATE TABLE `appointment_review`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `appointment_id` bigint NOT NULL COMMENT '预约ID',
  `student_id` int NOT NULL COMMENT '评价学生ID',
  `counselor_id` int NOT NULL COMMENT '被评价咨询师ID',
  `rating` tinyint NOT NULL COMMENT '评分:1-5分',
  `feedback_content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '反馈内容',
  `is_anonymous` tinyint NULL DEFAULT 0 COMMENT '是否匿名:0实名,1匿名',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `appointment_id`(`appointment_id` ASC) USING BTREE,
  INDEX `student_id`(`student_id` ASC) USING BTREE,
  INDEX `counselor_id`(`counselor_id` ASC) USING BTREE,
  CONSTRAINT `appointment_review_ibfk_1` FOREIGN KEY (`appointment_id`) REFERENCES `appointment` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `appointment_review_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `appointment_review_ibfk_3` FOREIGN KEY (`counselor_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '咨询评价表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of appointment_review
-- ----------------------------
INSERT INTO `appointment_review` VALUES (1, 29, 15, 20, 5, '老师非常专业有耐心，呼吸放松法真的很有用，睡眠好多了！', 0, '2026-07-15 16:20:10');
INSERT INTO `appointment_review` VALUES (2, 30, 17, 21, 4, '王老师很温和，聊天很放松。OH卡牌让我对自己有了新的认识。', 0, '2026-07-15 16:20:10');
INSERT INTO `appointment_review` VALUES (3, 31, 18, 20, 5, '分析家庭问题非常透彻，教的方法很实用，家里关系改善了很多。', 1, '2026-07-15 16:20:10');
INSERT INTO `appointment_review` VALUES (4, 32, 78, 21, 4, '社交技能训练很有用，现在敢在小组讨论中发言了。', 0, '2026-07-15 16:20:10');
INSERT INTO `appointment_review` VALUES (5, 34, 13, 21, 5, '非常理解我，能完全敞开心扉。给了很多实用建议，走出了失恋阴影。', 0, '2026-07-15 16:20:10');

-- ----------------------------
-- Table structure for article
-- ----------------------------
DROP TABLE IF EXISTS `article`;
CREATE TABLE `article`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '标题',
  `category_id` int NOT NULL COMMENT '分类ID',
  `author_id` int NULL DEFAULT NULL COMMENT '作者ID(管理员)',
  `summary` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '摘要',
  `cover_image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '封面图URL',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '正文内容',
  `view_count` int NULL DEFAULT 0 COMMENT '阅读量',
  `like_count` int NULL DEFAULT 0 COMMENT '点赞数',
  `comment_count` int NULL DEFAULT 0 COMMENT '评论数',
  `status` enum('DRAFT','PENDING_REVIEW','PUBLISHED','REJECTED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'DRAFT' COMMENT '状态:草稿/待审核/已发布/驳回',
  `reviewer_id` int NULL DEFAULT NULL COMMENT '审核人ID',
  `review_note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '审核备注',
  `published_at` datetime NULL DEFAULT NULL COMMENT '发布时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `author_id`(`author_id` ASC) USING BTREE,
  INDEX `reviewer_id`(`reviewer_id` ASC) USING BTREE,
  INDEX `idx_category_id`(`category_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  FULLTEXT INDEX `ft_title_content`(`title`, `content`),
  CONSTRAINT `article_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `article_category` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `article_ibfk_2` FOREIGN KEY (`author_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `article_ibfk_3` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '科普文章表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of article
-- ----------------------------
INSERT INTO `article` VALUES (1, '大学生常见心理问题及应对策略', 1, 20, '大学阶段最常见的心理问题类型及其应对方法', NULL, '<h2>一、学业压力</h2><p>制定合理的学习计划、寻求学习伙伴、善用学校资源。</p><h2>二、人际关系</h2><p>学会有效沟通、设立个人边界。</p><h2>三、自我认同</h2><p>通过社团活动和实习实践发现自己的兴趣。</p><h2>四、寻求帮助</h2><p>学校心理咨询中心提供免费、保密的一对一咨询服务。</p>', 356, 42, 8, 'PUBLISHED', NULL, NULL, '2026-06-15 00:00:00', '2026-07-15 16:20:10', '2026-07-15 16:20:10');
INSERT INTO `article` VALUES (2, '如何与焦虑和平共处——认知行为疗法入门', 1, 21, 'CBT的核心理念和简单实用的自助技巧', NULL, '<h2>什么是CBT</h2><p>通过改变思维和行为来改善情绪。情绪不是由事件本身引起，而是由认知决定。</p><h2>三步识别自动负性思维</h2><p>记录-评估-替代。</p><h2>呼吸放松技巧</h2><p>4-7-8呼吸法：吸气4秒，屏息7秒，呼出8秒。</p>', 489, 67, 12, 'PUBLISHED', NULL, NULL, '2026-06-25 00:00:00', '2026-07-15 16:20:10', '2026-07-15 16:20:10');
INSERT INTO `article` VALUES (3, '宿舍人际关系指南：从摩擦到和谐', 4, 86, '处理宿舍矛盾的实用沟通技巧和边界建立方法', NULL, '<h2>宿舍关系的特殊性</h2><p>不同成长背景、生活习惯的碰撞。</p><h2>建设性沟通四步法</h2><p>1.选择合适时机 2.用\"我\"句式 3.提出具体请求 4.表达协商态度</p>', 278, 35, 6, 'PUBLISHED', NULL, NULL, '2026-06-30 00:00:00', '2026-07-15 16:20:10', '2026-07-15 16:20:10');
INSERT INTO `article` VALUES (4, '正念冥想入门：每天十分钟，找回内心平静', 5, 87, '从零开始的正念冥想指南', NULL, '<h2>什么是正念</h2><p>有意识地、不加评判地对当下的觉察。</p><h2>五分钟呼吸觉察</h2><p>1.找安静的地方坐下 2.关注呼吸 3.思绪飘走时温柔拉回</p>', 612, 89, 15, 'PUBLISHED', NULL, NULL, '2026-07-05 00:00:00', '2026-07-15 16:20:10', '2026-07-15 16:20:10');
INSERT INTO `article` VALUES (5, '考前焦虑自救手册', 2, 21, '考试季的心理调适完整方案', NULL, '<h2>焦虑的倒U型曲线</h2><p>适度焦虑最佳。考前一周：制定计划、规律作息、减少咖啡因。考试当天：提前到场、深呼吸、先做有把握的题。</p>', 723, 105, 20, 'PUBLISHED', NULL, NULL, '2026-07-10 00:00:00', '2026-07-15 16:20:10', '2026-07-15 16:20:10');
INSERT INTO `article` VALUES (6, '情绪日记：认识自己情绪的第一步', 1, 20, '通过情绪日记实现自我调节', NULL, '<h2>情绪日记模板</h2><p>日期、情境、感受、身体反应、想法、行为、反思。丰富情绪词汇库：沮丧、焦虑、欣慰、感激等。</p>', 198, 28, 2, 'PUBLISHED', NULL, NULL, '2026-07-12 00:00:00', '2026-07-15 16:20:10', '2026-07-15 16:20:10');

-- ----------------------------
-- Table structure for article_category
-- ----------------------------
DROP TABLE IF EXISTS `article_category`;
CREATE TABLE `article_category`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '分类名称',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分类描述',
  `sort_order` int NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint NULL DEFAULT 1 COMMENT '状态:0停用,1启用',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `name`(`name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '文章分类表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of article_category
-- ----------------------------
INSERT INTO `article_category` VALUES (1, '情绪疏导', '关于情绪管理、调节的文章', 1, 1, '2026-07-10 17:30:29');
INSERT INTO `article_category` VALUES (2, '压力缓解', '学习压力、生活压力应对方法', 2, 1, '2026-07-10 17:30:29');
INSERT INTO `article_category` VALUES (3, '恋爱心理', '恋爱关系、情感困惑指导', 3, 1, '2026-07-10 17:30:29');
INSERT INTO `article_category` VALUES (4, '人际交往', '人际沟通、社交技巧提升', 4, 1, '2026-07-10 17:30:29');
INSERT INTO `article_category` VALUES (5, '自我成长', '自我认知、个人发展', 5, 1, '2026-07-10 17:30:29');

-- ----------------------------
-- Table structure for article_comment
-- ----------------------------
DROP TABLE IF EXISTS `article_comment`;
CREATE TABLE `article_comment`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `article_id` bigint NOT NULL COMMENT '文章ID',
  `user_id` int NOT NULL COMMENT '评论用户ID',
  `parent_id` bigint NULL DEFAULT NULL COMMENT '父评论ID(回复功能)',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '评论内容',
  `status` enum('PENDING','APPROVED','REJECTED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'PENDING' COMMENT '审核状态',
  `like_count` int NULL DEFAULT 0 COMMENT '点赞数',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `parent_id`(`parent_id` ASC) USING BTREE,
  INDEX `idx_article_id`(`article_id` ASC) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  CONSTRAINT `article_comment_ibfk_1` FOREIGN KEY (`article_id`) REFERENCES `article` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `article_comment_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `article_comment_ibfk_3` FOREIGN KEY (`parent_id`) REFERENCES `article_comment` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '文章留言表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of article_comment
-- ----------------------------

-- ----------------------------
-- Table structure for assessment_record
-- ----------------------------
DROP TABLE IF EXISTS `assessment_record`;
CREATE TABLE `assessment_record`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `user_id` int NOT NULL COMMENT '作答学生ID',
  `scale_id` int NOT NULL COMMENT '量表ID',
  `start_time` datetime NOT NULL COMMENT '开始答题时间',
  `end_time` datetime NOT NULL COMMENT '提交时间',
  `duration_seconds` int NULL DEFAULT NULL COMMENT '实际答题耗时(秒),用于防作弊判断',
  `total_score` decimal(10, 2) NULL DEFAULT NULL COMMENT '总分',
  `dimension_scores` json NULL COMMENT '各维度分数',
  `risk_level` enum('LOW','MEDIUM','HIGH') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '风险等级:低/中/高',
  `is_suspicious` tinyint NULL DEFAULT 0 COMMENT '是否疑似作弊:0正常,1异常',
  `suspicious_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '异常原因',
  `answers_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '答案详情(JSON格式加密存储)',
  `counselor_id` int NULL DEFAULT NULL COMMENT '分配的咨询师ID',
  `is_viewed` tinyint NULL DEFAULT 0 COMMENT '咨询师是否已查看',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `counselor_id`(`counselor_id` ASC) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_scale_id`(`scale_id` ASC) USING BTREE,
  INDEX `idx_risk_level`(`risk_level` ASC) USING BTREE,
  INDEX `idx_created_at`(`created_at` ASC) USING BTREE,
  CONSTRAINT `assessment_record_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `assessment_record_ibfk_2` FOREIGN KEY (`scale_id`) REFERENCES `scale` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `assessment_record_ibfk_3` FOREIGN KEY (`counselor_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 127 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '测评记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of assessment_record
-- ----------------------------
INSERT INTO `assessment_record` VALUES (1, 2, 1, '2025-08-15 09:00:00', '2025-08-15 09:25:00', 1500, 45.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2025-08-15 09:25:00');
INSERT INTO `assessment_record` VALUES (2, 3, 1, '2025-08-18 10:00:00', '2025-08-18 10:28:00', 1680, 68.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-08-18 10:28:00');
INSERT INTO `assessment_record` VALUES (3, 4, 1, '2025-09-12 15:00:00', '2025-09-12 15:30:00', 1800, 72.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-09-12 15:30:00');
INSERT INTO `assessment_record` VALUES (4, 5, 1, '2025-09-14 11:00:00', '2025-09-14 11:26:00', 1560, 48.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2025-09-14 11:26:00');
INSERT INTO `assessment_record` VALUES (5, 6, 1, '2025-10-10 14:00:00', '2025-10-10 14:29:00', 1740, 65.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-10-10 14:29:00');
INSERT INTO `assessment_record` VALUES (6, 7, 1, '2025-10-20 10:30:00', '2025-10-20 10:55:00', 1500, 40.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2025-10-20 10:55:00');
INSERT INTO `assessment_record` VALUES (7, 2, 1, '2025-11-18 10:00:00', '2025-11-18 10:31:00', 1860, 75.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-11-18 10:31:00');
INSERT INTO `assessment_record` VALUES (8, 3, 1, '2025-12-05 14:00:00', '2025-12-05 14:28:00', 1680, 58.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2025-12-05 14:28:00');
INSERT INTO `assessment_record` VALUES (9, 4, 1, '2026-01-07 09:00:00', '2026-01-07 09:30:00', 1800, 78.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-01-07 09:30:00');
INSERT INTO `assessment_record` VALUES (10, 5, 1, '2026-02-08 14:00:00', '2026-02-08 14:32:00', 1920, 73.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-02-08 14:32:00');
INSERT INTO `assessment_record` VALUES (11, 6, 1, '2026-03-03 09:30:00', '2026-03-03 09:58:00', 1680, 62.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-03-03 09:58:00');
INSERT INTO `assessment_record` VALUES (12, 7, 1, '2026-03-10 10:00:00', '2026-03-10 10:29:00', 1740, 67.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-03-10 10:29:00');
INSERT INTO `assessment_record` VALUES (13, 2, 1, '2026-04-07 13:30:00', '2026-04-07 13:57:00', 1620, 56.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2026-04-07 13:57:00');
INSERT INTO `assessment_record` VALUES (14, 3, 1, '2026-04-12 10:00:00', '2026-04-12 10:30:00', 1800, 71.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-04-12 10:30:00');
INSERT INTO `assessment_record` VALUES (15, 4, 1, '2026-05-05 09:00:00', '2026-05-05 09:23:00', 1380, 42.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-05-05 09:23:00');
INSERT INTO `assessment_record` VALUES (16, 5, 1, '2026-05-09 14:30:00', '2026-05-09 14:55:00', 1500, 51.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2026-05-09 14:55:00');
INSERT INTO `assessment_record` VALUES (17, 6, 1, '2026-05-14 11:00:00', '2026-05-14 11:28:00', 1680, 64.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-05-14 11:28:00');
INSERT INTO `assessment_record` VALUES (18, 7, 1, '2026-06-03 09:30:00', '2026-06-03 09:52:00', 1320, 38.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-06-03 09:52:00');
INSERT INTO `assessment_record` VALUES (19, 2, 1, '2026-06-12 10:00:00', '2026-06-12 10:33:00', 1980, 76.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-06-12 10:33:00');
INSERT INTO `assessment_record` VALUES (20, 3, 1, '2026-07-01 09:00:00', '2026-07-01 09:22:00', 1320, 41.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-07-01 09:22:00');
INSERT INTO `assessment_record` VALUES (24, 2, 1, '2025-08-15 09:00:00', '2025-08-15 09:25:00', 1500, 45.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2025-08-15 09:25:00');
INSERT INTO `assessment_record` VALUES (25, 3, 1, '2025-08-18 10:00:00', '2025-08-18 10:28:00', 1680, 68.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-08-18 10:28:00');
INSERT INTO `assessment_record` VALUES (26, 4, 1, '2025-09-12 15:00:00', '2025-09-12 15:30:00', 1800, 72.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-09-12 15:30:00');
INSERT INTO `assessment_record` VALUES (27, 5, 1, '2025-09-14 11:00:00', '2025-09-14 11:26:00', 1560, 48.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2025-09-14 11:26:00');
INSERT INTO `assessment_record` VALUES (28, 6, 1, '2025-10-10 14:00:00', '2025-10-10 14:29:00', 1740, 65.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-10-10 14:29:00');
INSERT INTO `assessment_record` VALUES (29, 7, 1, '2025-10-20 10:30:00', '2025-10-20 10:55:00', 1500, 40.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2025-10-20 10:55:00');
INSERT INTO `assessment_record` VALUES (30, 2, 1, '2025-11-18 10:00:00', '2025-11-18 10:31:00', 1860, 75.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-11-18 10:31:00');
INSERT INTO `assessment_record` VALUES (31, 3, 1, '2025-12-05 14:00:00', '2025-12-05 14:28:00', 1680, 58.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2025-12-05 14:28:00');
INSERT INTO `assessment_record` VALUES (32, 4, 1, '2026-01-07 09:00:00', '2026-01-07 09:30:00', 1800, 78.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-01-07 09:30:00');
INSERT INTO `assessment_record` VALUES (33, 5, 1, '2026-02-08 14:00:00', '2026-02-08 14:32:00', 1920, 73.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-02-08 14:32:00');
INSERT INTO `assessment_record` VALUES (34, 6, 1, '2026-03-03 09:30:00', '2026-03-03 09:58:00', 1680, 62.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-03-03 09:58:00');
INSERT INTO `assessment_record` VALUES (35, 7, 1, '2026-03-10 10:00:00', '2026-03-10 10:29:00', 1740, 67.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-03-10 10:29:00');
INSERT INTO `assessment_record` VALUES (36, 2, 1, '2026-04-07 13:30:00', '2026-04-07 13:57:00', 1620, 56.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2026-04-07 13:57:00');
INSERT INTO `assessment_record` VALUES (37, 3, 1, '2026-04-12 10:00:00', '2026-04-12 10:30:00', 1800, 71.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-04-12 10:30:00');
INSERT INTO `assessment_record` VALUES (38, 4, 1, '2026-05-05 09:00:00', '2026-05-05 09:23:00', 1380, 42.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-05-05 09:23:00');
INSERT INTO `assessment_record` VALUES (39, 5, 1, '2026-05-09 14:30:00', '2026-05-09 14:55:00', 1500, 51.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2026-05-09 14:55:00');
INSERT INTO `assessment_record` VALUES (40, 6, 1, '2026-05-14 11:00:00', '2026-05-14 11:28:00', 1680, 64.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-05-14 11:28:00');
INSERT INTO `assessment_record` VALUES (41, 7, 1, '2026-06-03 09:30:00', '2026-06-03 09:52:00', 1320, 38.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-06-03 09:52:00');
INSERT INTO `assessment_record` VALUES (42, 2, 1, '2026-06-12 10:00:00', '2026-06-12 10:33:00', 1980, 76.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-06-12 10:33:00');
INSERT INTO `assessment_record` VALUES (43, 3, 1, '2026-07-01 09:00:00', '2026-07-01 09:22:00', 1320, 41.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-07-01 09:22:00');
INSERT INTO `assessment_record` VALUES (71, 2, 1, '2025-08-15 09:00:00', '2025-08-15 09:25:00', 1500, 45.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2025-08-15 09:25:00');
INSERT INTO `assessment_record` VALUES (72, 3, 1, '2025-08-18 10:00:00', '2025-08-18 10:28:00', 1680, 68.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-08-18 10:28:00');
INSERT INTO `assessment_record` VALUES (73, 4, 1, '2025-09-12 15:00:00', '2025-09-12 15:30:00', 1800, 72.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-09-12 15:30:00');
INSERT INTO `assessment_record` VALUES (74, 5, 1, '2025-09-14 11:00:00', '2025-09-14 11:26:00', 1560, 48.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2025-09-14 11:26:00');
INSERT INTO `assessment_record` VALUES (75, 6, 1, '2025-10-10 14:00:00', '2025-10-10 14:29:00', 1740, 65.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-10-10 14:29:00');
INSERT INTO `assessment_record` VALUES (76, 7, 1, '2025-10-20 10:30:00', '2025-10-20 10:55:00', 1500, 40.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2025-10-20 10:55:00');
INSERT INTO `assessment_record` VALUES (77, 19, 1, '2025-10-25 16:00:00', '2025-10-25 16:22:00', 1320, 38.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2025-10-25 16:22:00');
INSERT INTO `assessment_record` VALUES (78, 2, 1, '2025-11-08 13:30:00', '2025-11-08 13:58:00', 1680, 70.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-11-08 13:58:00');
INSERT INTO `assessment_record` VALUES (79, 3, 1, '2025-11-18 10:00:00', '2025-11-18 10:31:00', 1860, 75.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2025-11-18 10:31:00');
INSERT INTO `assessment_record` VALUES (80, 4, 1, '2025-12-05 14:00:00', '2025-12-05 14:28:00', 1680, 58.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2025-12-05 14:28:00');
INSERT INTO `assessment_record` VALUES (81, 1, 1, '2025-12-10 11:00:00', '2025-12-10 11:25:00', 1500, 46.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2025-12-10 11:25:00');
INSERT INTO `assessment_record` VALUES (82, 5, 1, '2026-01-07 09:00:00', '2026-01-07 09:30:00', 1800, 78.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-01-07 09:30:00');
INSERT INTO `assessment_record` VALUES (83, 19, 1, '2026-01-15 15:00:00', '2026-01-15 15:22:00', 1320, 41.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-01-15 15:22:00');
INSERT INTO `assessment_record` VALUES (84, 6, 1, '2026-02-08 14:00:00', '2026-02-08 14:32:00', 1920, 73.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-02-08 14:32:00');
INSERT INTO `assessment_record` VALUES (85, 7, 1, '2026-02-14 10:00:00', '2026-02-14 10:21:00', 1260, 39.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-02-14 10:21:00');
INSERT INTO `assessment_record` VALUES (86, 2, 1, '2026-03-03 09:30:00', '2026-03-03 09:58:00', 1680, 62.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-03-03 09:58:00');
INSERT INTO `assessment_record` VALUES (87, 1, 1, '2026-03-12 14:30:00', '2026-03-12 14:51:00', 1260, 37.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-03-12 14:51:00');
INSERT INTO `assessment_record` VALUES (88, 3, 1, '2026-04-02 09:00:00', '2026-04-02 09:25:00', 1500, 49.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2026-04-02 09:25:00');
INSERT INTO `assessment_record` VALUES (89, 5, 1, '2026-04-10 13:30:00', '2026-04-10 13:57:00', 1620, 56.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2026-04-10 13:57:00');
INSERT INTO `assessment_record` VALUES (90, 4, 1, '2026-05-05 09:00:00', '2026-05-05 09:23:00', 1380, 42.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-05-05 09:23:00');
INSERT INTO `assessment_record` VALUES (91, 7, 1, '2026-05-14 11:00:00', '2026-05-14 11:28:00', 1680, 64.00, NULL, 'HIGH', 0, NULL, '{}', NULL, 0, '2026-05-14 11:28:00');
INSERT INTO `assessment_record` VALUES (92, 6, 1, '2026-06-03 09:30:00', '2026-06-03 09:52:00', 1320, 38.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-06-03 09:52:00');
INSERT INTO `assessment_record` VALUES (93, 19, 1, '2026-06-10 15:00:00', '2026-06-10 15:26:00', 1560, 54.00, NULL, 'MEDIUM', 0, NULL, '{}', NULL, 0, '2026-06-10 15:26:00');
INSERT INTO `assessment_record` VALUES (94, 1, 1, '2026-07-12 09:00:00', '2026-07-12 09:22:00', 1320, 41.00, NULL, 'LOW', 0, NULL, '{}', NULL, 0, '2026-07-12 09:22:00');
INSERT INTO `assessment_record` VALUES (95, 17, 1, '2026-07-14 00:44:56', '2026-07-14 00:45:04', 7, 10.00, '{}', 'LOW', 1, '答题时长过短(7秒)，疑似乱填', 'Z2uAUPbrpNdY7LH81JH8d6YiXotjbYC6wHXMz7vZEtA/WuENvQ5DsT43yIz4/ejuaImFC8/O4yAaKm/WkG0XdATmfXO+w22om5cmHCVvDkWUUNvkz2zwEpKxWmVrmPZvFxTNuImsJjpkBEBtHU15gYJlfweppNW6J3mp8PArnYcxLSpr38Bg+ifQa68ouErjF6kKp/34r7XbGqw2YZnQLg==', NULL, 0, '2026-07-14 00:45:03');
INSERT INTO `assessment_record` VALUES (96, 17, 1, '2026-07-14 00:52:07', '2026-07-14 00:52:23', 15, 50.00, '{}', 'LOW', 1, '答题时长过短(15秒)，疑似乱填', 'DPAzENpqLiEHDDEN7eYo8zZF/3frYqX6Qd4RTk9N31taD2zJALngo8aBuqZtpguOapA5WIU7hJJ2GIQiyzmbHM/zoGQxd5VquHyIAPbCL0giYhWazvTLXJFP1P34Bl5GPf90m7xygT9mm4ftfdH5uQTGzQfqAb0zldCRxUcDcY4F/69SPHXS9zdfY0YWhDUKInMmfpNh5LY5zTkWxfXgLA==', NULL, 0, '2026-07-14 00:52:22');
INSERT INTO `assessment_record` VALUES (97, 17, 1, '2026-07-14 01:51:36', '2026-07-14 01:51:50', 13, 100.00, '{}', 'LOW', 1, '答题时长过短(13秒)，疑似乱填', 'A5WwvfzOp+syr2IQXpt/lbRboPT8KIN7HZENZuP7UbDNDnra+omSxEKodEBrQGLG+fiWUde4Cqk3xbDHWDEQ+xdnVii/g/pwMDLC0EyhOYNOiOo9dTY3FrXt8M+pjXEpkfsZ295LHX1EgF+xvHFIS2xqHyUfELKLtBDEu4JFJOQX9fbvddvROGujzpffFf+DFuOGZqc4cHv6jai/h4VSvw==', NULL, 0, '2026-07-14 01:51:49');
INSERT INTO `assessment_record` VALUES (98, 17, 2, '2026-07-14 01:51:54', '2026-07-14 01:52:03', 9, 100.00, '{}', 'HIGH', 1, '答题时长过短(9秒)，疑似乱填', 'q56R902Tf8fUzRlIqF2ODBeg74rjg0sqL+B3LpcXHu2rfBCrs55qZtTaE4oBzxwpvAutNwtrpv1UtSgjoNSbBIlN/XodWj4KNWRh/wpFnLTJVX1ygmkyhnQ2gNhhq72uz5GN5YUy1TpStPV+ZCr7wLaUzbWPhwlv36QwBMgfVMVeIbVG1h/Qz23kKdsEgfbxHr5UbrPtEwtm0jnIMr+QHg==', NULL, 0, '2026-07-14 01:52:03');
INSERT INTO `assessment_record` VALUES (99, 12, 1, '2025-07-10 09:00:00', '2025-07-10 09:25:00', 1500, 245.00, '{\"偏执\": 2.8, \"恐怖\": 2.3, \"抑郁\": 3.8, \"敌对\": 2.5, \"焦虑\": 3.1, \"躯体化\": 3.2, \"强迫症状\": 3.5, \"精神病性\": 3.0, \"人际关系敏感\": 3.0}', 'HIGH', 0, NULL, '[{\"q\":1,\"a\":4},{\"q\":2,\"a\":3},{\"q\":3,\"a\":4}]', NULL, 0, '2025-07-10 09:25:00');
INSERT INTO `assessment_record` VALUES (100, 12, 2, '2025-07-12 14:00:00', '2025-07-12 14:08:00', 480, 58.00, '{\"抑郁\": 58}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":3},{\"q\":2,\"a\":2},{\"q\":3,\"a\":3}]', NULL, 0, '2025-07-12 14:08:00');
INSERT INTO `assessment_record` VALUES (101, 12, 3, '2025-06-20 10:00:00', '2025-06-20 10:07:00', 420, 42.00, '{\"焦虑\": 42}', 'LOW', 0, NULL, '[{\"q\":1,\"a\":2},{\"q\":2,\"a\":1},{\"q\":3,\"a\":2}]', NULL, 0, '2025-06-20 10:07:00');
INSERT INTO `assessment_record` VALUES (102, 13, 1, '2025-07-11 10:00:00', '2025-07-11 10:22:00', 1320, 180.00, '{\"偏执\": 2.3, \"恐怖\": 2.0, \"抑郁\": 2.9, \"敌对\": 2.1, \"焦虑\": 2.7, \"躯体化\": 2.5, \"强迫症状\": 2.8, \"精神病性\": 2.1, \"人际关系敏感\": 3.2}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":3},{\"q\":2,\"a\":2},{\"q\":3,\"a\":3}]', NULL, 0, '2025-07-11 10:22:00');
INSERT INTO `assessment_record` VALUES (105, 12, 1, '2025-07-10 09:00:00', '2025-07-10 09:25:00', 1500, 245.00, '{\"抑郁\": 3.8, \"躯体化\": 3.2, \"强迫症状\": 3.5, \"人际关系敏感\": 3.0}', 'HIGH', 0, NULL, '[{\"q\":1,\"a\":4}]', NULL, 0, '2025-07-10 09:25:00');
INSERT INTO `assessment_record` VALUES (106, 12, 2, '2025-07-12 14:00:00', '2025-07-12 14:08:00', 480, 58.00, '{\"抑郁\": 58}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":3}]', NULL, 0, '2025-07-12 14:08:00');
INSERT INTO `assessment_record` VALUES (107, 12, 3, '2025-06-20 10:00:00', '2025-06-20 10:07:00', 420, 42.00, '{\"焦虑\": 42}', 'LOW', 0, NULL, '[{\"q\":1,\"a\":2}]', NULL, 0, '2025-06-20 10:07:00');
INSERT INTO `assessment_record` VALUES (108, 13, 1, '2025-07-11 10:00:00', '2025-07-11 10:22:00', 1320, 180.00, '{\"抑郁\": 2.9, \"躯体化\": 2.5, \"强迫症状\": 2.8, \"人际关系敏感\": 3.2}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":3}]', NULL, 0, '2025-07-11 10:22:00');
INSERT INTO `assessment_record` VALUES (109, 13, 4, '2025-07-13 15:00:00', '2025-07-13 15:04:00', 240, 15.00, '{\"抑郁\": 15}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":2}]', NULL, 0, '2025-07-13 15:04:00');
INSERT INTO `assessment_record` VALUES (110, 13, 5, '2025-06-15 09:00:00', '2025-06-15 09:03:00', 180, 8.00, '{\"焦虑\": 8}', 'LOW', 0, NULL, '[{\"q\":1,\"a\":1}]', NULL, 0, '2025-06-15 09:03:00');
INSERT INTO `assessment_record` VALUES (111, 14, 1, '2025-07-14 08:00:00', '2025-07-14 08:28:00', 1680, 280.00, '{\"抑郁\": 4.2, \"躯体化\": 3.8, \"强迫症状\": 3.9, \"人际关系敏感\": 4.0}', 'HIGH', 0, NULL, '[{\"q\":1,\"a\":5}]', NULL, 0, '2025-07-14 08:28:00');
INSERT INTO `assessment_record` VALUES (112, 14, 2, '2025-07-14 16:00:00', '2025-07-14 16:10:00', 600, 68.00, '{\"抑郁\": 68}', 'HIGH', 0, NULL, '[{\"q\":1,\"a\":4}]', NULL, 0, '2025-07-14 16:10:00');
INSERT INTO `assessment_record` VALUES (113, 15, 3, '2025-07-13 11:00:00', '2025-07-13 11:08:00', 480, 52.00, '{\"焦虑\": 52}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":3}]', NULL, 0, '2025-07-13 11:08:00');
INSERT INTO `assessment_record` VALUES (114, 16, 4, '2025-07-12 09:00:00', '2025-07-12 09:05:00', 300, 22.00, '{\"抑郁\": 22}', 'HIGH', 0, NULL, '[{\"q\":1,\"a\":3}]', NULL, 0, '2025-07-12 09:05:00');
INSERT INTO `assessment_record` VALUES (115, 16, 5, '2025-07-12 09:10:00', '2025-07-12 09:14:00', 240, 16.00, '{\"焦虑\": 16}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":3}]', NULL, 0, '2025-07-12 09:14:00');
INSERT INTO `assessment_record` VALUES (116, 17, 2, '2025-07-08 10:00:00', '2025-07-08 10:06:00', 360, 38.00, '{\"抑郁\": 38}', 'LOW', 0, NULL, '[{\"q\":1,\"a\":1}]', NULL, 0, '2025-07-08 10:06:00');
INSERT INTO `assessment_record` VALUES (117, 17, 3, '2025-07-08 10:15:00', '2025-07-08 10:21:00', 360, 35.00, '{\"焦虑\": 35}', 'LOW', 0, NULL, '[{\"q\":1,\"a\":1}]', NULL, 0, '2025-07-08 10:21:00');
INSERT INTO `assessment_record` VALUES (118, 18, 1, '2025-07-09 13:00:00', '2025-07-09 13:20:00', 1200, 175.00, '{\"抑郁\": 2.8, \"躯体化\": 2.4, \"强迫症状\": 2.7, \"人际关系敏感\": 3.0}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":3}]', NULL, 0, '2025-07-09 13:20:00');
INSERT INTO `assessment_record` VALUES (119, 19, 2, '2025-07-14 10:00:00', '2025-07-14 10:08:00', 480, 72.00, '{\"抑郁\": 72}', 'HIGH', 0, NULL, '[{\"q\":1,\"a\":4}]', NULL, 0, '2025-07-14 10:08:00');
INSERT INTO `assessment_record` VALUES (120, 19, 5, '2025-07-14 10:15:00', '2025-07-14 10:18:00', 180, 19.00, '{\"焦虑\": 19}', 'HIGH', 0, NULL, '[{\"q\":1,\"a\":3}]', NULL, 0, '2025-07-14 10:18:00');
INSERT INTO `assessment_record` VALUES (121, 78, 1, '2025-07-08 14:00:00', '2025-07-08 14:18:00', 1080, 120.00, '{\"抑郁\": 1.9, \"躯体化\": 1.5, \"强迫症状\": 1.8, \"人际关系敏感\": 2.0}', 'LOW', 0, NULL, '[{\"q\":1,\"a\":2}]', NULL, 0, '2025-07-08 14:18:00');
INSERT INTO `assessment_record` VALUES (122, 79, 3, '2025-07-13 08:00:00', '2025-07-13 08:07:00', 420, 65.00, '{\"焦虑\": 65}', 'HIGH', 0, NULL, '[{\"q\":1,\"a\":4}]', NULL, 0, '2025-07-13 08:07:00');
INSERT INTO `assessment_record` VALUES (123, 79, 4, '2025-07-13 08:15:00', '2025-07-13 08:19:00', 240, 14.00, '{\"抑郁\": 14}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":2}]', NULL, 0, '2025-07-13 08:19:00');
INSERT INTO `assessment_record` VALUES (124, 12, 1, '2025-06-05 10:00:00', '2025-06-05 10:20:00', 1200, 155.00, '{\"躯体化\": 2.0}', 'LOW', 0, NULL, '[{\"q\":1,\"a\":2}]', NULL, 0, '2025-06-05 10:20:00');
INSERT INTO `assessment_record` VALUES (125, 13, 2, '2025-06-08 14:00:00', '2025-06-08 14:07:00', 420, 45.00, '{\"抑郁\": 45}', 'MEDIUM', 0, NULL, '[{\"q\":1,\"a\":2}]', NULL, 0, '2025-06-08 14:07:00');
INSERT INTO `assessment_record` VALUES (126, 15, 1, '2025-05-10 08:00:00', '2025-05-10 08:20:00', 1200, 140.00, '{\"躯体化\": 1.8}', 'LOW', 0, NULL, '[{\"q\":1,\"a\":2}]', NULL, 0, '2025-05-10 08:20:00');

-- ----------------------------
-- Table structure for chat_message
-- ----------------------------
DROP TABLE IF EXISTS `chat_message`;
CREATE TABLE `chat_message`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `session_id` bigint NOT NULL COMMENT '会话ID',
  `sender_type` enum('USER','AI') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '发送者:用户/AI',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息内容(可加密)',
  `emotion_tag` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '情绪标签',
  `is_encrypted` tinyint NULL DEFAULT 0 COMMENT '是否加密',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_session_id`(`session_id` ASC) USING BTREE,
  CONSTRAINT `chat_message_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `chat_session` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 46 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '树洞消息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of chat_message
-- ----------------------------
INSERT INTO `chat_message` VALUES (1, 1, 'USER', '最近期末考试压力好大，每天晚上都睡不着，脑子里全是考试的事情', '焦虑', 0, '2026-07-12 16:20:10');
INSERT INTO `chat_message` VALUES (2, 1, 'AI', '失眠确实会让人更加焦虑。试试睡前1小时放下手机、温水泡脚15分钟、听白噪音。如果持续失眠，建议预约心理咨询。', NULL, 0, '2026-07-12 16:20:10');
INSERT INTO `chat_message` VALUES (3, 1, 'USER', '谢谢你的建议，我今晚试试。但还是好害怕考不好，爸妈期望很高', NULL, 0, '2026-07-12 16:20:10');
INSERT INTO `chat_message` VALUES (4, 1, 'AI', '你的价值不只由考试成绩决定。你很努力了，这份努力本身就值得肯定。不妨和父母坦诚沟通你的感受？', NULL, 0, '2026-07-12 16:20:10');
INSERT INTO `chat_message` VALUES (5, 2, 'USER', '我觉得自己做什么都做不好，没有人在乎我...', '抑郁', 0, '2026-07-14 16:20:10');
INSERT INTO `chat_message` VALUES (6, 2, 'AI', '听到你这样说让我很关心你。每个人都会有感到无力的时刻。你能具体说说为什么有这样的感受吗？', NULL, 0, '2026-07-14 16:20:10');
INSERT INTO `chat_message` VALUES (7, 2, 'USER', '成绩一直下滑，和朋友闹掰了，父母天天吵架。觉得活着好累...', '绝望', 0, '2026-07-14 16:20:10');
INSERT INTO `chat_message` VALUES (8, 2, 'AI', '我听到了你的痛苦。请知道你的生命是珍贵的。建议立即联系心理咨询中心热线，或拨打24小时心理援助热线400-161-9995。有人愿意帮助你。', NULL, 0, '2026-07-14 16:20:10');
INSERT INTO `chat_message` VALUES (9, 2, 'USER', '谢谢你...以前从来没跟人说过这些', NULL, 0, '2026-07-14 16:20:10');
INSERT INTO `chat_message` VALUES (10, 2, 'AI', '迈出这一步需要很大的勇气。请务必联系心理咨询中心，他们能提供面对面帮助。你值得被关心和帮助。', NULL, 0, '2026-07-14 16:20:10');
INSERT INTO `chat_message` VALUES (11, 3, 'USER', '我室友真的太自私了，每天外放音乐到很晚，说了好几次都不听', '愤怒', 0, '2026-07-13 16:20:10');
INSERT INTO `chat_message` VALUES (12, 3, 'AI', '宿舍矛盾确实让人身心俱疲。换个方式沟通：用\"我感觉...\"而非\"你总是...\"表达。无效可寻求辅导员帮助。', NULL, 0, '2026-07-13 16:20:10');
INSERT INTO `chat_message` VALUES (13, 3, 'USER', '我试过好好说，她答应后第二天又照旧。都想换宿舍了', NULL, 0, '2026-07-13 16:20:10');
INSERT INTO `chat_message` VALUES (14, 3, 'AI', '换宿舍是个选项。建议先和辅导员谈谈。同时可以在需要专注时去图书馆或自习室。你的感受是合理的。', NULL, 0, '2026-07-13 16:20:10');
INSERT INTO `chat_message` VALUES (15, 4, 'USER', '你好，我期末考试成绩不理想', NULL, 0, '2026-07-16 03:00:33');
INSERT INTO `chat_message` VALUES (16, 4, 'USER', '你好，我的学习压力大', NULL, 0, '2026-07-16 03:01:17');
INSERT INTO `chat_message` VALUES (17, 5, 'USER', '我心情不好', NULL, 0, '2026-07-16 03:05:31');
INSERT INTO `chat_message` VALUES (18, 5, 'USER', '你好', NULL, 0, '2026-07-16 03:05:39');
INSERT INTO `chat_message` VALUES (19, 6, 'USER', '你好，我心情不好', NULL, 0, '2026-07-16 03:12:50');
INSERT INTO `chat_message` VALUES (20, 6, 'AI', '', '一般倾诉', 0, '2026-07-16 03:13:22');
INSERT INTO `chat_message` VALUES (21, 7, 'USER', '你好，我心情不好', NULL, 0, '2026-07-16 03:17:11');
INSERT INTO `chat_message` VALUES (22, 7, 'AI', '', '一般倾诉', 0, '2026-07-16 03:17:53');
INSERT INTO `chat_message` VALUES (23, 8, 'USER', '你好，我心情不好', NULL, 0, '2026-07-16 03:18:47');
INSERT INTO `chat_message` VALUES (24, 8, 'USER', '最近总是睡不好，晚上失眠，白天没精神', NULL, 0, '2026-07-16 03:19:11');
INSERT INTO `chat_message` VALUES (25, 8, 'AI', '', '一般倾诉', 0, '2026-07-16 03:19:23');
INSERT INTO `chat_message` VALUES (26, 8, 'AI', '', '一般倾诉', 0, '2026-07-16 03:19:52');
INSERT INTO `chat_message` VALUES (27, 9, 'USER', '你好，我心情不好', NULL, 0, '2026-07-16 03:20:56');
INSERT INTO `chat_message` VALUES (28, 9, 'AI', '', '一般倾诉', 0, '2026-07-16 03:21:35');
INSERT INTO `chat_message` VALUES (29, 11, 'USER', '你好，我心情不好', NULL, 0, '2026-07-16 03:23:58');
INSERT INTO `chat_message` VALUES (30, 12, 'USER', '你好，我心情不好', NULL, 0, '2026-07-16 03:27:26');
INSERT INTO `chat_message` VALUES (31, 13, 'USER', '你好', NULL, 0, '2026-07-16 03:27:43');
INSERT INTO `chat_message` VALUES (32, 13, 'AI', '', '一般倾诉', 0, '2026-07-16 03:28:08');
INSERT INTO `chat_message` VALUES (33, 12, 'AI', '', '一般倾诉', 0, '2026-07-16 03:28:09');
INSERT INTO `chat_message` VALUES (34, 16, 'USER', '你好', NULL, 0, '2026-07-16 03:31:24');
INSERT INTO `chat_message` VALUES (35, 16, 'AI', '你好呀😊 很高兴你来到这个安全的小树洞。\n这里没有评判、没有要求，不管你是最近攒了满肚子的情绪想倒一倒，遇到了拧巴的事想捋捋思路，还是只是想随便说点什么，我都会安安静静陪着你、认真听你讲。\n\n现在刚好是期末季，我知道很多同学最近都在连轴转复习，难免会有点疲惫，或是遇到情绪卡壳的时候。如果你愿意的话，可以慢慢说说最近的状态呀，什么内容都可以：\n- 是复习备考的压力有点扛不住？\n- 和朋友、家人相处时碰到了让人不舒服的事？\n- 还是有别的藏在心里没处说的小困扰？\n\n你完全不用有顾虑，我会好好接住你的每一份情绪🤗', '一般倾诉', 0, '2026-07-16 03:32:21');
INSERT INTO `chat_message` VALUES (36, 17, 'USER', '你好', NULL, 0, '2026-07-16 03:32:46');
INSERT INTO `chat_message` VALUES (37, 17, 'AI', '你好呀🤗 很高兴你愿意停留在这个安全的小空间里。\n我是始终抱着接纳态度听你说话的树洞伙伴，不管你此刻是被学业压力绊住脚步、在人际关系里觉得疲惫、和家人相处时有说不出的委屈，还是只是莫名提不起劲、心里堵得慌，都可以毫无顾虑地说出来。\n你不用强迫自己立刻梳理清楚所有感受，想到什么聊什么就好。\n今天你来到这里，是想聊聊最近让你挂心的事情吗？', '一般倾诉', 0, '2026-07-16 03:33:09');
INSERT INTO `chat_message` VALUES (38, 17, 'USER', '期末没考好', NULL, 0, '2026-07-16 03:34:18');
INSERT INTO `chat_message` VALUES (39, 17, 'AI', '我听到你现在因为期末没考好，心里满是失落、挫败，说不定还藏着点自责对不对😔\n认认真真准备了一学期，最后没拿到预期的结果，这种堵得慌的难受真的太正常了。好多同学出分那段时间都会闷好几天，做什么都提不起劲，你有这样的感受一点都不奇怪。\n\n我特别懂这种心情——可能你考前也熬了不少夜、花了不少精力啃知识点，看到分数的那一刻，之前攒的期待一下子落了空，还会忍不住反复回想“要是当时再仔细一点、多复习一点就好了”。\n\n其实我们可以先不急着逼自己立刻“振作”或者否定自己呀：\n🤍 先给情绪一点出口：允许自己为这个结果难过一会儿，吃点喜欢的东西、在校园里散散步，不用硬撑着“无所谓”\n🤍 等情绪松快些了，再慢慢捋捋问题出在哪——是复习节奏没踩对，还是有些知识点没摸透，一次的分数从来定义不了你的能力\n\n对了，这份堵在心里的难受，你有没有和身边信任的人聊过呀？说出来会轻很多的🤗', '一般倾诉', 0, '2026-07-16 03:34:54');
INSERT INTO `chat_message` VALUES (40, 17, 'USER', '我喜欢的人不喜欢我', NULL, 0, '2026-07-16 03:35:56');
INSERT INTO `chat_message` VALUES (41, 17, 'AI', '我听到你现在心里涨着满满的失落和酸涩对不对😔\n揣着软乎乎的真心喜欢一个人，却没得到期待的回应，这种悬在半空落不下来的难受，真的太戳人了。这段时间你既要扛着期末备考的压力，又遇上感情上的小挫折，两件不顺心的事凑到一起，肯定偷偷攒了好多委屈吧。很多人遇到这种情况都会忍不住自我怀疑，是不是我哪里不够好才不被喜欢，有这样的念头真的太正常了。\n\n但我想告诉你呀：**你认真捧着真心的样子特别珍贵，对方没有选择你，从来不是你不够好，只是你们的心动频率刚好没对上而已**。\n不用逼自己马上“走出来”，你可以允许自己为这份没结果的喜欢难过一小段时间，也可以多做点让自己舒服的小事：\n🍬 去吃想念了很久的美食\n🍬 和室友绕着操场散散步吹吹风\n慢慢把放在对方身上的注意力，拉回自己身上就好。\n\n现在一想到这件事，你最难受的是什么呀？可以慢慢说给我听🤗', '一般倾诉', 0, '2026-07-16 03:36:25');
INSERT INTO `chat_message` VALUES (42, 18, 'USER', '你好', NULL, 0, '2026-07-16 03:41:43');
INSERT INTO `chat_message` VALUES (43, 18, 'AI', '你好呀🤗 很开心你愿意敲开这扇树洞的门。\n这里是完全安全、不带评判的倾诉空间，不管是压在心里好久没处说的烦心事、最近让你觉得有点累的压力，还是只是莫名提不起劲的低落情绪，都可以放心讲出来。\n我会好好接住你的每一份感受，不会随便说教，会安安静静听你说，也会陪你一起慢慢梳理。\n不知道你今天是带着什么样的心情过来的呀？有没有什么想聊的小事都可以说哦🌟', '一般倾诉', 0, '2026-07-16 03:42:12');
INSERT INTO `chat_message` VALUES (44, 19, 'USER', '你好', NULL, 0, '2026-07-16 10:13:40');
INSERT INTO `chat_message` VALUES (45, 19, 'AI', '😊你好呀，很开心你愿意来到这个可以放心说心事的小空间✨\n我知道有时候主动敲下第一句话、想要倾诉的时刻，本身就带着一点不容易的勇气。不管你此刻是揣着没处说的低落、攒了好久的烦心事，还是只是想随便聊聊日常里细碎的感受，这里都完全接纳你的所有情绪，我会认真听你讲，不会随意评判你。\n\n如果你暂时还没想好从哪里说起也没关系，我们可以慢慢聊：最近这几天，有没有什么小小的瞬间，让你觉得哪怕只有一小会儿，是轻松舒服的呀？', '一般倾诉', 0, '2026-07-16 10:14:05');

-- ----------------------------
-- Table structure for chat_rate_limit
-- ----------------------------
DROP TABLE IF EXISTS `chat_rate_limit`;
CREATE TABLE `chat_rate_limit`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '用户ID',
  `date` date NOT NULL COMMENT '日期',
  `request_count` int NOT NULL DEFAULT 0 COMMENT '当日请求次数',
  `last_request_time` datetime NULL DEFAULT NULL COMMENT '最后一次请求时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_date`(`user_id` ASC, `date` ASC) USING BTREE,
  CONSTRAINT `chat_rate_limit_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'AI对话限流表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of chat_rate_limit
-- ----------------------------
INSERT INTO `chat_rate_limit` VALUES (1, 17, '2026-07-16', 10, '2026-07-16 10:13:40', '2026-07-16 03:00:33');
INSERT INTO `chat_rate_limit` VALUES (2, 18, '2026-07-16', 8, '2026-07-16 03:35:56', '2026-07-16 03:20:56');

-- ----------------------------
-- Table structure for chat_session
-- ----------------------------
DROP TABLE IF EXISTS `chat_session`;
CREATE TABLE `chat_session`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '学生用户ID',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '会话标题(自动生成)',
  `emotion_tags` json NULL COMMENT 'AI识别的情绪标签',
  `is_high_risk` tinyint NULL DEFAULT 0 COMMENT '是否包含高风险内容',
  `alert_triggered` tinyint NULL DEFAULT 0 COMMENT '是否已触发预警',
  `message_count` int NULL DEFAULT 0 COMMENT '消息总数',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_is_high_risk`(`is_high_risk` ASC) USING BTREE,
  CONSTRAINT `chat_session_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '树洞会话表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of chat_session
-- ----------------------------
INSERT INTO `chat_session` VALUES (1, 12, '最近压力好大...', '[\"焦虑\", \"压力\", \"失眠\"]', 0, 0, 4, '2026-07-12 16:20:10', '2026-07-15 16:20:10');
INSERT INTO `chat_session` VALUES (2, 14, '感觉自己一无是处', '[\"抑郁\", \"绝望\", \"自我否定\"]', 1, 1, 6, '2026-07-14 16:20:10', '2026-07-15 16:20:10');
INSERT INTO `chat_session` VALUES (3, 17, '和室友的矛盾', '[\"愤怒\", \"委屈\", \"孤独\"]', 0, 0, 4, '2026-07-13 16:20:10', '2026-07-15 16:20:10');
INSERT INTO `chat_session` VALUES (4, 17, '新对话', NULL, 0, 0, 0, '2026-07-16 03:00:14', '2026-07-16 03:00:14');
INSERT INTO `chat_session` VALUES (5, 17, '新对话', NULL, 0, 0, 0, '2026-07-16 03:05:25', '2026-07-16 03:05:25');
INSERT INTO `chat_session` VALUES (6, 17, '你好，我心情不好', '[\"一般倾诉\"]', 0, 0, 1, '2026-07-16 03:12:42', '2026-07-16 03:13:22');
INSERT INTO `chat_session` VALUES (7, 17, '你好，我心情不好', '[\"一般倾诉\"]', 0, 0, 1, '2026-07-16 03:17:02', '2026-07-16 03:17:53');
INSERT INTO `chat_session` VALUES (8, 17, '新对话', '[\"一般倾诉\"]', 0, 0, 2, '2026-07-16 03:17:28', '2026-07-16 03:19:52');
INSERT INTO `chat_session` VALUES (9, 18, '你好，我心情不好', '[\"一般倾诉\"]', 0, 0, 1, '2026-07-16 03:20:50', '2026-07-16 03:21:35');
INSERT INTO `chat_session` VALUES (10, 18, '新对话', NULL, 0, 0, 0, '2026-07-16 03:21:19', '2026-07-16 03:21:19');
INSERT INTO `chat_session` VALUES (11, 18, '新对话', NULL, 0, 0, 0, '2026-07-16 03:23:50', '2026-07-16 03:23:50');
INSERT INTO `chat_session` VALUES (12, 18, '你好，我心情不好', '[\"一般倾诉\"]', 0, 0, 1, '2026-07-16 03:27:18', '2026-07-16 03:28:09');
INSERT INTO `chat_session` VALUES (13, 18, '新对话', '[\"一般倾诉\"]', 0, 0, 1, '2026-07-16 03:27:38', '2026-07-16 03:28:08');
INSERT INTO `chat_session` VALUES (14, 18, '新对话', NULL, 0, 0, 0, '2026-07-16 03:27:52', '2026-07-16 03:27:52');
INSERT INTO `chat_session` VALUES (15, 18, '新对话', NULL, 0, 0, 0, '2026-07-16 03:27:58', '2026-07-16 03:27:58');
INSERT INTO `chat_session` VALUES (16, 18, '新对话', '[\"一般倾诉\"]', 0, 0, 1, '2026-07-16 03:31:20', '2026-07-16 03:32:21');
INSERT INTO `chat_session` VALUES (17, 18, '新对话', '[\"一般倾诉\"]', 0, 0, 3, '2026-07-16 03:31:46', '2026-07-16 03:36:25');
INSERT INTO `chat_session` VALUES (18, 17, '新对话', '[\"一般倾诉\"]', 0, 0, 1, '2026-07-16 03:41:39', '2026-07-16 03:42:12');
INSERT INTO `chat_session` VALUES (19, 17, '新对话', '[\"一般倾诉\"]', 0, 0, 1, '2026-07-16 10:13:36', '2026-07-16 10:14:05');

-- ----------------------------
-- Table structure for consultation_record
-- ----------------------------
DROP TABLE IF EXISTS `consultation_record`;
CREATE TABLE `consultation_record`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `appointment_id` bigint NOT NULL COMMENT '关联预约ID',
  `student_id` int NOT NULL COMMENT '学生ID',
  `counselor_id` int NOT NULL COMMENT '咨询师ID',
  `check_in_time` datetime NULL DEFAULT NULL COMMENT '签到时间',
  `start_time` datetime NULL DEFAULT NULL COMMENT '实际开始时间',
  `end_time` datetime NULL DEFAULT NULL COMMENT '结束时间',
  `summary_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '咨询复盘笔记(加密存储)',
  `assessment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '初步评估',
  `follow_up_plan` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '后续跟进计划',
  `is_encrypted` tinyint NULL DEFAULT 1 COMMENT '是否已加密:0否,1是',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'ONGOING',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `appointment_id`(`appointment_id` ASC) USING BTREE,
  INDEX `idx_counselor_id`(`counselor_id` ASC) USING BTREE,
  INDEX `idx_student_id`(`student_id` ASC) USING BTREE,
  CONSTRAINT `consultation_record_ibfk_1` FOREIGN KEY (`appointment_id`) REFERENCES `appointment` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `consultation_record_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `consultation_record_ibfk_3` FOREIGN KEY (`counselor_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '线下咨询记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of consultation_record
-- ----------------------------
INSERT INTO `consultation_record` VALUES (1, 29, 15, 20, '2026-07-14 09:00:00', '2026-07-14 09:02:00', '2026-07-14 09:50:00', '学生主诉学业压力大，近两周睡眠不足，有明显的焦虑躯体化症状。运用CBT认知重构技术帮助学生识别不合理信念，制定作息调整计划。', '初步评估为适应性障碍伴焦虑情绪，无自杀风险。建议每周一次咨询持续6-8周。', '1.每天记录情绪日记和睡眠时间\n2.练习腹式呼吸放松法\n3.下周同一时间复诊', 1, 'COMPLETED', '2026-07-15 16:20:09', '2026-07-15 17:33:21');
INSERT INTO `consultation_record` VALUES (2, 30, 17, 21, '2026-07-16 01:17:11', '2026-07-16 01:17:11', '2026-07-14 10:55:00', '来', '预警等级：HIGH；触发原因：测评得分异常: 2, 总分=100.0, 风险等级=HIGH', '1.每天记录3件做得好的事情\n2.尝试一项新的兴趣爱好\n3.两周后复诊', 1, 'COMPLETED', '2026-07-15 16:20:10', '2026-07-16 01:17:10');
INSERT INTO `consultation_record` VALUES (3, 31, 18, 20, '2026-07-13 14:00:00', '2026-07-13 14:02:00', '2026-07-13 14:52:00', '学生与父母关系紧张，父母过度干预学业规划导致学生抵触。运用家庭系统理论分析，教授非暴力沟通技巧。', '家庭关系冲突导致的情绪困扰，伴有轻度抑郁。学生自我觉察能力较好。', '1.练习非暴力沟通四步法\n2.尝试给父母写信表达感受\n3.一个月后复诊', 1, 'COMPLETED', '2026-07-15 16:20:10', '2026-07-15 17:33:21');
INSERT INTO `consultation_record` VALUES (4, 32, 78, 21, '2026-07-12 09:00:00', '2026-07-12 09:03:00', '2026-07-12 09:48:00', '学生主诉社交场合紧张，回避小组讨论。使用系统脱敏法和社交技能训练逐步建立信心。', '社交焦虑障碍（轻度），功能损害较轻，学业未受明显影响。', '1.建立焦虑等级表\n2.从低焦虑情境开始练习\n3.三周后复诊', 1, 'COMPLETED', '2026-07-15 16:20:10', '2026-07-15 17:33:21');
INSERT INTO `consultation_record` VALUES (5, 34, 13, 21, '2026-07-08 14:00:00', '2026-07-08 14:01:00', '2026-07-08 14:48:00', '学生因失恋情绪低落三周，伴食欲减退和失眠。运用接纳承诺疗法帮助学生理解并探索有价值的生活方向。', '适应障碍伴抑郁情绪，与失恋应激事件直接相关，无自杀意念。', '1.允许悲伤，设定固定\"悲伤时间\"\n2.每周至少三次体育活动\n3.两周后复诊', 1, 'COMPLETED', '2026-07-15 16:20:10', '2026-07-15 17:33:21');
INSERT INTO `consultation_record` VALUES (6, 21, 35, 21, '2026-07-15 17:34:09', '2026-07-15 17:34:09', '2026-07-15 17:39:41', '[测试数据] 学生刚完成签到，准备开始首次咨询。SAS标准分58分（中度焦虑），SDS标准分52分（轻度抑郁）。', '初步评估：中度焦虑状态，需进一步观察。', '后续跟进：建议进行认知行为疗法干预，每周一次。', 0, 'COMPLETED', '2026-07-15 17:34:09', '2026-07-15 17:39:41');
INSERT INTO `consultation_record` VALUES (7, 23, 37, 21, NULL, NULL, NULL, '[测试数据] 学生未按约定时间到场，事后联系得知因个人原因无法参加。预约已取消。', '', '', 0, 'CANCELLED', '2026-07-15 17:34:09', '2026-07-15 17:34:09');
INSERT INTO `consultation_record` VALUES (8, 35, 7, 21, '2026-07-15 18:31:57', '2026-07-15 18:31:57', NULL, 'mmm', '预警等级：MEDIUM；触发原因：情绪管理困难', NULL, 1, 'ONGOING', '2026-07-15 17:49:17', '2026-07-15 18:31:56');
INSERT INTO `consultation_record` VALUES (9, 36, 79, 21, '2026-07-15 18:36:53', '2026-07-15 18:36:53', NULL, '干涉', '预警等级：HIGH；触发原因：SAS标准分65，提示重度焦虑', NULL, 1, 'ONGOING', '2026-07-15 17:50:06', '2026-07-15 18:36:53');
INSERT INTO `consultation_record` VALUES (10, 14, 17, 21, '2026-07-15 17:51:20', NULL, '2026-07-15 21:15:27', NULL, NULL, NULL, 1, 'COMPLETED', '2026-07-15 17:51:20', '2026-07-15 21:15:27');
INSERT INTO `consultation_record` VALUES (11, 37, 17, 10, NULL, NULL, NULL, '学生已预约咨询，主题：', '待咨询', NULL, 0, 'ONGOING', '2026-07-15 21:03:56', '2026-07-15 21:03:56');

-- ----------------------------
-- Table structure for counselor_schedule
-- ----------------------------
DROP TABLE IF EXISTS `counselor_schedule`;
CREATE TABLE `counselor_schedule`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `counselor_id` int NOT NULL COMMENT '咨询师ID',
  `schedule_date` date NOT NULL COMMENT '排班日期',
  `time_slot` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '时段:08:00-09:00/09:00-10:00...',
  `max_appointments` int NOT NULL DEFAULT 1 COMMENT '最大预约人数',
  `current_appointments` int NOT NULL DEFAULT 0 COMMENT '已预约人数',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'OFF' COMMENT '状态: AVAILABLE=可预约, OFF=休息',
  `location` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '咨询地点',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_counselor_date_slot`(`counselor_id` ASC, `schedule_date` ASC, `time_slot` ASC) USING BTREE,
  INDEX `idx_date`(`schedule_date` ASC) USING BTREE,
  CONSTRAINT `counselor_schedule_ibfk_1` FOREIGN KEY (`counselor_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 979 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '咨询师排班表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of counselor_schedule
-- ----------------------------
INSERT INTO `counselor_schedule` VALUES (517, 21, '2026-08-03', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (518, 21, '2026-08-03', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (519, 21, '2026-08-03', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (520, 21, '2026-08-03', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (521, 21, '2026-08-04', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (522, 21, '2026-08-04', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (523, 21, '2026-08-04', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (524, 21, '2026-08-04', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (525, 21, '2026-08-05', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (526, 21, '2026-08-05', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (527, 21, '2026-08-05', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (528, 21, '2026-08-05', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (529, 21, '2026-08-06', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (530, 21, '2026-08-06', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (531, 21, '2026-08-06', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (532, 21, '2026-08-06', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (533, 21, '2026-08-07', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (534, 21, '2026-08-07', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (535, 21, '2026-08-07', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (536, 21, '2026-08-07', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:36');
INSERT INTO `counselor_schedule` VALUES (557, 21, '2026-07-27', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (558, 21, '2026-07-27', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (559, 21, '2026-07-27', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (560, 21, '2026-07-27', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (561, 21, '2026-07-28', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (562, 21, '2026-07-28', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (563, 21, '2026-07-28', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (564, 21, '2026-07-28', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (565, 21, '2026-07-29', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (567, 21, '2026-07-29', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (569, 21, '2026-07-29', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (571, 21, '2026-07-29', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (573, 21, '2026-07-30', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (575, 21, '2026-07-30', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (577, 21, '2026-07-30', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (579, 21, '2026-07-30', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (581, 21, '2026-07-31', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (583, 21, '2026-07-31', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (585, 21, '2026-07-31', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (587, 21, '2026-07-31', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (597, 21, '2026-07-20', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (598, 21, '2026-07-20', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (599, 21, '2026-07-20', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (600, 21, '2026-07-20', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (601, 21, '2026-07-21', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (602, 21, '2026-07-21', '10:00', 1, 1, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (603, 21, '2026-07-21', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (604, 21, '2026-07-21', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (605, 21, '2026-07-22', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (606, 21, '2026-07-22', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (607, 21, '2026-07-22', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (608, 21, '2026-07-22', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (609, 21, '2026-07-23', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (610, 21, '2026-07-23', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (611, 21, '2026-07-23', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (612, 21, '2026-07-23', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (613, 21, '2026-07-24', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (614, 21, '2026-07-24', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (615, 21, '2026-07-24', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (616, 21, '2026-07-13', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (617, 21, '2026-07-24', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (618, 21, '2026-07-13', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (619, 21, '2026-07-13', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (620, 21, '2026-07-13', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (621, 21, '2026-07-14', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (622, 21, '2026-07-14', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (623, 21, '2026-07-14', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (624, 21, '2026-07-14', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (625, 21, '2026-07-15', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (626, 21, '2026-07-15', '10:00', 1, 1, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (627, 21, '2026-07-15', '14:00', 1, 1, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (628, 21, '2026-07-15', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (629, 21, '2026-07-16', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (630, 21, '2026-07-16', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (631, 21, '2026-07-16', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (632, 21, '2026-07-16', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (633, 21, '2026-07-17', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (634, 21, '2026-07-17', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (635, 21, '2026-07-17', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (636, 21, '2026-07-17', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (657, 21, '2026-07-06', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (658, 21, '2026-07-06', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (660, 21, '2026-07-06', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (662, 21, '2026-07-06', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (664, 21, '2026-07-07', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (666, 21, '2026-07-07', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (668, 21, '2026-07-07', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (670, 21, '2026-07-07', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (672, 21, '2026-07-08', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (674, 21, '2026-07-08', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (676, 21, '2026-07-08', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (678, 21, '2026-07-08', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (680, 21, '2026-07-09', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (682, 21, '2026-07-09', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (684, 21, '2026-07-09', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (686, 21, '2026-07-09', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (688, 21, '2026-07-10', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (690, 21, '2026-07-10', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (692, 21, '2026-07-10', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (694, 21, '2026-07-10', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (697, 21, '2026-06-22', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (698, 21, '2026-06-29', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (699, 21, '2026-06-22', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (700, 21, '2026-06-29', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (701, 21, '2026-06-22', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (702, 21, '2026-06-29', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (703, 21, '2026-06-22', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:37');
INSERT INTO `counselor_schedule` VALUES (704, 21, '2026-06-29', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (705, 21, '2026-06-23', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (706, 21, '2026-06-30', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (707, 21, '2026-06-23', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (708, 21, '2026-06-30', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (709, 21, '2026-06-23', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (710, 21, '2026-06-30', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (711, 21, '2026-06-23', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (712, 21, '2026-06-30', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (713, 21, '2026-06-24', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (714, 21, '2026-07-01', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (715, 21, '2026-06-24', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (716, 21, '2026-07-01', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (717, 21, '2026-06-24', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (718, 21, '2026-07-01', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (719, 21, '2026-06-24', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (720, 21, '2026-07-01', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (721, 21, '2026-06-25', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (722, 21, '2026-07-02', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (723, 21, '2026-06-25', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (724, 21, '2026-07-02', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (725, 21, '2026-06-25', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (726, 21, '2026-07-02', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (727, 21, '2026-06-25', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (728, 21, '2026-07-02', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (729, 21, '2026-06-26', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (730, 21, '2026-07-03', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (731, 21, '2026-06-26', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (732, 21, '2026-07-03', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (733, 21, '2026-06-26', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (734, 21, '2026-07-03', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (735, 21, '2026-06-26', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (736, 21, '2026-07-03', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:08:38');
INSERT INTO `counselor_schedule` VALUES (757, 21, '2026-07-18', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:29');
INSERT INTO `counselor_schedule` VALUES (758, 21, '2026-07-18', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:29');
INSERT INTO `counselor_schedule` VALUES (759, 21, '2026-07-18', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:29');
INSERT INTO `counselor_schedule` VALUES (760, 21, '2026-07-18', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:29');
INSERT INTO `counselor_schedule` VALUES (761, 21, '2026-07-19', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:29');
INSERT INTO `counselor_schedule` VALUES (762, 21, '2026-07-19', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:29');
INSERT INTO `counselor_schedule` VALUES (763, 21, '2026-07-19', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:29');
INSERT INTO `counselor_schedule` VALUES (764, 21, '2026-07-19', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:29');
INSERT INTO `counselor_schedule` VALUES (785, 21, '2026-07-25', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:37');
INSERT INTO `counselor_schedule` VALUES (786, 21, '2026-07-25', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:37');
INSERT INTO `counselor_schedule` VALUES (787, 21, '2026-07-25', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:37');
INSERT INTO `counselor_schedule` VALUES (788, 21, '2026-07-25', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:37');
INSERT INTO `counselor_schedule` VALUES (789, 21, '2026-07-26', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:37');
INSERT INTO `counselor_schedule` VALUES (790, 21, '2026-07-26', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:37');
INSERT INTO `counselor_schedule` VALUES (791, 21, '2026-07-26', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:37');
INSERT INTO `counselor_schedule` VALUES (792, 21, '2026-07-26', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:37');
INSERT INTO `counselor_schedule` VALUES (813, 21, '2026-08-01', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:39');
INSERT INTO `counselor_schedule` VALUES (814, 21, '2026-08-01', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:39');
INSERT INTO `counselor_schedule` VALUES (815, 21, '2026-08-01', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:39');
INSERT INTO `counselor_schedule` VALUES (816, 21, '2026-08-01', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:39');
INSERT INTO `counselor_schedule` VALUES (817, 21, '2026-08-02', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:39');
INSERT INTO `counselor_schedule` VALUES (818, 21, '2026-08-02', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:39');
INSERT INTO `counselor_schedule` VALUES (819, 21, '2026-08-02', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:39');
INSERT INTO `counselor_schedule` VALUES (820, 21, '2026-08-02', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:17:39');
INSERT INTO `counselor_schedule` VALUES (841, 21, '2026-08-08', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:56');
INSERT INTO `counselor_schedule` VALUES (842, 21, '2026-08-08', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:56');
INSERT INTO `counselor_schedule` VALUES (843, 21, '2026-08-08', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:56');
INSERT INTO `counselor_schedule` VALUES (844, 21, '2026-08-08', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:56');
INSERT INTO `counselor_schedule` VALUES (845, 21, '2026-08-09', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:56');
INSERT INTO `counselor_schedule` VALUES (846, 21, '2026-08-09', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:56');
INSERT INTO `counselor_schedule` VALUES (847, 21, '2026-08-09', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:56');
INSERT INTO `counselor_schedule` VALUES (848, 21, '2026-08-09', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:56');
INSERT INTO `counselor_schedule` VALUES (849, 21, '2026-08-10', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (850, 21, '2026-08-10', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (851, 21, '2026-08-10', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (852, 21, '2026-08-10', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (853, 21, '2026-08-11', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (854, 21, '2026-08-11', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (855, 21, '2026-08-11', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (856, 21, '2026-08-11', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (857, 21, '2026-08-12', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (858, 21, '2026-08-12', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (859, 21, '2026-08-12', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (860, 21, '2026-08-12', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (861, 21, '2026-08-13', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (862, 21, '2026-08-13', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (863, 21, '2026-08-13', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (864, 21, '2026-08-13', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (865, 21, '2026-08-14', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (866, 21, '2026-08-14', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (867, 21, '2026-08-14', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (868, 21, '2026-08-14', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (869, 21, '2026-08-15', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (870, 21, '2026-08-15', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (871, 21, '2026-08-15', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (872, 21, '2026-08-15', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (873, 21, '2026-08-16', '09:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (874, 21, '2026-08-16', '10:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (875, 21, '2026-08-16', '14:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (876, 21, '2026-08-16', '15:00', 1, 0, 'OFF', NULL, '2026-07-14 19:28:57');
INSERT INTO `counselor_schedule` VALUES (877, 20, '2026-07-13', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (878, 20, '2026-07-13', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (879, 20, '2026-07-13', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (880, 20, '2026-07-13', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (881, 20, '2026-07-14', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (882, 20, '2026-07-14', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (883, 20, '2026-07-14', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (884, 20, '2026-07-14', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (885, 20, '2026-07-15', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (886, 20, '2026-07-15', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (887, 20, '2026-07-15', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (888, 20, '2026-07-15', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (889, 20, '2026-07-16', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (890, 20, '2026-07-16', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (891, 20, '2026-07-16', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (892, 20, '2026-07-16', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (893, 20, '2026-07-17', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (894, 20, '2026-07-17', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (895, 20, '2026-07-17', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (896, 20, '2026-07-17', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (897, 20, '2026-07-18', '09:00', 1, 0, 'OFF', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (898, 20, '2026-07-18', '10:00', 1, 0, 'OFF', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (899, 20, '2026-07-18', '14:00', 1, 0, 'OFF', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (900, 20, '2026-07-18', '15:00', 1, 0, 'OFF', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (901, 20, '2026-07-19', '09:00', 1, 0, 'OFF', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (902, 20, '2026-07-19', '10:00', 1, 0, 'OFF', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (903, 20, '2026-07-19', '14:00', 1, 0, 'OFF', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (904, 20, '2026-07-19', '15:00', 1, 0, 'OFF', NULL, '2026-07-15 15:46:30');
INSERT INTO `counselor_schedule` VALUES (905, 20, '2026-07-15', '09:00-10:00', 2, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (906, 20, '2026-07-15', '10:00-11:00', 2, 0, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (907, 20, '2026-07-15', '14:00-15:00', 2, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (908, 20, '2026-07-15', '15:00-16:00', 2, 0, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (909, 21, '2026-07-15', '09:00-10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (910, 21, '2026-07-15', '10:00-11:00', 1, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (911, 21, '2026-07-15', '14:00-15:00', 1, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (912, 21, '2026-07-15', '15:00-16:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (913, 86, '2026-07-15', '09:00-10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (914, 86, '2026-07-15', '14:00-15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (915, 87, '2026-07-15', '10:00-11:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (916, 87, '2026-07-15', '15:00-16:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (917, 20, '2026-07-14', '09:00-10:00', 2, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (918, 21, '2026-07-14', '10:00-11:00', 2, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (919, 20, '2026-07-13', '14:00-15:00', 2, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (920, 21, '2026-07-12', '09:00-10:00', 2, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (921, 20, '2026-07-10', '10:00-11:00', 2, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (922, 21, '2026-07-08', '14:00-15:00', 2, 1, 'AVAILABLE', NULL, '2026-07-15 16:19:17');
INSERT INTO `counselor_schedule` VALUES (923, 20, '2026-07-20', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (924, 20, '2026-07-20', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (925, 20, '2026-07-20', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (926, 20, '2026-07-20', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (927, 20, '2026-07-21', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (928, 20, '2026-07-21', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (929, 20, '2026-07-21', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (930, 20, '2026-07-21', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (931, 20, '2026-07-22', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (932, 20, '2026-07-22', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (933, 20, '2026-07-22', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (934, 20, '2026-07-22', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (935, 20, '2026-07-23', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (936, 20, '2026-07-23', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (937, 20, '2026-07-23', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (938, 20, '2026-07-23', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (939, 20, '2026-07-24', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (940, 20, '2026-07-24', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (941, 20, '2026-07-24', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (942, 20, '2026-07-24', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (943, 20, '2026-07-25', '09:00', 1, 0, 'OFF', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (944, 20, '2026-07-25', '10:00', 1, 0, 'OFF', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (945, 20, '2026-07-25', '14:00', 1, 0, 'OFF', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (946, 20, '2026-07-25', '15:00', 1, 0, 'OFF', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (947, 20, '2026-07-26', '09:00', 1, 0, 'OFF', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (948, 20, '2026-07-26', '10:00', 1, 0, 'OFF', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (949, 20, '2026-07-26', '14:00', 1, 0, 'OFF', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (950, 20, '2026-07-26', '15:00', 1, 0, 'OFF', NULL, '2026-07-15 16:22:59');
INSERT INTO `counselor_schedule` VALUES (951, 20, '2026-07-06', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (952, 20, '2026-07-06', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (953, 20, '2026-07-06', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (954, 20, '2026-07-06', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (955, 20, '2026-07-07', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (956, 20, '2026-07-07', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (957, 20, '2026-07-07', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (958, 20, '2026-07-07', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (959, 20, '2026-07-08', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (960, 20, '2026-07-08', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (961, 20, '2026-07-08', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (962, 20, '2026-07-08', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (963, 20, '2026-07-09', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (964, 20, '2026-07-09', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (965, 20, '2026-07-09', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (966, 20, '2026-07-09', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (967, 20, '2026-07-10', '09:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (968, 20, '2026-07-10', '10:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (969, 20, '2026-07-10', '14:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (970, 20, '2026-07-10', '15:00', 1, 0, 'AVAILABLE', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (971, 20, '2026-07-11', '09:00', 1, 0, 'OFF', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (972, 20, '2026-07-11', '10:00', 1, 0, 'OFF', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (973, 20, '2026-07-11', '14:00', 1, 0, 'OFF', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (974, 20, '2026-07-11', '15:00', 1, 0, 'OFF', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (975, 20, '2026-07-12', '09:00', 1, 0, 'OFF', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (976, 20, '2026-07-12', '10:00', 1, 0, 'OFF', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (977, 20, '2026-07-12', '14:00', 1, 0, 'OFF', NULL, '2026-07-15 16:23:02');
INSERT INTO `counselor_schedule` VALUES (978, 20, '2026-07-12', '15:00', 1, 0, 'OFF', NULL, '2026-07-15 16:23:02');

-- ----------------------------
-- Table structure for file_upload
-- ----------------------------
DROP TABLE IF EXISTS `file_upload`;
CREATE TABLE `file_upload`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '原始文件名',
  `stored_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '存储文件名(UUID)',
  `file_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '存储路径',
  `file_size` bigint NULL DEFAULT NULL COMMENT '文件大小(bytes)',
  `file_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '文件类型(MIME)',
  `uploader_id` int NOT NULL COMMENT '上传者ID',
  `uploader_role` enum('STUDENT','COUNSELOR','ADMIN') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '上传者角色',
  `related_type` enum('CONSULTATION','SELF_REPORT','OTHER') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '关联类型:咨询附件/自述文档/其他',
  `related_id` bigint NULL DEFAULT NULL COMMENT '关联业务ID',
  `is_encrypted` tinyint NULL DEFAULT 0 COMMENT '是否加密:0否,1是',
  `encryption_key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '加密密钥(如使用)',
  `download_count` int NULL DEFAULT 0 COMMENT '下载次数',
  `status` tinyint NULL DEFAULT 1 COMMENT '状态:0删除,1正常',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_uploader_id`(`uploader_id` ASC) USING BTREE,
  CONSTRAINT `file_upload_ibfk_1` FOREIGN KEY (`uploader_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '文件上传表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of file_upload
-- ----------------------------

-- ----------------------------
-- Table structure for notification
-- ----------------------------
DROP TABLE IF EXISTS `notification`;
CREATE TABLE `notification`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `receiver_id` int NOT NULL COMMENT '接收者ID',
  `sender_id` int NULL DEFAULT NULL COMMENT '发送者ID(系统消息为NULL)',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息内容',
  `type` enum('APPOINTMENT_CHANGE','ALERT_REMINDER','CONSULTATION_SCHEDULE','SYSTEM','ASSESSMENT_RESULT','OTHER') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息类型',
  `is_read` tinyint NULL DEFAULT 0 COMMENT '是否已读:0未读,1已读',
  `related_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '关联业务类型',
  `related_id` bigint NULL DEFAULT NULL COMMENT '关联业务ID',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `read_at` datetime NULL DEFAULT NULL COMMENT '阅读时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `sender_id`(`sender_id` ASC) USING BTREE,
  INDEX `idx_receiver_id`(`receiver_id` ASC) USING BTREE,
  INDEX `idx_is_read`(`is_read` ASC) USING BTREE,
  CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`receiver_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `notification_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 55 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '站内消息通知表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of notification
-- ----------------------------
INSERT INTO `notification` VALUES (1, 21, 17, '新预约通知', '有学生预约了您的咨询服务，请及时确认', 'CONSULTATION_SCHEDULE', 0, 'CONSULTATIONSCHEDULE', 14, '2026-07-14 11:02:19', NULL);
INSERT INTO `notification` VALUES (2, 21, 17, '新预约通知', '有学生预约了您的咨询服务，请及时确认', 'CONSULTATION_SCHEDULE', 0, 'CONSULTATIONSCHEDULE', 15, '2026-07-14 11:53:27', NULL);
INSERT INTO `notification` VALUES (3, 21, 17, '预约已取消', '学生取消了预约: 学生主动取消', 'APPOINTMENT_CHANGE', 0, 'APPOINTMENTCHANGE', 15, '2026-07-14 12:15:44', NULL);
INSERT INTO `notification` VALUES (4, 2, 18, '新预约通知', '有学生预约了您的咨询服务，请及时确认', 'CONSULTATION_SCHEDULE', 0, 'CONSULTATIONSCHEDULE', 16, '2026-07-14 12:16:09', NULL);
INSERT INTO `notification` VALUES (5, 2, 17, '新预约通知', '有学生预约了您的咨询服务，请及时确认', 'CONSULTATION_SCHEDULE', 0, 'CONSULTATIONSCHEDULE', 17, '2026-07-14 19:18:05', NULL);
INSERT INTO `notification` VALUES (6, 2, 17, '预约已取消', '学生取消了预约: 学生主动取消', 'APPOINTMENT_CHANGE', 0, 'APPOINTMENTCHANGE', 17, '2026-07-14 19:18:33', NULL);
INSERT INTO `notification` VALUES (7, 21, 17, '新预约通知', '有学生预约了您的咨询服务，请及时确认', 'CONSULTATION_SCHEDULE', 0, 'CONSULTATIONSCHEDULE', 18, '2026-07-14 19:18:42', NULL);
INSERT INTO `notification` VALUES (8, 2, 17, '新预约通知', '有学生预约了您的咨询服务，请及时确认', 'CONSULTATION_SCHEDULE', 0, 'CONSULTATIONSCHEDULE', 24, '2026-07-15 15:45:39', NULL);
INSERT INTO `notification` VALUES (9, 21, 17, '预约已取消', '学生取消了预约: 学生主动取消', 'APPOINTMENT_CHANGE', 0, 'APPOINTMENTCHANGE', 18, '2026-07-15 15:45:43', NULL);
INSERT INTO `notification` VALUES (10, 12, 20, '预约确认通知', '您的心理咨询预约已确认，咨询师：陈老师。请提前5分钟到达心理咨询中心。', 'APPOINTMENT_CHANGE', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (11, 13, 21, '预约确认通知', '您的心理咨询预约已确认，咨询师：林老师。请提前5分钟到达心理咨询中心。', 'APPOINTMENT_CHANGE', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (12, 14, 1, '心理健康预警通知', '根据您最近的测评结果，系统检测到您可能存在较高的心理压力。建议预约心理咨询。', 'ALERT_REMINDER', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (13, 19, 1, '心理健康预警通知', '根据您最近的测评结果，系统检测到您可能存在较高的心理压力。建议预约心理咨询。', 'ALERT_REMINDER', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (14, 79, 1, '心理健康预警通知', '根据您最近的测评结果，系统检测到较高的焦虑水平。建议学习放松技巧。', 'ALERT_REMINDER', 1, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (15, 12, NULL, '测评完成通知', '您已成功完成SCL-90症状自评量表，测评报告已生成。', 'ASSESSMENT_RESULT', 1, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (16, 13, NULL, '测评完成通知', '您已成功完成SCL-90症状自评量表，测评报告已生成。', 'ASSESSMENT_RESULT', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (17, 16, NULL, '测评完成通知', '您已成功完成PHQ-9抑郁筛查量表。请关注测评建议。', 'ASSESSMENT_RESULT', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (18, 4, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (19, 5, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (20, 6, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (21, 7, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (22, 9, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (23, 11, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (24, 12, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (25, 13, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (26, 14, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (27, 15, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (28, 17, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (29, 18, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (30, 19, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (31, 33, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (32, 34, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (33, 35, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (34, 36, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (35, 37, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (36, 78, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (37, 79, 1, '系统公告：心理健康月活动通知', '本月为学校心理健康月，心理咨询中心将举办系列心理健康讲座和团体辅导活动。欢迎同学们报名参加！', 'SYSTEM', 0, NULL, NULL, '2026-07-15 16:20:10', NULL);
INSERT INTO `notification` VALUES (49, 17, 21, '预约已确认', '您的预约已被咨询师确认，请准时参加', 'APPOINTMENT_CHANGE', 0, 'APPOINTMENTCHANGE', 14, '2026-07-15 19:21:55', NULL);
INSERT INTO `notification` VALUES (50, 2, 17, '预约已取消', '学生取消了预约: 学生主动取消', 'APPOINTMENT_CHANGE', 0, 'APPOINTMENTCHANGE', 24, '2026-07-15 19:22:16', NULL);
INSERT INTO `notification` VALUES (51, 10, 17, '新预约通知', '有学生预约了您的咨询服务，请及时确认', 'CONSULTATION_SCHEDULE', 0, 'CONSULTATIONSCHEDULE', 37, '2026-07-15 21:03:56', NULL);
INSERT INTO `notification` VALUES (52, 10, 17, '预约已确认', '预约 2026-07-16 10:00-10:50 已确认。', 'APPOINTMENT_CHANGE', 0, 'APPOINTMENTCHANGE', 37, '2026-07-16 01:15:12', NULL);
INSERT INTO `notification` VALUES (53, 17, 21, '预警处理：咨询预约待确认', '咨询师为您安排了咨询预约：2026-07-21 10:00-11:00。\n\n干预记录：来\n\n请点击“确认”或“申请改期”进行反馈。', 'APPOINTMENT_CHANGE', 0, 'APPOINTMENTCHANGE', 30, '2026-07-16 01:17:10', NULL);
INSERT INTO `notification` VALUES (54, 21, 17, '学生申请改期', '学生申请将预约改期至 2026-07-22 10:00-11:00，原因：3，请确认。', 'APPOINTMENT_CHANGE', 0, 'APPOINTMENTCHANGE', 30, '2026-07-16 01:17:48', NULL);

-- ----------------------------
-- Table structure for operation_log
-- ----------------------------
DROP TABLE IF EXISTS `operation_log`;
CREATE TABLE `operation_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `operator_id` int NOT NULL COMMENT '操作人ID',
  `operator_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '操作人姓名',
  `operator_role` enum('STUDENT','COUNSELOR','ADMIN') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '操作人角色',
  `operation_type` enum('VIEW_SENSITIVE_DATA','EXPORT_SENSITIVE_DATA','LOGIN','LOGOUT','DELETE','UPDATE','CREATE','OTHER') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '操作类型',
  `target_type` enum('ASSESSMENT_RECORD','STUDENT_INFO','CONSULTATION_RECORD','ALERT_RECORD','CHAT_SESSION','REPORT_EXPORT','OTHER') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '目标数据类型',
  `target_id` bigint NULL DEFAULT NULL COMMENT '目标数据ID',
  `target_description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '目标描述(脱敏后)',
  `detail` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '操作详情(JSON)',
  `ip_address` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '操作IP',
  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '浏览器UA',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_operator_id`(`operator_id` ASC) USING BTREE,
  INDEX `idx_operation_type`(`operation_type` ASC) USING BTREE,
  INDEX `idx_target_type`(`target_type` ASC) USING BTREE,
  INDEX `idx_created_at`(`created_at` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 966 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '操作日志审计表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of operation_log
-- ----------------------------
INSERT INTO `operation_log` VALUES (1, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:27:19');
INSERT INTO `operation_log` VALUES (2, 9, '张三', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:28:49');
INSERT INTO `operation_log` VALUES (3, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:29:33');
INSERT INTO `operation_log` VALUES (4, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:30:30');
INSERT INTO `operation_log` VALUES (5, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:30:31');
INSERT INTO `operation_log` VALUES (6, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:31:35');
INSERT INTO `operation_log` VALUES (7, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:31:43');
INSERT INTO `operation_log` VALUES (8, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:32:10');
INSERT INTO `operation_log` VALUES (9, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:43:40');
INSERT INTO `operation_log` VALUES (10, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:44:41');
INSERT INTO `operation_log` VALUES (11, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:44:50');
INSERT INTO `operation_log` VALUES (12, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:45:06');
INSERT INTO `operation_log` VALUES (13, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/admin/export-data.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:48:16');
INSERT INTO `operation_log` VALUES (14, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:48:45');
INSERT INTO `operation_log` VALUES (15, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:48:46');
INSERT INTO `operation_log` VALUES (16, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:49:18');
INSERT INTO `operation_log` VALUES (17, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:49:42');
INSERT INTO `operation_log` VALUES (18, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:50:00');
INSERT INTO `operation_log` VALUES (19, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:50:20');
INSERT INTO `operation_log` VALUES (20, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:50:45');
INSERT INTO `operation_log` VALUES (21, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:57:28');
INSERT INTO `operation_log` VALUES (22, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:58:07');
INSERT INTO `operation_log` VALUES (23, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 18:58:35');
INSERT INTO `operation_log` VALUES (24, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 19:01:15');
INSERT INTO `operation_log` VALUES (25, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 19:01:19');
INSERT INTO `operation_log` VALUES (26, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 19:01:21');
INSERT INTO `operation_log` VALUES (27, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出登录', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 19:02:33');
INSERT INTO `operation_log` VALUES (28, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 19:02:35');
INSERT INTO `operation_log` VALUES (29, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-10 19:05:57');
INSERT INTO `operation_log` VALUES (30, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 17:42:49');
INSERT INTO `operation_log` VALUES (31, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 17:42:55');
INSERT INTO `operation_log` VALUES (32, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 17:47:14');
INSERT INTO `operation_log` VALUES (33, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 17:49:12');
INSERT INTO `operation_log` VALUES (34, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 17:49:23');
INSERT INTO `operation_log` VALUES (35, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 17:49:53');
INSERT INTO `operation_log` VALUES (36, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 17:50:42');
INSERT INTO `operation_log` VALUES (37, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:03:01');
INSERT INTO `operation_log` VALUES (38, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:03:20');
INSERT INTO `operation_log` VALUES (39, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:06:00');
INSERT INTO `operation_log` VALUES (40, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:06:20');
INSERT INTO `operation_log` VALUES (41, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:08:58');
INSERT INTO `operation_log` VALUES (42, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:11:20');
INSERT INTO `operation_log` VALUES (43, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:13:42');
INSERT INTO `operation_log` VALUES (44, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:17:17');
INSERT INTO `operation_log` VALUES (45, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:18:13');
INSERT INTO `operation_log` VALUES (46, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:20:52');
INSERT INTO `operation_log` VALUES (47, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:21:17');
INSERT INTO `operation_log` VALUES (48, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:45:03');
INSERT INTO `operation_log` VALUES (49, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:48:16');
INSERT INTO `operation_log` VALUES (50, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/log/export', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:48:29');
INSERT INTO `operation_log` VALUES (51, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:49:14');
INSERT INTO `operation_log` VALUES (52, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:51:29');
INSERT INTO `operation_log` VALUES (53, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:55:49');
INSERT INTO `operation_log` VALUES (54, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/statistics/alert-levels', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:55:56');
INSERT INTO `operation_log` VALUES (55, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/statistics/alert-levels', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 18:56:02');
INSERT INTO `operation_log` VALUES (56, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 19:00:28');
INSERT INTO `operation_log` VALUES (57, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/statistics/alert-levels', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 19:00:40');
INSERT INTO `operation_log` VALUES (58, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 19:03:34');
INSERT INTO `operation_log` VALUES (59, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 19:29:31');
INSERT INTO `operation_log` VALUES (60, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/statistics/alert-levels', NULL, '0:0:0:0:0:0:0:1', NULL, '2026-07-12 19:58:54');
INSERT INTO `operation_log` VALUES (61, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 20:01:40');
INSERT INTO `operation_log` VALUES (62, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 20:02:59');
INSERT INTO `operation_log` VALUES (63, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 20:07:38');
INSERT INTO `operation_log` VALUES (64, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 20:33:26');
INSERT INTO `operation_log` VALUES (65, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-12 20:38:14');
INSERT INTO `operation_log` VALUES (66, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 14:42:21');
INSERT INTO `operation_log` VALUES (67, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 14:42:39');
INSERT INTO `operation_log` VALUES (68, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/log/export', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 14:44:41');
INSERT INTO `operation_log` VALUES (69, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 14:45:07');
INSERT INTO `operation_log` VALUES (70, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 14:45:10');
INSERT INTO `operation_log` VALUES (71, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 14:45:18');
INSERT INTO `operation_log` VALUES (72, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 14:45:24');
INSERT INTO `operation_log` VALUES (73, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 14:57:03');
INSERT INTO `operation_log` VALUES (74, 11, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 16:25:49');
INSERT INTO `operation_log` VALUES (75, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 16:26:27');
INSERT INTO `operation_log` VALUES (76, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 16:55:24');
INSERT INTO `operation_log` VALUES (77, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 17:07:25');
INSERT INTO `operation_log` VALUES (78, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 17:07:26');
INSERT INTO `operation_log` VALUES (79, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 17:20:36');
INSERT INTO `operation_log` VALUES (80, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 17:23:12');
INSERT INTO `operation_log` VALUES (81, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 17:51:37');
INSERT INTO `operation_log` VALUES (82, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 17:55:36');
INSERT INTO `operation_log` VALUES (83, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 18:06:37');
INSERT INTO `operation_log` VALUES (84, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 18:12:41');
INSERT INTO `operation_log` VALUES (85, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 18:13:26');
INSERT INTO `operation_log` VALUES (86, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 18:14:52');
INSERT INTO `operation_log` VALUES (87, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 18:15:13');
INSERT INTO `operation_log` VALUES (88, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 18:54:57');
INSERT INTO `operation_log` VALUES (89, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 18:55:13');
INSERT INTO `operation_log` VALUES (90, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 19:07:27');
INSERT INTO `operation_log` VALUES (91, 12, '张三', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 19:25:23');
INSERT INTO `operation_log` VALUES (92, 12, '张三', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 19:26:03');
INSERT INTO `operation_log` VALUES (93, 9, '张三', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 19:26:49');
INSERT INTO `operation_log` VALUES (94, 12, '张三', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 19:27:00');
INSERT INTO `operation_log` VALUES (95, 7, 'cq', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-13 19:27:34');
INSERT INTO `operation_log` VALUES (96, 15, '赵六', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:32:53');
INSERT INTO `operation_log` VALUES (97, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:33:03');
INSERT INTO `operation_log` VALUES (98, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:33:13');
INSERT INTO `operation_log` VALUES (99, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:33:13');
INSERT INTO `operation_log` VALUES (100, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:33:15');
INSERT INTO `operation_log` VALUES (101, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:33:44');
INSERT INTO `operation_log` VALUES (102, 16, '孙七', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:33:53');
INSERT INTO `operation_log` VALUES (103, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:34:00');
INSERT INTO `operation_log` VALUES (104, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:34:13');
INSERT INTO `operation_log` VALUES (105, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:34:24');
INSERT INTO `operation_log` VALUES (106, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:44:50');
INSERT INTO `operation_log` VALUES (107, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:49:30');
INSERT INTO `operation_log` VALUES (108, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:52:01');
INSERT INTO `operation_log` VALUES (109, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 00:56:50');
INSERT INTO `operation_log` VALUES (110, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 01:01:17');
INSERT INTO `operation_log` VALUES (111, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 01:03:10');
INSERT INTO `operation_log` VALUES (112, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 01:46:47');
INSERT INTO `operation_log` VALUES (113, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 01:47:12');
INSERT INTO `operation_log` VALUES (114, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 01:48:42');
INSERT INTO `operation_log` VALUES (115, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 01:51:31');
INSERT INTO `operation_log` VALUES (116, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 01:55:29');
INSERT INTO `operation_log` VALUES (117, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 01:57:59');
INSERT INTO `operation_log` VALUES (118, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:01:31');
INSERT INTO `operation_log` VALUES (119, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:04:46');
INSERT INTO `operation_log` VALUES (120, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:07:23');
INSERT INTO `operation_log` VALUES (121, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:10:55');
INSERT INTO `operation_log` VALUES (122, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:11:12');
INSERT INTO `operation_log` VALUES (123, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:11:22');
INSERT INTO `operation_log` VALUES (124, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:11:22');
INSERT INTO `operation_log` VALUES (125, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:11:35');
INSERT INTO `operation_log` VALUES (126, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:11:36');
INSERT INTO `operation_log` VALUES (127, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:11:44');
INSERT INTO `operation_log` VALUES (128, 2, '王心理师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:12:04');
INSERT INTO `operation_log` VALUES (129, 2, '王心理师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:12:04');
INSERT INTO `operation_log` VALUES (130, 3, '李辅导员', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:12:20');
INSERT INTO `operation_log` VALUES (131, 3, '李辅导员', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 02:12:20');
INSERT INTO `operation_log` VALUES (132, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 10:04:21');
INSERT INTO `operation_log` VALUES (133, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 10:06:00');
INSERT INTO `operation_log` VALUES (134, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 10:21:30');
INSERT INTO `operation_log` VALUES (135, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 10:31:29');
INSERT INTO `operation_log` VALUES (136, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 10:48:41');
INSERT INTO `operation_log` VALUES (137, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 10:52:53');
INSERT INTO `operation_log` VALUES (138, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 10:55:12');
INSERT INTO `operation_log` VALUES (139, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:01:55');
INSERT INTO `operation_log` VALUES (140, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:02:45');
INSERT INTO `operation_log` VALUES (141, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:02:46');
INSERT INTO `operation_log` VALUES (142, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:07:51');
INSERT INTO `operation_log` VALUES (143, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:07:53');
INSERT INTO `operation_log` VALUES (144, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:08:04');
INSERT INTO `operation_log` VALUES (145, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:10:25');
INSERT INTO `operation_log` VALUES (146, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:10:31');
INSERT INTO `operation_log` VALUES (147, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:32:25');
INSERT INTO `operation_log` VALUES (148, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:32:26');
INSERT INTO `operation_log` VALUES (149, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:32:26');
INSERT INTO `operation_log` VALUES (150, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:32:30');
INSERT INTO `operation_log` VALUES (151, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:45:14');
INSERT INTO `operation_log` VALUES (152, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:45:16');
INSERT INTO `operation_log` VALUES (153, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:45:17');
INSERT INTO `operation_log` VALUES (154, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:52:26');
INSERT INTO `operation_log` VALUES (155, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:52:26');
INSERT INTO `operation_log` VALUES (156, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:52:30');
INSERT INTO `operation_log` VALUES (157, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:53:16');
INSERT INTO `operation_log` VALUES (158, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:53:57');
INSERT INTO `operation_log` VALUES (159, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 11:53:57');
INSERT INTO `operation_log` VALUES (160, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:07:49');
INSERT INTO `operation_log` VALUES (161, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:07:50');
INSERT INTO `operation_log` VALUES (162, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:08:04');
INSERT INTO `operation_log` VALUES (163, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:15:28');
INSERT INTO `operation_log` VALUES (164, 18, '吴九', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:16:02');
INSERT INTO `operation_log` VALUES (165, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:16:28');
INSERT INTO `operation_log` VALUES (166, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:16:28');
INSERT INTO `operation_log` VALUES (167, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:20:00');
INSERT INTO `operation_log` VALUES (168, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:20:02');
INSERT INTO `operation_log` VALUES (169, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:23:29');
INSERT INTO `operation_log` VALUES (170, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:23:31');
INSERT INTO `operation_log` VALUES (171, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:28:12');
INSERT INTO `operation_log` VALUES (172, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:28:14');
INSERT INTO `operation_log` VALUES (173, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:34:56');
INSERT INTO `operation_log` VALUES (174, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:34:58');
INSERT INTO `operation_log` VALUES (175, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:40:40');
INSERT INTO `operation_log` VALUES (176, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 12:40:41');
INSERT INTO `operation_log` VALUES (177, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 13:00:30');
INSERT INTO `operation_log` VALUES (178, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 13:00:31');
INSERT INTO `operation_log` VALUES (179, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 13:05:09');
INSERT INTO `operation_log` VALUES (180, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 13:05:10');
INSERT INTO `operation_log` VALUES (181, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 13:07:40');
INSERT INTO `operation_log` VALUES (182, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 13:07:41');
INSERT INTO `operation_log` VALUES (183, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 18:52:13');
INSERT INTO `operation_log` VALUES (184, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 18:52:13');
INSERT INTO `operation_log` VALUES (185, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 18:58:50');
INSERT INTO `operation_log` VALUES (186, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 18:58:51');
INSERT INTO `operation_log` VALUES (187, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:05:29');
INSERT INTO `operation_log` VALUES (188, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:05:30');
INSERT INTO `operation_log` VALUES (189, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:08:19');
INSERT INTO `operation_log` VALUES (190, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:08:20');
INSERT INTO `operation_log` VALUES (191, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:17:26');
INSERT INTO `operation_log` VALUES (192, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:17:27');
INSERT INTO `operation_log` VALUES (193, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:17:53');
INSERT INTO `operation_log` VALUES (194, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:18:14');
INSERT INTO `operation_log` VALUES (195, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:18:14');
INSERT INTO `operation_log` VALUES (196, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:18:27');
INSERT INTO `operation_log` VALUES (197, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:18:48');
INSERT INTO `operation_log` VALUES (198, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:18:54');
INSERT INTO `operation_log` VALUES (199, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:18:55');
INSERT INTO `operation_log` VALUES (200, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:20:03');
INSERT INTO `operation_log` VALUES (201, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:20:17');
INSERT INTO `operation_log` VALUES (202, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:20:29');
INSERT INTO `operation_log` VALUES (203, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:20:37');
INSERT INTO `operation_log` VALUES (204, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:21:16');
INSERT INTO `operation_log` VALUES (205, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:21:16');
INSERT INTO `operation_log` VALUES (206, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:23:01');
INSERT INTO `operation_log` VALUES (207, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:23:02');
INSERT INTO `operation_log` VALUES (208, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:28:40');
INSERT INTO `operation_log` VALUES (209, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:28:41');
INSERT INTO `operation_log` VALUES (210, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:36:48');
INSERT INTO `operation_log` VALUES (211, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:36:50');
INSERT INTO `operation_log` VALUES (212, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:36:50');
INSERT INTO `operation_log` VALUES (213, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:39:21');
INSERT INTO `operation_log` VALUES (214, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:39:23');
INSERT INTO `operation_log` VALUES (215, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:42:30');
INSERT INTO `operation_log` VALUES (216, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:42:31');
INSERT INTO `operation_log` VALUES (217, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 19:42:31');
INSERT INTO `operation_log` VALUES (218, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:04:19');
INSERT INTO `operation_log` VALUES (219, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:04:19');
INSERT INTO `operation_log` VALUES (220, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:08:23');
INSERT INTO `operation_log` VALUES (221, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:08:24');
INSERT INTO `operation_log` VALUES (222, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:15:16');
INSERT INTO `operation_log` VALUES (223, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:15:18');
INSERT INTO `operation_log` VALUES (224, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:15:45');
INSERT INTO `operation_log` VALUES (225, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:19:52');
INSERT INTO `operation_log` VALUES (226, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:19:54');
INSERT INTO `operation_log` VALUES (227, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:19:54');
INSERT INTO `operation_log` VALUES (228, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:20:14');
INSERT INTO `operation_log` VALUES (229, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:26:01');
INSERT INTO `operation_log` VALUES (230, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:26:03');
INSERT INTO `operation_log` VALUES (231, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:26:03');
INSERT INTO `operation_log` VALUES (232, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:29:55');
INSERT INTO `operation_log` VALUES (233, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:29:56');
INSERT INTO `operation_log` VALUES (234, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:35:26');
INSERT INTO `operation_log` VALUES (235, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:35:28');
INSERT INTO `operation_log` VALUES (236, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:35:35');
INSERT INTO `operation_log` VALUES (237, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:35:58');
INSERT INTO `operation_log` VALUES (238, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:36:00');
INSERT INTO `operation_log` VALUES (239, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:39:11');
INSERT INTO `operation_log` VALUES (240, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:39:12');
INSERT INTO `operation_log` VALUES (241, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:39:12');
INSERT INTO `operation_log` VALUES (242, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:43:03');
INSERT INTO `operation_log` VALUES (243, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:43:03');
INSERT INTO `operation_log` VALUES (244, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:47:29');
INSERT INTO `operation_log` VALUES (245, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:47:29');
INSERT INTO `operation_log` VALUES (246, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:47:31');
INSERT INTO `operation_log` VALUES (247, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:47:31');
INSERT INTO `operation_log` VALUES (248, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:47:31');
INSERT INTO `operation_log` VALUES (249, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:47:31');
INSERT INTO `operation_log` VALUES (250, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:47:32');
INSERT INTO `operation_log` VALUES (251, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:47:32');
INSERT INTO `operation_log` VALUES (252, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:48:06');
INSERT INTO `operation_log` VALUES (253, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:48:07');
INSERT INTO `operation_log` VALUES (254, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:48:07');
INSERT INTO `operation_log` VALUES (255, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:51:18');
INSERT INTO `operation_log` VALUES (256, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:51:20');
INSERT INTO `operation_log` VALUES (257, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:51:20');
INSERT INTO `operation_log` VALUES (258, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:51:36');
INSERT INTO `operation_log` VALUES (259, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:51:56');
INSERT INTO `operation_log` VALUES (260, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:51:56');
INSERT INTO `operation_log` VALUES (261, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:55:20');
INSERT INTO `operation_log` VALUES (262, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:55:22');
INSERT INTO `operation_log` VALUES (263, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:55:22');
INSERT INTO `operation_log` VALUES (264, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:55:25');
INSERT INTO `operation_log` VALUES (265, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:55:26');
INSERT INTO `operation_log` VALUES (266, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:55:26');
INSERT INTO `operation_log` VALUES (267, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:55:26');
INSERT INTO `operation_log` VALUES (268, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:56:09');
INSERT INTO `operation_log` VALUES (269, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:56:12');
INSERT INTO `operation_log` VALUES (270, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:56:12');
INSERT INTO `operation_log` VALUES (271, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:56:23');
INSERT INTO `operation_log` VALUES (272, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:56:23');
INSERT INTO `operation_log` VALUES (273, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:56:23');
INSERT INTO `operation_log` VALUES (274, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:56:23');
INSERT INTO `operation_log` VALUES (275, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:57:53');
INSERT INTO `operation_log` VALUES (276, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:57:55');
INSERT INTO `operation_log` VALUES (277, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:57:55');
INSERT INTO `operation_log` VALUES (278, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:57:59');
INSERT INTO `operation_log` VALUES (279, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:00');
INSERT INTO `operation_log` VALUES (280, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:00');
INSERT INTO `operation_log` VALUES (281, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:00');
INSERT INTO `operation_log` VALUES (282, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:25');
INSERT INTO `operation_log` VALUES (283, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:26');
INSERT INTO `operation_log` VALUES (284, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:26');
INSERT INTO `operation_log` VALUES (285, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:28');
INSERT INTO `operation_log` VALUES (286, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:29');
INSERT INTO `operation_log` VALUES (287, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:29');
INSERT INTO `operation_log` VALUES (288, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 20:58:29');
INSERT INTO `operation_log` VALUES (289, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:02:10');
INSERT INTO `operation_log` VALUES (290, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:02:12');
INSERT INTO `operation_log` VALUES (291, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:02:12');
INSERT INTO `operation_log` VALUES (292, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:02:15');
INSERT INTO `operation_log` VALUES (293, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:02:16');
INSERT INTO `operation_log` VALUES (294, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:02:16');
INSERT INTO `operation_log` VALUES (295, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:02:16');
INSERT INTO `operation_log` VALUES (296, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:05:46');
INSERT INTO `operation_log` VALUES (297, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:05:47');
INSERT INTO `operation_log` VALUES (298, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:05:47');
INSERT INTO `operation_log` VALUES (299, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:05:50');
INSERT INTO `operation_log` VALUES (300, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:05:53');
INSERT INTO `operation_log` VALUES (301, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:05:56');
INSERT INTO `operation_log` VALUES (302, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:06:01');
INSERT INTO `operation_log` VALUES (303, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:06:03');
INSERT INTO `operation_log` VALUES (304, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:06:04');
INSERT INTO `operation_log` VALUES (305, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:09:05');
INSERT INTO `operation_log` VALUES (306, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:09:07');
INSERT INTO `operation_log` VALUES (307, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:09:07');
INSERT INTO `operation_log` VALUES (308, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:09:09');
INSERT INTO `operation_log` VALUES (309, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:09:10');
INSERT INTO `operation_log` VALUES (310, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:09:10');
INSERT INTO `operation_log` VALUES (311, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:09:10');
INSERT INTO `operation_log` VALUES (312, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:13:12');
INSERT INTO `operation_log` VALUES (313, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:13:14');
INSERT INTO `operation_log` VALUES (314, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:13:14');
INSERT INTO `operation_log` VALUES (315, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:13:16');
INSERT INTO `operation_log` VALUES (316, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:26:48');
INSERT INTO `operation_log` VALUES (317, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:26:49');
INSERT INTO `operation_log` VALUES (318, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:26:49');
INSERT INTO `operation_log` VALUES (319, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:26:52');
INSERT INTO `operation_log` VALUES (320, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:30:14');
INSERT INTO `operation_log` VALUES (321, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:30:15');
INSERT INTO `operation_log` VALUES (322, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:30:15');
INSERT INTO `operation_log` VALUES (323, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:30:19');
INSERT INTO `operation_log` VALUES (324, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:30:30');
INSERT INTO `operation_log` VALUES (325, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:34:01');
INSERT INTO `operation_log` VALUES (326, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:34:02');
INSERT INTO `operation_log` VALUES (327, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:34:02');
INSERT INTO `operation_log` VALUES (328, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:34:04');
INSERT INTO `operation_log` VALUES (329, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:34:54');
INSERT INTO `operation_log` VALUES (330, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:35:02');
INSERT INTO `operation_log` VALUES (331, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:35:31');
INSERT INTO `operation_log` VALUES (332, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:35:32');
INSERT INTO `operation_log` VALUES (333, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:35:32');
INSERT INTO `operation_log` VALUES (334, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:35:34');
INSERT INTO `operation_log` VALUES (335, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:37:20');
INSERT INTO `operation_log` VALUES (336, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:37:21');
INSERT INTO `operation_log` VALUES (337, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:37:21');
INSERT INTO `operation_log` VALUES (338, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-14 21:37:26');
INSERT INTO `operation_log` VALUES (339, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 01:34:41');
INSERT INTO `operation_log` VALUES (340, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 01:35:36');
INSERT INTO `operation_log` VALUES (341, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 01:35:37');
INSERT INTO `operation_log` VALUES (342, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 01:36:01');
INSERT INTO `operation_log` VALUES (343, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 01:36:03');
INSERT INTO `operation_log` VALUES (344, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 01:36:12');
INSERT INTO `operation_log` VALUES (345, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:45:27');
INSERT INTO `operation_log` VALUES (346, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:27');
INSERT INTO `operation_log` VALUES (347, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:27');
INSERT INTO `operation_log` VALUES (348, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:27');
INSERT INTO `operation_log` VALUES (349, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:33');
INSERT INTO `operation_log` VALUES (350, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:34');
INSERT INTO `operation_log` VALUES (351, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:34');
INSERT INTO `operation_log` VALUES (352, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:43');
INSERT INTO `operation_log` VALUES (353, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:48');
INSERT INTO `operation_log` VALUES (354, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:46:48');
INSERT INTO `operation_log` VALUES (355, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:48:21');
INSERT INTO `operation_log` VALUES (356, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:48:22');
INSERT INTO `operation_log` VALUES (357, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:48:22');
INSERT INTO `operation_log` VALUES (358, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:48:35');
INSERT INTO `operation_log` VALUES (359, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:48:40');
INSERT INTO `operation_log` VALUES (360, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:48:40');
INSERT INTO `operation_log` VALUES (361, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:48:52');
INSERT INTO `operation_log` VALUES (362, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:59:18');
INSERT INTO `operation_log` VALUES (363, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:59:19');
INSERT INTO `operation_log` VALUES (364, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:59:19');
INSERT INTO `operation_log` VALUES (365, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:59:24');
INSERT INTO `operation_log` VALUES (366, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:59:29');
INSERT INTO `operation_log` VALUES (367, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 15:59:29');
INSERT INTO `operation_log` VALUES (368, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:01:50');
INSERT INTO `operation_log` VALUES (369, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:02:36');
INSERT INTO `operation_log` VALUES (370, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:02:36');
INSERT INTO `operation_log` VALUES (371, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:22:03');
INSERT INTO `operation_log` VALUES (372, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:22:04');
INSERT INTO `operation_log` VALUES (373, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:22:04');
INSERT INTO `operation_log` VALUES (374, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:22:10');
INSERT INTO `operation_log` VALUES (375, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:23:09');
INSERT INTO `operation_log` VALUES (376, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:23:09');
INSERT INTO `operation_log` VALUES (377, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:23:12');
INSERT INTO `operation_log` VALUES (378, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:23:14');
INSERT INTO `operation_log` VALUES (379, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:23:14');
INSERT INTO `operation_log` VALUES (380, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:23:39');
INSERT INTO `operation_log` VALUES (381, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:42:12');
INSERT INTO `operation_log` VALUES (382, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:42:13');
INSERT INTO `operation_log` VALUES (383, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:42:13');
INSERT INTO `operation_log` VALUES (384, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:44:57');
INSERT INTO `operation_log` VALUES (385, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:44:57');
INSERT INTO `operation_log` VALUES (386, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:45:28');
INSERT INTO `operation_log` VALUES (387, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/list', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:45:28');
INSERT INTO `operation_log` VALUES (388, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:49:01');
INSERT INTO `operation_log` VALUES (389, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:49:01');
INSERT INTO `operation_log` VALUES (390, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:49:11');
INSERT INTO `operation_log` VALUES (391, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:49:11');
INSERT INTO `operation_log` VALUES (392, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:52:36');
INSERT INTO `operation_log` VALUES (393, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:52:38');
INSERT INTO `operation_log` VALUES (394, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:52:38');
INSERT INTO `operation_log` VALUES (395, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:52:53');
INSERT INTO `operation_log` VALUES (396, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:52:54');
INSERT INTO `operation_log` VALUES (397, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:52:54');
INSERT INTO `operation_log` VALUES (398, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:15');
INSERT INTO `operation_log` VALUES (399, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:16');
INSERT INTO `operation_log` VALUES (400, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:17');
INSERT INTO `operation_log` VALUES (401, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:17');
INSERT INTO `operation_log` VALUES (402, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:33');
INSERT INTO `operation_log` VALUES (403, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:33');
INSERT INTO `operation_log` VALUES (404, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:42');
INSERT INTO `operation_log` VALUES (405, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:42');
INSERT INTO `operation_log` VALUES (406, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:53:42');
INSERT INTO `operation_log` VALUES (407, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:54:57');
INSERT INTO `operation_log` VALUES (408, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:54:57');
INSERT INTO `operation_log` VALUES (409, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:54:57');
INSERT INTO `operation_log` VALUES (410, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:54:59');
INSERT INTO `operation_log` VALUES (411, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:54:59');
INSERT INTO `operation_log` VALUES (412, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:54:59');
INSERT INTO `operation_log` VALUES (413, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:00');
INSERT INTO `operation_log` VALUES (414, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:00');
INSERT INTO `operation_log` VALUES (415, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:00');
INSERT INTO `operation_log` VALUES (416, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:00');
INSERT INTO `operation_log` VALUES (417, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:00');
INSERT INTO `operation_log` VALUES (418, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:00');
INSERT INTO `operation_log` VALUES (419, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:01');
INSERT INTO `operation_log` VALUES (420, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:01');
INSERT INTO `operation_log` VALUES (421, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 16:55:01');
INSERT INTO `operation_log` VALUES (422, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; zh-CN) WindowsPowerShell/5.1.26100.7019', '2026-07-15 16:57:59');
INSERT INTO `operation_log` VALUES (423, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:01:08');
INSERT INTO `operation_log` VALUES (424, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:01:09');
INSERT INTO `operation_log` VALUES (425, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:01:09');
INSERT INTO `operation_log` VALUES (426, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:01:20');
INSERT INTO `operation_log` VALUES (427, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:01:21');
INSERT INTO `operation_log` VALUES (428, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:01:21');
INSERT INTO `operation_log` VALUES (429, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:01:22');
INSERT INTO `operation_log` VALUES (430, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:11:49');
INSERT INTO `operation_log` VALUES (431, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:11:51');
INSERT INTO `operation_log` VALUES (432, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:11:51');
INSERT INTO `operation_log` VALUES (433, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:11:57');
INSERT INTO `operation_log` VALUES (434, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:11:58');
INSERT INTO `operation_log` VALUES (435, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:11:58');
INSERT INTO `operation_log` VALUES (436, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:12:03');
INSERT INTO `operation_log` VALUES (437, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:12:04');
INSERT INTO `operation_log` VALUES (438, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:12:08');
INSERT INTO `operation_log` VALUES (439, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:12:09');
INSERT INTO `operation_log` VALUES (440, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:20:51');
INSERT INTO `operation_log` VALUES (441, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:00');
INSERT INTO `operation_log` VALUES (442, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:00');
INSERT INTO `operation_log` VALUES (443, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:00');
INSERT INTO `operation_log` VALUES (444, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:04');
INSERT INTO `operation_log` VALUES (445, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:04');
INSERT INTO `operation_log` VALUES (446, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:04');
INSERT INTO `operation_log` VALUES (447, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:05');
INSERT INTO `operation_log` VALUES (448, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:05');
INSERT INTO `operation_log` VALUES (449, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:05');
INSERT INTO `operation_log` VALUES (450, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:07');
INSERT INTO `operation_log` VALUES (451, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:08');
INSERT INTO `operation_log` VALUES (452, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:11');
INSERT INTO `operation_log` VALUES (453, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:11');
INSERT INTO `operation_log` VALUES (454, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:11');
INSERT INTO `operation_log` VALUES (455, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:13');
INSERT INTO `operation_log` VALUES (456, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:13');
INSERT INTO `operation_log` VALUES (457, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:21');
INSERT INTO `operation_log` VALUES (458, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:22');
INSERT INTO `operation_log` VALUES (459, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:22');
INSERT INTO `operation_log` VALUES (460, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:23');
INSERT INTO `operation_log` VALUES (461, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:30');
INSERT INTO `operation_log` VALUES (462, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:30');
INSERT INTO `operation_log` VALUES (463, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:21:30');
INSERT INTO `operation_log` VALUES (464, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:22:37');
INSERT INTO `operation_log` VALUES (465, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:22:42');
INSERT INTO `operation_log` VALUES (466, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:22:42');
INSERT INTO `operation_log` VALUES (467, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:22:42');
INSERT INTO `operation_log` VALUES (468, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:29:56');
INSERT INTO `operation_log` VALUES (469, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:29:58');
INSERT INTO `operation_log` VALUES (470, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:29:58');
INSERT INTO `operation_log` VALUES (471, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:04');
INSERT INTO `operation_log` VALUES (472, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:04');
INSERT INTO `operation_log` VALUES (473, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:04');
INSERT INTO `operation_log` VALUES (474, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:07');
INSERT INTO `operation_log` VALUES (475, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:08');
INSERT INTO `operation_log` VALUES (476, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:09');
INSERT INTO `operation_log` VALUES (477, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:10');
INSERT INTO `operation_log` VALUES (478, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:14');
INSERT INTO `operation_log` VALUES (479, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:14');
INSERT INTO `operation_log` VALUES (480, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:14');
INSERT INTO `operation_log` VALUES (481, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:15');
INSERT INTO `operation_log` VALUES (482, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:15');
INSERT INTO `operation_log` VALUES (483, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:15');
INSERT INTO `operation_log` VALUES (484, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:16');
INSERT INTO `operation_log` VALUES (485, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:16');
INSERT INTO `operation_log` VALUES (486, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:16');
INSERT INTO `operation_log` VALUES (487, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:18');
INSERT INTO `operation_log` VALUES (488, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:19');
INSERT INTO `operation_log` VALUES (489, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:19');
INSERT INTO `operation_log` VALUES (490, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:19');
INSERT INTO `operation_log` VALUES (491, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:22');
INSERT INTO `operation_log` VALUES (492, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:30:23');
INSERT INTO `operation_log` VALUES (493, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:35:44');
INSERT INTO `operation_log` VALUES (494, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:35:46');
INSERT INTO `operation_log` VALUES (495, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:35:46');
INSERT INTO `operation_log` VALUES (496, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:35:49');
INSERT INTO `operation_log` VALUES (497, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:35:50');
INSERT INTO `operation_log` VALUES (498, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:35:50');
INSERT INTO `operation_log` VALUES (499, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:36:34');
INSERT INTO `operation_log` VALUES (500, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:36:34');
INSERT INTO `operation_log` VALUES (501, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:36:34');
INSERT INTO `operation_log` VALUES (502, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:36:36');
INSERT INTO `operation_log` VALUES (503, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:36:49');
INSERT INTO `operation_log` VALUES (504, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:36:49');
INSERT INTO `operation_log` VALUES (505, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:36:49');
INSERT INTO `operation_log` VALUES (506, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:36:53');
INSERT INTO `operation_log` VALUES (507, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:09');
INSERT INTO `operation_log` VALUES (508, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:09');
INSERT INTO `operation_log` VALUES (509, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:09');
INSERT INTO `operation_log` VALUES (510, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:14');
INSERT INTO `operation_log` VALUES (511, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:14');
INSERT INTO `operation_log` VALUES (512, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:14');
INSERT INTO `operation_log` VALUES (513, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:16');
INSERT INTO `operation_log` VALUES (514, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:16');
INSERT INTO `operation_log` VALUES (515, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:18');
INSERT INTO `operation_log` VALUES (516, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:18');
INSERT INTO `operation_log` VALUES (517, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:18');
INSERT INTO `operation_log` VALUES (518, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:37:21');
INSERT INTO `operation_log` VALUES (519, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:38:32');
INSERT INTO `operation_log` VALUES (520, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:39:20');
INSERT INTO `operation_log` VALUES (521, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:39:20');
INSERT INTO `operation_log` VALUES (522, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:39:20');
INSERT INTO `operation_log` VALUES (523, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:02');
INSERT INTO `operation_log` VALUES (524, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:04');
INSERT INTO `operation_log` VALUES (525, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:04');
INSERT INTO `operation_log` VALUES (526, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:04');
INSERT INTO `operation_log` VALUES (527, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:10');
INSERT INTO `operation_log` VALUES (528, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:11');
INSERT INTO `operation_log` VALUES (529, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:11');
INSERT INTO `operation_log` VALUES (530, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:12');
INSERT INTO `operation_log` VALUES (531, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:18');
INSERT INTO `operation_log` VALUES (532, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:18');
INSERT INTO `operation_log` VALUES (533, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:18');
INSERT INTO `operation_log` VALUES (534, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:36');
INSERT INTO `operation_log` VALUES (535, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:36');
INSERT INTO `operation_log` VALUES (536, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:36');
INSERT INTO `operation_log` VALUES (537, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:39');
INSERT INTO `operation_log` VALUES (538, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:44');
INSERT INTO `operation_log` VALUES (539, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:44');
INSERT INTO `operation_log` VALUES (540, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:44');
INSERT INTO `operation_log` VALUES (541, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:46');
INSERT INTO `operation_log` VALUES (542, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:46');
INSERT INTO `operation_log` VALUES (543, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:46');
INSERT INTO `operation_log` VALUES (544, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:52');
INSERT INTO `operation_log` VALUES (545, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:52');
INSERT INTO `operation_log` VALUES (546, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:52');
INSERT INTO `operation_log` VALUES (547, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:49:56');
INSERT INTO `operation_log` VALUES (548, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:07');
INSERT INTO `operation_log` VALUES (549, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:07');
INSERT INTO `operation_log` VALUES (550, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:07');
INSERT INTO `operation_log` VALUES (551, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:38');
INSERT INTO `operation_log` VALUES (552, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:40');
INSERT INTO `operation_log` VALUES (553, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:40');
INSERT INTO `operation_log` VALUES (554, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:43');
INSERT INTO `operation_log` VALUES (555, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:44');
INSERT INTO `operation_log` VALUES (556, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:44');
INSERT INTO `operation_log` VALUES (557, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:46');
INSERT INTO `operation_log` VALUES (558, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:50:46');
INSERT INTO `operation_log` VALUES (559, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:51:03');
INSERT INTO `operation_log` VALUES (560, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:51:03');
INSERT INTO `operation_log` VALUES (561, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:51:03');
INSERT INTO `operation_log` VALUES (562, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:51:05');
INSERT INTO `operation_log` VALUES (563, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:51:05');
INSERT INTO `operation_log` VALUES (564, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:52:02');
INSERT INTO `operation_log` VALUES (565, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:52:02');
INSERT INTO `operation_log` VALUES (566, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:52:02');
INSERT INTO `operation_log` VALUES (567, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:52:04');
INSERT INTO `operation_log` VALUES (568, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 17:52:04');
INSERT INTO `operation_log` VALUES (569, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:01:11');
INSERT INTO `operation_log` VALUES (570, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:01:12');
INSERT INTO `operation_log` VALUES (571, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:01:12');
INSERT INTO `operation_log` VALUES (572, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:03:32');
INSERT INTO `operation_log` VALUES (573, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:03:33');
INSERT INTO `operation_log` VALUES (574, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:03:33');
INSERT INTO `operation_log` VALUES (575, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:36');
INSERT INTO `operation_log` VALUES (576, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:36');
INSERT INTO `operation_log` VALUES (577, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:38');
INSERT INTO `operation_log` VALUES (578, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:38');
INSERT INTO `operation_log` VALUES (579, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:38');
INSERT INTO `operation_log` VALUES (580, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:38');
INSERT INTO `operation_log` VALUES (581, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:38');
INSERT INTO `operation_log` VALUES (582, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:41');
INSERT INTO `operation_log` VALUES (583, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:41');
INSERT INTO `operation_log` VALUES (584, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:41');
INSERT INTO `operation_log` VALUES (585, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:41');
INSERT INTO `operation_log` VALUES (586, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:53');
INSERT INTO `operation_log` VALUES (587, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:54');
INSERT INTO `operation_log` VALUES (588, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:13:54');
INSERT INTO `operation_log` VALUES (589, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:00');
INSERT INTO `operation_log` VALUES (590, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:00');
INSERT INTO `operation_log` VALUES (591, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:00');
INSERT INTO `operation_log` VALUES (592, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:09');
INSERT INTO `operation_log` VALUES (593, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:18');
INSERT INTO `operation_log` VALUES (594, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:18');
INSERT INTO `operation_log` VALUES (595, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:18');
INSERT INTO `operation_log` VALUES (596, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:31');
INSERT INTO `operation_log` VALUES (597, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:31');
INSERT INTO `operation_log` VALUES (598, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:31');
INSERT INTO `operation_log` VALUES (599, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:32');
INSERT INTO `operation_log` VALUES (600, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:14:32');
INSERT INTO `operation_log` VALUES (601, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:30:32');
INSERT INTO `operation_log` VALUES (602, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:30:34');
INSERT INTO `operation_log` VALUES (603, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:30:34');
INSERT INTO `operation_log` VALUES (604, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:31:45');
INSERT INTO `operation_log` VALUES (605, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:31:45');
INSERT INTO `operation_log` VALUES (606, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:31:45');
INSERT INTO `operation_log` VALUES (607, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:31:47');
INSERT INTO `operation_log` VALUES (608, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:31:57');
INSERT INTO `operation_log` VALUES (609, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:31:57');
INSERT INTO `operation_log` VALUES (610, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:31:57');
INSERT INTO `operation_log` VALUES (611, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:33:20');
INSERT INTO `operation_log` VALUES (612, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:33:20');
INSERT INTO `operation_log` VALUES (613, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:33:20');
INSERT INTO `operation_log` VALUES (614, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:33:21');
INSERT INTO `operation_log` VALUES (615, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 18:33:21');
INSERT INTO `operation_log` VALUES (616, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:00:27');
INSERT INTO `operation_log` VALUES (617, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:00:28');
INSERT INTO `operation_log` VALUES (618, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:00:28');
INSERT INTO `operation_log` VALUES (619, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:00:57');
INSERT INTO `operation_log` VALUES (620, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:00:57');
INSERT INTO `operation_log` VALUES (621, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:01:02');
INSERT INTO `operation_log` VALUES (622, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:01:03');
INSERT INTO `operation_log` VALUES (623, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:01:03');
INSERT INTO `operation_log` VALUES (624, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:01:06');
INSERT INTO `operation_log` VALUES (625, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:02:06');
INSERT INTO `operation_log` VALUES (626, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:02:06');
INSERT INTO `operation_log` VALUES (627, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:02:06');
INSERT INTO `operation_log` VALUES (628, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:02:08');
INSERT INTO `operation_log` VALUES (629, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:02:08');
INSERT INTO `operation_log` VALUES (630, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:02:08');
INSERT INTO `operation_log` VALUES (631, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:04:05');
INSERT INTO `operation_log` VALUES (632, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:04:07');
INSERT INTO `operation_log` VALUES (633, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:04:07');
INSERT INTO `operation_log` VALUES (634, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:04:10');
INSERT INTO `operation_log` VALUES (635, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:04:11');
INSERT INTO `operation_log` VALUES (636, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:04:11');
INSERT INTO `operation_log` VALUES (637, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:04:15');
INSERT INTO `operation_log` VALUES (638, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:04:15');
INSERT INTO `operation_log` VALUES (639, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:10');
INSERT INTO `operation_log` VALUES (640, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:10');
INSERT INTO `operation_log` VALUES (641, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:10');
INSERT INTO `operation_log` VALUES (642, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:12');
INSERT INTO `operation_log` VALUES (643, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:12');
INSERT INTO `operation_log` VALUES (644, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:12');
INSERT INTO `operation_log` VALUES (645, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:33');
INSERT INTO `operation_log` VALUES (646, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:33');
INSERT INTO `operation_log` VALUES (647, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:05:33');
INSERT INTO `operation_log` VALUES (648, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:10:05');
INSERT INTO `operation_log` VALUES (649, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:10:07');
INSERT INTO `operation_log` VALUES (650, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:10:07');
INSERT INTO `operation_log` VALUES (651, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:10:07');
INSERT INTO `operation_log` VALUES (652, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:10:25');
INSERT INTO `operation_log` VALUES (653, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:10:25');
INSERT INTO `operation_log` VALUES (654, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:12:15');
INSERT INTO `operation_log` VALUES (655, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:12:15');
INSERT INTO `operation_log` VALUES (656, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:12:25');
INSERT INTO `operation_log` VALUES (657, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:12:25');
INSERT INTO `operation_log` VALUES (658, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:16');
INSERT INTO `operation_log` VALUES (659, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:18');
INSERT INTO `operation_log` VALUES (660, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:18');
INSERT INTO `operation_log` VALUES (661, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:27');
INSERT INTO `operation_log` VALUES (662, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:28');
INSERT INTO `operation_log` VALUES (663, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:28');
INSERT INTO `operation_log` VALUES (664, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:32');
INSERT INTO `operation_log` VALUES (665, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:32');
INSERT INTO `operation_log` VALUES (666, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:57');
INSERT INTO `operation_log` VALUES (667, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:16:57');
INSERT INTO `operation_log` VALUES (668, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:21:48');
INSERT INTO `operation_log` VALUES (669, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:21:50');
INSERT INTO `operation_log` VALUES (670, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:21:50');
INSERT INTO `operation_log` VALUES (671, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:22:05');
INSERT INTO `operation_log` VALUES (672, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:23:04');
INSERT INTO `operation_log` VALUES (673, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:23:06');
INSERT INTO `operation_log` VALUES (674, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:23:06');
INSERT INTO `operation_log` VALUES (675, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:23:13');
INSERT INTO `operation_log` VALUES (676, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:23:14');
INSERT INTO `operation_log` VALUES (677, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:23:14');
INSERT INTO `operation_log` VALUES (678, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:23:17');
INSERT INTO `operation_log` VALUES (679, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:24');
INSERT INTO `operation_log` VALUES (680, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:26');
INSERT INTO `operation_log` VALUES (681, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:26');
INSERT INTO `operation_log` VALUES (682, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:30');
INSERT INTO `operation_log` VALUES (683, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:37');
INSERT INTO `operation_log` VALUES (684, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:38');
INSERT INTO `operation_log` VALUES (685, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:38');
INSERT INTO `operation_log` VALUES (686, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', NULL, '2026-07-15 19:55:40');
INSERT INTO `operation_log` VALUES (687, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:40');
INSERT INTO `operation_log` VALUES (688, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:44');
INSERT INTO `operation_log` VALUES (689, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:44');
INSERT INTO `operation_log` VALUES (690, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:44');
INSERT INTO `operation_log` VALUES (691, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, NULL, NULL, '2026-07-15 19:55:46');
INSERT INTO `operation_log` VALUES (692, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:46');
INSERT INTO `operation_log` VALUES (693, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'REPORT_EXPORT', NULL, '访问/counselor/export.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:48');
INSERT INTO `operation_log` VALUES (694, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:52');
INSERT INTO `operation_log` VALUES (695, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:52');
INSERT INTO `operation_log` VALUES (696, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:52');
INSERT INTO `operation_log` VALUES (697, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:53');
INSERT INTO `operation_log` VALUES (698, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:55:53');
INSERT INTO `operation_log` VALUES (699, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 19:56:20');
INSERT INTO `operation_log` VALUES (700, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:01:53');
INSERT INTO `operation_log` VALUES (701, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:01:54');
INSERT INTO `operation_log` VALUES (702, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:01:54');
INSERT INTO `operation_log` VALUES (703, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:00');
INSERT INTO `operation_log` VALUES (704, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:01');
INSERT INTO `operation_log` VALUES (705, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:01');
INSERT INTO `operation_log` VALUES (706, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:03');
INSERT INTO `operation_log` VALUES (707, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:04');
INSERT INTO `operation_log` VALUES (708, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:04');
INSERT INTO `operation_log` VALUES (709, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:15');
INSERT INTO `operation_log` VALUES (710, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:15');
INSERT INTO `operation_log` VALUES (711, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:26');
INSERT INTO `operation_log` VALUES (712, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:26');
INSERT INTO `operation_log` VALUES (713, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:02:26');
INSERT INTO `operation_log` VALUES (714, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:16');
INSERT INTO `operation_log` VALUES (715, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:18');
INSERT INTO `operation_log` VALUES (716, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:18');
INSERT INTO `operation_log` VALUES (717, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:21');
INSERT INTO `operation_log` VALUES (718, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:22');
INSERT INTO `operation_log` VALUES (719, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:22');
INSERT INTO `operation_log` VALUES (720, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:23');
INSERT INTO `operation_log` VALUES (721, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:23');
INSERT INTO `operation_log` VALUES (722, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:37');
INSERT INTO `operation_log` VALUES (723, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:37');
INSERT INTO `operation_log` VALUES (724, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:06:37');
INSERT INTO `operation_log` VALUES (725, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:13:19');
INSERT INTO `operation_log` VALUES (726, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:13:19');
INSERT INTO `operation_log` VALUES (727, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:17:27');
INSERT INTO `operation_log` VALUES (728, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:17:29');
INSERT INTO `operation_log` VALUES (729, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:17:29');
INSERT INTO `operation_log` VALUES (730, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:17:32');
INSERT INTO `operation_log` VALUES (731, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:17:33');
INSERT INTO `operation_log` VALUES (732, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:17:33');
INSERT INTO `operation_log` VALUES (733, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:17:36');
INSERT INTO `operation_log` VALUES (734, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:17:36');
INSERT INTO `operation_log` VALUES (735, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:18:10');
INSERT INTO `operation_log` VALUES (736, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:18:10');
INSERT INTO `operation_log` VALUES (737, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:18:10');
INSERT INTO `operation_log` VALUES (738, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:18:54');
INSERT INTO `operation_log` VALUES (739, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:18:54');
INSERT INTO `operation_log` VALUES (740, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:10');
INSERT INTO `operation_log` VALUES (741, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:11');
INSERT INTO `operation_log` VALUES (742, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:11');
INSERT INTO `operation_log` VALUES (743, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:14');
INSERT INTO `operation_log` VALUES (744, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:15');
INSERT INTO `operation_log` VALUES (745, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:15');
INSERT INTO `operation_log` VALUES (746, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:18');
INSERT INTO `operation_log` VALUES (747, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:18');
INSERT INTO `operation_log` VALUES (748, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:30');
INSERT INTO `operation_log` VALUES (749, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:30');
INSERT INTO `operation_log` VALUES (750, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:30');
INSERT INTO `operation_log` VALUES (751, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:34');
INSERT INTO `operation_log` VALUES (752, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:35');
INSERT INTO `operation_log` VALUES (753, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:35');
INSERT INTO `operation_log` VALUES (754, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:38');
INSERT INTO `operation_log` VALUES (755, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:24:38');
INSERT INTO `operation_log` VALUES (756, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:17');
INSERT INTO `operation_log` VALUES (757, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:17');
INSERT INTO `operation_log` VALUES (758, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:18');
INSERT INTO `operation_log` VALUES (759, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:18');
INSERT INTO `operation_log` VALUES (760, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:19');
INSERT INTO `operation_log` VALUES (761, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:19');
INSERT INTO `operation_log` VALUES (762, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:19');
INSERT INTO `operation_log` VALUES (763, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:19');
INSERT INTO `operation_log` VALUES (764, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:42');
INSERT INTO `operation_log` VALUES (765, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:44');
INSERT INTO `operation_log` VALUES (766, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:44');
INSERT INTO `operation_log` VALUES (767, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:49');
INSERT INTO `operation_log` VALUES (768, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:49');
INSERT INTO `operation_log` VALUES (769, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:49');
INSERT INTO `operation_log` VALUES (770, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:51');
INSERT INTO `operation_log` VALUES (771, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:26:51');
INSERT INTO `operation_log` VALUES (772, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:27:06');
INSERT INTO `operation_log` VALUES (773, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:27:06');
INSERT INTO `operation_log` VALUES (774, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:27:06');
INSERT INTO `operation_log` VALUES (775, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:33:54');
INSERT INTO `operation_log` VALUES (776, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:33:55');
INSERT INTO `operation_log` VALUES (777, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:33:55');
INSERT INTO `operation_log` VALUES (778, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:33:57');
INSERT INTO `operation_log` VALUES (779, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:33:58');
INSERT INTO `operation_log` VALUES (780, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:33:58');
INSERT INTO `operation_log` VALUES (781, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:33:59');
INSERT INTO `operation_log` VALUES (782, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:33:59');
INSERT INTO `operation_log` VALUES (783, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:06');
INSERT INTO `operation_log` VALUES (784, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:06');
INSERT INTO `operation_log` VALUES (785, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:06');
INSERT INTO `operation_log` VALUES (786, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:11');
INSERT INTO `operation_log` VALUES (787, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:11');
INSERT INTO `operation_log` VALUES (788, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:11');
INSERT INTO `operation_log` VALUES (789, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:11');
INSERT INTO `operation_log` VALUES (790, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:11');
INSERT INTO `operation_log` VALUES (791, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:13');
INSERT INTO `operation_log` VALUES (792, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:34:13');
INSERT INTO `operation_log` VALUES (793, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:36:02');
INSERT INTO `operation_log` VALUES (794, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:36:03');
INSERT INTO `operation_log` VALUES (795, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:36:03');
INSERT INTO `operation_log` VALUES (796, 20, '陈老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:39:25');
INSERT INTO `operation_log` VALUES (797, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:39:26');
INSERT INTO `operation_log` VALUES (798, 20, '陈老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:39:26');
INSERT INTO `operation_log` VALUES (799, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:18');
INSERT INTO `operation_log` VALUES (800, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:20');
INSERT INTO `operation_log` VALUES (801, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:20');
INSERT INTO `operation_log` VALUES (802, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:23');
INSERT INTO `operation_log` VALUES (803, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:24');
INSERT INTO `operation_log` VALUES (804, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:24');
INSERT INTO `operation_log` VALUES (805, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:25');
INSERT INTO `operation_log` VALUES (806, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:25');
INSERT INTO `operation_log` VALUES (807, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:38');
INSERT INTO `operation_log` VALUES (808, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:38');
INSERT INTO `operation_log` VALUES (809, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:39');
INSERT INTO `operation_log` VALUES (810, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:39');
INSERT INTO `operation_log` VALUES (811, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:39');
INSERT INTO `operation_log` VALUES (812, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:40');
INSERT INTO `operation_log` VALUES (813, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:44:40');
INSERT INTO `operation_log` VALUES (814, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:45:58');
INSERT INTO `operation_log` VALUES (815, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:45:58');
INSERT INTO `operation_log` VALUES (816, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:00');
INSERT INTO `operation_log` VALUES (817, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:00');
INSERT INTO `operation_log` VALUES (818, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:02');
INSERT INTO `operation_log` VALUES (819, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:02');
INSERT INTO `operation_log` VALUES (820, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:30');
INSERT INTO `operation_log` VALUES (821, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:32');
INSERT INTO `operation_log` VALUES (822, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:32');
INSERT INTO `operation_log` VALUES (823, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:44');
INSERT INTO `operation_log` VALUES (824, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:46:44');
INSERT INTO `operation_log` VALUES (825, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:48:06');
INSERT INTO `operation_log` VALUES (826, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:48:07');
INSERT INTO `operation_log` VALUES (827, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:48:07');
INSERT INTO `operation_log` VALUES (828, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:50:11');
INSERT INTO `operation_log` VALUES (829, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:50:12');
INSERT INTO `operation_log` VALUES (830, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:50:12');
INSERT INTO `operation_log` VALUES (831, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:50:20');
INSERT INTO `operation_log` VALUES (832, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:50:20');
INSERT INTO `operation_log` VALUES (833, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:50:52');
INSERT INTO `operation_log` VALUES (834, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:50:52');
INSERT INTO `operation_log` VALUES (835, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:50:52');
INSERT INTO `operation_log` VALUES (836, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:52:48');
INSERT INTO `operation_log` VALUES (837, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:52:50');
INSERT INTO `operation_log` VALUES (838, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:52:50');
INSERT INTO `operation_log` VALUES (839, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:52:54');
INSERT INTO `operation_log` VALUES (840, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:52:55');
INSERT INTO `operation_log` VALUES (841, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:52:55');
INSERT INTO `operation_log` VALUES (842, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:53:05');
INSERT INTO `operation_log` VALUES (843, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:53:05');
INSERT INTO `operation_log` VALUES (844, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:53:13');
INSERT INTO `operation_log` VALUES (845, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:54:26');
INSERT INTO `operation_log` VALUES (846, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 20:57:02');
INSERT INTO `operation_log` VALUES (847, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:03:40');
INSERT INTO `operation_log` VALUES (848, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:04:27');
INSERT INTO `operation_log` VALUES (849, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:04:28');
INSERT INTO `operation_log` VALUES (850, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:04:28');
INSERT INTO `operation_log` VALUES (851, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:07:34');
INSERT INTO `operation_log` VALUES (852, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:09:46');
INSERT INTO `operation_log` VALUES (853, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:10:04');
INSERT INTO `operation_log` VALUES (854, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:10:05');
INSERT INTO `operation_log` VALUES (855, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:10:05');
INSERT INTO `operation_log` VALUES (856, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:10:17');
INSERT INTO `operation_log` VALUES (857, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:11:24');
INSERT INTO `operation_log` VALUES (858, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:11:24');
INSERT INTO `operation_log` VALUES (859, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:11:24');
INSERT INTO `operation_log` VALUES (860, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:11:55');
INSERT INTO `operation_log` VALUES (861, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:12:16');
INSERT INTO `operation_log` VALUES (862, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:12:17');
INSERT INTO `operation_log` VALUES (863, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:12:17');
INSERT INTO `operation_log` VALUES (864, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:14:15');
INSERT INTO `operation_log` VALUES (865, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:15:10');
INSERT INTO `operation_log` VALUES (866, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:15:10');
INSERT INTO `operation_log` VALUES (867, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:15:10');
INSERT INTO `operation_log` VALUES (868, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:15:36');
INSERT INTO `operation_log` VALUES (869, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:18:44');
INSERT INTO `operation_log` VALUES (870, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:21:57');
INSERT INTO `operation_log` VALUES (871, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:25:15');
INSERT INTO `operation_log` VALUES (872, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:30:22');
INSERT INTO `operation_log` VALUES (873, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:30:24');
INSERT INTO `operation_log` VALUES (874, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:33:32');
INSERT INTO `operation_log` VALUES (875, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:33:58');
INSERT INTO `operation_log` VALUES (876, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:33:58');
INSERT INTO `operation_log` VALUES (877, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:33:58');
INSERT INTO `operation_log` VALUES (878, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:39:20');
INSERT INTO `operation_log` VALUES (879, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:42:51');
INSERT INTO `operation_log` VALUES (880, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:45:31');
INSERT INTO `operation_log` VALUES (881, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:45:32');
INSERT INTO `operation_log` VALUES (882, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:45:55');
INSERT INTO `operation_log` VALUES (883, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:45:56');
INSERT INTO `operation_log` VALUES (884, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:45:56');
INSERT INTO `operation_log` VALUES (885, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:50:04');
INSERT INTO `operation_log` VALUES (886, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:55:08');
INSERT INTO `operation_log` VALUES (887, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 21:57:56');
INSERT INTO `operation_log` VALUES (888, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 22:02:11');
INSERT INTO `operation_log` VALUES (889, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 22:02:12');
INSERT INTO `operation_log` VALUES (890, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 22:06:08');
INSERT INTO `operation_log` VALUES (891, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 22:08:30');
INSERT INTO `operation_log` VALUES (892, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 22:12:29');
INSERT INTO `operation_log` VALUES (893, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 22:15:36');
INSERT INTO `operation_log` VALUES (894, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-15 22:15:38');
INSERT INTO `operation_log` VALUES (895, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:14:28');
INSERT INTO `operation_log` VALUES (896, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:16:04');
INSERT INTO `operation_log` VALUES (897, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:16:04');
INSERT INTO `operation_log` VALUES (898, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:16:04');
INSERT INTO `operation_log` VALUES (899, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:16:46');
INSERT INTO `operation_log` VALUES (900, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:16:47');
INSERT INTO `operation_log` VALUES (901, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:16:47');
INSERT INTO `operation_log` VALUES (902, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:16:49');
INSERT INTO `operation_log` VALUES (903, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:17:11');
INSERT INTO `operation_log` VALUES (904, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:17:11');
INSERT INTO `operation_log` VALUES (905, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:17:11');
INSERT INTO `operation_log` VALUES (906, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:17:20');
INSERT INTO `operation_log` VALUES (907, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:17:20');
INSERT INTO `operation_log` VALUES (908, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:17:30');
INSERT INTO `operation_log` VALUES (909, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:17:57');
INSERT INTO `operation_log` VALUES (910, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:17:57');
INSERT INTO `operation_log` VALUES (911, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, NULL, NULL, '2026-07-16 01:17:57');
INSERT INTO `operation_log` VALUES (912, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:34:42');
INSERT INTO `operation_log` VALUES (913, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:34:42');
INSERT INTO `operation_log` VALUES (914, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:34:42');
INSERT INTO `operation_log` VALUES (915, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:34:43');
INSERT INTO `operation_log` VALUES (916, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, NULL, NULL, '2026-07-16 01:34:43');
INSERT INTO `operation_log` VALUES (917, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:28');
INSERT INTO `operation_log` VALUES (918, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:28');
INSERT INTO `operation_log` VALUES (919, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:30');
INSERT INTO `operation_log` VALUES (920, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:30');
INSERT INTO `operation_log` VALUES (921, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:31');
INSERT INTO `operation_log` VALUES (922, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:31');
INSERT INTO `operation_log` VALUES (923, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:31');
INSERT INTO `operation_log` VALUES (924, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:31');
INSERT INTO `operation_log` VALUES (925, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:55');
INSERT INTO `operation_log` VALUES (926, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:56');
INSERT INTO `operation_log` VALUES (927, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:56');
INSERT INTO `operation_log` VALUES (928, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:37:56');
INSERT INTO `operation_log` VALUES (929, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:40:39');
INSERT INTO `operation_log` VALUES (930, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:40:39');
INSERT INTO `operation_log` VALUES (931, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/counselor/alerts.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:40:42');
INSERT INTO `operation_log` VALUES (932, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:40:42');
INSERT INTO `operation_log` VALUES (933, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:40:42');
INSERT INTO `operation_log` VALUES (934, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:40:45');
INSERT INTO `operation_log` VALUES (935, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:40:57');
INSERT INTO `operation_log` VALUES (936, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:41:07');
INSERT INTO `operation_log` VALUES (937, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:41:07');
INSERT INTO `operation_log` VALUES (938, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/detail', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:41:09');
INSERT INTO `operation_log` VALUES (939, 1, '系统管理员', 'ADMIN', 'LOGOUT', 'OTHER', NULL, '用户退出系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:41:41');
INSERT INTO `operation_log` VALUES (940, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 01:41:48');
INSERT INTO `operation_log` VALUES (941, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 02:42:59');
INSERT INTO `operation_log` VALUES (942, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 02:43:37');
INSERT INTO `operation_log` VALUES (943, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 02:47:08');
INSERT INTO `operation_log` VALUES (944, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 02:48:58');
INSERT INTO `operation_log` VALUES (945, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 02:54:43');
INSERT INTO `operation_log` VALUES (946, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:00:10');
INSERT INTO `operation_log` VALUES (947, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:05:21');
INSERT INTO `operation_log` VALUES (948, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:12:38');
INSERT INTO `operation_log` VALUES (949, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:12:40');
INSERT INTO `operation_log` VALUES (950, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:16:58');
INSERT INTO `operation_log` VALUES (951, 18, '吴九', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:20:44');
INSERT INTO `operation_log` VALUES (952, 18, '吴九', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:23:42');
INSERT INTO `operation_log` VALUES (953, 18, '吴九', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:27:14');
INSERT INTO `operation_log` VALUES (954, 18, '吴九', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:31:13');
INSERT INTO `operation_log` VALUES (955, 14, '王五', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:40:54');
INSERT INTO `operation_log` VALUES (956, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 03:41:35');
INSERT INTO `operation_log` VALUES (957, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:06:45');
INSERT INTO `operation_log` VALUES (958, 21, '林老师', 'COUNSELOR', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:08:32');
INSERT INTO `operation_log` VALUES (959, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/counselor/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:08:33');
INSERT INTO `operation_log` VALUES (960, 21, '林老师', 'COUNSELOR', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/statistics', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:08:33');
INSERT INTO `operation_log` VALUES (961, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:08:47');
INSERT INTO `operation_log` VALUES (962, 17, '周八', 'STUDENT', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:13:33');
INSERT INTO `operation_log` VALUES (963, 1, '系统管理员', 'ADMIN', 'LOGIN', 'OTHER', NULL, '用户登录系统', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:23:16');
INSERT INTO `operation_log` VALUES (964, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/admin/alert-manage.jsp', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:23:53');
INSERT INTO `operation_log` VALUES (965, 1, '系统管理员', 'ADMIN', 'VIEW_SENSITIVE_DATA', 'ALERT_RECORD', NULL, '访问/alert/list', NULL, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-16 10:23:53');

-- ----------------------------
-- Table structure for scale
-- ----------------------------
DROP TABLE IF EXISTS `scale`;
CREATE TABLE `scale`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '量表ID',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '量表名称',
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '量表编码(SCL90/SDS等)',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '量表说明',
  `instruction` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '答题指导语',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '量表分类',
  `total_questions` int NOT NULL DEFAULT 0 COMMENT '题目总数',
  `time_limit` int NULL DEFAULT NULL COMMENT '建议完成时长(分钟)',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态:0停用,1启用',
  `creator_id` int NULL DEFAULT NULL COMMENT '创建者ID(管理员)',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `code`(`code` ASC) USING BTREE,
  INDEX `idx_code`(`code` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '测评量表表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of scale
-- ----------------------------
INSERT INTO `scale` VALUES (1, '症状自评量表-SCL90', 'SCL90', '该量表用于评估心理健康状况，包含90个题目，涵盖躯体化、强迫症状、人际关系敏感、抑郁、焦虑、敌对、恐怖、偏执、精神病性等9个因子。', '以下表格中列出了有些人可能有的症状或问题，请仔细阅读每一条。然后根据最近一星期以内（或过去）下列问题影响你或使你感到苦恼的程度，在相应方格内打一个√。请不要漏掉问题。', '心理健康筛查', 90, 30, 1, NULL, '2026-07-10 17:30:29', '2026-07-10 17:30:29');
INSERT INTO `scale` VALUES (2, '抑郁自评量表-SDS', 'SDS', '用于衡量抑郁状态的轻重程度及其在治疗中的变化。', '请根据您近一周的感觉，在最符合您情况的数字上画圈。', '情绪测评', 20, 10, 1, NULL, '2026-07-10 17:30:29', '2026-07-10 17:30:29');
INSERT INTO `scale` VALUES (3, '焦虑自评量表-SAS', 'SAS', '用于评定焦虑患者的主观感受。', '请根据您近一周的感觉，在最符合您情况的数字上画圈。', '情绪测评', 20, 10, 1, NULL, '2026-07-10 17:30:29', '2026-07-10 17:30:29');
INSERT INTO `scale` VALUES (4, '病人健康问卷抑郁量表(PHQ-9)', 'PHQ9', 'PHQ-9是一个简便、有效的抑郁障碍自评工具，包含9个条目，用于筛查和评估抑郁症状的严重程度。', '在过去两周中，您有多少时候被以下问题困扰？评分标准：0=完全不会，1=有几天，2=一半以上的日子，3=几乎每天。', '抑郁', 9, 5, 1, NULL, '2026-07-15 16:16:19', '2026-07-15 16:16:19');
INSERT INTO `scale` VALUES (5, '广泛性焦虑障碍量表(GAD-7)', 'GAD7', 'GAD-7用于广泛性焦虑的筛查和严重程度评估，包含7个条目。', '在过去两周中，您有多少时候被以下问题困扰？评分标准：0=完全不会，1=有几天，2=一半以上的日子，3=几乎每天。', '焦虑', 7, 5, 1, NULL, '2026-07-15 16:16:19', '2026-07-15 16:16:19');

-- ----------------------------
-- Table structure for scale_favorite
-- ----------------------------
DROP TABLE IF EXISTS `scale_favorite`;
CREATE TABLE `scale_favorite`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '学生用户ID',
  `scale_id` int NOT NULL COMMENT '量表ID',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_scale`(`user_id` ASC, `scale_id` ASC) USING BTREE,
  INDEX `scale_id`(`scale_id` ASC) USING BTREE,
  CONSTRAINT `scale_favorite_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `scale_favorite_ibfk_2` FOREIGN KEY (`scale_id`) REFERENCES `scale` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '量表收藏表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of scale_favorite
-- ----------------------------
INSERT INTO `scale_favorite` VALUES (1, 12, 1, '2026-07-15 16:20:10');
INSERT INTO `scale_favorite` VALUES (2, 12, 2, '2026-07-15 16:20:10');
INSERT INTO `scale_favorite` VALUES (3, 13, 1, '2026-07-15 16:20:10');
INSERT INTO `scale_favorite` VALUES (4, 13, 4, '2026-07-15 16:20:10');
INSERT INTO `scale_favorite` VALUES (5, 14, 1, '2026-07-15 16:20:10');
INSERT INTO `scale_favorite` VALUES (6, 15, 3, '2026-07-15 16:20:10');
INSERT INTO `scale_favorite` VALUES (7, 18, 1, '2026-07-15 16:20:10');

-- ----------------------------
-- Table structure for scale_question
-- ----------------------------
DROP TABLE IF EXISTS `scale_question`;
CREATE TABLE `scale_question`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '题目ID',
  `scale_id` int NOT NULL COMMENT '所属量表ID',
  `question_no` int NOT NULL COMMENT '题号',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '题目内容',
  `dimension` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '维度(如SCL90的躯体化、强迫等)',
  `option_type` enum('LIKERT_5','YES_NO','LIKERT_4') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'LIKERT_5' COMMENT '选项类型',
  `score_rule` json NULL COMMENT '评分规则',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_scale_id`(`scale_id` ASC) USING BTREE,
  CONSTRAINT `scale_question_ibfk_1` FOREIGN KEY (`scale_id`) REFERENCES `scale` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 147 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '测评题目表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of scale_question
-- ----------------------------
INSERT INTO `scale_question` VALUES (1, 1, 1, '头痛', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (2, 1, 2, '神经过敏，心中不踏实', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (3, 1, 3, '头脑中有不必要的想法或字句盘旋', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (4, 1, 4, '头昏或昏倒', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (5, 1, 5, '对异性的兴趣减退', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (6, 1, 6, '对旁人责备求全', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (7, 1, 7, '感到别人能控制你的思想', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (8, 1, 8, '责怪别人制造麻烦', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (9, 1, 9, '忘性大', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (10, 1, 10, '担心自己的衣饰整齐及仪态的端正', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (11, 1, 11, '容易烦恼和激动', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (12, 1, 12, '胸痛', '躯体化', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (13, 1, 13, '害怕空旷的场所或街道', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (14, 1, 14, '感到自己的精力下降，活动减慢', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (15, 1, 15, '想结束自己的生命', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (16, 1, 16, '听到旁人听不到的声音', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (17, 1, 17, '发抖', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (18, 1, 18, '感到大多数人都不可信任', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (19, 1, 19, '胃口不好', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (20, 1, 20, '容易哭泣', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (21, 1, 21, '同异性相处时感到害羞不自在', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (22, 1, 22, '感到受骗，中了圈套或有人想抓您', '强迫症状', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (23, 1, 23, '无缘无故地突然感到害怕', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (24, 1, 24, '自己不能控制地大发脾气', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (25, 1, 25, '怕单独出门', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (26, 1, 26, '经常责怪自己', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (27, 1, 27, '腰痛', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (28, 1, 28, '感到难以完成任务', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (29, 1, 29, '感到孤独', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (30, 1, 30, '感到苦闷', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (31, 1, 31, '过分担忧', '人际关系敏感', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (32, 1, 32, '对事物不感兴趣', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (33, 1, 33, '感到害怕', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (34, 1, 34, '我的感情容易受到伤害', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (35, 1, 35, '旁人能知道您的私下想法', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (36, 1, 36, '感到别人不理解您、不同情您', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (37, 1, 37, '感到人们对你不友好，不喜欢您', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (38, 1, 38, '做事必须做得很慢以保证做得正确', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (39, 1, 39, '心跳得很厉害', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (40, 1, 40, '恶心或胃部不舒服', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (41, 1, 41, '感到比不上他人', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (42, 1, 42, '肌肉酸痛', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (43, 1, 43, '感到有人在监视您、谈论您', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (44, 1, 44, '难以入睡', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (45, 1, 45, '做事必须反复检查', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (46, 1, 46, '难以做出决定', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (47, 1, 47, '怕乘电车、公共汽车、地铁或火车', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (48, 1, 48, '呼吸有困难', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (49, 1, 49, '一阵阵发冷或发热', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (50, 1, 50, '因为感到害怕而避开某些东西、场合或活动', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (51, 1, 51, '脑子变空了', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (52, 1, 52, '身体发麻或刺痛', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (53, 1, 53, '喉咙有梗塞感', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (54, 1, 54, '感到没有前途没有希望', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (55, 1, 55, '不能集中注意力', '敌对', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (56, 1, 56, '感到身体的某一部分软弱无力', '敌对', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (57, 1, 57, '感到紧张或容易紧张', '敌对', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (58, 1, 58, '感到手或脚发重', '敌对', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (59, 1, 59, '想到死亡的事', '敌对', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (60, 1, 60, '吃得太多', '敌对', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (61, 1, 61, '当别人看着您或谈论您时感到不自在', '恐怖', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (62, 1, 62, '有一些不属于您自己的想法', '恐怖', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (63, 1, 63, '有想打人或伤害他人的冲动', '恐怖', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (64, 1, 64, '醒得太早', '恐怖', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (65, 1, 65, '必须反复洗手、点数目或触摸某些东西', '恐怖', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (66, 1, 66, '睡得不稳不深', '恐怖', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (67, 1, 67, '有想摔坏或破坏东西的冲动', '恐怖', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (68, 1, 68, '有一些别人没有的想法或念头', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (69, 1, 69, '感到对别人神经过敏', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (70, 1, 70, '在商店或电影院等人多的地方感到不自在', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (71, 1, 71, '感到任何事情都很困难', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (72, 1, 72, '一阵阵恐惧或惊恐', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (73, 1, 73, '感到在公共场合吃东西很不舒服', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (74, 1, 74, '经常与人争论', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (75, 1, 75, '单独一人时神经很紧张', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (76, 1, 76, '别人对您的成绩没有作出恰当的评价', '偏执', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (77, 1, 77, '即使和别人在一起也感到孤单', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (78, 1, 78, '感到坐立不安心神不宁', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (79, 1, 79, '感到自己没有什么价值', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (80, 1, 80, '感到熟悉的东西变成陌生或不像是真的', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (81, 1, 81, '大叫或摔东西', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (82, 1, 82, '害怕会在公共场合昏倒', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (83, 1, 83, '感到别人想占您的便宜', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (84, 1, 84, '为一些有关\"性\"的想法而很苦恼', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (85, 1, 85, '您认为应该因为自己的过错而受到惩罚', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (86, 1, 86, '感到要赶快把事情做完', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (87, 1, 87, '感到自己的身体有严重问题', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (88, 1, 88, '从未感到和其他人很亲近', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (89, 1, 89, '感到自己有罪', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (90, 1, 90, '感到自己的脑子有毛病', '精神病性', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (91, 2, 1, '我觉得闷闷不乐，情绪低沉', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (92, 2, 2, '我觉得一天之中早晨最好', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (93, 2, 3, '我一阵阵哭出来或想哭', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (94, 2, 4, '我晚上睡眠不好', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (95, 2, 5, '我吃得跟平常一样多', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (96, 2, 6, '我与异性密切接触时和以往一样感到愉快', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (97, 2, 7, '我发觉我的体重在下降', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (98, 2, 8, '我有便秘的苦恼', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (99, 2, 9, '我心跳比平时快', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (100, 2, 10, '我无缘无故地感到疲乏', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (101, 2, 11, '我的头脑跟平常一样清楚', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (102, 2, 12, '我觉得经常做的事情并没困难', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (103, 2, 13, '我觉得不安而平静不下来', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (104, 2, 14, '我对将来抱有希望', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (105, 2, 15, '我比平常容易生气激动', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (106, 2, 16, '我觉得作出决定是容易的', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (107, 2, 17, '我觉得自己是个有用的人，有人需要我', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (108, 2, 18, '我的生活过得很有意思', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (109, 2, 19, '我认为如果我死了别人会生活得更好些', '抑郁', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (110, 2, 20, '平常感兴趣的事我仍然照样感兴趣', '抑郁', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (111, 3, 1, '我觉得比平时容易紧张和着急', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (112, 3, 2, '我无缘无故地感到害怕', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (113, 3, 3, '我容易心里烦乱或觉得惊恐', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (114, 3, 4, '我觉得我可能将要发疯', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (115, 3, 5, '我觉得一切都很好，也不会发生什么不幸', '焦虑', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (116, 3, 6, '我手脚发抖打颤', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (117, 3, 7, '我因为头痛、颈痛和背痛而苦恼', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (118, 3, 8, '我感觉容易衰弱和疲乏', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (119, 3, 9, '我觉得心平气和，并且容易安静坐着', '焦虑', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (120, 3, 10, '我觉得心跳得快', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (121, 3, 11, '我因为一阵阵头晕而苦恼', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (122, 3, 12, '我有晕倒发作，或觉得要晕倒似的', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (123, 3, 13, '我呼气吸气都感到很容易', '焦虑', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (124, 3, 14, '我的手脚麻木和刺痛', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (125, 3, 15, '我因为胃痛和消化不良而苦恼', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (126, 3, 16, '我常常要小便', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (127, 3, 17, '我的手脚常常是干燥温暖的', '焦虑', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (128, 3, 18, '我脸红发热', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (129, 3, 19, '我容易入睡并且一夜睡得很好', '焦虑', 'LIKERT_5', '{\"reverse\": true}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (130, 3, 20, '我做恶梦', '焦虑', 'LIKERT_5', '{\"reverse\": false}', '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (131, 4, 1, '做事时提不起劲或没有兴趣', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (132, 4, 2, '感到心情低落、沮丧或绝望', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (133, 4, 3, '入睡困难、睡不安稳或睡得过多', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (134, 4, 4, '感觉疲倦或没有活力', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (135, 4, 5, '食欲不振或吃太多', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (136, 4, 6, '觉得自己很糟，或觉得自己很失败，或让自己或家人失望', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (137, 4, 7, '对事物专注有困难，例如阅读报纸或看电视时', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (138, 4, 8, '动作或说话速度缓慢到别人已经觉察，或正好相反，烦躁或坐立不安', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (139, 4, 9, '有不如死掉或用某种方式伤害自己的念头', '抑郁', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (140, 5, 1, '感觉紧张、焦虑或急切', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (141, 5, 2, '不能够停止或控制担忧', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (142, 5, 3, '对各种各样的事情担忧过多', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (143, 5, 4, '很难放松下来', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (144, 5, 5, '由于不安而无法静坐', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (145, 5, 6, '变得容易烦恼或急躁', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');
INSERT INTO `scale_question` VALUES (146, 5, 7, '感到似乎将有可怕的事情发生而害怕', '焦虑', 'LIKERT_5', NULL, '2026-07-15 16:17:44');

-- ----------------------------
-- Table structure for schedule
-- ----------------------------
DROP TABLE IF EXISTS `schedule`;
CREATE TABLE `schedule`  (
  `id` int NOT NULL,
  `counselor_id` int NOT NULL COMMENT '咨询师用户ID',
  `week_day` tinyint NOT NULL COMMENT '星期(1=周一~7=周日)',
  `start_time` time NOT NULL COMMENT '时段开始时间',
  `end_time` time NOT NULL COMMENT '时段结束时间',
  `max_num` tinyint NOT NULL COMMENT '单时段最大预约人数',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '启用状态：1启用 0停用',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '咨询师可预约时段表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of schedule
-- ----------------------------
INSERT INTO `schedule` VALUES (1, 9, 1, '09:00:00', '10:00:00', 5, 1);
INSERT INTO `schedule` VALUES (2, 10, 1, '14:00:00', '15:00:00', 5, 1);
INSERT INTO `schedule` VALUES (3, 9, 2, '10:00:00', '11:00:00', 5, 1);
INSERT INTO `schedule` VALUES (4, 10, 2, '15:00:00', '16:00:00', 5, 1);
INSERT INTO `schedule` VALUES (5, 9, 3, '09:00:00', '10:00:00', 5, 1);
INSERT INTO `schedule` VALUES (6, 10, 3, '14:00:00', '15:00:00', 5, 1);
INSERT INTO `schedule` VALUES (7, 9, 4, '10:00:00', '11:00:00', 5, 1);
INSERT INTO `schedule` VALUES (8, 10, 4, '15:00:00', '16:00:00', 5, 1);
INSERT INTO `schedule` VALUES (9, 9, 5, '09:00:00', '10:00:00', 5, 1);
INSERT INTO `schedule` VALUES (10, 10, 5, '14:00:00', '15:00:00', 5, 1);
INSERT INTO `schedule` VALUES (11, 9, 6, '10:00:00', '11:00:00', 5, 1);
INSERT INTO `schedule` VALUES (12, 10, 6, '15:00:00', '16:00:00', 5, 1);

-- ----------------------------
-- Table structure for sys_user
-- ----------------------------
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '用户名',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码(MD5加密)',
  `salt` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '密码盐值',
  `real_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '真实姓名',
  `role` enum('STUDENT','COUNSELOR','ADMIN') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'STUDENT' COMMENT '角色:学生/咨询师-辅导员/管理员',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '绑定邮箱',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '手机号',
  `student_id` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '学号(仅学生角色)',
  `department` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '院系',
  `grade` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '年级',
  `class_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '班级',
  `gender` enum('MALE','FEMALE') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '性别',
  `avatar_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '头像URL',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态:0禁用,1正常',
  `last_login_time` datetime NULL DEFAULT NULL COMMENT '最后登录时间',
  `last_login_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '最后登录IP',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `username`(`username` ASC) USING BTREE,
  INDEX `idx_role`(`role` ASC) USING BTREE,
  INDEX `idx_student_id`(`student_id` ASC) USING BTREE,
  INDEX `idx_department`(`department` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 97 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user
-- ----------------------------
INSERT INTO `sys_user` VALUES (1, 'admin', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '系统管理员', 'ADMIN', 'admin@school.edu.cn', '13800000001', NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-07-16 10:23:16', '0:0:0:0:0:0:0:1', '2026-07-10 17:30:29', '2026-07-16 10:23:16');
INSERT INTO `sys_user` VALUES (2, 'counselor01', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '王心理师', 'COUNSELOR', 'wangxl@school.edu.cn', '13800000002', NULL, '心理咨询中心', NULL, NULL, NULL, NULL, 1, '2026-07-14 02:12:04', '0:0:0:0:0:0:0:1', '2026-07-10 17:30:29', '2026-07-14 02:12:04');
INSERT INTO `sys_user` VALUES (3, 'counselor02', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '李辅导员', 'COUNSELOR', 'lifdy@school.edu.cn', '13800000003', NULL, '计算机学院', NULL, NULL, NULL, NULL, 1, '2026-07-14 02:12:20', '0:0:0:0:0:0:0:1', '2026-07-10 17:30:29', '2026-07-14 02:12:20');
INSERT INTO `sys_user` VALUES (4, 'student01', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '张三', 'STUDENT', 'zhangsan@student.edu.cn', '13800100001', '2024001', '计算机学院', '2024级', '计科2401班', 'MALE', NULL, 1, NULL, NULL, '2026-07-10 17:30:29', '2026-07-14 00:32:30');
INSERT INTO `sys_user` VALUES (5, 'student02', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '李四', 'STUDENT', 'lisi@student.edu.cn', '13800100002', '2024002', '计算机学院', '2024级', '计科2401班', 'FEMALE', NULL, 1, NULL, NULL, '2026-07-10 17:30:29', '2026-07-13 19:01:16');
INSERT INTO `sys_user` VALUES (6, 'student03', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '王五', 'STUDENT', 'wangwu@student.edu.cn', '13800100003', '2024003', '数学学院', '2024级', '数统2401班', 'MALE', NULL, 1, NULL, NULL, '2026-07-10 17:30:29', '2026-07-13 19:01:17');
INSERT INTO `sys_user` VALUES (7, 'lise', '0c909a141f1f2c0a1cb602b0b2d7d050', '', 'cq', 'STUDENT', '20242501328@stu.xju.deu.cn', NULL, '20242501328', '软件', '24', '21', 'MALE', NULL, 1, '2026-07-13 19:27:34', '0:0:0:0:0:0:0:1', '2026-07-10 18:24:22', '2026-07-13 19:27:34');
INSERT INTO `sys_user` VALUES (9, 'student', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '张三', 'STUDENT', NULL, NULL, '2024001', '计算机学院', '2024级', NULL, 'MALE', NULL, 1, '2026-07-13 19:26:49', '0:0:0:0:0:0:0:1', '2026-07-10 18:25:35', '2026-07-13 19:26:49');
INSERT INTO `sys_user` VALUES (10, 'counselor', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '李老师', 'COUNSELOR', 'counselor@school.edu.cn', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-07-10 18:25:35', '2026-07-10 18:25:35');
INSERT INTO `sys_user` VALUES (11, 'lisea', '0c909a141f1f2c0a1cb602b0b2d7d050', '', 'cq', 'STUDENT', '20242501328@stu.xju.deu.cn', NULL, '20242501328', '软件', '24', '21', 'MALE', NULL, 1, '2026-07-13 16:25:49', '0:0:0:0:0:0:0:1', '2026-07-10 18:31:26', '2026-07-13 16:25:49');
INSERT INTO `sys_user` VALUES (12, 'student1', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '张三', 'STUDENT', 'zhangsan@edu.cn', '13800001001', '2021001', '计算机学院', '2021级', '计科2101', 'MALE', NULL, 1, '2026-07-13 19:27:00', '0:0:0:0:0:0:0:1', '2026-06-12 19:23:45', '2026-07-13 19:27:00');
INSERT INTO `sys_user` VALUES (13, 'student2', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '李四', 'STUDENT', 'lisi@edu.cn', '13800001002', '2021002', '计算机学院', '2021级', '计科2102', 'FEMALE', NULL, 1, NULL, NULL, '2026-06-14 19:23:45', '2026-07-14 00:32:30');
INSERT INTO `sys_user` VALUES (14, 'student3', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '王五', 'STUDENT', 'wangwu@edu.cn', '13800001003', '2003001', '心理学系', '2020级', '心理2001', 'MALE', NULL, 1, '2026-07-16 03:40:54', '0:0:0:0:0:0:0:1', '2026-06-16 19:23:45', '2026-07-16 03:40:54');
INSERT INTO `sys_user` VALUES (15, 'student4', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '赵六', 'STUDENT', 'zhaoliu@edu.cn', '13800001004', '2003002', '心理学系', '2020级', '心理2002', 'FEMALE', NULL, 1, '2026-07-14 00:32:53', '0:0:0:0:0:0:0:1', '2026-06-18 19:23:45', '2026-07-14 00:32:53');
INSERT INTO `sys_user` VALUES (16, 'student5', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '孙七', 'STUDENT', 'sunqi@edu.cn', '13800001005', '2022001', '文学院', '2022级', '中文2201', 'MALE', NULL, 0, '2026-07-14 00:33:53', '0:0:0:0:0:0:0:1', '2026-06-20 19:23:45', '2026-07-14 00:34:10');
INSERT INTO `sys_user` VALUES (17, 'student6', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '周八', 'STUDENT', 'zhouba@edu.cn', '13800001006', '2022002', '文学院', '2022级', '中文2202', 'FEMALE', NULL, 1, '2026-07-16 10:13:33', '0:0:0:0:0:0:0:1', '2026-06-22 19:23:45', '2026-07-16 10:13:33');
INSERT INTO `sys_user` VALUES (18, 'student7', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '吴九', 'STUDENT', 'wujiu@edu.cn', '13800001007', '2024001', '商学院', '2024级', '工商2401', 'MALE', NULL, 1, '2026-07-16 03:31:13', '0:0:0:0:0:0:0:1', '2026-06-24 19:23:45', '2026-07-16 03:31:13');
INSERT INTO `sys_user` VALUES (19, 'student8', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '郑十', 'STUDENT', 'zhengshi@edu.cn', '13800001008', '2024002', '商学院', '2024级', '工商2402', 'FEMALE', NULL, 1, NULL, NULL, '2026-06-26 19:23:45', '2026-07-14 00:32:30');
INSERT INTO `sys_user` VALUES (20, 'counselor1', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '陈老师', 'COUNSELOR', 'chen@edu.cn', '13900001001', NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-07-15 20:39:25', '0:0:0:0:0:0:0:1', '2026-06-02 19:23:45', '2026-07-15 20:39:25');
INSERT INTO `sys_user` VALUES (21, 'counselor2', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '林老师', 'COUNSELOR', 'lin@edu.cn', '13900001002', NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-07-16 10:08:32', '0:0:0:0:0:0:0:1', '2026-06-04 19:23:45', '2026-07-16 10:08:32');
INSERT INTO `sys_user` VALUES (33, 'zhangsan_test', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '张三', 'STUDENT', NULL, NULL, '2024001', '计算机科学与技术学院', '2024级', '软件工程2401班', NULL, NULL, 1, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `sys_user` VALUES (34, 'lisi_test', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '李四', 'STUDENT', NULL, NULL, '2023056', '心理学院', '2023级', '应用心理学2301班', NULL, NULL, 1, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `sys_user` VALUES (35, 'wangwu_test', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '王五', 'STUDENT', NULL, NULL, '2024089', '外国语学院', '2024级', '英语2402班', NULL, NULL, 1, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `sys_user` VALUES (36, 'zhaoliu_test', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '赵六', 'STUDENT', NULL, NULL, '2023012', '商学院', '2023级', '工商管理2301班', NULL, NULL, 1, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `sys_user` VALUES (37, 'sunqi_test', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '孙七', 'STUDENT', NULL, NULL, '2024078', '文学院', '2024级', '汉语言文学2401班', NULL, NULL, 1, NULL, NULL, '2026-07-14 20:15:21', '2026-07-14 20:15:21');
INSERT INTO `sys_user` VALUES (78, 'student9', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '郑成功', 'STUDENT', 'zhengcg@example.com', '13800010007', '2024018', '经济管理学院', '2024级', '经管2401班', NULL, NULL, 1, '2025-07-13 09:15:00', NULL, '2026-07-15 16:10:51', '2026-07-15 16:10:51');
INSERT INTO `sys_user` VALUES (79, 'student10', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '钱多多', 'STUDENT', 'qiandd@example.com', '13800010008', '2023007', '法学院', '2023级', '法学2301班', NULL, NULL, 1, '2025-07-11 15:45:00', NULL, '2026-07-15 16:10:51', '2026-07-15 16:10:51');
INSERT INTO `sys_user` VALUES (86, 'counselor3', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '陈老师', 'COUNSELOR', 'chen@psychology.com', '13900020001', NULL, '心理咨询中心', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-07-15 16:10:51', '2026-07-15 16:10:51');
INSERT INTO `sys_user` VALUES (87, 'counselor4', '0c909a141f1f2c0a1cb602b0b2d7d050', '', '张老师', 'COUNSELOR', 'zhang@psychology.com', '13900020002', NULL, '学生心理健康中心', NULL, NULL, NULL, NULL, 1, NULL, NULL, '2026-07-15 16:10:51', '2026-07-15 16:10:51');

-- 安全添加列（防止重复执行失败）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = 'psychology' AND TABLE_NAME = 'article' AND COLUMN_NAME = 'source_url');
SET @sql1 = IF(@col_exists = 0, 'ALTER TABLE `article` ADD COLUMN `source_url` VARCHAR(500) NULL COMMENT ''外部来源URL'' AFTER `content`', 'SELECT ''source_url already exists, skipping'' AS info');
PREPARE stmt1 FROM @sql1; EXECUTE stmt1; DEALLOCATE PREPARE stmt1;

SET @col_exists2 = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = 'psychology' AND TABLE_NAME = 'article' AND COLUMN_NAME = 'source_name');
SET @sql2 = IF(@col_exists2 = 0, 'ALTER TABLE `article` ADD COLUMN `source_name` VARCHAR(100) NULL COMMENT ''来源名称(壹心理/简单心理/高校心理/自建)'' AFTER `source_url`', 'SELECT ''source_name already exists, skipping'' AS info');
PREPARE stmt2 FROM @sql2; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;
SET FOREIGN_KEY_CHECKS = 1;
