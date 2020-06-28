-- Function: public.p_action_expense_docs_to_transactionlog_rollback(bigint)

-- DROP FUNCTION public.p_action_expense_docs_to_transactionlog_rollback(bigint);

CREATE OR REPLACE FUNCTION public.p_action_expense_docs_to_transactionlog_rollback(id bigint)
  RETURNS text AS
$BODY$
/*Действие: Отмена проведения документа в учете*/
declare
  nID    BIGINT:=ID;  
  REC    record;
begin
  --Очистим дату оплаты и сменим статус на "В работе"
  update EXPENSE_DOCS p set STATUS = '0' where p.ID = nID;
  --Удалим записи из журнала операций
  delete from TRANSACTIONLOG_DOCS t 
   where exists(select d.KEYOUT 
                  from DOCLINKS d 
                 where d.TABLEIN ilike 'EXPENSE_DOCS' 
                   and d.KEYIN = nID 
                   and d.TABLEOUT ilike 'TRANSACTIONLOG_DOCS'
                   and t.ID = d.KEYOUT);
  --Удалим записи из проводки хозяйственной операции
  delete from TRANSACTIONLOG_STAGES t 
   where exists(select d.KEYOUT 
                  from DOCLINKS d 
                 where d.TABLEIN ilike 'EXPENSE_DOCS' 
                   and d.KEYIN = nID 
                   and d.TABLEOUT ilike 'TRANSACTIONLOG_STAGES'
                   and t.ID = d.KEYOUT);
  --Удалим все связи с журналом операций
  
  perform p_system_doclinks_del('EXPENSE_DOCS',nID,'TRANSACTIONLOG',NULL);
  
  /*perform p_system_doclinks_del('EXPENSE_DOCS',nID,'TRANSACTIONLOG',NULL,false);
  perform p_system_doclinks_del('EXPENSE_DOCS',nID,'TRANSACTIONLOG_DOCS',NULL,false);
  perform p_system_doclinks_del('EXPENSE_DOCS',nID,'TRANSACTIONLOG_STAGES',NULL,false);
  for rec in 
      select p.ID
        from EXPENSE_DOCS sp,
             EXPENSE_REPORTS p
       where sp.ID = nID
         and p.ID = sp.EXPENSEREPORTSID
  loop
       perform p_system_doclinks_del('EXPENSE_REPORTS',rec.ID,'TRANSACTIONLOG',NULL,false);
       perform p_system_doclinks_del('EXPENSE_REPORTS',rec.ID,'TRANSACTIONLOG_DOCS',NULL,false);
       perform p_system_doclinks_del('EXPENSE_REPORTS',rec.ID,'TRANSACTIONLOG_STAGES',NULL,false);
  end loop;
  for rec in 
      select p.ID
        from EXPENDED p
       where p.EXPENSE_DOCS_ID = nID
  loop
       perform p_system_doclinks_del('EXPENDED',rec.ID,'TRANSACTIONLOG',NULL,false);
       perform p_system_doclinks_del('EXPENDED',rec.ID,'TRANSACTIONLOG_DOCS',NULL,false);
       perform p_system_doclinks_del('EXPENDED',rec.ID,'TRANSACTIONLOG_STAGES',NULL,false);
  end loop;*/
  
  return 'Отмена проведения документа в учёте выполнена';
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_expense_docs_to_transactionlog_rollback(bigint)
  OWNER TO magicbox;
