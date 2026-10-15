<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<html>
<head>
  <title>Edit Bin &mdash; WMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>
<jsp:include page="nav.jsp"/>

<div class="wrap">
  <h2>Edit Bin #${bin.id}</h2>

  <div class="card">
    <form method="post" action="${pageContext.request.contextPath}/bins">
      <input type="hidden" name="action" value="update"/>
      <input type="hidden" name="bin_id" value="${bin.id}"/>
      <div class="grid">
        <div><label>Location</label>
             <input name="location" value="${bin.location}" required/></div>
        <div><label>Capacity (kg)</label>
             <input name="capacity" type="number" step="0.01" min="0.01"
                    value="${bin.capacity}" required/></div>
        <div><label>Waste Type</label>
          <select name="waste_type">
            <c:forEach var="t" items="DRY,WET,E-WASTE,HAZARD">
              <option value="${t}" ${t == bin.wasteType ? 'selected' : ''}>${t}</option>
            </c:forEach>
          </select>
        </div>
        <div><label>Zone</label>
          <select name="zone_id">
            <c:forEach var="z" items="${zones}">
              <option value="${z.key}" ${z.key == bin.zoneId ? 'selected' : ''}>${z.value}</option>
            </c:forEach>
          </select>
        </div>
      </div>
      <div style="margin-top:18px">
        <button type="submit">Save Changes</button>
        <a class="btn btn-grey" href="${pageContext.request.contextPath}/bins">Cancel</a>
      </div>
    </form>
  </div>
</div>
</body>
</html>