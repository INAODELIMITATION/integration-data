----------------------------------------------------------------------------------
-- Creation de la table Aire-Geo après récpération des fichiers MapInfo via FME --
----------------------------------------------------------------------------------
-- Modification de la structure de la table aire_geo
ALTER TABLE metier_inao.aire_geo
ADD COLUMN 

-- Mise à jour du champ dénomination à partir de work.siqo_produit pour les produits ayant des DGC
UPDATE metier_inao.aire_geo ag
SET denomination = sp.denomination
FROM work.siqo_produit sp
WHERE sp.id_denom = ag.id_denom
AND ag.id_denom != 0;

-- Mise à jour du champ dénomination à partir de work.siqo_produit pour les produits n'ayant pas de DGC 
UPDATE metier_inao.aire_geo ag
SET denomination = sp.denomination
FROM work.siqo_produit sp
WHERE sp.id_app = ag.id_app
AND ag.id_denom = 0;

-- Création des indexs
CREATE INDEX ON metier_inao.aire_geo USING BTREE(id_app);
CREATE INDEX ON metier_inao.aire_geo USING BTREE(id_denom);