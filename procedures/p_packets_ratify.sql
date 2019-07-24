CREATE OR REPLACE FUNCTION public.p_packets_ratify (
  idlist text,
  tablename text
)
RETURNS void AS
$body$
declare
  /* Процедура меняет значение статуса в таблице и сохраняет предыдущий статус*/
begin
  insert into statustech(historystatus,nametable,idtable) 
  select s.statuspack,tablename,s.id
    from BENEFITSPACKETS s 
   where s.id = ANY(P_SYSTEM_GET_SELECTLIST(idlist));
  update BENEFITSPACKETS s set statuspack = '01' where s.id = ANY(P_SYSTEM_GET_SELECTLIST(idlist));
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_packets_ratify (idlist text, tablename text)
  OWNER TO magicbox;