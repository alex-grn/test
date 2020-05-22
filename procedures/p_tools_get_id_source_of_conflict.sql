CREATE OR REPLACE FUNCTION public.p_tools_get_id_source_of_conflict (
  stablename text,
  serror text
)
RETURNS bigint AS
$body$
/* Процедура ищет зачинщика конфликта.
   в sERROR должна передаваться ошибка PG_EXCEPTION_DETAIL */
declare
   sINPUT       text:=REPLACE(REPLACE(split_part(serror,'"','2'),'(',''),')','');
   sCOLUMNS     text:=(select split_part(sINPUT,'=',1));
   sVALUES      text:=(select split_part(sINPUT,'=',2));
   rec          record;
   sWHERE       text:='';
   nID          bigint;
   sTYPECOL     text;
begin

  for rec in
       select regexp_split_to_table(sCOLUMNS,', ') as scolumns,
              regexp_split_to_table(sVALUES,', ') as svalues
  loop
     select s.udt_name
       into sTYPECOL
       from information_schema.columns s
      where s.table_name ~* sTABLENAME
        and s.column_name ~* rec.SCOLUMNS;
     if sTYPECOL in ('text','varchar','char') then
         rec.SVALUES:=''''||rec.SVALUES||'''';
     end if;
     sWHERE:=sWHERE||' '||rec.SCOLUMNS||' = '||rec.SVALUES||' and ';
  end loop;
  sWHERE:=rtrim(sWHERE,'and ');
  
  for rec in execute
       'select s.id
          from '||sTABLENAME||' s '||
       'where '||sWHERE
  loop
     nID:=rec.ID;
  end loop;

  return nID;
  
  exception when others then return null;
  
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_tools_get_id_source_of_conflict (stablename text, serror text)
  OWNER TO magicbox;