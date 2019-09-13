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
 status_now integer;
 begin
   if tablename = 'citizenry' then 
     st := 'statuscitizen';
   else
     st := 'statusorg';
   end if;
   if tablename = 'vacancyorg' then 
   	 select s.statusorg
       into status_now
       from vacancyorg s
      where s.id = nID;
      if status_now = 2 then 
        sql:='update '||tablename||' s set '||st||' = 1 where s.id = '|| nID;  execute sql;
      end if; 
   elsif tablename = 'organization' then
     select s.statusorg
       into status_now
       from organization s
      where s.id = nID;
      if status_now = 2 then 
        sql:='update '||tablename||' s set '||st||' = 1 where s.id = '|| nID;  execute sql;
      end if;
   elsif tablename = 'citizenry' then
     select s.statuscitizen
       into status_now
       from citizenry s
      where s.id = nID;
      if status_now = 2 then 
        sql:='update '||tablename||' s set '||st||' = 1 where s.id = '|| nID;  execute sql;
      end if;
   else 
   	  sql:='update '||tablename||' s set '||st||' = 1 where s.id = '|| nID; execute sql;
   end if;
  
  
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_org_cancelreject (id bigint, tablename text)
  OWNER TO magicbox;