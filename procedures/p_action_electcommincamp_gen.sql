-- Function: public.p_action_electcommincamp_gen(date, date, text, integer, boolean, text, bigint)

-- DROP FUNCTION public.p_action_electcommincamp_gen(date, date, text, integer, boolean, text, bigint);

CREATE OR REPLACE FUNCTION public.p_action_electcommincamp_gen(
    begindate date,
    enddate date,
    leveldcchairman text,
    ncount integer,
    printreport boolean,
    idlist text,
    uid bigint)
  RETURNS void AS
$BODY$
/*Действие: Сформировать комплекты расчетных форм*/
declare
  BDATE  date := BEGINDATE; --неоднозначная ссылка
  EDATE  date := ENDDATE; --неоднозначная ссылка
  REC    record;
  IZ     record;
  RK     record;
  STEMP  TEXT;
  NID    BIGINT;
  COMPIT TEXT := 'Компенсация'; --таблица pays всегда компенсация
  COMID  BIGINT;
  REGID  BIGINT;
  SUBID  BIGINT; --ID субъекта РФ
  TDOC   BIGINT;
  TIK    TEXT := 'territory'; --код ТИК в системе
  IKMO   TEXT := 'circuit'; --код ИКМО
  J      integer := 1;
  bprintreport BOOLEAN;
  NUID   BIGINT:=UID;
  NLID   BIGINT;
begin
    
                                                  --ПЕРЕДЕЛАТЬ ↓
  select R.ID into SUBID from REGIONSRF R where R.IDGASREGIONSRF = '00';  --Российская Федерация
  
  if NCOUNT not in (1, 2) then
    raise
      using MESSAGE = 'Количество строк для одного календарного дня может принимать значение 1 или 2. Введите одно из значений.';
  end if;
  for REC in (select S.*,
                     LOWER(IK.LEVELELCOMMITTEE) as LEVELCOM,
                     I.BEGINDATE,
                     I.ENDDATE,
                     I.BEGINDATETER,
                     I.ENDDATETER,
                     UPPER(I.LEVELELCAMPAIGN) as level,
                     IK.REGIONSRFID as REGION,
                     I.ELECTDATE,
                     (select F.MFIN from MFIN F where F.ELECTCOMMITTEEID = IK.ID  and ((LOWER(IK.LEVELELCOMMITTEE) in ('territory','circuit') and I.BEGINDATETER >= F.BEGINDATE  and  (I.BEGINDATETER<=F.ENDDATE OR F.ENDDATE IS NULL))
     or (LOWER(IK.LEVELELCOMMITTEE) = 'district' and I.BEGINDATE >= F.BEGINDATE  and  (I.BEGINDATE<=F.ENDDATE OR F.ENDDATE IS NULL)))) AS MFIN
                from ELECTCOMMINCAMP S,
                     ELECTCAMPAIGN   I,
                     ELECTCOMMITTEE  IK
               where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                 and I.ID = S.ELECTCAMPAIGNID
                 and IK.ID = S.ELECTCOMMITTEEID)
  loop
                                                 --ПЕРЕДЕЛАТЬ ↓
    select S.ID into TDOC from DOCTYPES S where LOWER(S.CODE) = 'комплект расчетных форм';
  
    --Проверки
    if (select count(*)
          from REGISTER S
         where S.ELECTCOMMINCAMPID = REC.ID
           and S.DOCTYPEID = TDOC
           and (BDATE between S.BEGINDATE and S.ENDDATE or EDATE between S.BEGINDATE and S.ENDDATE)) > 0 then
      raise
        using MESSAGE = 'На периоде ' || TO_CHAR(BDATE, 'dd.mm.yyyy') || ' - ' || TO_CHAR(EDATE, 'dd.mm.yyyy') || ' сформирован комплект расчетных форм!';
    end if;
    if (REC.LEVELCOM = TIK or REC.LEVELCOM = IKMO) and REC.MTERELCOM then
      if REC.BEGINDATETER > BDATE or REC.BEGINDATETER > EDATE or REC.ENDDATETER < BDATE or REC.ENDDATETER < EDATE then
        raise
          using MESSAGE = 'Неверно указан период работы членов избирательной комиссии. Для избирательной кампании период работы членов установлен c ' || TO_CHAR(REC.BEGINDATETER, 'dd.mm.yyyy') || ' по ' || D2S(REC.ENDDATETER);
      elsif REC.BEGINDATETER is null or REC.ENDDATETER is null then
        raise
          using MESSAGE = 'Не задан период работы ТИК в избирательных кампаниях!';
      end if;
    else
      if REC.BEGINDATE > BDATE or REC.BEGINDATE > EDATE or REC.ENDDATE < BDATE or REC.ENDDATE < EDATE then
        raise
          using MESSAGE = 'Неверно указан период работы членов избирательной комиссии. Для избирательной кампании период работы членов установлен c ' || TO_CHAR(REC.BEGINDATE, 'dd.mm.yyyy') || ' по ' || D2S(REC.ENDDATE);
      end if;
    end if;
    --Проверка по событию МАЦ-4011
    --1. Дата окончания действия полномочий не задана
    if exists (select 1
          from ELECTCOMMITTEE X
         where X.ID = REC.ELECTCOMMITTEEID
           and X.POSTENDDATE is null) then
      raise
        using MESSAGE = 'Формирование комплекта расчетных форм запрещено. Не задана дата окончания действия полномочий.';
    end if;
    --2. Дата окончания действия полномочий меньше даты голосования
    if exists (select 1
          from ELECTCOMMITTEE X
         where X.ID = REC.ELECTCOMMITTEEID
           and X.POSTENDDATE < REC.ELECTDATE) then
      raise
        using MESSAGE = 'Формирование комплекта расчетных форм запрещено. Полномочия комиссии на день голосования прекращены.';
    end if;
    --3. Дата начала действия полномочий больше даты голосования 
    if exists (select 1
          from ELECTCOMMITTEE X
         where X.ID = REC.ELECTCOMMITTEEID
           and X.POSTBEGINDATE > REC.ELECTDATE) then
      raise
        using MESSAGE = 'Формирование комплекта расчетных форм запрещено. Полномочия комиссии на день голосования не установлены.';
    end if;
  
    STEMP := TDOC || '_' || --Код избирательного участка
             (select COALESCE(TO_CHAR(X.ELECTDATE, 'dd.mm.yyyy'), '') from ELECTCAMPAIGN X where X.ID = REC.ELECTCAMPAIGNID) || '_';
    --update ELECTCOMMINCAMP S set MSREGISTER = COALESCE(MSREGISTER, 0) + 1 where S.ID = REC.ID; --апдейтим КОД
     if REC.LEVEL ilike 'central' and REC.MFIN = '1' then  
       BPRINTREPORT:=FALSE;
    elsif REC.LEVEL ilike 'central' and REC.MFIN = '2' then  
       BPRINTREPORT:=TRUE;
    elsif REC.LEVEL ilike 'central' and REC.MFIN = '3' then 
       BPRINTREPORT:=TRUE;
    elsif REC.LEVEL not ilike 'central' and REC.MFIN = '1' THEN
       BPRINTREPORT:=FALSE;
    elsif REC.LEVEL not ilike 'central' and REC.MFIN = '2' THEN
       BPRINTREPORT:=PRINTREPORT;
    elsif REC.LEVEL not ilike 'central' and REC.MFIN = '3' THEN
       BPRINTREPORT:=PRINTREPORT;
    else 
       raise using message = 'Неопределен порядок финансирования!';
    end if;
  
    NLID := P_SYSTEM_GEN_LID('REGISTER',nUID);
    insert into REGISTER
      (UID, LID, CODE, DOCTYPEID, STATUS, ELECTCAMPAIGNID, BEGINDATE, ENDDATE, ELECTCOMMINCAMPID, DATELOADTBL, RESPONSPERSID, PRINTREPORT)
      select NUID,
             NLID,
             STEMP,
             TDOC,
             1,
             REC.ELECTCAMPAIGNID,
             BDATE,
             EDATE,
             REC.ID,
             null,
             null,
             BPRINTREPORT returning ID
        into REGID;
    update REGISTER S set CODE = CODE || REGID where S.ID = REGID;
    for IZ in (select R.CODE,
                      R.ID,
                      R.POSTSID,
                      R.PERSONID,
                      case
                        when D.POSTPRINT ILIKE 'CHAIRMAN' then
                         LEVELDCCHAIRMAN
                      end as LVLCH
                 from ELECTCOMMITTEE X,
                      COMMITTEEMAN   R,
                      POSTS          D
                where X.ID = REC.ELECTCOMMITTEEID
                  and R.ELECTCOMMITTEEID = X.ID
                  and D.ID = R.POSTSID
                  and ((BDATE between R.POSTBEGINDATE and R.POSTENDDATE or EDATE between R.POSTBEGINDATE and R.POSTENDDATE) or
                      (BDATE between R.POSTBEGINDATE and R.POSTENDDATE and EDATE between R.POSTBEGINDATE and R.POSTENDDATE) or
                      (R.POSTBEGINDATE between BDATE and EDATE and R.POSTENDDATE between BDATE and EDATE)))
    loop
      --Наполняем таблицу "члены избирательных комиссий"
      NLID := P_SYSTEM_GEN_LID('REGISTERLIST',nUID);
      insert into REGISTERLIST
        (UID, LID, REGISTERID, CODE, COMMITTEEMANID, MIDDLESALARY, DEPCOEFF, LEVELDCCHAIRMAN)
        select NUID,
               NLID,
               REGID,
               IZ.CODE,
               IZ.ID,
               (select P.VALUE
                  from PERSON       S,
                       PERSONSAVSLR P
                 where S.ID = IZ.PERSONID
                   and P.PERSONID = S.ID
                   and P.ELECTCAMPAIGNID = REC.ELECTCAMPAIGNID limit 1),
               0,
               IZ.LVLCH returning ID
          into NID;
      if (select S.LEVELELCAMPAIGN from ELECTCAMPAIGN S where S.ID = REC.ELECTCAMPAIGNID) = 'central' then
        J := 1;
        --Уровень федеральный 
        for RK in (select DD, --заполняем таблицу worktbl 
                          (select D.TYPEDAYID
                             from WORKCALENDARS     W,
                                  DAYSWORKCALENDARS D
                            where D.WORKCALENDARSID = W.ID
                              and W.REGIONSRFID = SUBID --Российская Федерация
                              and D.DATEWC = DD) as STYPE
                     from GENERATE_SERIES(BDATE, EDATE, interval '1 day') as DD
                    order by DD)
        loop
          for I in 1 .. NCOUNT
          loop
            insert into WORKTBL (UID, LID, REGISTERLISTID, DATETBL, TYPEDAYID, NUMBCALDAY) values (NUID, P_SYSTEM_GEN_LID('WORKTBL',nUID), NID, RK.DD, RK.STYPE, J);
            J := J + 1;
          end loop;
        end loop;
        for RK in (select (select W.ID
                             from WORKCALENDARS W
                            where W.REGIONSRFID = SUBID
                              and W.MONTH ::integer = TO_CHAR(DD, 'mm') ::integer
                              and W.YEAR = TO_CHAR(DD, 'yyyy') ::integer) as WID
                     from GENERATE_SERIES(BDATE, DATE_TRUNC('month', EDATE) + interval '1 MONTH - 1 DAY', interval '1 month') as DD)
        loop
          select S.ID into COMID from SLCOMPCHARGES S where LOWER(S.NAME) = LOWER(COMPIT); --находим id компенсации
          insert into PAYS (UID, LID, REGISTERLISTID, SLCOMPCHARGESID, WORKCALENDARSID) values (NUID, P_SYSTEM_GEN_LID('PAYS',nUID), NID, COMID, RK.WID);
        end loop;
      else
        J := 1;
        --Уровень региональный
        for RK in (select DD, --заполняем таблицу worktbl 
                          (select case
                                    when (select count(*)
                                            from WORKCALENDARS     W,
                                                 DAYSWORKCALENDARS D
                                           where D.WORKCALENDARSID = W.ID
                                             and W.REGIONSRFID = REC.REGION
                                             and D.DATEWC = DD) > 0 then
                                     (select D.TYPEDAYID
                                        from WORKCALENDARS     W,
                                             DAYSWORKCALENDARS D
                                       where D.WORKCALENDARSID = W.ID
                                         and W.REGIONSRFID = REC.REGION
                                         and D.DATEWC = DD)
                                    else
                                     (select D.TYPEDAYID
                                        from WORKCALENDARS     W,
                                             DAYSWORKCALENDARS D
                                       where D.WORKCALENDARSID = W.ID
                                         and W.REGIONSRFID = SUBID --Российская Федерация
                                         and D.DATEWC = DD)
                                  end) as STYPE
                     from GENERATE_SERIES(BDATE, EDATE, interval '1 day') as DD
                    order by DD)
        loop
          for I in 1 .. NCOUNT
          loop
            insert into WORKTBL (UID, LID, REGISTERLISTID, DATETBL, TYPEDAYID, NUMBCALDAY) values (NUID, P_SYSTEM_GEN_LID('WORKTBL',nUID), NID, RK.DD, RK.STYPE, J);
            J := J + 1;
          end loop;
        end loop;
        for RK in (select (select case
                                    when (select count(*)
                                            from WORKCALENDARS W
                                           where W.REGIONSRFID = REC.REGION
                                             and W.MONTH ::integer = TO_CHAR(DD, 'mm') ::integer
                                             and W.YEAR = TO_CHAR(DD, 'yyyy') ::integer) > 0 then
                                     (select W.ID
                                        from WORKCALENDARS W
                                       where W.REGIONSRFID = REC.REGION
                                         and W.MONTH ::integer = TO_CHAR(DD, 'mm') ::integer
                                         and W.YEAR = TO_CHAR(DD, 'yyyy') ::integer)
                                    else
                                     (select W.ID
                                        from WORKCALENDARS W
                                       where W.REGIONSRFID = SUBID
                                         and W.MONTH ::integer = TO_CHAR(DD, 'mm') ::integer
                                         and W.YEAR = TO_CHAR(DD, 'yyyy') ::integer)
                                  end) as WID
                     from GENERATE_SERIES(BDATE, DATE_TRUNC('month', EDATE) + interval '1 MONTH - 1 DAY', interval '1 month') as DD)
        loop
          select S.ID into COMID from SLCOMPCHARGES S where LOWER(S.NAME) = LOWER(COMPIT); --находим id компенсации
          insert into PAYS (UID, LID, REGISTERLISTID, SLCOMPCHARGESID, WORKCALENDARSID) values (NUID, P_SYSTEM_GEN_LID('PAYS',nUID), NID, COMID, RK.WID);
        end loop;
      end if;
      NLID := P_SYSTEM_GEN_LID('PAYS',nUID);
      insert into PAYS
        (UID, LID, REGISTERLISTID, SLCOMPCHARGESID)
        select NUID,
               NLID,
               NID,
               S.ID
          from SLCOMPCHARGES S
         where UPPER(trim(S.DESCRIPTION)) in ('EXTRA1', 'EXTRA2', 'SUMEXTRA12', 'EXTRAA', 'SUMALL');
    end loop;
   
    --МАЦ-4232
    for RK in (
        select t.ID
          from FINANCEELCOM f,
               TYPEEXP t
         where f.ELECTCOMMINCAMPID = REC.ID
           and t.id = f.TYPEEXPID
           and t.TYPEEXPENSES ilike 'salary'
    )
    loop
       if (select count(*)
              from FINEXP S
             where S.TYPEEXPID = RK.ID
               and S.ELECTCOMMINCAMPID = REC.ID) = 0 then 
          --уровень      
          select case 
                  when (k.levelelcommittee ~* 'territory' or k.levelelcommittee ~* 'circuit') and sum(COALESCE(f.sumfintik,0)) > 0 then 'territory'
                  when (k.levelelcommittee ~* 'territory' or k.levelelcommittee ~* 'circuit') and sum(COALESCE(f.sumfintik,0)) = 0 and sum(COALESCE(f.sumfintikcen,0)) > 0 then 'terdist'
                  when k.levelelcommittee ~* 'district' and sum(COALESCE(f.sumfintikcen,0)) > 0 then 'terdist'
                  when k.levelelcommittee ~* 'district' and sum(COALESCE(f.sumfinuik,0)) > 0 then 'district'
                 end
            into STEMP 
            from FINANCEELCOM f,
                 ELECTCOMMINCAMP e,
                 ELECTCOMMITTEE k
           where f.TYPEEXPID = RK.ID
             and f.ELECTCOMMINCAMPID = REC.ID
             and e.ID = f.ELECTCOMMINCAMPID
             and k.ID = e.ELECTCOMMITTEEID
           group by k.LEVELELCOMMITTEE;  
          insert into FINEXP (UID, LID, TYPEEXPID, ELECTCOMMINCAMPID, LEVELESTIMATE) values (NUID, P_SYSTEM_GEN_LID('FINEXP',nUID), RK.ID, REC.ID, STEMP);
        end if;
    end loop;
    --
  end loop;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_electcommincamp_gen(date, date, text, integer, boolean, text, bigint)
  OWNER TO magicbox;
