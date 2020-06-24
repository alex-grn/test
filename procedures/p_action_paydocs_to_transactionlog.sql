-- Function: public.p_action_paydocs_to_transactionlog(bigint, bigint, date, bigint)

-- DROP FUNCTION public.p_action_paydocs_to_transactionlog(bigint, bigint, date, bigint);

CREATE OR REPLACE FUNCTION public.p_action_paydocs_to_transactionlog(
    id bigint,
    uid bigint,
    ddocdate date,
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
               p.AGENTID,
               p.PERSONID,
               p.ID as PAYDOCSID,
               a.ID as PAYACCOUNTSID,
               t.name as TYPENAME
          from PAYDOCS p, 
               PAYACCOUNTS a,
               PAYDOCSCONS ps,
               TYPICALOPERS t
         where p.id = nID 
           and a.id = p.PAYACCOUNTSID
           and ps.PAYDOCSID = p.ID
           and t.ID = ps.TYPICALOPERSID
      group by a.ELECTCAMPAIGNID, a.JURPERSONSID,
               p.DOCTYPEID, p.DOCNUMB, p.DOCDATE,
               ps.TYPICALOPERSID, p.AGENTID, p.PERSONID,
               p.ID, a.ID,t.name
    LOOP
       update PAYDOCS p set status = '2', paydate = DDOCDATE where p.ID = rec.PAYDOCSID;
       if rec.count_typ > 1 then raise using message = 'Для платежного поручения указаны разные типовые операции в спецификации документа'; end if;
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
       values(nUID,P_SYSTEM_GEN_LID('TRANSACTIONLOG_DOCS',nUID,UNIT),nTRANSACTIONLOGID,COALESCE(next_num,'1'),DDOCDATE,rec.DOCTYPEID,rec.DOCNUMB,rec.DOCDATE,rec.SUMM,rec.TYPICALOPERSID,rec.TYPENAME) 
       returning TRANSACTIONLOG_DOCS.ID into nTRANSACTIONLOG_DOCSID;
       
       for sp in (
           select case when t.ACCOUNTDTID is null and t.typetos = '0' then null else COALESCE(t.DTBUDGCLASSID,p.BUDGCLASSID) end as DTBUDGCLASSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else COALESCE(t.KTBUDGCLASSID,p.BUDGCLASSID) end as KTBUDGCLASSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else COALESCE(k.KTECONCLASSID,t.ECONCLASSKTID,p.ECONCLASSKTID) end as ECONCLASSKTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else COALESCE(d.DTECONCLASSID,t.ECONCLASSDTID,p.ECONCLASSKTID) end as ECONCLASSDTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else p.TYPEEXPID end as DTYPEEXPID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else p.TYPEEXPID end as KTYPEEXPID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else t.ACCOUNTDTID end as ACCOUNTDTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else 1 end as dKFO,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else 1 end as kKFO,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else case d.ACCTYPE when '7' then rec.AGENTID end end as AGENTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else case d.ACCTYPE when '7' then rec.PERSONID end end as PERSONID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else t.ACCOUNTKTID end as ACCOUNTKTID,
                  p.SUMM,
                  p.ID,
                  t.MEMORDERID,
                  p.LEVELESTIMATE
             from PAYDOCSCONS p
             left join TYPICALOPERSPEC t on t.TYPICALOPERSID = p.TYPICALOPERSID
             left join DICACCS d on d.ID = t.ACCOUNTDTID 
             left join DICACCS k on k.ID = t.ACCOUNTKTID
            where p.PAYDOCSID = nID
       )
       LOOP
           insert into TRANSACTIONLOG_STAGES(uid,lid,transactionlog_docsid,dtfinsecurity,dtbudgclassid,dteconclassktid,dttypeexpid,accountdtid,agentdtid,persondtid,ktfinsecurity,ktbudgclassid,kteconclassktid,kttypeexpid,accountktid,summ,memorderid,levelestimate)
             values(nUID,P_SYSTEM_GEN_LID('TRANSACTIONLOG_STAGES',nUID,UNIT),nTRANSACTIONLOG_DOCSID,sp.dKFO,sp.DTBUDGCLASSID,sp.ECONCLASSDTID,sp.DTYPEEXPID,sp.ACCOUNTDTID,sp.AGENTID,sp.PERSONID,sp.kKFO,sp.KTBUDGCLASSID,sp.ECONCLASSKTID,sp.KTYPEEXPID,sp.ACCOUNTKTID,sp.SUMM,sp.memorderid,sp.LEVELESTIMATE)
           returning TRANSACTIONLOG_STAGES.ID into nTRANSACTIONLOG_STAGESID;
           perform p_system_doclinks_add('PAYDOCSCONS',sp.ID,'TRANSACTIONLOG_STAGES',nTRANSACTIONLOG_STAGESID);
       end loop; 
       
    END LOOP; 
    return 'Документ проведён в учёте';  
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_paydocs_to_transactionlog(bigint, bigint, date, bigint)
  OWNER TO magicbox;
