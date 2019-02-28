# Intégration des aire-géo INAO 

## Définition :
>>Dans le cas d'une appellation, **l' aire-géo** ou **aire de production** est le territoire au sein duquel doivent être réalisées toutes les étapes de l'élaboration du produit dans le respect des usages et des conditions de production définies par le cahier des charges pour pouvoir revendiquer l'AOC. L'aire de production de l'appellation doit recouvrir l'aire de production de la matière première (qui correspond généralement à l'aire délimitée ou identifiée) et l'aire de transformation
Dans le cas d'une IGP, l'aire de production ne recouvre pas nécessairement toutes les étapes de l'élaboration du produit

## Structure de la table :

|champ|valeur|
|---|---|
|id|identifiant unique de la table|
|id_app|identifiant de l'appellation|
|id_denomination|identifiant de la denomination|
|denomination|valeur de la denomination|
|url_fiche|URL de la fiche sur le site de l'INAO|
|url_cdc|URL sur le cahier des charge de l'appellation|
|geom_exist|champ qui permet à l'application web de savoir si un objet geographique existe en base ou non|
|id_sig_aire_geo|identifiant d'une aire geo au sens du sig|
|geom|geometry (multipolygon,2154)|

## Procédure d'intégration des données :

1. Supprimer la table metier_inao.aire_geo de la base avant l'intégration des données

```
drop table metier_inao.aire_geo
```

2. Récupération des aires-géographique à partir de 3  fichiers .shp (IG,IGP,AOC) et transfert de ces données via FME avec le projet "push_aire_geo_from_shp.fmw". 

3. Récupération des libelles des aires-geographique à partir de la table work.siqo_produit sur l'id_app & l'id_denom avec le script "create_metier_inao_aire_geo". Nous profitons également de ce moment pour créer les indexs de la table. 

## Remarques & corrections 

1. Quatre aire-geo ne trouvent pas de correspondance dans la base SIQO : 

```
-- recherche des libelles d'aires-geo non mis à jour
select * from metier_inao.aire_geo where denomination = ''
``` 

Valeur dénomination manquantes :

|id_app|id_denom|denomination|commentaire|
|---|---|---|---|
|73|170|Saint-Foy-Bordeau|L'appellation a changé de nom "Côtes de Bordeaux - Sainte-Foy" => id_app 685 & id_denom 2825|
|894|0|Corrèze|Est passé en AOC => id_app 1168 & id_denomination 2818|
|315|0|Armagnac|Armagnac (2565 pour Armagnac Ténarèze, 2566 pour Bas armagnac et 2568 pour Haut Armagnac)|
|746|0|Absinthe de Pontarlier|La dénomination n'existe pas dans la base SIQO seul l'appellation la recup des libellé l'a écrasé|