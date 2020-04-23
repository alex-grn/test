CREATE OR REPLACE FUNCTION public.p_action_stages_pers_form_pp (
  idlist text,
  uid bigint,
  doctypeid bigint,
  ddate date,
  priority text,
  typicalopersid bigint
)
RETURNS void AS
$body$
declare
  NUID             BIGINT := UID;
  NLID_PAYACCOUNTS BIGINT;
  NLID_PAYDOCS 	   BIGINT;
  NID              BIGINT;
  REC              record;
  NPAYACCOUNTSID   BIGINT;
  NDOCTYPEID       BIGINT;
  NTYPICALOPERSID  BIGINT;
  NEXT_NUM         INTEGER;
  dbegindateter    electcampaign.begindateter%type;
  denddateter      electcampaign.enddateter%type;
begin
  --Найдем тип документа "Платежное поручение"
  NDOCTYPEID := doctypeid;

  -- определение прав
  NLID_PAYACCOUNTS := P_SYSTEM_GEN_LID('PAYACCOUNTS', NUID);
  NLID_PAYDOCS     := P_SYSTEM_GEN_LID('PAYDOCS', NUID);

  -- выборка отмеченных записей
  for REC in (select ps.id,
  				     C.ID as contracts_id,
                     pc.id as person_contractsdocs_id,
                     pc.PERSONID,
                     pc.PERSONACCDID,
                     pc.DOCNUMB,
                     pc.docdate,
                     ps.summ,
                     ps.budgclassid,
                     ps.econclassktid,
                     ps.typeexpid,
                     c.ELECTCAMPAIGNID,
                     c.jurpersonsid
                from PERSONS_STAGES PS
                left join PERSON_CONTRACTSDOCS PC on PC.ID = PS.person_contractsdocsid
                left join CONTRACTS             C on C.ID = PC.contractsid
               where ps.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST)))
  loop
    --Найдем расчетный счет в банке
    begin
     select P.ID
       into STRICT NPAYACCOUNTSID
       from PAYACCOUNTS P
      where P.JURPERSONSID = REC.JURPERSONSID
        and P.ELECTCAMPAIGNID = REC.ELECTCAMPAIGNID;
    exception
      when no_data_found then
        insert into PAYACCOUNTS(lid, uid, JURPERSONSID, ELECTCAMPAIGNID) values(NLID_PAYACCOUNTS, NUID, REC.JURPERSONSID, REC.ELECTCAMPAIGNID)
          returning ID into NPAYACCOUNTSID;
      when too_many_rows then
        raise using MESSAGE = 'Определено больше одной записей лицевого счета в банке!';
    end;

  -- определение периода
  select e.begindateter,
  	     e.enddateter
    into dbegindateter,
         denddateter
    from electcampaign e,
         PAYACCOUNTS   c
   where e.id = c.ELECTCAMPAIGNID
     and c.id= NPAYACCOUNTSID;

  if DDATE not between dbegindateter and denddateter then
    raise using message = 'Дата документа "'|| d2s(DDATE) ||'" должна быть в периоде работы ТИК, с "'||d2s(dbegindateter)||'" по "'||d2s(denddateter)||'"!';
  end if;

    -- Найдем след номер документа
    select coalesce(regexp_replace(max(lpad(docnumb::text,80,' ')), '[^0-9]', '', 'g')::int+1,1)
      into NEXT_NUM
      from PAYDOCS
     where PAYACCOUNTSID = NPAYACCOUNTSID
       and date_trunc('year', DOCDATE) = date_trunc('year', ddate);
    -- Вставим строку в документ платежного поручения
    insert into PAYDOCS(LID, UID, PAYACCOUNTSID, DOCTYPEID, DOCNUMB, DOCDATE, NTAX, personid, personaccdocid, PURPOSE, PRIORITY, STATUS)
    values
      (NLID_PAYDOCS, NUID, NPAYACCOUNTSID, NDOCTYPEID, NEXT_NUM, DDATE, '20', REC.PERSONID, REC.PERSONACCDID, 'Оплата по договору ' || REC.DOCNUMB||' от '||d2s(REC.DOCDATE), Priority, '0')
    returning ID into NID;

    -- Добавим строку расшифровки для платежного поручения
    insert into PAYDOCSCONS
      (LID, UID, PAYDOCSID, SUMM, NUMBPP, BUDGCLASSID, ECONCLASSKTID, TYPEEXPID, TYPICALOPERSID)
    values
      (NLID_PAYDOCS, nUID, NID, REC.SUMM, 1, REC.BUDGCLASSID, REC.ECONCLASSKTID, REC.TYPEEXPID, p_action_stages_pers_form_pp.Typicalopersid)
    returning ID into NID;
    --Создадим связь
    PERFORM P_SYSTEM_DOCLINKS_ADD('PERSONS_STAGES',REC.ID,'PAYDOCSCONS',NID);
  end loop;

end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_stages_pers_form_pp (idlist text, uid bigint, doctypeid bigint, ddate date, priority text, typicalopersid bigint)
  OWNER TO magicbox;