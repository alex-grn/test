CREATE OR REPLACE FUNCTION public.p_action_org_approve (
  id bigint,
  tablename text
)
RETURNS void AS
$body$
--Действие "Утвердить"
DECLARE
  NID           BIGINT := ID;
  SQL           TEXT;
  ST            TEXT; --поле статуса в таблицах
  CTZYRG BIGINT; -- идентификатор "Организации гражданина"
  REC           RECORD;
  VL            TEXT := '3';
BEGIN
  IF TABLENAME = 'citizenry' THEN
    ST := 'statuscitizen';
    VL := '2';
  ELSIF TABLENAME = 'direction' THEN
    ST := 'status';
  ELSIF TABLENAME = 'plans' THEN
    ST := 'status2';
  ELSE
    ST := 'statusorg';
  END IF;

  -- смена статуса текущего раздела
  SQL := 'update ' || TABLENAME || ' s set ' || ST || ' = ' || VL || ' where s.id = ' || NID;
  EXECUTE SQL;

  IF TABLENAME = 'vacancyorg' THEN
    UPDATE ORGANIZATION S SET STATUSORG = VL WHERE S.ID = (SELECT S.ORGANIZATIONID FROM VACANCYORG S WHERE S.ID = NID);
  END IF;
  IF TABLENAME = 'citizenry' THEN
    -- запись гражданина в подчиненный раздел организаций "Организации гражданина"
    PERFORM P_ACTION_CITIZENRYORG_FILL(NID);
  
    -- смена статуса гражданин--> планы заданий
    UPDATE DIRECTION S SET STATUS = 3 WHERE S.CITIZENRYID = NID;
  END IF;
  IF TABLENAME = 'direction' THEN
    /*
    "Утверждено" переводит выбранный "План заданий" в статус "Направлен на АГС" и добавляет гражданина к выбранной организации, 
    к выбранной вакансии в разделе "Организации" во вкладке "Организации гражданина" со статусом "Направлен на АГС".
    */
    FOR REC IN (SELECT D.CITIZENRYID,   --id гражданина
                      D.ORGANIZATIONID, --id организации
                      D.VACANCYORGID,   --id вакансии
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
      	INSERT INTO CITIZENRYORG (CITIZENRYID, ORGANIZATIONID, VACANCYORGID, STATUSCITIZEN, TARIFFRATE) VALUES (REC.CITIZENRYID, REC.ORGANIZATIONID, REC.VACANCYORGID, '7', REC.TARIFFRATE);
      ELSE
      	UPDATE CITIZENRYORG S SET STATUSCITIZEN = '7' WHERE S.ID = CTZYRG;
      END IF;
      CTZYRG:=NULL;
    END LOOP;
  
    -- запись гражданина в подчиненный раздел организаций "Организации гражданина"
    PERFORM P_ACTION_CITIZENRYORG_FILL(NID);
  
    -- смена статуса гражданин
    UPDATE CITIZENRY S SET STATUSCITIZEN = 2 WHERE S.ID = (SELECT C.CITIZENRYID FROM DIRECTION C WHERE C.ID = NID);
  END IF;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_org_approve (id bigint, tablename text)
  OWNER TO magicbox;