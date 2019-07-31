CREATE OR REPLACE FUNCTION p_get_kbk_name(n_id bigint) RETURNS text AS
$body$
DECLARE sRESULT TEXT ;
BEGIN
	sRESULT = NULL ;
BEGIN
	SELECT
	 f.name INTO sRESULT
	FROM
		KbkIn f
		WHERE
		f.ID = n_id ; EXCEPTION
	WHEN OTHERS THEN
		sRESULT = NULL ;
	END ; RETURN sRESULT ;
END;
$body$
language plpgsql volatile;
