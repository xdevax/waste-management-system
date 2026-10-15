<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<html>
<head>
<title>Waste Management System</title>
<style>
 body{font-family:Arial;margin:30px;background:#f1f5f1}
 h2{color:#2e7d32}
 table{border-collapse:collapse;width:100%;background:#fff;box-shadow:0 1px 4px #0002}
 th,td{border:1px solid #ddd;padding:9px;text-align:left}
 th{background:#2e7d32;color:#fff}
 .card{background:#fff;padding:15px;border-radius:6px;margin-bottom:18px;box-shadow:0 1px 4px #0002}
 input,select{padding:7px;margin:4px;border:1px solid #bbb;border-radius:4px}
 button{padding:7px 14px;background:#2e7d32;color:#fff;border:0;border-radius:4px;cursor:pointer}
 .del{background:#c62828}
 .inline{display:inline;margin:0;padding:0;box-shadow:none;background:none}
</style>
</head>
<body>
<h2>&#9851; Waste Management System &mdash; Bins</h2>

<div class="card">
  <form method="post" action="${pageContext.request.contextPath}/bins">
    <input type="hidden" name="action" value="add"/>
    <input name="location" placeholder="Location" required/>
    <input name="capacity" type="number" step="0.01" placeholder="Capacity (kg)" required/>
    <select name="waste_type">
      <option>DRY</option><option>WET</option>
      <option>E-WASTE</option><option>HAZARD</option>
    </select>
    <select name="zone_id">
      <option value="1">Kothrud</option>
      <option value="2">Hinjewadi</option>
      <option value="3">Viman Nagar</option>
    </select>
    <button type="submit">Add Bin</button>
  </form>
</div>

<table>
  <tr><th>ID</th><th>Location</th><th>Capacity (kg)</th><th>Type</th><th>Zone</th><th>Actions</th></tr>
  <c:forEach var="b" items="${bins}">
    <tr>
      <td>${b.id}</td>
      <td>${b.location}</td>
      <td>${b.capacity}</td>
      <td>${b.wasteType}</td>
      <td>${b.zoneName}</td>
      <td>
        <form class="inline" method="post" action="${pageContext.request.contextPath}/bins">
          <input type="hidden" name="action" value="update"/>
          <input type="hidden" name="bin_id" value="${b.id}"/>
          <input name="capacity" type="number" step="0.01" size="5" required/>
          <button>Update</button>
        </form>
        <form class="inline" method="post" action="${pageContext.request.contextPath}/bins">
          <input type="hidden" name="action" value="delete"/>
          <input type="hidden" name="bin_id" value="${b.id}"/>
          <button class="del">Delete</button>
        </form>
      </td>
    </tr>
  </c:forEach>
</table>
</body>
</html>
