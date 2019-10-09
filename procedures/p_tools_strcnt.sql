CREATE OR REPLACE FUNCTION public.p_tools_strcnt (
  source    in varchar,
  delimeter in varchar
)
RETURNS integer AS
$body$
 declare
  n         integer;
  i         integer;
 begin
  -- проверка параметров
  if ( source is null ) then
    return 0;
  end if;
  if ( delimeter is null ) then
    return 1;
  end if;

  i := 1;
  n := 0;
  while ( i > 0 ) loop
    i := p_tools_instr( source,delimeter,i );
    if ( i = 0 ) then
      exit;
    end if;
    i := i + length( delimeter );
    n := n + 1;
    if ( n > length( source ) ) then
      exit;
    end if;
  end loop;

  if ( i < length( source ) ) then
    n := n + 1; -- последняя - подстрока, а не разделитель
  end if;

  return n;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_tools_strcnt (source varchar, delimeter varchar)
  OWNER TO magicbox;