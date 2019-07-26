DROP FUNCTION IF EXISTS ign_admin_express.add_api();
CREATE FUNCTION ign_admin_express.add_api()
RETURNS TABLE(
	lbl_aire text,
	id_siqo text,
	id_api_base integer,
	nomcom text,
	inseecom text,
	anneecom integer,
	comgeom geometry(multipolygon,2154)
)
AS
$$
DECLARE 
	rec record;
	rec2 record;
	req text;
BEGIN

	FOR rec IN SELECT * FROM lst_api ORDER BY lbl_aire
	LOOP
		lbl_aire := rec.lbl_aire;
		id_siqo := rec.id_siqo;
		id_api_base := rec.id_api_base;

		req:='
			WITH lst_com_api_base AS(
				SELECT *
				FROM api_ag
				WHERE id_api = '||id_api_base||'
				),
				lst_com_ag AS(
				SELECT * 
				FROM data_ag
				WHERE id_siqo = '''||id_siqo||''')

			SELECT cab.insee, cab.nom, cab.annee, cab.geom
			FROM lst_com_api_base cab
			FULL JOIN lst_com_ag lca ON lca.insee = cab.insee
			WHERE lca.id_siqo is null';

		FOR rec2 IN EXECUTE req 
		LOOP 
			inseecom := rec2.insee;
			nomcom := rec2.nom;
			comgeom := rec2.geom;
			anneecom := rec2.annee;
			INSERT INTO data_api_zpi (nomapi,insee,nomcom,annee,geom, id_api_base,id_siqo) values (lbl_aire,inseecom,nomcom,anneecom,comgeom,id_api_base,id_siqo);
			RETURN NEXT;
		END LOOP;

	END LOOP;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM ign_admin_express.add_api();