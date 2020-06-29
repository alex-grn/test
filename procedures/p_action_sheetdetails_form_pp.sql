-- Function: public.p_action_sheetdetails_form_pp(text, bigint, date, bigint, bigint)

-- DROP FUNCTION public.p_action_sheetdetails_form_pp(text, bigint, date, bigint, bigint);

CREATE OR REPLACE FUNCTION public.p_action_sheetdetails_form_pp(
    idlist text,
    uid bigint,
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
  NPAYACCOUNTSID  BIGINT;
  NDOCTYPEID      BIGINT;
  NBUDGCLASSID    BIGINT := BUDGCLASSID;
  NECONCLASSKTID  BIGINT := ECONCLASSKTID;
  NTYPICALOPERSID BIGINT;
  NEXT_NUM        INTEGER;
  NPAYDOCSCONS	  BIGINT;
begin

  --Найдем тип документа "Платежное поручение"
  select D.ID into NDOCTYPEID from DOCTYPES D where D.CODE ILIKE '%плат_жное%';
  --Найдем в типовых операциях "Перечисление на лицевой счет члена избирательной комиссии"
  select T.ID into NTYPICALOPERSID from TYPICALOPERS T where T.CODE ILIKE '%Перечисление на лицевой сч_т физ%';

  for REC in (select S.ID,
                     S.TRPERSONID,
                     S.PERSONACCID,
                     SS.ELECTCAMPAIGNID,
                     case lower(k.levelelcommittee)
                      when 'district' then (select i.id from ELECTCOMMITTEE i where i.idgasecom = k.idgasparecom)
                      else k.id
                     end as ELECTCOMMITTEEID,
                  --   E.ELECTCOMMITTEEID,
                     COALESCE(P.RODSURNAME, '') || ' ' || COALESCE(P.RODFIRSTNAME, '') || ' ' || COALESCE(P.RODMIDDLENAME, '') as FIO,
                     COALESCE(S.SUMCOMP, 0) + COALESCE(S.SUMEXTRA12, 0) + COALESCE(S.EXTRAA, 0) as SUMM,
                     sS.LEVELESTIMATE,
                     sS.TYPEEXPID
                from SHEETDETAILS    S,
                     SHEETS          SS,
                     ELECTCOMMINCAMP E,
                     PERSON          P,
                     ELECTCOMMITTEE  k
               where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                 and SS.ID = S.SHEETSID
                 and E.ID = SS.ELECTCOMMINCAMPID
                 and P.ID = S.TRPERSONID
                 and k.ID = e.ELECTCOMMITTEEID)
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
      from PAYACCOUNTS P,
           JURPERSONS  J
     where J.ID = P.JURPERSONSID
       and J.ELECTCOMMITTEEID = REC.ELECTCOMMITTEEID
       and P.ELECTCAMPAIGNID = REC.ELECTCAMPAIGNID;
   exception when no_data_found then
             insert into PAYACCOUNTS(uid, lid, JURPERSONSID, ELECTCAMPAIGNID)
             values(NUID, P_SYSTEM_GEN_LID('PAYACCOUNTS',nUID),(select t.id from JURPERSONS t where t.ELECTCOMMITTEEID = REC.ELECTCOMMITTEEID),REC.ELECTCAMPAIGNID)
             returning PAYACCOUNTS.ID into NPAYACCOUNTSID;
   /*
   ПП не создается. Также необходимо при поиске в таблице PAYACCOUNTS для ТИК - искать ID ТИКа в JURPERSONS,
   для УИК  - искать ID ТИКа, к которому принадлежит УИК в JURPERSONS.  В случае отсутсвия записи в таблице PAYACCOUNTS  - создать
   */
             when too_many_rows then raise using MESSAGE = 'Критическая ошибка, найдено больше записей чем предполагалось. Обратитесь к администратору.';
   end;

    --Найдем след номер документа
    select coalesce(regexp_replace(max(lpad(docnumb::text,80,' ')), '[^0-9]', '', 'g')::int+1,1) into NEXT_NUM from PAYDOCS where PAYACCOUNTSID = NPAYACCOUNTSID and date_trunc('year', DOCDATE) = date_trunc('year', DDATE);
    --Вставим строку в документ платежного поручения
    insert into PAYDOCS
      (UID, LID, PAYACCOUNTSID, DOCTYPEID, DOCNUMB, DOCDATE, NTAX, PERSONID, PERSONACCDOCID, PURPOSE, PRIORITY, STATUS)
    values
      (NUID, P_SYSTEM_GEN_LID('PAYDOCS',nUID), NPAYACCOUNTSID, NDOCTYPEID, COALESCE(NEXT_NUM,1), DDATE, '0', REC.TRPERSONID, REC.PERSONACCID, 'Оплата труда ' || REC.FIO, '1', '0')
    returning PAYDOCS.ID into NID;

    --Добавим строку расшифровки для платежного поручения
    insert into PAYDOCSCONS (UID, LID, PAYDOCSID, SUMM, NUMBPP, BUDGCLASSID, ECONCLASSKTID, TYPICALOPERSID, LEVELESTIMATE, TYPEEXPID)
     values (nUID, P_SYSTEM_GEN_LID('PAYDOCSCONS',nUID), NID, REC.SUMM, 1, NBUDGCLASSID, NECONCLASSKTID, NTYPICALOPERSID, rec.LEVELESTIMATE, rec.TYPEEXPID)
     returning ID into NPAYDOCSCONS;
    update SHEETDETAILS S set PAYDOCSID = NID where S.ID = REC.ID;

    -- установим линк
    PERFORM P_SYSTEM_DOCLINKS_ADD('SHEETDETAILS', REC.ID, 'PAYDOCSCONS', NPAYDOCSCONS);
  end loop;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_sheetdetails_form_pp(text, bigint, date, bigint, bigint)
  OWNER TO magicbox;
