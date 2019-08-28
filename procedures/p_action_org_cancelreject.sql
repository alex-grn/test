CREATE OR REPLACE FUNCTION public.p_action_org_cancelreject (
  id bigint,
  tablename text
)
RETURNS void AS
$body$
 declare
 nID bigint := id;
 sql text;	
 st text;   --поле статуса в таблицах
 begin
   if tablename = 'citizenry' then 
     st := 'statuscitizen';
   else
     st := 'statusorg';
   end if;
   sql:='update '||tablename||' s set '||st||' = 1 where s.id = '|| nID;
   execute sql;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_org_cancelreject (id bigint, tablename text)
  OWNER TO magicbox;