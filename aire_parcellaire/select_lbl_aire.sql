SET search_path = public, pg_catalog, metier_inao;

SELECT DISTINCT id_app, id_denom, id_siqo, id_aire, lbl_aire
FROM metier_inao.siqo_produit sp
INNER JOIN metier_inao.t_aire ta ON concat(lpad(sp.id_app,4,'0'),lpad(sp.id_denom,4,'0')) = ta.id_siqo
INNER JOIN metier_inao.l_aire_zone USING(id_aire)
INNER JOIN metier_inao.t_zone USING(id_zone)
WHERE lbl_aire ilike '%blaye%'
ORDER BY id_aire

