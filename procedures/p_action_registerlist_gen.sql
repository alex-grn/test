-- Function: public.p_action_registerlist_gen(text, bigint)

-- DROP FUNCTION public.p_action_registerlist_gen(text, bigint);

CREATE OR REPLACE FUNCTION public.p_action_registerlist_gen(
    idlist text,
    uid bigint)
  RETURNS void AS
$BODY$
declare
  NUID        BIGINT := UID;
  REC         record;
  ALLS        record;
  SLCOM       varchar; --код выплаты
  ALG         record;
  SUM_SPRAVKA numeric; --справка о среднем заработке с основного места работы
  SUM_LIMIT   numeric; --предельный размер компенсации
  BUF         numeric [ ];
begin
  if exists (select 1
        from WORKTBL W
       where W.REGISTERLISTID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
         and W.ERRWH is not null
         and W.ERRWH != '') then
    raise
      using MESSAGE = 'В сведениях фов обнаружены ошибки заполнения времени работы членов ИК. Сформируйте отчёт «Протокол проверки сведений о ФОВ» для расчетного документа и устраните замечания.';
  end if;
  if exists (select R.ID
        from REGISTER     R,
             REGISTERLIST RL
       where RL.REGISTERID = R.ID
         and R.STATUS = '4'
         and RL.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))) then
    raise exception 'Расчет выплат запрещен! Сформированы ведомости по оплате труда!';
  end if;

  for ALLS in (select S.ID from REGISTERLIST S where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST)))
  loop
    for REC in (select S.*,
                       P.ID as PID,
                       P.SLCOMPCHARGESID,
                       S.MIDDLESALARY,
                       (select X.COUNTWD from WORKCALENDARS X where X.ID = P.WORKCALENDARSID) as COUNTWD,
                       P.WORKCALENDARSID,
                       trim(LOWER(SS.CODE)) as SLCOM,
                       COALESCE((select sum(K.WHCOMP)
                                   from WORKTBL K
                                  where K.REGISTERLISTID = S.ID
                                    and K.DATETBL in (select SX.DATEWC
                                                        from WORKCALENDARS     X,
                                                             DAYSWORKCALENDARS SX
                                                       where X.ID = P.WORKCALENDARSID
                                                         and SX.WORKCALENDARSID = X.ID)) / 8,
                                0) as SUMM,
                       COALESCE((select sum(K.WHEXTRAWORKDAY) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as WORKDAY_SUMM,
                       COALESCE((select sum(K.WHEXTRANIGHT + K.WHEXTRAHOL) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as SUMX2,
                       case
                         when COALESCE(S.MIDDLESALARY, 0) > 0 then
                          1
                         else
                          0
                       end as IFMIDSAL --Заполнена ли средняя зарплата в членах изберательной комиссии
                
                  from REGISTERLIST  S,
                       PAYS          P,
                       SLCOMPCHARGES SS
                 where S.ID = ALLS.ID
                   and P.REGISTERLISTID = S.ID
                   and P.SHEETSID is null
                   and SS.ID = P.SLCOMPCHARGESID
                   and UPPER(SS.DESCRIPTION) = 'COMPENSATION')
    loop
      update PAYS S
         set NORM      = 0,
             WORKHOURS = 0,
             SUMPAY    = 0,
             PROPPAYS  = null
       where S.ID = REC.PID;
    
      select COALESCE(S.VALUE, 0)
        into SUM_SPRAVKA
        from COMMITTEEMAN C,
             PERSON       P,
             PERSONSAVSLR S
       where C.ID = REC.COMMITTEEMANID
         and P.ID = C.PERSONID
         and S.PERSONID = P.ID
         and S.BEGINDATE <= NOW()
         and (S.ENDDATE >= NOW() or S.ENDDATE is null);
      select COALESCE(SN.VALUE, 0)
        into SUM_LIMIT
        from REGISTER        R, --расчет
             ELECTCAMPAIGN   I, --избирательная камания
             FEDELECCAMP     N, --нормативный документ
             NORMSFEDEC      SN, --спецификация нормативного документа: расчет оплаты труда
             ELECTCOMMINCAMP KK,
             ELECTCOMMITTEE  K --избирательная коммисия
       where I.ID = R.ELECTCAMPAIGNID
         and N.ID = I.FEDELECCAMPID
         and SN.FEDELECCAMPID = N.ID
         and SN.NAMENORMS = 'limitcomp'
         and KK.ID = R.ELECTCOMMINCAMPID
         and K.ID = KK.ELECTCOMMITTEEID
         and SN.REGIONSRFID = K.REGIONSRFID;
    
      update PAYS S
         set NORM      = LEAST(REC.MIDDLESALARY, SUM_LIMIT) / REC.COUNTWD * /*МАЦ-3955*/
                         REC.IFMIDSAL,
             WORKHOURS = REC.SUMM,
             SUMPAY   =
             (LEAST(REC.MIDDLESALARY, SUM_LIMIT) / REC.COUNTWD) * REC.SUMM
       where S.ID = REC.PID;
      SUM_LIMIT   := 0;
      SUM_SPRAVKA := 0;
    end loop;
    for REC in (select S.*,
                       P.ID as PID,
                       P.SLCOMPCHARGESID,
                       (select X.COUNTWD from WORKCALENDARS X where X.ID = P.WORKCALENDARSID) as COUNTWD,
                       P.WORKCALENDARSID,
                       trim(LOWER(SS.CODE)) as SLCOM,
                       COALESCE((select sum(K.WHCOMP)
                                   from WORKTBL K
                                  where K.REGISTERLISTID = S.ID
                                    and K.DATETBL in (select SX.DATEWC
                                                        from WORKCALENDARS     X,
                                                             DAYSWORKCALENDARS SX
                                                       where X.ID = P.WORKCALENDARSID
                                                         and SX.WORKCALENDARSID = X.ID)) / 8,
                                0) as SUMM,
                       COALESCE((select sum(K.WHEXTRAWORKDAY) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as WORKDAY_SUMM,
                       COALESCE((select sum(K.WHEXTRANIGHT + K.WHEXTRAHOL) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as SUMX2
                
                  from REGISTERLIST  S,
                       PAYS          P,
                       SLCOMPCHARGES SS
                 where S.ID = ALLS.ID
                   and P.REGISTERLISTID = S.ID
                   and P.SHEETSID is null
                   and SS.ID = P.SLCOMPCHARGESID
                   and UPPER(SS.DESCRIPTION) = 'EXTRA1')
    loop
      update PAYS S
         set NORM      = 0,
             WORKHOURS = 0,
             SUMPAY    = 0,
             PROPPAYS  = null
       where S.ID = REC.PID;
      select COALESCE(SN.VALUE, 0)
        into SUM_SPRAVKA
        from REGISTER        R, --расчет
             ELECTCAMPAIGN   I, --избирательная камания
             FEDELECCAMP     N, --нормативный документ
             NORMSFEDEC      SN, --спецификация нормативного документа: расчет оплаты труда
             ELECTCOMMINCAMP KK,
             COMMITTEEMAN    CC,
             ELECTCOMMITTEE  K --избирательная коммисия
       where I.ID = R.ELECTCAMPAIGNID
         and N.ID = I.FEDELECCAMPID
         and SN.FEDELECCAMPID = N.ID
         and SN.NAMENORMS = 'reward' --размер дополнительной оплаты турла
         and KK.ID = R.ELECTCOMMINCAMPID
         and K.ID = KK.ELECTCOMMITTEEID
         and SN.MCIRCUIT = KK.MCIRCUIT --полномочия ОИК
         and CC.ID = REC.COMMITTEEMANID
         and R.ID = REC.REGISTERID
         and SN.POSTSID = CC.POSTSID;
    
      select case I.LEVELELCAMPAIGN
               when 'central' then
                K.DISCOEFFFED
               when 'region' then
                K.DISCOEFREG
             end
        into SUM_LIMIT
        from REGISTER       R,
             ELECTCAMPAIGN  I,
             ELECTCOMMITTEE K,
             COMMITTEEMAN   C
       where R.ID = REC.REGISTERID
         and I.ID = R.ELECTCAMPAIGNID
         and K.ID = C.ELECTCOMMITTEEID
         and C.ID = REC.COMMITTEEMANID;
         
      BUF [ 1 ] := SUM_SPRAVKA;
      BUF [ 2 ] := SUM_LIMIT;
    
      update PAYS S
         set NORM      = ROUND(BUF [ 1 ], 4),
             WORKHOURS = REC.WORKDAY_SUMM,
             SUMPAY    = BUF [ 1 ] * REC.WORKDAY_SUMM * BUF [ 2 ],
             PROPPAYS  = 'Районный коэффициент = ' || ROUND(BUF [ 2 ], 2)
       where S.ID = REC.PID;
      SUM_LIMIT   := 0;
      SUM_SPRAVKA := 0;
    end loop;
    for REC in (select S.*,
                       P.ID as PID,
                       P.SLCOMPCHARGESID,
                       (select X.COUNTWD from WORKCALENDARS X where X.ID = P.WORKCALENDARSID) as COUNTWD,
                       P.WORKCALENDARSID,
                       trim(LOWER(SS.CODE)) as SLCOM,
                       COALESCE((select sum(K.WHCOMP)
                                   from WORKTBL K
                                  where K.REGISTERLISTID = S.ID
                                    and K.DATETBL in (select SX.DATEWC
                                                        from WORKCALENDARS     X,
                                                             DAYSWORKCALENDARS SX
                                                       where X.ID = P.WORKCALENDARSID
                                                         and SX.WORKCALENDARSID = X.ID)) / 8,
                                0) as SUMM,
                       COALESCE((select sum(K.WHEXTRAWORKDAY) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as WORKDAY_SUMM,
                       COALESCE((select sum(K.WHEXTRANIGHT + K.WHEXTRAHOL) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as SUMX2
                
                  from REGISTERLIST  S,
                       PAYS          P,
                       SLCOMPCHARGES SS
                 where S.ID = ALLS.ID
                   and P.REGISTERLISTID = S.ID
                   and P.SHEETSID is null
                   and SS.ID = P.SLCOMPCHARGESID
                   and UPPER(SS.DESCRIPTION) = 'EXTRA2')
    loop
      update PAYS S
         set NORM      = 0,
             WORKHOURS = 0,
             SUMPAY    = 0,
             PROPPAYS  = null
       where S.ID = REC.PID;
      select COALESCE(SN.VALUE, 0)
        into SUM_SPRAVKA
        from REGISTER        R, --расчет
             ELECTCAMPAIGN   I, --избирательная камания
             FEDELECCAMP     N, --нормативный документ
             NORMSFEDEC      SN, --спецификация нормативного документа: расчет оплаты труда
             ELECTCOMMITTEE  K, --избирательная коммисия
             ELECTCOMMINCAMP KK,
             COMMITTEEMAN    CC
       where I.ID = R.ELECTCAMPAIGNID
         and N.ID = I.FEDELECCAMPID
         and SN.FEDELECCAMPID = N.ID
         and SN.NAMENORMS = 'reward' --размер дополнительной оплаты турла
         and KK.ID = R.ELECTCOMMINCAMPID
         and K.ID = KK.ELECTCOMMITTEEID
         and SN.MCIRCUIT = KK.MCIRCUIT --полномочия ОИК
         and CC.ID = REC.COMMITTEEMANID
         and R.ID = REC.REGISTERID
         and SN.POSTSID = CC.POSTSID;
    
      select case I.LEVELELCAMPAIGN
               when 'central' then
                K.DISCOEFFFED
               when 'region' then
                K.DISCOEFREG
             end
        into SUM_LIMIT
        from REGISTER       R,
             ELECTCAMPAIGN  I,
             ELECTCOMMITTEE K,
             COMMITTEEMAN   C
       where R.ID = REC.REGISTERID
         and I.ID = R.ELECTCAMPAIGNID
         and K.ID = C.ELECTCOMMITTEEID
         and C.ID = REC.COMMITTEEMANID;
         
      BUF [ 3 ] := SUM_SPRAVKA;
      BUF [ 4 ] := SUM_LIMIT;
      update PAYS S
         set NORM      = BUF [ 3 ] * 2,
             WORKHOURS = REC.SUMX2,
             SUMPAY    = BUF [ 3 ] * 2 * REC.SUMX2 * BUF [ 4 ],
             PROPPAYS  = 'Районный коэффициент = ' || ROUND(BUF [ 4 ], 2)
       where S.ID = REC.PID;
      SUM_LIMIT   := 0;
      SUM_SPRAVKA := 0;
    end loop;
    for REC in (select S.*,
                       P.ID as PID,
                       P.SLCOMPCHARGESID,
                       (select X.COUNTWD from WORKCALENDARS X where X.ID = P.WORKCALENDARSID) as COUNTWD,
                       P.WORKCALENDARSID,
                       trim(LOWER(SS.CODE)) as SLCOM,
                       COALESCE((select sum(K.WHCOMP)
                                   from WORKTBL K
                                  where K.REGISTERLISTID = S.ID
                                    and K.DATETBL in (select SX.DATEWC
                                                        from WORKCALENDARS     X,
                                                             DAYSWORKCALENDARS SX
                                                       where X.ID = P.WORKCALENDARSID
                                                         and SX.WORKCALENDARSID = X.ID)) / 8,
                                0) as SUMM,
                       COALESCE((select sum(K.WHEXTRAWORKDAY) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as WORKDAY_SUMM,
                       COALESCE((select sum(K.WHEXTRANIGHT + K.WHEXTRAHOL) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as SUMX2
                
                  from REGISTERLIST  S,
                       PAYS          P,
                       SLCOMPCHARGES SS
                 where S.ID = ALLS.ID
                   and P.REGISTERLISTID = S.ID
                   and P.SHEETSID is null
                   and SS.ID = P.SLCOMPCHARGESID
                   and UPPER(SS.DESCRIPTION) = 'SUMEXTRA12')
    loop
      update PAYS S
         set NORM      = 0,
             WORKHOURS = 0,
             SUMPAY    = 0,
             PROPPAYS  = null
       where S.ID = REC.PID;
       
      update PAYS S
         set NORM      = 0,
             WORKHOURS = REC.WORKDAY_SUMM + REC.SUMX2,
             SUMPAY    = BUF [ 1 ] * REC.WORKDAY_SUMM * BUF [ 2 ] + BUF [ 3 ] * 2 * REC.SUMX2 * BUF [ 4 ],
             PROPPAYS  = 'ДОТ за ФОВ в одинарном размере =' || ROUND(BUF [ 1 ] * REC.WORKDAY_SUMM * BUF [ 2 ], 2) 
                         || '; ДОТ за ФОВ в двойном размере = ' || ROUND(BUF [ 3 ] * REC.SUMX2 * BUF [ 4 ] * 2, 2) 
                         ||'. РК = ' || ROUND(BUF [ 4 ], 2)
       where S.ID = REC.PID;
       
    end loop;
  
    ------дот за активную работу
    for REC in (select S.*,
                       P.ID as PID,
                       P.SLCOMPCHARGESID,
                       (select X.COUNTWD from WORKCALENDARS X where X.ID = P.WORKCALENDARSID) as COUNTWD,
                       P.WORKCALENDARSID,
                       trim(LOWER(SS.CODE)) as SLCOM,
                       COALESCE((select sum(K.WHCOMP)
                                   from WORKTBL K
                                  where K.REGISTERLISTID = S.ID
                                    and K.DATETBL in (select SX.DATEWC
                                                        from WORKCALENDARS     X,
                                                             DAYSWORKCALENDARS SX
                                                       where X.ID = P.WORKCALENDARSID
                                                         and SX.WORKCALENDARSID = X.ID)) / 8,
                                0) as SUMM,
                       COALESCE((select sum(K.WHEXTRAWORKDAY) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as WORKDAY_SUMM,
                       COALESCE((select sum(K.WHEXTRANIGHT + K.WHEXTRAHOL) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as SUMX2
                
                  from REGISTERLIST  S,
                       PAYS          P,
                       SLCOMPCHARGES SS
                 where S.ID = ALLS.ID
                   and P.REGISTERLISTID = S.ID
                   and P.SHEETSID is null
                   and SS.ID = P.SLCOMPCHARGESID
                   and UPPER(SS.DESCRIPTION) = 'EXTRAA')
    loop
      update PAYS S
         set NORM      = 0,
             WORKHOURS = 0,
             SUMPAY    = 0,
             PROPPAYS  = null
       where S.ID = REC.PID;
       
      select sum(P.SUMPAY)
        into SUM_LIMIT
        from REGISTER      R,
             REGISTERLIST  L,
             PAYS          P,
             SLCOMPCHARGES C
       where R.ELECTCAMPAIGNID = (select X.ELECTCAMPAIGNID from REGISTER X where X.ID = REC.REGISTERID)
         and L.REGISTERID = R.ID
         and L.COMMITTEEMANID = REC.COMMITTEEMANID
         and P.REGISTERLISTID = L.ID
         and C.ID = P.SLCOMPCHARGESID
         and UPPER(C.DESCRIPTION) = 'SUMEXTRA12';
      update PAYS S
         set SUMPAY   = SUM_LIMIT * REC.DEPCOEFF,
             PROPPAYS = 'ДОТ за ФОВ = ' || ROUND(SUM_LIMIT, 2) || ' Ведомственный коэффициент = ' || ROUND(REC.DEPCOEFF, 2)
       where S.ID = REC.PID;
      SUM_LIMIT := 0;
    end loop;
    ---------
    for REC in (select S.*,
                       P.ID as PID,
                       P.SLCOMPCHARGESID,
                       (select X.COUNTWD from WORKCALENDARS X where X.ID = P.WORKCALENDARSID) as COUNTWD,
                       P.WORKCALENDARSID,
                       trim(LOWER(SS.CODE)) as SLCOM,
                       COALESCE((select sum(K.WHCOMP)
                                   from WORKTBL K
                                  where K.REGISTERLISTID = S.ID
                                    and K.DATETBL in (select SX.DATEWC
                                                        from WORKCALENDARS     X,
                                                             DAYSWORKCALENDARS SX
                                                       where X.ID = P.WORKCALENDARSID
                                                         and SX.WORKCALENDARSID = X.ID)) / 8,
                                0) as SUMM,
                       COALESCE((select sum(K.WHEXTRAWORKDAY) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as WORKDAY_SUMM,
                       COALESCE((select sum(round(K.WHEXTRANIGHT,2) + round(K.WHEXTRAHOL,2)) from WORKTBL K where K.REGISTERLISTID = S.ID), 0) as SUMX2
                
                  from REGISTERLIST  S,
                       PAYS          P,
                       SLCOMPCHARGES SS
                 where S.ID = ALLS.ID
                   and P.REGISTERLISTID = S.ID
                   and P.SHEETSID is null
                   and SS.ID = P.SLCOMPCHARGESID
                   and UPPER(SS.DESCRIPTION) = 'SUMALL')
    loop
      update PAYS S
         set NORM      = 0,
             WORKHOURS = 0,
             SUMPAY    = 0,
             PROPPAYS  = null
       where S.ID = REC.PID;
      select sum(round(P.SUMPAY,2))
        into SUM_LIMIT
        from REGISTERLIST  L,
             PAYS          P,
             SLCOMPCHARGES C
       where L.ID = REC.ID
         and P.REGISTERLISTID = L.ID
         and P.SLCOMPCHARGESID = C.ID
         and UPPER(C.DESCRIPTION) in ('SUMEXTRA12', 'COMPENSATION', 'EXTRAA');
    
      update PAYS S set SUMPAY = SUM_LIMIT where S.ID = REC.PID;
      SUM_LIMIT := 0;
    end loop;
  end loop;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_registerlist_gen(text, bigint)
  OWNER TO magicbox;
