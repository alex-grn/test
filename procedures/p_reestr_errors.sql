CREATE OR REPLACE FUNCTION public.p_reestr_errors (
  ident bigint,
  id bigint
)
RETURNS text AS
$body$
 declare
  rec record;
  nid bigint:=id;
begin
  --raise using message = 'boom';
  delete from filebuffer where cid = ident;
  for rec in(
  			select s.wrongloading
             from BENEFICIARIESREGISTERS s
            where s.id = nid)
            loop
			   insert into filebuffer(cid, filename, bfile) values (ident, 'Reestr_errors.txt', P_SYSTEM_FILE_FROM_TEXT(rec.wrongloading));
    	   end loop;
  return null;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_reestr_errors (ident bigint, id bigint)
  OWNER TO magicbox;