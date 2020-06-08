CREATE OR REPLACE FUNCTION public.t_committeeman_before_iu (
)
RETURNS trigger AS
$body$
declare
  nid    bigint;
  ncount integer;
begin
  if tg_op = 'INSERT' then
    nid := -1;
  elsif tg_op = 'UPDATE' then
    nid = old.ID;
  end if;

  -- ищем запись
  select count(*)
    into ncount
    from (select null
            from COMMITTEEMAN cm
           where cm.electcommitteeid = new.electcommitteeid
             and cm.id <> nid
             and cm.personid = new.personid
             and cm.postbegindate <= new.postenddate
             and cm.postenddate >= new.postbegindate
             and (cm.cid is null or cm.cid = 0)
          ) tmp;
--raise using message = new.postbegindate;
  if ncount > 0 then
    perform p_system_exception(0, 'По заданному ФЛ и на заданном периоде, уже имеется запись!');
  end if;
  return NEW;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.t_committeeman_before_iu ()
  OWNER TO magicbox;