-- Recherche de l'ensemble des dénominations associé à leur lst_categorie, lst_signe, lst_id_cvi
SELECT DISTINCT
    concat(p.`ID_APPELLATION`,p.`ID_DENOMINATION_GEO`) id_siqo,
    p.`ID_APPELLATION` id_app,
    p.`ID_DENOMINATION_GEO` id_denom,
    d.`DEN_GEO_LIBELLE` denomination,
    group_concat(DISTINCT cp.`CAT_PRO_LIBELLE` ORDER BY cp.`CAT_PRO_LIBELLE` ASC separator ', ') lst_categorie,
    group_concat(DISTINCT s.`STA_LIBELLE` ORDER BY  s.`STA_LIBELLE` ASC separator ', ') lst_signe,
    group_concat(DISTINCT p.pro_id_cvi ORDER BY p.pro_id_cvi ASC separator ', ') lst_id_cvi
FROM `t_produit` p
INNER JOIN `t_denomination_geo` d ON p.`ID_DENOMINATION_GEO` = d.`ID_DENOMINATION_GEO`
LEFT JOIN `t_categorie_produit` cp ON p.`ID_CATEGORIE_PRODUIT`= cp.`ID_CATEGORIE_PRODUIT`
LEFT JOIN `t_statut` s ON p.`ID_STATUT` = s.`ID_STATUT`
WHERE p.`PRO_DATE_ARCHIVAGE` = 0 
AND p.`PRO_ETAT` = 2 
GROUP BY  
    p.`ID_APPELLATION` ,
    p.`ID_DENOMINATION_GEO` ,
    d.`DEN_GEO_LIBELLE` 
