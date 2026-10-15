<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<html>
<head>
  <title>Login &mdash; Waste Management System</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body class="login-bg">
<div class="login-box">
  <h1>&#9851; Waste Management</h1>
  <p class="sub">Sign in to manage bins, collectors and pickups</p>

  <c:if test="${not empty error}"><div class="flash err">${error}</div></c:if>

  <form method="post" action="${pageContext.request.contextPath}/login">
    <div class="field">
      <label>Username</label>
      <input name="username" required autofocus/>
    </div>
    <div class="field">
      <label>Password</label>
      <input name="password" type="password" required/>
    </div>
    <button type="submit">Sign In</button>
  </form>

  <div class="hint">Demo: <b>admin / admin123</b> &nbsp;&middot;&nbsp; <b>staff / staff123</b></div>
</div>
</body>
</html>