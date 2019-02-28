
-------------------------------------------------------------------------
--> ------[PROCEDURE DE MISE A JOUR DE LA TABLE AIREPARCELLAIRE]----- <--
--------------------- Auteur: Martin BAUSSIER ---------------------------
---------------------------- 08/03/2018 ---------------------------------
-------------------------------------------------------------------------

-- => APRES INTEGRATION DES FICHIERS MAPINFO DANS LA TABLE WORK.AIRE_PARCELLAIRE

-------------------------------------------------------------------------
--> [Correction des geometries]
-------------------------------------------------------------------------
-- UPDATE work.aire_parcellaire
-- SET geom = st_buffer(geom,0)
-- WHERE not st_isvalid(geom);

-- SELECT ST_ISVALIDREASON(geom)
-- FROM work.aire_parcellaire
-- WHERE NOT ST_ISVALID(geom);

UPDATE work.aire_parcellaire
SET geom = st_multi(st_collectionextract(st_makevalid(geom),3))
WHERE not st_isvalid(geom);

-------------------------------------------------------------------------
--> [Mise à jour des champs airegeo_cvi, appellation, denomination, surf_sig, new_com, etc... ]
-------------------------------------------------------------------------
WITH fake_insee as(
	select id, st_pointonsurface(geom) as point, code_cvi,commentaire, file_name
	from work.aire_parcellaire 
	)
UPDATE work.aire_parcellaire ap
SET 
	airegeo_cvi = substring(siqo.id_cvi from 3 for 3),
	id_app = siqo.id_app,
	appellation = siqo.appellation,
	id_denom = siqo.id_denom,
	denomination = siqo.denomination,
	id_prod = siqo.id_prod,
	produit = rpad(siqo.produit, 100),
	old_nomcom = old.nom_com,
	old_insee = old.code_insee,
	new_insee = new.insee_com,
	new_nomcom = new.nom_com,
	surf_sig = st_area(ap.geom)/10000
FROM
	work.siqo_produit siqo,
	work.commune_old old,
	work.commune_new new,
	fake_insee
WHERE st_intersects(fake_insee.point, old.geom)
AND st_intersects(fake_insee.point, new.geom)
AND siqo.id_cvi = fake_insee.code_cvi
AND ap.id = fake_insee.id
AND date_integration = '';

-------------------------------------------------------------------------
--> [Remise à zero des champs de traitement des doublons]
-------------------------------------------------------------------------
UPDATE work.aire_parcellaire
SET  doublon = null , drop_doublon = null;

-------------------------------------------------------------------------
--> [Priorisation des doublons]
-------------------------------------------------------------------------
WITH double AS ( 
	SELECT  id, row_number() OVER (PARTITION BY old_insee,id_denom, airegeo_cvi  ORDER BY date_integration desc) AS doublon
	FROM work.aire_parcellaire
	)
UPDATE work.aire_parcellaire
SET doublon = double.doublon
FROM double
WHERE double.id = aire_parcellaire.id;

-------------------------------------------------------------------------
--> [true dans le champ drop_doublon]
-------------------------------------------------------------------------
UPDATE work.aire_parcellaire
SET drop_doublon = true
WHERE doublon > 1;

-------------------------------------------------------------------------
--> [Création de la table pour l'INAO]
-------------------------------------------------------------------------
DROP TABLE IF EXISTS metier_inao.aire_parcellaire ;

CREATE TABLE IF NOT EXISTS metier_inao.aire_parcellaire (
	id bigserial primary key,
	new_insee character varying(5), 
	new_nomcom character varying(100), 
	old_insee character varying(5),
	old_nomcom character varying(100),
	type_ig character varying(10),
	id_app integer,
	appellation character varying(150),
	id_denom integer,
	denomination character varying(150),
	geom geometry(multipolygon,2154)
);

INSERT INTO metier_inao.aire_parcellaire (new_insee, new_nomcom, old_insee, old_nomcom, type_ig, id_app, appellation, id_denom, denomination,  geom )
SELECT 	new_insee, new_nomcom, 
	old_insee, old_nomcom, 
	'AOC' as type_ig,
	id_app, appellation, 
	id_denom, denomination,   
	st_multi(st_union(geom)) AS geom 
FROM work.aire_parcellaire
WHERE drop_doublon is not true
GROUP BY new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation,  id_denom, denomination, millesime, file_name
ORDER BY new_insee,old_insee,appellation, denomination;

CREATE INDEX aire_parcellaire_idx ON metier_inao.aire_parcellaire USING GIST(geom);

--> SUPPRESSION DE DES FICHIERS VENTOUX EN COURS "PROJET"
DELETE FROM metier_inao.aire_parcellaire WHERE appellation ilike '%ventoux%';
DELETE FROM metier_inao.aire_parcellaire WHERE old_insee = '84150';
DELETE FROM metier_inao.aire_parcellaire WHERE appellation ilike '%luberon%';

--> AJOUT D'UNE VALEUR POUR LE CRINAO ET CREATION DU CHAMP
alter table metier_inao.aire_parcellaire
add column crinao character varying(100);

update metier_inao.aire_parcellaire ap
set crinao = grp.crinao
from work.grp_semiologie grp
where grp.id_app = ap.id_app;

-------------------------------------------------------------------------
--> [Création de la table pour l'ETALAB]
-------------------------------------------------------------------------

DROP TABLE IF EXISTS metier_inao.aire_parcellaire_wgs84 ;

CREATE TABLE IF NOT EXISTS metier_inao.aire_parcellaire_wgs84 (
	id bigserial primary key,
	new_insee character varying(5), 
	new_nomcom character varying(100), 
	old_insee character varying(5),
	old_nomcom character varying(100),
	type_ig character varying(10),
	id_app integer,
	appellation character varying(150),
	id_denom integer,
	denomination character varying(150),
	geom geometry(multipolygon,4326)
);

INSERT INTO metier_inao.aire_parcellaire_wgs84 (new_insee, new_nomcom, old_insee, old_nomcom, type_ig, id_app, appellation, id_denom, denomination,  geom )
SELECT new_insee, new_nomcom, old_insee, old_nomcom, type_ig, id_app, appellation, id_denom, denomination,  ST_SNAPTOGRID(ST_TRANSFORM(ST_SETSRID(geom,2154),4326),0.0000001)
FROM metier_inao.aire_parcellaire;

-------------------------------------------------------------------------
--> [Création de la table pour FAM]
-------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS metier_inao.aire_parcellaire_fam (
	id bigserial primary key,
	new_insee character varying(5), 
	new_nomcom character varying(100), 
	type_ig character varying(10),
	id_app integer,
	appellation character varying(150),
	geom geometry(multipolygon,2154)
);

INSERT INTO metier_inao.aire_parcellaire_fam (new_insee, new_nomcom, type_ig, id_app, appellation, geom )
SELECT 	new_insee, new_nomcom, 
	'AOC' as type_ig,
	id_app, appellation, 
	st_multi(st_union(geom)) AS geom 
FROM work.aire_parcellaire
WHERE drop_doublon is not true
GROUP BY new_insee, new_nomcom, id_app, appellation
ORDER BY new_insee,appellation;

--> SUPPRESSION DE DES FICHIERS VENTOUX EN COURS "PROJET"
DELETE FROM metier_inao.aire_parcellaire_fam WHERE appellation ilike '%ventoux%';
DELETE FROM metier_inao.aire_parcellaire_fam WHERE new_insee = '84150';
DELETE FROM metier_inao.aire_parcellaire_fam WHERE appellation ilike '%luberon%';

CREATE INDEX aire_parcellaire_fam_idx ON metier_inao.aire_parcellaire_fam USING GIST(geom);
-------------------------------------------------------------------------
--> [UPDATE GEOMETRIE SRID SI BESOIN]
-------------------------------------------------------------------------
-- ALTER TABLE work.aire_parcellaire
  -- ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 2154)
    -- USING ST_SetSRID(geom,2154);

-------------------------------------------------------------------------
--> [CONCAVEHULL POUR TEST QUALITE]
-------------------------------------------------------------------------	
	
drop table if exists work.concavehull;

create table if not exists work.concavehull (
	id bigserial primary key,
	denomination character varying(150),
	geom geometry (MULTIPOLYGON,2154)
);


INSERT INTO work.concavehull (denomination,geom)
SELECT denomination, ST_MULTI(ST_CONCAVEHULL(ST_COLLECT(geom),1))
FROM work.aire_parcellaire
WHERE drop_doublon is null
GROUP BY denomination;

-------------------------------------------------------------------------
--> [TESTS DE CORRECTION TOPO]
-------------------------------------------------------------------------
-- DROP TABLE IF EXISTS work.test1;

-- CREATE TABLE work.test1 (
	-- id bigserial primary key,
	-- new_insee character varying(5),
	-- new_nomcom character varying(50),
	-- old_insee character varying(5),
	-- old_nomcom character varying(50),
	-- id_app bigint,
	-- appellation character varying(100),
	-- id_denom bigint,
	-- denomination character varying(100),
	-- geom geometry(POLYGON,2154)
-- );

-- INSERT INTO work.test1 (new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation, id_denom, denomination, geom)
-- SELECT DISTINCT new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation, id_denom, denomination, ST_ASEWKT(geom)
-- FROM
	-- (SELECT  new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation, id_denom, denomination, (ST_DUMP(geom)).geom as geom
	-- FROM work.aire_parcellaire
	-- WHERE drop_doublon is not true) as dump
-- WHERE ST_AREA(geom) >= 1

-- DROP TABLE IF EXISTS work.test2;

-- CREATE TABLE work.test2 (
	-- id bigserial primary key,
	-- new_insee character varying(5),
	-- new_nomcom character varying(50),
	-- old_insee character varying(5),
	-- old_nomcom character varying(50),
	-- id_app bigint,
	-- appellation character varying(100),
	-- id_denom bigint,
	-- denomination character varying(100),
	-- geom geometry(MULTIPOLYGON,2154)
-- );

-- INSERT INTO work.test2 (new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation, id_denom, denomination, geom)
-- SELECT new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation, id_denom, denomination,  st_multi(geom)
-- FROM work.test1

-- UPDATE work.test2
-- SET geom = st_multi(st_buffer(geom,0))
-- WHERE not st_isvalid(geom);

-- UPDATE work.test2
-- SET geom = st_multi(st_collectionextract(st_makevalid(geom),3))
-- WHERE not st_isvalid(geom);


-- DROP TABLE IF EXISTS work.test3;

-- CREATE TABLE work.test3 (
	-- id bigserial primary key,
	-- new_insee character varying(5),
	-- new_nomcom character varying(50),
	-- old_insee character varying(5),
	-- old_nomcom character varying(50),
	-- id_app bigint,
	-- appellation character varying(100),
	-- id_denom bigint,
	-- denomination character varying(100),
	-- geom geometry(MULTIPOLYGON,2154)
-- );

-- INSERT INTO work.test3 (new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation, id_denom, denomination, geom)
-- SELECT new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation, id_denom, denomination,  st_multi(st_union(geom))
-- FROM work.test2
-- GROUP BY new_insee, new_nomcom, old_insee, old_nomcom, id_app, appellation, id_denom, denomination;

