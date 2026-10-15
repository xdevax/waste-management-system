USE wms;
SET FOREIGN_KEY_CHECKS = 0;

-- collector: rename columns to match the DAO, add shift
ALTER TABLE collector CHANGE col_id   collector_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE collector CHANGE col_name name         VARCHAR(60) NOT NULL;
ALTER TABLE collector ADD COLUMN shift ENUM('MORNING','EVENING','NIGHT') DEFAULT 'MORNING';
UPDATE collector SET zone_id = 1 WHERE zone_id IS NULL;
ALTER TABLE collector MODIFY zone_id INT NOT NULL;

-- pickup: rename FK column, tighten nullability
ALTER TABLE pickup CHANGE col_id collector_id INT NOT NULL;
ALTER TABLE pickup MODIFY bin_id INT NOT NULL;
ALTER TABLE pickup MODIFY pickup_date DATE NOT NULL;
ALTER TABLE pickup MODIFY weight_kg DECIMAL(7,2) NOT NULL;

SET FOREIGN_KEY_CHECKS = 1;

SELECT * FROM collector;
SELECT * FROM pickup;