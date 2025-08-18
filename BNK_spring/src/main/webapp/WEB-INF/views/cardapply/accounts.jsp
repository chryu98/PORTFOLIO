<%@ page contentType="text/html; charset=UTF-8" language="java" isELIgnored="true" %>
<%
  String ctx = request.getContextPath();
  org.springframework.security.web.csrf.CsrfToken csrf =
      (org.springframework.security.web.csrf.CsrfToken) request.getAttribute("_csrf");
  String csrfToken  = (csrf != null ? csrf.getToken() : "");
  String csrfHeader = (csrf != null ? csrf.getHeaderName() : "X-CSRF-TOKEN");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8"/>
  <title>계좌 관리</title>

  <meta name="_ctx"         content="<%= ctx %>"/>
  <meta name="_csrf"        content="<%= csrfToken %>"/>
  <meta name="_csrf_header" content="<%= csrfHeader %>"/>

  <style>
    body { font-family: system-ui, sans-serif; margin: 24px; }
    .card { border:1px solid #ddd; border-radius:12px; padding:16px; margin-bottom:16px; }
    .row { display:flex; gap:12px; align-items:center; flex-wrap:wrap; margin-top:8px; }
    input, button { padding:10px; }
    table { border-collapse: collapse; width:100%; }
    th, td { border-bottom:1px solid #eee; padding:10px; text-align:left; }
    .muted { color:#666; font-size:0.9em; }
  </style>
</head>
<body>
  <h1>계좌 관리 (REST + fetch)</h1>
  <div id="message" class="muted"></div>
  <div id="root"></div>

  <script>
  const ctx        = document.querySelector('meta[name="_ctx"]').content || '';
  const csrfToken  = document.querySelector('meta[name="_csrf"]').content || '';
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content || 'X-CSRF-TOKEN';

  const API_BASE   = ctx + '/card/apply/api/accounts';
  const API_STATE  = API_BASE + '/state';
  const API_CREATE = API_BASE + '/create-if-none';            // 비번 없어도 생성
  const API_SELECT = (acNo) => `${API_BASE}/${acNo}/verify-and-select`; // 비번검증+선택
  const API_SET_PW = (acNo) => `${API_BASE}/${acNo}/set-password`;      // 비번설정
  
  const APP_NO = new URLSearchParams(location.search).get('applicationNo');

  // 다음 페이지(원하는 경로로 바꿔줘)
  const NEXT_URL_AFTER_SET_PW = ctx + '/card/apply/contactInfo' + (APP_NO ? `?applicationNo=${encodeURIComponent(APP_NO)}` : '');
  const NEXT_URL_AFTER_SELECT  = ctx + '/card/apply/contactInfo' + (APP_NO ? `?applicationNo=${encodeURIComponent(APP_NO)}` : '');

  function readCookie(name) {
    return document.cookie.split('; ').reduce((acc, cur) => {
      const [k, v] = cur.split('=');
      return k === name ? decodeURIComponent(v) : acc;
    }, '');
  }
  function getJwtToken() {
    return (
      localStorage.getItem('jwtToken') ||
      sessionStorage.getItem('jwtToken') ||
      localStorage.getItem('accessToken') ||
      sessionStorage.getItem('accessToken') ||
      localStorage.getItem('jwt') ||
      sessionStorage.getItem('jwt') ||
      readCookie('ACCESS_TOKEN') ||
      ''
    );
  }
  (function bridgeJwt(){
    if (!localStorage.getItem('accessToken')) {
      const c = readCookie('ACCESS_TOKEN');
      if (c) localStorage.setItem('accessToken', c);
    }
  })();

  function defaultHeaders(extra = {}) {
    const h = { 'Accept': 'application/json', ...extra };
    const jwt = getJwtToken();
    if (jwt) h['Authorization'] = 'Bearer ' + jwt;
    if (csrfToken) h[csrfHeader] = csrfToken;
    return h;
  }

  const root = document.getElementById('root');
  const msg  = document.getElementById('message');
  function setMessage(t) { msg.textContent = t || ''; }

  async function loadState() {
    setMessage('');
    root.innerHTML = '<div class="card">로딩 중...</div>';
    try {
      const res = await fetch(API_STATE, { method:'GET', credentials:'same-origin', headers: defaultHeaders() });
      if (res.status === 401) { root.innerHTML = '<div class="card">로그인이 필요합니다.</div>'; return; }
      if (!res.ok) throw new Error('상태 조회 실패');
      const data = await res.json();
      if (data.hasAccount) renderSelect(data.accounts || []);
      else renderAutoCreate();                      // ⬅️ 계좌없음 → 자동생성 버튼로
    } catch (e) {
      root.innerHTML = `<div class="card">오류: ${e.message}</div>`;
    }
  }

  // (1) 계좌 자동 생성 화면
  function renderAutoCreate() {
  root.innerHTML = `
    <div class="card">
      <h2>새 계좌 자동 생성</h2>
      <div class="row">
        <button id="btnAutoCreate">계좌 생성</button>
      </div>
    </div>
  `;
  document.getElementById('btnAutoCreate').addEventListener('click', async () => {
    try {
      const res = await fetch(API_CREATE, {
        method: 'POST',
        credentials: 'same-origin',
        headers: defaultHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({}) // 카드번호 없이 생성
        // ↳ 원하면 body 자체를 생략해도 됩니다.
      });
      if (res.status === 401) { setMessage('로그인이 필요합니다.'); return; }
      const data = await res.json();
      if (!data.created) { setMessage(data.message || '생성 실패'); return; }

      const acNo = data.account?.acNo;
      if (!acNo) { setMessage('생성은 되었으나 AC_NO를 받지 못했습니다.'); return; }
      renderSetPassword(acNo);
    } catch {
      setMessage('생성 요청 중 오류가 발생했습니다.');
    }
  });
}

  // (2) 비밀번호 설정(두 번 입력)
  function renderSetPassword(acNo) {
    root.innerHTML = `
      <div class="card">
        <h2>계좌 비밀번호 설정</h2>
        <div class="row">
          <input id="pw1" type="password" placeholder="비밀번호" />
          <input id="pw2" type="password" placeholder="비밀번호 확인" />
        </div>
        <div class="row">
          <button id="btnSetPw">저장</button>
        </div>
      </div>
    `;
    document.getElementById('btnSetPw').addEventListener('click', async () => {
      const pw1 = document.getElementById('pw1').value;
      const pw2 = document.getElementById('pw2').value;
      if (!pw1 || !pw2) { setMessage('비밀번호를 입력하세요.'); return; }
      if (pw1 !== pw2) { setMessage('비밀번호가 일치하지 않습니다.'); return; }

      try {
        const res = await fetch(API_SET_PW(acNo), {
          method: 'POST',
          credentials: 'same-origin',
          headers: defaultHeaders({ 'Content-Type': 'application/json' }),
          body: JSON.stringify({ pw1, pw2 })
        });
        const data = await res.json();
        if (!res.ok || !data.ok) { setMessage(data.message || '저장 실패'); return; }

        // 성공 → 다음 페이지로
        location.href = NEXT_URL_AFTER_SET_PW;
      } catch {
        setMessage('비밀번호 저장 중 오류가 발생했습니다.');
      }
    });
  }

  // (3) 기존 계좌 선택 리스트 + 비밀번호 검증
  function renderSelect(accounts) {
    const rows = accounts.map(a => `
      <tr>
        <td>${a.acNo}</td>
        <td>${a.accountNumber}</td>
        <td>${a.status}</td>
        <td>${a.createdAt ? new Date(a.createdAt).toLocaleString() : '-'}</td>
        <td><button class="btn-select" data-acno="${a.acNo}">선택</button></td>
      </tr>
    `).join('');

    root.innerHTML = `
      <div class="card">
        <h2>활성 계좌 선택</h2>
        ${accounts.length === 0 ? '<div>활성 계좌가 없습니다.</div>' : `
          <table>
            <thead>
              <tr><th>AC_NO</th><th>계좌번호</th><th>상태</th><th>생성일</th><th>동작</th></tr>
            </thead>
            <tbody>${rows}</tbody>
          </table>
        `}
        <div class="row">
          <button id="btnRefresh">새로고침</button>
          <button id="btnCreateNew">새 계좌 생성</button>
        </div>
        <div id="pwBox" style="margin-top:12px; display:none;">
          <input id="pwExist" type="password" placeholder="계좌 비밀번호 입력"/>
          <button id="btnVerify">확인</button>
        </div>
      </div>
    `;

    document.getElementById('btnRefresh').addEventListener('click', loadState);
    document.getElementById('btnCreateNew').addEventListener('click', renderAutoCreate);

    let targetAcNo = null;

    document.querySelectorAll('.btn-select').forEach(btn => {
      btn.addEventListener('click', () => {
        targetAcNo = Number(btn.getAttribute('data-acno'));
        document.getElementById('pwBox').style.display = 'block';
        document.getElementById('pwExist').value = '';
        setMessage('선택한 계좌의 비밀번호를 입력하세요.');
      });
    });

    document.getElementById('btnVerify').addEventListener('click', async () => {
      const pw = document.getElementById('pwExist').value;
      if (!targetAcNo) { setMessage('계좌를 먼저 선택하세요.'); return; }
      if (!pw) { setMessage('비밀번호를 입력하세요.'); return; }

      try {
        const res = await fetch(API_SELECT(targetAcNo), {
          method: 'POST',
          credentials: 'same-origin',
          headers: defaultHeaders({ 'Content-Type': 'application/json' }),
          body: JSON.stringify({ password: pw })
        });
        const data = await res.json();
        if (!res.ok || !data.ok) { setMessage(data.message || '인증 실패'); return; }

        // 성공 → 다음 페이지로
        location.href = NEXT_URL_AFTER_SELECT;
      } catch {
        setMessage('인증 요청 중 오류가 발생했습니다.');
      }
    });
  }

  loadState();
</script>

</body>
</html>
