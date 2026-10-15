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