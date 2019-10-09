CREATE OR REPLACE FUNCTION public.p_tools_strtok (
  source    in varchar,
  delimeter in varchar,
  item      in integer
)
RETURNS varchar AS
$body$
 declare
  i         integer;
  n         integer;
 begin
  -- проверка параметров
  if ( delimeter is null ) then
    return source;
  end if;
  if ( item < 1 ) then
    return null;
  end if;

  -- прогнать до item группы
  n := 1;
  i := 1;
  while n < item loop
    i := p_tools_instr( source,delimeter,i );
    if ( i = 0 ) then
      return null; -- не нашли столько групп
    end if;
    n := n + 1;
    i := i + length( delimeter );
  end loop;

  -- взять строку
  n := i;
  i := p_tools_instr( source,delimeter,n );
  if ( i > 0 ) then
    return substr( source,n,i-n );
  end if;
  return substr( source,n );
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_tools_strtok (source varchar, delimeter varchar, item integer)
  OWNER TO magicbox;