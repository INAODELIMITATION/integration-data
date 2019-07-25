SELECT DISTINCT 
        t_commune.COM_CCOM AS "code_insee", 
	t_commune.COM_NCC AS "nom_com", 
	t_appellation.ID_APPELLATION AS "id_app", 
	t_appellation.app_libelle AS "appellation", 
	t_denomination_geo.id_denomination_geo AS "id_denom", 
	t_denomination_geo.DEN_GEO_LIBELLE AS "denomination" ,
        t_zone.zon_libelle, 
t_statut.STA_LIBELLE "sta_libelle" 
FROM 
	t_produit 
	JOIN l_produit_centre_inao ON t_produit.ID_PRODUIT = l_produit_centre_inao.ID_PRODUIT 
	JOIN t_centre_inao ON l_produit_centre_inao.ID_CENTRE_INAO = t_centre_inao.ID_CENTRE_INAO 
	JOIN t_statut ON  t_produit.id_statut = t_statut.id_statut 
	JOIN t_denomination_geo ON t_produit.ID_DENOMINATION_GEO = t_denomination_geo.ID_DENOMINATION_GEO  
	JOIN t_appellation ON t_appellation.id_appellation = t_produit.id_appellation  
	JOIN t_categorie_produit ON t_produit.ID_CATEGORIE_PRODUIT =  t_categorie_produit.ID_CATEGORIE_PRODUIT 
	JOIN t_type_produit ON t_categorie_produit.ID_TYPE_PRODUIT = t_type_produit.ID_TYPE_PRODUIT 
	JOIN t_aire_geographique ON t_produit.ID_AIRE_GEOGRAPHIQUE = t_aire_geographique.ID_AIRE_GEOGRAPHIQUE 
	JOIN t_zone ON t_aire_geographique.ID_AIRE_GEOGRAPHIQUE = t_zone.ID_AIRE_GEO 
	JOIN l_commune_zone ON t_zone.ID_ZONE = l_commune_zone.ID_ZONE 
	JOIN t_commune ON l_commune_zone.ID_COMMUNE = t_commune.ID_COMMUNE 
WHERE 
	t_produit.PRO_DATE_ARCHIVAGE = 0 
	and t_produit.PRO_ETAT = 2   
ORDER BY 
	1, 6