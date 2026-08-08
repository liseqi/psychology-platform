<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"STUDENT".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI树洞 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .chat-container { display: flex; height: calc(100vh - 180px); margin-top: 20px; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .chat-sidebar { width: 260px; background: #fafafa; border-right: 1px solid #eee; display: flex; flex-direction: column; }
        .sidebar-header { padding: 20px; border-bottom: 1px solid #eee; }
        .sidebar-header h3 { color: #333; font-size: 16px; margin-bottom: 8px; }
        .new-chat-btn { padding: 10px; background: #667eea; color: white; border: none; border-radius: 8px; cursor: pointer; width: 100%; font-size: 14px; transition: background 0.2s; }
        .new-chat-btn:hover { background: #5568d3; }
        .chat-history { flex: 1; overflow-y: auto; padding: 12px; }
        .history-item { padding: 12px; border-radius: 8px; cursor: pointer; margin-bottom: 8px; transition: background 0.2s; border: 1px solid transparent; }
        .history-item:hover { background: #e6f7ff; border-color: #bae7ff; }
        .history-item.active { background: #d6e4ff; border-color: #667eea; }
        .history-item .title { font-size: 14px; color: #333; margin-bottom: 4px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-weight: 500; }
        .history-item .time { font-size: 12px; color: #999; }
        .history-item .tag { display: inline-block; padding: 2px 6px; border-radius: 10px; font-size: 11px; margin-right: 4px; background: #fff2e8; color: #fa8c16; }
        .chat-main { flex: 1; display: flex; flex-direction: column; }
        .chat-messages { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; }
        .message { max-width: 75%; padding: 14px 18px; border-radius: 12px; line-height: 1.6; animation: fadeIn 0.3s ease-out; word-break: break-word; }
        @keyframes fadeIn { from{opacity:0;transform:translateY(10px)} to{opacity:1;transform:none} }
        .message.user { background: linear-gradient(135deg, #667eea, #764ba2); color: white; align-self: flex-end; border-bottom-right-radius: 4px; box-shadow: 0 2px 8px rgba(102,126,234,0.3); }
        .message.ai { background: #f0f2f5; color: #333; align-self: flex-start; border-bottom-left-radius: 4px; box-shadow: 0 2px 6px rgba(0,0,0,0.05); }
        .message .sender { font-size: 12px; opacity: 0.75; margin-bottom: 6px; display: flex; align-items: center; gap: 4px; }
        .message .sender .badge { padding: 1px 6px; border-radius: 8px; font-size: 10px; background: #e6f7ff; color: #1890ff; }
        .message.user .sender .badge { background: rgba(255,255,255,0.2); color: white; }
        
        /* AI消息中的格式化样式 */
        .message.ai strong { color: #cf1322; font-weight: 600; }
        .message.ai ul, .message.ai ol { margin: 8px 0; padding-left: 20px; }
        .message.ai li { margin: 4px 0; }
        
        .chat-input-area { padding: 20px 24px; border-top: 1px solid #eee; display: flex; gap: 12px; align-items: flex-end; background: #fafafa; }
        .chat-input-area textarea { flex: 1; padding: 12px 16px; border: 1px solid #ddd; border-radius: 12px; resize: none; height: 52px; outline: none; font-family: inherit; font-size: 14px; line-height: 1.5; transition: all 0.2s; background: white; }
        .chat-input-area textarea:focus { border-color: #667eea; box-shadow: 0 0 0 3px rgba(102,126,234,0.1); }
        .send-btn { padding: 12px 28px; background: linear-gradient(135deg,#667eea,#764ba2); color: white; border: none; border-radius: 12px; cursor: pointer; font-size: 15px; font-weight: 500; transition: all 0.2s; display: flex; align-items: center; gap: 6px; }
        .send-btn:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(102,126,234,0.4); }
        .send-btn:active { transform: translateY(0); }
        .send-btn:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }
        
        .quick-prompts { display: flex; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; padding: 0 24px; }
        .quick-prompt { padding: 8px 16px; background: #f0f5ff; color: #667eea; border-radius: 20px; font-size: 13px; cursor: pointer; transition: all 0.2s; border: 1px solid transparent; }
        .quick-prompt:hover { border-color: #667eea; background: #e6f7ff; transform: translateY(-1px); }
        .typing-indicator { display: none; padding: 14px 18px; background: linear-gradient(135deg, #e8e8e8, #f0f0f0); color: #666; align-self: flex-start; border-radius: 12px; border-bottom-left-radius: 4px; font-size: 13px; }
        .typing-indicator.show { display: block; animation: fadeIn 0.2s; }
        .dots span { display: inline-block; width: 8px; height: 8px; background: #999; border-radius: 50%; margin: 0 2px; animation: bounce 1.4s infinite ease-in-out; }
        .dots span:nth-child(2) { animation-delay: 0.2s; }
        .dots span:nth-child(3) { animation-delay: 0.4s; }
        @keyframes bounce { 0%,80%,100%{transform:translateY(0)}40%{transform:translateY(-8px)} }
        
        .privacy-note { padding: 16px 24px; background: linear-gradient(135deg, #fffbe6, #fff1b8); border-radius: 8px; margin: 16px 24px 0; font-size: 13px; color: #d48806; display: flex; align-items: center; gap: 8px; border: 1px solid #ffe58f; }
        
        /* 状态栏 */
        .status-bar { padding: 8px 24px; background: #fafafa; border-top: 1px solid #eee; font-size: 12px; color: #999; display: flex; justify-content: space-between; align-items: center; }
        .status-bar .ai-status { display: flex; align-items: center; gap: 4px; }
        .status-bar .dot { width: 8px; height: 8px; border-radius: 50%; background: #52c41a; animation: pulse 2s infinite; }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.5} }
        
        /* 错误提示 */
        .error-toast { position: fixed; top: 80px; right: 24px; padding: 12px 20px; background: #fff2f0; border: 1px solid #ffccc7; border-radius: 8px; color: #cf1322; font-size: 14px; z-index: 1000; animation: slideIn 0.3s; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        @keyframes slideIn { from{transform:translateX(100%);opacity:0} to{transform:none;opacity:1} }

        .streaming-message .sender .badge { background: #faad14; color: white; animation: pulse 1s infinite; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <div class="container" style="max-width:1100px;">
        <header class="page-header" style="padding:20px 0;">
            <h1>🤖 AI 树洞</h1>
            <p>基于大模型的智能心理陪伴 · 匿名倾诉你的心事</p>
        </header>

        <div class="chat-container">
            <!-- 左侧会话列表 -->
            <aside class="chat-sidebar">
                <div class="sidebar-header">
                    <h3>💬 对话记录</h3>
                    <button class="new-chat-btn" onclick="newChat()">+ 新对话</button>
                </div>
                <div class="chat-history" id="chatHistory">
                    <div style="text-align:center;padding:40px;color:#999;">
                        <div style="font-size:40px;margin-bottom:12px;">💬</div>
                        加载中...
                    </div>
                </div>
            </aside>

            <!-- 主聊天区域 -->
            <div class="chat-main">
                <div class="chat-messages" id="chatMessages">
                    <div class="message ai">
                        <div class="sender">🤖 AI 心灵伙伴</div>
                        <div id="welcomeMsg">正在连接AI服务...</div>
                    </div>
                </div>
                
                <div class="quick-prompts" id="quickPrompts">
                    <span class="quick-prompt" onclick="sendQuick('最近感觉学习压力很大，很焦虑，不知道该怎么办')">😰 学习压力大</span>
                    <span class="quick-prompt" onclick="sendQuick('和室友的关系让我很困扰，感觉被孤立了')">😔 人际关系困扰</span>
                    <span class="quick-prompt" onclick="sendQuick('最近总是睡不好，晚上失眠，白天没精神')">😴 失眠问题</span>
                    <span class="quick-prompt" onclick="sendQuick('对未来感到迷茫不知道该怎么办，感觉没有方向')">🤔 对未来迷茫</span>
                </div>

                <div class="typing-indicator" id="typingIndicator">
                    <span class="sender">🤖 AI 正在思考...</span>
                    <div class="dots"><span></span><span></span><span></div>
                </div>

                <div class="chat-input-area">
                    <textarea id="messageInput" placeholder="输入你想说的话... (Enter发送，Shift+Enter换行)" rows="1" onkeydown="handleKeydown(event)" oninput="autoResize(this)"></textarea>
                    <button class="send-btn" id="sendBtn" onclick="sendMessage()">
                        发送 <span>➤</span>
                    </button>
                </div>
            </div>
        </div>

        <div class="privacy-note">
            🔒 <b>隐私保护：</b>所有对话内容均加密存储，仅供你自己查看。AI助手基于专业心理咨询模型，但<strong>不能替代专业诊断</strong>。
        </div>
        
        <div class="status-bar">
            <div class="ai-status">
                <span class="dot"></span>
                <span id="aiProviderInfo">AI服务已就绪</span>
            </div>
            <div id="quotaInfo"></div>
        </div>
    </div>

    <script>
    // =====================================================
    // 配置与全局状态 - 使用JSP EL获取上下文路径
    // =====================================================
    var APP_CONTEXT = '<%= request.getContextPath() %>';
    var currentSessionId = null;
    var isGenerating = false;

    // =====================================================
    // 初始化
    // =====================================================
    document.addEventListener('DOMContentLoaded', function() {
        console.log('[Chat] Context Path:', APP_CONTEXT);
        loadSessions();
        loadLimitInfo();
        checkAIStatus();
        createNewSession();
    });

    // =====================================================
    // API请求封装 - 统一处理路径和错误
    // =====================================================
    function apiGet(path) {
        console.log('[API] GET:', APP_CONTEXT + path);
        return fetch(APP_CONTEXT + path).then(function(r) {
            if (!r.ok) throw new Error('HTTP ' + r.status);
            return r.json();
        });
    }

    function apiPost(path, data) {
        console.log('[API] POST:', APP_CONTEXT + path);
        return fetch(APP_CONTEXT + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: data
        }).then(function(r) {
            if (!r.ok) throw new Error('HTTP ' + r.status);
            return r.json();
        });
    }

    // =====================================================
    // 会话管理
    // =====================================================
    
    function loadSessions() {
        apiGet('/chat/sessions')
            .then(function(data) {
                if (data.code === 200 && data.data) {
                    renderSessionList(data.data);
                } else {
                    document.getElementById('chatHistory').innerHTML =
                        '<div style="text-align:center;padding:40px;color:#999;">暂无对话记录</div>';
                }
            })
            .catch(function(err) {
                console.error('[Chat] 加载会话列表失败:', err);
                showError('加载失败，请刷新重试');
            });
    }
    
    function renderSessionList(sessions) {
        var container = document.getElementById('chatHistory');
        
        if (!sessions || sessions.length === 0) {
            container.innerHTML = '<div style="text-align:center;padding:40px;color:#999;">暂无对话记录</div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < sessions.length; i++) {
            var session = sessions[i];
            var time = formatTime(session.createdAt);
            var activeClass = session.id === currentSessionId ? ' active' : '';
            var tagHtml = session.isHighRisk ? '<span class="tag">⚠️ 高危</span>' : '';
            
            html += '<div class="history-item' + activeClass + '" onclick="loadSession(' + session.id + ')">' +
                '<div class="title">' + tagHtml + escapeHtml(session.title) + '</div>' +
                '<div class="time">' + time + '</div>' +
                '</div>';
        }
        
        container.innerHTML = html;
    }
    
    function createNewSession() {
        return apiPost('/chat/session/create', '')
            .then(function(data) {
                if (data.code === 200) {
                    currentSessionId = data.data.sessionId;
                    
                    if (data.data.welcomeMessage) {
                        document.getElementById('welcomeMsg').innerHTML = formatMessage(data.data.welcomeMessage);
                    }
                    
                    console.log('[Chat] 创建会话成功:', currentSessionId);
                } else {
                    showError(data.message || '创建会话失败');
                }
            })
            .catch(function(err) {
                console.error('[Chat] 创建会话失败:', err);
                showError('网络错误，请检查连接');
            });
    }
    
    function newChat() {
        document.getElementById('chatMessages').innerHTML = '';
        currentSessionId = null;
        createNewSession();
        loadSessions();
    }
    
    function loadSession(sessionId) {
        if (isGenerating) return;
        
        currentSessionId = sessionId;
        
        var items = document.querySelectorAll('.history-item');
        for (var j = 0; j < items.length; j++) {
            items[j].classList.remove('active');
        }
        event.currentTarget.classList.add('active');
        
        document.getElementById('chatMessages').innerHTML = '<div style="text-align:center;color:#999;padding:20px;">加载中...</div>';
        
        apiGet('/chat/messages?sessionId=' + sessionId)
            .then(function(data) {
                if (data.code === 200 && data.data) {
                    renderMessages(data.data);
                }
            })
            .catch(function(err) {
                console.error('[Chat] 加载消息失败:', err);
                showError('加载消息失败');
            });
    }
    
    // =====================================================
    // 消息发送与渲染（核心）
    // =====================================================
    
    async function sendMessage() {
        if (isGenerating) return;
        
        var input = document.getElementById('messageInput');
        var msg = input.value.trim();
        if (!msg) return;
        if (!currentSessionId) {
            showError('请先等待会话创建完成');
            return;
        }
        
        input.value = '';
        autoResize(input);
        isGenerating = true;
        updateSendButton(true);
        
        addMessage(msg, 'user');
        showTypingIndicator(true);
        disableQuickPrompts(true);
        
        try {
            await sendWithStream(msg);
        } catch (err) {
            console.error('[Chat] 流式发送失败:', err);
            try {
                await sendWithoutStream(msg);
            } catch (err2) {
                console.error('[Chat] 降级也失败:', err2);
                addMessage('抱歉，AI服务暂时不可用。请稍后再试或联系管理员。', 'ai');
            }
        } finally {
            isGenerating = false;
            updateSendButton(false);
            showTypingIndicator(false);
            disableQuickPrompts(false);
            loadLimitInfo();
            loadSessions();
        }
    }
    
    /**
     * SSE流式发送 - 打字机效果
     */
    function sendWithStream(userMessage) {
        return new Promise(function(resolve, reject) {
            var formData = new URLSearchParams();
            formData.append('sessionId', currentSessionId);
            formData.append('message', userMessage);
            
            var aiMsgContainer = createStreamingMessage();
            var url = APP_CONTEXT + '/chat/stream?' + formData.toString();
            console.log('[Stream] URL:', url);
            
            fetch(url, {
                method: 'GET',
                headers: { 'Accept': 'text/event-stream' }
            }).then(function(response) {
                if (!response.body) {
                    reject(new Error('不支持流'));
                    return;
                }
                
                var reader = response.body.getReader();
                var decoder = new TextDecoder();
                var buffer = '';
                
                function read() {
                    reader.read().then(function(result) {
                        var done = result.done;
                        var value = result.value;
                        
                        if (done) {
                            finalizeStream(aiMsgContainer);
                            resolve();
                            return;
                        }
                        
                        buffer += decoder.decode(value, { stream: true });
                        
                        var lines = buffer.split('\n');
                        buffer = lines.pop() || '';
                        
                        for (var k = 0; k < lines.length; k++) {
                            var line = lines[k];
                            if (line.indexOf('data: ') === 0) {
                                var dataStr = line.substring(6).trim();
                                
                                if (dataStr === '[DONE]') {
                                    finalizeStream(aiMsgContainer);
                                    resolve();
                                    return;
                                }
                                
                                try {
                                    var parsed = JSON.parse(dataStr);
                                    
                                    if (parsed.error) {
                                        reject(new Error(parsed.error));
                                        return;
                                    }
                                    
                                    if (parsed.content) {
                                        appendToStream(aiMsgContainer, parsed.content);
                                    }
                                } catch (e) {
                                    if (e.message !== 'Unexpected end of JSON input') {
                                        reject(e);
                                        return;
                                    }
                                }
                            }
                        }
                        
                        read();
                    }).catch(reject);
                }
                
                read();
            }).catch(reject);
        });
    }
    
    /**
     * 非流式发送（降级方案）
     */
    function sendWithoutStream(userMessage) {
        var formData = new URLSearchParams();
        formData.append('sessionId', currentSessionId);
        formData.append('message', userMessage);
        
        return apiPost('/chat/send', formData.toString())
            .then(function(data) {
                if (data.code === 200) {
                    var reply = data.data.aiMessage;
                    
                    if (data.data.fallbackMessage) {
                        reply = data.data.fallbackMessage;
                    }
                    
                    addMessage(reply, 'ai');
                    
                    if (data.data.isHighRisk) {
                        addWarningBadge('⚠️ 已触发高危预警，专业人员将关注');
                    }
                } else {
                    throw new Error(data.message || '服务器返回错误');
                }
            });
    }
    
    /**
     * 创建流式消息容器
     */
    function createStreamingMessage() {
        var container = document.getElementById('chatMessages');
        
        var msgDiv = document.createElement('div');
        msgDiv.className = 'message ai streaming-message';
        msgDiv.innerHTML =
            '<div class="sender">' +
                '🤖 AI 心灵伙伴 ' +
                '<span class="badge">实时生成中</span>' +
            '</div>' +
            '<div class="content"></div>';
        
        container.appendChild(msgDiv);
        scrollToBottom();
        
        return msgDiv;
    }
    
    /**
     * 向流式消息追加内容
     */
    function appendToStream(container, text) {
        var contentEl = container.querySelector('.content');
        contentEl.innerHTML += escapeHtml(text);
        scrollToBottom();
    }
    
    /**
     * 完成流式输出
     */
    function finalizeStream(container) {
        container.classList.remove('streaming-message');
        var badge = container.querySelector('.badge');
        if (badge) badge.textContent = 'AI回复';
    }
    
    // =====================================================
    // UI辅助方法
    // =====================================================
    
    function addMessage(content, type) {
        var container = document.getElementById('chatMessages');
        var senderName = type === 'user' ? '我' : '🤖 AI 心灵伙伴';
        
        var msgDiv = document.createElement('div');
        msgDiv.className = 'message ' + type;
        msgDiv.innerHTML =
            '<div class="sender">' + senderName + '</div>' +
            '<div>' + formatMessage(content) + '</div>';
        
        container.appendChild(msgDiv);
        scrollToBottom();
    }
    
    function addWarningBadge(text) {
        var container = document.getElementById('chatMessages');
        var warning = document.createElement('div');
        warning.style.cssText = 'padding:12px;background:#fffbe6;border:1px solid #ffe58f;border-radius:8px;color:#d48806;font-size:13px;text-align:center;';
        warning.textContent = text;
        container.appendChild(warning);
        scrollToBottom();
    }
    
    function formatMessage(text) {
        return text
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\n/g, '<br>');
    }
    
    function showTypingIndicator(show) {
        var el = document.getElementById('typingIndicator');
        el.classList.toggle('show', show);
        if (show) scrollToBottom();
    }
    
    function updateSendButton(disabled) {
        var btn = document.getElementById('sendBtn');
        btn.disabled = disabled;
        btn.innerHTML = disabled ? '生成中...' : '发送 <span>➤</span>';
    }
    
    function disableQuickPrompts(disabled) {
        var prompts = document.querySelectorAll('.quick-prompt');
        for (var m = 0; m < prompts.length; m++) {
            prompts[m].style.pointerEvents = disabled ? 'none' : 'auto';
            prompts[m].style.opacity = disabled ? '0.5' : '1';
        }
    }
    
    function scrollToBottom() {
        var container = document.getElementById('chatMessages');
        requestAnimationFrame(function() {
            container.scrollTop = container.scrollHeight;
        });
    }
    
    function renderMessages(messages) {
        var container = document.getElementById('chatMessages');
        container.innerHTML = '';
        
        for (var n = 0; n < messages.length; n++) {
            var msg = messages[n];
            var type = msg.senderType === 'USER' ? 'user' : 'ai';
            var senderName = type === 'user' ? '我' : '🤖 AI 心灵伙伴';
            
            var msgDiv = document.createElement('div');
            msgDiv.className = 'message ' + type;

            var badgeHtml = '';
            if (type === 'ai' && msg.emotionTag) {
                badgeHtml = '<span class="badge">' + msg.emotionTag + '</span>';
            }

            msgDiv.innerHTML =
                '<div class="sender">' + senderName + ' ' + badgeHtml + '</div>' +
                '<div>' + formatMessage(msg.content) + '</div>';
            
            container.appendChild(msgDiv);
        }
        
        scrollToBottom();
    }
    
    function showError(message) {
        var existing = document.querySelectorAll('.error-toast');
        for (var p = 0; p < existing.length; p++) {
            existing[p].remove();
        }
        
        var toast = document.createElement('div');
        toast.className = 'error-toast';
        toast.textContent = message;
        document.body.appendChild(toast);
        
        setTimeout(function() { toast.remove(); }, 4000);
    }
    
    // =====================================================
    // 工具方法
    // =====================================================
    
    function sendQuick(text) {
        document.getElementById('messageInput').value = text;
        sendMessage();
    }
    
    function handleKeydown(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    }
    
    function autoResize(el) {
        el.style.height = 'auto';
        el.style.height = Math.min(el.scrollHeight, 120) + 'px';
    }
    
    function escapeHtml(text) {
        var div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML.replace(/\n/g, '<br>');
    }
    
    function formatTime(dateStr) {
        if (!dateStr) return '';
        var date = new Date(dateStr);
        var now = new Date();
        var diffMs = now - date;
        var diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) {
            return '今天 ' + date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
        } else if (diffDays === 1) {
            return '昨天 ' + date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
        } else if (diffDays < 7) {
            return diffDays + '天前';
        } else {
            return date.toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' }) + 
                   ' ' + date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
        }
    }
    
    async function loadLimitInfo() {
        try {
            var data = await apiGet('/chat/limit-info');
            if (data.code === 200 && data.data) {
                var info = data.data;
                document.getElementById('quotaInfo').textContent =
                    '今日剩余: ' + info.remaining + '/' + info.limit + ' 次';
            }
        } catch (err) {
            console.warn('[Chat] 加载限额信息失败:', err);
        }
    }
    
    async function checkAIStatus() {
        try {
            var info = await apiGet('/chat/limit-info');
            if (info.data && info.data.aiProvider) {
                var providerNames = {
                    'DOUBAO': '豆包(字节)',
                    'DEEPSEEK': 'DeepSeek',
                    'OPENAI': 'OpenAI',
                    'CUSTOM': '自定义'
                };
                document.getElementById('aiProviderInfo').textContent = 
                    'AI引擎: ' + (providerNames[info.data.aiProvider] || info.data.aiProvider);
            }
        } catch (e) {
            document.getElementById('aiProviderInfo').textContent = 'AI状态未知';
        }
    }
    </script>
</body>
</html>
