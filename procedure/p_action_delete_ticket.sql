CREATE OR REPLACE FUNCTION public.p_action_delete_ticket (
  idlist text,
  tablename text
)
RETURNS void AS
$body$
declare
  REC record;
begin
  for REC in execute 'select * from ' || TABLENAME || ' where id = any(p_system_get_selectlist(''' || IDLIST || '''))'
  loop
    if TABLENAME ILIKE 'FINEPAY' then
      delete from FINEPAY F where F.ID = REC.ID;
      PERFORM P_SYSTEM_DOCLINKS_DEL('JOURNALPAYS', REC.JOURNALPAYSID, 'FINEPAY', REC.ID,false);
      PERFORM P_SYSTEM_DOCLINKS_DEL('JOURNALPAYS', REC.JOURNALPAYSID, 'FINE', REC.FINEID,false);
      update JOURNALPAYS J set SIGN_FAIT = '3' where J.ID = REC.JOURNALPAYSID;
      update STATEMENTADBDONE s set STATUSDOC = '1' where exists(select 1
                                                                   from doclinks d 
                                                                  where d.tablein ~~* 'STATEMENTADBDONE'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALPAYS'
                                                                    and d.keyout = REC.JOURNALPAYSID)
                                                  and not exists(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'JOURNALPAYS'
                                                                    and d.keyin = s.id
                                                                    and upper(d.tableout) in ('REFIREQ','RETURNREQ','REFINENOTIF')
                                                                    and d.keyout = REC.JOURNALPAYSID);
    elsif TABLENAME ILIKE 'JOURNALPAYS' then
      delete from FINEPAY F where F.JOURNALPAYSID = REC.ID;
      PERFORM P_SYSTEM_DOCLINKS_DEL('JOURNALPAYS', REC.ID, 'FINEPAY', (SELECT F.ID FROM FINEPAY F WHERE F.JOURNALPAYSID = REC.ID),false);
      PERFORM P_SYSTEM_DOCLINKS_DEL('JOURNALPAYS', REC.ID, 'FINE', (SELECT F.FINEID FROM FINEPAY F WHERE F.JOURNALPAYSID = REC.ID),false);
      update JOURNALPAYS J set SIGN_FAIT = '3' where J.ID = REC.ID;
      update STATEMENTADBDONE s set STATUSDOC = '1' where exists(select 1
                                                                   from doclinks d 
                                                                  where d.tablein ~~* 'STATEMENTADBDONE'
                                                                    and d.keyin = s.id
                                                                    and d.tableout ~~* 'JOURNALPAYS'
                                                                    and d.keyout = rec.ID)
                                                  and not exists(select 1
                                                                   from doclinks d
                                                                  where d.tablein ~~* 'JOURNALPAYS'
                                                                    and d.keyin = s.id
                                                                    and upper(d.tableout) in ('REFIREQ','RETURNREQ','REFINENOTIF')
                                                                    and d.keyout = REC.JOURNALPAYSID);
    end if;
  end loop;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_delete_ticket (idlist text, tablename text)
  OWNER TO magicbox;