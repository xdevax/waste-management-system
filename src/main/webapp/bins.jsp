<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<html>
<head>
  <title>Bins &mdash; WMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>
<jsp:include page="nav.jsp"/>

<div class="wrap">
  <h2>Waste Bins</h2>

  <c:if test="${not empty sessionScope.flash}">
    <div class="flash">${sessionScope.flash}</div>
    <c:remove var="flash" scope="session"/>
  </c:if>

  <div class="card">
    <h3>Add New Bin</h3>
    <form method="post" action="${pageContext.request.contextPath}/bins">
      <input type="hidden" name="action" value="add"/>
      <div class="grid">
        <div><label>Location</label><input name="location" required/></div>
        <div><label>Capacity (kg)</label>
             <input name="capacity" type="number" step="0.01" min="0.01" required/></div>
        <div><label>Waste Type</label>
          <select name="waste_type">
            <option>DRY</option><option>WET</option>
            <option>E-WASTE</option><option>HAZARD</option>
          </select>
        </div>
        <div><label>Zone</label>
          <select name="zone_id">
            <c:forEach var="z" items="${zones}">
              <option value="${z.key}">${z.value}</option>
            </c:forEach>
          </select>
        </div>
        <div><button type="submit">Add Bin</button></div>
      </div>
    </form>
  </div>

  <div class="card">
    <form method="get" action="${pageContext.request.contextPath}/bins">
      <div class="grid">
        <div><label>Search by location or zone</label>
             <input name="q" value="${search}" placeholder="e.g. Karve"/></div>
        <div><button type="submit">Search</button></div>
        <div><a class="btn btn-grey" href="${pageContext.request.contextPath}/bins">Reset</a></div>
      </div>
    </form>
  </div>

  <table>
    <tr><th>ID</th><th>Location</th><th>Capacity (kg)</th>
        <th>Type</th><th>Zone</th><th>Actions</th></tr>
    <c:forEach var="b" items="${bins}">
      <tr>
        <td>${b.id}</td>
        <td>${b.location}</td>
        <td>${b.capacity}</td>
        <td><span class="tag">${b.wasteType}</span></td>
        <td>${b.zoneName}</td>
        <td>
          <a class="btn btn-sm" href="${pageContext.request.contextPath}/bins/edit?id=${b.id}">Edit</a>
          <form style="display:inline" method="post"
                action="${pageContext.request.contextPath}/bins"
                onsubmit="return confirm('Delete bin #${b.id}?')">
            <input type="hidden" name="action" value="delete"/>
            <input type="hidden" name="bin_id" value="${b.id}"/>
            <button class="btn-sm btn-red">Delete</button>
          </form>
        </td>
      </tr>
    </c:forEach>
    <c:if test="${empty bins}">
      <tr><td colspan="6" class="empty">No bins found.</td></tr>
    </c:if>
  </table>
</div>
</body>
</html>