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