CREATE OR REPLACE FUNCTION public.p_action_org_unlock (
  id bigint,
  tablename text
)
RETURNS void AS
$body$
declare
 nID bigint := id;
 sql text;
 begin
   sql:='update '||tablename||' s set statusorg = 1 where s.id = '|| nID;
   execute sql;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_org_unlock (id bigint, tablename text)
  OWNER TO magicbox;