CREATE OR REPLACE FUNCTION public.p_tools_strinlike (
  ssubstr in varchar,
  ssource in varchar,
  sdelim1 in varchar default null,
  sblank  in varchar default null
)
RETURNS integer AS
$body$
 declare
  sdelim constant varchar := COALESCE(sdelim1, ';'); -- разделитель по умолчанию
  icount integer; -- кол-во
  sitem  varchar; -- элемент
 begin
  -- если не указали что, тогда 0
  if (ssource is null)
  then
    return 0;
  end if;

  -- кол-во элементов в строке
  icount := p_tools_strcnt(ssource, sdelim);
  -- разбираем и сверяем
  for i in 1 .. icount
  loop
    sitem := replace(replace(p_tools_strtok(ssource, sdelim, i), '*', '%'), '?', '_');
    if (sitem is not null and sblank is not null and sitem = sblank and ssubstr is null or
       sitem is not null and ssubstr is not null and ssubstr like sitem)
    then
      return 1;
    end if;
  end loop;
  return 0;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_tools_strinlike (source varchar, delimeter varchar, sdelim1 varchar, sblank varchar)
  OWNER TO magicbox;