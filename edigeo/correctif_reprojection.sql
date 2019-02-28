update edigeo.parcelle
set geom = ST_Transform(ST_setsrid(geom,4326),2154) 
where commune ~* '^34'