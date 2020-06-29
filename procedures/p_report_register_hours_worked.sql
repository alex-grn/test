﻿-- Function: public.p_report_register_hours_worked(text, bigint, bigint, bigint, bigint)

-- DROP FUNCTION public.p_report_register_hours_worked(text, bigint, bigint, bigint, bigint);

CREATE OR REPLACE FUNCTION public.p_report_register_hours_worked(
    idlist text,
    uid bigint,
    chairman bigint,
    vicechairman bigint,
    secretary bigint)
  RETURNS text AS
$BODY$
declare
  NUID  BIGINT := UID;
  RC    record;
  PR    record;
  TSQL  TEXT;
  NMANS integer;
begin

  delete from T_REPORT_REGISTER_HOURS_WORKED T where T.UID = NUID;
  --заполняем ФИО
  for RC in (select RS.COMMITTEEMANID,
                    ROW_NUMBER() OVER(order by M.POSTBEGINDATE, P.POSTPRINT) as NUM,
                    '''' || COALESCE(PP.SURNAME, '') || ' ' || COALESCE(PP.FIRSTNAME, '') || ' ' || COALESCE(PP.MIDDLENAME, '') || '''' as FIO,
                    RS.ID as REGLIST_ID
               from REGISTER     R,
                    REGISTERLIST RS,
                    COMMITTEEMAN M,
                    PERSON       PP,
                    POSTS        P
              where R.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                and RS.REGISTERID = R.ID
                and M.ID = RS.COMMITTEEMANID
                and P.ID = M.POSTSID
                and PP.ID = M.PERSONID
              order by M.POSTBEGINDATE,
                       P.POSTPRINT)
  loop
  
    if RC.NUM = 1 then
      execute 'insert into t_report_register_hours_worked (col' || RC.NUM || ',block,uid)
                                values(' || RC.FIO || ',''fio'',' || NUID || ');';
    else
      execute 'update t_report_register_hours_worked s set col' || RC.NUM || '=' || RC.FIO || ' where s.block = ''fio'';';
    end if;
    --собираем часы 
    for PR in (select TO_CHAR(W.DATETBL, 'dd.mm.yyyy') as DATETBL,
                      trim(STRING_AGG(trim(COALESCE(TO_CHAR(W.TIMEBEGINTBL ::time, 'hh24:mi'), '') || '-' || COALESCE(TO_CHAR(W.TIMEENDTBL ::time, 'hh24:mi'), '') || chr(10) ||
                                           COALESCE((select case W.TYPEPAY
                                                             when 'K' then
                                                              'К'
                                                             when 'D' then
                                                              'Д'
                                                           end),
                                                    '') || chr(10)  || replace((W.WHCOMP + W.WHEXTRAFULL) ::TEXT, '0', ''),
                                           '-'),
                                      CHR(10)),
                           ' ' || CHR(10)) as TIMES,
                      COALESCE(T.CODE, '') as TYPE_DAY
                 from WORKTBL W
                 left join TYPEDAYS T
                   on T.ID = W.TYPEDAYID
                where W.REGISTERLISTID = RC.REGLIST_ID
                group by W.DATETBL,
                         T.CODE
                order by W.DATETBL)
    loop
    
      if RC.NUM = 1 then
        execute 'insert into t_report_register_hours_worked (col' || RC.NUM || ',block,date,type_day,UID)
                                values(''' || PR.TIMES || ''',''time'',''' || PR.DATETBL || ''',''' || PR.TYPE_DAY || ''',' || NUID || ');';
      else
        execute 'update t_report_register_hours_worked s set col' || RC.NUM || '=''' || PR.TIMES || ''' where s.block = ''time'' and s.date = ''' || PR.DATETBL || ''';';
      end if;
    
    end loop;
    --Отработано часов, всего
    for PR in (select sum((COALESCE(W.WHCOMP, 0) + COALESCE(W.WHEXTRAFULL, 0))) as SUMM from WORKTBL W where W.REGISTERLISTID = RC.REGLIST_ID)
    loop
      if RC.NUM = 1 then
        execute 'insert into t_report_register_hours_worked (col' || RC.NUM || ',block,UID)
                                values(''' || PR.SUMM || ''',''worked_hours'',' || NUID || ');';
      else
        execute 'update t_report_register_hours_worked s set col' || RC.NUM || '=''' || PR.SUMM || ''' where s.block = ''worked_hours'';';
      end if;
    end loop;
    --Для выплаты компенсации
    for PR in (select sum(COALESCE(W.WHCOMP, 0)) as SUMM from WORKTBL W where W.REGISTERLISTID = RC.REGLIST_ID)
    loop
      if RC.NUM = 1 then
        execute 'insert into t_report_register_hours_worked (col' || RC.NUM || ',block,UID)
                                values(''' || PR.SUMM || ''',''compensation'',' || NUID || ');';
      else
        execute 'update t_report_register_hours_worked s set col' || RC.NUM || '=''' || PR.SUMM || ''' where s.block = ''compensation'';';
      end if;
    end loop;
    --Для дополнительной оплаты труда (вознаграждения), всего
    for PR in (select sum(COALESCE(W.WHEXTRAFULL, 0)) as SUMM from WORKTBL W where W.REGISTERLISTID = RC.REGLIST_ID)
    loop
      if RC.NUM = 1 then
        execute 'insert into t_report_register_hours_worked (col' || RC.NUM || ',block,UID)
                                values(''' || PR.SUMM || ''',''extra_pay'',' || NUID || ');';
      else
        execute 'update t_report_register_hours_worked s set col' || RC.NUM || '=''' || PR.SUMM || ''' where s.block = ''extra_pay'';';
      end if;
    end loop;
    --в том числе:в ночное время
    for PR in (select sum(COALESCE(W.WHEXTRANIGHT, 0)) as SUMM from WORKTBL W where W.REGISTERLISTID = RC.REGLIST_ID)
    loop
      if RC.NUM = 1 then
        execute 'insert into t_report_register_hours_worked (col' || RC.NUM || ',block,UID)
                                values(''' || PR.SUMM || ''',''night_time'',' || NUID || ');';
      else
        execute 'update t_report_register_hours_worked s set col' || RC.NUM || '=''' || PR.SUMM || ''' where s.block = ''night_time'';';
      end if;
    end loop;
    --в выходные и нерабочие праздничные дни
    for PR in (select sum(COALESCE(W.WHEXTRAHOL, 0)) as SUMM from WORKTBL W where W.REGISTERLISTID = RC.REGLIST_ID)
    loop
      if RC.NUM = 1 then
        execute 'insert into t_report_register_hours_worked (col' || RC.NUM || ',block,UID)
                                values(''' || PR.SUMM || ''',''weekend_time'',' || NUID || ');';
      else
        execute 'update t_report_register_hours_worked s set col' || RC.NUM || '=''' || PR.SUMM || ''' where s.block = ''weekend_time'';';
      end if;
    end loop;
    --
    for PR in (select sum((COALESCE(W.WHEXTRAFULL, 0) - COALESCE(W.WHEXTRANIGHT, 0) - COALESCE(W.WHEXTRAHOL, 0))) as SUMM from WORKTBL W where W.REGISTERLISTID = RC.REGLIST_ID)
    loop
      if RC.NUM = 1 then
        execute 'insert into t_report_register_hours_worked (col' || RC.NUM || ',block,UID)
                                values(''' || PR.SUMM || ''',''others_days'',' || UID || ');';
      else
        execute 'update t_report_register_hours_worked s set col' || RC.NUM || '=''' || PR.SUMM || ''' where s.block = ''others_days'';';
      end if;
    end loop;
  end loop;

  return null;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_report_register_hours_worked(text, bigint, bigint, bigint, bigint)
  OWNER TO magicbox;
