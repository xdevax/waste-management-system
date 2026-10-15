USE wms;

-- simple selects
SELECT * FROM bin;
SELECT bin_id, location, waste_type FROM bin WHERE zone_id = 1;

-- multi-table join
SELECT p.pickup_id, b.location, c.col_name, z.zone_name, p.weight_kg, p.status
FROM pickup p
JOIN bin b       ON p.bin_id = b.bin_id
JOIN collector c ON p.col_id = c.col_id
JOIN zone z      ON b.zone_id = z.zone_id;

-- aggregate + group by + having
SELECT z.zone_name, SUM(p.weight_kg) AS total_kg, COUNT(*) AS trips
FROM pickup p
JOIN bin b  ON p.bin_id = b.bin_id
JOIN zone z ON b.zone_id = z.zone_id
GROUP BY z.zone_name
HAVING SUM(p.weight_kg) > 50
ORDER BY total_kg DESC;

-- subquery
SELECT col_name FROM collector
WHERE col_id IN (SELECT col_id FROM pickup WHERE status = 'PENDING');

-- date formatting and null handling
SELECT DATE_FORMAT(pickup_date,'%d-%b-%Y') AS dt, IFNULL(weight_kg,0) AS w FROM pickup;
