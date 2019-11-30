CREATE OR REPLACE FUNCTION public.p_action_dir_confirm (
  id bigint,
  tablename text
)
RETURNS void AS
$body$
--Действие "подтверждение"
DECLARE
  NID BIGINT := ID;
  SQL TEXT;
  RC  RECORD;
BEGIN
  SQL := 'update ' || TABLENAME || ' s set status = 4 where s.id = ' || NID;
  EXECUTE SQL;
  /*
  "Подтверждено" переводит выбранный "План заданий" в статус "Подтверждено" и добавляет гражданина к выбранной организации, 
  к выбранной вакансии в разделе "Организации" во вкладке "Организации гражданина" со статусом "Подтверждено".
  */
  IF LOWER(TABLENAME) = 'direction' THEN
    FOR RC IN (SELECT D.CITIZENRYID,
                      D.ORGANIZATIONID,
                      D.VACANCYORGID
                 FROM DIRECTION D
                WHERE D.ID = NID)
    LOOP
      INSERT INTO CITIZENRYORG (CITIZENRYID, ORGANIZATIONID, VACANCYORGID, STATUSCITIZEN) VALUES (RC.CITIZENRYID, RC.ORGANIZATIONID, RC.VACANCYORGID, '5');
    END LOOP;
  END IF;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_dir_confirm (id bigint, tablename text)
  OWNER TO magicbox;