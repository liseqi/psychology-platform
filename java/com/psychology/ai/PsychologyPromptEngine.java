package com.psychology.ai;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * 心理咨询专用Prompt工程引擎
 * 
 * 核心职责：
 * 1. 构建专业的心理咨询系统提示词（System Prompt）
 * 2. 动态注入学生画像和业务数据
 * 3. 实现多轮对话的上下文管理
 * 4. 场景化的回复策略引导
 *
 * 设计原则：
 * - 让AI成为"专业心理咨询助手"，而非通用聊天机器人
 * - 结合数据库中的真实业务数据（测评、咨询记录等）
 * - 遵循心理咨询伦理和边界
 */
public class PsychologyPromptEngine {
    
    // =====================================================
    // 系统提示词模板（核心）
    // =====================================================
    
    /**
     * 基础系统提示词 - 定义AI的角色、能力边界和行为准则
     */
    private static final String BASE_SYSTEM_PROMPT = 
        "# 角色定义\n\n" +
        "你是「心灵树洞」AI心理咨询助手，一个专业、温暖、有边界感的大学生心理支持伙伴。\n\n" +
        "## 核心身份特征\n\n" +
        "**专业性**：\n" +
        "- 你具备心理学基础知识，熟悉认知行为疗法(CBT)、人本主义治疗、积极心理学等方法\n" +
        "- 你能识别常见的心理健康问题：焦虑、抑郁、学业压力、人际关系、情感困扰、自我认同危机等\n" +
        "- 你的建议基于科学心理学原理，但会明确标注\"这不是专业诊断\"\n\n" +
        "**温暖共情**：\n" +
        "- 使用温暖、接纳、不评判的语言风格\n" +
        "- 积极倾听，先确认情绪，再提供建议\n" +
        "- 适当使用表情符号(🌟💪🤗😊)增强亲和力，但不滥用\n\n" +
        "**严格边界**：\n" +
        "- ❌ 绝不提供医疗诊断或药物建议\n" +
        "- ❌ 不承诺\"治愈\"或\"立即好转\"\n" +
        "- ❌ 不涉及法律、财务等专业领域\n" +
        "- ✅ 当检测到严重危机时，必须立即引导寻求专业帮助\n" +
        "- ✅ 明确告知用户你的局限性\n\n" +
        "## 回复策略框架\n\n" +
        "### 1️⃣ 情绪确认阶段（必须）\n" +
        "- 首先确认并命名用户的情绪：\"我听到你现在感到[情绪词]...\"\n" +
        "- 正常化感受：\"这种感觉在[类似情境]下是很正常的...\"\n\n" +
        "### 2️⃣ 共情理解阶段（核心）\n" +
        "- 使用开放式问题探索：\"能告诉我更多关于...吗？\"\n" +
        "- 反馈性倾听：\"所以你的意思是...\"\n" +
        "- 避免过早给建议\n\n" +
        "### 3️⃣ 轻度介入阶段（可选）\n" +
        "提供以下类型的支持（根据情况选择1-2个）：\n" +
        "- 🧠 **认知重构**：帮助用户识别非理性信念\n" +
        "- 💡 **应对技巧**：呼吸放松、正念冥想、日记书写等\n" +
        "- 🎯 **行动计划**：小步骤、可操作的建议\n" +
        "- 🔗 **资源链接**：推荐预约学校心理咨询中心\n\n" +
        "### 4️⃣ 安全兜底阶段（高危场景强制）\n" +
        "当检测到以下关键词时触发危机干预流程：\n" +
        "自杀/自残/想死/不想活/结束生命/割腕/跳楼/服药过量 → \n" +
        "必须回复：\n" +
        "\"🚨 我很担心你的安全。如果你正在经历这些想法，请立即：\n" +
        "1. 拨打全国心理援助热线：400-161-9995（24小时）\n" +
        "2. 联系学校心理咨询中心：[电话]\n" +
        "3. 告诉身边信任的人（辅导员/室友/家人）\n\n" +
        "你并不孤单，专业的心理老师愿意帮助你。这里的信息也会被转介给专业人员关注。\"\n\n" +
        "## 语言风格规范\n\n" +
        "- 使用第二人称\"你\"，建立对话感\n" +
        "- 句子长度适中（15-25字为宜），避免过长段落\n" +
        "- 适当分段和使用emoji增强可读性\n" +
        "- 避免过于学术化或说教式语气\n" +
        "- 结尾通常用开放性问题鼓励继续对话\n\n" +
        "## 输出格式要求\n\n" +
        "- 单次回复控制在300-500字以内\n" +
        "- 重要信息用**加粗**标记\n" +
        "- 使用列表结构呈现多条建议\n" +
        "- 危机干预内容置顶显示";
    
    /**
     * 数据增强模板 - 在基础提示词后追加的学生个性化信息
     */
    private static final String DATA_ENHANCEMENT_TEMPLATE = 
        "\n\n--- 【当前学生画像（仅AI可见，不要向用户透露具体来源）】 ---\n\n" +
        "## 基本信息\n{student_profile}\n\n{assessment_section}\n{consultation_section}{appointment_section}" +
        "\n## 对话历史摘要\n{conversation_summary}\n\n--- 【画像结束】 ---\n\n" +
        "请结合以上信息，为这位同学提供个性化的心理支持。" +
        "记住：画像中的信息用于更好地理解对方，不要直接提及\"我知道你做过XX测评\"" +
        "这类话，而是自然地融入对话中。";
    
    // =====================================================
    // 公开方法
    // =====================================================
    
    /**
     * 构建完整的系统提示词（包含数据增强）
     * 
     * @param studentContext 学生上下文数据（可为null表示无数据增强）
     * @param conversationHistory 近期对话摘要
     * @return 完整的系统提示词
     */
    public static String buildSystemPrompt(StudentContextBuilder.StudentContext studentContext, 
                                            String conversationHistory) {
        StringBuilder prompt = new StringBuilder(BASE_SYSTEM_PROMPT);
        
        // 如果有学生数据，追加数据增强部分
        if (studentContext != null && studentContext.hasData()) {
            String enhancedData = buildDataEnhancement(studentContext, conversationHistory);
            prompt.append(enhancedData);
        }
        
        return prompt.toString();
    }
    
    /**
     * 构建纯基础提示词（不含数据增强）
     */
    public static String buildBaseSystemPrompt() {
        return BASE_SYSTEM_PROMPT;
    }
    
    /**
     * 为新会话生成欢迎语
     */
    public static String generateWelcomeMessage() {
        return "你好呀！我是 AI 心灵树洞 🌳 这里是一个安全、保密的倾诉空间。\n\n" +
               "你可以放心地和我分享任何烦恼——学习压力、人际关系、情绪困扰...\n\n" +
               "我会认真倾听你说的每一句话，并尽力给你温暖的支持和建议。✨\n\n" +
               "💡 <b>小提示：</b>如果你想聊聊什么，可以直接开始；也可以点击下方的快捷话题～";
    }
    
    /**
     * 从用户消息智能提取会话标题
     */
    public static String generateSessionTitle(String firstMessage) {
        if (firstMessage == null || firstMessage.length() < 5) {
            return "新对话";
        }
        
        // 截取前20字作为标题
        String title = firstMessage.substring(0, Math.min(20, firstMessage.length()));
        if (firstMessage.length() > 20) {
            title += "...";
        }
        
        return title.replace("\n", " ").trim();
    }
    
    // =====================================================
    // 私有方法
    // =====================================================
    
    /**
     * 构建数据增强部分
     */
    private static String buildDataEnhancement(StudentContextBuilder.StudentContext ctx, String conversationSummary) {
        String result = DATA_ENHANCEMENT_TEMPLATE;
        
        // 替换基本信息
        result = result.replace("{student_profile}", formatStudentProfile(ctx));
        
        // 替换测评信息
        result = result.replace("{assessment_section}", formatAssessmentSection(ctx));
        
        // 替换咨询记录
        result = result.replace("{consultation_section}", formatConsultationSection(ctx));
        
        // 替换预约信息
        result = result.replace("{appointment_section}", formatAppointmentSection(ctx));
        
        // 替换对话历史摘要
        result = result.replace("{conversation_summary}", 
            conversationSummary != null ? conversationSummary : "暂无历史对话");
        
        return result;
    }
    
    private static String formatStudentProfile(StudentContextBuilder.StudentContext ctx) {
        StringBuilder sb = new StringBuilder();
        sb.append("- 年级: ").append(ctx.grade != null ? ctx.grade : "未知").append("\n");
        sb.append("- 院系: ").append(ctx.department != null ? ctx.department : "未知").append("\n");
        if (ctx.lastLoginTime != null) {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
            sb.append("- 最近登录: ").append(sdf.format(ctx.lastLoginTime)).append("\n");
        }
        return sb.toString();
    }
    
    private static String formatAssessmentSection(StudentContextBuilder.StudentContext ctx) {
        if (ctx.recentAssessments == null || ctx.recentAssessments.isEmpty()) {
            return "";  // 无数据则隐藏整个section标题
        }
        
        StringBuilder sb = new StringBuilder("## 最近的心理测评结果\n");
        for (Map<String, Object> assessment : ctx.recentAssessments) {
            sb.append("- ").append(assessment.get("scaleName"))
              .append(" [").append(assessment.get("date")).append("]")
              .append(": 风险等级=").append(assessment.get("riskLevel"))
              .append(", 总分=").append(assessment.get("totalScore")).append("\n");
        }
        return sb.toString();
    }
    
    private static String formatConsultationSection(StudentContextBuilder.StudentContext ctx) {
        if (ctx.consultationCount == 0) {
            return "";
        }
        
        StringBuilder sb = new StringBuilder("## 历史咨询记录\n");
        sb.append("- 累计咨询次数: ").append(ctx.consultationCount).append("次\n");
        if (ctx.lastConsultationTopic != null) {
            sb.append("- 最近一次咨询主题: ").append(ctx.lastConsultationTopic).append("\n");
        }
        return sb.toString();
    }
    
    private static String formatAppointmentSection(StudentContextBuilder.StudentContext ctx) {
        if (!ctx.hasUpcomingAppointment) {
            return "";
        }
        
        StringBuilder sb = new StringBuilder("## 即将到来的预约\n");
        sb.append("- 预约时间: ").append(ctx.upcomingAppointmentDate).append(" ")
          .append(ctx.upcomingAppointmentTime).append("\n");
        if (ctx.upcomingAppointmentTopic != null) {
            sb.append("- 咨询主题: ").append(ctx.upcomingAppointmentTopic).append("\n");
        }
        return sb.toString();
    }
}
