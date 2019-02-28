CREATE TABLE metier_inao.t_zone_urba AS 
 SELECT req.id,
    req.id_aire,
    req.lbl_aire,
    st_area(req.geom) / 10000::double precision AS aireha,
    req.geom
   FROM ( SELECT row_number() OVER () AS id,
            vlz.id_aire,
            vlz.lbl_aire,
            st_multi(st_collectionextract(st_intersection(vlz.geom, clc.geom), 3))::geometry(MultiPolygon,2154) AS geom
           FROM metier_inao.v_lst_zone vlz
             JOIN work.clc ON st_intersects(vlz.geom, clc.geom)
          WHERE vlz.type_zone = 2 AND clc.code ~ '^11|^12|^13'::text) req
WITH DATA;

ALTER TABLE metier_inao.v_clc_aoc