# Run from repo root:  .\upgrade.ps1
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding $false

function W($Path, $Content) {
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $Path), $Content, $enc)
    Write-Host "  wrote $Path" -ForegroundColor Green
}

# ---------------- 1. sql/04_auth.sql ----------------
W 'sql\04_auth.sql' @'
USE wms;

CREATE TABLE IF NOT EXISTS app_user (
  user_id    INT PRIMARY KEY AUTO_INCREMENT,
  username   VARCHAR(40) NOT NULL UNIQUE,
  pwd_hash   CHAR(64) NOT NULL,
  full_name  VARCHAR(60),
  role       ENUM('ADMIN','STAFF') DEFAULT 'STAFF',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO app_user (username, pwd_hash, full_name, role) VALUES
 ('admin', SHA2('admin123',256), 'Administrator', 'ADMIN'),
 ('staff', SHA2('staff123',256), 'Collection Staff', 'STAFF')
ON DUPLICATE KEY UPDATE username = username;
'@

# ---------------- 2. User.java ----------------
W 'src\main\java\wms\User.java' @'
package wms;

public class User {
    private int id;
    private String username;
    private String fullName;
    private String role;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public boolean isAdmin() { return "ADMIN".equals(role); }
}
'@

# ---------------- 3. UserDAO.java ----------------
W 'src\main\java\wms\UserDAO.java' @'
package wms;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class UserDAO {

    public static String sha256(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] d = md.digest(s.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : d) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public User authenticate(String username, String password) throws SQLException {
        String sql = "SELECT user_id, username, full_name, role FROM app_user "
                   + "WHERE username = ? AND pwd_hash = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, sha256(password));
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                User u = new User();
                u.setId(rs.getInt("user_id"));
                u.setUsername(rs.getString("username"));
                u.setFullName(rs.getString("full_name"));
                u.setRole(rs.getString("role"));
                return u;
            }
        }
    }
}
'@

# ---------------- 4. LoginServlet.java ----------------
W 'src\main\java\wms\LoginServlet.java' @'
package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet({"/login", "/logout"})
public class LoginServlet extends HttpServlet {

    private final UserDAO dao = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        if (req.getServletPath().equals("/logout")) {
            HttpSession s = req.getSession(false);
            if (s != null) s.invalidate();
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        req.getRequestDispatcher("/login.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        try {
            User u = dao.authenticate(req.getParameter("username"),
                                      req.getParameter("password"));
            if (u == null) {
                req.setAttribute("error", "Invalid username or password");
                req.getRequestDispatcher("/login.jsp").forward(req, res);
                return;
            }
            HttpSession session = req.getSession(true);
            session.setAttribute("user", u);
            res.sendRedirect(req.getContextPath() + "/bins");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
'@

# ---------------- 5. AuthFilter.java ----------------
W 'src\main\java\wms\AuthFilter.java' @'
package wms;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter("/*")
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String path = req.getRequestURI().substring(req.getContextPath().length());
        boolean open = path.startsWith("/login")
                    || path.startsWith("/css")
                    || path.equals("/favicon.ico");

        HttpSession session = req.getSession(false);
        boolean loggedIn = session != null && session.getAttribute("user") != null;

        if (open || loggedIn) {
            chain.doFilter(request, response);
        } else {
            res.sendRedirect(req.getContextPath() + "/login");
        }
    }
}
'@

# ---------------- 6. ZoneDAO.java ----------------
W 'src\main\java\wms\ZoneDAO.java' @'
package wms;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

public class ZoneDAO {
    public Map<Integer,String> findAll() throws SQLException {
        Map<Integer,String> m = new LinkedHashMap<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT zone_id, zone_name FROM zone ORDER BY zone_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) m.put(rs.getInt(1), rs.getString(2));
        }
        return m;
    }
}
'@

# ---------------- 7. BinDAO.java (REPLACED) ----------------
W 'src\main\java\wms\BinDAO.java' @'
package wms;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class BinDAO {

    private Bin map(ResultSet rs) throws SQLException {
        Bin b = new Bin();
        b.setId(rs.getInt("bin_id"));
        b.setLocation(rs.getString("location"));
        b.setCapacity(rs.getDouble("capacity_kg"));
        b.setWasteType(rs.getString("waste_type"));
        b.setZoneId(rs.getInt("zone_id"));
        b.setZoneName(rs.getString("zone_name"));
        return b;
    }

    /* DQL: list with optional LIKE search */
    public List<Bin> findAll(String search) throws SQLException {
        String sql = "SELECT b.bin_id, b.location, b.capacity_kg, b.waste_type, b.zone_id, z.zone_name "
                   + "FROM bin b JOIN zone z ON b.zone_id = z.zone_id ";
        boolean filtered = search != null && !search.isBlank();
        if (filtered) sql += "WHERE b.location LIKE ? OR z.zone_name LIKE ? ";
        sql += "ORDER BY b.bin_id";

        List<Bin> list = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            if (filtered) {
                ps.setString(1, "%" + search + "%");
                ps.setString(2, "%" + search + "%");
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        }
        return list;
    }

    /* DQL: single row for the edit form */
    public Bin findById(int id) throws SQLException {
        String sql = "SELECT b.bin_id, b.location, b.capacity_kg, b.waste_type, b.zone_id, z.zone_name "
                   + "FROM bin b JOIN zone z ON b.zone_id = z.zone_id WHERE b.bin_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    /* DML: INSERT */
    public int insert(String location, double capacity, String type, int zoneId) throws SQLException {
        String sql = "INSERT INTO bin (location, capacity_kg, waste_type, zone_id) VALUES (?,?,?,?)";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, location);
            ps.setDouble(2, capacity);
            ps.setString(3, type);
            ps.setInt(4, zoneId);
            return ps.executeUpdate();
        }
    }

    /* DML: full UPDATE */
    public int update(int id, String location, double capacity, String type, int zoneId)
            throws SQLException {
        String sql = "UPDATE bin SET location = ?, capacity_kg = ?, waste_type = ?, zone_id = ? "
                   + "WHERE bin_id = ?";
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, location);
            ps.setDouble(2, capacity);
            ps.setString(3, type);
            ps.setInt(4, zoneId);
            ps.setInt(5, id);
            return ps.executeUpdate();
        }
    }

    /* DML: DELETE */
    public int delete(int id) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement("DELETE FROM bin WHERE bin_id = ?")) {
            ps.setInt(1, id);
            return ps.executeUpdate();
        }
    }
}
'@

# ---------------- 8. BinServlet.java (REPLACED) ----------------
W 'src\main\java\wms\BinServlet.java' @'
package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet({"/bins", "/bins/edit"})
public class BinServlet extends HttpServlet {

    private final BinDAO dao = new BinDAO();
    private final ZoneDAO zoneDao = new ZoneDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("zones", zoneDao.findAll());

            if (req.getServletPath().endsWith("/edit")) {
                int id = Integer.parseInt(req.getParameter("id"));
                req.setAttribute("bin", dao.findById(id));
                req.getRequestDispatcher("/bin-edit.jsp").forward(req, res);
                return;
            }

            req.setAttribute("search", req.getParameter("q"));
            req.setAttribute("bins", dao.findAll(req.getParameter("q")));
            req.getRequestDispatcher("/bins.jsp").forward(req, res);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        String flash;
        try {
            if ("add".equals(action)) {
                dao.insert(req.getParameter("location"),
                           Double.parseDouble(req.getParameter("capacity")),
                           req.getParameter("waste_type"),
                           Integer.parseInt(req.getParameter("zone_id")));
                flash = "Bin added successfully";
            } else if ("update".equals(action)) {
                dao.update(Integer.parseInt(req.getParameter("bin_id")),
                           req.getParameter("location"),
                           Double.parseDouble(req.getParameter("capacity")),
                           req.getParameter("waste_type"),
                           Integer.parseInt(req.getParameter("zone_id")));
                flash = "Bin updated successfully";
            } else if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("bin_id")));
                flash = "Bin deleted";
            } else {
                flash = "Unknown action";
            }
            req.getSession().setAttribute("flash", flash);
        } catch (Exception e) {
            req.getSession().setAttribute("flash", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/bins");
    }
}
'@

# ---------------- 9. css/style.css ----------------
W 'src\main\webapp\css\style.css' @'
:root{
  --green:#1b7a3d; --green-dark:#145c2d; --green-light:#e8f5ec;
  --red:#c62828; --ink:#1f2933; --muted:#6b7a8d; --line:#e3e8ee;
}
*{box-sizing:border-box}
body{margin:0;font-family:"Segoe UI",system-ui,Arial,sans-serif;
     background:#f4f7f5;color:var(--ink)}

.nav{background:var(--green);color:#fff;padding:0 28px;display:flex;
     align-items:center;gap:26px;height:60px;box-shadow:0 2px 8px #0002}
.nav .brand{font-size:19px;font-weight:700;margin-right:auto}
.nav a{color:#fff;text-decoration:none;opacity:.9;font-size:15px;
       padding:6px 2px;border-bottom:2px solid transparent}
.nav a:hover{opacity:1;border-bottom-color:#fff}
.nav .who{font-size:14px;opacity:.85}

.wrap{max-width:1100px;margin:28px auto;padding:0 20px}
h2{margin:0 0 18px;font-size:24px;color:var(--green-dark)}

.card{background:#fff;border:1px solid var(--line);border-radius:10px;
      padding:20px;margin-bottom:22px;box-shadow:0 1px 3px #0000000d}
.card h3{margin:0 0 14px;font-size:15px;text-transform:uppercase;
         letter-spacing:.6px;color:var(--muted)}

label{display:block;font-size:13px;color:var(--muted);margin-bottom:4px}
input,select{width:100%;padding:10px 12px;border:1px solid #cfd8e3;
             border-radius:7px;font-size:14px;background:#fff}
input:focus,select:focus{outline:none;border-color:var(--green);
             box-shadow:0 0 0 3px var(--green-light)}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(165px,1fr));
      gap:14px;align-items:end}

button,.btn{padding:10px 18px;border:0;border-radius:7px;background:var(--green);
     color:#fff;font-size:14px;font-weight:600;cursor:pointer;
     text-decoration:none;display:inline-block;text-align:center}
button:hover,.btn:hover{background:var(--green-dark)}
.btn-sm{padding:6px 12px;font-size:13px}
.btn-red{background:var(--red)} .btn-red:hover{background:#9e1f1f}
.btn-grey{background:#607385} .btn-grey:hover{background:#4a5b6b}

table{width:100%;border-collapse:collapse;background:#fff;
      border:1px solid var(--line);border-radius:10px;overflow:hidden}
th{background:var(--green);color:#fff;text-align:left;padding:13px 14px;
   font-size:13px;text-transform:uppercase;letter-spacing:.5px}
td{padding:12px 14px;border-top:1px solid var(--line);font-size:14px}
tr:hover td{background:#fafcfb}
.tag{display:inline-block;padding:3px 10px;border-radius:20px;font-size:12px;
     font-weight:600;background:var(--green-light);color:var(--green-dark)}

.flash{background:var(--green-light);border-left:4px solid var(--green);
       padding:12px 16px;border-radius:7px;margin-bottom:18px;font-size:14px}
.err{background:#fdecea;border-left-color:var(--red);color:#8c1d18}
.empty{text-align:center;color:var(--muted);padding:30px}

.login-bg{min-height:100vh;display:flex;align-items:center;justify-content:center;
          background:linear-gradient(135deg,#1b7a3d,#0f4a26)}
.login-box{background:#fff;padding:38px 34px;border-radius:14px;width:360px;
           box-shadow:0 12px 40px #0004}
.login-box h1{margin:0 0 6px;font-size:22px;color:var(--green-dark)}
.login-box p.sub{margin:0 0 22px;font-size:13px;color:var(--muted)}
.login-box .field{margin-bottom:15px}
.login-box button{width:100%;padding:12px;margin-top:6px}
.hint{margin-top:18px;font-size:12px;color:var(--muted);text-align:center;
      border-top:1px solid var(--line);padding-top:14px}
'@

# ---------------- 10. login.jsp ----------------
W 'src\main\webapp\login.jsp' @'
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
'@

# ---------------- 11. nav.jsp ----------------
W 'src\main\webapp\nav.jsp' @'
<%@ page contentType="text/html;charset=UTF-8" %>
<div class="nav">
  <span class="brand">&#9851; Waste Management System</span>
  <a href="${pageContext.request.contextPath}/bins">Bins</a>
  <span class="who">${sessionScope.user.fullName} (${sessionScope.user.role})</span>
  <a href="${pageContext.request.contextPath}/logout">Logout</a>
</div>
'@

# ---------------- 12. bins.jsp (REPLACED) ----------------
W 'src\main\webapp\bins.jsp' @'
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
'@

# ---------------- 13. bin-edit.jsp ----------------
W 'src\main\webapp\bin-edit.jsp' @'
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
'@

# ---------------- cleanup ----------------
Remove-Item 'scaffold.ps1' -Force -ErrorAction SilentlyContinue

Write-Host "`nAll files written. Next: load sql\04_auth.sql, then mvn clean package." -ForegroundColor Yellow