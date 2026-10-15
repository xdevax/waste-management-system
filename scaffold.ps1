# Run from repo root: .\scaffold.ps1
$ErrorActionPreference = 'Stop'

# --- folders ---
'src\main\java\wms','src\main\webapp\WEB-INF','src\main\resources','sql' |
  ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }

function Write-File($Path, $Content) {
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    # utf8NoBOM on PS7; 'utf8' is fine for PS5 here since content is ASCII
    Set-Content -Path $Path -Value $Content -Encoding utf8
    Write-Host "  created $Path" -ForegroundColor Green
}

# ============ 1. pom.xml ============
Write-File 'pom.xml' @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.college</groupId>
  <artifactId>wms</artifactId>
  <version>1.0</version>
  <packaging>war</packaging>

  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>jakarta.servlet</groupId>
      <artifactId>jakarta.servlet-api</artifactId>
      <version>6.0.0</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>jakarta.servlet.jsp.jstl</groupId>
      <artifactId>jakarta.servlet.jsp.jstl-api</artifactId>
      <version>3.0.0</version>
    </dependency>
    <dependency>
      <groupId>org.glassfish.web</groupId>
      <artifactId>jakarta.servlet.jsp.jstl</artifactId>
      <version>3.0.1</version>
    </dependency>
    <dependency>
      <groupId>com.mysql</groupId>
      <artifactId>mysql-connector-j</artifactId>
      <version>8.4.0</version>
    </dependency>
  </dependencies>

  <build>
    <finalName>wms</finalName>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-war-plugin</artifactId>
        <version>3.4.0</version>
      </plugin>
    </plugins>
  </build>
</project>
'@

# ============ 2. sql/01_ddl.sql ============
Write-File 'sql\01_ddl.sql' @'
CREATE DATABASE IF NOT EXISTS wms;
USE wms;

CREATE TABLE zone (
  zone_id   INT PRIMARY KEY AUTO_INCREMENT,
  zone_name VARCHAR(50) NOT NULL UNIQUE,
  city      VARCHAR(50) DEFAULT 'Pune'
);

CREATE TABLE collector (
  col_id    INT PRIMARY KEY AUTO_INCREMENT,
  col_name  VARCHAR(60) NOT NULL,
  phone     VARCHAR(15),
  zone_id   INT,
  joined_on DATE DEFAULT (CURRENT_DATE),
  FOREIGN KEY (zone_id) REFERENCES zone(zone_id)
);

CREATE TABLE bin (
  bin_id      INT PRIMARY KEY AUTO_INCREMENT,
  location    VARCHAR(100) NOT NULL,
  capacity_kg DECIMAL(6,2) CHECK (capacity_kg > 0),
  waste_type  ENUM('DRY','WET','E-WASTE','HAZARD') NOT NULL,
  zone_id     INT,
  FOREIGN KEY (zone_id) REFERENCES zone(zone_id)
);

CREATE TABLE pickup (
  pickup_id   INT PRIMARY KEY AUTO_INCREMENT,
  bin_id      INT,
  col_id      INT,
  pickup_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  weight_kg   DECIMAL(6,2),
  status      ENUM('PENDING','DONE','MISSED') DEFAULT 'PENDING',
  FOREIGN KEY (bin_id) REFERENCES bin(bin_id),
  FOREIGN KEY (col_id) REFERENCES collector(col_id)
);

CREATE INDEX idx_pickup_date ON pickup(pickup_date);
'@

# ============ 3. sql/02_dml.sql ============
Write-File 'sql\02_dml.sql' @'
USE wms;

INSERT INTO zone (zone_name, city) VALUES
 ('Kothrud','Pune'), ('Hinjewadi','Pune'), ('Viman Nagar','Pune');

INSERT INTO collector (col_name, phone, zone_id) VALUES
 ('Ramesh More','9876500011',1),
 ('Sunita Jadhav','9876500012',2),
 ('Amit Rao','9876500013',3);

INSERT INTO bin (location, capacity_kg, waste_type, zone_id) VALUES
 ('Karve Road Stop',120.50,'DRY',1),
 ('Phase 1 Gate',200.00,'WET',2),
 ('Airport Road',80.00,'E-WASTE',3);

INSERT INTO pickup (bin_id, col_id, weight_kg, status) VALUES
 (1,1,95.5,'DONE'), (2,2,180.0,'DONE'), (3,3,0,'PENDING');

UPDATE pickup SET status='DONE', weight_kg=60 WHERE pickup_id=3;
DELETE FROM pickup WHERE status='MISSED';
'@

# ============ 4. sql/03_dql.sql ============
Write-File 'sql\03_dql.sql' @'
USE wms;

-- simple selects
SELECT * FROM bin;
SELECT bin_id, location, waste_type FROM bin WHERE zone_id = 1;

-- multi-table join
SELECT p.pickup_id, b.location, c.col_name, z.zone_name, p.weight_kg, p.status
FROM pickup p
JOIN bin b       ON p.bin_id = b.bin_id
JOIN collector c ON p.col_id = c.col_id
JOIN zone z      ON b.zone_id = z.zone_id;

-- aggregate + group by + having
SELECT z.zone_name, SUM(p.weight_kg) AS total_kg, COUNT(*) AS trips
FROM pickup p
JOIN bin b  ON p.bin_id = b.bin_id
JOIN zone z ON b.zone_id = z.zone_id
GROUP BY z.zone_name
HAVING SUM(p.weight_kg) > 50
ORDER BY total_kg DESC;

-- subquery
SELECT col_name FROM collector
WHERE col_id IN (SELECT col_id FROM pickup WHERE status = 'PENDING');

-- date formatting and null handling
SELECT DATE_FORMAT(pickup_date,'%d-%b-%Y') AS dt, IFNULL(weight_kg,0) AS w FROM pickup;
'@

# ============ 5. DBUtil.java ============
Write-File 'src\main\java\wms\DBUtil.java' @'
package wms;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DBUtil {
    private static final String URL, USER, PASS;

    static {
        try (InputStream in = DBUtil.class.getResourceAsStream("/db.properties")) {
            if (in == null) throw new IllegalStateException(
                "db.properties not found - copy db.properties.example and fill in your password");
            Properties p = new Properties();
            p.load(in);
            URL  = p.getProperty("db.url");
            USER = p.getProperty("db.user");
            PASS = p.getProperty("db.password");
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (Exception e) {
            throw new RuntimeException("DB config failed", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }
}
'@

# ============ 6. Bin.java ============
Write-File 'src\main\java\wms\Bin.java' @'
package wms;

public class Bin {
    private int id;
    private String location;
    private double capacity;
    private String wasteType;
    private String zoneName;
    private int zoneId;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }
    public double getCapacity() { return capacity; }
    public void setCapacity(double capacity) { this.capacity = capacity; }
    public String getWasteType() { return wasteType; }
    public void setWasteType(String wasteType) { this.wasteType = wasteType; }
    public String getZoneName() { return zoneName; }
    public void setZoneName(String zoneName) { this.zoneName = zoneName; }
    public int getZoneId() { return zoneId; }
    public void setZoneId(int zoneId) { this.zoneId = zoneId; }
}
'@

# ============ 7. BinDAO.java ============
Write-File 'src\main\java\wms\BinDAO.java' @'
package wms;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class BinDAO {

    /* ---------- DQL: SELECT with JOIN ---------- */
    public List<Bin> findAll() throws SQLException {
        String sql = "SELECT b.bin_id, b.location, b.capacity_kg, b.waste_type, b.zone_id, z.zone_name "
                   + "FROM bin b JOIN zone z ON b.zone_id = z.zone_id ORDER BY b.bin_id";
        List<Bin> list = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Bin b = new Bin();
                b.setId(rs.getInt("bin_id"));
                b.setLocation(rs.getString("location"));
                b.setCapacity(rs.getDouble("capacity_kg"));
                b.setWasteType(rs.getString("waste_type"));
                b.setZoneId(rs.getInt("zone_id"));
                b.setZoneName(rs.getString("zone_name"));
                list.add(b);
            }
        }
        return list;
    }

    /* ---------- DML: INSERT ---------- */
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

    /* ---------- DML: UPDATE ---------- */
    public int updateCapacity(int id, double capacity) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                 "UPDATE bin SET capacity_kg = ? WHERE bin_id = ?")) {
            ps.setDouble(1, capacity);
            ps.setInt(2, id);
            return ps.executeUpdate();
        }
    }

    /* ---------- DML: DELETE ---------- */
    public int delete(int id) throws SQLException {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement("DELETE FROM bin WHERE bin_id = ?")) {
            ps.setInt(1, id);
            return ps.executeUpdate();
        }
    }
}
'@

# ============ 8. BinServlet.java ============
Write-File 'src\main\java\wms\BinServlet.java' @'
package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/bins")
public class BinServlet extends HttpServlet {

    private final BinDAO dao = new BinDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("bins", dao.findAll());
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
        try {
            if ("add".equals(action)) {
                dao.insert(req.getParameter("location"),
                           Double.parseDouble(req.getParameter("capacity")),
                           req.getParameter("waste_type"),
                           Integer.parseInt(req.getParameter("zone_id")));
            } else if ("update".equals(action)) {
                dao.updateCapacity(Integer.parseInt(req.getParameter("bin_id")),
                                   Double.parseDouble(req.getParameter("capacity")));
            } else if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("bin_id")));
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
        res.sendRedirect(req.getContextPath() + "/bins");
    }
}
'@

# ============ 9. bins.jsp ============
Write-File 'src\main\webapp\bins.jsp' @'
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
'@

# ============ 10. index.jsp ============
Write-File 'src\main\webapp\index.jsp' @'
<% response.sendRedirect(request.getContextPath() + "/bins"); %>
'@

# ============ 11. db.properties.example ============
Write-File 'src\main\resources\db.properties.example' @'
db.url=jdbc:mysql://localhost:3306/wms?useSSL=false&serverTimezone=Asia/Kolkata&allowPublicKeyRetrieval=true
db.user=root
db.password=CHANGE_ME
'@

# ============ .gitignore (overwrite GitHub default) ============
Write-File '.gitignore' @'
# Build output
target/
*.war
*.class

# Secrets - never commit real credentials
src/main/resources/db.properties

# IDE
.idea/
*.iml
.vscode/
.settings/
.classpath
.project

# OS
Thumbs.db
.DS_Store
'@

# ============ your real config (git-ignored) ============
Copy-Item 'src\main\resources\db.properties.example' 'src\main\resources\db.properties' -Force
Write-Host "`nDone. Now edit src\main\resources\db.properties and set your MySQL root password." -ForegroundColor Yellow