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
