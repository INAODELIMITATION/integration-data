# Intégration des tables provenant de la base de données SIQO (produits INAO) 

## Définition :
>>La base de données SIQO est gérée par le BSI. Elle est le coeur du système d'information de l'INAO. 

## Structure de la table siqo_produit:

|champ|valeur|
|---|---|
|id|identifiant unique de la table|
|id_app|identifiant de l'appellation|
|id_denomination|identifiant de la denomination|
|denomination|valeur de la denomination|
|id_prod|identifiant du produit|
|produit|valeur du produit|
|id_cvi|id unique propre au cvi (base des douanes)|
|id_aire_geographique|identifiant de l'aire geographique issu de la base SIQO|


## Procédure d'intégration des données :

1. Supprimer la table metier_inao.siqo_produit de la base avant l'intégration des données

