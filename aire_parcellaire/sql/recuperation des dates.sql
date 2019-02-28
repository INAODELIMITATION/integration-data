CREATE OR REPLACE FUNCTION work.extract_date(
	filename text,
	OUT  subtext text) AS $$
BEGIN
	
	IF (regexp_matches(filename,'\d{2}_\d{4}'))[1] != '' THEN
		subtext := (regexp_matches(filename,'(\d{2})_(\d{4})')); 
	ELSE
		subtext := 'pas bon';
	END IF;
END;$$
LANGUAGE plpgsql;

SELECT work.extract_date('20_2004');

