-- Function: public.p_action_actsdocs_to_transactionlog(bigint, bigint, bigint)

-- DROP FUNCTION public.p_action_actsdocs_to_transactionlog(bigint, bigint, bigint);

CREATE OR REPLACE FUNCTION public.p_action_actsdocs_to_transactionlog(
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
   next_num text;
   fl       boolean;
   --определим уровни доступа
   nLID_TRANSACTIONLOG        bigint:=P_SYSTEM_GEN_LID('TRANSACTIONLOG',nUID,UNIT);
   nLID_TRANSACTIONLOG_DOCS   bigint:=P_SYSTEM_GEN_LID('TRANSACTIONLOG_DOCS',nUID,UNIT);
   nLID_TRANSACTIONLOG_STAGES bigint:=P_SYSTEM_GEN_LID('TRANSACTIONLOG_STAGES',nUID,UNIT);
begin
    for rec in 
        select a.ELECTCAMPAIGNID,
               a.JURPERSONSID,
               p.DOCDATE,
               p.DOCTYPEID,
               p.DOCNUMBIN,
               p.DOCDATEIN,
               sum(COALESCE(ps.SUMM,0)) as SUMM,
               ps.TYPICALOPERSID,
               count(ps.TYPICALOPERSID) OVER() as count_typ,
               c.AGENTID,
               p.ID as ACTSDOCSID,
               a.ID as ACTSID,
               t.name as TYPENAME
          from ACTSDOCS p, 
               ACTS a,
               ACTSGOODS ps,
               CONTRACTSDOCS c,
               TYPICALOPERS t
         where p.id = nID 
           and a.id = p.ACTSID
           and ps.ACTSDOCSID = p.ID
           and c.ID = p.CONTRACTSDOCSID
           and t.ID = ps.TYPICALOPERSID
      group by a.ELECTCAMPAIGNID, a.JURPERSONSID, p.DOCDATE,
               p.DOCTYPEID, p.DOCNUMBIN, p.DOCDATEIN,
               ps.TYPICALOPERSID, c.AGENTID, p.ID, a.ID, t.name
    LOOP
       fl:=false;
       update ACTSDOCS p set status = '2' where p.ID = rec.ACTSDOCSID;
       if rec.count_typ > 1 then raise using message = 'Для акта указаны разные типовые операции'; end if;
      --найдем заголовок, если нет его, то добавим
       BEGIN
         select t.ID 
           into STRICT nTRANSACTIONLOGID
           from TRANSACTIONLOG t 
          where t.ELECTCAMPAIGNID = rec.ELECTCAMPAIGNID 
            and t.JURPERSONSID = rec.JURPERSONSID;
       exception when no_data_found THEN 
          insert into transactionlog(uid,lid,electcampaignid,jurpersonsid)
                              values(nUID,nLID_TRANSACTIONLOG,rec.ELECTCAMPAIGNID,rec.JURPERSONSID) returning TRANSACTIONLOG.ID into nTRANSACTIONLOGID;
       end;
       
       --сгенерируем следующий номер
       select coalesce(regexp_replace(max(lpad(TRANSACTIONNUMB::text,80,' ')), '[^0-9]', '', 'g')::int+1,1) into next_num from TRANSACTIONLOG_DOCS where TRANSACTIONLOGID = nTRANSACTIONLOGID;
       
       --создаем запись в журнале операций
       insert into TRANSACTIONLOG_DOCS(uid,lid,transactionlogid,transactionnumb,transactiondate,doctypeid,docnumb,docdate,docsum,typicalopersid,tponame)
       values(nUID,nLID_TRANSACTIONLOG_DOCS,nTRANSACTIONLOGID,COALESCE(next_num,'1'),rec.DOCDATE,rec.DOCTYPEID,rec.DOCNUMBIN,rec.DOCDATEIN,rec.SUMM,rec.TYPICALOPERSID,rec.TYPENAME) 
       returning TRANSACTIONLOG_DOCS.ID into nTRANSACTIONLOG_DOCSID;
       
       
       for sp in (
           select case when t.ACCOUNTDTID is null and t.typetos = '0' then null else COALESCE(t.DTBUDGCLASSID,p.BUDGCLASSID) end as DTBUDGCLASSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else COALESCE(t.KTBUDGCLASSID,p.BUDGCLASSID) end as KTBUDGCLASSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else COALESCE(k.DTECONCLASSID,t.ECONCLASSKTID,p.ECONCLASSKTID) end as ECONCLASSKTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else COALESCE(d.KTECONCLASSID,t.ECONCLASSDTID,p.ECONCLASSKTID) end as ECONCLASSDTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else p.TYPEEXPID end as DTYPEEXPID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else p.TYPEEXPID end as KTYPEEXPID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else t.ACCOUNTDTID end as ACCOUNTDTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else 1 end as dKFO,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else 1 end as kKFO,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else rec.AGENTID end as AGENTID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else t.ACCOUNTKTID end as ACCOUNTKTID,
                  p.SUMM,
                  p.ID,
                  t.MEMORDERID,
                  p.LEVELESTIMATE
             from ACTSGOODS p
             left join TYPICALOPERSPEC t on t.TYPICALOPERSID = p.TYPICALOPERSID
             left join DICACCS d on d.ID = t.ACCOUNTDTID 
             left join DICACCS k on k.ID = t.ACCOUNTKTID
            where p.ACTSDOCSID = nID
       )
       LOOP
           insert into TRANSACTIONLOG_STAGES(uid,lid,transactionlog_docsid,dtfinsecurity,dtbudgclassid,dteconclassktid,dttypeexpid,accountdtid,agentktid,ktfinsecurity,ktbudgclassid,kteconclassktid,kttypeexpid,accountktid,summ,memorderid,levelestimate)
             values(nUID,nLID_TRANSACTIONLOG_STAGES,nTRANSACTIONLOG_DOCSID,sp.dKFO,sp.DTBUDGCLASSID,sp.ECONCLASSDTID,sp.DTYPEEXPID,sp.ACCOUNTDTID,sp.AGENTID,sp.kKFO,sp.KTBUDGCLASSID,sp.ECONCLASSKTID,sp.KTYPEEXPID,sp.ACCOUNTKTID,sp.SUMM,sp.memorderid,sp.LEVELESTIMATE)
           returning TRANSACTIONLOG_STAGES.ID into nTRANSACTIONLOG_STAGESID;
           perform p_system_doclinks_add('ACTSGOODS',sp.ID,'TRANSACTIONLOG_STAGES',nTRANSACTIONLOG_STAGESID);
           
       end loop; 
       
       --зачет аванса
       for sp in 
           select case when t.ACCOUNTDTID is null and t.typetos = '0' then null else COALESCE(t.DTBUDGCLASSID,p.BUDGCLASSID) end as DTBUDGCLASSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else COALESCE(t.KTBUDGCLASSID,p.BUDGCLASSID) end as KTBUDGCLASSID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else COALESCE(k.DTECONCLASSID,t.ECONCLASSKTID,p.ECONCLASSKTID) end as ECONCLASSKTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else COALESCE(d.KTECONCLASSID,t.ECONCLASSDTID,p.ECONCLASSKTID) end as ECONCLASSDTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else p.TYPEEXPID end as DTYPEEXPID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else p.TYPEEXPID end as KTYPEEXPID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else t.ACCOUNTDTID end as ACCOUNTDTID,
                  case when t.ACCOUNTDTID is null and t.typetos = '0' then null else 1 end as dKFO,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else 1 end as kKFO,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else rec.AGENTID end as AGENTID,
                  case when t.ACCOUNTKTID is null and t.typetos = '0' then null else t.ACCOUNTKTID end as ACCOUNTKTID,
                  p.SETOFFPREPAYMENT as summ,
                  p.ID,
                  t.MEMORDERID
             from ACTSDOCS p
             left join TYPICALOPERSPEC t on t.TYPICALOPERSID = p.TYPICALOPERSID
             left join DICACCS d on d.ID = t.ACCOUNTDTID 
             left join DICACCS k on k.ID = t.ACCOUNTKTID
            where p.ID = nID
              and p.SUPEXPENSE 
       loop
          insert into TRANSACTIONLOG_STAGES(uid,lid,transactionlog_docsid,dtfinsecurity,dtbudgclassid,dteconclassktid,dttypeexpid,accountdtid,agentdtid,ktfinsecurity,ktbudgclassid,kteconclassktid,kttypeexpid,accountktid,agentktid,summ,memorderid)
                values(nUID,nLID_TRANSACTIONLOG_STAGES,nTRANSACTIONLOG_DOCSID,sp.dKFO,sp.DTBUDGCLASSID,sp.ECONCLASSDTID,sp.DTYPEEXPID,sp.ACCOUNTDTID,sp.AGENTID,sp.kKFO,sp.KTBUDGCLASSID,sp.ECONCLASSKTID,sp.KTYPEEXPID,sp.ACCOUNTKTID,sp.AGENTID,sp.SUMM,sp.MEMORDERID)
          returning TRANSACTIONLOG_STAGES.ID into nTRANSACTIONLOG_STAGESID;
          --Создаем связи
          perform p_system_doclinks_add('ACTSDOCS',nID,'TRANSACTIONLOG_STAGES',nTRANSACTIONLOG_STAGESID);
       end loop;    
       
    END LOOP; 
    return 'Документ проведён в учёте';  
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_actsdocs_to_transactionlog(bigint, bigint, bigint)
  OWNER TO magicbox;
