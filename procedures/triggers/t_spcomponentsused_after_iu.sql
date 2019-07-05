CREATE OR REPLACE FUNCTION public.t_spcomponentsused_after_iu() RETURNS trigger AS
$body$
declare 
 nCOUNT numeric(17,2);
 nCOUNT_SP numeric(17,2);
begin
/*Определяем сумму спецификаций*/
select coalesce(sum(u.quant),0)+coalesce(NEW.quant,0),
       (select coalesce(c.quant,0) from components c where c.id=NEW.pid)
  into nCOUNT_SP, nCOUNT
  from spcomponentsused u
 where u.pid=NEW.pid
   and u.ID <> NEW.ID
   and u.cid = 0;

  if nCOUNT_SP>nCOUNT
  then raise exception 'Ошибка: Сумма спецификаций расхода (%) превышает количество (%) в заголовке!', nCOUNT_SP, nCOUNT;
       return OLD;
  end if;

  return NEW;

end;
$body$
language plpgsql volatile;
