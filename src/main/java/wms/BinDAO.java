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
