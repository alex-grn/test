CREATE OR REPLACE FUNCTION public.p_action_return_to_statement (
  idlist text,
  uid bigint,
  sure text,
  tablename text
)
RETURNS void AS
$body$
declare 
  nUID bigint:=uid;
  rec  record;
  nID  bigint;
  sTYPEPAYDOC text;
begin
  if sure not ilike 'yes' then return; end if;
  if tablename ilike 'INFOPAYDOC' then
     
     for rec in(
         select d.*
           from INFOPAYDOC d
          where d.id = ANY(p_system_get_selectlist(idlist))
     )
     loop
         if exists (select 1 from FINEPAY f, JOURNALPAYS j where j.infopaydocid = rec.id and f.journalpaysid = j.id) THEN
            raise using message = 'Платеж сквитирован с начислением. Для возврата платежа в выписку необходимо удалить квитовку.';
         end if;
         update STATEMENTADBDONE s set statusdoc = '0' where s.id = rec.STATEMENTADBDONEID;
         delete from JOURNALPAYS j where j.infopaydocid = rec.id;
         delete from DOCLINKS d where d.tableout = 'INFOPAYDOC' and d.keyout = rec.id; 
         delete from INFOPAYDOC f where f.id = rec.id;
         update INFOPAYDOC f set sign_fait = '0' where f.id = rec.id;
         delete from DOCLINKS d where d.tablein = 'STATEMENTADBDONE'
                                  and d.tableout = 'JOURNALPAYS'
                                  and d.keyout in (select j.id from JOURNALPAYS j where j.infopaydocid = rec.id);
       --  perform p_system_doclinks_del('STATEMENTADBDONE',null,'JOURNALPAYS',(select j.id from JOURNALPAYS j where j.infopaydocid = rec.id),false);
     end loop;
     
     
  elsif tablename ilike 'JOURNALPAYS' then 
  
     for rec in(
      select j.*
        from JOURNALPAYS j
       where j.id = ANY(P_SYSTEM_GET_SELECTLIST(idlist))
     )
     loop
         if exists (select 1 from FINEPAY f where f.journalpaysid = rec.id) THEN
            raise using message = 'Платеж сквитирован с начислением. Для возврата платежа в выписку необходимо удалить квитовку.';
         end if;
         delete from JOURNALPAYS j where j.id = rec.id;
         if (select t.typeinfo from INFOPAYDOCDETAIL t where t.id = rec.infopaydocdetailid) = '0' 
              or not exists(select 1 from INFOPAYDOCDETAIL t where t.INFOPAYDOCid = rec.INFOPAYDOCid) then
           update STATEMENTADBDONE s set statusdoc = '0' where s.id = (select f.STATEMENTADBDONEID from infopaydoc f where f.id = rec.infopaydocid);
           delete from JOURNALPAYS j where j.infopaydocid = rec.INFOPAYDOCid;
           delete from INFOPAYDOC f where f.id = rec.INFOPAYDOCid;
           delete from DOCLINKS d where d.tableout = 'INFOPAYDOC' and d.keyout = rec.INFOPAYDOCid; 
         else
           update STATEMENTADBDONE s set statusdoc = '1' where s.id = (select f.STATEMENTADBDONEID from infopaydoc f where f.id = rec.infopaydocid);
           delete from INFOPAYDOCDETAIL t where t.id = rec.infopaydocdetailid;
         end if;
         delete from DOCLINKS d where d.tablein = 'STATEMENTADBDONE'
                                  and d.tableout = 'JOURNALPAYS'
                                  and d.keyout = rec.id;
         --perform p_system_doclinks_del('STATEMENTADBDONE',null,'JOURNALPAYS',rec.id,false);
         update INFOPAYDOC f set sign_fait = '0' where f.id = rec.INFOPAYDOCid;
     end loop;
  
  elsif tablename ilike 'JOURNALNOTIFMBT' then 
    for rec in
         select j.*
           from JOURNALNOTIFMBT j
          where j.id = ANY(P_SYSTEM_GET_SELECTLIST(idlist))
    loop
      delete from JOURNALNOTIFMBT j where j.id = rec.id;
      update STATEMENTADBDONE s set statusdoc = '0' where EXISTS(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'STATEMENTADBDONE'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALNOTIFMBT'
                                                                    and d.keyout = rec.id);
      perform p_system_doclinks_del('STATEMENTADBDONE',null,'JOURNALNOTIFMBT',rec.id);
    end loop;
  elsif tablename ilike 'JOURNALPERSPAY' then 
    for rec in
         select j.*
           from JOURNALPERSPAY j
          where j.id = ANY(P_SYSTEM_GET_SELECTLIST(idlist))
    loop
      delete from JOURNALPERSPAY j where j.id = rec.id;
      update STATEMENTADBDONE s set statusdoc = '0' where EXISTS(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'STATEMENTADBDONE'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALPERSPAY'
                                                                    and d.keyout = rec.id);
      perform p_system_doclinks_del('STATEMENTADBDONE',null,'JOURNALPERSPAY',rec.id);
      update STATEMENTPBSVPKP s set statusdoc = '0' where EXISTS(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'STATEMENTPBSVPKP'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALPERSPAY'
                                                                    and d.keyout = rec.id);
      perform p_system_doclinks_del('STATEMENTPBSVPKP',null,'JOURNALPERSPAY',rec.id);
      update STATEMENTPBSVPPP s set statusdoc = '0' where EXISTS(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'STATEMENTPBSVPPP'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALPERSPAY'
                                                                    and d.keyout = rec.id);
      perform p_system_doclinks_del('STATEMENTPBSVPPP',null,'JOURNALPERSPAY',rec.id);
    end loop;
  elsif tablename ilike 'JOURNALOTHERS' then 
    for rec in
         select j.*
           from JOURNALOTHERS j
          where j.id = ANY(P_SYSTEM_GET_SELECTLIST(idlist))
    loop
      delete from JOURNALOTHERS j where j.id = rec.id;
      update STATEMENTADBDONE s set statusdoc = '0' where EXISTS(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'STATEMENTADBDONE'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALOTHERS'
                                                                    and d.keyout = rec.id);
      perform p_system_doclinks_del('STATEMENTADBDONE',null,'JOURNALOTHERS',rec.id);
      update STATEMENTPBSVPKP s set statusdoc = '0' where EXISTS(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'STATEMENTPBSVPKP'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALOTHERS'
                                                                    and d.keyout = rec.id);
      perform p_system_doclinks_del('STATEMENTPBSVPKP',null,'JOURNALOTHERS',rec.id);
      update STATEMENTPBSVPPP s set statusdoc = '0' where EXISTS(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'STATEMENTPBSVPPP'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALOTHERS'
                                                                    and d.keyout = rec.id);
      perform p_system_doclinks_del('STATEMENTPBSVPPP',null,'JOURNALOTHERS',rec.id);
    end loop;
  end if;
   
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_return_to_statement (idlist text, uid bigint, sure text, tablename text)
  OWNER TO magicbox;