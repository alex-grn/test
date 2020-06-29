-- Function: public.p_action_sheetdetails_form_rko(text, bigint, bigint, date, bigint, bigint)

-- DROP FUNCTION public.p_action_sheetdetails_form_rko(text, bigint, bigint, date, bigint, bigint);

CREATE OR REPLACE FUNCTION public.p_action_sheetdetails_form_rko(
    idlist text,
    uid bigint,
    unit bigint,
    ddate date,
    budgclassid bigint,
    econclassktid bigint)
  RETURNS void AS
$BODY$
declare
  NUID            BIGINT := UID;
  NID             BIGINT;
  REC             record;
  CH              record;
  NCASHDOCSID     BIGINT;
  NDOCTYPEID      BIGINT;
  NBUDGCLASSID    BIGINT := BUDGCLASSID;
  NECONCLASSKTID  BIGINT := ECONCLASSKTID;
  NTYPICALOPERSID BIGINT;
  NEXT_NUM        INTEGER;
  NCASHPAYMENT	  BIGINT;
begin
  --Найдем тип документа "Расходный кассовый ордер"
  select D.ID into NDOCTYPEID from DOCTYPES D where D.CODE ILIKE '%расходны_%касс%';
  --Найдем в типовых операциях "Выдача наличных на оплату труда члену избирательной комиссии"
  select T.ID into NTYPICALOPERSID from TYPICALOPERS T where T.CODE ILIKE '%Выдача%наличных%на%оплату%труда%члену%';

  for REC in select S.ID,
                     cm.PERSONID,
                     S.PERSONACCID,
                     SS.ELECTCAMPAIGNID,
                     case lower(k.levelelcommittee)
                      when 'district' then (select i.id from ELECTCOMMITTEE i where i.idgasecom = k.idgasparecom)
                      else k.id
                     end as ELECTCOMMITTEEID,
                     --E.ELECTCOMMITTEEID,
                     COALESCE(S.SUMCOMP, 0) + COALESCE(S.SUMEXTRA12, 0) + COALESCE(S.EXTRAA, 0) as SUMM,
                     sS.DOCNUMB,
                     sS.DOCDATE,
                     sS.LEVELESTIMATE,
                     sS.TYPEEXPID
                from SHEETDETAILS    S,
                     SHEETS          SS,
                     ELECTCOMMINCAMP E,
                     ELECTCOMMITTEE  k,
                     COMMITTEEMAN cm
               where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                 and SS.ID = S.SHEETSID
                 and E.ID = SS.ELECTCOMMINCAMPID
                 and k.ID = e.ELECTCOMMITTEEID
                 and cm.ELECTCOMMITTEEID = k.ID
                 and cm.ID = s.COMMITTEEMANID
                 
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

    begin
      --Найдем журнал кассовых документов по избирательной кампании и комиссии
      select C.ID
        into STRICT NCASHDOCSID
        from CASHDOCS   C,
             JURPERSONS J
       where J.ID = C.JURPERSONSID
         and J.ELECTCOMMITTEEID = REC.ELECTCOMMITTEEID
         and C.ELECTCAMPAIGNID = REC.ELECTCAMPAIGNID;
    exception
      when NO_DATA_FOUND then
        insert into CASHDOCS(uid, lid, JURPERSONSID, ELECTCAMPAIGNID)
             values(NUID, P_SYSTEM_GEN_LID('CASHDOCS',nUID,UNIT), (select t.id from JURPERSONS t where t.ELECTCOMMITTEEID = REC.ELECTCOMMITTEEID),REC.ELECTCAMPAIGNID)
             returning CASHDOCS.ID into NCASHDOCSID;
      when TOO_MANY_ROWS then
        raise
          using MESSAGE = 'Критическая ошибка, найдено больше записей чем предполагалось. Обратитесь к администратору.';
    end;

    --Найдем след номер документа
    select coalesce(regexp_replace(max(lpad(DOCNUMB::text,80,' ')), '[^0-9]', '', 'g')::int+1,1) into NEXT_NUM from CASHPAYMENT_HEADER where CASHDOCSID = NCASHDOCSID and DOCSTATUS!='3';

    --Вставим строку в документ РКО
    insert into CASHPAYMENT_HEADER
      (UID, LID, CASHDOCSID, DOCTYPEID, DOCSTATUS, DOCNUMB, DOCDATE, PERSONID, BASIS,ELECTCAMPAIGNID)
    values
      (NUID, P_SYSTEM_GEN_LID('CASHPAYMENT_HEADER',nUID,UNIT), NCASHDOCSID, NDOCTYPEID, '1', COALESCE(NEXT_NUM,1), DDATE, REC.PERSONID, 'Расчетно-платежная ведомость № ' || REC.DOCNUMB || ' от ' || REC.DOCDATE, rec.ELECTCAMPAIGNID)
    returning CASHPAYMENT_HEADER.ID into NID;

    --Добавим строку расшифровки для РКО
    insert into CASHPAYMENT (UID, LID, CASHPAYMENTHEADERID, SUMMPAY, NUMBPP, BUDGCLASSID, ECONCLASSKTID, TYPICALOPERSID, LEVELESTIMATE, TYPEEXPID)
    values (NUID, P_SYSTEM_GEN_LID('CASHPAYMENT',nUID,UNIT), NID, REC.SUMM, 1, NBUDGCLASSID, NECONCLASSKTID, NTYPICALOPERSID, rec.LEVELESTIMATE, rec.TYPEEXPID)
    returning id into NCASHPAYMENT;
    update SHEETDETAILS S set CASHPAYMENTHEADERID = NID where S.ID = REC.ID;

    -- установим линк
    PERFORM P_SYSTEM_DOCLINKS_ADD('SHEETDETAILS', REC.ID, 'CASHPAYMENT', NCASHPAYMENT);
  end loop;

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_sheetdetails_form_rko(text, bigint, bigint, date, bigint, bigint)
  OWNER TO magicbox;
