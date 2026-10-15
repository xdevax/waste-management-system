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
