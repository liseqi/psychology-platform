<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>登录 - 心理健康管理系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            min-height: 100vh;
            overflow: hidden;
        }

        /* ====== 主容器 - Grid两栏布局 (6:4) ====== */
        .main-container {
            display: grid;
            grid-template-columns: 60% 40%;
            width: 100%;
            min-height: 100vh;
        }

        /* ====== 左侧面板 - 动画角色区域 ====== */
        .left-panel {
            background: linear-gradient(135deg, 
                #d4a574 0%, 
                #c9956c 20%, 
                #b8866b 40%, 
                #c9a078 70%, 
                #d4b08a 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
        }

        /* 动态背景光效 */
        .left-panel::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: 
                radial-gradient(ellipse at 25% 35%, rgba(255,230,190,0.4) 0%, transparent 45%),
                radial-gradient(ellipse at 75% 65%, rgba(200,150,100,0.3) 0%, transparent 40%),
                radial-gradient(ellipse at 50% 15%, rgba(240,200,150,0.35) 0%, transparent 50%);
            animation: bgGlow 12s ease-in-out infinite alternate;
        }

        @keyframes bgGlow {
            0% { opacity: 0.8; transform: scale(1); }
            100% { opacity: 1; transform: scale(1.03); }
        }

        /* 角色场景容器 */
        .scene {
            position: relative;
            width: 400px;
            height: 380px;
            z-index: 2;
        }

        /* ========== 角色通用样式 ========== */
        .character {
            position: absolute;
            transition: all 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);
        }

        /* 眼睛容器 */
        .eyes {
            position: absolute;
            display: flex;
            gap: 18px;
        }
        
        .eye {
            width: 16px;
            height: 22px;
            background: white;
            border-radius: 50%;
            position: relative;
            overflow: hidden;
        }

        .pupil {
            width: 8px;
            height: 10px;
            background: #1a1a2e;
            border-radius: 50%;
            position: absolute;
            top: 7px;
            left: 4px;
            transition: all 0.2s ease;
        }

        /* 眨眼动画 */
        @keyframes blink {
            0%, 94%, 98%, 100% { transform: scaleY(1); }
            96% { transform: scaleY(0.05); }
        }

        .eye.blinking {
            animation: blink 4s ease-in-out infinite;
        }

        .eye.blinking .pupil {
            animation: none;
        }

        /* ========== 蓝色/紫色方块角色 ========== */
        .character-purple {
            width: 95px;
            height: 125px;
            background: linear-gradient(145deg, #5b6ec9, #4a5bb8);
            border-radius: 14px 14px 22px 22px;
            left: 75px;
            bottom: 115px;
            animation: floatPurple 4s ease-in-out infinite;
            box-shadow: 8px 10px 28px rgba(0,0,0,0.16);
            transform-origin: center bottom;
        }

        .character-purple .eyes {
            top: 38px;
            left: 22px;
        }

        @keyframes floatPurple {
            0%, 100% { transform: translateY(0) rotate(-1.5deg); }
            50% { transform: translateY(-13px) rotate(1deg); }
        }

        /* ========== 黑色高瘦角色 ========== */
        .character-black {
            width: 58px;
            height: 140px;
            background: linear-gradient(145deg, #3d3d45, #2d2d35);
            border-radius: 16px;
            left: 178px;
            bottom: 105px;
            animation: floatBlack 4s ease-in-out infinite 0.4s;
            box-shadow: 8px 10px 26px rgba(0,0,0,0.22);
            transform-origin: center bottom;
        }

        .character-black .eyes {
            top: 32px;
            left: 11px;
            gap: 14px;
        }

        .character-black .eye {
            width: 14px;
            height: 19px;
        }

        @keyframes floatBlack {
            0%, 100% { transform: translateY(0) rotate(0.8deg); }
            50% { transform: translateY(-10px) rotate(-0.6deg); }
        }

        /* ========== 黄色圆脸角色 ========== */
        .character-yellow {
            width: 105px;
            height: 110px;
            background: linear-gradient(145deg, #f0c73e, #deb432);
            border-radius: 52px 52px 48px 48px;
            left: 248px;
            bottom: 82px;
            animation: floatYellow 4s ease-in-out infinite 0.9s;
            box-shadow: 10px 12px 30px rgba(0,0,0,0.15);
            transform-origin: center bottom;
        }

        .character-yellow .eyes {
            top: 36px;
            left: 26px;
        }

        .character-yellow .eye {
            width: 12px;
            height: 15px;
            background: #1a1a2e;
        }

        .character-yellow .mouth {
            position: absolute;
            width: 22px;
            height: 10px;
            border-bottom: 3px solid #1a1a2e;
            border-radius: 0 0 11px 11px;
            bottom: 30px;
            left: 41px;
            transition: all 0.4s ease;
        }

        @keyframes floatYellow {
            0%, 100% { transform: translateY(0) rotate(1.2deg); }
            50% { transform: translateY(-9px) rotate(-0.8deg); }
        }

        /* ========== 橙色半圆角色 ========== */
        .character-orange {
            width: 120px;
            height: 100px;
            background: linear-gradient(145deg, #e88f39, #d97c27);
            border-radius: 60px 60px 0 0;
            left: 28px;
            bottom: 28px;
            animation: floatOrange 4.5s ease-in-out infinite 0.2s;
            box-shadow: 8px 14px 28px rgba(0,0,0,0.17);
            transform-origin: center bottom;
        }

        .character-orange .eyes {
            top: 46px;
            left: 32px;
        }

        .character-orange .eye {
            width: 11px;
            height: 14px;
            background: #1a1a2e;
        }

        @keyframes floatOrange {
            0%, 100% { transform: translateY(0) scale(1); }
            50% { transform: translateY(-7px) scale(1.02); }
        }

        /* ========== 装饰元素 ========== */
        .deco-dot {
            position: absolute;
            border-radius: 50%;
            background: rgba(255,255,255,0.5);
            animation: dotPulse 3s ease-in-out infinite;
        }
        .dot-1 { width: 8px; height: 8px; top: 55px; right: 75px; animation-delay: 0s; }
        .dot-2 { width: 6px; height: 6px; top: 115px; right: 135px; animation-delay: 1s; }
        .dot-3 { width: 5px; height: 5px; top: 85px; right: 105px; animation-delay: 2s; }

        @keyframes dotPulse {
            0%, 100% { opacity: 0.2; transform: scale(1); }
            50% { opacity: 0.7; transform: scale(1.4); }
        }

        .brand-text {
            position: absolute;
            bottom: 32px;
            left: 50%;
            transform: translateX(-50%);
            color: rgba(255,255,255,0.72);
            font-size: 13px;
            letter-spacing: 3px;
            z-index: 3;
            text-transform: uppercase;
            font-weight: 500;
        }

        /* ====== 右侧面板 - 登录表单 ====== */
        .right-panel {
            background: linear-gradient(to bottom, 
                #faf9f4 0%, 
                #f5f3ed 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 56px 48px;
        }

            .login-wrapper {
                width: 100%;
                max-width: 340px;
            }

            /* Logo */
            .logo-icon {
                width: 64px;
                height: 64px;
                border-radius: 18px;
                object-fit: cover;
                margin: 0 auto 18px;
                display: block;
                box-shadow: 0 6px 20px rgba(91, 110, 201, 0.18);
            }

            /* 标题 */
            .welcome-header {
                margin-bottom: 34px;
                text-align: center;
            }

        .welcome-header h1 {
            font-size: 27px;
            color: #222;
            font-weight: 700;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }

        .welcome-header p {
            color: #999;
            font-size: 13px;
            letter-spacing: 0.5px;
        }

        /* 表单 */
        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            color: #444;
            margin-bottom: 7px;
            text-transform: uppercase;
            letter-spacing: 0.8px;
        }

        .input-wrap {
            position: relative;
        }

        .form-group input[type="text"],
        .form-group input[type="password"] {
            width: 100%;
            padding: 13px 42px 13px 15px;
            border: 1.5px solid #ddd;
            border-radius: 8px;
            font-size: 14px;
            background: white;
            color: #333;
            transition: all 0.3s ease;
            outline: none;
        }

        .form-group input::placeholder {
            color: #bbb;
            font-style: italic;
        }

        .form-group input:focus {
            border-color: #5b6ec9;
            box-shadow: 0 0 0 3px rgba(91,110,201,0.1);
        }

        /* 密码切换按钮 */
        .toggle-pwd {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            cursor: pointer;
            font-size: 15px;
            padding: 4px;
            color: #999;
            line-height: 1;
            transition: color 0.3s;
        }
        .toggle-pwd:hover { color: #666; }

        /* 记住我 & 忘记密码 */
        .form-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            font-size: 12.5px;
        }

        .remember-label {
            display: flex;
            align-items: center;
            gap: 6px;
            color: #666;
            cursor: pointer;
            user-select: none;
        }
        .remember-label input { accent-color: #5b6ec9; cursor: pointer; }

        .forgot-link {
            color: #5b6ec9;
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s;
        }
        .forgot-link:hover { color: #4a5bb8; text-decoration: underline; }

        /* 登录按钮 */
        .btn-login {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #3a3a43, #2a2a33);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 14.5px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
            letter-spacing: 1.5px;
            position: relative;
            overflow: hidden;
            margin-bottom: 14px;
        }

        .btn-login:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(58,58,67,0.35);
        }

        .btn-login:active:not(:disabled) { transform: translateY(0); }
        .btn-login:disabled { opacity: 0.7; cursor: not-allowed; }

        /* 分割线 */
        .divider {
            display: flex;
            align-items: center;
            gap: 14px;
            margin: 20px 0;
            color: #aaa;
            font-size: 12px;
        }
        .divider::before, .divider::after {
            content: '';
            flex: 1;
            height: 1px;
            background: linear-gradient(to right, transparent, #ddd, transparent);
        }

        /* 注册链接 */
        .btn-register {
            display: block;
            width: 100%;
            padding: 13px;
            background: transparent;
            color: #5b6ec9;
            border: 1.5px solid #5b6ec9;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            text-align: center;
            text-decoration: none;
            transition: all 0.3s;
            letter-spacing: 0.5px;
        }
        .btn-register:hover {
            background: rgba(91,110,201,0.06);
            transform: translateY(-1px);
            box-shadow: 0 4px 14px rgba(91,110,201,0.15);
        }

        /* 底部提示 */
        .signup-note {
            text-align: center;
            margin-top: 22px;
            font-size: 12.5px;
            color: #888;
        }
        .signup-note a {
            color: #5b6ec9;
            text-decoration: none;
            font-weight: 500;
        }
        .signup-note a:hover { text-decoration: underline; }

        /* 错误提示 */
        .error-box {
            background: linear-gradient(135deg, #fee2e2, #fecaca);
            color: #dc2626;
            padding: 11px 15px;
            border-radius: 8px;
            margin-bottom: 18px;
            display: none;
            font-size: 12.5px;
            border: 1px solid #fca5a5;
        }

        /* ========== 角色交互状态类 ========== */
        /* 输入用户名时 - 角色互相对视 */
        .scene.username-focus .character-purple,
        .scene.username-focus .character-black,
        .scene.username-focus .character-yellow,
        .scene.username-focus .character-orange {
            transform: translateY(-5px);
        }

        .scene.username-focus .character-purple .pupil,
        .scene.username-focus .character-black .pupil {
            transform: translateX(4px);
        }
        .scene.username-focus .character-yellow .pupil,
        .scene.username-focus .character-orange .pupil {
            transform: translateX(-4px);
        }

        /* 输入密码时 - 角色转头回避（保护隐私） */
        .scene.password-focus .character-purple {
            transform: translateY(-3px) rotate(-8deg);
        }
        .scene.password-focus .character-black {
            transform: translateY(-3px) rotate(6deg);
        }
        .scene.password-focus .character-yellow {
            transform: translateY(-3px) rotate(-5deg);
        }
        .scene.password-focus .character-orange {
            transform: translateY(-3px) rotate(5deg);
        }

        /* 显示密码时 - 偷看效果 */
        .scene.password-visible .character-purple .pupil {
            transform: translateX(6px) !important;
        }

        /* 登录失败 - 沮丧摇头 */
        .scene.login-error .character-purple {
            animation: shakeHead 0.6s ease;
        }
        .scene.login-error .character-black {
            animation: shakeHead 0.6s ease 0.1s;
        }
        .scene.login-error .character-yellow {
            animation: shakeHead 0.6s ease 0.2s;
        }
        .scene.login-error .character-yellow .mouth {
            border-radius: 11px 11px 0 0;
            border-top: 3px solid #1a1a2e;
            border-bottom: none;
            height: 6px;
            bottom: 37px;
        }

        @keyframes shakeHead {
            0%, 100% { transform: rotate(0); }
            20% { transform: rotate(-12deg); }
            40% { transform: rotate(10deg); }
            60% { transform: rotate(-8deg); }
            80% { transform: rotate(6deg); }
        }

        /* ========== 响应式适配 ========== */
        @media (max-width: 1024px) {
            .main-container { grid-template-columns: 55% 45%; }
            .scene { transform: scale(0.85); }
        }

        @media (max-width: 768px) {
            .main-container {
                grid-template-columns: 1fr;
                grid-template-rows: auto 1fr;
            }
            .left-panel {
                order: 2;
                min-height: 260px;
            }
            .right-panel { order: 1; padding: 36px 24px; }
            .scene { transform: scale(0.55); }
            .brand-text { display: none; }
        }
    </style>
</head>
<body>

<div class="main-container">

    <!-- 左侧：动画角色区域 (60%) -->
    <div class="left-panel">
        <div class="scene" id="scene">
            <!-- 装饰小点 -->
            <div class="deco-dot dot-1"></div>
            <div class="deco-dot dot-2"></div>
            <div class="deco-dot dot-3"></div>

            <!-- 橙色半圆 -->
            <div class="character character-orange">
                <div class="eyes">
                    <div class=" eye blinking"><div class="pupil orange-pupil"></div></div>
                    <div class=" eye blinking"><div class="pupil orange-pupil"></div></div>
                </div>
            </div>

            <!-- 蓝紫色方块 -->
            <div class="character character-purple">
                <div class="eyes">
                    <div class=" eye blinking"><div class="pupil purple-pupil"></div></div>
                    <div class=" eye blinking"><div class="pupil purple-pupil"></div></div>
                </div>
            </div>

            <!-- 黑色高瘦 -->
            <div class="character character-black">
                <div class="eyes">
                    <div class=" eye blinking"><div class="pupil black-pupil"></div></div>
                    <div class=" eye blinking"><div class="pupil black-pupil"></div></div>
                </div>
            </div>

            <!-- 黄色圆脸 -->
            <div class="character character-yellow">
                <div class="eyes">
                    <div class=" eye"><div class="pupil yellow-pupil"></div></div>
                    <div class=" eye"><div class="pupil yellow-pupil"></div></div>
                </div>
                <div class="mouth"></div>
            </div>
        </div>
        <div class="brand-text">心理健康管理系统</div>
    </div>

    <!-- 右侧：登录表单 (40%) -->
    <div class="right-panel">
        <div class="login-wrapper">
            <div class="welcome-header">
                <img src="assets/images/mental-health-logo.png" alt="心理健康 Logo" class="logo-icon">
                <h1>欢迎回来！</h1>
                <p>请输入您的账户信息登录系统</p>
            </div>

            <div id="errorMsg" class="error-box"></div>

            <form id="loginForm" onsubmit="handleLogin(event)">
                <div class="form-group">
                    <label for="username">用户名</label>
                    <div class="input-wrap">
                        <input type="text" id="username" placeholder="请输入用户名" required autocomplete="username">
                    </div>
                </div>

                <div class="form-group">
                    <label for="password">密码</label>
                    <div class="input-wrap">
                        <input type="password" id="password" placeholder="输入密码" required autocomplete="current-password">
                        <button type="button" class="toggle-pwd" onclick="togglePassword()" title="显示/隐藏密码">👁</button>
                    </div>
                </div>

                <div class="form-row">
                    <label class="remember-label">
                        <input type="checkbox" id="remember"> 记住我
                    </label>
                    <a href="forgot-password.jsp" class="forgot-link">忘记密码?</a>
                </div>

                <button type="submit" class="btn-login" id="submitBtn">登 录</button>
            </form>

            <div class="divider">或</div>

            <a href="register.jsp" class="btn-register">注册新账号</a>

            <div class="signup-note">
                还没有账户? <a href="register.jsp">立即注册</a>
            </div>
        </div>
    </div>

</div>

<script>
// ========== 角色交互动画逻辑 ==========
(function() {
    var scene = document.getElementById('scene');
    var usernameInput = document.getElementById('username');
    var passwordInput = document.getElementById('password');
    
    // 所有瞳孔
    var pupils = document.querySelectorAll('.pupil');
    // 紫色和黑色角色的眼睛（用于眨眼）
    var blinkingEyes = document.querySelectorAll('.eye.blinking');

    // ---------- 1. 眼睛跟随鼠标 ----------
    document.addEventListener('mousemove', function(e) {
        var sceneRect = scene.getBoundingClientRect();
        var centerX = sceneRect.left + sceneRect.width / 2;
        var centerY = sceneRect.top + sceneRect.height / 2;

        var deltaX = e.clientX - centerX;
        var deltaY = e.clientY - centerY;

        // 归一化并限制移动范围
        var maxMove = 5;
        var moveX = Math.max(-maxMove, Math.min(maxMove, deltaX / 60));
        var moveY = Math.max(-3, Math.min(3, deltaY / 80));

        pupils.forEach(function(pupil) {
            if (!document.body.classList.contains('typing')) {
                pupil.style.transform = 'translate(' + moveX + 'px, ' + moveY + 'px)';
            }
        });
    });

    // ---------- 2. 输入框焦点检测 ----------
    usernameInput.addEventListener('focus', function() {
        scene.classList.add('username-focus');
        scene.classList.remove('password-focus', 'password-visible');
        document.body.classList.add('typing');
    });

    usernameInput.addEventListener('blur', function() {
        scene.classList.remove('username-focus');
        document.body.classList.remove('typing');
    });

    passwordInput.addEventListener('focus', function() {
        scene.classList.add('password-focus');
        scene.classList.remove('username-focus');
        document.body.classList.add('typing');
    });

    passwordInput.addEventListener('blur', function() {
        scene.classList.remove('password-focus', 'password-visible');
        document.body.classList.remove('typing');
    });

    // ---------- 3. 随机眨眼 ----------
    function randomBlink() {
        if (blinkingEyes.length === 0) return;
        var randomEye = blinkingEyes[Math.floor(Math.random() * blinkingEyes.length)];
        randomEye.style.animation = 'none';
        void randomEye.offsetWidth; // 强制重绘
        randomEye.style.animation = 'blink 0.3s ease';
        setTimeout(function() {
            randomEye.style.animation = '';
        }, 300);

        // 随机间隔下一次眨眼
        setTimeout(randomBlink, 2500 + Math.random() * 3500);
    }
    setTimeout(randomBlink, 1500);
})();

// ========== 密码显示切换 ==========
function togglePassword() {
    var pwdInput = document.getElementById('password');
    var btn = document.querySelector('.toggle-pwd');
    var scene = document.getElementById('scene');

    if (pwdInput.type === 'password') {
        pwdInput.type = 'text';
        btn.textContent = '🔒';
        scene.classList.add('password-visible'); // 角色偷看
    } else {
        pwdInput.type = 'password';
        btn.textContent = '👁';
        scene.classList.remove('password-visible');
    }
}

// ========== 登录处理 ==========
var CONTEXT_PATH = '${pageContext.request.contextPath}';

async function handleLogin(e) {
    e.preventDefault();

    var username = document.getElementById('username').value.trim();
    var password = document.getElementById('password').value;
    var submitBtn = document.getElementById('submitBtn');
    var scene = document.getElementById('scene');

    if (!username || !password) {
        showError('请填写用户名和密码');
        triggerErrorAnimation();
        return;
    }

    submitBtn.disabled = true;
    submitBtn.textContent = '登 录 中...';

    try {
        var response = await fetch(CONTEXT_PATH + '/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'username=' + encodeURIComponent(username) + '&password=' + encodeURIComponent(password)
        });

        var result = await response.json();

        if (result.code === 200) {
            window.location.href = CONTEXT_PATH + (result.data || '/student/dashboard.jsp');
        } else {
            showError(result.message || '登录失败，请检查账户信息');
            triggerErrorAnimation();
            submitBtn.disabled = false;
            submitBtn.textContent = '登 录';
        }
    } catch (err) {
        showError('网络错误，请稍后重试');
        triggerErrorAnimation();
        submitBtn.disabled = false;
        submitBtn.textContent = '登 录';
    }
}

function showError(msg) {
    var errorBox = document.getElementById('errorMsg');
    errorBox.textContent = msg;
    errorBox.style.display = 'block';
    setTimeout(function() { errorBox.style.display = 'none'; }, 5000);
}

function triggerErrorAnimation() {
    var scene = document.getElementById('scene');
    scene.classList.add('login-error');
    setTimeout(function() { scene.classList.remove('login-error'); }, 800);
}
</script>

</body>
</html>
