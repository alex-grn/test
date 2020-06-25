﻿-- Function: public.p_action_writeoff_inv_to_transactionlog(bigint, bigint, bigint)

-- DROP FUNCTION public.p_action_writeoff_inv_to_transactionlog(bigint, bigint, bigint);

CREATE OR REPLACE FUNCTION public.p_action_writeoff_inv_to_transactionlog(
    id bigint,
    uid bigint,
    unit bigint)
  RETURNS text AS
$BODY$
declare 
   nID  bigint:=ID;
   nUID bigint:=UID;
   rec  record;
   sp   record;
   nTRANSACTIONLOGID bigint;
   nTRANSACTIONLOG_DOCSID bigint;
   nTRANSACTIONLOG_STAGESID bigint;
   nINVENTORY_TRIAL_BALANCEID bigint;
   nINVENTORY_TRIAL_BALANCEDOCSID bigint;
   nINVENTORY_TRIAL_BALANCE_DICNOMNSID bigint;
   nINVENTORY_TRIAL_BALANCE_CHANGEID bigint;
   next_num text;
begin
    for rec in 
        select a.ELECTCAMPAIGNID,
               a.JURPERSONSID,
               p.DOCTYPEID,
               p.DOCNUMB,
               p.DOCDATE,
               sum(COALESCE(ps.SUMM,0)) as SUMM,
               ps.TYPICALOPERSID,
               count(ps.TYPICALOPERSID) OVER() as count_typ,
               p.RESPPERSON,
               p.recipientrespperson,
               p.ID as WRITEOFF_INVOICE_HEADERID,
               a.ID as WRITEOFFID,
               d.CODE||' № '||p.DOCNUMB||' от '||d2s(p.DOCDATE) as DOCNUMB_C,
               t.name
          from WRITEOFF_INVOICE_HEADER p  
     left join WRITEOFF a on a.id = p.WRITEOFFID
     left join WRITEOFF_INVOICE_GOODS ps on ps.WRITEOFF_INVOICE_HEADERID = p.ID
     left join DOCTYPES d on d.ID = p.DOCTYPEID
     left join TYPICALOPERS t on t.ID = ps.TYPICALOPERSID
         where p.ID = nID
      group by a.ELECTCAMPAIGNID,a.JURPERSONSID,
               p.DOCTYPEID,p.DOCNUMB,p.DOCDATE,
               ps.TYPICALOPERSID,p.RESPPERSON,
               p.ID,a.ID,d.CODE,
               t.name
    LOOP
       update WRITEOFF_INVOICE_HEADER p set status = '2' where p.ID = rec.WRITEOFF_INVOICE_HEADERID;
       if rec.count_typ > 1 then raise using message = 'Для накладной на внутреннее перемещение МЗ указаны разные типовые операции'; end if;
      --найдем заголовок, если нет его, то добавим
       BEGIN
         select t.ID 
           into STRICT nTRANSACTIONLOGID
           from TRANSACTIONLOG t 
          where t.ELECTCAMPAIGNID = rec.ELECTCAMPAIGNID 
            and t.JURPERSONSID = rec.JURPERSONSID;
       exception when no_data_found THEN 
          insert into transactionlog(uid,lid,electcampaignid,jurpersonsid)
                              values(nUID,P_SYSTEM_GEN_LID('TRANSACTIONLOG',nUID,UNIT),rec.ELECTCAMPAIGNID,rec.JURPERSONSID) returning TRANSACTIONLOG.ID into nTRANSACTIONLOGID;
       end;
       --сгенерируем следующий номер
       select (max(t.transactionnumb::integer)+1)::text into next_num from TRANSACTIONLOG_DOCS t where t.transactionlogid = nTRANSACTIONLOGID;
       
       --создаем запись в журнале операций
       insert into TRANSACTIONLOG_DOCS(uid,lid,transactionlogid,transactionnumb,transactiondate,doctypeid,docnumb,docdate,docsum,typicalopersid,tponame)
       values(nUID,P_SYSTEM_GEN_LID('TRANSACTIONLOG_DOCS',nUID,UNIT),nTRANSACTIONLOGID,COALESCE(next_num,'1'),rec.DOCDATE,rec.DOCTYPEID,rec.DOCNUMB,rec.DOCDATE,rec.SUMM,rec.TYPICALOPERSID,rec.name) 
       returning TRANSACTIONLOG_DOCS.ID into nTRANSACTIONLOG_DOCSID;
       
       --ищем или создаем обороты в оборотной ведомости по НФА избирательных кампаний
       BEGIN
         select t.ID 
           into STRICT nINVENTORY_TRIAL_BALANCEID
           from INVENTORY_TRIAL_BALANCE t 
          where t.ELECTCAMPAIGNID = rec.ELECTCAMPAIGNID 
            and t.JURPERSONSID = rec.JURPERSONSID;
       exception when no_data_found THEN 
          insert into INVENTORY_TRIAL_BALANCE(uid,lid,electcampaignid,jurpersonsid)
                              values(nUID,P_SYSTEM_GEN_LID('INVENTORY_TRIAL_BALANCE',nUID,UNIT),rec.ELECTCAMPAIGNID,rec.JURPERSONSID) returning INVENTORY_TRIAL_BALANCE.ID into nINVENTORY_TRIAL_BALANCEID;
       end;
       
      
       for sp in 
           select case when t.ACCOUNTDTID is null and t.typetos = '0' then null else COALESCE(t.DTBUDGCLASSID,p.BUDGCLASSID) end as DTBUDGCLASSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else COALESCE(t.KTBUDGCLASSID,p.BUDGCLASSID) end as KTBUDGCLASSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else COALESCE(k.KTECONCLASSID,t.ECONCLASSKTID,p.ECONCLASSKTID) end as ECONCLASSKTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else COALESCE(d.DTECONCLASSID,t.ECONCLASSDTID,p.ECONCLASSKTID) end as ECONCLASSDTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else p.TYPEEXPID end as DTYPEEXPID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else p.TYPEEXPID end as KTYPEEXPID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else 1 end as dKFO,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else 1 end as kKFO,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else t.ACCOUNTDTID end as ACCOUNTDTID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else t.ACCOUNTKTID end as ACCOUNTKTID,
                  p.SUMM,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else p.DICNOMNSID end AS KTDICNOMNSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else p.QUANTITY end AS KTQUANTITY,
                  --case when t.ACCOUNTKTID is null and t.typetos = '0' then null else p.RESPPERSON end AS KTRESPPERSON,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else p.DICNOMNSID end AS DTDICNOMNSID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else p.QUANTITY end AS DTQUANTITY,
                  --case when t.ACCOUNTDTID is null and t.typetos = '0' then null else p.RESPPERSON end AS DTRESPPERSON,
                  p.ID,
                  t.MEMORDERID,
                  p.LEVELESTIMATE
             from WRITEOFF_INVOICE_GOODS p
             left join TYPICALOPERSPEC t on t.TYPICALOPERSID = p.TYPICALOPERSID
             left join DICACCS d on d.ID = t.ACCOUNTDTID
             left join DICACCS k on k.ID = t.ACCOUNTKTID
            where p.WRITEOFF_INVOICE_HEADERID = nID
       LOOP
           insert into TRANSACTIONLOG_STAGES(uid,lid,transactionlog_docsid,dtfinsecurity,dtbudgclassid,dteconclassktid,dttypeexpid,accountdtid,dtdicnomnsid,dtquantity,dtrespperson,ktfinsecurity,ktbudgclassid,kteconclassktid,kttypeexpid,accountktid,ktrespperson,ktdicnomnsid,ktquantity,summ,memorderid,levelestimate)
             values(nUID,P_SYSTEM_GEN_LID('TRANSACTIONLOG_STAGES',nUID,UNIT),nTRANSACTIONLOG_DOCSID,SP.dKFO,sp.DTBUDGCLASSID,sp.ECONCLASSDTID,sp.DTYPEEXPID,sp.ACCOUNTDTID,sp.DTDICNOMNSID,sp.DTQUANTITY,rec.RESPPERSON,SP.kKFO,sp.KTBUDGCLASSID,sp.ECONCLASSKTID,sp.KTYPEEXPID,sp.ACCOUNTKTID,rec.recipientrespperson,sp.KTDICNOMNSID,sp.KTQUANTITY,sp.SUMM,sp.memorderid,sp.LEVELESTIMATE)
           returning TRANSACTIONLOG_STAGES.ID into nTRANSACTIONLOG_STAGESID;
           --Создаем связи
           perform P_SYSTEM_DOCLINKS_ADD('WRITEOFF_INVOICE_GOODS',sp.ID,'TRANSACTIONLOG_STAGES',nTRANSACTIONLOG_STAGESID);
           /*Заполняем оборотку.*/
           --ищем или создаем оборотные ведомости по НФА
           BEGIN
              select t.ID
                into STRICT nINVENTORY_TRIAL_BALANCEDOCSID
                from INVENTORY_TRIAL_BALANCEDOCS t
               where t.respperson = rec.respperson
                 and t.accountid = sp.ACCOUNTDTID
                 and t.INVENTORY_TRIAL_BALANCEID = nINVENTORY_TRIAL_BALANCEID;
           exception when no_data_found THEN
               insert into INVENTORY_TRIAL_BALANCEDOCS(uid,lid,INVENTORY_TRIAL_BALANCEID,RESPPERSON,ACCOUNTID)
                 values(nUID,P_SYSTEM_GEN_LID('INVENTORY_TRIAL_BALANCEDOCS',nUID,UNIT),nINVENTORY_TRIAL_BALANCEID,rec.RESPPERSON,sp.ACCOUNTDTID)
                 returning INVENTORY_TRIAL_BALANCEDOCS.ID into nINVENTORY_TRIAL_BALANCEDOCSID;
           end;
           
           --ищем или создаем перечень номенклатуры
           BEGIN
             select t.ID
               into STRICT nINVENTORY_TRIAL_BALANCE_DICNOMNSID
               from INVENTORY_TRIAL_BALANCE_DICNOMNS t
              where t.INVENTORY_TRIAL_BALANCEDOCSID = nINVENTORY_TRIAL_BALANCEDOCSID
                and t.DICNOMNSID = COALESCE(sp.KTDICNOMNSID,sp.DTDICNOMNSID);
           exception when no_data_found then
                     insert into INVENTORY_TRIAL_BALANCE_DICNOMNS(uid,lid,INVENTORY_TRIAL_BALANCEDOCSID,DICNOMNSID)
                     values(nUID,P_SYSTEM_GEN_LID('INVENTORY_TRIAL_BALANCE_DICNOMNS',nUID,UNIT),nINVENTORY_TRIAL_BALANCEDOCSID,COALESCE(sp.KTDICNOMNSID,sp.DTDICNOMNSID))
                     returning INVENTORY_TRIAL_BALANCE_DICNOMNS.ID into nINVENTORY_TRIAL_BALANCE_DICNOMNSID;
           end;
           
           --добавляем записи в раздел "Обороты по номенклатуре"
           begin
              select t.ID
                into STRICT nINVENTORY_TRIAL_BALANCE_CHANGEID
                from INVENTORY_TRIAL_BALANCE_CHANGE t
               where t.inventory_trial_balance_dicnomnsid = nINVENTORY_TRIAL_BALANCE_DICNOMNSID
                 and t.docnumb = rec.DOCNUMB_C
                 and t.balancedate = rec.DOCDATE;
           exception when no_data_found then
             insert into INVENTORY_TRIAL_BALANCE_CHANGE(uid,lid,inventory_trial_balance_dicnomnsid,docnumb,balancedate,quantityout,summout)
              values(nUID,P_SYSTEM_GEN_LID('INVENTORY_TRIAL_BALANCE_CHANGE',nUID,UNIT),nINVENTORY_TRIAL_BALANCE_DICNOMNSID,rec.DOCNUMB_C,rec.DOCDATE,0,0)
             RETURNING INVENTORY_TRIAL_BALANCE_CHANGE.ID into nINVENTORY_TRIAL_BALANCE_CHANGEID;
           end;
           update INVENTORY_TRIAL_BALANCE_CHANGE t set quantityout = t.quantityout + COALESCE(sp.DTQUANTITY,sp.KTQUANTITY), summout = t.summout + sp.SUMM where t.ID = nINVENTORY_TRIAL_BALANCE_CHANGEID;
           --Создаем связи
           perform P_SYSTEM_DOCLINKS_ADD('WRITEOFF_INVOICE_GOODS',sp.ID,'INVENTORY_TRIAL_BALANCE_CHANGE',nINVENTORY_TRIAL_BALANCE_CHANGEID);
           
           /*Заполняем оборотку. Для МОЛ*/
           --ищем или создаем оборотные ведомости по НФА
           BEGIN
              select t.ID
                into STRICT nINVENTORY_TRIAL_BALANCEDOCSID
                from INVENTORY_TRIAL_BALANCEDOCS t
               where t.respperson = rec.RECIPIENTRESPPERSON
                 and t.accountid = sp.ACCOUNTKTID
                 and t.INVENTORY_TRIAL_BALANCEID = nINVENTORY_TRIAL_BALANCEID;
           exception when no_data_found THEN
               insert into INVENTORY_TRIAL_BALANCEDOCS(uid,lid,INVENTORY_TRIAL_BALANCEID,RESPPERSON,ACCOUNTID)
                 values(nUID,P_SYSTEM_GEN_LID('INVENTORY_TRIAL_BALANCEDOCS',nUID,UNIT),nINVENTORY_TRIAL_BALANCEID,rec.RECIPIENTRESPPERSON,sp.ACCOUNTKTID)
                 returning INVENTORY_TRIAL_BALANCEDOCS.ID into nINVENTORY_TRIAL_BALANCEDOCSID;
           end;
           
           --ищем или создаем перечень номенклатуры
           BEGIN
             select t.ID
               into STRICT nINVENTORY_TRIAL_BALANCE_DICNOMNSID
               from INVENTORY_TRIAL_BALANCE_DICNOMNS t
              where t.INVENTORY_TRIAL_BALANCEDOCSID = nINVENTORY_TRIAL_BALANCEDOCSID
                and t.DICNOMNSID = COALESCE(sp.KTDICNOMNSID,sp.DTDICNOMNSID);
           exception when no_data_found then
                     insert into INVENTORY_TRIAL_BALANCE_DICNOMNS(uid,lid,INVENTORY_TRIAL_BALANCEDOCSID,DICNOMNSID)
                     values(nUID,P_SYSTEM_GEN_LID('INVENTORY_TRIAL_BALANCE_DICNOMNS',nUID,UNIT),nINVENTORY_TRIAL_BALANCEDOCSID,COALESCE(sp.KTDICNOMNSID,sp.DTDICNOMNSID))
                     returning INVENTORY_TRIAL_BALANCE_DICNOMNS.ID into nINVENTORY_TRIAL_BALANCE_DICNOMNSID;
           end;
           --добавляем записи в раздел "Обороты по номенклатуре"
           begin
              select t.ID
                into STRICT nINVENTORY_TRIAL_BALANCE_CHANGEID
                from INVENTORY_TRIAL_BALANCE_CHANGE t
               where t.inventory_trial_balance_dicnomnsid = nINVENTORY_TRIAL_BALANCE_DICNOMNSID
                 and t.docnumb = rec.DOCNUMB_C
                 and t.balancedate = rec.DOCDATE;
           exception when no_data_found then
             insert into INVENTORY_TRIAL_BALANCE_CHANGE(uid,lid,inventory_trial_balance_dicnomnsid,docnumb,balancedate,quantityin,summin)
              values(nUID,P_SYSTEM_GEN_LID('INVENTORY_TRIAL_BALANCE_CHANGE',nUID,UNIT),nINVENTORY_TRIAL_BALANCE_DICNOMNSID,rec.DOCNUMB_C,rec.DOCDATE,0,0)
             RETURNING INVENTORY_TRIAL_BALANCE_CHANGE.ID into nINVENTORY_TRIAL_BALANCE_CHANGEID;
           end;
           update INVENTORY_TRIAL_BALANCE_CHANGE t set quantityin = t.quantityin + COALESCE(sp.DTQUANTITY,sp.KTQUANTITY), summin = t.summin + sp.SUMM where t.ID = nINVENTORY_TRIAL_BALANCE_CHANGEID;
           --Создаем связи
           perform P_SYSTEM_DOCLINKS_ADD('WRITEOFF_INVOICE_GOODS',sp.ID,'INVENTORY_TRIAL_BALANCE_CHANGE',nINVENTORY_TRIAL_BALANCE_CHANGEID);
       end loop; 
       
    END LOOP; 
    return 'Документ проведён в учёте';  
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_writeoff_inv_to_transactionlog(bigint, bigint, bigint)
  OWNER TO magicbox;
