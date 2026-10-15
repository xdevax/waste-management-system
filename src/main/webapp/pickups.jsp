<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<html>
<head>
  <title>Pickups &mdash; WMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>
<jsp:include page="nav.jsp"/>
<div class="wrap">
  <h2>Pickup Records</h2>

  <c:if test="${not empty sessionScope.flash}">
    <div class="flash">${sessionScope.flash}</div>
    <c:remove var="flash" scope="session"/>
  </c:if>

  <div class="card">
    <h3>Record Pickup</h3>
    <form method="post" action="${pageContext.request.contextPath}/pickups">
      <input type="hidden" name="action" value="add"/>
      <div class="grid">
        <div><label>Bin</label>
          <select name="bin_id">
            <c:forEach var="b" items="${binOpts}"><option value="${b.key}">${b.value}</option></c:forEach>
          </select>
        </div>
        <div><label>Collector</label>
          <select name="collector_id">
            <c:forEach var="k" items="${colOpts}"><option value="${k.key}">${k.value}</option></c:forEach>
          </select>
        </div>
        <div><label>Date</label><input name="pickup_date" type="date" required/></div>
        <div><label>Weight (kg)</label>
             <input name="weight" type="number" step="0.01" min="0.01" required/></div>
        <div><button type="submit">Add Pickup</button></div>
      </div>
    </form>
  </div>

  <div class="card">
    <form method="get" action="${pageContext.request.contextPath}/pickups">
      <div class="grid">
        <div><label>Search by bin or collector</label><input name="q" value="${search}"/></div>
        <div><button type="submit">Search</button></div>
        <div><a class="btn btn-grey" href="${pageContext.request.contextPath}/pickups">Reset</a></div>
      </div>
    </form>
  </div>

  <table>
    <tr><th>ID</th><th>Bin</th><th>Collector</th><th>Date</th><th>Weight (kg)</th><th>Actions</th></tr>
    <c:forEach var="p" items="${pickups}">
      <tr>
        <td>${p.id}</td><td>${p.binLocation}</td><td>${p.collectorName}</td>
        <td>${p.pickupDate}</td><td>${p.weight}</td>
        <td>
          <a class="btn btn-sm" href="${pageContext.request.contextPath}/pickups/edit?id=${p.id}">Edit</a>
          <form style="display:inline" method="post"
                action="${pageContext.request.contextPath}/pickups"
                onsubmit="return confirm('Delete pickup #${p.id}?')">
            <input type="hidden" name="action" value="delete"/>
            <input type="hidden" name="pickup_id" value="${p.id}"/>
            <button class="btn-sm btn-red">Delete</button>
          </form>
        </td>
      </tr>
    </c:forEach>
    <c:if test="${empty pickups}"><tr><td colspan="6" class="empty">No pickups found.</td></tr></c:if>
  </table>
</div>
</body>
</html>