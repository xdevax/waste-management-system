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