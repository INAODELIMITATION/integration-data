z

---------------------------------------------------------------------------
---------------------------------------------------------------------------

SELECT id_signe, file_rep_name, id_denom, denomination, max(file_path_rep)
FROM work.plan_final
WHERE id_denom is null
GROUP BY id_signe, file_rep_name, id_denom, denomination
ORDER BY file_rep_name

---------------------------------------------------------------------------
---------------------------------------------------------------------------

DROP MATERIALIZED VIEW IF EXISTS metier_inao.v_plan_com;
CREATE MATERIALIZED VIEW metier_inao.v_plan_com AS 
WITH group_plan AS (
	SELECT DISTINCT 
		ta.id_siqo,
		ta.id_aire,
		tp.insee,
		ta.lbl_aire,
		lower(tp.file_extension::text) file_extension,
		max(tp.file_date) AS file_date,
		tp.file_path_rep,
		tp.df,
		tp.me
	FROM metier_inao.t_plan tp
	LEFT JOIN metier_inao.t_siqo ts ON tp.id_denom = ts.id_denom
	LEFT JOIN metier_inao.t_aire ta ON ts.id_siqo::text = ta.id_siqo
	LEFT JOIN metier_inao.l_aire_zone laz ON laz.id_aire = ta.id_aire
	LEFT JOIN metier_inao.t_zone tz ON tz.insee = tp.insee::bpchar AND tz.id_zone = laz.id_zone
	GROUP BY ta.id_siqo, ta.id_aire, tp.insee, ta.lbl_aire, (lower(tp.file_extension::text)), tp.file_path_rep, tp.df, tp.me
	)

SELECT 
	id_siqo,
	id_aire,
	insee,
	lbl_aire,
	(CASE WHEN file_extension = 'tif' THEN true END) tif,
	(CASE WHEN file_extension = 'tif' THEN file_date END) tif_file_date,
	(CASE WHEN file_extension = 'tif' THEN file_path_rep END) tif_file_path_rep,
	(CASE WHEN file_extension = 'tif' THEN df END) tif_df,
	(CASE WHEN file_extension = 'tif' THEN me END) tif_me,
	(CASE WHEN file_extension = 'pdf' THEN true END) pdf,
	(CASE WHEN file_extension = 'pdf' THEN file_date END) pdf_file_date,
	(CASE WHEN file_extension = 'pdf' THEN file_path_rep END) pdf_file_path_rep,
	(CASE WHEN file_extension = 'pdf' THEN df END) pdf_df,
	(CASE WHEN file_extension = 'pdf' THEN me END) pdf_me
FROM group_plan





-- WITH DATA;