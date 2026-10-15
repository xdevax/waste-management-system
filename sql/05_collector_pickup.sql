USE wms;

CREATE TABLE IF NOT EXISTS collector (
  collector_id INT PRIMARY KEY AUTO_INCREMENT,
  name         VARCHAR(60) NOT NULL,
  phone        VARCHAR(15),
  shift        ENUM('MORNING','EVENING','NIGHT') DEFAULT 'MORNING',
  zone_id      INT NOT NULL,
  CONSTRAINT fk_col_zone FOREIGN KEY (zone_id) REFERENCES zone(zone_id)
);

CREATE TABLE IF NOT EXISTS pickup (
  pickup_id    INT PRIMARY KEY AUTO_INCREMENT,
  bin_id       INT NOT NULL,
  collector_id INT NOT NULL,
  pickup_date  DATE NOT NULL,
  weight_kg    DECIMAL(7,2) NOT NULL CHECK (weight_kg > 0),
  CONSTRAINT fk_pick_bin FOREIGN KEY (bin_id) REFERENCES bin(bin_id) ON DELETE CASCADE,
  CONSTRAINT fk_pick_col FOREIGN KEY (collector_id) REFERENCES collector(collector_id)
);

INSERT INTO collector (name, phone, shift, zone_id)
SELECT * FROM (SELECT 'Ramesh Patil','9822001100','MORNING',1) AS t
WHERE NOT EXISTS (SELECT 1 FROM collector);

INSERT INTO collector (name, phone, shift, zone_id)
SELECT * FROM (SELECT 'Sunita Jadhav','9822002200','EVENING',2) AS t
WHERE (SELECT COUNT(*) FROM collector) < 2;