CREATE OR REPLACE FUNCTION public.p_action_create_payroll (
  id bigint,
  ddocdate date,
  bpay boolean,
  bchairman boolean,
  uid bigint
)
RETURNS text AS
$body$
declare 
    IDENT   BIGINT := ID;
	RC      RECORD;
    SH      RECORD;
    TYP     RECORD;
	nVED    BIGINT;																--Тип документа "ведомость"
    UD      BIGINT;																--Уровень доступа текущего пользователя
    NUID    BIGINT:=UID;                                                        --Пользователь
    nID     BIGINT;
    tSQL    TEXT;
    KOLS    INTEGER;																--Количество ведомостей
    CR      TEXT:=CHR(13);
    SQL_BUF TEXT;																--SQL буффер для каждого условия
    NAL		TEXT;																--Наличка
    BEZ	    TEXT;																--Безнал
    N_PR   	TEXT;																--НЕ Председатель
    PR		TEXT;																--Председатель
    FL		BOOLEAN:=FALSE;														--FLAG
    PAYS    TEXT[];                                                               --Условия по выплатам
    nTYPEEXP BIGINT;
begin
	--Проверка
    IF (SELECT COUNT(*) FROM SHEETS S WHERE S.REGISTERID = IDENT) > 0 THEN RAISE USING MESSAGE = 'Ведомость по оплате труда уже сформирована!'; END IF;
    IF (SELECT COALESCE(SUM(COALESCE(V.SUMPAY,0)),0)
                 FROM REGISTERLIST RS,
                      PAYS V, 
                      SLCOMPCHARGES T
                WHERE V.REGISTERLISTID = RS.ID 
                  AND T.ID = V.SLCOMPCHARGESID 
                  AND UPPER(T.DESCRIPTION) = 'SUMALL'
              ) = 0 THEN RAISE USING MESSAGE = 'Нет данных для формирования!'||tSQL;
    END IF;
    SELECT D.ID INTO nVED FROM DOCTYPES D WHERE D.CODE ILIKE '%расчетн%платежн%ведомость%';
    UD := P_SYSTEM_GEN_LID('SHEETDETAILS',nUID);
   -- SELECT L.ID INTO UD FROM USERS U, LEVACCESS L WHERE U.ID = P_ACTION_CREATE_PAYROLL.UID AND L.ID = U.LEVACCESSID;
    --сделать цикл 2 . и там сделать if где будет меняться значение
   FOR PA in 1..2
   loop 
   if PA = 1 then 
      PAYS[0]:='AND (SELECT SUM(COALESCE(V.SUMPAY,0)) FROM PAYS V, SLCOMPCHARGES T WHERE V.REGISTERLISTID = RS.ID AND T.ID = V.SLCOMPCHARGESID AND UPPER(T.DESCRIPTION) = ''COMPENSATION'') > 0'; 
      PAYS[1]:='(SELECT SUM(COALESCE(V.SUMPAY,0)) FROM PAYS V, SLCOMPCHARGES T WHERE V.REGISTERLISTID = RS.ID AND T.ID = V.SLCOMPCHARGESID AND UPPER(T.DESCRIPTION) = ''COMPENSATION'') AS SUMCOMP,';
      PAYS[2]:='0.0 AS SUMEXTRA12,';
      PAYS[3]:='0.0 AS EXTRAA,';
   else
      PAYS[0]:='AND (SELECT SUM(COALESCE(V.SUMPAY,0)) FROM PAYS V, SLCOMPCHARGES T WHERE V.REGISTERLISTID = RS.ID AND T.ID = V.SLCOMPCHARGESID AND (UPPER(T.DESCRIPTION) = ''SUMEXTRA12'' OR UPPER(T.DESCRIPTION) = ''EXTRAA'')) > 0';
      PAYS[1]:='0.0 AS SUMCOMP,';
      PAYS[2]:='(SELECT SUM(COALESCE(V.SUMPAY,0)) FROM PAYS V, SLCOMPCHARGES T WHERE V.REGISTERLISTID = RS.ID AND T.ID = V.SLCOMPCHARGESID AND UPPER(T.DESCRIPTION) = ''SUMEXTRA12'') AS SUMEXTRA12,';
      PAYS[3]:='(SELECT SUM(COALESCE(V.SUMPAY,0)) FROM PAYS V, SLCOMPCHARGES T WHERE V.REGISTERLISTID = RS.ID AND T.ID = V.SLCOMPCHARGESID AND UPPER(T.DESCRIPTION) = ''EXTRAA'') AS EXTRAA,';
   end if;
    --Шаблон запроса для заполнения таблицы SHEETDETAILS.
    tSQL:='SELECT RS.COMMITTEEMANID,
          '||CR||PAYS[1]||CR||PAYS[2]||CR||PAYS[3]||CR||'
          CH.TRPERSONID,
          CH.PERSONACCID,
          RS.ID AS REGLISTID,
          (SELECT F.MFIN FROM MFIN F WHERE F.ELECTCOMMITTEEID = I.ID AND F.BEGINDATE <= NOW() AND (F.ENDDATE >= NOW() OR F.ENDDATE IS NULL))::INTEGER AS MFIN
          /*
              1 - "участник зарплатного проекта"
            2 - "не участник зарплатного проекта"
            3 - "участник зарплатного проекта и подотчетное лицо"
          */
                    FROM REGISTERLIST RS,                                        /*Члены избирательной комиссии по ведомости*/
                         COMMITTEEMAN CH,                                        /*Члены избирательных комиссий*/
                         POSTS P,                                                /*Должности*/
                         /*добавлено по событию МАЦ-3993*/
                         REGISTER R,                                            /*Расчетные документы*/
                         ELECTCOMMINCAMP IK,                                    /*Избирательные комиссии*/
                         ELECTCOMMITTEE I                                        /*Избирательные комиссии и их состав*/
                   WHERE RS.REGISTERID = '||IDENT||'
                     AND CH.ID = RS.COMMITTEEMANID 
                     AND R.ID = RS.REGISTERID
                     AND IK.ID = R.ELECTCOMMINCAMPID
                     AND I.ID = IK.ELECTCOMMITTEEID'||CR||PAYS[0]||CR||'
                     AND (SELECT SP.SUMPAY FROM PAYS SP, SLCOMPCHARGES SL WHERE SP.REGISTERLISTID = RS.ID AND SL.ID = SP.SLCOMPCHARGESID AND SL.DESCRIPTION = ''SUMALL'') != 0
                     AND P.ID = CH.POSTSID'||CR;
                     
    NAL:='AND CH.PERSONACCID IS NULL'||CR||' AND CH.TRPERSONID IS NULL'||CR;      --Наличка
    BEZ:='AND CH.PERSONACCID IS NOT NULL'||CR||' AND CH.TRPERSONID IS NOT NULL'||CR; --Безнал
    N_PR:='AND UPPER(P.POSTPRINT) != ''CHAIRMAN'''||CR;                    --НЕ Председатель
    PR:='AND UPPER(P.POSTPRINT) = ''CHAIRMAN'''||CR;                            --Председатель
    
       --условия по "Разбить ведомости по виду оплаты (наличный и безналичный)"(BPAY) и "Выделить председателя в отдельную ведомость"(bchairman)    
    IF BCHAIRMAN AND BPAY THEN     
       /*
      Выделим председателя в отдельную ведомость. 
      По остальным членам спецификации REGISTERLIST определим есть ли реквизиты перечисления в таблице COMMITTEEMAN
      по полям PERSONID и PERSONACCID, и выделим в 2 группы. Итого = 3 документа
      */
      KOLS:=3;
    ELSIF NOT BCHAIRMAN AND BPAY THEN
      /*
      2 документа: один на председателя, второй-по остальным членам ИК
      */
      KOLS:=2;    
    ELSIF BCHAIRMAN AND NOT BPAY THEN
      /*
      2 документа по виду оплаты
      */
      KOLS:=2;    
    ELSIF NOT BCHAIRMAN AND NOT BPAY THEN
      /*
      Одна ведомость, в которую включаются все члены по расчетному документу
      */
      KOLS:=1;
    END IF; 
    
    
    FOR I IN 1..KOLS LOOP
      FOR SH IN
          select null as CODE,null as DOCPREF,null as DOCNUMB,null as DDOCDATE,t.ELECTCAMPAIGNID,t.ELECTDATE,t.ELECTCOMMINCAMPID,t.ID,t.LEVELEST,t.STATUS,
                 REPLACE(upper(sl.DESCRIPTION),'SUMEXTRA12','EXTRAA') as DESCRIPTION,t.REGIONSRFID
            from (
            SELECT R.ELECTCAMPAIGNID,
                   El.ELECTDATE,
                   R.ELECTCOMMINCAMPID,
                   R.ID,
                   --
                   CASE 
                     WHEN K.LEVELELCOMMITTEE ILIKE 'district' THEN 
                          CASE (SELECT F.MFIN FROM MFIN F WHERE F.ELECTCOMMITTEEID = K.ID AND F.BEGINDATE <= El.BEGINDATE AND (F.ENDDATE >=  El.BEGINDATE OR F.ENDDATE IS NULL))
                            WHEN '1' THEN 'terdist'
                            WHEN '2' THEN 'district'
                            WHEN '3' THEN 'terdist'
                          END 
                     WHEN K.LEVELELCOMMITTEE ILIKE 'territory' OR K.LEVELELCOMMITTEE ILIKE 'circuit' THEN
                         CASE 
                           WHEN D.CODE ILIKE '%ведомость%дот%за%актив%работ%председат%уик%' THEN 'terdist'
                           WHEN D.CODE ILIKE '%ведомость%дот%за%актив%работ%член%тик%' THEN 'territory'
                           WHEN D.CODE ILIKE '%комплект%расчетных%форм%' THEN 'territory'
                         END
                   END LEVELEST,
                   '1'::text as STATUS,
                   case lower(el.LEVELELCAMPAIGN)
                     when 'central' then (select rf.ID from REGIONSRF rf where rf.IDGASREGIONSRF = '00')--РФ
                     else k.REGIONSRFID
                   end as REGIONSRFID
              FROM REGISTER R
        INNER JOIN ELECTCAMPAIGN El ON El.ID = R.ELECTCAMPAIGNID
        INNER JOIN ELECTCOMMINCAMP E ON E.ID = R.ELECTCOMMINCAMPID
        INNER JOIN ELECTCOMMITTEE K ON K.ID = E.ELECTCOMMITTEEID
         LEFT JOIN DOCTYPES D ON D.ID = R.DOCTYPEID
             WHERE R.ID = IDENT) t
            INNER JOIN REGISTERLIST rs on rs.REGISTERID = t.ID
            INNER JOIN PAYS p on p.REGISTERLISTID = rs.ID
            INNER JOIN SLCOMPCHARGES sl on sl.ID = p.SLCOMPCHARGESID and upper(sl.DESCRIPTION) in ('COMPENSATION','EXTRAA','SUMEXTRA12')
         where REPLACE(upper(sl.DESCRIPTION),'SUMEXTRA12','EXTRAA') = 'COMPENSATION' and PA = 1 or REPLACE(upper(sl.DESCRIPTION),'SUMEXTRA12','EXTRAA') = 'EXTRAA' and PA = 2
        group by t.ELECTCAMPAIGNID,t.ELECTDATE,t.ELECTCOMMINCAMPID,t.ID,t.LEVELEST,
                 t.STATUS,t.REGIONSRFID,REPLACE(upper(sl.DESCRIPTION),'SUMEXTRA12','EXTRAA') 
        having COALESCE(sum(COALESCE(p.SUMPAY,0)),0) > 0
         
       LOOP
         SH.CODE:='Ведомость '||TO_CHAR(DDOCDATE,'YYYY')||'-'||UD||'-'||
                  (SELECT COALESCE(REGEXP_REPLACE(MAX(LPAD(DOCNUMB,80,' ')), '[^0-9]', '', 'g')::INT+1,1) FROM SHEETS WHERE DOCPREF = TO_CHAR(DDOCDATE,'YYYY')||'-'||UD AND CID=0)||' от '||to_char(ddocdate,'dd.mm.yyyy');
         SH.DOCPREF:=TO_CHAR(DDOCDATE,'YYYY')||'-'||UD AS DOCPREF;
         SH.DOCNUMB:=(SELECT COALESCE(REGEXP_REPLACE(MAX(LPAD(DOCNUMB,80,' ')), '[^0-9]', '', 'g')::INT+1,1) FROM SHEETS WHERE DOCPREF = TO_CHAR(DDOCDATE,'YYYY')||'-'||UD AND CID=0);
         select tp.ID into nTYPEEXP from typeexp tp where (tp.TYPEESTIMATE ~* 'К' and sh.DESCRIPTION = 'COMPENSATION' 
                                                        or tp.TYPEESTIMATE ~* 'Д' and sh.DESCRIPTION = 'EXTRAA') 
                                                       and tp.REGIONSRFID = sh.REGIONSRFID;
         INSERT INTO SHEETS(uid,lid,CODE,DOCTYPEID,DOCPREF,DOCNUMB,DOCDATE,ELECTCAMPAIGNID,ELECTDATE,ELECTCOMMINCAMPID,REGISTERID,LEVELESTIMATE,STATUS,TYPEEXPID)
            values(NUID,UD,sh.CODE,nVED,sh.DOCPREF,sh.DOCNUMB,DDOCDATE,sh.ELECTCAMPAIGNID,sh.ELECTDATE,sh.ELECTCOMMINCAMPID,sh.ID,sh.LEVELEST,sh.STATUS,nTYPEEXP)
               RETURNING SHEETS.ID 
                    INTO nID;
        IF BCHAIRMAN AND BPAY THEN     
           IF I = 1 THEN  --Отдельно председатели
            SQL_BUF:=tSQL;
               SQL_BUF:=SQL_BUF||PR;  --Председатель
            FOR RC IN EXECUTE SQL_BUF
               LOOP
                IF RC.MFIN = 2 THEN
                    RAISE USING MESSAGE = 'Формирование ведомостей запрещено! Оплата труда членам УИК осуществляется самостоятельно.';
                END IF;
                INSERT INTO SHEETDETAILS(uid, LID, SHEETSID,COMMITTEEMANID,   SUMCOMP,   SUMEXTRA12,   EXTRAA,   TRPERSONID,   PERSONACCID)
                                    VALUES(NUID, UD, NID, RC.COMMITTEEMANID,RC.SUMCOMP,RC.SUMEXTRA12,RC.EXTRAA,RC.TRPERSONID,RC.PERSONACCID);
                UPDATE PAYS P SET SHEETSID = NID WHERE P.REGISTERLISTID = RC.REGLISTID AND P.SLCOMPCHARGESID IN (SELECT SL.ID
                                                                                                                   FROM SLCOMPCHARGES SL 
                                                                                                                  WHERE UPPER(SL.DESCRIPTION) = 'COMPENSATION' AND PA = 1
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'SUMEXTRA12' AND PA = 2
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'EXTRAA' AND PA = 2); 
                
            END LOOP;
           ELSIF I = 2 THEN --Без председателей и наличкой
               SQL_BUF:=tSQL;
            SQL_BUF:=SQL_BUF||N_PR;  --НЕ Председатель
            SQL_BUF:=SQL_BUF||BEZ;   --Безнал
            FOR RC IN EXECUTE SQL_BUF
               LOOP
                IF RC.MFIN = 2 THEN
                    RAISE USING MESSAGE = 'Формирование ведомостей запрещено! Оплата труда членам УИК осуществляется самостоятельно.';
                END IF;
                INSERT INTO SHEETDETAILS(uid, LID, SHEETSID,COMMITTEEMANID,   SUMCOMP,   SUMEXTRA12,   EXTRAA,   TRPERSONID,   PERSONACCID)
                                    VALUES(NUID, UD, NID, RC.COMMITTEEMANID,RC.SUMCOMP,RC.SUMEXTRA12,RC.EXTRAA,RC.TRPERSONID,RC.PERSONACCID);
                UPDATE PAYS P SET SHEETSID = NID WHERE P.REGISTERLISTID = RC.REGLISTID AND P.SLCOMPCHARGESID IN (SELECT SL.ID
                                                                                                                   FROM SLCOMPCHARGES SL 
                                                                                                                  WHERE UPPER(SL.DESCRIPTION) = 'COMPENSATION' AND PA = 1
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'SUMEXTRA12' AND PA = 2
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'EXTRAA' AND PA = 2);
                
            END LOOP;
           ELSIF I = 3 THEN --Без председателей и безналом
               SQL_BUF:=tSQL;
            SQL_BUF:=SQL_BUF||N_PR;  --НЕ Председатель
            SQL_BUF:=SQL_BUF||NAL;   --Наличка
            FOR RC IN EXECUTE SQL_BUF
               LOOP
                IF RC.MFIN = 2 THEN
                    RAISE USING MESSAGE = 'Формирование ведомостей запрещено! Оплата труда членам УИК осуществляется самостоятельно.';
                END IF;
                INSERT INTO SHEETDETAILS(uid, LID, SHEETSID,COMMITTEEMANID,   SUMCOMP,   SUMEXTRA12,   EXTRAA,   TRPERSONID,   PERSONACCID)
                                    VALUES(NUID, UD, NID, RC.COMMITTEEMANID,RC.SUMCOMP,RC.SUMEXTRA12,RC.EXTRAA,RC.TRPERSONID,RC.PERSONACCID);
                UPDATE PAYS P SET SHEETSID = NID WHERE P.REGISTERLISTID = RC.REGLISTID AND P.SLCOMPCHARGESID IN (SELECT SL.ID
                                                                                                                   FROM SLCOMPCHARGES SL 
                                                                                                                  WHERE UPPER(SL.DESCRIPTION) = 'COMPENSATION' AND PA = 1
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'SUMEXTRA12' AND PA = 2
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'EXTRAA' AND PA = 2);
                 
            END LOOP;
           END IF;
        ELSIF NOT BCHAIRMAN AND BPAY THEN
           IF I = 1 THEN --Наличкой
               SQL_BUF:=tSQL;
            SQL_BUF:=SQL_BUF||NAL;
            FOR RC IN EXECUTE SQL_BUF
               LOOP
                IF RC.MFIN = 2 THEN
                    RAISE USING MESSAGE = 'Формирование ведомостей запрещено! Оплата труда членам УИК осуществляется самостоятельно.';
                END IF;
                INSERT INTO SHEETDETAILS(uid, LID, SHEETSID,COMMITTEEMANID,   SUMCOMP,   SUMEXTRA12,   EXTRAA,   TRPERSONID,   PERSONACCID)
                                    VALUES(NUID, UD, NID, RC.COMMITTEEMANID,RC.SUMCOMP,RC.SUMEXTRA12,RC.EXTRAA,RC.TRPERSONID,RC.PERSONACCID);
                UPDATE PAYS P SET SHEETSID = NID WHERE P.REGISTERLISTID = RC.REGLISTID AND P.SLCOMPCHARGESID IN (SELECT SL.ID
                                                                                                                   FROM SLCOMPCHARGES SL 
                                                                                                                  WHERE UPPER(SL.DESCRIPTION) = 'COMPENSATION' AND PA = 1
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'SUMEXTRA12' AND PA = 2
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'EXTRAA' AND PA = 2); 
                
            END LOOP;           
           ELSIF I = 2 THEN --Безналом
               SQL_BUF:=tSQL;
            SQL_BUF:=SQL_BUF||BEZ;
            FOR RC IN EXECUTE SQL_BUF
               LOOP
                IF RC.MFIN = 2 THEN
                    RAISE USING MESSAGE = 'Формирование ведомостей запрещено! Оплата труда членам УИК осуществляется самостоятельно.';
                END IF;
                INSERT INTO SHEETDETAILS(uid, LID, SHEETSID,COMMITTEEMANID,   SUMCOMP,   SUMEXTRA12,   EXTRAA,   TRPERSONID,   PERSONACCID)
                                    VALUES(NUID, UD, NID, RC.COMMITTEEMANID,RC.SUMCOMP,RC.SUMEXTRA12,RC.EXTRAA,RC.TRPERSONID,RC.PERSONACCID);
                UPDATE PAYS P SET SHEETSID = NID WHERE P.REGISTERLISTID = RC.REGLISTID AND P.SLCOMPCHARGESID IN (SELECT SL.ID
                                                                                                                   FROM SLCOMPCHARGES SL 
                                                                                                                  WHERE UPPER(SL.DESCRIPTION) = 'COMPENSATION' AND PA = 1
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'SUMEXTRA12' AND PA = 2
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'EXTRAA' AND PA = 2);
                
            END LOOP;
           END IF;  
        ELSIF BCHAIRMAN AND NOT BPAY THEN
           IF I = 1 THEN --Председатель
               SQL_BUF:=tSQL;
            SQL_BUF:=SQL_BUF||PR;
            FOR RC IN EXECUTE SQL_BUF
               LOOP
                IF RC.MFIN = 2 THEN
                    RAISE USING MESSAGE = 'Формирование ведомостей запрещено! Оплата труда членам УИК осуществляется самостоятельно.';
                END IF;
                INSERT INTO SHEETDETAILS(uid, LID, SHEETSID,COMMITTEEMANID,   SUMCOMP,   SUMEXTRA12,   EXTRAA,   TRPERSONID,   PERSONACCID)
                                    VALUES(NUID, UD, NID, RC.COMMITTEEMANID,RC.SUMCOMP,RC.SUMEXTRA12,RC.EXTRAA,RC.TRPERSONID,RC.PERSONACCID);
                UPDATE PAYS P SET SHEETSID = NID WHERE P.REGISTERLISTID = RC.REGLISTID AND P.SLCOMPCHARGESID IN (SELECT SL.ID
                                                                                                                   FROM SLCOMPCHARGES SL 
                                                                                                                  WHERE UPPER(SL.DESCRIPTION) = 'COMPENSATION' AND PA = 1
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'SUMEXTRA12' AND PA = 2
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'EXTRAA' AND PA = 2); 
                
            END LOOP;
           ELSIF I = 2 THEN --НЕ Председатель
               SQL_BUF:=tSQL;
            SQL_BUF:=SQL_BUF||N_PR;
            FOR RC IN EXECUTE SQL_BUF
               LOOP
                IF RC.MFIN = 2 THEN
                    RAISE USING MESSAGE = 'Формирование ведомостей запрещено! Оплата труда членам УИК осуществляется самостоятельно.';
                END IF;
                INSERT INTO SHEETDETAILS(uid, LID, SHEETSID,COMMITTEEMANID,   SUMCOMP,   SUMEXTRA12,   EXTRAA,   TRPERSONID,   PERSONACCID)
                                    VALUES(NUID, UD, NID, RC.COMMITTEEMANID,RC.SUMCOMP,RC.SUMEXTRA12,RC.EXTRAA,RC.TRPERSONID,RC.PERSONACCID);
                UPDATE PAYS P SET SHEETSID = NID WHERE P.REGISTERLISTID = RC.REGLISTID AND P.SLCOMPCHARGESID IN (SELECT SL.ID
                                                                                                                   FROM SLCOMPCHARGES SL 
                                                                                                                  WHERE UPPER(SL.DESCRIPTION) = 'COMPENSATION' AND PA = 1
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'SUMEXTRA12' AND PA = 2
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'EXTRAA' AND PA = 2);
                
            END LOOP;
           END IF;
        ELSIF NOT BCHAIRMAN AND NOT BPAY THEN
           FOR RC IN EXECUTE tSQL
            LOOP
                IF RC.MFIN = 2 THEN
                    RAISE USING MESSAGE = 'Формирование ведомостей запрещено! Оплата труда членам УИК осуществляется самостоятельно.';
                END IF;
               -- BEGIN
                INSERT INTO SHEETDETAILS(uid, LID, SHEETSID,COMMITTEEMANID,   SUMCOMP,   SUMEXTRA12,   EXTRAA,   TRPERSONID,   PERSONACCID)
                                    VALUES(NUID, UD, NID, RC.COMMITTEEMANID,RC.SUMCOMP,RC.SUMEXTRA12,RC.EXTRAA,RC.TRPERSONID,RC.PERSONACCID);
               -- EXCEPTION WHEN OTHERS THEN  RAISE USING MESSAGE = COALESCE(RC.COMMITTEEMANID,-1)||' '||COALESCE(RC.SUMCOMP,-1)||' '||COALESCE(RC.SUMEXTRA12,-1)||' '||COALESCE(RC.EXTRAA,-1)||' '||COALESCE(RC.TRPERSONID,-1)||' '||COALESCE(RC.PERSONACCID,-1); END;
                UPDATE PAYS P SET SHEETSID = NID WHERE P.REGISTERLISTID = RC.REGLISTID AND P.SLCOMPCHARGESID IN (SELECT SL.ID
                                                                                                                   FROM SLCOMPCHARGES SL 
                                                                                                                  WHERE UPPER(SL.DESCRIPTION) = 'COMPENSATION' AND PA = 1
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'SUMEXTRA12' AND PA = 2
                                                                                                                     OR UPPER(SL.DESCRIPTION) = 'EXTRAA' AND PA = 2);
               --raise using message = ; 
            END LOOP;
        END IF;
        
            
            
     --Проверка на наличие спецификации
     IF (SELECT COUNT(*) FROM SHEETDETAILS SD WHERE SD.SHEETSID = NID) = 0 THEN DELETE FROM SHEETS S WHERE S.ID = NID; END IF;
     END LOOP;
    END LOOP;
    UPDATE REGISTER R SET STATUS = '4' WHERE R.ID = IDENT;
  end loop; 
    RETURN NULL;    
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_create_payroll (id bigint, ddocdate date, bpay boolean, bchairman boolean, uid bigint)
  OWNER TO magicbox;