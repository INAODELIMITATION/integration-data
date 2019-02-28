SET search_path = insee;

DROP MATERIALIZED VIEW IF EXISTS insee.historique;
CREATE MATERIALIZED VIEW insee.historique AS

----------------------------------------------------------------------
--- Différentiel des changemets entre 2012 et 2018 -------------------
----------------------------------------------------------------------

-- WITH change_name AS (SELECT *
-- FROM "cog_2012" old
-- INNER JOIN "cog_2018" new ON new.insee = old.insee AND new.nom != old.nom
-- WHERE new.nom !~* '\u0152'), 
-- 
-- change_insee AS (SELECT *
-- FROM "cog_2012" old
-- LEFT JOIN "cog_2018" new ON new.insee = old.insee
-- WHERE new.insee is null),


----------------------------------------------------------------------
-- Creation des tables d'historiques des changements par année -------
----------------------------------------------------------------------

WITH histo2013 AS (
SELECT DISTINCT old_insee, new_insee, new_name, mod, eff
FROM "cog_histo_2018" hist 
WHERE eff = 2013 AND mod::integer IN(341,100,321)
ORDER BY old_insee, eff
),
histo2014 AS (
SELECT DISTINCT old_insee, new_insee, new_name, mod, eff
FROM "cog_histo_2018" hist 
WHERE eff = 2014 AND mod::integer IN(341,100,321)
ORDER BY old_insee, eff
),
histo2015 AS (
SELECT DISTINCT old_insee, new_insee, new_name, mod, eff
FROM "cog_histo_2018" hist 
WHERE eff = 2015 AND mod::integer IN(341,100,321)
ORDER BY old_insee, eff
),
histo2016 AS (
SELECT DISTINCT old_insee, new_insee, new_name, mod, eff
FROM "cog_histo_2018" hist 
WHERE eff = 2016 AND mod::integer IN(341,100,321)
ORDER BY old_insee, eff
),
histo2017 AS (
SELECT DISTINCT old_insee, new_insee, new_name, mod, eff
FROM "cog_histo_2018" hist 
WHERE eff = 2017 AND mod::integer IN(341,100,321)
ORDER BY old_insee, eff
),
histo2018 AS (
SELECT DISTINCT old_insee, new_insee, new_name, mod, eff
FROM "cog_histo_2018" hist 
WHERE eff = 2018 AND mod::integer IN(341,100,321)
ORDER BY old_insee, eff
),
----------------------------------------------------------------------
--creation de la compilation des changement de code insee par année---
----------------------------------------------------------------------
tab2013 AS
(SELECT nom nom2012, insee insee2012, 
	CASE WHEN new_insee is null THEN insee ELSE new_insee END insee2013, 
	CASE WHEN new_name is null THEN nom ELSE new_name END nom2013,
	CASE WHEN new_insee is not null THEN true ELSE false END changement
FROM "cog_2012" cog2012
FULL JOIN histo2013 ON cog2012.insee = histo2013.old_insee),

tab2014 AS
(SELECT insee2012, nom2012, insee2013, nom2013,
	CASE WHEN new_insee is null THEN insee2013 ELSE new_insee END insee2014, 
	CASE WHEN new_name is null THEN nom2013 ELSE new_name END nom2014,
	CASE WHEN new_insee is not null THEN true ELSE changement END changement	
FROM tab2013
FULL JOIN histo2014 ON insee2013 = old_insee),

tab2015 AS
(SELECT insee2012, nom2012, insee2013, nom2013, insee2014, nom2014,
	CASE WHEN new_insee is null THEN insee2014 ELSE new_insee END insee2015, 
	CASE WHEN new_name is null THEN nom2014 ELSE new_name END nom2015,
	CASE WHEN new_insee is not null THEN true ELSE changement END changement	
FROM tab2014
FULL JOIN histo2015 ON insee2014 = old_insee),

tab2016 AS
(SELECT insee2012, nom2012, insee2013, nom2013, insee2014, nom2014, insee2015, nom2015,
	CASE WHEN new_insee is null THEN insee2015 ELSE new_insee END insee2016, 
	CASE WHEN new_name is null THEN nom2015 ELSE new_name END nom2016,
	CASE WHEN new_insee is not null THEN true ELSE changement END changement	
FROM tab2015
FULL JOIN histo2016 ON insee2015 = old_insee),

tab2017 AS
(SELECT insee2012, nom2012, insee2013, nom2013, insee2014, nom2014, insee2015, nom2015, insee2016, nom2016,
	CASE WHEN new_insee is null THEN insee2016 ELSE new_insee END insee2017, 
	CASE WHEN new_name is null THEN nom2016 ELSE new_name END nom2017,
	CASE WHEN new_insee is not null THEN true ELSE changement END changement	
FROM tab2016
FULL JOIN histo2017 ON insee2016 = old_insee)

SELECT insee2012, nom2012, insee2013, nom2013, insee2014, nom2014, insee2015, nom2015, insee2016, nom2016, insee2017, nom2017,
	CASE WHEN new_insee is null THEN insee2017 ELSE new_insee END insee2018, 
	CASE WHEN new_name is null THEN nom2017 ELSE new_name END nom2018,
	CASE WHEN new_insee is not null THEN true ELSE changement END changement	
FROM tab2017
FULL JOIN histo2018 ON insee2017 = old_insee




