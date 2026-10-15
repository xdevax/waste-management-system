<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<html>
<head>
  <title>Edit Pickup &mdash; WMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>
<jsp:include page="nav.jsp"/>
<div class="wrap">
  <h2>Edit Pickup #${pk.id}</h2>
  <div class="card">
    <form method="post" action="${pageContext.request.contextPath}/pickups">
      <input type="hidden" name="action" value="update"/>
      <input type="hidden" name="pickup_id" value="${pk.id}"/>
      <div class="grid">
        <div><label>Bin</label>
          <select name="bin_id">
            <c:forEach var="b" items="${binOpts}">
              <option value="${b.key}" ${b.key == pk.binId ? 'selected' : ''}>${b.value}</option>
            </c:forEach>
          </select>
        </div>
        <div><label>Collector</label>
          <select name="collector_id">
            <c:forEach var="k" items="${colOpts}">
              <option value="${k.key}" ${k.key == pk.collectorId ? 'selected' : ''}>${k.value}</option>
            </c:forEach>
          </select>
        </div>
        <div><label>Date</label>
             <input name="pickup_date" type="date" value="${pk.pickupDate}" required/></div>
        <div><label>Weight (kg)</label>
             <input name="weight" type="number" step="0.01" min="0.01" value="${pk.weight}" required/></div>
      </div>
      <div style="margin-top:18px">
        <button type="submit">Save Changes</button>
        <a class="btn btn-grey" href="${pageContext.request.contextPath}/pickups">Cancel</a>
      </div>
    </form>
  </div>
</div>
</body>
</html>