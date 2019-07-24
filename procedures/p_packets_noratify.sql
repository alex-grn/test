CREATE OR REPLACE FUNCTION public.p_packets_noratify (
  idlist text,
  tablename text
)
RETURNS void AS
$body$
declare
  /* Процедура меняет значение статуса в таблице
  */
  rec record;
begin
  for rec in (select s.historystatus,s.idtable from statustech s where s.nametable = tablename and s.idtable::bigint = ANY(P_SYSTEM_GET_SELECTLIST(idlist)))
  loop
  update BENEFITSPACKETS s set statuspack = rec.historystatus where s.id = rec.idtable::bigint;
  delete from statustech s where s.nametable = tablename and s.idtable::bigint = ANY(P_SYSTEM_GET_SELECTLIST(idlist));
  end loop;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_packets_noratify (idlist text, tablename text)
  OWNER TO magicbox;