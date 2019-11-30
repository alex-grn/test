CREATE OR REPLACE FUNCTION public.p_action_org_reject (
  id bigint,
  tablename text
)
RETURNS void AS
$body$
DECLARE
  NID BIGINT := ID;
  SQL TEXT;
  ST  TEXT; --поле статуса в таблицах
  RC  RECORD;
BEGIN
  IF TABLENAME = 'direction' THEN
    ST := 'status';
    FOR RC IN (SELECT D.CITIZENRYID,
                      D.ORGANIZATIONID
                 FROM DIRECTION D
                WHERE D.ID = NID)
    LOOP
      DELETE FROM CITIZENRYORG C
       WHERE C.CITIZENRYID = RC.CITIZENRYID
         AND C.ORGANIZATIONID = RC.ORGANIZATIONID;
    END LOOP;
  ELSE
    ST := 'statusorg';
  END IF;
  SQL := 'update ' || TABLENAME || ' s set ' || ST || ' = 2 where s.id = ' || NID;
  EXECUTE SQL;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_org_reject (id bigint, tablename text)
  OWNER TO magicbox;