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