﻿-- Function: public.p_action_unloading_reestr_to_bank(date, bigint, bigint)

-- DROP FUNCTION public.p_action_unloading_reestr_to_bank(date, bigint, bigint);

CREATE OR REPLACE FUNCTION public.p_action_unloading_reestr_to_bank(
    fdate date,
    ident bigint,
    id bigint)
  RETURNS text AS
$BODY$
declare
  NID     BIGINT := ID;
  nIDENT  BIGINT :=ident;
  TXML    TEXT;
  CR      TEXT := CHR(13); --enter 
  TB      TEXT := CHR(9); --tab
  RC      record;
  EMP     record;
  SERRORS TEXT := '';
  FL      integer;
begin

  TXML := '<?xml version="1.0" encoding="UTF-8"?>' || CR;
  for RC in select R.ID,
                    COALESCE(S.CONTRACTNUMB, '') as CONTRACTNUMB,
                    COALESCE(R.DOCNUMB, '') as DOCNUMB,
                    COALESCE(IK.NAME, '') as NAME_IK,
                    COALESCE(IK.INN, '') as INN_IK,
                    COALESCE(RS.BANKACC, '') as BANKACC,
                    COALESCE(S.DEPARTMENT ::TEXT, '') as OTDEL,
                    COALESCE(B.BIC, '') as BIC,
                    COALESCE(R.TRANSFERSTYPE, '') as ENROLLMENT
               from REGISTERSTRANSFERS R
               left join ELECTCOMMINCAMP K
                 on K.ID = R.ELECTCOMMINCAMPID
              inner join ELECTCOMMITTEE IK
                 on IK.ID = K.ELECTCOMMITTEEID
               left join ELCMTACC RS
                 on RS.ID = R.ELCMTACCID
               left join SALARYCONTRACT S
                 on s.ID = R.SALARYCONTRACT_ID
               left join AGENTBANKS B
                 on B.ID = s.AGENTBANKSID 
              where R.ID = NID
  loop
    
    TXML := TXML || '<СчетаПК'
           -- ||' xmlns:xs="http://www.w3.org/2001/XMLSchema"'
           -- ||' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
           -- ||' xmlns="http://v8.1c.ru/edi/edi_stnd/109"'
           -- ||' xsi:type="СчетПК"'
            || ' ДатаФормирования="' || TO_CHAR(FDATE, 'yyyy-mm-dd') || '"' || ' НомерДоговора="' || RC.CONTRACTNUMB || '"'
           -- ||' ДатаДоговора="2010-11-09"'                   --???
            || ' НаименованиеОрганизации="' || RC.NAME_IK || '"' ;
   --if nullif(RC.INN_IK,'') is not null  then
   -- TXML := TXML  || ' ИНН="' || RC.INN_IK || '"';
   --end if;
   --if nullif(RC.BANKACC,'') is not null  then
   -- TXML := TXML  || ' РасчетныйСчетОрганизации="' || RC.BANKACC || '"';
   --end if;
   --if nullif(RC.BIC,'') is not null  then
   -- TXML := TXML  || ' БИК="' || RC.BIC || '"';
   --end if;
           -- ||' ИдПервичногоДокумента="'||'?'||'"'               --???
    TXML := TXML  || ' НомерРеестра="' || RC.DOCNUMB || '">' || CR;
           -- ||' ДатаРеестра="'||'?'||'">'||CR;  --Тег <СчетаПК>            ???
    
    TXML := TXML || '<ЗачислениеЗарплаты>' || CR;
  
    for EMP in (select ROW_NUMBER() OVER() as NUM,
                       COALESCE(P.SURNAME, '') as SURNAME,
                       COALESCE(P.FIRSTNAME, '') as FIRSTNAME,
                       COALESCE(P.MIDDLENAME, '') as MIDDLENAME,
                       COALESCE(A.DEPARTMENT ::TEXT, '') as OTDEL_B,
                       COALESCE(A.BRANCHOFFICE ::TEXT, '') as FILIAL_B,
                       COALESCE(A.BANKACC, '') as ACC_B,
                       COALESCE(S.SUMTRN, 0) as SUMMA
                  from SLREGTRNPR S
                 inner join COMMITTEEMAN C
                    on C.ID = S.COMMITTEEMANID
                 inner join PERSON P
                    on P.ID = C.PERSONID
                  left join PERSONACC A
                    on A.ID = S.PERSONACCID
                 where S.REGISTERSTRANSFERSID = RC.ID)
    loop
      if EMP.OTDEL_B = '' then
        FL      := 1;
        SERRORS := SERRORS || CR || EMP.SURNAME || ' ' || EMP.FIRSTNAME || ' ' || EMP.MIDDLENAME || ';';
      end if;
      TXML := TXML || TB || '<Сотрудник Нпп="' || EMP.NUM || '">' || CR || TB || TB || '<Фамилия>' || EMP.SURNAME || '</Фамилия>' || CR || TB || TB || '<Имя>' || EMP.FIRSTNAME || '</Имя>' || CR || TB || TB ||
              '<Отчество>' || EMP.MIDDLENAME || '</Отчество>' || CR || TB || TB || '<ОтделениеБанка>' || EMP.OTDEL_B || '</ОтделениеБанка>' || CR || TB || TB || '<ФилиалОтделенияБанка>' || EMP.FILIAL_B ||
              '</ФилиалОтделенияБанка>' || CR || TB || TB || '<ЛицевойСчет>' || EMP.ACC_B || '</ЛицевойСчет>' || CR || TB || TB || '<Сумма>' || ROUND(EMP.SUMMA, 2) || '</Сумма>' || CR
             --||'<КодВалюты>'||'?'||'</КодВалюты>'||CR --???
              || TB || '</Сотрудник>' || CR;
    end loop;
  
    TXML := TXML || '</ЗачислениеЗарплаты>' || CR;
    TXML := TXML || '<ВидЗачисления>' || RC.ENROLLMENT || '</ВидЗачисления>' || CR;
    TXML := TXML || '<КонтрольныеСуммы>' || CR;
  
    for EMP in (select count(*) as KOL_VO,
                       COALESCE(sum(COALESCE(S.SUMTRN, 0)), 0) as SUMMA
                  from SLREGTRNPR   S,
                       COMMITTEEMAN C,
                       PERSONACC    A
                 where S.REGISTERSTRANSFERSID = RC.ID
                   and C.ID = S.COMMITTEEMANID
                   and A.ID = S.PERSONACCID)
    loop
      TXML := TXML || TB || '<КоличествоЗаписей>' || EMP.KOL_VO || '</КоличествоЗаписей>' || CR || TB || '<СуммаИтого>' || ROUND(EMP.SUMMA, 2) || '</СуммаИтого>' || CR;
    end loop;
  
    TXML := TXML || '</КонтрольныеСуммы>' || CR;
    TXML := TXML || '</СчетаПК>' || CR;
  
    --Чистим буферную таблицу, затем закидываем XML 
    delete from FILEBUFFER where CID = nIDENT;
    insert into FILEBUFFER (CID, IDENT, FILENAME, bfile) values (nIDENT, nIDENT, COALESCE(RC.OTDEL ::TEXT, '') || COALESCE(RC.DOCNUMB, '') || 'z.xml', P_SYSTEM_FILE_FROM_TEXT(TXML));
    update REGISTERSTRANSFERS T
       set FILENAME = COALESCE(RC.OTDEL ::TEXT, '') || COALESCE(RC.DOCNUMB, '') || 'z.xml',
           FORMDATE = TO_CHAR(FDATE, 'dd.mm.yyyy')
     where T.ID = RC.ID;
  end loop;
  if FL = 1 then
    raise
      using MESSAGE = 'Не указан номер отделения банка! У физических лиц:' || CR || LTRIM(SERRORS, CR);
  end if;
  return null;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_unloading_reestr_to_bank(date, bigint, bigint)
  OWNER TO magicbox;
