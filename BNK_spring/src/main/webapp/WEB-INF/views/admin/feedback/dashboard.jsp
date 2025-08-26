<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<%@ taglib prefix="fn" uri="jakarta.tags.functions"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>피드백 대시보드</title>
<style>
:root {
	--bg: #fff;
	--txt: #111;
	--muted: #808089;
	--line: #ececec;
	--card: #f8f9fb;
	--pill: #eef1f7;
	--good: #28a745;
	--bad: #dc3545;
	--neutral: #6c757d;
	--accent: #3b82f6;
}

* {
	box-sizing: border-box
}

body {
	font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial,
		sans-serif;
	color: var(--txt);
	background: var(--bg)
}

.wrapper{
	max-width:1100px;
	margin:0 auto;
}

h1 {
	font-size: 28px;
	margin: 0 0 12px
}

.title{
    margin: 0 auto;
    width: 300px;
    padding: 30px;

}

h2 {
	font-size: 18px;
	margin: 26px 0 10px
}

.muted {
	color: var(--muted)
}

.grid {
	display: grid;
	gap: 12px
}

.kpis {
	grid-template-columns: repeat(4, minmax(180px, 1fr))
}

.card {
	background: var(--card);
	border: 1px solid var(--line);
	border-radius: 12px;
	padding: 14px
}

.kpi-title {
	font-size: 12px;
	color: var(--muted);
	margin-bottom: 6px
}

.kpi-number {
	font-size: 22px;
	font-weight: 700
}

.kpi-sub {
	font-size: 12px;
	color: var(--muted)
}

.progress {
	height: 10px;
	background: #f1f3f5;
	border-radius: 999px;
	overflow: hidden
}

.bar {
	height: 100%
}

.bar.good {
	background: var(--good)
}

.bar.bad {
	background: var(--bad)
}

.bar.neutral {
	background: var(--neutral)
}

table {
	width: 100%;
	border-collapse: collapse;
	background: #fff;
	border: 1px solid var(--line);
	border-radius: 12px;
	overflow: hidden
}

th, td {
	padding: 12px 10px;
	border-bottom: 1px solid var(--line);
	vertical-align: top;
	font-size: 14px
}

th {
	background: #fafbfc;
	text-align: left;
	font-weight: 700
}

tr:last-child td {
	border-bottom: none
}

.pill {
	display: inline-block;
	padding: 2px 8px;
	border-radius: 999px;
	background: var(--pill);
	font-size: 12px
}

.kw-bar {
	height: 8px;
	background: #eef2ff;
	border-radius: 999px;
	overflow: hidden
}

.kw-fill {
	height: 100%;
	background: var(--accent)
}

.section-head {
	display: flex;
	align-items: end;
	gap: 10px
}

.section-head small {
	color: var(--muted)
}

/* 필터바 */
.filters {
	display: flex;
	gap: 10px;
	align-items: center;
	background: var(--card);
	border: 1px solid var(--line);
	border-radius: 12px;
	padding: 10px;
	margin: 10px 0 16px
}

.filters label {
	font-size: 13px;
	color: var(--muted)
}

.filters input {
	width: 110px;
	padding: 6px 8px;
	border: 1px solid var(--line);
	border-radius: 8px
}

.filters button {
	padding: 8px 12px;
	border: 0;
	background: var(--accent);
	color: #fff;
	border-radius: 8px;
	font-weight: 600;
	cursor: pointer
}

.filters a {
	margin-left: auto;
	font-size: 13px;
	color: var(--muted);
	text-decoration: none
}

@media ( max-width :980px) {
	.kpis {
		grid-template-columns: repeat(2, 1fr)
	}
	.filters {
		flex-wrap: wrap
	}
}
</style>
<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
	<jsp:include page="../../fragments/header.jsp"></jsp:include>
	
	<div class="wrapper">
	<h1 class="title">피드백 대시보드</h1>

	<!-- 컨트롤러가 days/top/minScore를 안 줬어도 안전하게 기본값 보정 -->
	<c:set var="days" value="${empty days ? 30 : days}" />
	<c:set var="top" value="${empty top ? 10 : top}" />
	<c:set var="minScore" value="${minScore}" />

	<!-- 상단 필터 -->
	<form class="filters" action="/admin/feedback" method="get">
		<label>상위 N <input type="number" name="top" value="${top}"
			min="1" max="50" />
		</label> <label>최근 일수 <input type="number" name="days" value="${days}"
			min="1" max="365" />
		</label> <label>신뢰도 컷(0~1) <input type="number" step="0.01" min="0"
			max="1" name="minScore" value="<c:out value='${minScore}'/>"
			placeholder="예: 0.55" />
		</label>
		<button type="submit">적용</button>
		<a href="/admin/feedback">초기화</a>
	</form>

	<c:if test="${empty summary}">
		<p class="muted">데이터가 없습니다.</p>
	</c:if>

	<c:if test="${not empty summary}">
		<!-- 비율/요약 KPI -->
		<c:set var="posPct" value="${summary.positiveRatio * 100}" />
		<c:set var="negPct" value="${summary.negativeRatio * 100}" />
		<c:set var="neuPct"
			value="${(1 - summary.positiveRatio - summary.negativeRatio) * 100}" />

		<div class="grid kpis">
			<div class="card">
				<div class="kpi-title">긍정 비율</div>
				<div class="kpi-number">
					<fmt:formatNumber value="${posPct}" maxFractionDigits="1" />
					%
				</div>
				<div class="progress" style="margin-top: 8px">
					<div class="bar good" style="width:${posPct}%;"></div>
				</div>
			</div>
			<div class="card">
				<div class="kpi-title">부정 비율</div>
				<div class="kpi-number">
					<fmt:formatNumber value="${negPct}" maxFractionDigits="1" />
					%
				</div>
				<div class="progress" style="margin-top: 8px">
					<div class="bar bad" style="width:${negPct}%;"></div>
				</div>
			</div>
			<div class="card">
				<div class="kpi-title">중립/기타 추정</div>
				<div class="kpi-number">
					<fmt:formatNumber value="${neuPct < 0 ? 0 : neuPct}"
						maxFractionDigits="1" />
					%
				</div>
				<div class="progress" style="margin-top: 8px">
					<div class="bar neutral" style="width:${neuPct < 0 ? 0 : neuPct}%;"></div>
				</div>
				<div class="kpi-sub">* POS/NEG 외 비율(추정)</div>
			</div>
			<div class="card">
				<div class="kpi-title">평균 평점</div>
				<div class="kpi-number">
					<fmt:formatNumber value="${summary.avgRating}"
						maxFractionDigits="2" />
				</div>
				<div class="kpi-sub">스케일 1~5</div>
			</div>
		</div>

		<!-- 키워드 TOP N -->
		<div class="section-head">
			<h2>
				상위 키워드 <small>(상위 ${top}개)</small>
			</h2>
		</div>
		<table>
			<thead>
				<tr>
					<th style="width: 64px">순위</th>
					<th>키워드</th>
					<th style="width: 140px">건수</th>
					<th style="width: 220px">비율(상위 대비)</th>
				</tr>
			</thead>
			<tbody>
				<c:choose>
					<c:when test="${empty summary.topKeywords}">
						<tr>
							<td colspan="4" class="muted">집계된 키워드가 없습니다.</td>
						</tr>
					</c:when>
					<c:otherwise>
						<c:set var="kwMax" value="1" />
						<c:forEach var="k" items="${summary.topKeywords}" varStatus="st">
							<c:if test="${st.first}">
								<c:set var="kwMax" value="${k.count}" />
							</c:if>
							<c:set var="ratio"
								value="${kwMax == 0 ? 0 : (k.count * 100.0) / kwMax}" />
							<tr>
								<td>${st.index + 1}</td>
								<td><c:out value="${k.keyword}" /></td>
								<td><fmt:formatNumber value="${k.count}" /></td>
								<td><div class="kw-bar">
										<div class="kw-fill" style="width:${ratio}%;"></div>
									</div></td>
							</tr>
						</c:forEach>
					</c:otherwise>
				</c:choose>
			</tbody>
		</table>

		<!-- 최근 피드백 -->
		<h2>최근 피드백 (최대 20건)</h2>
		<table>
			<thead>
				<tr>
					<th style="width: 90px">번호</th>
					<th style="width: 160px">작성일시</th>
					<th style="width: 80px">평점</th>
					<th>의견</th>
					<th style="width: 120px">라벨</th>
					<th style="width: 120px">점수</th>
					<th style="width: 220px">키워드</th>
				</tr>
			</thead>
			<tbody>
				<c:choose>
					<c:when test="${empty summary.recent}">
						<tr>
							<td colspan="7" class="muted">최근 등록된 피드백이 없습니다.</td>
						</tr>
					</c:when>
					<c:otherwise>
						<c:forEach var="f" items="${summary.recent}">
							<tr>
								<td>${f.feedbackNo}</td>
								<td><fmt:formatDate value="${f.createdAt}"
										pattern="yyyy-MM-dd HH:mm" /></td>
								<td>${f.rating}</td>
								<td><c:set var="cmt"
										value="${not empty f.feedbackComment ? f.feedbackComment : (not empty f.comment ? f.comment : '')}" />
									<c:out
										value="${fn:length(cmt) > 90 ? fn:substring(cmt,0,90).concat('…') : cmt}" />
								</td>
								<td><c:out value="${f.sentimentLabel}" /></td>
								<td><c:if test="${not empty f.sentimentScore}">
										<fmt:formatNumber value="${f.sentimentScore}"
											maxFractionDigits="3" />
									</c:if></td>
								<td><c:forEach var="kw"
										items="${fn:split(empty f.aiKeywords ? '' : f.aiKeywords, ',')}">
										<c:if test="${not empty kw}">
											<span class="pill"><c:out value="${kw}" /></span>&nbsp;</c:if>
									</c:forEach></td>
							</tr>
						</c:forEach>
					</c:otherwise>
				</c:choose>
			</tbody>
		</table>

		<!-- 이상 패턴 -->
		<h2>이상 패턴 (Y)</h2>
		<table>
			<thead>
				<tr>
					<th style="width: 90px">번호</th>
					<th>사유</th>
					<th style="width: 120px">라벨</th>
					<th style="width: 120px">점수</th>
					<th style="width: 160px">작성일시</th>
				</tr>
			</thead>
			<tbody>
				<c:choose>
					<c:when test="${empty summary.anomalies}">
						<tr>
							<td colspan="5" class="muted">감지된 이상 패턴이 없습니다.</td>
						</tr>
					</c:when>
					<c:otherwise>
						<c:forEach var="a" items="${summary.anomalies}">
							<tr>
								<td>${a.feedbackNo}</td>
								<td><c:out value="${a.inconsistencyReason}" /></td>
								<td><c:out value="${a.sentimentLabel}" /></td>
								<td><c:if test="${not empty a.sentimentScore}">
										<fmt:formatNumber value="${a.sentimentScore}"
											maxFractionDigits="3" />
									</c:if></td>
								<td><fmt:formatDate value="${a.createdAt}"
										pattern="yyyy-MM-dd HH:mm" /></td>
							</tr>
						</c:forEach>
					</c:otherwise>
				</c:choose>
			</tbody>
		</table>
	</c:if>

	<!-- 인사이트 -->
	<c:if test="${not empty insights}">
		<div class="section-head">
			<h2>
				인사이트 <small>(최근 ${days}일, 상위 주제)</small>
			</h2>
		</div>

		<div class="grid" style="grid-template-columns: 1fr 1fr">
			<!-- 긍정 상위 주제 -->
			<div class="card">
				<div class="kpi-title">긍정 상위 주제</div>
				<c:choose>
					<c:when test="${empty insights.topPositive}">
						<div class="muted">데이터가 없습니다.</div>
					</c:when>
					<c:otherwise>
						<table>
							<thead>
								<tr>
									<th>주제</th>
									<th style="width: 90px">건수</th>
									<th style="width: 180px">긍정비율</th>
									<th style="width: 90px">평점</th>
								</tr>
							</thead>
							<tbody>
								<c:forEach var="t" items="${insights.topPositive}">
									<c:set var="ppct" value="${t.positiveRatio * 100}" />
									<tr>
										<td>
											<div style="font-weight: 700">
												<c:out value="${t.topic}" />
											</div> <c:forEach var="ex" items="${t.examples}">
												<div class="muted" style="margin-top: 4px">
													#${ex.feedbackNo} ★${ex.rating} ·
													<c:out value="${ex.comment}" />
												</div>
											</c:forEach>
										</td>
										<td><fmt:formatNumber value="${t.total}" /></td>
										<td>
											<div class="progress" style="height: 8px; margin-top: 4px">
												<div class="bar good" style="width:${ppct}%;"></div>
											</div>
											<div class="kpi-sub">
												<fmt:formatNumber value="${ppct}" maxFractionDigits="0" />
												%
											</div>
										</td>
										<td><c:choose>
												<c:when test="${not empty t.avgRating}">
													<fmt:formatNumber value="${t.avgRating}"
														maxFractionDigits="2" />
												</c:when>
												<c:otherwise>-</c:otherwise>
											</c:choose></td>
									</tr>
								</c:forEach>
							</tbody>
						</table>
					</c:otherwise>
				</c:choose>
			</div>

			<!-- 부정 상위 주제 -->
			<div class="card">
				<div class="kpi-title">부정 상위 주제</div>
				<c:choose>
					<c:when test="${empty insights.topNegative}">
						<div class="muted">데이터가 없습니다.</div>
					</c:when>
					<c:otherwise>
						<table>
							<thead>
								<tr>
									<th>주제</th>
									<th style="width: 90px">건수</th>
									<th style="width: 180px">부정비율</th>
									<th style="width: 90px">평점</th>
								</tr>
							</thead>
							<tbody>
								<c:forEach var="t" items="${insights.topNegative}">
									<c:set var="negPct"
										value="${(t.negative * 100.0) / (t.total == 0 ? 1 : t.total)}" />
									<tr>
										<td>
											<div style="font-weight: 700">
												<c:out value="${t.topic}" />
											</div> <c:forEach var="ex" items="${t.examples}">
												<div class="muted" style="margin-top: 4px">
													#${ex.feedbackNo} ★${ex.rating} ·
													<c:out value="${ex.comment}" />
												</div>
											</c:forEach>
										</td>
										<td><fmt:formatNumber value="${t.total}" /></td>
										<td>
											<div class="progress" style="height: 8px; margin-top: 4px">
												<div class="bar bad" style="width:${negPct}%;"></div>
											</div>
											<div class="kpi-sub">
												<fmt:formatNumber value="${negPct}" maxFractionDigits="0" />
												%
											</div>
										</td>
										<td><c:choose>
												<c:when test="${not empty t.avgRating}">
													<fmt:formatNumber value="${t.avgRating}"
														maxFractionDigits="2" />
												</c:when>
												<c:otherwise>-</c:otherwise>
											</c:choose></td>
									</tr>
								</c:forEach>
							</tbody>
						</table>
					</c:otherwise>
				</c:choose>
			</div>
		</div>

		<!-- 원시 JSON 보기 링크(디버깅/검증용) -->
		<div style="margin-top: 8px" class="muted">
			원시 데이터: <a
				href="/admin/feedback/insights.json?days=${days}&limit=${top}<c:if test='${not empty minScore}'>&minScore=${minScore}</c:if>"
				target="_blank">
				/admin/feedback/insights.json?days=${days}&limit=${top}<c:if
					test='${not empty minScore}'>&minScore=${minScore}</c:if>
			</a>
		</div>
	</c:if>
	</div>
<script src="/js/adminHeader.js"></script>
</body>
</html>
