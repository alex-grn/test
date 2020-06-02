CREATE OR REPLACE FUNCTION public.t_reporting_iksfr_before_u (
)
RETURNS trigger AS
$body$
 declare
  dSPDATE date;
 begin 
    perform p_action_set_status('ACCOUNTABILITYIKSRF',NEW.ACCOUNTABILITYIKSRFID::text,'7');
   return new;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.t_reporting_iksfr_before_u ()
  OWNER TO magicbox;

CREATE OR REPLACE FUNCTION public.t_reporting_tik_before_u (
)
RETURNS trigger AS
$body$
 declare
  dSPDATE date;
 begin 
    perform p_action_set_status('ACCOUNTABILITYTIK',NEW.ACCOUNTABILITYTIKID::text,'7');
   return new;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.t_reporting_tik_before_u ()
  OWNER TO magicbox;

CREATE OR REPLACE FUNCTION public.t_reporting_uik_before_u (
)
RETURNS trigger AS
$body$
 declare
  dSPDATE date;
 begin 
    perform p_action_set_status('ACCOUNTABILITYUIK',NEW.ACCOUNTABILITYUIKID::text,'7');
   return new;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.t_reporting_uik_before_u ()
  OWNER TO magicbox;

do
$$
declare
 /* скрипт создает триггера для подчиненых таблиц!*/
  rec record;
  sSQL text:='';
  cnt  integer:=0;
  --ключи по которым найдем подчиненные таблицы
  srod_id1     text:='ACCOUNTABILITYUIKID';
  srod_id2     text:='ACCOUNTABILITYTIKID';
  srod_id3     text:='ACCOUNTABILITYIKSRFID';
begin
  for rec in
     select c.table_name
    from information_schema.columns c
   where c.column_name ~* srod_id1
   order by c.table_name
  loop
     begin   
       cnt:=cnt+1;
       execute   'CREATE TRIGGER trg_'||rec.table_name||'_before_u
                         BEFORE UPDATE 
                         ON public.'||rec.table_name||'
                         FOR EACH ROW 
                         EXECUTE PROCEDURE public.t_reporting_uik_before_u();'||chr(13)||chr(13);
     exception when others then null;
     end;               
  end loop;
  
  for rec in
     select c.table_name
    from information_schema.columns c
   where c.column_name ~* srod_id2
   order by c.table_name
  loop   
     begin
       cnt:=cnt+1;
       execute   'CREATE TRIGGER trg_'||rec.table_name||'_before_u
                         BEFORE UPDATE 
                         ON public.'||rec.table_name||'
                         FOR EACH ROW 
                         EXECUTE PROCEDURE public.t_reporting_tik_before_u();'||chr(13)||chr(13);
     exception when others then null;
     end;
  end loop;
  
  for rec in
     select c.table_name
    from information_schema.columns c
   where c.column_name ~* srod_id3
   order by c.table_name
  loop   
     begin
       cnt:=cnt+1;
       execute   'CREATE TRIGGER trg_'||rec.table_name||'_before_u
                         BEFORE UPDATE 
                         ON public.'||rec.table_name||'
                         FOR EACH ROW 
                         EXECUTE PROCEDURE public.t_reporting_iksfr_before_u();'||chr(13)||chr(13);
     exception when others then null;
     end;
  end loop;
  
end;
$$