-- Function: public.p_action_stages_form_pp_prepayment(text, bigint, bigint, date, text, bigint, bigint)

-- DROP FUNCTION public.p_action_stages_form_pp_prepayment(text, bigint, bigint, date, text, bigint, bigint);

CREATE OR REPLACE FUNCTION public.p_action_stages_form_pp_prepayment(
    idlist text,
    uid bigint,
    doctypeid bigint,
    ddate date,
    priority text,
    typicalopersid bigint,
    unit bigint)
  RETURNS text AS
$BODY$
declare
  NUID            BIGINT := UID;
  NID             BIGINT;
  REC             record;
  CH              record;
  NPAYACCOUNTSID  BIGINT;
  NDOCTYPEID      BIGINT;
  NTYPICALOPERSID BIGINT;
  NEXT_NUM        INTEGER;
  spriority		  text;
  nREGIONSRF 	  bigint;
  dBEGINDATETER	  date;
  dENDDATETER	  date;
  nPAYDOCS		  bigint;
begin
   --Найдем тип документа "Платежное поручение"
   NDOCTYPEID := doctypeid;
   --Найдем в типовых операциях "Перечисление на лицевой счет члена избирательной комиссии"
   NTYPICALOPERSID := typicalopersid;
   spriority := priority;

  for REC in (select S.ID,
                     SS.AGENTID,
                     SS.AGENTACCID,
                     C.ELECTCAMPAIGNID,
                     C.JURPERSONSID,
                     SS.DOCNUMB,
                     d2s(SS.DOCDATE) as DOCDATE,
                     COALESCE(S.SETOFFPREPAYMENT, 0) as SUMM,
                     S.BUDGCLASSPREPID,
                     S.ECONCLASSPREPID,
                     S.TYPEEXPPREPID,
                     SS.ntax,
                     S.levelestimate,
                     SS.ID as CONTRACTSDOCS
                from STAGES          S,
                     CONTRACTSDOCS   SS,
                     CONTRACTS       C
               where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                 and SS.ID = S.CONTRACTSDOCSID
                 and C.ID = SS.CONTRACTSID)
  loop
    if nPAYDOCS is null
    then
      --МАЦ-4301 проверка дат
      For ch in
      (select *
         from electcampaign e
        where e.id = REC.ELECTCAMPAIGNID
          and ddate not between e.BEGINDATETER and e.ENDDATETER)
      loop
        dBEGINDATETER := ch.BEGINDATETER;
        dENDDATETER   := ch.ENDDATETER;
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
               values(NUID, P_SYSTEM_GEN_LID('PAYACCOUNTS',nUID,UNIT), REC.JURPERSONSID,REC.ELECTCAMPAIGNID)
               returning PAYACCOUNTS.ID into NPAYACCOUNTSID;
               when too_many_rows then raise using MESSAGE = 'Критическая ошибка, найдено больше записей чем предполагалось. Обратитесь к администратору.';
     end;

     --
     select case
              when EC.LEVELELCAMPAIGN = 'central' then
                (select R.ID from REGIONSRF R where R.IDGASREGIONSRF = '00')
              else
                        ECM.REGIONSRFID
            end
       into nREGIONSRF
       from CONTRACTSDOCS  C,
            CONTRACTS      CR,
            ELECTCAMPAIGN  EC,
            JURPERSONS     JP,
            ELECTCOMMITTEE ECM,
            REGIONSRF      T
      where C.ID = rec.CONTRACTSDOCS
        and CR.ID = C.CONTRACTSID
        and CR.ELECTCAMPAIGNID = EC.ID
        and CR.JURPERSONSID = JP.ID
        and JP.ELECTCOMMITTEEID = ECM.ID
        and ECM.REGIONSRFID = T.ID;

      --Найдем след номер документа
      select coalesce(regexp_replace(max(lpad(docnumb::text,80,' ')), '[^0-9]', '', 'g')::int+1,1) into NEXT_NUM from PAYDOCS where PAYACCOUNTSID = NPAYACCOUNTSID and date_trunc('year', DOCDATE) = date_trunc('year', DDATE);

      --Вставим строку в документ платежного поручения
      insert into PAYDOCS
        (UID, LID, PAYACCOUNTSID, DOCTYPEID, DOCNUMB, DOCDATE, NTAX, AGENTID, AGENTACCID, PURPOSE, PRIORITY, STATUS, begindatetik, enddatetik, electcampaignid)
      values
        (NUID, P_SYSTEM_GEN_LID('PAYDOCS',nUID,UNIT), NPAYACCOUNTSID, NDOCTYPEID, COALESCE(NEXT_NUM,1), DDATE, rec.ntax, REC.AGENTID, REC.AGENTACCID, 'Оплата по контракту ' || REC.DOCNUMB||' от '||REC.DOCDATE, spriority, '0', dBEGINDATETER, dENDDATETER, rec.ELECTCAMPAIGNID)
      returning PAYDOCS.ID into nPAYDOCS;
    end if;
    
    --Добавим строку расшифровки для платежного поручения
    --raise using message = NTYPICALOPERSID;
    select coalesce(regexp_replace(max(lpad(numbpp::text,80,' ')), '[^0-9]', '', 'g')::int+1,1)
      into NEXT_NUM
      from PAYDOCSCONS
     where PAYDOCSID = nPAYDOCS;

    insert into PAYDOCSCONS
      (UID, LID, PAYDOCSID, SUMM, NUMBPP, BUDGCLASSID, ECONCLASSKTID, TYPEEXPID, TYPICALOPERSID, levelestimate/*, regionsrfid, doctypeid*/)
    values
      (nUID, P_SYSTEM_GEN_LID('PAYDOCSCONS',nUID,UNIT), nPAYDOCS, REC.SUMM, NEXT_NUM, REC.BUDGCLASSPREPID, REC.ECONCLASSPREPID, REC.TYPEEXPPREPID, NTYPICALOPERSID, rec.levelestimate/*, nREGIONSRF, NDOCTYPEID*/)
    returning PAYDOCSCONS.ID into NID;
    --Создадим связь
    PERFORM P_SYSTEM_DOCLINKS_ADD('STAGES',REC.ID,'PAYDOCSCONS',NID);
  end loop;

  if NID is not null
  then
    return 'Платежное поручение успешно сформировано.';
  else
    return 'Формирование платежного поручения не выполнено/';
  end if;

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_stages_form_pp_prepayment(text, bigint, bigint, date, text, bigint, bigint)
  OWNER TO magicbox;
