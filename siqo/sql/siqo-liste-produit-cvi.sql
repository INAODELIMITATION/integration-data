SELECT DISTINCT  
        app.id_appellation id_app, 
        app.app_libelle appellation, 
	denom.id_denomination_geo id_denom, 
	denom.den_geo_libelle denomination, 
	prod.id_produit id_prod, 
	prod.pro_libelle_produit produit, 
        prod.pro_id_cvi id_cvi, 
        statut.sta_libelle, 
        statut.id_statut 
FROM t_produit as prod 
JOIN t_appellation as app  ON prod.id_appellation = app.id_appellation 
JOIN t_denomination_geo as denom ON prod.id_denomination_geo= denom.id_denomination_geo 
JOIN t_statut as statut ON  app.id_statut = statut.id_statut 
WHERE prod.pro_date_archivage = 0 
AND prod.pro_etat = 2 
ORDER BY produit 