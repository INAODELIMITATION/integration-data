
--[CREATION D UNE FONCTION QUI RECUPERE ET SIMPLIFIE LE NOM DU REPERTOIRE VERS UN NOM D APPELLATION]--
------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION work.m_keep_signe(rep TEXT)
RETURNS TEXT AS $$
DECLARE signe TEXT;
BEGIN
        SELECT  (regexp_replace($1, '[0-9]|\(|\)', '', 'g')) INTO signe;
        SELECT  (regexp_replace(signe, '\.|\sDF$|\sME$', '', 'g')) INTO signe;
        SELECT  (regexp_replace(signe, '^[A-z]\s|-|\sDF\s|(\s|^)AOC(\s|$)', '', 'g')) INTO signe;
        SELECT  (regexp_replace(signe, '_', '', 'g')) INTO signe;
	SELECT  trim(signe) INTO signe;
	SELECT lower(signe) INTO signe;

        RETURN signe;
END;
$$  LANGUAGE plpgsql;
    --SECURITY DEFINER
    -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
    --SET search_path = admin, pg_temp;

--[UPDATE DU CHAMP SIGNE_NAME]--
--------------------------------
UPDATE work.plan
SET signe_name = (regexp_split_to_array(file_path,'\\'))[array_length((regexp_split_to_array(file_path,'\\')),1)-1]
WHERE signe_name ~* '^syndic'
AND execorder = 2



--[UPDATE DU CHAMP SIGNE_NAME_CLEAN]--
--------------------------------------
UPDATE work.plan
SET signe_name_clean = work.m_keep_signe(req1.signe_name) 
FROM 
	(SELECT signe_name, id, (regexp_split_to_array(file_path, '\\')) file_path 
 	 FROM work.plan) req1
WHERE plan.id = req1.id
AND execorder = 2



--[UPDATE DU CHAMP file_name]-- (avec FME inutile)
-------------------------------
UPDATE work.plan
SET file_name =  req1.file_path[array_upper(req1.file_path,1)] 
FROM 
	(SELECT signe_name, id, (regexp_split_to_array(file_path, '\\')) file_path 
 	 FROM work.plan) req1
WHERE plan.id = req1.id


--[UPDATE DU CHAMP INSEE]--
---------------------------
UPDATE work.plan
SET insee = (regexp_matches(req1.file_path[array_upper(req1.file_path,1)],'(?:\D)(\d{5})(?:\D)'))[1] 
FROM 
	(SELECT signe_name, id, (regexp_split_to_array(file_path, '\\')) file_path 
 	 FROM work.plan) req1
WHERE plan.id = req1.id



--[MISE A JOUR DE L ID_SIGNE]--
-------------------------------
UPDATE work.plan p
SET id_signe = req1.id_signe
FROM	(select signe_name_clean, (row_number() over(order by signe_name_clean))+10664 id_signe
	from work.plan
	WHERE  ok is FALSE
	group by signe_name_clean
	order by signe_name_clean
	) req1
WHERE req1.signe_name_clean = p.signe_name_clean
AND ok is false


--[RECHERCHE DES ASSOCIATIONS ENTRE APPELLATION ET STOCK DANS UNE VUE MATERIALISEE]--
-------------------------------------------------------------------------------------
drop  materialized view if exists work.resultat_file;

create materialized view work.resultat_file as 
WITH 	req1 as (select distinct signe_name_clean, id_signe from work.plan where execorder = 1),
	req2 as (select distinct denomination, id_app, id_denom from work.siqo_produit ),
	req3 as (select req1.signe_name_clean, id_app, id_denom, denomination, id_signe,  similarity(req2.denomination,req1.signe_name_clean) note, row_number() OVER (PARTITION BY req1.signe_name_clean ORDER BY similarity(req2.denomination,req1.signe_name_clean) desc) as test
		from  req1,  req2
		where req2.denomination % req1.signe_name_clean)

select id_signe, signe_name_clean, id_app, id_denom, denomination
from req3
where test = 1
group by signe_name_clean, id_signe, id_app, id_denom, denomination, note;

refresh materialized view work.resultat_file;


--[FONCTION QUI CHANGE IDDENOM POUR UN SIGNE TROUVE DANS LES NOM DE REPERTOIRE SI ERREUR DANS LA TABLE PLAN]--
--------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION work.m_plan_set_signe(idsigne INTEGER, iddenom INTEGER)
RETURNS INTEGER AS $$
DECLARE idsigne INTEGER;
DECLARE iddenom INTEGER;
BEGIN
	UPDATE work.plan
	SET id_denom = iddenom
	WHERE id_signe = idsigne;

	RETURN 0;
END;
$$  LANGUAGE plpgsql


--[SELECTION DE TOUTES LES VALEURS QUE PEUT PRENDRE ID_SIGNE]--
---------------------------------------------------------------
SELECT id_signe, denomination, signe_name_clean
FROM work.resultat_file
order by denomination;


SELECT DISTINCT 
	signe_name_clean,
	 me, df,
	(regexp_split_to_array(file_path, '\\'))[array_length((regexp_split_to_array(file_path, '\\')),1)-1],
	array_to_string((regexp_split_to_array(file_path, '\\'))[1:array_length((regexp_split_to_array(file_path, '\\')),1)-1],'\') path
FROM work.plan
WHERE id_signe = 218


create table work.l_plan_denom(
	id_plan integer not null,
	id_denom integer not null,
	denomination text,
	file_path text
);



create or replace function insert_plan_denom_id(id_signe integer, lst_denom integer array) 
returns void as $$
declare 
	i record;
	str_denom text;
	denom integer;
begin
	foreach denom in array $2 loop
		str_denom = (select distinct denomination from work.siqo_produit sp where sp.id_denom = denom);
		for i in 
			select distinct id id_plan, file_path path
			from work.plan p
			where p.id_signe = $1
		loop
			raise notice '%==>%--%', str_denom, i.id_plan, i.path;
			INSERT INTO work.l_plan_denom (id_plan,id_denom,denomination,file_path) 
			VALUES (i.id_plan, denom, str_denom, i.path); 
		end loop;
	end loop;
end;
$$ language plpgsql;


--[SESSION 1]--
--------------
-- select insert_plan_denom_id(430,array[88]);
-- select insert_plan_denom_id(225,array[1338,1337]);
-- select insert_plan_denom_id(70,array[1293]);
-- select insert_plan_denom_id(743,array[1295]);
-- select insert_plan_denom_id(224,array[1337,1338]);
-- select insert_plan_denom_id(223,array[1337,1338]);
-- select insert_plan_denom_id(232,array[1339,1344]);
-- select insert_plan_denom_id(438,array[1573]);
-- select insert_plan_denom_id(517,array[1309]);
-- select insert_plan_denom_id(261,array[1309]);
-- select insert_plan_denom_id(262,array[1309]);
-- select insert_plan_denom_id(85,array[66,80]);
-- select insert_plan_denom_id(73,array[63,65,115,84]);
-- select insert_plan_denom_id(486,array[88]);
-- select insert_plan_denom_id(156,array[1324]);
-- select insert_plan_denom_id(832,array[88]);
-- select insert_plan_denom_id(518,array[574]);
-- select insert_plan_denom_id(373,array[95]);
-- select insert_plan_denom_id(815,array[1749]);
-- select insert_plan_denom_id(387,array[96,2037]);
-- select insert_plan_denom_id(185,array[96,2037]);
-- select insert_plan_denom_id(388,array[96,2037]);
-- select insert_plan_denom_id(414,array[1696,1754]);
-- select insert_plan_denom_id(413,array[1696,1754]);
-- select insert_plan_denom_id(415,array[1576]);
-- select insert_plan_denom_id(434,array[88]);
-- select insert_plan_denom_id(33,array[258,559,1285,562]);
-- select insert_plan_denom_id(426,array[559,552,1285,652]);
-- select insert_plan_denom_id(199,array[535,559,562,1285]);
-- select insert_plan_denom_id(294,array[559,1285,562]);
-- select insert_plan_denom_id(292,array[559,562,1285]);
-- select insert_plan_denom_id(557,array[1199,1204]);
-- select insert_plan_denom_id(640,array[208,229]);
-- select insert_plan_denom_id(671,array[534]);
-- select insert_plan_denom_id(711,array[212]);
-- select insert_plan_denom_id(710,array[213]);
-- select insert_plan_denom_id(259,array[1387,1402]);
-- select insert_plan_denom_id(367,array[40,13]);
-- select insert_plan_denom_id(867,array[40,44]);
-- select insert_plan_denom_id(903,array[46,33]);
-- select insert_plan_denom_id(984,array[50,11]);
-- select insert_plan_denom_id(688,array[552]);
-- select insert_plan_denom_id(157,array[1345]);
-- select insert_plan_denom_id(322,array[1345]);
-- select insert_plan_denom_id(161,array[1345]);
-- select insert_plan_denom_id(159,array[1345]);
-- select insert_plan_denom_id(29,array[173,224]);
-- select insert_plan_denom_id(160,array[1345]);
-- select insert_plan_denom_id(177,array[1345]);
-- select insert_plan_denom_id(158,array[1345]);
-- select insert_plan_denom_id(176,array[1345]);
-- select insert_plan_denom_id(468,array[1713]);
-- select insert_plan_denom_id(467,array[1713]);
-- select insert_plan_denom_id(68,array[88]);
-- select insert_plan_denom_id(72,array[65]);
-- select insert_plan_denom_id(96,array[74,67]);
-- select insert_plan_denom_id(95,array[74,67]);
-- select insert_plan_denom_id(334,array[67,90]);
-- select insert_plan_denom_id(533,array[67,112]);
-- select insert_plan_denom_id(900,array[2825]);
-- select insert_plan_denom_id(92,array[67,1740,89]);
-- select insert_plan_denom_id(101,array[362,2338]);
-- select insert_plan_denom_id(93,array[88]);
-- select insert_plan_denom_id(341,array[2077]);
-- select insert_plan_denom_id(773,array[1402,1384]);
-- select insert_plan_denom_id(775,array[1402,1384]);
-- select insert_plan_denom_id(774,array[1402,1384]);
-- select insert_plan_denom_id(611,array[474]);
-- select insert_plan_denom_id(618,array[449]);
-- select insert_plan_denom_id(786,array[120,96,2037]);
-- select insert_plan_denom_id(800,array[216,215]);
-- select insert_plan_denom_id(831,array[216]);
-- select insert_plan_denom_id(208,array[187]);
-- select insert_plan_denom_id(810,array[1891]);
-- select insert_plan_denom_id(24,array[173,224]);
-- select insert_plan_denom_id(30,array[173,224]);
-- select insert_plan_denom_id(75,array[63,65,171]);
-- select insert_plan_denom_id(170,array[1328]);
-- select insert_plan_denom_id(218,array[182,229]);
-- select insert_plan_denom_id(983,array[229,235]);
-- select insert_plan_denom_id(1001,array[1]);
--select insert_plan_denom_id(1002,array[173,221,195]);

-- [SESSION 2]--
----------------
-- select insert_plan_denom_id(1003,array[258,559,1285,562]);
-- select insert_plan_denom_id(1004,array[258,559,1285,562]);
-- select insert_plan_denom_id(1005,array[258,559,1285,562]);
-- select insert_plan_denom_id(1006,array[258,559,1285,562]);
-- select insert_plan_denom_id(1007,array[2518,2487,2501,1158]);
-- select insert_plan_denom_id(1008,array[2518,2487,2505,647]);
-- select insert_plan_denom_id(1009,array[2518,2487,2514]);
-- select insert_plan_denom_id(1010,array[559,285,562]);
-- select insert_plan_denom_id(1011,array[397,1024]);
-- select insert_plan_denom_id(1012,array[575,2518,2487]);
-- select insert_plan_denom_id(1013,array[15,24]);
-- select insert_plan_denom_id(1014,array[1288,362,2338,394,391,561,389]);
-- select insert_plan_denom_id(1016,array[362,2338,394,391,561,389,1288]);
-- select insert_plan_denom_id(1017,array[20,5]);
-- select insert_plan_denom_id(1020,array[106]);
-- select insert_plan_denom_id(1021,array[114]);
-- select insert_plan_denom_id(1022,array[2487,950,2518]);
-- select insert_plan_denom_id(1023,array[214,211]);
-- select insert_plan_denom_id(1024,array[118]);
-- select insert_plan_denom_id(1025,array[120,96,67]);
-- select insert_plan_denom_id(1026,array[1055,362,1713]);
-- select insert_plan_denom_id(1028,array[160,162]);
-- select insert_plan_denom_id(1029,array[1112,2518,2487]);
-- select insert_plan_denom_id(1030,array[362,2338,394,391,561,389,1158,1713,2518]);
-- select insert_plan_denom_id(1031,array[362,2338,394,391,561,389,1158,1713,2518]);
-- select insert_plan_denom_id(1032,array[1197,1204]);
-- select insert_plan_denom_id(1033,array[166]);
-- select insert_plan_denom_id(1034,array[362,2338,394,391,561,389,1597]);
-- select insert_plan_denom_id(1036,array[1208,1199]);
-- select insert_plan_denom_id(1037,array[1199,2068]);
-- select insert_plan_denom_id(1038,array[1199,1215]);
-- select insert_plan_denom_id(1039,array[1199,1216]);
-- select insert_plan_denom_id(1040,array[1218,1199]);
-- select insert_plan_denom_id(1041,array[1204,1199]);
-- select insert_plan_denom_id(1042,array[1204,1200]);
-- select insert_plan_denom_id(1043,array[1204,1200]);
--  select insert_plan_denom_id(1015,array[362,2338,394,391,561,389,1597,1288]);
--  select insert_plan_denom_id(1018,array[49,2481,29]);
--  select insert_plan_denom_id(1019,array[22,43]);
--  select insert_plan_denom_id(1035,array[1205,1199]);
--  select insert_plan_denom_id(1027,array[362,2338,394,391,561,389,1055,2518,1719]);


-- [SESSION 3] --
-- select insert_plan_denom_id(10335,array[1713]);
-- select insert_plan_denom_id(10086,array[1392]);--1393,,1306
-- select insert_plan_denom_id(10084,array[110]);
-- select insert_plan_denom_id(10091,array[2518,2487]);
-- select insert_plan_denom_id(10092,array[1742]);
-- select insert_plan_denom_id(10093,array[88]);
-- select insert_plan_denom_id(10097,array[63,65]);
-- select insert_plan_denom_id(10421,array[1309]);
-- select insert_plan_denom_id(10109,array[67,1740,89]);
-- select insert_plan_denom_id(10115,array[362,2338]);
-- select insert_plan_denom_id(10117,array[178,229]);
-- select insert_plan_denom_id(10106,array[1742]);
-- select insert_plan_denom_id(10135,array[1742]);
-- select insert_plan_denom_id(10289,array[88]);
-- select insert_plan_denom_id(10289,array[88]);
-- select insert_plan_denom_id(10164,array[2017]);
-- select insert_plan_denom_id(10187,array[2338]);
-- select insert_plan_denom_id(10203,array[2017]);
-- select insert_plan_denom_id(10111,array[2017]);
-- select insert_plan_denom_id(10166,array[2017]);
-- select insert_plan_denom_id(10184,array[2017]);
-- select insert_plan_denom_id(10105,array[66,80,67,1740,89]);
-- select insert_plan_denom_id(10098,array[63,65,84,99,115]);
-- select insert_plan_denom_id(10099,array[115,63,65]);
-- select insert_plan_denom_id(10074,array[258,559]);
-- select insert_plan_denom_id(10345,array[88]);
-- select insert_plan_denom_id(10069,array[173,195,221]);
-- select insert_plan_denom_id(10227,array[90,67,89,1740]);
-- select insert_plan_denom_id(10226,array[90,67,89,1740]);
-- select insert_plan_denom_id(10479,array[88]);
-- select insert_plan_denom_id(10236,array[2341,2346,2342,2343,2344]);
-- select insert_plan_denom_id(10157,array[2037,79,96]);
-- select insert_plan_denom_id(10290,array[88]);
-- select insert_plan_denom_id(10371,array[1742]);
-- select insert_plan_denom_id(10507,array[1742]);
-- select insert_plan_denom_id(10514,array[1742]);
-- select insert_plan_denom_id(10527,array[1742]);
-- select insert_plan_denom_id(10491,array[1309]);
-- select insert_plan_denom_id(10324,array[67,89,1740,112,98,104,116]);
-- select insert_plan_denom_id(10327,array[67,89,1740,112,98,104,116]);
-- select insert_plan_denom_id(10377,array[67,89,1740,112,98,104,116]);
-- select insert_plan_denom_id(10160,array[1057,1055]);
-- select insert_plan_denom_id(10248,array[1057,1055]);
-- select insert_plan_denom_id(10593,array[1057,1055]);
-- select insert_plan_denom_id(10629,array[1057,1055]);
-- select insert_plan_denom_id(10248,array[1057,1055]);
-- select insert_plan_denom_id(10336,array[1057,1055]);
-- select insert_plan_denom_id(10593,array[1057,1055]);
-- select insert_plan_denom_id(10629,array[1057,1055]);
-- select insert_plan_denom_id(10195,array[1285,559,562]);
-- select insert_plan_denom_id(10209,array[110]);
-- select insert_plan_denom_id(10365,array[1742]);
-- select insert_plan_denom_id(10366,array[863,913]);
-- select insert_plan_denom_id(10370,array[1309]);
-- select insert_plan_denom_id(1377,array[105,105,116]);
-- select insert_plan_denom_id(10331,array[1742]);
-- select insert_plan_denom_id(10330,array[1742]);
-- select insert_plan_denom_id(10528,array[2017]);
-- select insert_plan_denom_id(10427,array[96,2037,120]);
-- select insert_plan_denom_id(10447,array[216,215]);
-- select insert_plan_denom_id(10591,array[182]);
-- select insert_plan_denom_id(10480,array[1372]);
-- select insert_plan_denom_id(10591,array[182]);
-- select insert_plan_denom_id(10652,array[1204,1199]);
-- select insert_plan_denom_id(10658,array[1204,1199]);
-- select insert_plan_denom_id(10656,array[1204,1199]);
-- select insert_plan_denom_id(10653,array[1204,1199]);
-- select insert_plan_denom_id(10654,array[1204,1199,1205]);
-- select insert_plan_denom_id(10651,array[1203,1204]);
-- select insert_plan_denom_id(10482,array[1087,1111]);
-- select insert_plan_denom_id(10483,array[1087,1111]);
-- select insert_plan_denom_id(10564,array[2017]);
-- select insert_plan_denom_id(10486,array[1309]);
-- select insert_plan_denom_id(10596,array[162,163]);
-- select insert_plan_denom_id(10489,array[1369,98,67,1740,89,112]);
-- select insert_plan_denom_id(10488,array[1309]);
-- select insert_plan_denom_id(10499,array[1742]);
-- select insert_plan_denom_id(10500,array[88]);
-- select insert_plan_denom_id(10536,array[2017]);
-- select insert_plan_denom_id(10555,array[1742]);
-- select insert_plan_denom_id(10116,array[178,222,229]);
-- select insert_plan_denom_id(10118,array[178,222,229]);
-- select insert_plan_denom_id(10515,array[169,1849,89,1740,67]);
-- select insert_plan_denom_id(10100,array[63,65,171]);
-- select insert_plan_denom_id(10586,array[60,67,1740,89,172]);
-- select insert_plan_denom_id(10171,array[229,182]);
-- select insert_plan_denom_id(10163,array[1847,1846,1843]);
-- select insert_plan_denom_id(10650,array[1201]);
-- select insert_plan_denom_id(10112,array[88]);
-- select insert_plan_denom_id(10264,array[2037,96]);
-- select insert_plan_denom_id(10265,array[2037,96]);
-- select insert_plan_denom_id(10271,array[98,112]);
-- select insert_plan_denom_id(10240,array[2011]);

--[SESSION 4]--
-- select insert_plan_denom_id(10686,array[258,559]);
-- select insert_plan_denom_id(10687,array[2518,2487]);
-- select insert_plan_denom_id(10688,array[2518,2487,2508]);
-- select insert_plan_denom_id(10689,array[63,65]);
-- select insert_plan_denom_id(10690,array[63,65]);
-- select insert_plan_denom_id(10691,array[63,65,84]);
-- select insert_plan_denom_id(10693,array[63,65,171]);
-- select insert_plan_denom_id(10694,array[63,65]);
-- select insert_plan_denom_id(10695,array[66,80,67,1740,89,1849]);
-- select insert_plan_denom_id(10696,array[66,80,67,1740,89,1849]);
-- select insert_plan_denom_id(10697,array[66,80,67,1740,89,1849]);
-- select insert_plan_denom_id(10698,array[66,80,67,1740,89,1849]);
-- select insert_plan_denom_id(10701,array[67,1740]);
-- select insert_plan_denom_id(10702,array[67,1740,89]);
-- select insert_plan_denom_id(10721,array[96,2037]);
-- select insert_plan_denom_id(10722,array[1847,1846,1843]);
-- select insert_plan_denom_id(10725,array[182,229]);
-- select insert_plan_denom_id(10726,array[182,229]);
-- select insert_plan_denom_id(10732,array[1057,1055]);
-- select insert_plan_denom_id(10755,array[169,123,1849,89,1740,67]);
-- select insert_plan_denom_id(10765,array[90,67,1740,89]);
-- select insert_plan_denom_id(10766,array[90,67,1740,89]);
-- select insert_plan_denom_id(10772,array[96,2037]);
-- select insert_plan_denom_id(10773,array[96,2037]);
-- select insert_plan_denom_id(10778,array[112,98]);
-- select insert_plan_denom_id(10782,array[104,105,116]);
-- select insert_plan_denom_id(10786,array[1713]);
-- select insert_plan_denom_id(10793,array[114]);
-- select insert_plan_denom_id(10797,array[958,2508]);
-- select insert_plan_denom_id(10801,array[66,80]);
-- select insert_plan_denom_id(10802,array[67,1849]);
-- select insert_plan_denom_id(10809,array[104,112,98]);
-- select insert_plan_denom_id(10811,array[67,1740,89,123,1849]);
-- select insert_plan_denom_id(10816,array[120,2037,96]);
-- select insert_plan_denom_id(10821,array[215,216]);
-- select insert_plan_denom_id(10831,array[1087,1111]);
-- select insert_plan_denom_id(10831,array[60,172,89,1740,67]);
-- select insert_plan_denom_id(10840,array[162,163]);
-- select insert_plan_denom_id(10864,array[1201]);
-- select insert_plan_denom_id(10865,array[1204,1199]);
-- select insert_plan_denom_id(10866,array[1204,1199]);
-- select insert_plan_denom_id(10867,array[1204,1199]);
-- select insert_plan_denom_id(10868,array[1204,1205]);
-- select insert_plan_denom_id(10869,array[1204,1210]);
-- select insert_plan_denom_id(10870,array[1204,1199]);
-- select insert_plan_denom_id(10871,array[1204,1220]);
-- select insert_plan_denom_id(10872,array[1204,1199]);
-- select insert_plan_denom_id(10759,array[67,1740,89]);
-- select insert_plan_denom_id(10791,array[67,1740,89,111]);
-- select insert_plan_denom_id(10717,array[67,1740,89,123,76]);
-- select insert_plan_denom_id(10700,array[67,60,172,90,123]);
-- select insert_plan_denom_id(10790,array[111,67,98,112]); 


	

