<!-- src/main/webapp/WEB-INF/jsp/admin/push/adminPush.jsp -->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!doctype html>
<html>
<head>
  <meta charset="utf-8"/>
  <title>관리자 푸시 발송</title>
  <style>
    body { font-family: sans-serif; max-width: 720px; margin: 24px auto; }
    label { display:block; margin-top:12px; font-weight:bold; }
    input, textarea, button { width:100%; box-sizing:border-box; padding:10px; margin-top:6px; }
    .row { display:flex; gap:12px; }
    .row > div { flex:1; }
    .card { border:1px solid #ddd; border-radius:12px; padding:16px; box-shadow:0 2px 8px rgba(0,0,0,.04);}
    pre { background:#f7f7f7; padding:12px; border-radius:8px; }
  </style>
</head>
<body>
  <h2>관리자 푸시 발송 (WebSocket)</h2>

  <div class="card">
    <label>제목</label>
    <input id="title" placeholder="예) 9월 카드 혜택 안내"/>

    <label>내용</label>
    <textarea id="content" rows="4" placeholder="예) 주말 5% 추가 적립!"></textarea>

    <button onclick="sendAll()">전체 동의자에게 발송</button>
  </div>

  <div class="card" style="margin-top:16px;">
    <div class="row">
      <div>
        <label>나이 From</label>
        <input id="ageFrom" type="number" value="20"/>
      </div>
      <div>
        <label>나이 To</label>
        <input id="ageTo" type="number" value="29"/>
      </div>
    </div>
    <button onclick="sendByAge()">나이 조건으로 발송</button>
  </div>

  <pre id="log" style="margin-top:16px;"></pre>

  <script>
    const log = (m) => document.getElementById('log').textContent =
      new Date().toLocaleTimeString() + ' - ' + m;

    async function sendAll(){
      const payload = {
        title: document.getElementById('title').value,
        content: document.getElementById('content').value,
        createdBy: 'admin'
      };
      const res = await fetch('/admin/push/send', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify(payload)
      });
      const json = await res.json();
      log(`전체 발송 완료: pushNo=${json.pushNo}`);
    }

    async function sendByAge(){
      const payload = {
        title: document.getElementById('title').value,
        content: document.getElementById('content').value,
        ageFrom: Number(document.getElementById('ageFrom').value),
        ageTo: Number(document.getElementById('ageTo').value),
        createdBy: 'admin'
      };
      const res = await fetch('/admin/push/send/age', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify(payload)
      });
      const json = await res.json();
      log(`연령 발송 완료: pushNo=${json.pushNo} (age ${json.ageFrom}-${json.ageTo})`);
    }
  </script>
</body>
</html>
