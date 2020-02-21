CREATE OR REPLACE FUNCTION public.p_find_name_from_list (
  ttable text,
  tfield text,
  tvalue text
)
RETURNS text AS
$body$
declare

  RC     record;
  TMETA  METACLASS%rowtype;
  result TEXT;

begin
  for RC in (with RECURSIVE META(ID,HID,CODE,PATH) as
                (select M.ID, M.HID, M.CODE, cast(M.CODE as varchar(50)) as PATH
                  from METACLASS M
                 where M.CODE ILIKE TTABLE
                union
                select P.ID, P.HID, P.CODE, cast(META.PATH || '->' || P.CODE as varchar(50))
                  from METACLASS P
                 inner join META on META.ID = P.HID)
               select * from META M where M.CODE ILIKE TFIELD)
  loop
    TMETA.ID := RC.ID;
    exit;
  end loop;

  if exists (select 1 from METACLASS M where M.HID = TMETA.ID and M.CLASSNODE ILIKE 'ai') then
    select M.NAME
      into result
      from METACLASS M
     where M.HID = TMETA.ID
       and M.CODE ILIKE TVALUE;
    return result;
  else
    for RC in (with RECURSIVE META(ID,HID,CODE,PATH) as
                  (select M.ID, M.HID, M.CODE, cast(M.CODE as varchar(50)) as PATH
                    from METACLASS M
                   where M.CLASSNODE ILIKE 'ATTRIBUTES'
                  union
                  select P.ID, P.HID, P.CODE, cast(META.PATH || '->' || P.CODE as varchar(50))
                    from METACLASS P
                   inner join META on META.ID = P.HID)
                 select * from META M where M.CODE ILIKE TFIELD)
    loop
      TMETA.ID := RC.ID;
      exit;
    end loop;
    select M.NAME
      into result
      from METACLASS M
     where M.HID = TMETA.ID
       and M.CODE ILIKE TVALUE;
    return result;
  end if;

  return null;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_find_name_from_list (ttable text, tfield text, tvalue text)
  OWNER TO magicbox;