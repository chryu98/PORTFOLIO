<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>카드 PIN 설정</title>
  <style>
    body { font-family: system-ui, sans-serif; padding:24px; }
    label { display:block; margin-top:12px; }
    input { padding:8px; width:260px; }
    button { margin-top:16px; padding:10px 16px; cursor:pointer; }
    pre { background:#f6f8fa; padding:12px; border-radius:8px; margin-top:16px; white-space:pre-wrap; }
  </style>
</head>
<body>
  <h2>카드 PIN 설정</h2>

  <label>Card No</label>
  <input id="cardNo" type="number" placeholder="예: 12345678" />

  <label>PIN (4~6자리)</label>
  <input id="pin1" type="password" maxlength="6" />

  <label>PIN 확인</label>
  <input id="pin2" type="password" maxlength="6" />

  <div>
    <button id="btnSet">PIN 저장</button>
  </div>

  <pre id="out"></pre>

<script>
(function(){
  function $(id){ return document.getElementById(id); }

  // --- 유틸 ---
  function getParam(name){
    var m = new RegExp('[?&]' + name + '=([^&]*)').exec(location.search);
    return m ? decodeURIComponent(m[1].replace(/\+/g, ' ')) : '';
  }

  function readCookie(name){
    var s = document.cookie.split('; ');
    for (var i=0; i<s.length; i++){
      var p = s[i].split('=');
      if (p[0] === name) return decodeURIComponent(p[1] || '');
    }
    return '';
  }

  function getJwt(){
    // ① 쿠키 → ② localStorage → ③ ?jwt=
    var c = readCookie('jwtToken');
    if (c) return c;
    try {
      var ls = localStorage.getItem('jwtToken');
      if (ls) return ls;
    } catch(_) {}
    var q = getParam('jwt');
    if (q) return q;
    return '';
  }

  // CSRF + JWT 헤더 구성
  function makeHeaders(){
    var h = { 'Content-Type':'application/json' };

    // CSRF: XSRF-TOKEN 쿠키 → X-XSRF-TOKEN 헤더(쓰는 중이면)
    var xsrf = readCookie('XSRF-TOKEN');
    if (xsrf) h['X-XSRF-TOKEN'] = xsrf;

    // JWT: Authorization + (필요시) 커스텀 헤더명도 같이
    var jwt = getJwt();
    if (jwt) {
      h['Authorization'] = 'Bearer ' + jwt; // 표준
      h['jwtToken']      = jwt;              // 필터가 이 키를 읽는 경우 대비
    }
    return h;
  }

  // 초기 cardNo 세팅(쿼리스트링에서)
  var initial = getParam('cardNo');
  if (initial) $('cardNo').value = initial;

  $('btnSet').onclick = function(){
    var cardNo = String(($('cardNo').value || '').trim());
    if (!cardNo){ alert('카드번호를 입력하세요.'); return; }

    var body = { pin1: $('pin1').value, pin2: $('pin2').value };
    var url  = '/card/apply/api/card-password/' + encodeURIComponent(cardNo) + '/pin';

    fetch(url, {
      method: 'POST',
      headers: makeHeaders(),
      body: JSON.stringify(body),
      credentials: 'same-origin' // JSESSIONID 등 세션 쿠키 전송
    })
    .then(function(r){
      return r.text().then(function(t){ return { ok:r.ok, status:r.status, text:t }; });
    })
    .then(function(res){
      var out = 'HTTP ' + res.status + (res.ok ? ' (OK)\n' : ' (FAIL)\n');
      try {
        out += JSON.stringify(JSON.parse(res.text), null, 2);
      } catch(e){
        out += res.text;
      }
      $('out').textContent = out;
    })
    .catch(function(err){
      $('out').textContent = 'Network error: ' + err;
    });
  };
})();
</script>
</body>
</html>
