<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<html>
<head>
  <title>Edit Collector &mdash; WMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>
<jsp:include page="nav.jsp"/>
<div class="wrap">
  <h2>Edit Collector #${col.id}</h2>
  <div class="card">
    <form method="post" action="${pageContext.request.contextPath}/collectors">
      <input type="hidden" name="action" value="update"/>
      <input type="hidden" name="collector_id" value="${col.id}"/>
      <div class="grid">
        <div><label>Name</label><input name="name" value="${col.name}" required/></div>
        <div><label>Phone</label><input name="phone" value="${col.phone}"/></div>
        <div><label>Shift</label>
          <select name="shift">
            <c:forEach var="s" items="MORNING,EVENING,NIGHT">
              <option value="${s}" ${s == col.shift ? 'selected' : ''}>${s}</option>
            </c:forEach>
          </select>
        </div>
        <div><label>Zone</label>
          <select name="zone_id">
            <c:forEach var="z" items="${zones}">
              <option value="${z.key}" ${z.key == col.zoneId ? 'selected' : ''}>${z.value}</option>
            </c:forEach>
          </select>
        </div>
      </div>
      <div style="margin-top:18px">
        <button type="submit">Save Changes</button>
        <a class="btn btn-grey" href="${pageContext.request.contextPath}/collectors">Cancel</a>
      </div>
    </form>
  </div>
</div>
</body>
</html>