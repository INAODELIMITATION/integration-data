# Projet de création des aires de proximités immédiates

## Cas des formules de type : API + Aire-Géo de Crémant de Bourgogne - Aire-géo du produit concerné 



1. Création d'un projet FME pour intégrer la liste des produits à traiter dans la table **ign_admin_express.lst_api** en se reposant sur le fichier d'inventaire de Z:\ filtrés sur les champs qui conviennent. 

2. En parallèle, création d'un projet FME pour intégrer les aires-géo manquantes dans la base de données **métier_inao** .

3. A partir de **lst_api**, en SQL, associer les id_siqo aux aires-geo de métier_inao et faire une intersection entre le vecteur d'aire-geo et le champ pts_geom de la table **ign_admin_express.commune_histo** en filtrant sur date = 2011. Enfin, stocker le résultat dans la table **ign_bd_admin_.data_ag**. 

4. Utiliser la fonction **add_api()**  du fichier **api-zpi.sql** afin de générer les liste de communes des api par produits siqo. Cette fonction utlisisera une api-base de la table **api_ag** (api + aire-geo de base)

