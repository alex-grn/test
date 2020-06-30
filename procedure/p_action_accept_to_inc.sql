CREATE OR REPLACE FUNCTION public.p_action_accept_to_inc (
  idlist text
)
RETURNS void AS
$body$
declare
  REC    record;
  nIDLIST bigint[]:=p_system_get_selectlist(IDLIST);
begin

  update JOURNALOTHERS j set status_other = '2' where j.id = ANY(nIDLIST);
  
  update STATEMENTADBDONE s set statusdoc = '2' where EXISTS(select 1
                                                               from doclinks d
                                                              where d.tablein ~~* 'STATEMENTADBDONE'
                                                                and d.keyin = s.id
                                                                and d.tableout ~~* 'JOURNALOTHERS'
                                                                and d.keyout = ANY(nIDLIST));
  update STATEMENTPBSVPKP s set statusdoc = '2' where EXISTS(select 1
                                                               from doclinks d
                                                              where d.tablein ~~* 'STATEMENTPBSVPKP'
                                                                and d.keyin = s.id
                                                                and d.tableout ~~* 'JOURNALOTHERS'
                                                                and d.keyout = ANY(nIDLIST));
  update STATEMENTPBSVPPP s set statusdoc = '2' where EXISTS(select 1
                                                               from doclinks d
                                                              where d.tablein ~~* 'STATEMENTPBSVPPP'
                                                                and d.keyin = s.id
                                                                and d.tableout ~~* 'JOURNALOTHERS'
                                                                and d.keyout = ANY(nIDLIST));
    
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


ALTER FUNCTION public.p_action_accept_to_inc (idlist text)
  OWNER TO magicbox;
