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