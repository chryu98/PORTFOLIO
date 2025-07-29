/**
 * 
 */

/**
 * BNK Chatbot Modal
 * - Detects & builds once
 * - Supports multiple root placeholders safely
 * - Escalates to human chat after repeated apology responses
 * - Brand colored (see CSS)
 *
 * Config via root data-* attributes:
 *   data-placement="right" | "left"  (default: right)
 *   data-backend-local="http://localhost:8000"
 *   data-backend-remote="http://192.168.0.5:8000"
 *   data-human-url="/user/chat/page"
 */
(function(){
  if (window.__BNK_CHATBOT_INITIALIZED__) {
    console.warn('[BNK Chatbot] Already initialized. Skipping.');
    return;
  }
  window.__BNK_CHATBOT_INITIALIZED__ = true;

  /* ----- Root Detection ----- */
  // 다수 페이지에서 fragment가 중복 include되더라도 하나만 사용
  const roots = document.querySelectorAll('#bnkChatbotRoot');
  let root = null;

  if (roots.length > 1) {
    console.warn('[BNK Chatbot] Multiple roots detected, using last and hiding older ones.');
    roots.forEach((el, idx) => {
      if (idx < roots.length - 1) {
        el.style.display = 'none'; // 삭제 대신 숨김 처리
      }
    });
    root = roots[roots.length - 1]; // 마지막 것 사용
  } else if (roots.length === 1) {
    root = roots[0];
  }

  if (!root) {
    // Graceful fallback: body 끝에 root 생성
    root = document.createElement('div');
    root.id = 'bnkChatbotRoot';
    document.body.appendChild(root);
  }

  /* ----- Config ----- */
  const placement   = root.dataset.placement || 'right';
  const backendHost = (location.hostname === 'localhost')
        ? (root.dataset.backendLocal  || 'http://localhost:8000')
        : (root.dataset.backendRemote || 'http://192.168.0.5:8000');
  const humanUrl = root.dataset.humanUrl || '/user/chat/page';

  /* ----- Build Markup (if not already) ----- */
  // 중복 방지: 이미 생성됐다면 skip
  if (!document.getElementById('bnkCbOverlay')) {
    root.insertAdjacentHTML('beforeend', `
      <div class="bnk-cb-fab ${placement}" id="bnkCbFab" role="button"
           aria-haspopup="dialog" aria-controls="bnkCbModal" tabindex="0"
           title="부산은행 챗봇 열기">🤖</div>

      <div id="bnkCbOverlay" role="presentation" aria-hidden="true">
        <div id="bnkCbModal" role="dialog" aria-modal="true" aria-labelledby="bnkCbModalTitle">
          <button id="bnkCbCloseBtn" aria-label="닫기">×</button>
          <h2 id="bnkCbModalTitle">부산은행 챗봇</h2>

          <div class="bnk-cb-form">
            <input type="text" id="bnkCbQuestion" placeholder="질문을 입력하세요">
            <button id="bnkCbAskBtn" type="button">질문하기</button>
          </div>

          <div class="bnk-cb-answer-wrapper">
            <h3>챗봇 답변:</h3>
            <div id="bnkCbAnswer"></div>
          </div>

          <div id="bnkCbEscalationBox">
            <div class="esc-msg">필요하시면 상담사에게 연결해 드릴까요?</div>
            <button type="button" id="bnkCbGoHumanBtn">상담사 채팅으로 이동</button>
          </div>
        </div>
      </div>
    `);
  }

  /* ----- Element refs ----- */
  const fabEl   = document.getElementById('bnkCbFab');
  const overlay = document.getElementById('bnkCbOverlay');
  const modal   = document.getElementById('bnkCbModal');
  const closeEl = document.getElementById('bnkCbCloseBtn');
  const qEl     = document.getElementById('bnkCbQuestion');
  const askEl   = document.getElementById('bnkCbAskBtn');
  const ansEl   = document.getElementById('bnkCbAnswer');
  const escEl   = document.getElementById('bnkCbEscalationBox');
  const goEl    = document.getElementById('bnkCbGoHumanBtn');

  if (!fabEl || !overlay || !modal) {
    console.error('[BNK Chatbot] Required elements missing after build. Abort.');
    return;
  }

  /* ----- State ----- */
  let isSending = false;
  let apologyCount = 0;
  const APOLOGY_REGEX = /(죄송|사과드립|도움\s*드리기\s*어렵|답변드리기\s*어렵|확인\s*후\s*답변)/i;

  /* ----- Focus trap support ----- */
  let lastFocused = null;
  function trapFocus(container){
    lastFocused = document.activeElement;
    const focusables = container.querySelectorAll(
      'button,[href],input,select,textarea,[tabindex]:not([tabindex="-1"])'
    );
    if (!focusables.length) return;
    const first = focusables[0];
    const last = focusables[focusables.length - 1];

    function cycle(e){
      if (e.key !== 'Tab') return;
      if (e.shiftKey) {
        if (document.activeElement === first) {
          e.preventDefault(); last.focus();
        }
      } else {
        if (document.activeElement === last) {
          e.preventDefault(); first.focus();
        }
      }
    }
    container.addEventListener('keydown', cycle);
    container._cbCycle = cycle;
  }
  function releaseFocusTrap(){
    if (modal._cbCycle) {
      modal.removeEventListener('keydown', modal._cbCycle);
      delete modal._cbCycle;
    }
    if (lastFocused) lastFocused.focus();
    lastFocused = null;
  }

  /* ----- Open/Close ----- */
  function openModal(){
    overlay.style.display = 'flex';
    overlay.setAttribute('aria-hidden','false');
    setTimeout(() => { if (qEl) qEl.focus(); }, 50);
    trapFocus(modal);
	if (!ansEl.textContent || ansEl.textContent.trim() === '') {
	   ansEl.textContent = "안녕하세요! 도우미 챗봇 부뱅이입니다. 무엇을 도와드릴까요?";
	 }
  }
  function closeModal(){
    overlay.style.display = 'none';
    overlay.setAttribute('aria-hidden','true');
    releaseFocusTrap();
    fabEl.focus();
  }

  // 전역 노출 (디버그 및 inline fallback)
  window.__BNK_CHATBOT_OPEN__  = openModal;
  window.__BNK_CHATBOT_CLOSE__ = closeModal;

  /* ----- Event wiring ----- */
  // FAB click
  fabEl.addEventListener('click', openModal);
  fabEl.addEventListener('keydown', e=>{
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault(); openModal();
    }
  });
  // Close
  closeEl && closeEl.addEventListener('click', closeModal);
  // Overlay click outside
  overlay.addEventListener('mousedown', e=>{
    if (e.target === overlay) closeModal();
  });
  // ESC
  document.addEventListener('keydown', e=>{
    if (e.key === 'Escape' && overlay.style.display === 'flex') closeModal();
  });

  // Ask
  askEl && askEl.addEventListener('click', ask);
  qEl && qEl.addEventListener('keydown', e=>{
    if (e.key === 'Enter') {
      e.preventDefault();
      ask();
    }
  });

  // Human Chat
  goEl && goEl.addEventListener('click', goHuman);

  /* ----- Ask Bot ----- */
  function ask(){
    if (isSending) return;
    const q = qEl.value.trim();
    if (!q) { qEl.focus(); return; }

    isSending = true;
    askEl.disabled = true;
    ansEl.textContent = '';
    ansEl.classList.add('loading');
    ansEl.classList.remove('error');
    hideEscalation();

    fetch(backendHost + '/ask', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ question: q })
    })
    .then(r=>{
      if (!r.ok) throw new Error('HTTP '+r.status);
      return r.json();
    })
    .then(data=>{
      ansEl.classList.remove('loading');
      ansEl.classList.remove('error');
      const ans = data.answer ?? '(응답이 없습니다)';
      ansEl.textContent = ans;
      handleApology(ans);
    })
    .catch(err=>{
      console.error('[BNK Chatbot] fetch error:', err);
      ansEl.classList.remove('loading');
      ansEl.classList.add('error');
      ansEl.textContent = '서버 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      // handleApology('죄송'); // 오류도 사과로 카운트하려면 사용
    })
    .finally(()=>{
      isSending = false;
      askEl.disabled = false;
    });
  }

  /* ----- Apology detection ----- */
  function handleApology(answerText){
    if (APOLOGY_REGEX.test(answerText)) {
      apologyCount++;
      console.log('[BNK Chatbot] apology detected ->', apologyCount);
    } else {
      apologyCount = 0;
    }
    if (apologyCount === 2) {
      showEscalation('필요하시면 상담사에게 직접 문의하실 수 있어요.');
    } else if (apologyCount >= 3) {
      showEscalation('챗봇이 정확한 답변을 드리지 못하고 있습니다. 상담사 연결을 권장드립니다.');
      setTimeout(()=>{
        const go = confirm('상담사 채팅으로 이동할까요?');
        if (go) goHuman();
      },100);
    }
  }

  /* ----- Escalation box ----- */
  function showEscalation(msg){
    if (!escEl) return;
    escEl.querySelector('.esc-msg').textContent = msg;
    escEl.style.display = 'block';
  }
  function hideEscalation(){
    if (!escEl) return;
    escEl.style.display = 'none';
  }

  function goHuman(){
    window.location.href = humanUrl;
  }

})(); // IIFE end
