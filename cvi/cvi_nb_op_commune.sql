
-------------------------------------------------------------------------
--> -------------[PROCEDURE DE TRAIREMENT DU CVI]-------------------- <--
--------------------- Auteur: Martin BAUSSIER ---------------------------
---------------------------- 08/03/2018 ---------------------------------
-------------------------------------------------------------------------

--> NB OPERATEUR PAR COMMUNE <--

SELECT count(evv.codeevv) nb_operateur, com.code_insee, com.nom_com
FROM cvi.evv LEFT JOIN ign_bd_cadastre.commune com ON left(communerattachementcodeinsee,2)||right(communerattachementcodeinsee,3) = code_insee
WHERE (estprincipale IS NULL OR estprincipale ='1') 
AND etatactivite = '1'
GROUP BY code_insee, nom_com
ORDER BY code_insee

