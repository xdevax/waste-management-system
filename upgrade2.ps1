# Run from repo root:  .\upgrade2.ps1
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding $false

function W($Path, $Content) {
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $Path), $Content, $enc)
    Write-Host "  wrote $Path" -ForegroundColor Green
}

# ---------------- SQL ----------------
W 'sql\05_collector_pickup.sql' @'
USE wms;

CREATE TABLE IF NOT EXISTS collector (
  collector_id INT PRIMARY KEY AUTO_INCREMENT,
  name         VARCHAR(60) NOT NULL,
  phone        VARCHAR(15),
  shift        ENUM('MORNING','EVENING','NIGHT') DEFAULT 'MORNING',
  zone_id      INT NOT NULL,
  CONSTRAINT fk_col_zone FOREIGN KEY (zone_id) REFERENCES zone(zone_id)
);

CREATE TABLE IF NOT EXISTS pickup (
  pickup_id    INT PRIMARY KEY AUTO_INCREMENT,
  bin_id       INT NOT NULL,
  collector_id INT NOT NULL,
  pickup_date  DATE NOT NULL,
  weight_kg    DECIMAL(7,2) NOT NULL CHECK (weight_kg > 0),
  CONSTRAINT fk_pick_bin FOREIGN KEY (bin_id) REFERENCES bin(bin_id) ON DELETE CASCADE,
  CONSTRAINT fk_pick_col FOREIGN KEY (collector_id) REFERENCES collector(collector_id)
);

INSERT INTO collector (name, phone, shift, zone_id)
SELECT * FROM (SELECT 'Ramesh Patil','9822001100','MORNING',1) AS t
WHERE NOT EXISTS (SELECT 1 FROM collector);

INSERT INTO collector (name, phone, shift, zone_id)
SELECT * FROM (SELECT 'Sunita Jadhav','9822002200','EVENING',2) AS t
WHERE (SELECT COUNT(*) FROM collector) < 2;
'@

# ---------------- Collector model/DAO ----------------
W 'src\main\java\wms\Collector.java' @'
package wms;

public class Collector {
    private int id;
    private String name;
    private String phone;
    private String shift;
    private int zoneId;
    private String zoneName;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getShift() { return shift; }
    public void setShift(String shift) { this.shift = shift; }
    public int getZoneId() { return zoneId; }
    public void setZoneId(int zoneId) { this.zoneId = zoneId; }
    public String getZoneName() { return zoneName; }
    public void setZoneName(String zoneName) { this.zoneName = zoneName; }
}
'@

W 'src\main\java\wms\CollectorDAO.java' @'
package wms;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CollectorDAO {

    private Collector map(ResultSet rs) throws SQLException {
        Collector c = new Collector();
        c.setId(rs.getInt("collector_id"));
        c.setName(rs.getString("name"));
        c.setPhone(rs.getString("phone"));
        c.setShift(rs.getString("shift"));
        c.setZoneId(rs.getInt("zone_id"));
        c.setZoneName(rs.getString("zone_name"));
        return c;
    }

    private static final String BASE =
        "SELECT c.collector_id, c.name, c.phone, c.shift, c.zone_id, z.zone_name "
      + "FROM collector c JOIN zone z ON c.zone_id = z.zone_id ";

    public List<Collector> findAll(String search) throws SQLException {
        String sql = BASE;
        boolean f = search != null && !search.isBlank();
        if (f) sql += "WHERE c.name LIKE ? OR z.zone_name LIKE ? ";
        sql += "ORDER BY c.collector_id";
        List<Collector> list = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            if (f) { ps.setString(1, "%"+search+"%"); ps.setString(2, "%"+search+"%"); }
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(map(rs)); }
        }
        return list;
    }

    public Collector findById(int id) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(BASE + "WHERE c.collector_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? map(rs) : null; }
        }
    }

    public int insert(String name, String phone, String shift, int zoneId) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "INSERT INTO collector (name, phone, shift, zone_id) VALUES (?,?,?,?)")) {
            ps.setString(1,name); ps.setString(2,phone); ps.setString(3,shift); ps.setInt(4,zoneId);
            return ps.executeUpdate();
        }
    }

    public int update(int id, String name, String phone, String shift, int zoneId) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "UPDATE collector SET name=?, phone=?, shift=?, zone_id=? WHERE collector_id=?")) {
            ps.setString(1,name); ps.setString(2,phone); ps.setString(3,shift);
            ps.setInt(4,zoneId); ps.setInt(5,id);
            return ps.executeUpdate();
        }
    }

    public int delete(int id) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "DELETE FROM collector WHERE collector_id = ?")) {
            ps.setInt(1, id);
            return ps.executeUpdate();
        }
    }
}
'@

# ---------------- Pickup model/DAO ----------------
W 'src\main\java\wms\Pickup.java' @'
package wms;

public class Pickup {
    private int id;
    private int binId;
    private String binLocation;
    private int collectorId;
    private String collectorName;
    private String pickupDate;
    private double weight;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public int getBinId() { return binId; }
    public void setBinId(int binId) { this.binId = binId; }
    public String getBinLocation() { return binLocation; }
    public void setBinLocation(String s) { this.binLocation = s; }
    public int getCollectorId() { return collectorId; }
    public void setCollectorId(int c) { this.collectorId = c; }
    public String getCollectorName() { return collectorName; }
    public void setCollectorName(String s) { this.collectorName = s; }
    public String getPickupDate() { return pickupDate; }
    public void setPickupDate(String d) { this.pickupDate = d; }
    public double getWeight() { return weight; }
    public void setWeight(double w) { this.weight = w; }
}
'@

W 'src\main\java\wms\PickupDAO.java' @'
package wms;

import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class PickupDAO {

    /* 3-table JOIN: pickup + bin + collector */
    private static final String BASE =
        "SELECT p.pickup_id, p.bin_id, b.location, p.collector_id, c.name AS cname, "
      + "p.pickup_date, p.weight_kg "
      + "FROM pickup p JOIN bin b ON p.bin_id = b.bin_id "
      + "JOIN collector c ON p.collector_id = c.collector_id ";

    private Pickup map(ResultSet rs) throws SQLException {
        Pickup p = new Pickup();
        p.setId(rs.getInt("pickup_id"));
        p.setBinId(rs.getInt("bin_id"));
        p.setBinLocation(rs.getString("location"));
        p.setCollectorId(rs.getInt("collector_id"));
        p.setCollectorName(rs.getString("cname"));
        p.setPickupDate(String.valueOf(rs.getDate("pickup_date")));
        p.setWeight(rs.getDouble("weight_kg"));
        return p;
    }

    public List<Pickup> findAll(String search) throws SQLException {
        String sql = BASE;
        boolean f = search != null && !search.isBlank();
        if (f) sql += "WHERE b.location LIKE ? OR c.name LIKE ? ";
        sql += "ORDER BY p.pickup_date DESC, p.pickup_id DESC";
        List<Pickup> list = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            if (f) { ps.setString(1,"%"+search+"%"); ps.setString(2,"%"+search+"%"); }
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(map(rs)); }
        }
        return list;
    }

    public Pickup findById(int id) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(BASE + "WHERE p.pickup_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? map(rs) : null; }
        }
    }

    public int insert(int binId, int collectorId, String date, double weight) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "INSERT INTO pickup (bin_id, collector_id, pickup_date, weight_kg) VALUES (?,?,?,?)")) {
            ps.setInt(1,binId); ps.setInt(2,collectorId);
            ps.setDate(3, Date.valueOf(date)); ps.setDouble(4, weight);
            return ps.executeUpdate();
        }
    }

    public int update(int id, int binId, int collectorId, String date, double weight) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "UPDATE pickup SET bin_id=?, collector_id=?, pickup_date=?, weight_kg=? WHERE pickup_id=?")) {
            ps.setInt(1,binId); ps.setInt(2,collectorId);
            ps.setDate(3, Date.valueOf(date)); ps.setDouble(4, weight); ps.setInt(5, id);
            return ps.executeUpdate();
        }
    }

    public int delete(int id) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement("DELETE FROM pickup WHERE pickup_id = ?")) {
            ps.setInt(1, id);
            return ps.executeUpdate();
        }
    }

    /* dropdown helpers */
    public Map<Integer,String> binOptions() throws SQLException {
        Map<Integer,String> m = new LinkedHashMap<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "SELECT bin_id, location FROM bin ORDER BY location");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) m.put(rs.getInt(1), rs.getString(2));
        }
        return m;
    }

    public Map<Integer,String> collectorOptions() throws SQLException {
        Map<Integer,String> m = new LinkedHashMap<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "SELECT collector_id, name FROM collector ORDER BY name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) m.put(rs.getInt(1), rs.getString(2));
        }
        return m;
    }
}
'@

# ---------------- Dashboard DAO (COUNT / SUM / GROUP BY) ----------------
W 'src\main\java\wms\StatsDAO.java' @'
package wms;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class StatsDAO {

    private int count(String table) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM " + table);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    public int binCount()       throws SQLException { return count("bin"); }
    public int collectorCount() throws SQLException { return count("collector"); }
    public int pickupCount()    throws SQLException { return count("pickup"); }
    public int zoneCount()      throws SQLException { return count("zone"); }

    public double totalWeight() throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(SUM(weight_kg),0) FROM pickup");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getDouble(1) : 0;
        }
    }

    /* GROUP BY: bins + collected weight per zone */
    public List<String[]> perZone() throws SQLException {
        String sql =
            "SELECT z.zone_name, COUNT(DISTINCT b.bin_id) AS bins, "
          + "COALESCE(SUM(p.weight_kg),0) AS kg "
          + "FROM zone z LEFT JOIN bin b ON b.zone_id = z.zone_id "
          + "LEFT JOIN pickup p ON p.bin_id = b.bin_id "
          + "GROUP BY z.zone_id, z.zone_name ORDER BY kg DESC";
        List<String[]> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                rows.add(new String[]{ rs.getString(1), rs.getString(2), rs.getString(3) });
        }
        return rows;
    }

    /* GROUP BY + HAVING: collectors with at least one pickup */
    public List<String[]> perCollector() throws SQLException {
        String sql =
            "SELECT c.name, COUNT(p.pickup_id) AS trips, COALESCE(SUM(p.weight_kg),0) AS kg "
          + "FROM collector c LEFT JOIN pickup p ON p.collector_id = c.collector_id "
          + "GROUP BY c.collector_id, c.name HAVING trips > 0 ORDER BY kg DESC";
        List<String[]> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                rows.add(new String[]{ rs.getString(1), rs.getString(2), rs.getString(3) });
        }
        return rows;
    }

    /* Subquery: bins larger than the average capacity */
    public List<String[]> aboveAverage() throws SQLException {
        String sql =
            "SELECT b.location, b.capacity_kg FROM bin b "
          + "WHERE b.capacity_kg > (SELECT AVG(capacity_kg) FROM bin) "
          + "ORDER BY b.capacity_kg DESC";
        List<String[]> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                rows.add(new String[]{ rs.getString(1), rs.getString(2) });
        }
        return rows;
    }
}
'@

# ---------------- Servlets ----------------
W 'src\main\java\wms\CollectorServlet.java' @'
package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet({"/collectors", "/collectors/edit"})
public class CollectorServlet extends HttpServlet {

    private final CollectorDAO dao = new CollectorDAO();
    private final ZoneDAO zoneDao = new ZoneDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("zones", zoneDao.findAll());
            if (req.getServletPath().endsWith("/edit")) {
                req.setAttribute("col", dao.findById(Integer.parseInt(req.getParameter("id"))));
                req.getRequestDispatcher("/collector-edit.jsp").forward(req, res);
                return;
            }
            req.setAttribute("search", req.getParameter("q"));
            req.setAttribute("cols", dao.findAll(req.getParameter("q")));
            req.getRequestDispatcher("/collectors.jsp").forward(req, res);
        } catch (Exception e) { throw new ServletException(e); }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        try {
            if ("add".equals(action)) {
                dao.insert(req.getParameter("name"), req.getParameter("phone"),
                           req.getParameter("shift"),
                           Integer.parseInt(req.getParameter("zone_id")));
                req.getSession().setAttribute("flash", "Collector added");
            } else if ("update".equals(action)) {
                dao.update(Integer.parseInt(req.getParameter("collector_id")),
                           req.getParameter("name"), req.getParameter("phone"),
                           req.getParameter("shift"),
                           Integer.parseInt(req.getParameter("zone_id")));
                req.getSession().setAttribute("flash", "Collector updated");
            } else if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("collector_id")));
                req.getSession().setAttribute("flash", "Collector deleted");
            }
        } catch (Exception e) {
            req.getSession().setAttribute("flash", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/collectors");
    }
}
'@

W 'src\main\java\wms\PickupServlet.java' @'
package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet({"/pickups", "/pickups/edit"})
public class PickupServlet extends HttpServlet {

    private final PickupDAO dao = new PickupDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("binOpts", dao.binOptions());
            req.setAttribute("colOpts", dao.collectorOptions());
            if (req.getServletPath().endsWith("/edit")) {
                req.setAttribute("pk", dao.findById(Integer.parseInt(req.getParameter("id"))));
                req.getRequestDispatcher("/pickup-edit.jsp").forward(req, res);
                return;
            }
            req.setAttribute("search", req.getParameter("q"));
            req.setAttribute("pickups", dao.findAll(req.getParameter("q")));
            req.getRequestDispatcher("/pickups.jsp").forward(req, res);
        } catch (Exception e) { throw new ServletException(e); }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        try {
            if ("add".equals(action)) {
                dao.insert(Integer.parseInt(req.getParameter("bin_id")),
                           Integer.parseInt(req.getParameter("collector_id")),
                           req.getParameter("pickup_date"),
                           Double.parseDouble(req.getParameter("weight")));
                req.getSession().setAttribute("flash", "Pickup recorded");
            } else if ("update".equals(action)) {
                dao.update(Integer.parseInt(req.getParameter("pickup_id")),
                           Integer.parseInt(req.getParameter("bin_id")),
                           Integer.parseInt(req.getParameter("collector_id")),
                           req.getParameter("pickup_date"),
                           Double.parseDouble(req.getParameter("weight")));
                req.getSession().setAttribute("flash", "Pickup updated");
            } else if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("pickup_id")));
                req.getSession().setAttribute("flash", "Pickup deleted");
            }
        } catch (Exception e) {
            req.getSession().setAttribute("flash", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/pickups");
    }
}
'@

W 'src\main\java\wms\DashboardServlet.java' @'
package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private final StatsDAO dao = new StatsDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("binCount", dao.binCount());
            req.setAttribute("colCount", dao.collectorCount());
            req.setAttribute("pickCount", dao.pickupCount());
            req.setAttribute("zoneCount", dao.zoneCount());
            req.setAttribute("totalKg", dao.totalWeight());
            req.setAttribute("perZone", dao.perZone());
            req.setAttribute("perCol", dao.perCollector());
            req.setAttribute("aboveAvg", dao.aboveAverage());
            req.getRequestDispatcher("/dashboard.jsp").forward(req, res);
        } catch (Exception e) { throw new ServletException(e); }
    }
}
'@

# ---------------- nav (updated) ----------------
W 'src\main\webapp\nav.jsp' @'
<%@ page contentType="text/html;charset=UTF-8" %>
<div class="nav">
  <span class="brand">&#9851; Waste Management System</span>
  <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
  <a href="${pageContext.request.contextPath}/bins">Bins</a>
  <a href="${pageContext.request.contextPath}/collectors">Collectors</a>
  <a href="${pageContext.request.contextPath}/pickups">Pickups</a>
  <span class="who">${sessionScope.user.fullName} (${sessionScope.user.role})</span>
  <a href="${pageContext.request.contextPath}/logout">Logout</a>
</div>
'@

# ---------------- dashboard.jsp ----------------
W 'src\main\webapp\dashboard.jsp' @'
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<html>
<head>
  <title>Dashboard &mdash; WMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>
<jsp:include page="nav.jsp"/>
<div class="wrap">
  <h2>Dashboard</h2>

  <div class="stats">
    <div class="stat"><div class="n">${binCount}</div><div class="l">Total Bins</div></div>
    <div class="stat"><div class="n">${colCount}</div><div class="l">Collectors</div></div>
    <div class="stat"><div class="n">${pickCount}</div><div class="l">Pickups</div></div>
    <div class="stat"><div class="n">${zoneCount}</div><div class="l">Zones</div></div>
    <div class="stat"><div class="n"><fmt:formatNumber value="${totalKg}" maxFractionDigits="1"/></div>
         <div class="l">Total Collected (kg)</div></div>
  </div>

  <div class="card">
    <h3>Bins &amp; Collection per Zone (GROUP BY)</h3>
    <table>
      <tr><th>Zone</th><th>Bins</th><th>Collected (kg)</th></tr>
      <c:forEach var="r" items="${perZone}">
        <tr><td>${r[0]}</td><td>${r[1]}</td><td>${r[2]}</td></tr>
      </c:forEach>
    </table>
  </div>

  <div class="card">
    <h3>Collector Performance (GROUP BY + HAVING)</h3>
    <table>
      <tr><th>Collector</th><th>Pickups</th><th>Total (kg)</th></tr>
      <c:forEach var="r" items="${perCol}">
        <tr><td>${r[0]}</td><td>${r[1]}</td><td>${r[2]}</td></tr>
      </c:forEach>
      <c:if test="${empty perCol}">
        <tr><td colspan="3" class="empty">No pickups recorded yet.</td></tr>
      </c:if>
    </table>
  </div>

  <div class="card">
    <h3>Bins Above Average Capacity (Subquery)</h3>
    <table>
      <tr><th>Location</th><th>Capacity (kg)</th></tr>
      <c:forEach var="r" items="${aboveAvg}">
        <tr><td>${r[0]}</td><td>${r[1]}</td></tr>
      </c:forEach>
      <c:if test="${empty aboveAvg}">
        <tr><td colspan="2" class="empty">No bins above average.</td></tr>
      </c:if>
    </table>
  </div>
</div>
</body>
</html>
'@

# ---------------- collectors.jsp ----------------
W 'src\main\webapp\collectors.jsp' @'
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
'@

W 'src\main\webapp\collector-edit.jsp' @'
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
'@

# ---------------- pickups.jsp ----------------
W 'src\main\webapp\pickups.jsp' @'
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
'@

W 'src\main\webapp\pickup-edit.jsp' @'
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
'@

# ---------------- index redirect ----------------
W 'src\main\webapp\index.jsp' @'
<% response.sendRedirect(request.getContextPath() + "/dashboard"); %>
'@

# ---------------- append dashboard styles ----------------
$css = @'

/* dashboard stat cards */
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));
       gap:16px;margin-bottom:24px}
.stat{background:#fff;border:1px solid var(--line);border-radius:10px;padding:20px;
      text-align:center;box-shadow:0 1px 3px #0000000d}
.stat .n{font-size:32px;font-weight:700;color:var(--green)}
.stat .l{font-size:13px;color:var(--muted);margin-top:4px;
         text-transform:uppercase;letter-spacing:.5px}
'@
[System.IO.File]::AppendAllText((Join-Path (Get-Location) 'src\main\webapp\css\style.css'), $css, $enc)
Write-Host "  appended dashboard styles" -ForegroundColor Green

Write-Host "`nDone. Next: load sql\05_collector_pickup.sql, then mvn clean package." -ForegroundColor Yellow