<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<html>
<head>
  <title>Collectors &mdash; WMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>
<jsp:include page="nav.jsp"/>
<div class="wrap">
  <h2>Collectors</h2>

  <c:if test="${not empty sessionScope.flash}">
    <div class="flash">${sessionScope.flash}</div>
    <c:remove var="flash" scope="session"/>
  </c:if>

  <div class="card">
    <h3>Add Collector</h3>
    <form method="post" action="${pageContext.request.contextPath}/collectors">
      <input type="hidden" name="action" value="add"/>
      <div class="grid">
        <div><label>Name</label><input name="name" required/></div>
        <div><label>Phone</label><input name="phone" pattern="[0-9]{10}" title="10 digits"/></div>
        <div><label>Shift</label>
          <select name="shift"><option>MORNING</option><option>EVENING</option><option>NIGHT</option></select>
        </div>
        <div><label>Zone</label>
          <select name="zone_id">
            <c:forEach var="z" items="${zones}"><option value="${z.key}">${z.value}</option></c:forEach>
          </select>
        </div>
        <div><button type="submit">Add</button></div>
      </div>
    </form>
  </div>

  <div class="card">
    <form method="get" action="${pageContext.request.contextPath}/collectors">
      <div class="grid">
        <div><label>Search by name or zone</label><input name="q" value="${search}"/></div>
        <div><button type="submit">Search</button></div>
        <div><a class="btn btn-grey" href="${pageContext.request.contextPath}/collectors">Reset</a></div>
      </div>
    </form>
  </div>

  <table>
    <tr><th>ID</th><th>Name</th><th>Phone</th><th>Shift</th><th>Zone</th><th>Actions</th></tr>
    <c:forEach var="k" items="${cols}">
      <tr>
        <td>${k.id}</td><td>${k.name}</td><td>${k.phone}</td>
        <td><span class="tag">${k.shift}</span></td><td>${k.zoneName}</td>
        <td>
          <a class="btn btn-sm" href="${pageContext.request.contextPath}/collectors/edit?id=${k.id}">Edit</a>
          <form style="display:inline" method="post"
                action="${pageContext.request.contextPath}/collectors"
                onsubmit="return confirm('Delete collector #${k.id}?')">
            <input type="hidden" name="action" value="delete"/>
            <input type="hidden" name="collector_id" value="${k.id}"/>
            <button class="btn-sm btn-red">Delete</button>
          </form>
        </td>
      </tr>
    </c:forEach>
    <c:if test="${empty cols}"><tr><td colspan="6" class="empty">No collectors found.</td></tr></c:if>
  </table>
</div>
</body>
</html>