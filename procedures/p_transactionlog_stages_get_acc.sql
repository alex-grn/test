CREATE OR REPLACE FUNCTION public.p_transactionlog_stages_get_acc (
  nid bigint,
  smask text,
  nsign integer
)
RETURNS text AS
$body$
declare
 sresult text;
 ncnt	 integer;
 ssign   varchar(2);
 rec 	 record;
 r 	 	 integer;
 sdata0	 varchar;
 sdata1  varchar;
 sdelim	 varchar;
 stmp 	 text;
begin
  -- первоначальная проверка маски
  select mod(length(nullif(trim(replace(replace(smask, '|', ''), ' ', '.')), '')), 4)
    into ncnt;
  if ncnt is null
  then
    perform p_system_exception(0, 'Отсутствует маска, для формирования счета!');
  elsif ncnt <> 0
  then
    perform p_system_exception(0, 'Некоректно указана маска!');
  end if;

  -- ДТ/КТ
  if nsign = 0
  then
    ssign := 'dt';
  elsif nsign = 1
  then
    ssign := 'kt';
  else
    perform p_system_exception(0, 'Признак счета, непоределен!');
  end if;

  -- сборка по маске
  ncnt := p_tools_strcnt(smask, '|');

  for r in 1..ncnt
  loop
    -- считывание из маски показателей
    sdata0 := substr(p_tools_strtok(smask, '|', r), 1, 2);
    sdata1 := substr(p_tools_strtok(smask, '|', r), 3, 1);
    if sdata1 <> 'C' and sdata1 <> 'N'
    then
      perform p_system_exception(0, 'Тип выводимой информации "'|| sdata1 ||'", неопределен!');
    end if;
    sdelim := substr(p_tools_strtok(smask, '|', r), 4, 1);
    for rec in execute 'select '|| ssign || 'finsecurity as nfinsecurity, '||
                              ssign || 'budgclassid as nbudgclassid, '||
                              ssign || 'econclassktid as neconclassktid, '||
                              ssign || 'typeexpid as ntypeexpid, '||
                              'account'||ssign||'id as naccount, '||
                              --ssign || 'analytics1 as nanalytics1, '||
                              --ssign || 'analytics2 as nanalytics2, '||
                              'agent'||ssign||'id as nagent, '||
                              'person'||ssign||'id as nperson, '||
                              ssign || 'respperson as nrespperson, '||
                              ssign || 'dicnomnsid as ndicnomnsid '||
                         'from TRANSACTIONLOG_STAGES where id =  '|| COALESCE(nid,-1)
    loop
      if sdata0 = 'KO' -- КФО
      then
        stmp := sdelim || rec.nfinsecurity::text;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      elsif sdata0 = 'KS' -- КПС
      then
        select
          case sdata1
            when 'C' then
              sdelim || code::text
            when 'N' then
              sdelim || name::text
          else
            null
          end
          into stmp
          from budgclass where id = rec.nbudgclassid::bigint;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      elsif sdata0 = 'KU' -- КОСГУ
      then
        select
          case sdata1
            when 'C' then
              sdelim || code::text
            when 'N' then
              sdelim || name::text
          else
            null
          end
          into stmp
          from econclass where id = rec.neconclassktid::bigint;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      elsif sdata0 = 'DE' -- Направление расходов
      then
        select
          case sdata1
            when 'C' then
              sdelim || numbestimate::text
            when 'N' then
              sdelim || print_name::text
          else
            null
          end
          into stmp
          from typeexp where id = rec.ntypeexpid::bigint;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      elsif sdata0 = 'AC' -- Счет
      then
        select
          case sdata1
            when 'C' then
              sdelim || accnumb::text
            when 'N' then
              sdelim || accname::text
          else
            null
          end
          into stmp
          from dicaccs where id = rec.naccount::bigint;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      /*elsif sdata0 = 'A1' -- Аналитика 1
      then
        stmp := sdelim || rec.nanalytics1::text;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      elsif sdata0 = 'A2' -- Аналитика 2
      then
        stmp := sdelim || rec.nanalytics2::text;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');*/
      elsif sdata0 = 'UL' -- Юридическое лицо
      then
        select
          case sdata1
            when 'C' then
              sdelim || code::text
            when 'N' then
              sdelim || name::text
          else
            null
          end
          into stmp
          from agent where id = rec.nagent::bigint;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      elsif sdata0 = 'FL' -- Физическое лицо
      then
        select
          case sdata1
            when 'C' then
              sdelim || code::text
            when 'N' then
              sdelim || name::text
          else
            null
          end
          into stmp
          from person where id = rec.nperson::bigint;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      elsif sdata0 = 'ML' -- МОЛ
      then
        select
          case sdata1
            when 'C' then
              sdelim || p.code::text
            when 'N' then
              sdelim || p.name::text
          else
            null
          end
          into stmp
          from mtresponspers m
          left join person p on p.id = m.personid
        where m.id = rec.nrespperson::bigint;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      elsif sdata0 = 'NM' -- Номенклатура
      then
        select
          case sdata1
            when 'C' then
              sdelim || code::text
            when 'N' then
              sdelim || name::text
          else
            null
          end
          into stmp
          from dicnomns where id = rec.ndicnomnsid::bigint;
        sresult := nullif(COALESCE(sresult,'') || COALESCE(stmp,''),'');
      else
        perform p_system_exception(0, 'Макроподстановка "'|| sdata0 ||'", неопределена!');
      end if;
    end loop;
  end loop;
  return substr(sresult,2);
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_transactionlog_stages_get_acc (nid bigint, smask text, nsign integer)
  OWNER TO magicbox;