CREATE OR REPLACE FUNCTION public.p_action_stages_form_pp (
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
  NPAYACCOUNTSID  BIGINT;
  NDOCTYPEID      BIGINT;
  NTYPICALOPERSID BIGINT;
  NEXT_NUM        INTEGER;
begin
   --Найдем тип документа "Платежное поручение"
   select D.ID into NDOCTYPEID from DOCTYPES D where D.CODE ILIKE '%плат_жное%';
   --Найдем в типовых операциях "Перечисление на лицевой счет члена избирательной комиссии"
   select T.ID into NTYPICALOPERSID from TYPICALOPERS T where T.CODE ILIKE '%Перечислен%средств%оплат%договор%';

  for REC in (select S.ID,
                     SS.AGENTID,
                     SS.AGENTACCID,
                     C.ELECTCAMPAIGNID,
                     C.JURPERSONSID,
                     SS.DOCNUMB,
                     d2s(SS.DOCDATE) as DOCDATE,
                     COALESCE(S.SUMM, 0) as SUMM,
                     S.BUDGCLASSID,
                     S.ECONCLASSKTID,
                     S.TYPEEXPID
                from STAGES          S,
                     CONTRACTSDOCS   SS,
                     CONTRACTS       C
               where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                 and SS.ID = S.CONTRACTSDOCSID
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
    select P.ID
      into STRICT NPAYACCOUNTSID
      from PAYACCOUNTS P
     where P.JURPERSONSID = REC.JURPERSONSID
       and P.ELECTCAMPAIGNID = REC.ELECTCAMPAIGNID;
   exception when no_data_found then
             insert into PAYACCOUNTS(uid, lid, JURPERSONSID, ELECTCAMPAIGNID)
             values(NUID, P_SYSTEM_GEN_LID('PAYACCOUNTS',nUID), REC.JURPERSONSID,REC.ELECTCAMPAIGNID)
             returning PAYACCOUNTS.ID into NPAYACCOUNTSID;
             when too_many_rows then raise using MESSAGE = 'Критическая ошибка, найдено больше записей чем предполагалось. Обратитесь к администратору.';
   end;

    --Найдем след номер документа
    select coalesce(regexp_replace(max(lpad(docnumb::text,80,' ')), '[^0-9]', '', 'g')::int+1,1) into NEXT_NUM from PAYDOCS where PAYACCOUNTSID = NPAYACCOUNTSID and date_trunc('year', DOCDATE) = date_trunc('year', DDATE);

    --Вставим строку в документ платежного поручения
    insert into PAYDOCS
      (UID, LID, PAYACCOUNTSID, DOCTYPEID, DOCNUMB, DOCDATE, NTAX, AGENTID, AGENTACCID, PURPOSE, PRIORITY, STATUS)
    values
      (NUID, P_SYSTEM_GEN_LID('PAYDOCS',nUID), NPAYACCOUNTSID, NDOCTYPEID, COALESCE(NEXT_NUM,1), DDATE, '20', REC.AGENTID, REC.AGENTACCID, 'Оплата по договору ' || REC.DOCNUMB||' от '||REC.DOCDATE, '1', '0')
    returning PAYDOCS.ID into NID;

    --Добавим строку расшифровки для платежного поручения
    insert into PAYDOCSCONS
      (UID, LID, PAYDOCSID, SUMM, NUMBPP, BUDGCLASSID, ECONCLASSKTID, TYPEEXPID, TYPICALOPERSID)
    values
      (nUID, P_SYSTEM_GEN_LID('PAYDOCSCONS',nUID), NID, REC.SUMM, 1, REC.BUDGCLASSID, REC.ECONCLASSKTID, REC.TYPEEXPID, NTYPICALOPERSID)
    returning PAYDOCSCONS.ID into NID;
    --Создадим связь
    PERFORM P_SYSTEM_DOCLINKS_ADD('STAGES',REC.ID,'PAYDOCSCONS',NID);
  end loop;

end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_stages_form_pp (idlist text, uid bigint, ddate date)
  OWNER TO magicbox;