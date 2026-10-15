USE wms;

INSERT INTO zone (zone_name, city) VALUES
 ('Kothrud','Pune'), ('Hinjewadi','Pune'), ('Viman Nagar','Pune');

INSERT INTO collector (col_name, phone, zone_id) VALUES
 ('Ramesh More','9876500011',1),
 ('Sunita Jadhav','9876500012',2),
 ('Amit Rao','9876500013',3);

INSERT INTO bin (location, capacity_kg, waste_type, zone_id) VALUES
 ('Karve Road Stop',120.50,'DRY',1),
 ('Phase 1 Gate',200.00,'WET',2),
 ('Airport Road',80.00,'E-WASTE',3);

INSERT INTO pickup (bin_id, col_id, weight_kg, status) VALUES
 (1,1,95.5,'DONE'), (2,2,180.0,'DONE'), (3,3,0,'PENDING');

UPDATE pickup SET status='DONE', weight_kg=60 WHERE pickup_id=3;
DELETE FROM pickup WHERE status='MISSED';
