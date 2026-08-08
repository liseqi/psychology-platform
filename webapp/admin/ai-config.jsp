<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI智能助手配置中心 - 心理咨询系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container { max-width: 1400px; margin: 0 auto; }
        .header {
            background: white;
            border-radius: 16px;
            padding: 30px;
            margin-bottom: 24px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.15);
        }
        .header h1 {
            font-size: 28px;
            background: linear-gradient(135deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }
        .header p { color: #666; font-size: 14px; }
        
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 24px; margin-bottom: 24px; }
        .card {
            background: white;
            border-radius: 16px;
            padding: 28px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        .card:hover { transform: translateY(-4px); box-shadow: 0 8px 30px rgba(0,0,0,0.12); }
        
        .card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 24px;
            padding-bottom: 16px;
            border-bottom: 2px solid #f0f0f0;
        }
        .card-title {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 18px;
            font-weight: 600;
            color: #333;
        }
        .card-title .icon {
            width: 40px; height: 40px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }
        .icon.ai { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .icon.rag { background: linear-gradient(135deg, #11998e, #38ef7d); color: white; }
        .icon.memory { background: linear-gradient(135deg, #ee0979, #ff6a00); color: white; }
        .icon.vector { background: linear-gradient(135deg, #00c6fb, #005bea); color: white; }
        .icon.audit { background: linear-gradient(135deg, #8E2DE2, #4A00E0); color: white; }
        
        .form-group { margin-bottom: 20px; }
        .form-group label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #555;
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .form-group input, .form-group select, .form-group textarea {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e8e8e8;
            border-radius: 10px;
            font-size: 14px;
            transition: all 0.3s ease;
            background: #fafafa;
        }
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
            background: white;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.1);
        }
        .form-group input[type="checkbox"] {
            width: auto;
            margin-right: 8px;
        }
        .form-group small {
            display: block;
            color: #999;
            font-size: 12px;
            margin-top: 6px;
        }
        
        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 4px 15px rgba(102,126,234,0.4); }
        .btn-success { background: linear-gradient(135deg, #11998e, #38ef7d); color: white; }
        .btn-warning { background: linear-gradient(135deg, #f093fb, #f5576c); color: white; }
        .btn-info { background: linear-gradient(135deg, #00c6fb, #005bea); color: white; }
        .btn-sm { padding: 8px 16px; font-size: 12px; }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        .stat-item {
            text-align: center;
            padding: 20px;
            background: linear-gradient(135deg, #f5f7fa, #c3cfe2);
            border-radius: 12px;
        }
        .stat-value {
            font-size: 32px;
            font-weight: 700;
            background: linear-gradient(135deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .stat-label { font-size: 12px; color: #666; margin-top: 4px; font-weight: 500; }
        
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .status-active { background: #d4edda; color: #155724; }
        .status-inactive { background: #f8d7da; color: #721c24; }
        .status-warning { background: #fff3cd; color: #856404; }
        
        .log-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 16px;
        }
        .log-table th, .log-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
            font-size: 13px;
        }
        .log-table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #555;
        }
        .log-table tr:hover { background: #f8f9fa; }
        
        .alert-box {
            padding: 16px 20px;
            border-radius: 10px;
            margin-bottom: 16px;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .alert-info { background: #cce5ff; color: #004085; border: 1px solid #b8daff; }
        
        .loading-spinner {
            display: inline-block;
            width: 16px; height: 16px;
            border: 2px solid #fff;
            border-top-color: transparent;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        
        .hidden { display: none !important; }
        
        /* 响应式 */
        @media (max-width: 768px) {
            .grid { grid-template-columns: 1fr; }
            .container { padding: 10px; }
            body { padding: 10px; }
        }
    </style>
</head>
<body>
<div class="container">
    
    <!-- 页面头部 -->
    <div class="header">
        <h1>🤖 AI智能助手配置中心</h1>
        <p>管理大模型参数、RAG知识库、长期记忆、向量数据库 | V3.0 高级功能面板</p>
    </div>
    
    <!-- 快速状态概览 -->
    <div class="stats-grid" id="quickStats">
        <div class="stat-item">
            <div class="stat-value" id="aiStatus">--</div>
            <div class="stat-label">AI连接状态</div>
        </div>
        <div class="stat-item">
            <div class="stat-value" id="kbVectors">--</div>
            <div class="stat-label">知识库向量数</div>
        </div>
        <div class="stat-item">
            <div class="stat-value" id="chatVectors">--</div>
            <div class="stat-label">对话向量数</div>
        </div>
        <div class="stat-item">
            <div class="stat-value" id="totalMemory">--</div>
            <div class="stat-label">用户记忆总数</div>
        </div>
    </div>
    
    <!-- 主内容区 -->
    <div class="grid">
        
        <!-- 卡片1：AI基础配置 -->
        <div class="card">
            <div class="card-header">
                <div class="card-title">
                    <span class="icon ai">🤖</span>
                    <span>AI基础配置</span>
                </div>
                <span class="status-badge status-active" id="providerBadge">DOUBAO</span>
            </div>
            
            <form id="basicConfigForm">
                <div class="form-group">
                    <label>AI Provider（模型提供商）</label>
                    <select name="config.ai.provider" id="configProvider">
                        <option value="DOUBAO">豆包 (字节跳动) - 推荐</option>
                        <option value="DEEPSEEK">DeepSeek - 性价比高</option>
                        <option value="OPENAI">OpenAI (GPT-4o)</option>
                        <option value="CUSTOM">自定义 (Ollama本地)</option>
                    </select>
                    <small>切换Provider后需要填写对应的API Key</small>
                </div>
                
                <div class="form-group">
                    <label>API Key / 密钥</label>
                    <input type="password" name="config.api.key" id="apiKeyInput"
                           placeholder="请输入API Key（敏感信息会加密存储）">
                    <small>修改后立即生效，无需重启服务器</small>
                </div>
                
                <div class="form-group">
                    <label>默认模型名称/端点ID</label>
                    <input type="text" name="config.model" id="modelInput" 
                           placeholder="如: ep-20240601153646-lmzqv 或 deepseek-chat">
                    <small>豆包使用端点ID，其他使用模型名称</small>
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                    <div class="form-group">
                        <label>Temperature（创造性）</label>
                        <input type="number" step="0.1" min="0" max="2" name="config.temperature" 
                               value="0.7" placeholder="0.7">
                    </div>
                    <div class="form-group">
                        <label>Max Tokens（最大回复长度）</label>
                        <input type="number" min="256" max="4096" name="config.max.tokens" 
                               value="2048" placeholder="2048">
                    </div>
                </div>
                
                <button type="button" class="btn btn-primary" onclick="saveBasicConfig()">
                    💾 保存基础配置
                </button>
                <button type="button" class="btn btn-info btn-sm" onclick="testConnection()" 
                        style="margin-left: 12px;">
                    🔗 测试连接
                </button>
            </form>
            
            <!-- 连接测试结果 -->
            <div id="testResult" class="hidden"></div>
        </div>
        
        <!-- 卡片2：RAG知识库配置 -->
        <div class="card">
            <div class="card-header">
                <div class="card-title">
                    <span class="icon rag">📚</span>
                    <span>RAG检索增强生成</span>
                </div>
                <span class="status-badge status-active" id="ragStatus">已启用</span>
            </div>
            
            <form id="ragConfigForm">
                <div class="form-group">
                    <label style="display:flex;align-items:center;gap:8px;">
                        <input type="checkbox" name="config.rag.enabled" id="ragEnabled" checked> 启用RAG功能
                    </label>
                    <small>启用后，AI回答时会自动从科普文章库中检索相关资料作为参考依据</small>
                </div>
                
                <div class="form-group">
                    <label>返回最相关的 K 条结果</label>
                    <input type="number" min="1" max="10" name="config.rag.top_k" value="3">
                </div>
                
                <div class="form-group">
                    <label>相似度阈值（0-1，低于此值不返回）</label>
                    <input type="number" step="0.05" min="0" max="1" name="config.rag.similarity_threshold" value="0.6">
                    <small>建议值：0.55-0.70。越高越严格但可能漏掉相关结果</small>
                </div>
                
                <div class="form-group">
                    <label>最大上下文注入长度（字符）</label>
                    <input type="number" min="500" max="4000" name="config.rag.max_context_length" value="1500">
                    <small>控制注入Prompt的参考资料长度，避免超出Token限制</small>
                </div>
                
                <div style="display:flex;gap:12px;margin-top:20px;">
                    <button type="button" class="btn btn-success" onclick="saveRAGConfig()">
                        💾 保存RAG配置
                    </button>
                    <button type="button" class="btn btn-warning" onclick="buildKnowledgeBase()">
                        🔄 构建/重建知识库
                    </button>
                    <button type="button" class="btn btn-info btn-sm" onclick="testRAG()">
                        🧪 测试RAG
                    </button>
                </div>
            </form>
            
            <div id="ragTestResult" class="hidden"></div>
        </div>
        
        <!-- 卡片3：长期记忆配置 -->
        <div class="card">
            <div class="card-header">
                <div class="card-title">
                    <span class="icon memory">🧠</span>
                    <span>多轮记忆持久化</span>
                </div>
                <span class="status-badge status-active" id="memoryStatus">已启用</span>
            </div>
            
            <form id="memoryConfigForm">
                <div class="form-group">
                    <label style="display:flex;align-items:center;gap:8px;">
                        <input type="checkbox" name="config.memory.enabled" id="memoryEnabled" checked> 启用长期记忆
                    </label>
                    <small>启用后，AI会跨会话记住用户的偏好、困扰、目标等信息</small>
                </div>
                
                <div class="form-group">
                    <label style="display:flex;align-items:center;gap:8px;">
                        <input type="checkbox" name="config.memory.auto_extract" checked> 自动提取记忆
                    </label>
                    <small>每次对话结束后自动用AI提取关键信息存入长期记忆</small>
                </div>
                
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;">
                    <div class="form-group">
                        <label>每用户最大记忆条数</label>
                        <input type="number" min="10" max="500" name="config.memory.max_per_user" value="100">
                    </div>
                    <div class="form-group">
                        <label>提取置信度阈值</label>
                        <input type="number" step="0.05" min="0.5" max="0.95" 
                               name="config.memory.confidence_threshold" value="0.70">
                    </div>
                    <div class="form-group">
                        <label>记忆保留天数（0=永不过期）</label>
                        <input type="number" min="0" max="365" name="config.memory.expiration_days" value="180">
                    </div>
                </div>
                
                <button type="button" class="btn btn-primary" onclick="saveMemoryConfig()">
                    💾 保存记忆配置
                </button>
            </form>
            
            <!-- 查看记忆入口 -->
            <div style="margin-top:20px;padding:16px;background:#f8f9fa;border-radius:10px;">
                <strong>🔍 用户记忆查询：</strong>
                <div style="display:flex;gap:12px;margin-top:12px;">
                    <input type="number" placeholder="用户ID" id="memoryUserId" style="flex:1;">
                    <button type="button" class="btn btn-info btn-sm" onclick="loadUserMemories()">
                        查看记忆
                    </button>
                </div>
                <div id="userMemoryList" style="margin-top:12px;"></div>
            </div>
        </div>
        
        <!-- 卡片4：Embedding与向量配置 -->
        <div class="card">
            <div class="card-header">
                <div class="card-title">
                    <span class="icon vector">🎯</span>
                    <span>向量数据库 & Embedding</span>
                </div>
            </div>
            
            <form id="vectorConfigForm">
                <div class="form-group">
                    <label>存储模式</label>
                    <select name="config.vector.db.type" disabled>
                        <option value="MYSQL" selected>MySQL原生（当前推荐）</option>
                        <option value="MILVUS">Milvus（高性能，需部署）</option>
                        <option value="PINECONE">Pinecone（云端服务）</option>
                    </select>
                    <small>MySQL模式适合中小规模（<10万向量），无需额外基础设施</small>
                </div>
                
                <div class="form-group">
                    <label>Embedding Provider</label>
                    <select name="config.embedding.provider" id="embeddingProvider">
                        <option value="DOUBAO">豆包 Embedding API</option>
                        <option value="OPENAI">OpenAI text-embedding-ada-002</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>向量维度</label>
                    <input type="number" readonly value="768" style="background:#eee;">
                    <small>由所选Embedding模型决定，不可手动修改</small>
                </div>
                
                <div class="form-group">
                    <label>Milvus配置（如使用Milvus模式）</label>
                    <div style="display:grid;grid-template-columns:2fr 1fr;gap:12px;">
                        <input type="text" placeholder="Host: localhost" disabled value="localhost">
                        <input type="text" placeholder="Port: 19530" disabled value="19530">
                    </div>
                </div>
                
                <button type="button" class="btn btn-primary" onclick="saveVectorConfig()" disabled>
                    💾 保存向量配置（开发中）
                </button>
            </form>
            
            <!-- 知识库统计 -->
            <div id="kbStats" style="margin-top:24px;"></div>
        </div>
        
    </div><!-- end .grid -->
    
    <!-- 审计日志区域 -->
    <div class="card" style="margin-top:24px;">
        <div class="card-header">
            <div class="card-title">
                <span class="icon audit">📋</span>
                <span>配置变更审计日志</span>
            </div>
            <button type="button" class="btn btn-info btn-sm" onclick="loadAuditLog()">刷新</button>
        </div>
        
        <table class="log-table" id="auditLogTable">
            <thead>
                <tr>
                    <th>时间</th>
                    <th>管理员</th>
                    <th>配置项</th>
                    <th>操作</th>
                    <th>备注</th>
                </tr>
            </thead>
            <tbody id="auditLogBody">
                <tr><td colspan="5" style="text-align:center;color:#999;">点击"刷新"加载审计日志</td></tr>
            </tbody>
        </table>
    </div>

</div><!-- end .container -->

<script>
// =====================================================
// 页面初始化
// =====================================================
document.addEventListener('DOMContentLoaded', function() {
    loadQuickStats();
    loadCurrentConfig();
    loadAuditLog();
});

// =====================================================
// 工具函数：显示消息
// =====================================================
function showAlert(elementId, message, type) {
    const el = document.getElementById(elementId);
    el.className = 'alert-box alert-' + type;
    el.innerHTML = message;
    el.classList.remove('hidden');
    
    // 5秒后自动隐藏
    setTimeout(() => el.classList.add('hidden', 5000));
}

function showLoading(btn) {
    const originalText = btn.innerHTML;
    btn.innerHTML = '<span class="loading-spinner"></span> 处理中...';
    btn.disabled = true;
    return originalText;
}

function restoreButton(btn, originalText) {
    btn.innerHTML = originalText;
    btn.disabled = false;
}

// =====================================================
// 加载快速统计
// =====================================================
async function loadQuickStats() {
    try {
        // 测试AI连接
        const connResp = await fetch('admin/ai-config/test-connection');
        const connData = await connResp.json();
        
        document.getElementById('aiStatus').innerHTML = 
            connData.data.aiConnected ? '<span style="color:green">●</span>' : '<span style="color:red">●</span>';
        
        // 加载知识库统计
        const kbResp = await fetch('admin/ai-config/kb-stats');
        const kbData = await kbResp.json();
        
        if (kbData.success && kbData.data) {
            document.getElementById('kbVectors').textContent = kbData.data.totalVectors || 0;
            document.getElementById('chatVectors').textContent = kbData.data.totalMessageVectors || 0;
        }
        
        // TODO: 从接口获取总记忆数
        
    } catch (error) {
        console.error('加载统计数据失败:', error);
    }
}

// =====================================================
// 配置加载和保存
// =====================================================
async function loadCurrentConfig() {
    // TODO: 从API加载当前配置并填充表单
}

async function saveBasicConfig() {
    const btn = event.target;
    const originalHTML = showLoading(btn);
    
    try {
        const formData = new FormData(document.getElementById('basicConfigForm'));
        const params = new URLSearchParams();
        for (let [key, value] of formData.entries()) {
            if (value.trim()) params.append(key, value);
        }
        
        const resp = await fetch('admin/ai-config/batch-update', { method: 'POST', body: params });
        const data = await resp.json();
        
        showAlert('testResult', 
            data.success ? '✅ 基础配置保存成功！' : '❌ 保存失败: ' + (data.message || ''),
            data.success ? 'success' : 'error');
        
    } catch (error) {
        showAlert('testResult', '❌ 请求异常: ' + error.message, 'error');
    } finally {
        restoreButton(btn, originalHTML);
    }
}

async function saveRAGConfig() {
    alert('RAG配置保存功能 - 开发中...');
}

async function saveMemoryConfig() {
    alert('记忆配置保存功能 - 开发中...');
}

async function saveVectorConfig() {
    alert('向量配置保存功能 - 开发中...');
}

// =====================================================
// 测试功能
// =====================================================
async function testConnection() {
    const btn = event.target;
    const originalHTML = showLoading(btn);
    
    try {
        const resp = await fetch('admin/ai-config/test-connection');
        const data = await resp.json();
        
        if (data.success && data.data) {
            const d = data.data;
            let html = `<div class='alert-box ${d.aiConnected ? "alert-success" : "alert-error"}'>`;
            html += `<strong>${d.aiConnected ? '✅' : '❌'} AI大模型:</strong> `;
            html += d.aiConnected ? `已连接 (${d.provider})` : '连接失败';
            html += `<br><strong>${d.embeddingOk ? '✅' : '❌'} Embedding服务:</strong> `;
            html += d.embeddingOk ? `正常 (${d.embeddingModel})` : '不可用';
            html += `</div>`;
            
            document.getElementById('testResult').innerHTML = html;
            document.getElementById('testResult').classList.remove('hidden');
        }
        
    } catch (error) {
        showAlert('testResult', '❌ 测试请求失败: ' + error.message, 'error');
    } finally {
        restoreButton(btn, originalHTML);
    }
}

async function testRAG() {
    const query = prompt('请输入测试查询词:', '如何缓解考试焦虑');
    if (!query) return;
    
    try {
        const resp = await fetch(`admin/ai-config/test-rag?query=${encodeURIComponent(query)}`);
        const data = await resp.json();
        
        if (data.success && data.data) {
            const d = data.data;
            let html = `<div class='alert-box ${d.hasResult ? "alert-success" : "alert-info"}'>`;
            html += `<strong>查询词:</strong> ${d.testQuery}<br>`;
            html += `<strong>是否命中:</strong> ${d.hasResult ? '✅ 是' : '❌ 否'}<br>`;
            html += `<strong>上下文长度:</strong> ${d.contextLength} 字符<br>`;
            html += `<strong>耗时:</strong> ${d.durationMs}ms<br>`;
            if (d.contextPreview) {
                html += `<br><strong>预览:</strong> ${d.contextPreview.substring(0, 150)}...`;
            }
            html += `</div>`;
            
            document.getElementById('ragTestResult').innerHTML = html;
            document.getElementById('ragTestResult').classList.remove('hidden');
        }
        
    } catch (error) {
        showAlert('ragTestResult', '❌ RAG测试失败: ' + error.message, 'error');
    }
}

// =====================================================
// 知识库构建
// =====================================================
async function buildKnowledgeBase() {
    if (!confirm('确定要重建整个RAG知识库吗？\n\n这将重新向量化所有已发布的科普文章，可能需要几分钟时间。')) {
        return;
    }
    
    const btn = event.target;
    const originalHTML = showLoading(btn);
    
    try {
        const resp = await fetch('admin/ai-config/build-kb', { method: 'POST' });
        const data = await resp.json();
        
        alert(data.message || (data.success ? '知识库构建任务已启动！' : '启动失败'));
        
    } catch (error) {
        alert('请求失败: ' + error.message);
    } finally {
        restoreButton(btn, originalHTML);
        // 刷新统计
        setTimeout(loadQuickStats, 2000);
    }
}

// =====================================================
// 记忆管理
// =====================================================
async function loadUserMemories() {
    const userId = document.getElementById('memoryUserId').value;
    if (!userId) { alert('请输入用户ID'); return; }
    
    try {
        const resp = await fetch(`admin/ai-config/memory-list?userId=${userId}`);
        const data = await resp.json();
        
        let html = '';
        if (data.success && data.data.memories.length > 0) {
            html += '<table class="log-table"><thead><tr><th>类型</th><th>内容</th><th>置信度</th><th>引用次数</th></tr></thead><tbody>';
            data.data.memories.forEach(m => {
                html += `<tr><td>${m.memoryType}</td><td>${m.memoryContent.substring(0,50)}...</td>` +
                       `<td>${(m.confidence * 100).toFixed(0)}%</td><td>${m.referenceCount}</td></tr>`;
            });
            html += '</tbody></table>';
        } else {
            html = '<p style="color:#999;text-align:center;">该用户暂无记忆记录</p>';
        }
        
        document.getElementById('userMemoryList').innerHTML = html;
        
    } catch (error) {
        document.getElementById('userMemoryList').innerHTML = 
            '<p style="color:red;">加载失败: ' + error.message + '</p>';
    }
}

// =====================================================
// 审计日志
// =====================================================
async function loadAuditLog() {
    try {
        const resp = await fetch('admin/ai-config/audit-log?page=1&pageSize=10');
        const data = await resp.json();
        
        let tbody = '';
        if (data.success && data.data.logs.length > 0) {
            data.data.logs.forEach(log => {
                tbody += `<tr>
                    <td>${new Date(log.createdAt).toLocaleString()}</td>
                    <td>${log.adminName || '-'}</td>
                    <td><code>${log.configKey}</code></td>
                    <td>${log.operation}</td>
                    <td>${log.remark || '-'}</td>
                </tr>`;
            });
        } else {
            tbody = '<tr><td colspan="5" style="text-align:center;">暂无日志记录</td></tr>';
        }
        
        document.getElementById('auditLogBody').innerHTML = tbody;
        
    } catch (error) {
        console.error('加载审计日志失败:', error);
    }
}
</script>

</body>
</html>
