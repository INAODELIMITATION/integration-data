-- DROP MATERIALIZED VIEW metier_inao.v_clc_aoc;
-- CREATE MATERIALIZED VIEW metier_inao.v_clc_aoc AS
-- 
-- 
-- SELECT id_aire, 'urba' ocsol, st_area(geom)/10000 aireha, geom
-- FROM
-- 	(SELECT id_aire, st_multi(st_collectionextract(st_intersection(vlz.geom,clc.geom),3))::geometry(multipolygon,2154) geom
-- 	FROM metier_inao.v_lst_zone vlz
-- 	JOIN work.clc ON st_intersects(vlz.geom,clc.geom)
-- 	WHERE type_zone = 2
-- 	AND code ~ '^11|^12|^13') req_clc
-- UNION
DROP MATERIALIZED VIEW cvi.v_parcelle_geom; 
CREATE MATERIALIZED VIEW cvi.v_parcelle_geom AS
SELECT DISTINCT row_number() over() id, vcp.idu, tp.geom::geometry(multipolygon,2154)
FROM ign_bd_cadastre.t_parcelle tp
INNER JOIN cvi.v_cvi_parcelle vcp USING(idu)