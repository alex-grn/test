﻿-- Function: public.p_action_stages_create_inv(text, bigint, bigint, date, text, date, bigint, bigint)

-- DROP FUNCTION public.p_action_stages_create_inv(text, bigint, bigint, date, text, date, bigint, bigint);

CREATE OR REPLACE FUNCTION public.p_action_stages_create_inv(
    idlist text,
    uid bigint,
    doctypeid bigint,
    ddate date,
    sdocnumbin text,
    ddocdatein date,
    respperson bigint,
    typicalopersid bigint)
  RETURNS text AS
$BODY$
declare
  NUID                 BIGINT := UID;
  NID                  BIGINT;
  REC                  record;
  NLID_INVENTORY       BIGINT;
  NLID_INVENTORY_DOCS  BIGINT;
  NLID_INVENTORY_GOODS BIGINT;
  NINVENTORYID     	   BIGINT;
  NDOCTYPEID       	   BIGINT;
  nRESPPERSON	   	   bigint;
  NTYPICALOPERSID  	   BIGINT;
  NEXT_NUM         	   INTEGER;
  dbegindateter    	   electcampaign.begindateter%type;
  denddateter          electcampaign.enddateter%type;
  nREGIONSRF		   REGIONSRF.id%type;
  nINVENTORY_DOCS	   bigint;
begin
  -- Тип документа
  NDOCTYPEID      := doctypeid;
  nRESPPERSON     := RESPPERSON;
  NTYPICALOPERSID := typicalopersid;

  -- определение прав
  NLID_INVENTORY       := P_SYSTEM_GEN_LID('INVENTORY', NUID);
  NLID_INVENTORY_DOCS  := P_SYSTEM_GEN_LID('INVENTORY_DOCS', NUID);
  NLID_INVENTORY_GOODS := P_SYSTEM_GEN_LID('INVENTORY_GOODS', NUID);

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
                     S.TYPEEXPID,
                     ss.contrtype,
                     s.contractsdocsid,
                     s.quantity,
                     s.supexpense,
                     s.setoffprepayment,
                     s.budgclassprepid,
                     s.econclassktid,
                     s.typeexpprepid,
                     s.LEVELESTIMATE
                from STAGES          S,
                     CONTRACTSDOCS   SS,
                     CONTRACTS       C
               where 1=1
                 and S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                 and SS.ID = S.CONTRACTSDOCSID
                 and C.ID = SS.CONTRACTSID
                 and s.actsexp = false)
  loop
    -- только на поставку товаров
    if rec.contrtype <> 'product'
    then
      raise using message = 'Формирование Товарной накладной возможно только для договаров с типом "Поставка товара"!'||rec.contrtype;
    end if;
	if nINVENTORY_DOCS is null
    then
      -- Найдем Поступление МЗ избирательных кампаний
      begin
       select i.id
         into STRICT NINVENTORYID
         from inventory i
        where I.JURPERSONSID = REC.JURPERSONSID
          and I.ELECTCAMPAIGNID = REC.ELECTCAMPAIGNID;
      exception
        when no_data_found then
          insert into inventory(lid, uid, electcampaignid, jurpersonsid)
          values(NLID_INVENTORY, NUID, REC.ELECTCAMPAIGNID, REC.JURPERSONSID)
          returning ID into NINVENTORYID;
        when too_many_rows then
          raise using MESSAGE = 'Определено больше одной записи документа "Поступление МЗ"!.';
      end;

      -- определение периода
      select e.begindateter,
             e.enddateter
        into dbegindateter,
             denddateter
        from electcampaign e,
             INVENTORY     c
       where e.id = c.ELECTCAMPAIGNID
         and c.id= NINVENTORYID;

      -- определение региона
      select case
               when EC.LEVELELCAMPAIGN = 'central' then
                 (select R.ID from REGIONSRF R where R.IDGASREGIONSRF = '00')
               else
                 ECM.REGIONSRFID
             end
        into nREGIONSRF
        from INVENTORY      CR,
             ELECTCAMPAIGN  EC,
             JURPERSONS     JP,
             ELECTCOMMITTEE ECM,
             REGIONSRF      T
       where CR.ID = NINVENTORYID
         and CR.ELECTCAMPAIGNID = EC.ID
         and CR.JURPERSONSID = JP.ID
         and JP.ELECTCOMMITTEEID = ECM.ID
         and ECM.REGIONSRFID = T.ID;
  --raise using message = nREGIONSRF;

      if DDATE not between dbegindateter and denddateter then
        raise using message = 'Дата документа "'|| d2s(DDATE) ||'" должна быть в периоде работы ТИК, с "'||d2s(dbegindateter)||'" по "'||d2s(denddateter)||'"!';
      end if;

      -- Найдем след номер документа
      select coalesce(regexp_replace(max(lpad(NUMBPP::text,80,' ')), '[^0-9]', '', 'g')::int+1,1)
        into NEXT_NUM
        from INVENTORY_DOCS
       where INVENTORYID = NINVENTORYID
         and cid = 0
         and date_trunc('year', DOCDATE) = date_trunc('year', ddate);

      -- Вставим строку
      if rec.supexpense then
        insert into INVENTORY_DOCS(lid, uid, inventoryid, doctypeid, numbpp, docdate, supexpense, contractsdocsid, respperson, docdatein, docnumbin, enddatetik, begindatetik, status, --REGIONSRFID,
        setoffprepayment,
        budgclassid,
        econclassktid,
        typeexpid)
        values
          (NLID_INVENTORY_DOCS,NUID,NINVENTORYID,NDOCTYPEID,NEXT_NUM,DDATE,true,rec.contractsdocsid,nrespperson,ddocdatein,sdocnumbin,denddateter,dbegindateter, '1', --nREGIONSRF,
          rec.setoffprepayment,
          rec.budgclassprepid,
          rec.econclassktid,
          rec.typeexpprepid)
        returning ID into nINVENTORY_DOCS;
      else
        insert into INVENTORY_DOCS(lid, uid, inventoryid, doctypeid, numbpp, docdate, supexpense, contractsdocsid, respperson, docdatein, docnumbin, enddatetik, begindatetik, status/*, REGIONSRFID*/)
        values
          (NLID_INVENTORY_DOCS,NUID,NINVENTORYID,NDOCTYPEID,NEXT_NUM,DDATE,false,rec.contractsdocsid,nrespperson,ddocdatein,sdocnumbin,denddateter,dbegindateter, '1'/*, nREGIONSRF*/)
        returning ID into nINVENTORY_DOCS;
      end if;
    end if;
    -- номер пп
    select coalesce(regexp_replace(max(lpad(numbpp::text,80,' ')), '[^0-9]', '', 'g')::int+1,1)
      into NEXT_NUM
      from INVENTORY_GOODS
     where INVENTORY_DOCSID = nINVENTORY_DOCS
       and cid = 0;

    -- Добавим строку
    insert into INVENTORY_GOODS(lid,  uid, inventory_docsid, numbpp, stagesid, quantity, summ, budgclassid, econclassktid, typeexpid, typicalopersid, LEVELESTIMATE/*, doctypeid, REGIONSRFID*/)
    values (nlid_INVENTORY_GOODS, nUID, nINVENTORY_DOCS, NEXT_NUM, rec.id, rec.quantity, rec.summ, rec.budgclassid, rec.econclassktid, rec.typeexpid, NTYPICALOPERSID, rec.LEVELESTIMATE/*, NDOCTYPEID, nREGIONSRF*/)
    returning ID into NID;

    update stages su set ACTSEXP = true where su.id = rec.id;

    -- Создадим связь
    PERFORM P_SYSTEM_DOCLINKS_ADD('STAGES', REC.ID, 'INVENTORY_GOODS', NID);
  end loop;
  if NID is not null
  then
    return 'Товарная накладная успешно сформирована.';
  else
    return 'Формирование товарной накладной не выполнено.';
  end if;

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_stages_create_inv(text, bigint, bigint, date, text, date, bigint, bigint)
  OWNER TO magicbox;
