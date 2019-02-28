--PDATE de la table d'aire-geo et aire-par en base après avoir intégrer avec 

-- INSERT INTO work.add_feature(file_name, geom)
-- SELECT
--     file_name,
--     ST_MULTI(ST_COLLECTIONEXTRACT(ST_UNION(geom),3)) geom
-- FROM
-- 	(SELECT
-- 	    file_name,
-- 	    ST_MAKEVALID(ST_SNAPTOGRID((ST_DUMP(ST_TRANSFORM(geom,2154))).geom,0.2)) geom
-- 	FROM work.add) req1
-- GROUP BY file_name;



------------------------------------
--[ATTENTION EN CONSTRUCTION !!! ]
--------------------------------------
-- 
-- CREATE OR REPLACE FUNCTION work.test_integration()
--   RETURNS void AS
-- $BODY$
-- DECLARE 
-- 	rec_sel RECORD;
-- 	rec_ins_tzone RECORD;
-- 	rec_ins_lairezone RECORD;
-- BEGIN
-- 	FOR rec_sel IN SELECT * FROM work.add_feature LOOP
-- 		FOR -- rec_ins IN INSERT INTO metier_inao.t_zone ( id_zone,type_zone, insee,geom, last_update) VALUES (default, rec_sel.type, rec_sel.insee,rec_sel.geom,default) ON CONFLICT () RETURNING id_zone LOOP
-- 
-- 			INSERT INTO metier_inao.l_aire_zone (id_aire, id_zone, last_update) VALUES (rec_sel.id_aire, rec_ins.id_zone, default);
-- 		
-- 		END LOOP;
-- 	END LOOP;
-- END;
-- $BODY$
-- 
-- -- Exemple de upsert
-- 
-- INSERT INTO customers (name, email)
-- VALUES
--  (
--  'Microsoft',
--  'hotline@microsoft.com'
--  ) 
-- ON CONFLICT (name) 
-- DO
--  UPDATE
--    SET email = EXCLUDED.email || ';' || customers.email;



-- SELECT *
-- FROM metier_inao.t_aire ta
-- FULL JOIN metier_inao.l_aire_zone laz USING (id_aire)
-- FULL JOIN metier_inao.t_zone tz USING (id_zone)
-- WHERE nomcom ilike '%chamelet%'

UPDATE work.test
SET geom = req2.geom 
FROM (SELECT
    id_zone,
    ST_MULTI(ST_COLLECTIONEXTRACT(ST_UNION(geom),3)) geom
FROM
	(SELECT
	    id_zone,
	    ST_MAKEVALID(ST_SNAPTOGRID((ST_DUMP(ST_TRANSFORM(geom,2154))).geom,0.2)) geom
	FROM work.test) req1
GROUP BY id_zone ) req2 
WHERE test.id_zone = req2.id_zone


