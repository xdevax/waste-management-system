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