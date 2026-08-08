<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psychology.entity.User" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null || !"STUDENT".equals(user.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String scaleId = request.getParameter("scaleId");
    if (scaleId == null || scaleId.isEmpty()) {
        response.sendRedirect("assessment.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>正在测评 - 心理健康管理系统</title>
    <link rel="stylesheet" href="../css/common.css">
    <style>
        .assessment-container { max-width: 800px; margin: 0 auto; padding: 24px; }
        .scale-header { background: white; border-radius: 12px; padding: 24px; margin-bottom: 20px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .scale-header h1 { font-size: 22px; color: #333; margin-bottom: 8px; }
        .scale-header .instruction { color: #666; line-height: 1.7; font-size: 14px; }
        .scale-header .meta { display: flex; gap: 16px; margin-top: 12px; color: #999; font-size: 13px; }
        .progress-bar { background: #f0f0f0; border-radius: 10px; height: 8px; margin: 16px 0; overflow: hidden; }
        .progress-fill { background: linear-gradient(135deg, #667eea, #764ba2); height: 100%; border-radius: 10px; transition: width 0.3s; width: 0%; }
        .question-card { background: white; border-radius: 12px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .question-number { display: inline-block; background: #667eea; color: white; padding: 4px 12px; border-radius: 20px; font-size: 13px; margin-bottom: 12px; }
        .question-text { font-size: 16px; color: #333; margin-bottom: 16px; line-height: 1.6; }
        .options { display: flex; flex-direction: column; gap: 10px; }
        .option { display: flex; align-items: center; padding: 14px 20px; border: 2px solid #e8e8e8; border-radius: 10px; cursor: pointer; transition: all 0.15s ease; user-select: none; }
        .option:hover { border-color: #667eea; background: #f8f9ff; }
        .option.selected { border-color: #667eea; background: linear-gradient(135deg, #f0f5ff, #e8eeff); box-shadow: 0 2px 8px rgba(102,126,234,0.2); transform: scale(1.01); }
        .option-label { font-size: 15px; color: #444; font-weight: 500; }
        .option.selected .option-label { color: #667eea; font-weight: 600; }
        .btn-group { display: flex; justify-content: space-between; margin-top: 24px; }
        .btn { padding: 12px 32px; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; transition: all 0.2s; }
        .btn-prev { background: #f0f0f0; color: #666; }
        .btn-prev:hover { background: #e0e0e0; }
        .btn-next, .btn-submit { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .btn-next:hover, .btn-submit:hover { opacity: 0.9; transform: scale(1.02); }
        .btn:disabled { opacity: 0.5; cursor: not-allowed; }
        .loading { text-align: center; padding: 60px; color: #999; }
        .result-card { background: white; border-radius: 12px; padding: 32px; text-align: center; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .score-circle { width: 120px; height: 120px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px; font-size: 32px; font-weight: bold; color: white; }
        .score-low { background: #52c41a; }
        .score-medium { background: #faad14; }
        .score-high { background: #ff4d4f; }
        .result-title { font-size: 20px; margin-bottom: 12px; }
        .result-desc { color: #666; line-height: 1.7; margin-bottom: 24px; }
        .timer { position: fixed; top: 80px; right: 24px; background: white; padding: 12px 20px; border-radius: 8px; box-shadow: 0 2px 12px rgba(0,0,0,0.12); font-size: 14px; color: #667eea; font-weight: 500; z-index: 100; }
    </style>
</head>
<body>
    <%@ include file="../components/navbar.jsp" %>
    
    <main class="assessment-container">
        <div class="timer" id="timer">用时: 00:00</div>
        
        <div id="loadingState" class="loading">
            <p>正在加载测评题目...</p>
        </div>
        
        <div id="assessmentState" style="display:none;">
            <div class="scale-header">
                <h1 id="scaleName">--</h1>
                <div class="instruction" id="scaleInstruction">--</div>
                <div class="meta">
                    <span id="totalQuestions">--</span>
                    <span id="timeLimit">--</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" id="progressFill"></div>
                </div>
            </div>
            
            <div id="questionContainer"></div>
            
            <div class="btn-group">
                <button class="btn btn-prev" id="btnPrev" onclick="prevQuestion()" disabled>上一题</button>
                <button class="btn btn-next" id="btnNext" onclick="nextQuestion()">下一题</button>
                <button class="btn btn-submit" id="btnSubmit" onclick="submitAssessment()" style="display:none;">提交测评</button>
            </div>
        </div>
        
        <div id="resultState" style="display:none;">
            <div class="result-card">
                <div class="score-circle" id="scoreCircle">--</div>
                <div class="result-title" id="resultTitle">--</div>
                <div class="result-desc" id="resultDesc">--</div>
                <div style="display:flex; gap:12px; justify-content:center;">
                    <button class="btn btn-next" onclick="location.href='assessment.jsp'">返回测评中心</button>
                    <button class="btn btn-prev" onclick="location.href='assessment-history.jsp'">查看历史报告</button>
                </div>
            </div>
        </div>
    </main>

    <script>
        var CONTEXT_PATH = '${pageContext.request.contextPath}';
        var scaleId = '<%= scaleId %>';
        var questions = [];
        var answers = {};
        var currentIndex = 0;
        var startTime = Date.now();
        var timerInterval;
        var scaleInfo = {};
        var isNavigating = false; // 导航锁，防止重复跳转

        // 加载题目
        async function loadQuestions() {
            try {
                var resp = await fetch(CONTEXT_PATH + '/assessment/questions?scaleId=' + scaleId);
                var result = await resp.json();
                if (result.code !== 200) {
                    alert(result.message || '加载失败');
                    location.href = 'assessment.jsp';
                    return;
                }
                scaleInfo = result.data;
                questions = result.data.questions || [];
                
                // 如果数据库没有题目，使用内置题目
                if (questions.length === 0) {
                    loadBuiltInQuestions();
                }
                
                if (questions.length === 0) {
                    alert('该量表暂无题目');
                    location.href = 'assessment.jsp';
                    return;
                }
                renderHeader();
                renderQuestion(0);
                document.getElementById('loadingState').style.display = 'none';
                document.getElementById('assessmentState').style.display = 'block';
                startTimer();
            } catch (e) {
                console.error(e);
                alert('加载题目失败，请稍后重试');
            }
        }

        function loadBuiltInQuestions() {
            var code = scaleInfo.scaleCode || '';
            var builtIn = [];
            if (code === 'SDS' || code === 'PHQ9') {
                builtIn = [
                    {id:1, questionNo:1, content:'我觉得闷闷不乐，情绪低沉'},
                    {id:2, questionNo:2, content:'我觉得一天之中早晨最好'},
                    {id:3, questionNo:3, content:'我一阵阵哭出来或觉得想哭'},
                    {id:4, questionNo:4, content:'我晚上睡眠不好'},
                    {id:5, questionNo:5, content:'我吃得跟平常一样多'},
                    {id:6, questionNo:6, content:'我与异性密切接触时和以往一样感到愉快'},
                    {id:7, questionNo:7, content:'我发觉我的体重在下降'},
                    {id:8, questionNo:8, content:'我有便秘的苦恼'},
                    {id:9, questionNo:9, content:'我心跳比平时快'},
                    {id:10, questionNo:10, content:'我无缘无故地感到疲乏'},
                    {id:11, questionNo:11, content:'我的头脑跟平常一样清楚'},
                    {id:12, questionNo:12, content:'我觉得经常做的事情并没有困难'},
                    {id:13, questionNo:13, content:'我觉得不安而平静不下来'},
                    {id:14, questionNo:14, content:'我对将来抱有希望'},
                    {id:15, questionNo:15, content:'我比平常容易生气激动'},
                    {id:16, questionNo:16, content:'我觉得作出决定是容易的'},
                    {id:17, questionNo:17, content:'我觉得自己是个有用的人，有人需要我'},
                    {id:18, questionNo:18, content:'我的生活过得很有意思'},
                    {id:19, questionNo:19, content:'我认为如果我死了，别人会生活得好些'},
                    {id:20, questionNo:20, content:'平常感兴趣的事我仍然感兴趣'}
                ];
            } else if (code === 'SAS' || code === 'GAD7') {
                builtIn = [
                    {id:1, questionNo:1, content:'我觉得比平时容易紧张和着急'},
                    {id:2, questionNo:2, content:'我无缘无故地感到害怕'},
                    {id:3, questionNo:3, content:'我容易心里烦乱或觉得惊恐'},
                    {id:4, questionNo:4, content:'我觉得我可能将要发疯'},
                    {id:5, questionNo:5, content:'我觉得一切都很好，也不会发生什么不幸'},
                    {id:6, questionNo:6, content:'我手脚发抖打颤'},
                    {id:7, questionNo:7, content:'我因为头痛、头颈痛和背痛而苦恼'},
                    {id:8, questionNo:8, content:'我感觉容易衰弱和疲乏'},
                    {id:9, questionNo:9, content:'我觉得心平气和，并且容易安静坐着'},
                    {id:10, questionNo:10, content:'我觉得心跳得很快'},
                    {id:11, questionNo:11, content:'我因为一阵阵头晕而苦恼'},
                    {id:12, questionNo:12, content:'我有晕倒发作或觉得要晕倒似的'},
                    {id:13, questionNo:13, content:'我呼气吸气都感到很容易'},
                    {id:14, questionNo:14, content:'我手脚麻木和刺痛'},
                    {id:15, questionNo:15, content:'我因为胃痛和消化不良而苦恼'},
                    {id:16, questionNo:16, content:'我常常要小便'},
                    {id:17, questionNo:17, content:'我的手常常是干燥温暖的'},
                    {id:18, questionNo:18, content:'我脸红发热'},
                    {id:19, questionNo:19, content:'我容易入睡并且一夜睡得很好'},
                    {id:20, questionNo:20, content:'我做恶梦'}
                ];
            } else if (code === 'SCL90') {
                builtIn = [
                    {id:1, questionNo:1, content:'头痛'},
                    {id:2, questionNo:2, content:'神经过敏，心中不踏实'},
                    {id:3, questionNo:3, content:'头脑中有不必要的想法或字句盘旋'},
                    {id:4, questionNo:4, content:'头昏或昏倒'},
                    {id:5, questionNo:5, content:'对异性的兴趣减退'},
                    {id:6, questionNo:6, content:'对旁人责备求全'},
                    {id:7, questionNo:7, content:'感到别人能控制您的思想'},
                    {id:8, questionNo:8, content:'责怪别人制造麻烦'},
                    {id:9, questionNo:9, content:'忘记性大'},
                    {id:10, questionNo:10, content:'担心自己的衣饰整齐及仪态的端正'},
                    {id:11, questionNo:11, content:'容易烦恼和激动'},
                    {id:12, questionNo:12, content:'胸痛'},
                    {id:13, questionNo:13, content:'害怕空旷的场所或街道'},
                    {id:14, questionNo:14, content:'感到自己的精力下降，活动减慢'},
                    {id:15, questionNo:15, content:'想结束自己的生命'},
                    {id:16, questionNo:16, content:'听到旁人听不到的声音'},
                    {id:17, questionNo:17, content:'发抖'},
                    {id:18, questionNo:18, content:'感到大多数人都不可信任'},
                    {id:19, questionNo:19, content:'胃口不好'},
                    {id:20, questionNo:20, content:'容易哭泣'}
                ];
            }
            if (builtIn.length > 0) {
                questions = builtIn;
                scaleInfo.totalQuestions = builtIn.length;
            }
        }

        function renderHeader() {
            document.getElementById('scaleName').textContent = scaleInfo.scaleName || '心理测评';
            document.getElementById('scaleInstruction').textContent = scaleInfo.instruction || '请根据最近一周的实际感受回答以下问题。';
            document.getElementById('totalQuestions').textContent = '共 ' + questions.length + ' 题';
            document.getElementById('timeLimit').textContent = scaleInfo.timeLimit ? '建议用时 ' + scaleInfo.timeLimit + ' 分钟' : '';
        }

        function renderQuestion(index) {
            currentIndex = index;
            isNavigating = false;
            var q = questions[index];
            var container = document.getElementById('questionContainer');
            
            var optionsHtml = '';
            var options = [];
            
            // 根据量表类型生成选项
            if (scaleInfo.scaleCode === 'PHQ9' || scaleInfo.scaleCode === 'GAD7') {
                options = [
                    {val:0, text:'完全不会 (0分)'},
                    {val:1, text:'好几天 (1分)'},
                    {val:2, text:'一半以上天数 (2分)'},
                    {val:3, text:'几乎每天 (3分)'}
                ];
            } else if (scaleInfo.scaleCode === 'SCL90') {
                options = [
                    {val:1, text:'从无 (1分)'},
                    {val:2, text:'很轻 (2分)'},
                    {val:3, text:'中等 (3分)'},
                    {val:4, text:'偏重 (4分)'},
                    {val:5, text:'严重 (5分)'}
                ];
            } else {
                options = [
                    {val:1, text:'1分'},
                    {val:2, text:'2分'},
                    {val:3, text:'3分'},
                    {val:4, text:'4分'},
                    {val:5, text:'5分'}
                ];
            }
            
            for (var i = 0; i < options.length; i++) {
                var opt = options[i];
                var selected = answers[q.id] === opt.val ? 'selected' : '';
                // 纯 div 选项，不用 radio，用 data 属性存储值
                optionsHtml += '<div class="option ' + selected + '" data-val="' + opt.val + '" data-qid="' + q.id + '">' +
                    '<span class="option-label">' + opt.text + '</span>' +
                    '</div>';
            }
            
            container.innerHTML = '<div class="question-card">' +
                '<div class="question-number">第 ' + (index + 1) + ' / ' + questions.length + ' 题</div>' +
                '<div class="question-text">' + (q.content || q.questionNo + '.') + '</div>' +
                '<div class="options" id="optionsContainer">' + optionsHtml + '</div>' +
                '</div>';
            
            // 事件委托：只绑定一次，避免 label+radio 双重触发问题
            var optsContainer = document.getElementById('optionsContainer');
            if (optsContainer) {
                optsContainer.addEventListener('click', function(e) {
                    var optDiv = e.target.closest('.option');
                    if (!optDiv || isNavigating) return;
                    var qid = parseInt(optDiv.getAttribute('data-qid'));
                    var val = parseInt(optDiv.getAttribute('data-val'));
                    handleSelect(qid, val, optDiv);
                });
            }
            
            updateProgress();
            updateButtons();
        }

        // 处理选项点击（通过事件委托调用，只触发一次）
        function handleSelect(qid, val, clickedDiv) {
            if (isNavigating) return;
            isNavigating = true; // 立即加锁
            answers[qid] = val;
            
            // 1. 立即渲染选中效果
            var allOpts = document.querySelectorAll('.option');
            for (var i = 0; i < allOpts.length; i++) {
                allOpts[i].classList.remove('selected');
            }
            if (clickedDiv) {
                clickedDiv.classList.add('selected');
            }
            
            // 2. 如果不是最后一题，短暂延迟后跳转（让用户看到选中效果）
            if (currentIndex < questions.length - 1) {
                setTimeout(function() {
                    currentIndex++;
                    renderQuestion(currentIndex);
                }, 120);
            } else {
                // 最后一题，刷新显示选中状态即可
                renderQuestion(currentIndex);
                isNavigating = false;
            }
        }

        // 保留旧名兼容（已不再被 HTML 直接调用）
        function selectOption(qid, val) {
            handleSelect(qid, val, null);
        }

        function updateProgress() {
            var pct = ((currentIndex + 1) / questions.length) * 100;
            document.getElementById('progressFill').style.width = pct + '%';
        }

        function updateButtons() {
            document.getElementById('btnPrev').disabled = currentIndex === 0;
            var isLast = currentIndex === questions.length - 1;
            document.getElementById('btnNext').style.display = isLast ? 'none' : 'inline-block';
            document.getElementById('btnSubmit').style.display = isLast ? 'inline-block' : 'none';
        }

        function prevQuestion() {
            if (isNavigating) return;
            if (currentIndex > 0) {
                renderQuestion(currentIndex - 1);
            }
        }

        function nextQuestion() {
            if (isNavigating) return;
            if (currentIndex < questions.length - 1) {
                renderQuestion(currentIndex + 1);
            }
        }

        function startTimer() {
            timerInterval = setInterval(function() {
                var elapsed = Math.floor((Date.now() - startTime) / 1000);
                var m = Math.floor(elapsed / 60);
                var s = elapsed % 60;
                document.getElementById('timer').textContent = '用时: ' + 
                    (m < 10 ? '0' + m : m) + ':' + (s < 10 ? '0' + s : s);
            }, 1000);
        }

        async function submitAssessment() {
            // 检查未作答的题目，默认给0分
            var unanswered = 0;
            for (var i = 0; i < questions.length; i++) {
                if (answers[questions[i].id] === undefined) {
                    answers[questions[i].id] = 0;
                    unanswered++;
                }
            }
            if (unanswered > 0) {
                // 只提示，不阻止提交
                alert('提示：您有 ' + unanswered + ' 题未作答，已按最低分计算，仍可提交。');
            }
            clearInterval(timerInterval);
            
            // 构建答案JSON
            var answersJson = {};
            for (var i = 0; i < questions.length; i++) {
                answersJson[questions[i].questionNo] = answers[questions[i].id] || 0;
            }
            
            try {
                var btn = document.getElementById('btnSubmit');
                btn.disabled = true;
                btn.textContent = '提交中...';
                
                var resp = await fetch(CONTEXT_PATH + '/assessment/submit', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'scaleId=' + scaleId + '&answers=' + encodeURIComponent(JSON.stringify(answersJson)) + 
                         '&startTime=' + startTime
                });
                var result = await resp.json();
                
                if (result.code === 200) {
                    showResult(result.data);
                } else {
                    alert(result.message || '提交失败');
                    btn.disabled = false;
                    btn.textContent = '提交测评';
                }
            } catch (e) {
                console.error(e);
                alert('提交失败，请稍后重试');
                document.getElementById('btnSubmit').disabled = false;
                document.getElementById('btnSubmit').textContent = '提交测评';
            }
        }

        function showResult(data) {
            document.getElementById('assessmentState').style.display = 'none';
            document.getElementById('timer').style.display = 'none';
            document.getElementById('resultState').style.display = 'block';
            
            var score = data.totalScore;
            var level = data.riskLevel;
            var circle = document.getElementById('scoreCircle');
            var title = document.getElementById('resultTitle');
            var desc = document.getElementById('resultDesc');
            
            circle.textContent = score + '分';
            if (level === 'HIGH') {
                circle.className = 'score-circle score-high';
                title.textContent = '高风险 - 建议尽快咨询';
                desc.textContent = '您的测评结果显示存在一定的心理困扰，建议尽快预约心理咨询师进行专业评估。您可以通过本系统的预约功能或联系学校心理中心获取帮助。';
            } else if (level === 'MEDIUM') {
                circle.className = 'score-circle score-medium';
                title.textContent = '中风险 - 建议关注';
                desc.textContent = '您的测评结果显示存在一定的心理困扰，建议适当关注自身情绪变化，可以尝试与信任的人倾诉，或通过本系统的AI树洞进行初步交流。如有持续困扰，建议预约咨询。';
            } else {
                circle.className = 'score-circle score-low';
                title.textContent = '低风险 - 状态良好';
                desc.textContent = '您的测评结果显示心理状态良好，请继续保持积极乐观的心态。建议定期进行心理测评，关注自身心理健康。';
            }
            
            if (data.isSuspicious) {
                desc.innerHTML += '<br><br><span style="color:#faad14;">⚠️ ' + (data.suspiciousReason || '答题异常') + '</span>';
            }
        }

        loadQuestions();
    </script>
</body>
</html>
