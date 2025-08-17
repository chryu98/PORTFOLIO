<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>가입자/판매 리포트</title>

<!-- 라이브러리 -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>

<style>
/* ===== 기본 ===== */
* { box-sizing: border-box; }
body {
  margin: 0;
  background: #fff;
  color: #111827;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
}

/* ===== 페이지 컨테이너 ===== */
.container {
  width: min(1000px, 95vw);
  margin: 0 auto;
  padding: 20px;
}

/* ===== 제목 ===== */
h1 {
  margin: 20px auto 16px;
  font-size: 24px;
  font-weight: 700;
  text-align: center;  /* 가운데 정렬 */
}

/* ===== 툴바 ===== */
.toolbar {
  display: flex;
  justify-content: center;
  gap: 10px;
  flex-wrap: wrap;
  margin: 16px 0;
}
input[type=date], button {
  padding: 8px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
  color: #111827;
  font-size: 14px;
}
button {
  cursor: pointer;
}
.btn-primary {
  background: #2563eb;
  color: #fff;
  border-color: #2563eb;
}
.actions { display: flex; gap: 8px; flex-wrap: wrap; }

/* ===== KPI 박스 ===== */
.kpi {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 16px;
  text-align: center;
  box-shadow: 0 4px 12px rgba(0,0,0,.05);
}
.kpi .muted { font-size: 13px; color: #6b7280; margin-bottom: 4px; }
.kpi .value { font-size: 22px; font-weight: 700; }
.kpi .delta { font-size: 12px; color: #6b7280; margin-top: 4px; }
.kpi .delta.up { color: #16a34a; }
.kpi .delta.down { color: #dc2626; }

/* ===== 카드 공통 ===== */
.card {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 16px;
  margin-top: 16px;
  box-shadow: 0 4px 12px rgba(0,0,0,.05);
}
.card h2 {
  font-size: 16px;
  margin: 0 0 10px;
}

/* ===== 그리드 레이아웃 ===== */
.grid { display: grid; gap: 16px; }
.grid-2 { grid-template-columns: 1fr 1fr; }
.grid-3 { grid-template-columns: 1fr 1fr 1fr; }
@media (max-width: 900px) {
  .grid-2, .grid-3 { grid-template-columns: 1fr; }
}

/* ===== 표 ===== */
table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
}
th, td {
  padding: 10px 14px;
  border-bottom: 1px solid #f1f5f9;
  text-align: left;
  font-size: 14px;
}
th {
  background: #f9fafb;
  font-weight: 600;
  color: #374151;
}

/* ===== 보조 텍스트 ===== */
.muted {
  font-size: 12px;
  color: #6b7280;
  text-align: center;
  margin-top: 6px;
}

</style>



<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
<jsp:include page="../fragments/header.jsp"></jsp:include>

  <div class="container">
    <h1>가입자/판매 리포트</h1>
    <div class="toolbar">
      <span>기간</span>
      <input type="date" id="from">
      <input type="date" id="to">
      <button class="btn btn-primary" id="btnFetch">조회</button>
      <span style="flex:1;"></span>
      <div class="actions">
        <button class="btn" id="btnPdfPreview">PDF 미리보기</button>
        <button class="btn" id="btnPdfDownload">PDF 다운로드</button>
        <button class="btn" id="btnXlsxPreview">Excel 미리보기</button>
        <button class="btn" id="btnXlsxDownload">Excel 다운로드</button>
      </div>
    </div>
    <div class="muted">* 보고 범위: [from, to] 날짜의 신청/판매 데이터 (판매=ISSUED)</div>
  </div>

<div class="container" id="reportRoot">

  <!-- 1) KPI -->
  <div class="grid grid-3">
    <div class="kpi">
      <div>
        <div class="muted">신규 신청</div>
        <div class="value" id="kpiApplies">-</div>
      </div>
    </div>
    <div class="kpi">
      <div>
        <div class="muted">승인</div>
        <div class="value" id="kpiApproved">-</div>
      </div>
    </div>
    <div class="kpi">
      <div>
        <div class="muted">판매(발급완료)</div>
        <div class="value" id="kpiIssued">-</div>
        <div class="delta" id="kpiIssuedDelta">-</div>
      </div>
    </div>
  </div>

  <!-- 2) 판매 추세 -->
  <div class="card" style="margin-top:16px">
    <h2>판매 추세</h2>
    <canvas id="trendChart" height="120"></canvas>
  </div>

  <!-- 3) 상품별 판매 Top-N -->
  <div class="card" style="margin-top:16px">
    <h2>상품별 판매 Top-10</h2>
    <canvas id="productChart" height="200"></canvas>
  </div>

  <!-- 4) 신청→발급 퍼널 -->
  <div class="card" style="margin-top:16px">
    <h2>신청→발급 퍼널</h2>
    <canvas id="funnelChart" height="140"></canvas>
  </div>

  <!-- 5) 가입자 현황 -->
  <div class="grid grid-2" style="margin-top:16px">
    <div class="card">
      <h2>성별 비율 (판매 기준)</h2>
      <canvas id="genderChart" height="220"></canvas>
    </div>
    <div class="card">
      <h2>연령대 비율 (판매 기준 / 100%)</h2>
      <canvas id="ageChart" height="220"></canvas>
    </div>
  </div>

  <!-- 원천 표 (상품 요약) -->
  <div class="card" style="margin-top:16px">
    <h2>원천 데이터 (상품 요약)</h2>
    <table id="tbl">
      <thead>
        <tr>
          <th>카드번호</th>
          <th>카드명</th>
          <th>신청</th>
          <th>승인</th>
          <th>발급완료(판매)</th>
        </tr>
      </thead>
      <tbody></tbody>
    </table>
  </div>

</div>

<script src="/js/adminHeader.js"></script>
<script>
  /* ===== 공통 유틸 ===== */
  function apiBase() {
    var path = window.location.pathname;
    var i = path.indexOf('/admin/');
    var prefix = i >= 0 ? path.slice(0, i) : '';
    var s = prefix + '/admin/report';
    return s.replace(/\/{2,}/g, '/');
  }
  function qs(id){ return document.getElementById(id); }
  function setDefaultDates() {
    var to = new Date();
    var from = new Date(); from.setDate(to.getDate() - 7);
    function fmt(d){ return new Date(d.getTime() - d.getTimezoneOffset()*60000).toISOString().slice(0,10); }
    qs('from').value = fmt(from);
    qs('to').value   = fmt(to);
  }
  function qp() {
    return '?from=' + encodeURIComponent(qs('from').value) + '&to=' + encodeURIComponent(qs('to').value);
  }
  function getJSON(url) {
    return fetch(url, { headers: { 'Accept': 'application/json' }})
      .then(function(res){ if(!res.ok) throw new Error('요청 실패: ' + res.status + ' ' + url); return res.json(); });
  }
  function sum(a){ return a.reduce(function(x,y){ return x+y; }, 0); }

  /* ===== 상태 ===== */
  var trendChart, productChart, funnelChart, genderChart, ageChart;
  var cachedProducts = [];
  var cachedDemos = [];
  var cachedTrend = [];
  var cachedFunnel = {};
  var cachedOverview = {};

  /* ===== KPI 표시 ===== */
  function setKpi(ov){
    cachedOverview = ov || {};
    qs('kpiApplies').textContent  = (ov && ov.applies != null) ? ov.applies : '-';
    qs('kpiApproved').textContent = (ov && ov.approved != null) ? ov.approved : '-';
    qs('kpiIssued').textContent   = (ov && ov.issued != null) ? ov.issued : '-';

    var el = qs('kpiIssuedDelta');
    if (ov && ov.wowIssuedDeltaPct != null) {
      var sign = ov.wowIssuedDeltaPct >= 0 ? '▲ ' : '▼ ';
      el.textContent = '전주 대비 ' + sign + Math.abs(ov.wowIssuedDeltaPct) + '%';
      el.className = 'delta ' + (ov.wowIssuedDeltaPct >= 0 ? 'up' : 'down');
    } else {
      el.textContent = '전주 대비 데이터 없음';
      el.className = 'delta';
    }
  }

  /* ===== 차트: UX 최적화 프리셋 ===== */
  function asLineAreaConfig(labels, values, label){
    return {
      type: 'line',
      data: { labels: labels, datasets: [{ label: label, data: values, fill: true, tension: 0.3 }] },
      options: {
        responsive: true,
        plugins: { legend: { display: false }, tooltip: { enabled: true } },
        scales: { y: { beginAtZero: true } }
      }
    };
  }
  function asHBarConfig(labels, values, label){
    return {
      type: 'bar',
      data: { labels: labels, datasets: [{ label: label, data: values }] },
      options: {
        indexAxis: 'y',
        responsive: true,
        plugins: { legend: { display: false }, tooltip:{ enabled: true } },
        scales: { x: { beginAtZero: true }, y: { ticks:{ autoSkip:false, maxRotation:0, minRotation:0 } } }
      }
    };
  }
  function asDonutConfig(labels, values, label){
    return {
      type: 'doughnut',
      data: { labels: labels, datasets: [{ label: label, data: values }] },
      options: { responsive: true, plugins: { legend: { position:'bottom' } } }
    };
  }
  function asStacked100HBarConfig(labels, datasets){
    // datasets = [{label, data:[%...]}], 모든 합=100 가정
    return {
      type: 'bar',
      data: { labels: labels, datasets: datasets.map(function(d){ return { label:d.label, data:d.data, stack:'stack' }; }) },
      options: {
        indexAxis: 'y',
        responsive: true,
        plugins: { legend: { position:'bottom' }, tooltip:{ callbacks:{ label:function(ctx){ return ctx.dataset.label + ': ' + ctx.raw + '%'; } } } },
        scales: { x: { stacked:true, min:0, max:100, ticks:{ callback:function(v){ return v + '%'; } } }, y: { stacked:true } }
      }
    };
  }

  /* ===== 차트 그리기 ===== */
  function drawTrend(points){
    cachedTrend = points || [];
    var labels = cachedTrend.map(function(p){ return p.date; });
    var data   = cachedTrend.map(function(p){ return p.count || 0; });
    if (trendChart) trendChart.destroy();
    trendChart = new Chart(qs('trendChart'), asLineAreaConfig(labels, data, '일별 판매'));
  }

  function drawProductChart(rows){
    cachedProducts = rows || [];
    var labels = cachedProducts.map(function(r){ return r.cardName || ('카드#' + r.cardNo); });
    var data   = cachedProducts.map(function(r){ return r.issuedCount || 0; });
    if (productChart) productChart.destroy();
    productChart = new Chart(qs('productChart'), asHBarConfig(labels, data, '판매량(발급완료)'));
  }

  function drawFunnel(f){
    cachedFunnel = f || {};
    var labels = ['DRAFT','KYC_PASSED','ACCOUNT_CONFIRMED','OPTIONS_SET','ISSUED','CANCELLED'];
    var vals = [
      f && f.draft || 0, f && f.kycPassed || 0, f && f.accountConfirmed || 0,
      f && f.optionsSet || 0, f && f.issued || 0, f && f.cancelled || 0
    ];
    if (funnelChart) funnelChart.destroy();
    funnelChart = new Chart(qs('funnelChart'), asHBarConfig(labels, vals, '건수'));
  }

  function drawGender(demos){
    cachedDemos = demos || [];
    var totalMale   = sum(cachedDemos.map(function(d){ return d.maleCount || 0; }));
    var totalFemale = sum(cachedDemos.map(function(d){ return d.femaleCount || 0; }));
    if (genderChart) genderChart.destroy();
    genderChart = new Chart(qs('genderChart'), asDonutConfig(['남성','여성'], [totalMale, totalFemale], '성별 비율'));
  }

  function drawAge(demos){
    var a10 = sum(demos.map(function(d){ return d.age10s || 0; }));
    var a20 = sum(demos.map(function(d){ return d.age20s || 0; }));
    var a30 = sum(demos.map(function(d){ return d.age30s || 0; }));
    var a40 = sum(demos.map(function(d){ return d.age40s || 0; }));
    var a50 = sum(demos.map(function(d){ return d.age50s || 0; }));
    var a60 = sum(demos.map(function(d){ return d.age60s || 0; }));

    var tot = a10+a20+a30+a40+a50+a60;
    function pct(v){ return tot ? Math.round(v*1000/tot)/10 : 0; }
    var labels = ['연령 분포'];
    var datasets = [
      { label:'10대', data:[pct(a10)] },
      { label:'20대', data:[pct(a20)] },
      { label:'30대', data:[pct(a30)] },
      { label:'40대', data:[pct(a40)] },
      { label:'50대', data:[pct(a50)] },
      { label:'60대+',data:[pct(a60)] }
    ];

    if (ageChart) ageChart.destroy();
    ageChart = new Chart(qs('ageChart'), asStacked100HBarConfig(labels, datasets));
  }

  function fillTable(rows){
    var tb = qs('tbl').querySelector('tbody');
    tb.innerHTML = '';
    rows.forEach(function(r){
      tb.innerHTML += ''
        + '<tr>'
        +   '<td>' + (r.cardNo!=null ? r.cardNo : '') + '</td>'
        +   '<td>' + (r.cardName || '') + '</td>'
        +   '<td>' + (r.applyCount || 0) + '</td>'
        +   '<td>' + (r.approvedCount || 0) + '</td>'
        +   '<td>' + (r.issuedCount || 0) + '</td>'
        + '</tr>';
    });
  }

  /* ===== 데이터 로딩 ===== */
  function fetchOverview(){         return getJSON(apiBase() + '/overview'         + qp()); }
  function fetchTrendData(){        return getJSON(apiBase() + '/sales-trend'      + qp()); }
  function fetchSalesByProduct(){   return getJSON(apiBase() + '/sales-by-product' + qp() + '&top=10'); }
  function fetchFunnel(){           return getJSON(apiBase() + '/funnel'           + qp()); }
  function fetchDemographics(){     return getJSON(apiBase() + '/demographics'     + qp()); }

  function refresh(){
    return Promise.all([
      fetchOverview().then(setKpi),
      fetchTrendData().then(drawTrend),
      fetchSalesByProduct().then(function(rows){ drawProductChart(rows); fillTable(rows); }),
      fetchFunnel().then(drawFunnel),
      fetchDemographics().then(function(d){ drawGender(d); drawAge(d); })
    ]);
  }

  /* ===== PDF 생성 (전체 리포트 형식) ===== */
  async function makePdfBlob(){
    var node = document.getElementById('reportRoot');
    var { jsPDF } = window.jspdf;
    var pdf = new jsPDF('p', 'mm', 'a4');

    // 고해상도 캡처 후 페이지 분할
    var canvas = await html2canvas(node, { scale: 2, backgroundColor: '#ffffff' });
    var imgData = canvas.toDataURL('image/png');

    var pageW = 210, pageH = 297, margin = 10;
    var imgW = pageW - margin*2;
    var imgH = canvas.height * imgW / canvas.width;

    if (imgH <= pageH - margin*2) {
      pdf.addImage(imgData, 'PNG', margin, margin, imgW, imgH);
    } else {
      // 세로로 나눠서 여러 페이지에 출력
      var pxPerMm = canvas.width / imgW;
      var sliceHpx = Math.floor((pageH - margin*2) * pxPerMm);
      var y = 0;
      while (y < canvas.height) {
        var slice = document.createElement('canvas');
        slice.width = canvas.width;
        slice.height = Math.min(sliceHpx, canvas.height - y);
        var ctx = slice.getContext('2d');
        ctx.drawImage(canvas, 0, y, canvas.width, slice.height, 0, 0, canvas.width, slice.height);
        var part = slice.toDataURL('image/png');
        pdf.addImage(part, 'PNG', margin, margin, imgW, slice.height * (imgW/canvas.width));
        y += slice.height;
        if (y < canvas.height) pdf.addPage();
      }
    }
    return pdf.output('blob');
  }
  function openBlobInNewTab(blob){ var url = URL.createObjectURL(blob); var w = window.open(url, '_blank'); if (w) w.onload = function(){ URL.revokeObjectURL(url); }; }
  async function pdfPreview(){ var b = await makePdfBlob(); openBlobInNewTab(b); }
  async function pdfDownload(){
    var b = await makePdfBlob();
    var a = document.createElement('a');
    a.href = URL.createObjectURL(b);
    a.download = '리포트_' + qs('from').value + '_' + qs('to').value + '.pdf';
    a.click();
    setTimeout(function(){ URL.revokeObjectURL(a.href); }, 1000);
  }

  /* ===== Excel 생성 (섹션별 시트) ===== */
  function toAOA_KPI(ov){
    return [
      ['지표','값'],
      ['신규 신청', ov && ov.applies || 0],
      ['승인',      ov && ov.approved || 0],
      ['판매(발급완료)', ov && ov.issued || 0],
      ['전주 대비(판매, %)', ov && (ov.wowIssuedDeltaPct!=null ? ov.wowIssuedDeltaPct + '%' : '-') ]
    ];
  }
  function toAOA_Trend(points){
    var rows = [['날짜','판매']];
    (points||[]).forEach(function(p){ rows.push([p.date, p.count||0]); });
    return rows;
  }
  function toAOA_Products(rows){
    var out = [['카드번호','카드명','신청','승인','발급완료']];
    (rows||[]).forEach(function(r){
      out.push([r.cardNo, r.cardName, r.applyCount||0, r.approvedCount||0, r.issuedCount||0]);
    });
    return out;
  }
  function toAOA_Funnel(f){
    return [
      ['단계','건수'],
      ['DRAFT',             f && f.draft || 0],
      ['KYC_PASSED',        f && f.kycPassed || 0],
      ['ACCOUNT_CONFIRMED', f && f.accountConfirmed || 0],
      ['OPTIONS_SET',       f && f.optionsSet || 0],
      ['ISSUED',            f && f.issued || 0],
      ['CANCELLED',         f && f.cancelled || 0]
    ];
  }
  function toAOA_Demos(d){
    var rows = [['카드번호','카드명','판매','남','여','10대','20대','30대','40대','50대','60대+']];
    (d||[]).forEach(function(x){
      rows.push([
        x.cardNo, x.cardName, x.salesCount||0,
        x.maleCount||0, x.femaleCount||0,
        x.age10s||0, x.age20s||0, x.age30s||0, x.age40s||0, x.age50s||0, x.age60s||0
      ]);
    });
    return rows;
  }
  function buildWorkbook(){
    var wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(toAOA_KPI(cachedOverview)), 'KPI');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(toAOA_Trend(cachedTrend)), '판매추세');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(toAOA_Products(cachedProducts)), '상품별판매');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(toAOA_Funnel(cachedFunnel)), '퍼널');
    XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(toAOA_Demos(cachedDemos)), '가입자현황');
    return wb;
  }
  function xlsxPreview(){
    var wb = buildWorkbook();
    var html = '';
    function sect(name){
      html += '<h3>' + name + '</h3>' + XLSX.utils.sheet_to_html(wb.Sheets[name]) + '<hr/>';
    }
    sect('KPI'); sect('판매추세'); sect('상품별판매'); sect('퍼널'); sect('가입자현황');
    var w = window.open('', '_blank');
    w.document.write('<html><head><meta charset="utf-8"><title>Excel 미리보기</title></head><body style="font-family:system-ui,Arial;">' + html + '</body></html>');
    w.document.close();
  }
  function xlsxDownload(){
    var wb = buildWorkbook();
    XLSX.writeFile(wb, '리포트_' + qs('from').value + '_' + qs('to').value + '.xlsx');
  }

  /* ===== 초기화 ===== */
  setDefaultDates();
  qs('btnFetch').addEventListener('click', function(){ refresh().catch(console.error); });
  qs('btnPdfPreview').addEventListener('click', function(){ pdfPreview().catch(console.error); });
  qs('btnPdfDownload').addEventListener('click', function(){ pdfDownload().catch(console.error); });
  qs('btnXlsxPreview').addEventListener('click', function(){ xlsxPreview(); });
  qs('btnXlsxDownload').addEventListener('click', function(){ xlsxDownload(); });

  // 첫 로드
  refresh().catch(console.error);
</script>
</body>
</html>
