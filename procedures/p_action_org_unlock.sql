CREATE OR REPLACE FUNCTION public.p_action_org_unlock (
  id bigint,
  tablename text
)
RETURNS void AS
$body$
declare
 nID bigint := id;
 sql text;
 status_now integer;
 begin
 	if tablename = 'vacancyorg' then 
   	 select s.statusorg
       into status_now
       from vacancyorg s
      where s.id = nID;
      if status_now = 4 then 
        sql:='update '||tablename||' s set statusorg = 1 where s.id = '|| nID;  execute sql;
      end if; 
   elsif tablename = 'organization' then
     select s.statusorg
       into status_now
       from organization s
      where s.id = nID;
      if status_now = 4 then 
        sql:='update '||tablename||' s set statusorg = 1 where s.id = '|| nID;  execute sql;
      end if;
   else
   sql:='update '||tablename||' s set statusorg = 1 where s.id = '|| nID;
   execute sql;
   end if;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_org_unlock (id bigint, tablename text)
  OWNER TO magicbox;