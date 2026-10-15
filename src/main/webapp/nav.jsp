<%@ page contentType="text/html;charset=UTF-8" %>
<div class="nav">
  <span class="brand">&#9851; Waste Management System</span>
  <a href="${pageContext.request.contextPath}/bins">Bins</a>
  <span class="who">${sessionScope.user.fullName} (${sessionScope.user.role})</span>
  <a href="${pageContext.request.contextPath}/logout">Logout</a>
</div>