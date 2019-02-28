---------------------------------
-- On découpe les multi polygones
---------------------------------

BEGIN;

CREATE TABLE inao.donnees_decoupees (
    id SERIAL PRIMARY KEY,
    file_name varchar(150),
    appellation_simple varchar(100),
    appellation varchar(256),
    denomination varchar(256)
);
SELECT AddGeometryColumn('inao','donnees_decoupees','geom','2154','POLYGON',2);

INSERT INTO inao.donnees_decoupees (file_name, geom, appellation, denomination)
    SELECT base.file_name, (ST_Dump(ST_CollectionExtract(base.geom,3))).geom, base.appellatio, base.denominati FROM
        ( SELECT st_makevalid(geom) as geom, file_name, appellatio, denominati FROM inao.donnees_brutes ) AS base;

CREATE INDEX ON inao.donnees_decoupees USING GIST (geom);

END;


--------------------------------------
-- On calcule la partition de l'espace
--------------------------------------

BEGIN;

CREATE TABLE inao.partition (
    id SERIAL PRIMARY KEY,
    file_name varchar(150),
    appellation_principale varchar(50),
    appellation_simple varchar(256),
    appellation varchar(1024),
    denomination varchar(1024)
);
SELECT AddGeometryColumn('inao','partition','geom','2154','POLYGON',2);

INSERT INTO inao.partition (geom)
    SELECT geom FROM
        ( SELECT (ST_Dump(geom)).geom AS geom FROM
            ( SELECT ST_Polygonize(geom) AS geom FROM 
                ( SELECT (ST_Dump(ST_Union(geom))).geom FROM 
                    ( SELECT DISTINCT ST_AsEwkb(ST_ExteriorRing(geom)) as geom FROM inao.donnees_decoupees ) as limites
                ) AS limites_union
            ) AS partition
        ) AS poly
    WHERE ST_Area(geom)>0.01;

CREATE INDEX ON inao.partition USING GIST (geom);

END;


---------------------------------------------
-- On calcule les infos pour chaque partition
---------------------------------------------

UPDATE inao.partition t SET appellation = (
    SELECT string_agg(tmp.appellation, ',') FROM 
        (SELECT DISTINCT e.appellation FROM inao.donnees_decoupees e WHERE st_intersects(e.geom, t.geom) ORDER BY e.appellation) as tmp
    );

UPDATE inao.partition t SET denomination = (
    SELECT string_agg(tmp.denomination, ',') FROM 
        (SELECT DISTINCT e.denomination FROM inao.donnees_decoupees e WHERE st_intersects(e.geom, t.geom) ORDER BY e.denomination) as tmp
    );

-----------------------------------------------------
-- On définit l'appellation principale, pour le style
-----------------------------------------------------

-- Utiliser la table des grands groupes
