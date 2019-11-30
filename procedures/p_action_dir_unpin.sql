CREATE OR REPLACE FUNCTION public.p_action_dir_unpin (
  id bigint,
  tablename text
)
RETURNS void AS
$body$
DECLARE
  NID BIGINT := ID;
  SQL TEXT;
  RC  RECORD;
BEGIN

  SQL := 'update ' || TABLENAME || ' s set status = 1 where s.id = ' || NID;
  EXECUTE SQL;

  IF LOWER(TABLENAME) = 'direction' THEN
    FOR RC IN (SELECT D.CITIZENRYID,
                      D.ORGANIZATIONID
                 FROM DIRECTION D
                WHERE D.ID = NID)
    LOOP
      DELETE FROM CITIZENRYORG C
       WHERE C.CITIZENRYID = RC.CITIZENRYID
         AND C.ORGANIZATIONID = RC.ORGANIZATIONID;
    END LOOP;
  END IF;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_dir_unpin (id bigint, tablename text)
  OWNER TO magicbox;