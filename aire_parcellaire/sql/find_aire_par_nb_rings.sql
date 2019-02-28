-- Classes l'ensemble des polygones composant les aires-parcellaire par nombre d'anneau. 

SELECT id_siqo, id_app, id_denom, id_aire,lbl_aire, id_zone, insee, nomcom, type_zone,  ST_NRINGS(geom) nrings, geom
FROM
			(
			SELECT ts.id_siqo, ts.id_app, ts.id_denom, ta.id_aire,ta.lbl_aire, tz.id_zone, tz.insee, tz.nomcom, tz.type_zone,(ST_DUMP(geom)).path[1] path, (ST_DUMP(geom)).geom geom
			FROM metier_inao.t_siqo ts
			INNER JOIN metier_inao.t_aire ta ON ts.id_siqo = ta.id_siqo
			INNER JOIN metier_inao.l_aire_zone laz ON laz.id_aire = ta.id_aire
			INNER JOIN metier_inao.t_zone tz ON laz.id_zone = tz.id_zone
			LEFT JOIN work.keep_geom_src kgs ON kgs.id_app= ts.id_app AND kgs.id_denom=ts.id_denom AND kgs.insee = tz.insee
			)  as req1
WHERE ST_NRINGS(geom) >= 10
AND type_zone = 2
ORDER BY ST_NRINGS(geom) DESC