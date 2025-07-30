<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>관리자 검색 통계</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
   <link rel="stylesheet" href="/css/adminstyle.css">
  <style>
 
  
    body {
      font-family: 'Segoe UI', sans-serif;
      background-color: #f9f9f9;
    }
    h1 {
      text-align: center;
    }
    h2 {
      margin-top: 40px;
      text-align: center;
      color: #2c3e50;
      cursor: pointer;
      background-color: #f1f3f5;
      padding: 10px;
      border-radius: 6px;
    }
    .chart-container, .table-container, .list-container, .button-group {
      overflow: visible;
      margin: 20px auto;
      max-width: 800px;
    }
    canvas {
      width: 100% !important;
      margin-bottom: 40px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
    }
    th, td {
      border: 1px solid #ccc;
      padding: 10px;
      text-align: center;
    }
    th {
      background-color: #f8f9fa;
    }
    ul {
      list-style: none;
      padding-left: 0;
    }
    .btn {
      padding: 5px 10px;
      margin: 5px;
      cursor: pointer;
      background: #3498db;
      color: white;
      border: none;
      border-radius: 4px;
    }
    .chart-container, .list-container, .table-container2 {
      display: none;
      flex-direction: column;
      align-items: center;
    }
    .ranked-list {
      list-style: none;
      padding: 0;
      margin: 10px auto;
      width: 80%;
      max-width: 300px;
      max-height: 300px;
      border: 1px solid #ddd;
      border-radius: 8px;
      background: #fcfcfc;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    .ranked-list li {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 4px 10px;
      font-size: 13.5px;
      height: 28px;
      border-bottom: 1px solid #eee;
      white-space: nowrap;
    }
    .ranked-list li:last-child {
      border-bottom: none;
    }
    .ranked-list .rank {
      width: 22px;
      text-align: right;
      font-weight: bold;
      color: #555;
      flex-shrink: 0;
      margin-right: 8px;
      font-size: 12.5px;
    }
    .ranked-list .keyword {
      flex: 1;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      font-size: 13px;
      color: #333;
    }
    .ranked-list .count {
      width: 40px;
      text-align: right;
      font-size: 12.5px;
      color: #999;
    }
    
.table-container2 {
  display: none;
  max-width: 500px;
  margin: 0 auto;
}

.table-container2 table {
  width: 100%;
  table-layout: fixed; /* 각 열 폭 균일하게 */
  border-collapse: collapse;
  text-align: center;
}

.table-container2 th, .table-container2 td {
  padding: 6px 8px;
  font-size: 13px;
  white-space: nowrap;
}

  #userTypeChart {
    max-width: 400px;
    max-height: 400px;
  }
    
      #genderChart {
    max-width: 400px;
    max-height: 400px;
  }
  
  canvas {
  display: block;
  margin: 0 auto 40px auto; /* 가운데 정렬 + 아래 여백 */
  width: 100% !important;
}
  </style>
</head>
<body>
<jsp:include page="../fragments/header.jsp"></jsp:include>
<h1>관리자 검색 통계</h1>

<h2 onclick="toggleSection('userTypeSection')">1. 회원/비회원 검색 비율</h2>
<div id="userTypeSection" class="chart-container">
  <canvas id="userTypeChart"></canvas>
  <div class="table-container">
    <table>
      <thead><tr><th>구분</th><th>검색 건수</th></tr></thead>
      <tbody id="userTypeTableBody"></tbody>
    </table>
  </div>
</div>

<h2 onclick="toggleSection('ageGroupSection')">2. 나이대별 검색 비율</h2>
<div id="ageGroupSection" class="chart-container">
  <canvas id="ageGroupChart"></canvas>
  <div class="table-container">
    <table>
      <thead><tr><th>나이대</th><th>조회수</th></tr></thead>
      <tbody id="ageGroupTableBody"></tbody>
    </table>
  </div>
</div>

<h2 onclick="toggleSection('genderChartSection')">3. 성별별 검색 비율</h2>
<div id="genderChartSection" class="chart-container">
  <canvas id="genderChart"></canvas>
  <div class="table-container">
    <table>
      <thead><tr><th>성별</th><th>조회수</th></tr></thead>
      <tbody id="genderTableBody"></tbody>
    </table>
  </div>
</div>

<h2 onclick="toggleSection('topCardsSection')">4. 조회수가 높은 카드 순위</h2>
<div id="topCardsSection" class="list-container">
  <ul id="topCardsList" class="ranked-list"></ul>
</div>

<h2 onclick="toggleSection('topKeywordsSection')">5. 인기 검색어 TOP10</h2>
<div id="topKeywordsSection" class="list-container">
  <div style="text-align:center;">
    <button class="btn" onclick="loadTopKeywords('member')">회원</button>
    <button class="btn" onclick="loadTopKeywords('nonmember')">비회원</button>
    <h3 id="keywordTitle">선택된 대상 없음</h3>
  </div>
  <ul id="topKeywordsList" class="ranked-list"></ul>
</div>

<h2 onclick="toggleSection('recommendedRateSection')">6. 추천어 전환율</h2>
<div id="recommendedRateSection" class="table-container2">
  <table>
    <thead>
      <tr><th>전체 검색</th><th>추천 검색</th><th>전환율 (%)</th></tr>
    </thead>
    <tbody id="recommendTableBody"></tbody>
  </table>
</div>

<h2 onclick="toggleSection('searchByHourSection')">7. 시간대별 검색 건수</h2>
<div id="searchByHourSection" class="chart-container">
  <div class="button-group" style="text-align:center;">
    <button class="btn" onclick="loadHourlyStats('하루')">하루</button>
    <button class="btn" onclick="loadHourlyStats('일주일')">일주일</button>
    <button class="btn" onclick="loadHourlyStats('한달')">한달</button>
    <button class="btn" onclick="loadHourlyStats('6개월')">6개월</button>
    <button class="btn" onclick="loadHourlyStats('1년')">1년</button>
    <button class="btn" onclick="loadHourlyStats('5년')">5년</button>
    <button class="btn" onclick="loadHourlyStats('전체')">전체</button>
  </div>
  <div class="hour-content">
    <canvas id="hourChart"></canvas>
    <div class="table-container">
      <table>
        <tbody id="hourlyStatsTableBody"></tbody>
      </table>
    </div>
  </div>
</div>


<script src="/js/adminHeader.js"></script>

<script>
let hourChartInstance;

function toggleSection(id) {
  const el = document.getElementById(id);
  const visible = el.style.display === 'block';
  el.style.display = visible ? 'none' : 'block';
  if (!visible && !el.dataset.loaded) {
    loadDataFor(id);
    el.dataset.loaded = 'true';
  }
}

function loadDataFor(id) {
  const map = {
    userTypeSection: loadUserTypeChart,
    ageGroupSection: loadAgeGroupChart,
    genderChartSection: loadGenderChart,
    topCardsSection: loadTopCards,
    topKeywordsSection: () => {},
    recommendedRateSection: loadRecommendConversion,
    searchByHourSection: () => loadHourlyStats('day')
  };
  if (map[id]) map[id]();
}

function loadUserTypeChart() {
  fetch('/admin/Search/stats/userType')
    .then(res => res.json())
    .then(data => {
      new Chart(document.getElementById('userTypeChart'), {
        type: 'pie',
        data: {
          labels: ['회원', '비회원'],
          datasets: [{
            data: [data.member, data.nonmember],
            backgroundColor: ['#36A2EB', '#FF6384']
          }]
        }
      });
      const tbody = document.getElementById('userTypeTableBody');
      tbody.innerHTML = `
        <tr><td>회원</td><td>\${data.member}</td></tr>
        <tr><td>비회원</td><td>\${data.nonmember}</td></tr>
      `;
    });
}

function loadAgeGroupChart() {
  fetch('/admin/Search/stats/cardViewsByAgeGroup')
    .then(res => res.json())
    .then(data => {
      const labels = Object.keys(data);
      const values = Object.values(data);
      new Chart(document.getElementById('ageGroupChart'), {
        type: 'bar',
        data: {
          labels,
          datasets: [{
            label: '조회수',
            data: values,
            backgroundColor: 'rgba(75,192,192,0.5)'
          }]
        }
      });
      const tbody = document.getElementById('ageGroupTableBody');
      tbody.innerHTML = labels.map((label, i) =>
        `<tr><td>\${label}</td><td>\${values[i]}</td></tr>`
      ).join('');
    });
}

function loadGenderChart() {
  fetch('/admin/Search/stats/cardViewsByGender')
    .then(res => res.json())
    .then(data => {
      const labels = Object.keys(data);
      const values = Object.values(data);
      new Chart(document.getElementById('genderChart'), {
        type: 'doughnut',
        data: {
          labels,
          datasets: [{
            label: '성별 조회',
            data: values,
            backgroundColor: ['#ffc0cb', '#3498db']
          }]
        }
      });
      const tbody = document.getElementById('genderTableBody');
      tbody.innerHTML = labels.map((label, i) =>
        `<tr><td>\${label}</td><td>\${values[i]}</td></tr>`
      ).join('');
    });
}

function loadTopCards() {
  fetch('/admin/Search/stats/topCards')
    .then(res => res.json())
    .then(data => {
      const ul = document.getElementById('topCardsList');
      ul.innerHTML = '';
      data.forEach((item, idx) => {
        const li = document.createElement('li');
        li.innerHTML = `
          <span class="rank">\${idx + 1}.</span>
          <span class="keyword">\${item.cardName}</span>
          <span class="count">(\${item.viewCount})</span>
        `;
        ul.appendChild(li);
      });
    });
}

function loadTopKeywords(type) {
  const titleMap = {
    member: '회원 인기 검색어 TOP10',
    nonmember: '비회원 인기 검색어 TOP10'
  };
  fetch(`/admin/Search/stats/topKeywords?type=\${type}`)
    .then(res => res.json())
    .then(data => {
      const title = document.getElementById('keywordTitle');
      const ul = document.getElementById('topKeywordsList');
      title.textContent = titleMap[type] || '인기 검색어';
      ul.innerHTML = '';
      if (data.length === 0) {
        ul.innerHTML = '<li>데이터 없음</li>';
      } else {
        data.forEach((item, idx) => {
          const li = document.createElement('li');
          li.innerHTML = `
            <span class="rank">\${idx + 1}.</span>
            <span class="keyword">\${item.keyword}</span>
            <span class="count">(\${item.count})</span>
          `;
          ul.appendChild(li);
        });
      }
    });
}

function loadHourlyStats(period) {
  fetch(`/admin/Search/stats/searchByHour?period=\${period}`)
    .then(res => res.json())
    .then(data => {
      const labels = data.map(item => item.hour + "시");
      const values = data.map(item => item.count);
      if (hourChartInstance) hourChartInstance.destroy();
      hourChartInstance = new Chart(document.getElementById('hourChart'), {
        type: 'line',
        data: {
          labels,
          datasets: [{
            label: `\${period} 기준 시간대별 검색 건수`,
            data: values,
            borderColor: 'rgba(255, 99, 132, 1)',
            backgroundColor: 'rgba(255, 99, 132, 0.2)',
            tension: 0.4,
            fill: true,
            pointRadius: 5,
            pointHoverRadius: 7
          }]
        },
        options: {
          responsive: true,
          plugins: {
            legend: { display: true },
            tooltip: { mode: 'index', intersect: false }
          },
          interaction: {
            mode: 'nearest',
            axis: 'x',
            intersect: false
          },
          scales: {
            y: {
              beginAtZero: true,
              title: { display: true, text: '검색 건수' }
            },
            x: {
              title: { display: true, text: '시간대' }
            }
          }
        }
      });
      const tbody = document.getElementById('hourlyStatsTableBody');
      const timeRow = `<tr><th>시간</th>\${data.map(item => `<td>\${item.hour}시</td>`).join('')}</tr>`;
      const countRow = `<tr><th>검색건수</th>\${data.map(item => `<td>\${item.count}</td>`).join('')}</tr>`;
      tbody.innerHTML = timeRow + countRow;
    });
}

function loadRecommendConversion() {
  fetch('/admin/Search/stats/recommendedConversionRate')
    .then(res => res.json())
    .then(data => {
      const tbody = document.getElementById('recommendTableBody');
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>\${data.total}</td>
        <td>\${data.recommended}</td>
        <td>\${data.conversionRate}%</td>
      `;
      tbody.appendChild(tr);
    });
}
</script>
</body>
</html>
