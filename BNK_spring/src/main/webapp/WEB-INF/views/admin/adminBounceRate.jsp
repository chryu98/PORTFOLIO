<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" isELIgnored="true"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>카드별 구간 이탈 현황 (LEGACY API)</title>

<!-- (선택) 공통 스타일 -->
<link rel="stylesheet" href="/css/adminstyle.css">

<style>
/* =========================
   Design Tokens (영업점 톤)
   ========================= */
:root{
  --bg:#ffffff;
  --txt:#111827;
  --muted:#6b7280;
  --line:#e5e7eb;
  --line-soft:#f3f4f6;
  --thead:#fafbfc;
  --card:#ffffff;
  --accent:#2563eb;
  --shadow:0 6px 18px rgba(17,24,39,.06);
  --radius:12px;
  --radius-lg:14px;
  --container:1100px;
}

/* =========================
   Base
   ========================= */
*{ box-sizing:border-box }
html,body{ height:100% }
body{
  margin:0;
  background:var(--bg);
  color:var(--txt);
  font-family:'Noto Sans KR', system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing:antialiased; -moz-osx-font-smoothing:grayscale;
}

/* =========================
   Layout
   ========================= */
.container{
  width:min(var(--container),92vw);
  margin:0 auto;
  padding:0 0 24px;
}

h2{
  margin:0 0 16px;
  text-align:center;
  font-size:24px;
  font-weight:700;
  letter-spacing:-.01em;
  padding-top:24px;
}

/* 카드형 패널 */
.panel{
  background:var(--card);
  border:1px solid var(--line);
  border-radius:var(--radius-lg);
  padding:16px;
  margin:16px auto;
  box-shadow:var(--shadow);
}

/* =========================
   Form / Controls
   ========================= */
.row{
  display:flex;
  gap:12px;
  align-items:center;
  flex-wrap:wrap;
  justify-content:center; /* 가운데 정렬 */
}

label{
  font-size:13px;
  color:#374151;
  display:flex;
  align-items:center;
  gap:8px;
}

input, select, button{
  height:40px;
  padding:0 12px;
  border:1px solid var(--line);
  border-radius:10px;
  background:#fff;
  color:var(--txt);
  font-size:14px;
  outline:none;
  transition:border-color .18s, box-shadow .18s, transform .05s, filter .12s;
}
input:focus, select:focus{
  border-color:var(--accent);
  box-shadow:0 0 0 3px rgba(37,99,235,.15);
}

/* 버튼 (조회 등) */
button{
  cursor:pointer;
  background:var(--accent);
  border-color:var(--accent);
  color:#fff;
  border:1px solid var(--accent);
  padding:0 14px;
  border-radius:10px;
  font-weight:600;
}
button:hover{ filter:brightness(.98) }
button:active{ transform:translateY(1px) }

/* 링크형 버튼 (상세보기) */
.btn-link{
  background:none;
  border:none;
  padding:0;
  height:auto;
  color:var(--accent);
  text-decoration:underline;
  cursor:pointer;
  font:inherit;
}

/* =========================
   Tables
   ========================= */
table{
  width:100%;
  border-collapse:separate;
  border-spacing:0;
  margin-top:8px;
  background:#fff;
  border:1px solid var(--line);
  border-radius:var(--radius);
  overflow:hidden;
  box-shadow:var(--shadow);
}
thead th{
  background:var(--thead);
  font-weight:700;
  color:#374151;
  padding:12px 10px;
  border-bottom:1px solid var(--line);
  text-align:center;
}
th, td{
  font-size:13px;
  padding:12px 10px;
  border-bottom:1px solid var(--line-soft);
  text-align:center;
}
tbody tr:hover{ background:#fcfdff }
.num{ text-align:right }

/* =========================
   Bars / Charts
   ========================= */
.bar{
  height:10px;
  background:var(--line-soft);
  border-radius:6px;
  overflow:hidden;
  flex:1;
}
.bar>i{
  display:block;
  height:100%;
  background:var(--accent);
}

/* =========================
   Sub text / Tags / Pills
   ========================= */
.muted{ color:var(--muted); font-size:12px }
.tag{
  display:inline-block;
  padding:2px 8px;
  border:1px solid var(--line);
  border-radius:999px;
  background:#f9fafb;
  font-size:12px;
  color:#374151;
}

/* 통계 배지 */
.stat-pills{
  display:flex;
  gap:10px;
  flex-wrap:wrap;
  margin:8px 0 14px;
  justify-content:center;
}
.pill{
  min-width:110px;
  border:1px solid var(--line);
  border-radius:12px;
  padding:10px 12px;
  background:#fafafa;
}
.pill .k{
  display:block; color:var(--muted); font-size:12px; margin-bottom:6px;
}
.pill .v{
  display:block; font-size:18px; font-weight:700;
}

/* 차트 카드 */
.charts{
  display:grid;
  grid-template-columns:repeat(auto-fit, minmax(280px,1fr));
  gap:16px;
  max-width:900px;
  margin:0 auto; /* 차트 그룹 가운데 */
}
.chart{
  border:1px solid var(--line);
  border-radius:12px;
  padding:12px;
  background:#fff;
}
.chart h4{
  margin:0 0 10px;
  font-size:14px;
  font-weight:700;
}
.bar-row{
  display:flex;
  align-items:center;
  gap:8px;
  margin:8px 0;
}
.bar-row .lbl{ width:48px; text-align:right; font-size:12px; color:#374151 }
.bar-row .val{ width:88px; text-align:left; font-size:12px; color:#374151 }

/* =========================
   A11y / Responsive
   ========================= */
:focus-visible{ outline:3px solid rgba(37,99,235,.35); outline-offset:2px }

@media (max-width:720px){
  h2{ font-size:20px }
  input, select, button{ height:38px }
  thead th, td{ padding:10px 8px; font-size:12.5px }
}

/* 프린트 최소화 */
@media print{
  .panel{ box-shadow:none; border-color:#ddd }
  button, .row select, .row input{ display:none !important }
}
</style>
</head>
<body>
	<jsp:include page="../fragments/header.jsp"></jsp:include>

	<div class="container">
		<h2>카드별 구간 이탈 현황</h2>

		<div class="panel">
			<form id="q" class="row" onsubmit="return false;">
				<label>카드
					<select id="cardNo" required>
						<option value="">카드 선택</option>
					</select>
				</label>
				<label>기간
					<input type="date" id="from" /> ~
					<input type="date" id="to" />
				</label>
				<label>표시 구간 수
					<input type="number" id="limitPerCard" min="1" max="50" value="20" />
				</label>
				<button id="btn">조회</button>
			</form>
		</div>

		<div class="panel">
			<div id="cardTitle" class="muted" style="margin-bottom: 8px"></div>
			<table id="tbl">
				<thead>
					<tr>
						<th>이탈 구간 (현재 단계 → 다음 단계)</th>
						<th>이탈 수</th>
						<th>이탈률(%)</th>
						<th>상세</th>
					</tr>
				</thead>
				<tbody id="tbody">
					<tr>
						<td colspan="4" class="muted">카드를 선택하고 조회하세요.</td>
					</tr>
				</tbody>
			</table>
		</div>

		<!-- 통계 패널 -->
		<div class="panel" id="statsPanel" style="display: none">
			<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px">
				<h3 style="margin: 0">이탈자 통계</h3>
				<span class="tag" id="statsMeta"></span>
			</div>

			<div class="stat-pills">
				<div class="pill"><span class="k">총 이탈자</span><span class="v" id="pTotal">-</span></div>
				<div class="pill"><span class="k">남</span><span class="v" id="pMale">-</span></div>
				<div class="pill"><span class="k">여</span><span class="v" id="pFemale">-</span></div>
				<div class="pill"><span class="k">20대</span><span class="v" id="pA20">-</span></div>
				<div class="pill"><span class="k">30대</span><span class="v" id="pA30">-</span></div>
				<div class="pill"><span class="k">40대</span><span class="v" id="pA40">-</span></div>
				<div class="pill"><span class="k">50+</span><span class="v" id="pA50">-</span></div>
			</div>

			<div class="charts">
				<div class="chart">
					<h4>성별 분포</h4>
					<div id="genderBars"></div>
				</div>
				<div class="chart">
					<h4>연령대 분포</h4>
					<div id="ageBars"></div>
				</div>
			</div>
		</div>

		<!-- 상세 테이블 -->
		<div class="panel" id="detailPanel" style="display: none">
			<h3 style="margin: 0 0 8px">이탈자 상세</h3>
			<div id="detailMeta" class="muted" style="margin-bottom: 8px"></div>
			<table>
				<thead>
					<tr>
						<th>신청번호</th>
						<th>회원번호</th>
						<th>이름</th>
						<th>아이디</th>
						<th>성별</th>
						<th>나이</th>
						<th>최종상태</th>
						<th>신청일</th>
						<th>갱신일</th>
					</tr>
				</thead>
				<tbody id="detailBody">
					<tr>
						<td colspan="9" class="muted">상세를 선택하세요.</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div><!-- /container -->

	<script src="/js/adminHeader.js"></script>
	<script>
/* =========================
   ⬇ 기존 스크립트 그대로 유지
   ========================= */
(function(){
  const $ = (id)=>document.getElementById(id);
  const fmt = (n)=> n==null ? '' : Number(n).toLocaleString();
  const fmtPct = (n)=> n==null ? '' : Number(n).toFixed(1);
  const dateStr = (s)=> s ? new Date(s).toLocaleString() : '';
  const pad = (x)=> String(x).padStart(2,'0');
  const toISO = (d)=> d.getFullYear()+"-"+pad(d.getMonth()+1)+"-"+pad(d.getDate());

  const today = new Date();
  const monthAgo = new Date(); monthAgo.setDate(today.getDate()-30);
  $('from').value = toISO(monthAgo);
  $('to').value = toISO(today);

  loadCards().then(loadSummary);

  async function loadCards(){
    const res = await fetch('/admin/api/journey/cards?activeOnly=Y', { headers: { 'Accept': 'application/json' } });
    const list = await res.json();
    $('cardNo').innerHTML = '<option value="">카드 선택</option>' + list.map(c =>
      `<option value="${c.cardNo}">[${c.cardNo}] ${c.cardName || ''}</option>`
    ).join('');
  }

  $('btn').addEventListener('click', loadSummary);
  $('cardNo').addEventListener('change', loadSummary);

  async function loadSummary(){
    const cardNo = $('cardNo').value;
    const from = $('from').value.trim();
    const to = $('to').value.trim();
    const limitPerCard = $('limitPerCard').value.trim();

    if(!cardNo){
      $('tbody').innerHTML = '<tr><td colspan="4" class="muted">카드를 선택하세요.</td></tr>';
      $('cardTitle').textContent = '';
      $('statsPanel').style.display = 'none';
      $('detailPanel').style.display = 'none';
      return;
    }

    const params = new URLSearchParams({ cardNo, limitPerCard });
    if(from) params.set('from', from);
    if(to) params.set('to', to);

    const url = '/admin/api/journey/drop-legacy/by-card?' + params.toString();

    const tbody = $('tbody');
    tbody.innerHTML = '<tr><td colspan="4" class="muted">불러오는 중…</td></tr>';

    try {
      const res = await fetch(url, { headers: { 'Accept': 'application/json' } });
      if(!res.ok) throw new Error('HTTP '+res.status);
      const data = await res.json();

      if(!Array.isArray(data) || data.length===0){
        tbody.innerHTML = '<tr><td colspan="4" class="muted">데이터가 없습니다.</td></tr>';
        $('cardTitle').textContent = '';
        $('statsPanel').style.display = 'none';
        $('detailPanel').style.display = 'none';
        return;
      }

      const cardName = data[0].cardName || '';
      $('cardTitle').textContent = `선택 카드: [${cardNo}] ${cardName}`;

      tbody.innerHTML = data.map((r)=> {
        const dropPct = r.dropPct==null ? 0 : r.dropPct;
        const gap = `${r.fromStepName || ''} → ${r.toStepName || ''}`;
        const btn = `<button class="btn-link" data-card="${r.cardNo}" data-cardname="${r.cardName}"
                       data-from="${r.fromStepCode}" data-gap="${gap}">상세보기</button>`;
        return `
          <tr>
            <td>${gap}</td>
            <td class="num"><strong>${fmt(r.droppedBetween)}</strong></td>
            <td class="num">
              <strong>${fmtPct(dropPct)}</strong>
              <div class="bar" title="${fmtPct(dropPct)}%"><i style="width:${dropPct}%;"></i></div>
            </td>
            <td>${btn}</td>
          </tr>`;
      }).join('');

      [...document.querySelectorAll('button.btn-link')].forEach(btn=>{
        btn.addEventListener('click', ()=>{
          loadDetail({
            cardNo,
            cardName,
            atStep: btn.getAttribute('data-from'),
            gap: btn.getAttribute('data-gap'),
            from, to
          });
        });
      });

    } catch(err){
      tbody.innerHTML = `<tr><td colspan="4" style="color:#b91c1c">에러: ${err.message}</td></tr>`;
      $('statsPanel').style.display = 'none';
      $('detailPanel').style.display = 'none';
    }
  }

  function computeStats(rows){
    const s = { total: rows.length, male:0, female:0, a20:0, a30:0, a40:0, a50:0 };
    rows.forEach(d=>{
      if(d.gender === '남') s.male++;
      else if(d.gender === '여') s.female++;

      const age = typeof d.ageYears === 'number' ? d.ageYears : null;
      if(age != null){
        if(age>=20 && age<=29) s.a20++;
        else if(age>=30 && age<=39) s.a30++;
        else if(age>=40 && age<=49) s.a40++;
        else if(age>=50) s.a50++;
      }
    });
    return s;
  }
  function pct(n, total){ return total>0 ? Math.round((n*1000/total))/10 : 0; }

  function renderBars(containerId, rows){
    const wrap = document.getElementById(containerId);
    wrap.innerHTML = rows.map(r=>{
      const w = Math.max(0, Math.min(100, r.pct));
      return `
        <div class="bar-row">
          <div class="lbl">${r.label}</div>
          <div class="bar" title="${r.pct}%"><i style="width:${w}%;"></i></div>
          <div class="val">${r.count.toLocaleString()} (${r.pct}%)</div>
        </div>
      `;
    }).join('');
  }

  function renderStats(cardNo, cardName, atStep, gap, from, to, rows){
    const s = computeStats(rows);

    document.getElementById('statsMeta').textContent =
      `[${cardNo}] ${cardName} • ${gap} • 총 ${s.total.toLocaleString()}명` +
      (from||to ? ` • 기간 ${from||'~'} ~ ${to||'~'}` : '');

    document.getElementById('pTotal').textContent = s.total.toLocaleString();
    document.getElementById('pMale').textContent  = s.male.toLocaleString();
    document.getElementById('pFemale').textContent= s.female.toLocaleString();
    document.getElementById('pA20').textContent   = s.a20.toLocaleString();
    document.getElementById('pA30').textContent   = s.a30.toLocaleString();
    document.getElementById('pA40').textContent   = s.a40.toLocaleString();
    document.getElementById('pA50').textContent   = s.a50.toLocaleString();

    renderBars('genderBars', [
      { label:'남', count:s.male,   pct: pct(s.male, s.total) },
      { label:'여', count:s.female, pct: pct(s.female, s.total) }
    ]);
    renderBars('ageBars', [
      { label:'20대', count:s.a20, pct: pct(s.a20, s.total) },
      { label:'30대', count:s.a30, pct: pct(s.a30, s.total) },
      { label:'40대', count:s.a40, pct: pct(s.a40, s.total) },
      { label:'50+',  count:s.a50, pct: pct(s.a50, s.total) }
    ]);

    document.getElementById('statsPanel').style.display = 'block';
  }

  async function loadDetail({from, to, cardNo, cardName, atStep, gap}){
    const params = new URLSearchParams({ cardNo, fromStepCode: atStep });
    if(from) params.set('from', from);
    if(to) params.set('to', to);

    const url = '/admin/api/journey/drop-legacy/by-card/details?' + params.toString();

    document.getElementById('detailPanel').style.display = 'block';
    document.getElementById('detailMeta').textContent =
    	   `[${cardNo}] ${cardName} — 이탈 구간: ${gap} (현재=${atStep} → 다음 단계 이탈)`;

    const tbody = document.getElementById('detailBody');
    tbody.innerHTML = '<tr><td colspan="9" class="muted">불러오는 중…</td></tr>';

    try {
      const res = await fetch(url, { headers: { 'Accept': 'application/json' } });
      if(!res.ok) throw new Error('HTTP '+res.status);
      const data = await res.json();

      if(!Array.isArray(data) || data.length===0){
        tbody.innerHTML = '<tr><td colspan="9" class="muted">이탈자가 없습니다.</td></tr>';
        document.getElementById('statsPanel').style.display = 'none';
        return;
      }

      tbody.innerHTML = data.map(d => `
        <tr>
          <td class="num">${d.applicationNo}</td>
          <td class="num">${d.memberNo}</td>
          <td>${d.name || ''}</td>
          <td>${d.username || ''}</td>
          <td>${d.gender || ''}</td>
          <td class="num">${d.ageYears ?? ''}</td>
          <td>${d.lastStatus}</td>
          <td>${(d.createdAt ? new Date(d.createdAt).toLocaleString() : '')}</td>
          <td>${(d.updatedAt ? new Date(d.updatedAt).toLocaleString() : '')}</td>
        </tr>
      `).join('');

      renderStats(cardNo, cardName, atStep, gap, from, to, data);

    } catch(err){
      tbody.innerHTML = `<tr><td colspan="9" style="color:#b91c1c">에러: ${err.message}</td></tr>`;
      document.getElementById('statsPanel').style.display = 'none';
    }
  }
})();
</script>

</body>
</html>
