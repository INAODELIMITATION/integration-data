-- When table work.integration_parcelle is ready to push in production
-- read this table and push it in t_zone and l_aire_zone
CREATE OR REPLACE FUNCTION work.test_integration() 
RETURNS 
void
-- TABLE (
-- 	id_aire integer,
-- 	id_zone integer,
-- 	insee char(6),
-- 	app text,
-- 	geom geometry(MULTIPOLYGON,2154)
-- ) 

AS $$
DECLARE 
	rec_sel RECORD;
	rec_ins RECORD;
	rec_ins2 RECORD;
BEGIN
	FOR rec_sel IN SELECT * FROM work.integration_parcelle LOOP
		FOR rec_ins IN INSERT INTO metier_inao.t_zone ( id_zone,type_zone, insee,geom, last_update) VALUES (default, 2, rec_sel.insee,rec_sel.geom,default) RETURNING id_zone LOOP
		
			INSERT INTO metier_inao.l_aire_zone (id_aire, id_zone, last_update) VALUES (rec_sel.id_aire, rec_ins.id_zone, default);
		
		END LOOP;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT *  FROM work.test_integration();



