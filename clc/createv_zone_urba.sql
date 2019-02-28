DROP VIEW IF EXISTS metier_inao.v_zone_urba;
CREATE VIEW metier_inao.v_zone_urba AS
SELECT *
FROM work.clc
WHERE code_12 ~ '^11|^12|^13';
