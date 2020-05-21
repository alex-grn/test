CREATE OR REPLACE FUNCTION public.p_action_stages_form_rko (
  idlist text,
  uid bigint,
  ddate date
)
RETURNS void AS
$body$
declare
  NUID            BIGINT := UID;
  NID             BIGINT;
  REC             record;
  CH              record;
  NCASHDOCSID     BIGINT;
  NDOCTYPEID      BIGINT;
  NTYPICALOPERSID BIGINT;
  NEXT_NUM        INTEGER;
begin
  --Найдем тип документа "Расходный кассовый ордер"
  select D.ID into NDOCTYPEID from DOCTYPES D where D.CODE ILIKE '%расходны_%касс%';
  --Найдем в типовых операциях "Выдача наличных на оплату труда члену избирательной комиссии"
  select T.ID into NTYPICALOPERSID from TYPICALOPERS T where T.CODE ILIKE '%Выдач%налич%оплат%договор%граждан%правов%характер%';

  for REC in (select  S.ID,
                     SS.TRPERSONID,
                     C.ELECTCAMPAIGNID,
                     C.JURPERSONSID,
                     SS.DOCNUMB,
                     d2s(SS.DOCDATE) as DOCDATE,
                     COALESCE(S.SUMM, 0) as SUMM,
                     S.BUDGCLASSID,
                     S.ECONCLASSKTID,
                     S.TYPEEXPID
                from PERSONS_STAGES  S,
                     PERSON_CONTRACTSDOCS SS,
                     CONTRACTS C
               where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                 and SS.ID = S.PERSON_CONTRACTSDOCSID
                 and C.ID = SS.CONTRACTSID)
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
      --Найдем расчетный счет в банке
      select C.ID
        into STRICT NCASHDOCSID
        from CASHDOCS   C
       where C.JURPERSONSID = REC.JURPERSONSID
         and C.ELECTCAMPAIGNID = REC.ELECTCAMPAIGNID;
    exception
      when NO_DATA_FOUND then
        insert into CASHDOCS(uid, lid, JURPERSONSID, ELECTCAMPAIGNID)
             values(NUID, P_SYSTEM_GEN_LID('CASHDOCS',nUID), REC.JURPERSONSID, REC.ELECTCAMPAIGNID)
             returning CASHDOCS.ID into NCASHDOCSID;
      when TOO_MANY_ROWS then
        raise
          using MESSAGE = 'Критическая ошибка, найдено больше записей чем предполагалось. Обратитесь к администратору.';
    end;

    --Найдем след номер документа
    select coalesce(regexp_replace(max(lpad(DOCNUMB::text,80,' ')), '[^0-9]', '', 'g')::int+1,1) into NEXT_NUM from CASHPAYMENT_HEADER where CASHDOCSID = NCASHDOCSID and DOCSTATUS!='3';

    --Вставим строку в документ платежного поручения
    insert into CASHPAYMENT_HEADER
      (UID, LID, CASHDOCSID, DOCTYPEID, DOCSTATUS, DOCNUMB, DOCDATE, PERSONID, PURPOSE)
    values
      (NUID, P_SYSTEM_GEN_LID('CASHPAYMENT_HEADER',nUID), NCASHDOCSID, NDOCTYPEID, '1', NEXT_NUM, DDATE, REC.TRPERSONID, 'Оплата по договору № ' || REC.DOCNUMB || ' от ' || REC.DOCDATE)
    returning CASHPAYMENT_HEADER.ID into NID;

    --Добавим строку расшифровки для платежного поручения
    insert into CASHPAYMENT
      (UID, LID, CASHPAYMENTHEADERID, SUMMPAY, NUMBPP, BUDGCLASSID, ECONCLASSKTID, TYPEEXPID, TYPICALOPERSID)
    values
      (NUID, P_SYSTEM_GEN_LID('CASHPAYMENT',nUID), NID, REC.SUMM, 1, REC.BUDGCLASSID, REC.ECONCLASSKTID, REC.TYPEEXPID, NTYPICALOPERSID)
    returning CASHPAYMENT.ID into NID;
    --Создадим связь
    PERFORM P_SYSTEM_DOCLINKS_ADD('PERSONS_STAGES',REC.ID,'CASHPAYMENT',NID);
  end loop;

end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_stages_form_rko (idlist text, uid bigint, ddate date)
  OWNER TO magicbox;