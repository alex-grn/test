CREATE OR REPLACE FUNCTION public.p_tools_merge_row
(
 stable_name TEXT,
 nleave BIGINT,
 ndel BIGINT
)
RETURNS void AS
$body$
declare
   REC RECORD;
   sfld_prm text;
begin
  for rec in
    (select kcu.table_name,
    	    kcu.column_name,
            ccu.column_name as fld_prm
       FROM information_schema.table_constraints AS tc,
            information_schema.key_column_usage AS kcu,
            information_schema.constraint_column_usage AS ccu,
            information_schema.referential_constraints AS rc
      WHERE tc.constraint_type = 'FOREIGN KEY'
        and ccu.table_name=lower(trim(stable_name))
        and tc.table_schema='public'
        and kcu.constraint_name=tc.constraint_name
        and tc.constraint_name=ccu.constraint_name
        and tc.constraint_name=rc.constraint_name
    )
  loop
    -- Подменяем
    execute 'update '||rec.table_name||' set '||rec.column_name||' = '||nleave||' where '||rec.column_name||' = '||ndel;
    sfld_prm := rec.fld_prm;
  end loop;
  -- удаляем запись
  if nullif(sfld_prm,'') is not null
  then
    execute 'delete from '||trim(stable_name)||' where '||sfld_prm||' = '||ndel;
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_tools_merge_row(stable_name TEXT, nleave BIGINT, ndel BIGINT)
  OWNER TO magicbox;

--select * from BENEFITSRECIPIENTS
--BENEFITCHILD
