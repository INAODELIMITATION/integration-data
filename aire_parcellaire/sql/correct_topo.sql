-- DROP TABLE IF EXISTS work.alsace_final;

-- CREATE TABLE work.alsace_final (
-- 	insee char(6),
-- 	appellation text,
-- 	geom geometry(MULTIPOLYGON,2154));

-- INSERT INTO work.alsace_final

SELECT 
    insee, 
    appellation, 
    ST_MULTI(ST_COLLECTIONEXTRACT(ST_UNION(geom),3)) geom
FROM	
	(SELECT 
        insee, 
        appellation, 
        ST_MAKEVALID(ST_SNAPTOGRID((ST_DUMP(geom)).geom,0.01)) geom
	FROM work.alsace) req1
GROUP BY insee, appellation