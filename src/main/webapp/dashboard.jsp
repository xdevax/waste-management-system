<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<html>
<head>
  <title>Dashboard &mdash; WMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>
<jsp:include page="nav.jsp"/>
<div class="wrap">
  <h2>Dashboard</h2>

  <div class="stats">
    <div class="stat"><div class="n">${binCount}</div><div class="l">Total Bins</div></div>
    <div class="stat"><div class="n">${colCount}</div><div class="l">Collectors</div></div>
    <div class="stat"><div class="n">${pickCount}</div><div class="l">Pickups</div></div>
    <div class="stat"><div class="n">${zoneCount}</div><div class="l">Zones</div></div>
    <div class="stat"><div class="n"><fmt:formatNumber value="${totalKg}" maxFractionDigits="1"/></div>
         <div class="l">Total Collected (kg)</div></div>
  </div>

  <div class="card">
    <h3>Bins &amp; Collection per Zone (GROUP BY)</h3>
    <table>
      <tr><th>Zone</th><th>Bins</th><th>Collected (kg)</th></tr>
      <c:forEach var="r" items="${perZone}">
        <tr><td>${r[0]}</td><td>${r[1]}</td><td>${r[2]}</td></tr>
      </c:forEach>
    </table>
  </div>

  <div class="card">
    <h3>Collector Performance (GROUP BY + HAVING)</h3>
    <table>
      <tr><th>Collector</th><th>Pickups</th><th>Total (kg)</th></tr>
      <c:forEach var="r" items="${perCol}">
        <tr><td>${r[0]}</td><td>${r[1]}</td><td>${r[2]}</td></tr>
      </c:forEach>
      <c:if test="${empty perCol}">
        <tr><td colspan="3" class="empty">No pickups recorded yet.</td></tr>
      </c:if>
    </table>
  </div>

  <div class="card">
    <h3>Bins Above Average Capacity (Subquery)</h3>
    <table>
      <tr><th>Location</th><th>Capacity (kg)</th></tr>
      <c:forEach var="r" items="${aboveAvg}">
        <tr><td>${r[0]}</td><td>${r[1]}</td></tr>
      </c:forEach>
      <c:if test="${empty aboveAvg}">
        <tr><td colspan="2" class="empty">No bins above average.</td></tr>
      </c:if>
    </table>
  </div>
</div>
</body>
</html>