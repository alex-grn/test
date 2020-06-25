﻿-- Function: public.p_action_stages_form_rko(text, bigint, date, bigint)

-- DROP FUNCTION public.p_action_stages_form_rko(text, bigint, date, bigint);

CREATE OR REPLACE FUNCTION public.p_action_stages_form_rko(
    idlist text,
    uid bigint,
    ddate date,
    unit bigint)
  RETURNS text AS
$BODY$
declare
  NUID            BIGINT := UID;
  NID             BIGINT;
  REC             record;
  CH              record;
  NCASHDOCSID     BIGINT;
  NDOCTYPEID      BIGINT;
  NTYPICALOPERSID BIGINT;
  NEXT_NUM        INTEGER;
  dBEGINDATETER   DATE;
  dENDDATETER     DATE;
  nELECTCAMPAIGNID BIGINT;
begin
  --Найдем тип документа "Расходный кассовый ордер"
  select D.ID into NDOCTYPEID from DOCTYPES D where D.CODE ILIKE '%расходны_%касс%';
  --Найдем в типовых операциях "Выдача наличных на оплату труда члену избирательной комиссии"
  select T.ID into NTYPICALOPERSID from TYPICALOPERS T where T.CODE ILIKE '%Выдач%налич%оплат%договор%граждан%правов%характер%';

  for REC in select  S.ID,
                   --  SS.TRPERSONID,
                     C.ELECTCAMPAIGNID,
                     C.JURPERSONSID,
                     SS.DOCNUMB,
                     d2s(SS.DOCDATE) as DOCDATE,
                     COALESCE(S.SUMM, 0) as SUMM,
                     S.BUDGCLASSID,
                     S.ECONCLASSKTID,
                     S.TYPEEXPID,
                     ss.PERSONID,
                     s.LEVELESTIMATE
                from PERSONS_STAGES  S
          inner join PERSON_CONTRACTSDOCS SS on SS.ID = S.PERSON_CONTRACTSDOCSID
          inner join CONTRACTS C on C.ID = SS.CONTRACTSID
               where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
  loop
   --МАЦ-4301 проверка дат
    For ch in
    (select *
       from electcampaign e
      where e.id = REC.ELECTCAMPAIGNID
        and ddate not between e.BEGINDATETER and e.ENDDATETER)
    loop
       raise using message = 'Дата документа должна быть в периоде работы ТИК('||to_char(ch.BEGINDATETER,'dd.mm.yyyy')||'-'||to_char(ch.ENDDATETER,'dd.mm.yyyy')||')';
    end loop;
   --
    select e.begindateter, e.enddateter
      into dBEGINDATETER, dENDDATETER
      from electcampaign e
     where e.id = REC.ELECTCAMPAIGNID;
    begin
      --Найдем расчетный счет в банке
      select C.ID, C.ELECTCAMPAIGNID
        into STRICT NCASHDOCSID, nELECTCAMPAIGNID
        from CASHDOCS   C
       where C.JURPERSONSID = REC.JURPERSONSID
         and C.ELECTCAMPAIGNID = REC.ELECTCAMPAIGNID;
    exception
      when NO_DATA_FOUND then
        insert into CASHDOCS(uid, lid, JURPERSONSID, ELECTCAMPAIGNID)
             values(NUID, P_SYSTEM_GEN_LID('CASHDOCS',nUID,UNIT), REC.JURPERSONSID, REC.ELECTCAMPAIGNID)
             returning CASHDOCS.ID into NCASHDOCSID;
        nELECTCAMPAIGNID:=REC.ELECTCAMPAIGNID;
      when TOO_MANY_ROWS then
        raise
          using MESSAGE = 'Критическая ошибка, найдено больше записей чем предполагалось. Обратитесь к администратору.';
    end;
    
    --Найдем след номер документа
    select coalesce(regexp_replace(max(lpad(DOCNUMB::text,80,' ')), '[^0-9]', '', 'g')::int+1,1) into NEXT_NUM from CASHPAYMENT_HEADER where CASHDOCSID = NCASHDOCSID and DOCSTATUS!='3';

    --Вставим строку в документ платежного поручения
    insert into CASHPAYMENT_HEADER
      (UID, LID, CASHDOCSID, DOCTYPEID, DOCSTATUS, DOCNUMB, DOCDATE, PERSONID, BASIS, BEGINDATETIK, ENDDATETIK, ELECTCAMPAIGNID)
    values
      (NUID, P_SYSTEM_GEN_LID('CASHPAYMENT_HEADER',nUID,UNIT), NCASHDOCSID, NDOCTYPEID, '1', NEXT_NUM, DDATE, REC.PERSONID, 'Оплата по договору № ' || REC.DOCNUMB || ' от ' || REC.DOCDATE, dBEGINDATETER, dENDDATETER, nELECTCAMPAIGNID)
    returning CASHPAYMENT_HEADER.ID into NID;

    --Добавим строку расшифровки для платежного поручения
    insert into CASHPAYMENT
      (UID, LID, CASHPAYMENTHEADERID, SUMMPAY, NUMBPP, BUDGCLASSID, ECONCLASSKTID, TYPEEXPID, TYPICALOPERSID, LEVELESTIMATE)
    values
      (NUID, P_SYSTEM_GEN_LID('CASHPAYMENT',nUID,UNIT), NID, REC.SUMM, 1, REC.BUDGCLASSID, REC.ECONCLASSKTID, REC.TYPEEXPID, NTYPICALOPERSID, REC.LEVELESTIMATE)
    returning CASHPAYMENT.ID into NID;
    --Создадим связь
    PERFORM P_SYSTEM_DOCLINKS_ADD('PERSONS_STAGES',REC.ID,'CASHPAYMENT',NID);
  end loop;
  return 'Расходный кассовый ордер успешно сформирован';
  exception when others then 
    return 'Формирование расходного кассового ордера не выполнено';
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_stages_form_rko(text, bigint, date, bigint)
  OWNER TO magicbox;
