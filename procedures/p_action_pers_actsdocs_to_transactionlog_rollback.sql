-- Function: public.p_action_pers_actsdocs_to_transactionlog_rollback(bigint)

-- DROP FUNCTION public.p_action_pers_actsdocs_to_transactionlog_rollback(bigint);

CREATE OR REPLACE FUNCTION public.p_action_pers_actsdocs_to_transactionlog_rollback(id bigint)
  RETURNS text AS
$BODY$
/*Действие: Отмена проведения документа в учете*/
declare
  nID    BIGINT:=ID;  
  REC    record;
begin
  --Очистим дату оплаты и сменим статус на "В работе"
  update PERS_ACTSDOCS p set STATUS = '1' where p.ID = nID;
  --Удалим записи из журнала операций
  delete from TRANSACTIONLOG_DOCS t 
   where exists(select d.KEYOUT 
                  from DOCLINKS d 
                 where d.TABLEIN ilike 'PERS_ACTSDOCS' 
                   and d.KEYIN = nID 
                   and d.TABLEOUT ilike 'TRANSACTIONLOG_DOCS'
                   and t.ID = d.KEYOUT);
  --Удалим записи из проводки хозяйственной операции
  delete from TRANSACTIONLOG_STAGES t 
   where exists(select d.KEYOUT 
                  from DOCLINKS d 
                 where d.TABLEIN ilike 'PERS_ACTSDOCS' 
                   and d.KEYIN = nID 
                   and d.TABLEOUT ilike 'TRANSACTIONLOG_STAGES'
                   and t.ID = d.KEYOUT);
  --Удалим все связи с журналом операций

  perform p_system_doclinks_del('PERS_ACTSDOCS',nID,'TRANSACTIONLOG',NULL);
  
  /*perform p_system_doclinks_del('PERS_ACTSDOCS',nID,'TRANSACTIONLOG',NULL,false);
  perform p_system_doclinks_del('PERS_ACTSDOCS',nID,'TRANSACTIONLOG_DOCS',NULL,false);
  perform p_system_doclinks_del('PERS_ACTSDOCS',nID,'TRANSACTIONLOG_STAGES',NULL,false);
  for rec in (
      select p.ID
        from PERS_ACTSDOCS sp,
             ACTS p
       where sp.ID = nID
         and p.ID = sp.ACTSID
  )
  loop
       perform p_system_doclinks_del('ACTS',rec.ID,'TRANSACTIONLOG',NULL,false);
       perform p_system_doclinks_del('ACTS',rec.ID,'TRANSACTIONLOG_DOCS',NULL,false);
       perform p_system_doclinks_del('ACTS',rec.ID,'TRANSACTIONLOG_STAGES',NULL,false);
  end loop;
  for rec in (
      select p.ID
        from PERS_ACTSGOODS p
       where p.PERSACTSDOCSID = nID
  )
  loop
       perform p_system_doclinks_del('PERS_ACTSGOODS',rec.ID,'TRANSACTIONLOG',NULL,false);
       perform p_system_doclinks_del('PERS_ACTSGOODS',rec.ID,'TRANSACTIONLOG_DOCS',NULL,false);
       perform p_system_doclinks_del('PERS_ACTSGOODS',rec.ID,'TRANSACTIONLOG_STAGES',NULL,false);
  end loop;*/
  
  return 'Отмена проведения документа в учёте выполнена';
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_pers_actsdocs_to_transactionlog_rollback(bigint)
  OWNER TO magicbox;
