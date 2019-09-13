CREATE OR REPLACE FUNCTION public.p_action_org_approve (
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
   elsif tablename = 'direction' then
     st := 'status';
   elsif tablename = 'plans' then
     st := 'status2';
   else
     st := 'statusorg';
   end if;
   sql:='update '||tablename||' s set '||st||' = 3 where s.id = '|| nID;
   execute sql;
   if tablename = 'vacancyorg' then
         update organization s set statusorg = 3 where s.id = (select s.organizationid from VACANCYORG s where s.id = nID);
   end if;
   if tablename = 'citizenry' then
         update direction s set status = 3 where s.citizenryid = nID;
   end if;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_org_approve (id bigint, tablename text)
  OWNER TO magicbox;