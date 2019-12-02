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
  REC  RECORD;
  CTZYRG BIGINT;
BEGIN
  SQL := 'update ' || TABLENAME || ' s set status = 4 where s.id = ' || NID;
  EXECUTE SQL;
  /*
  "Подтверждено" переводит выбранный "План заданий" в статус "Подтверждено" и добавляет гражданина к выбранной организации, 
  к выбранной вакансии в разделе "Организации" во вкладке "Организации гражданина" со статусом "Подтверждено".
  */
  IF LOWER(TABLENAME) = 'direction' THEN
    FOR REC IN (SELECT D.CITIZENRYID,
                      D.ORGANIZATIONID,
                      D.VACANCYORGID,
                      V.TARIFFRATE 	    --тарифная ставка
                 FROM DIRECTION D,
                 	  VACANCYORG V
                WHERE D.ID = NID
                  AND V.ID = D.VACANCYORGID)
    LOOP
       --Ищем такую же строку
      SELECT S.ID INTO CTZYRG FROM CITIZENRYORG S 
      WHERE S.CITIZENRYID = REC.CITIZENRYID AND S.ORGANIZATIONID = REC.ORGANIZATIONID AND S.VACANCYORGID = REC.VACANCYORGID AND S.TARIFFRATE = REC.TARIFFRATE;
      --Если нет таких строк, то добавляем иначе меняем статус
      IF CTZYRG IS NULL THEN
      	INSERT INTO CITIZENRYORG (CITIZENRYID, ORGANIZATIONID, VACANCYORGID, STATUSCITIZEN, TARIFFRATE) VALUES (REC.CITIZENRYID, REC.ORGANIZATIONID, REC.VACANCYORGID, '5', REC.TARIFFRATE);
      ELSE
      	UPDATE CITIZENRYORG S SET STATUSCITIZEN = '5' WHERE S.ID = CTZYRG;
      END IF;
      CTZYRG:=NULL;
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