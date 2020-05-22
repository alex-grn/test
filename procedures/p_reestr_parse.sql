CREATE OR REPLACE FUNCTION public.p_reestr_parse (
  id bigint,
  uid bigint
)
RETURNS text AS
$body$
 declare
  NID                      BIGINT = ID;											--ID последней записи таблицы "–еестры получателей"
  NUSERID                  BIGINT = UID;
  NLEVEL                   integer[ ];										--идентификаци€ Ѕорна
  NLID                     BIGINT;  											--”ровень доступа									
  NZAP                     INT;
  BENEFITSPACKETS_ID       BIGINT;												--ID последней записи таблицы "ѕакеты реестров"
  FILE_XML                 XML;
  FILE_TEXT                TEXT;
  sql                      TEXT;
  DOW                      record;
  REC                      record;
  DR                       record;
  BENEFITSRECIPIENTS_ID    BIGINT;
  BENEFITCHILD_ID		   BIGINT;
  OLDBENEFITID             BIGINT;
  BENEFITID                BIGINT;
  NRN                      BIGINT;
  TRETURN                  TEXT;
  ERR_TABLE                TEXT;
  ERR_STATE                TEXT;
  NTEMP                    numeric = 0;
  SNODE                    TEXT;
  FL					   BIGINT = 0;											-- 1-ошибка, но грузим, 2-ошибка не грузим
  SERRORS				   TEXT='';												--ѕеременна€ дл€ накоплени€ ошибок при загрузке реестра
  SMESSAGE_ERR			   TEXT='';												--—ообщение об ошибке
  SERR_TABLENAME           TEXT;
  SDETAIL_ERR              TEXT;
  SINSTIGATOR              TEXT;
  SSQL_STATE               TEXT;
  SDOCTYPE                 TEXT;
  temp                     text; --переменна€ дл€ отладки
  REMARK_ID				   BIGINT;
  buff					   numeric[];
begin

  --получаем ID последней строки пакета реестра
  select P.ID into BENEFITSPACKETS_ID from BENEFICIARIESREGISTERS B, BENEFITSPACKETS P where P.ID = B.BENEFITSPACKETSID and B.ID = NID;
  if BENEFITSPACKETS_ID is null then
    TRETURN := '–еестр не определен!';
    delete from BENEFICIARIESREGISTERS S where S.ID = NID;
    return TRETURN;
  end if;
  
  if (select count(S.ID)
        from SENDERS S, USERS U
       where U.ID = NUSERID
         and S.USERID = U.ID
         and S.BANLOAD = true) > 0 and TO_NUMBER(TO_CHAR(NOW(), 'dd'), '99') > 11
  then
    TRETURN := '«агрузка реестра после 11 числа текущего мес€ца запрещена!';
    delete from BENEFICIARIESREGISTERS S where S.ID = NID;
    return TRETURN;
  end if;
  TRETURN := '«агрузка успешно завершена';
  if   TO_NUMBER(TO_CHAR(NOW(), 'dd'), '99') >= 11
        	or (select s.repmonth from BENEFITSPACKETS s where s.id = BENEFITSPACKETS_ID)::numeric != TO_NUMBER(TO_CHAR(NOW() - interval '1 month', 'mm'), '99') 
               or (select s.repyear from BENEFITSPACKETS s where s.id = BENEFITSPACKETS_ID) != TO_NUMBER(TO_CHAR(NOW() - interval '1 month', 'yyyy'), '9999')	
  			then
    	--мац 3684 добавили после 1-ого числа, ставим нарушение сроков
    			update BENEFITSPACKETS S set TERMSVIOLATION = true where S.ID = BENEFITSPACKETS_ID;
       else update BENEFITSPACKETS S set TERMSVIOLATION = false where S.ID = BENEFITSPACKETS_ID;  
  end if;
  select S.LEVACCESSID into NLID from USERS S where S.ID = NUSERID;
  update BENEFICIARIESREGISTERS S set STATUS = '01', LID = NLID where S.ID = NID;
  if (select S.STATUSPACK
        from BENEFITSPACKETS S, BENEFICIARIESREGISTERS R
       where S.ID = R.BENEFITSPACKETSID
         and R.ID = NID) = '01'
  then
    TRETURN = '«агрузка реестра не возможна, обратитесь к своему куратору в ‘едеральную службу по труду и зан€тости';
    delete from BENEFICIARIESREGISTERS S where S.ID = NID;
    return TRETURN;
  end if;
  begin
    select P_SYSTEM_FILE_TO_TEXT(CONVERT(F.BFILE, 'WIN1251', 'UTF8')) into FILE_TEXT from FILEBUFFER F where F.ID = (select max(F2.ID) from FILEBUFFER F2 where F2.CID = NID);
    --  delete from filebuffer f where f.cid = nID;
    if FILE_TEXT is null
    then
      delete from BENEFICIARIESREGISTERS S where S.ID = NID;
      TRETURN = 'ќшибка: ‘айл реестра отсутствует.';
      raise
        using MESSAGE = 'ќшибка: ‘айл реестра отсутствует.';
      return TRETURN;
    end if;
    begin
      FILE_XML = cast(replace(FILE_TEXT, 'xmlns', 'name') as XML);
    exception
      when others then
        delete from BENEFICIARIESREGISTERS S where S.ID = NID;
        TRETURN = 'ќшибка: Ќекорректна€ структура XML-файла.';
        raise
          using MESSAGE = 'ќшибка: Ќекорректна€ структура XML-файла.';
        return TRETURN;
    end;
    if (select cast((xpath('name(/*)', file_xml))[1] as text)) not like 'benefit%' then raise using message = '‘ормат загружаемого реестра не соответствует. –еестр не загружен!'; end if;
  exception
    when others then
      GET STACKED DIAGNOSTICS ERR_STATE = RETURNED_SQLSTATE, ERR_TABLE = TABLE_NAME, TRETURN = MESSAGE_TEXT;
       delete from BENEFICIARIESREGISTERS s where s.id = NID; /*raise using message = tRETURN;*/
      return TRETURN;
  end;
  sql = 'CREATE TEMPORARY TABLE file_imp (
               stable       character varying,
                 sort       bigserial,
                 nzap       integer,
                 level      integer,
                 flag       integer,
                 col1       text,
                 col2       text,
                 col3       text,
                 col4       text,
                 col5       text,
                 col6       text,
                 col7       text,
                 col8       text,
                 col9       text,
                 col10      text,
                 col11      text,
                 col12      text,
                 col13      text
                 ) 
                 WITH (oids = false) ON COMMIT DROP;';
  execute sql;

  sql = 'CREATE INDEX ir_file_imp_fd ON file_imp USING btree (stable, level);';
  execute sql;

--  sql = 'CREATE UNIQUE INDEX ir_file_imp_fd2 ON file_imp USING btree (nzap,sort);';
--  execute sql;

   begin
   NLEVEL[1]:=0;
   NLEVEL[2]:=0;
   NLEVEL[3]:=0;
   NLEVEL[4]:=0;
   NLEVEL[5]:=0;
   NLEVEL[6]:=0;
   NLEVEL := p_reestr_parse_xml(file_xml, NID, NLEVEL);
   exception when others then
   GET STACKED DIAGNOSTICS   err_state = RETURNED_SQLSTATE,
      						 err_table = TABLE_NAME,
      						 tRETURN   = MESSAGE_TEXT;
    delete from BENEFICIARIESREGISTERS s where s.id = NID; 
    return tRETURN;
    end;

perform p_system_exception(1,'parse xml end '||nlevel[1]||' '||nlevel[2]||' '||nlevel[3]||' '||nlevel[4]||' '||nlevel[5]||' '||nlevel[6]);          
    
    --проверка на ошибки внутри процедуры p_reestr_parse_xml
FOR REC in (select S.COL1 from FILE_IMP S where s.stable = 'ERRORS')
loop
	update BENEFICIARIESREGISTERS s set wrongloading = COALESCE(wrongloading,'')||chr(13)||rec.col1, status = '02' where s.id = NID;
    update BENEFITSPACKETS S set STATUSPACK  = '03' where S.ID = BENEFITSPACKETS_ID; --статус ошибка в пакетах реестра
    FL:=1;
end loop;
if FL = 1 then
	update BENEFICIARIESREGISTERS s set wrongloading = ltrim(wrongloading,chr(13)) where s.id = NID;
    tRETURN:='ќбнаружены ошибки при загрузке!';
    return tRETURN;
end if;
FL:=0;
--  
    select lower(cast((xpath('name(/*)', file_xml))[1] as text)) into sNODE;
   begin
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
   if SNODE = 'benefit07' then
    --select max(s.id) into benefitID from benefit07 s;
    --for REC in (select S.NZAP from FILE_IMP S group by S.NZAP)
    --loop
      NZAP := -1; 
      for DOW in (select * from FILE_IMP F order by F.NZAP, F.SORT)
      loop
        if NZAP <> DOW.NZAP then
          insert into BENEFIT07 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT07.ID into BENEFITID;
          NZAP = DOW.NZAP;
        end if;
        dow.col1:= nullif(dow.col1,'');
        dow.col2:= nullif(dow.col2,'');
        dow.col3:= nullif(dow.col3,'');
        dow.col4:= nullif(dow.col4,'');
        dow.col5:= nullif(dow.col5,'');
        dow.col6:= nullif(dow.col6,'');
        dow.col7:= nullif(dow.col7,'');
        dow.col8:= nullif(dow.col8,'');
        dow.col9:= nullif(dow.col9,'');
        dow.col10:= nullif(dow.col10,'');
        dow.col11:= nullif(dow.col11,'');
        dow.col12:= nullif(dow.col12,'');
        dow.col13:= nullif(dow.col13,'');
        if DOW.STABLE = 'BENEFITSRECIPIENTS'
        then
          --проверка 
          begin
            select p.name into SDOCTYPE from PERSONDOCUMENTDIR p where p.id = DOW.col9::bigint;
            temp := ' ‘»ќ: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col10::text,'')||' '||COALESCE(dow.col11::text,''); --берем данные на случай если возникнет ошибка
            select S.ID
              into STRICT BENEFITSRECIPIENTS_ID
              from BENEFITSRECIPIENTS S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and trim(S.PERSONDOCUMENTNUMBER) = trim(DOW.COL11)
               and trim(S.PERSONDOCUMENTSERIES) = trim(DOW.COL10);
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по получателю пособи€ (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, удостовер€ющего личность, не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --
              begin
               insert into BENEFITSRECIPIENTS
                (UID,
                 LID,
                 LASTNAME,
                 FIRSTNAME,
                 PATRONYMIC,
                 CITIZENSHIP,
                 SNILS,
                 RECIPIENTSDATEBIRTH,
                 RECIPIENTSCATEGORIESDIRID,
                 RECIPIENTADDRESS,
                 PERSONDOCUMENTTYPEID,
                 PERSONDOCUMENTSERIES,
                 PERSONDOCUMENTNUMBER,
                 PERSONDOCUMENTDATE)
               values
                (NUSERID, NLID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL7, DOW.COL8, DOW.COL5 ::date, DOW.COL4 ::BIGINT, DOW.COL6, DOW.COL9 ::BIGINT, DOW.COL10, DOW.COL11, DOW.COL12 ::date)
                returning BENEFITSRECIPIENTS.ID into BENEFITSRECIPIENTS_ID;
/*исключени€*/     exception when others then
                        		  GET STACKED DIAGNOSTICS  
   /*копим ошибки*/               SMESSAGE_ERR = MESSAGE_TEXT,
                                  SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                                  SERR_TABLENAME = TABLE_NAME,
                                  SSQL_STATE = RETURNED_SQLSTATE; 
                                  FL:=2; 
                                  IF SSQL_STATE = '23505' THEN
                                    BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                                    SELECT 'в базе данных ‘»ќ ребенка: '||
                                           COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                           COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                                      into SINSTIGATOR
                                      FROM BENEFITCHILD B
                                     WHERE B.ID = BENEFITCHILD_ID;
                                  END IF;
                                  SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
                   end;
              --
            when too_many_rows then 
                GET STACKED DIAGNOSTICS 
                SMESSAGE_ERR = MESSAGE_TEXT;
                FL:=2; 
                select string_agg(' ‘»ќ ребенка: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                  COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                  COALESCE(s.docbirthchildserial,'')||' '||COALESCE(s.docbirthchildnumber,''),';')
                  into SINSTIGATOR 
                  from BENEFITCHILD s,
                       CERTIFICATEBIRTHDIR p
                 where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                   and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                   and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                   and trim(COALESCE(s.docbirthchildnumber,'')) = trim(COALESCE(dow.col7,''))
                   and trim(COALESCE(s.docbirthchildserial,'')) = trim(COALESCE(dow.col6,''))
                   and s.benefitsrecipientsid = BENEFITSRECIPIENTS_ID
                   and p.id = s.docbirthchildtypeid;
                   select p.name into SDOCTYPE from CERTIFICATEBIRTHDIR p where p.id = DOW.col5::bigint;
                   SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование ребенка получател€ пособи€:'||temp||'. ¬ базе данных: '||SINSTIGATOR||'. ¬ документе: ‘»ќ ребенка: '
                          ||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' '||SDOCTYPE||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
                      
          end;
          --update BENEFIT07 S set BENEFITSRECIPIENTSID = BENEFITSRECIPIENTS_ID where S.ID = BENEFITID;
        elsif DOW.STABLE = 'BENEFITCHILD'
        then
          begin
        --  if dow.col7 is null then fl:=2;SERRORS := SERRORS||CHR(13)|| temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' нет номера документа ребенка!'; end if;
        --  if dow.col6 is null then fl:=2;SERRORS := SERRORS||CHR(13)|| temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' нет серии документа ребенка!'; end if;
            select S.ID
              into STRICT OLDBENEFITID
              from BENEFITCHILD S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and (trim(S.DOCBIRTHCHILDNUMBER) = trim(DOW.COL7) or DOW.COL7 is null)
               and (trim(S.DOCBIRTHCHILDSERIAL) = trim(DOW.COL6) or DOW.COL6 is null)
               and s.benefitsrecipientsid = BENEFITSRECIPIENTS_ID
            ;
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||chr(13)|| 'ƒанные по ребенку (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, подтверждающего факт рождени€, дата рождени€ не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --raise using MESSAGE =BENEFITSRECIPIENTS_ID||' '||dow.col1||' '||dow.col2||' '||dow.col3||' '||dow.col7||' '||dow.col6;
              --
              begin
               insert into BENEFITCHILD
                (UID, LID, BENEFITSRECIPIENTSID, LASTNAME, FIRSTNAME, PATRONYMIC, BENEFITCHILDDATEBIRTH, DOCBIRTHCHILDTYPEID, DOCBIRTHCHILDSERIAL, DOCBIRTHCHILDNUMBER, DOCBIRTHCHILDDATE, BENEFITCHILDUMBER)
               values
                (NUSERID, NLID, BENEFITSRECIPIENTS_ID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL4 ::date, DOW.COL5 ::BIGINT, DOW.COL6, DOW.COL7, DOW.COL8 ::date, 1);
              exception when others then  
                         GET STACKED DIAGNOSTICS  
   /*копим ошибки*/      SMESSAGE_ERR = MESSAGE_TEXT,
                         SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                         SERR_TABLENAME = TABLE_NAME,
                         SSQL_STATE = RETURNED_SQLSTATE; 
                         FL:=2; 
                         IF SSQL_STATE = '23505' THEN
                           BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                           SELECT 'в базе данных ‘»ќ ребенка: '||
                                  COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                  COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                             into SINSTIGATOR
                             FROM BENEFITCHILD B
                            WHERE B.ID = BENEFITCHILD_ID;
                         END IF;
                         SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
                       end;
              select max(F.ID) into OLDBENEFITID from BENEFITCHILD F;
            when TOO_MANY_ROWS then
                     GET STACKED DIAGNOSTICS 
                     SMESSAGE_ERR = MESSAGE_TEXT;
                     FL:=2; 
                     select string_agg(' ‘»ќ ребенка: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                       COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                       COALESCE(s.docbirthchildserial,'')||' '||COALESCE(s.docbirthchildnumber,''),';')
                       into SINSTIGATOR 
                       from BENEFITCHILD s,
                            CERTIFICATEBIRTHDIR p
                      where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                        and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                        and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                        and trim(COALESCE(s.docbirthchildnumber,'')) = trim(COALESCE(dow.col7,''))
                        and trim(COALESCE(s.docbirthchildserial,'')) = trim(COALESCE(dow.col6,''))
                        and s.benefitsrecipientsid = BENEFITSRECIPIENTS_ID
                        and p.id = s.docbirthchildtypeid;
                        select p.name into SDOCTYPE from CERTIFICATEBIRTHDIR p where p.id = DOW.col5::bigint;
                        SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование ребенка получател€ пособи€:'||temp||'. ¬ базе данных: '||SINSTIGATOR||'. ¬ документе: ‘»ќ ребенка: '
                               ||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' '||SDOCTYPE||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
          end;
          --
          begin
           insert into CHILD07 (UID, LID, BENEFIT07ID, BENEFITCHILDID) values (NUSERID, NLID, BENEFITID, OLDBENEFITID);
          exception when others then  
                         GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                  SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
                       end;
          --
          select max(F.ID) into OLDBENEFITID from CHILD F;
        elsif DOW.STABLE = 'FAMILYMEMBERS'
        then
          if DOW.COL7 ::numeric <> DOW.COL6 ::numeric / DOW.COL1 ::integer
          then
            TRETURN = '—реднедушевой доход членов семьи не соответствует алгоритму расчета. –еестр не загружен!';
            delete from BENEFICIARIESREGISTERS S where S.ID = NID;
            return TRETURN;
          end if;
          begin
          insert into FAMILYMEMBERS
            (UID, LID, BENEFIT07ID, FAMILYMEMBERCOUNT, TOTALINCOME, AVERAGEINCOME, FIO, INCOMECERTIFICATENUMBER, INCOMECERTIFICATEDATE, REGISTEREDDATE07)
          values
            (NUSERID, NLID, BENEFITID, DOW.COL1 ::integer, DOW.COL6 ::numeric, DOW.COL7 ::numeric, DOW.COL4, DOW.COL2, DOW.COL3 ::date, DOW.COL5 ::date);
          exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <familymembers>';
                     end; 
         NTEMP := DOW.COL7 ::numeric;
        elsif DOW.STABLE = 'BENEFIT07PURPOSE'
        then
          if DOW.COL3 ::numeric > 1.5 * NTEMP
          then
            TRETURN = '—реднедушевой доход членов семьи должен быть не больше, чем в 1,5 раза, размера прожиточного минимума трудоспособного населени€. –еестр не загружен!';
            delete from BENEFICIARIESREGISTERS S where S.ID = NID;
            return TRETURN;
          end if;
          begin
           insert into BENEFIT07PURPOSE
            (UID, LID, BENEFIT07ID, BENEFITPURPOSENUMBER, BENEFITPURPOSEDATE, BENEFITSUBSISTENCEWORKING)
           values
            (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date, DOW.COL3 ::numeric);
          exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <purpose>';
                     end;
          --on CONFLICT (benefitpurposenumber, benefitpurposedate, cid) do update set benefitpurposenumber = dow.col1, benefitpurposedate = dow.col2::date, benefitsubsistenceworking = dow.col3::numeric;
        elsif DOW.STABLE = 'BENEFIT07PAYMENT'
        then
          /*if DOW.FLAG = 1 THEN													--проверка есть ли по человеку выплата пособий как выплата, иначе ругаемс€, но все равно грузим
          	if (SELECT COUNT(*)
                 FROM BENEFIT07PAYMENT P,
                 	  BENEFIT07 B
                WHERE B.ID = P.BENEFIT07ID
                  AND B.BENEFITSRECIPIENTSID = BENEFITSRECIPIENTSID
                  AND (P.PAYSUM IS NULL OR P.PAYSUM = 0)) < 1 then  end if;
          END IF;*/
          begin
          --проверка по суммам
                       --смотрим есть ли значени€ в возврате, доплате, удержании
                     	if (dow.col4::numeric is null or dow.col4::numeric = 0)
                     	 and (dow.col7::numeric != 0 and dow.col7::numeric is not null 
                           or dow.col10::numeric != 0 and dow.col10::numeric is not null 
                           or dow.col13::numeric != 0 and dow.col13::numeric is not null) then
                      	    --ищем записи по получателю, были ли выплаты ранее
                            IF (
                            select 1
                              from benefit07payment s,
                                   benefit07 t,
                                   child07 c
                             where s.paysum is not null
                               and t.id = s.benefit07id
                               and c.id = s.child07id
                               and c.benefitchildid = BENEFITCHILD_ID
                               and t.benefitsrecipientsid = BENEFITSRECIPIENTS_ID limit 1) = 1 THEN null;
                             ELSE  
                                SERRORS := SERRORS||CHR(13)||'ѕо '||temp||' выплат не обнаружено. –еестр загружен с предупреждением!';
                                if fl!=2 then FL:=1; end if;
                             END IF;
                        end if; 
                     --
           if (dow.col4::numeric = 0 or dow.col4 is null) and (dow.col7::numeric = 0 or dow.col7 is null) and (dow.col10::numeric = 0 or dow.col10 is null)and (dow.col13::numeric = 0 or dow.col13 is null) THEN raise using message = '¬се теги с суммами пустые!'; end if;
           insert into BENEFIT07PAYMENT
            (UID,
             LID,
             BENEFIT07ID,
             SUBSISTENCECHILD,
             PAYDATEFROM,
             PAYDATETO,
             PAYSUM,
             SURCHARGEDATEFROM,
             SURCHARGEDATETO,
             SURCHARGESUM,
             REFUNDDATEFROM,
             REFUNDDATETO,
             REFUNDSUM,
             HOLDDATEFROM,
             HOLDDATETO,
             HOLDSUM,
             CHILD07ID)
           values
            (NUSERID,
             NLID,
             BENEFITID,
             DOW.COL1 ::numeric,
             DOW.COL2 ::date,
             DOW.COL3 ::date,
             DOW.COL4 ::numeric,
             DOW.COL5 ::date,
             DOW.COL6 ::date,
             DOW.COL7 ::numeric,
             DOW.COL8 ::date,
             DOW.COL9 ::date,
             DOW.COL10 ::numeric,
             DOW.COL11 ::date,
             DOW.COL12 ::date,
             DOW.COL13 ::numeric,
             OLDBENEFITID) returning benefit07id,SUBSISTENCECHILD,SURCHARGESUM,REFUNDSUM,HOLDSUM into buff[0],buff[1],buff[2],buff[3],buff[4];
             /*if (select count(*) from BENEFIT07PAYMENT s where benefit07id = buff[0] and SUBSISTENCECHILD = buff[1] and SURCHARGESUM = buff[2] and REFUNDSUM = buff[3] and HOLDSUM = buff[4]) then
             	
             end if;*/
        exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <payment>';
                     end;
        elsif DOW.STABLE = 'REMARK'
        then
          insert into REMARK (HID, UID, LID) values (null, NUSERID, NLID);
          update REMARK S
             set NOTE                 = DOW.COL1,
                 BENEFITSRECIPIENTSID =
                 BENEFITSRECIPIENTS_ID,
                 BENEFITSTYPEDIRID   =
                  NRN,
                 BENEFITSPACKETSID   =
                 (select X.ID
                    from BENEFITSPACKETS X, BENEFICIARIESREGISTERS X1
                   where X1.BENEFITSPACKETSID = X.ID
                     and X1.ID =  NRN)
           where S.ID = (select max(X.ID) from REMARK X);
          update BENEFIT07 S
             set REMARKID =
                 (select max(S.ID) from REMARK S)
           where S.ID = BENEFITID;
        end if;
      end loop;
    --end loop;
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
   elsif sNODE = 'benefit01' then
   --for rec in (select S.NZAP from file_imp s group by s.NZAP) 
   --loop  
    NZAP = -1;
    for dow in (select * from file_imp f order by f.nzap,f.sort)
    loop
        if NZAP <> DOW.NZAP then
          insert into BENEFIT01 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT01.ID into BENEFITID;
          NZAP = DOW.NZAP;
          perform p_system_exception(1,'nzap = '||NZAP);          
        end if;
        dow.col1:= nullif(dow.col1,'');
        dow.col2:= nullif(dow.col2,'');
        dow.col3:= nullif(dow.col3,'');
        dow.col4:= nullif(dow.col4,'');
        dow.col5:= nullif(dow.col5,'');
        dow.col6:= nullif(dow.col6,'');
        dow.col7:= nullif(dow.col7,'');
        dow.col8:= nullif(dow.col8,'');
        dow.col9:= nullif(dow.col9,'');
        dow.col10:= nullif(dow.col10,'');
        dow.col11:= nullif(dow.col11,'');
        dow.col12:= nullif(dow.col12,'');
        dow.col13:= nullif(dow.col13,'');
                	if dow.stable = 'BENEFITSRECIPIENTS' then
                      --проверка 
                      BEGIN 
                      select p.name into SDOCTYPE from PERSONDOCUMENTDIR p where p.id = DOW.col9::bigint;
                      temp := ' ‘»ќ: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' '||SDOCTYPE||' сери€ и номер документа: '||COALESCE(dow.col10::text,'')||' '||COALESCE(dow.col11::text,''); --берем данные на случай если возникнет ошибка
                      select s.id
                        into STRICT BENEFITSRECIPIENTS_ID
                        from BENEFITSRECIPIENTS s
                       where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                         and trim(s.persondocumentnumber) = trim(COALESCE(dow.col11,''))
                         and trim(s.persondocumentseries) = trim(COALESCE(dow.col10,''));
--          perform p_system_exception(1,'nzap = '||NZAP||' finded BENEFITSRECIPIENTS');          
                      exception when no_data_found then 
                        if dow.flag = 1 then /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по получателю пособи€ (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, удостовер€ющего личность, не подтверждены). –еестр загружен с ошибкой.'; fl:=1; end if;                      
                        --
                        begin
                          insert into BENEFITSRECIPIENTS(uid,lid,lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                      	  VALUES(nUSERID,nLID,dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date) returning BENEFITSRECIPIENTS.ID into BENEFITSRECIPIENTS_ID;
   /*исключени€*/      	exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT,
                                    SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                                    SERR_TABLENAME = TABLE_NAME,
                                    SSQL_STATE = RETURNED_SQLSTATE; 
                                    FL:=2; 
                                    IF SSQL_STATE = '23505' THEN
                                       BENEFITSRECIPIENTS_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                                       SELECT 'в базе данных ‘»ќ: '||
                                              COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                              COALESCE(b.persondocumentseries,'')||' '||COALESCE(b.persondocumentnumber,'')
                                         into SINSTIGATOR
                                         FROM BENEFITSRECIPIENTS B
                                        WHERE B.ID = BENEFITSRECIPIENTS_ID;
                                    END IF;
                                    SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@Ќе соответствие данных: '||SINSTIGATOR||', в документе ';--||temp;
                           end;
                        --
                               when too_many_rows then 
                                    GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT;
                                    FL:=2;
                                    select string_agg(' ‘»ќ: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                                        COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                                        COALESCE(s.persondocumentseries,'')||' '||COALESCE(s.persondocumentnumber,''),';')
                                      into SINSTIGATOR
                                      from BENEFITSRECIPIENTS s,
                                           PERSONDOCUMENTDIR p
                                     where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                                       and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                                       and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                                       and trim(s.persondocumentnumber) = trim(COALESCE(dow.col11,''))
                                       and trim(s.persondocumentseries) = trim(COALESCE(dow.col10,''))
                                       and p.id = s.persondocumenttypeid;
--          perform p_system_exception(1,'nzap = '||NZAP||' finded BENEFITSRECIPIENTS errors');          
                                    SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование получател€ пособи€: ¬ базе данных '||SINSTIGATOR||'. ¬ документе:'||temp;     
                      end;
                        update benefit01 s set benefitsrecipientsid = BENEFITSRECIPIENTS_ID where s.id = benefitID;
                    elsif dow.stable = 'BENEFITCHILD' then
                      begin
                     if dow.col7 is null or dow.col7 = '' then fl:=2;SERRORS := SERRORS||CHR(13)||'не все сведени€ документа@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' нет номера документа ребенка!'; end if;
          			 if dow.col6 is null or dow.col6 = '' then fl:=2;SERRORS := SERRORS||CHR(13)||'не все сведени€ документа@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' нет серии документа ребенка!'; end if;
--          perform p_system_exception(1,'nzap = '||NZAP||' beg find BENEFITCHILD');          
          		     select s.id
                       into STRICT OLDbenefitID 
                       from BENEFITCHILD s
                      where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                        and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                        and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                        and (trim(COALESCE(s.docbirthchildnumber,'')) = trim(COALESCE(dow.col7,''))) 
                        and (trim(COALESCE(s.docbirthchildserial,'')) = trim(COALESCE(dow.col6,'')))
                        and s.benefitsrecipientsid = BENEFITSRECIPIENTS_ID;
--          perform p_system_exception(1,'nzap = '||NZAP||' finded BENEFITCHILD');          
                      exception when no_data_found then
                        if dow.flag = 1 then /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по ребенку (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, подтверждающего факт рождени€, дата рождени€ не подтверждены). –еестр загружен с ошибкой.'; fl:=1; end if;
                      --
                       begin
                        if dow.col9 is null or dow.col9 = '' then FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||'. ќтсутствует тег childNumber!'; end if;
                        if dow.col9::integer <=0 then FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||'. ќчередность рождени€ ребенка не может быть <=0 или пустой!'; end if;
                        insert into BENEFITCHILD(uid,lid,benefitsrecipientsid,lastname,firstname,patronymic,benefitchilddatebirth,docbirthchildtypeid,docbirthchildserial,docbirthchildnumber,docbirthchilddate,benefitchildumber)
                        values(nUSERID,nLID,BENEFITSRECIPIENTS_ID,dow.col1,dow.col2,dow.col3,dow.col4::date,dow.col5::bigint,dow.col6,dow.col7,dow.col8::date,dow.col9::integer) RETURNING BENEFITCHILD.ID INTO BENEFITCHILD_ID; select max(f.id) into OLDbenefitID from BENEFITCHILD f;
                       exception when others then  
                                     GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                  SMESSAGE_ERR = MESSAGE_TEXT,
                                     SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                                     SERR_TABLENAME = TABLE_NAME,
                                     SSQL_STATE = RETURNED_SQLSTATE; 
                                     FL:=2; 
--          perform p_system_exception(1,'nzap = '||NZAP||' find BENEFITCHILD too_many_rows');          
                                     IF SSQL_STATE = '23505' THEN
                                       BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                                       SELECT 'в базе данных ‘»ќ ребенка: '||
                                              COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                              COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                                         into SINSTIGATOR
                                         FROM BENEFITCHILD B
                                        WHERE B.ID = BENEFITCHILD_ID;
                                     END IF;
                                     SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
                       end;		
                      --  
                               when too_many_rows then 
                                    GET STACKED DIAGNOSTICS 
                                    SMESSAGE_ERR = MESSAGE_TEXT;
                                    FL:=2; 
--          perform p_system_exception(1,'nzap = '||NZAP||' find BENEFITCHILD too_many_rows');          
                                    select string_agg(' ‘»ќ ребенка: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                                      COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                                      COALESCE(s.docbirthchildserial,'')||' '||COALESCE(s.docbirthchildnumber,''),';')
                                      into SINSTIGATOR 
                                      from BENEFITCHILD s,
                                           CERTIFICATEBIRTHDIR p
                                     where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                                       and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                                       and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                                       and trim(COALESCE(s.docbirthchildnumber,'')) = trim(COALESCE(dow.col7,''))
                                       and trim(COALESCE(s.docbirthchildserial,'')) = trim(COALESCE(dow.col6,''))
                                       and s.benefitsrecipientsid = BENEFITSRECIPIENTS_ID
                                       and p.id = s.docbirthchildtypeid;
                                       select p.name into SDOCTYPE from CERTIFICATEBIRTHDIR p where p.id = DOW.col5::bigint;
--          perform p_system_exception(1,'nzap = '||NZAP||' finded BENEFITCHILD errors');          
                                       SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование ребенка получател€ пособи€:'||temp||'. ¬ базе данных: '||SINSTIGATOR||'. ¬ документе: ‘»ќ ребенка: '
                                              ||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' '||SDOCTYPE||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
                      end;
                      --
                      if FL!=2 then 
                       begin
                        insert into child(uid,lid,benefit01id,benefitchildid) values(nUSERID,nLID,benefitID,OLDbenefitID); select max(f.id) into OLDbenefitID from child f;
                       exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS :=  SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
   					   end;
                      end if;
                      --
                    elsif dow.stable = 'BENEFIT01BASIS' then
                     begin
                      insert into BENEFIT01BASIS(uid,lid,benefit01id,docchildcohabitation,registereddate,dismissalnumber,dismissaldate,docfssreg)
                      values(nUSERID,nLID,benefitID,dow.col1,dow.col2::date,dow.col3,dow.col4::date,dow.col7);
                     exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <benefitassignment>';
                     end;
                    elsif dow.stable = 'BENEFIT01PURPOSE' then 
                     begin
                      insert into BENEFIT01PURPOSE(uid,lid,benefit01id,benefitpurposenumber,benefitpurposedate)
                      values(nUSERID,nLID,benefitID,dow.col1,dow.col2::date);
                     exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <payments>';
                     end;
                    elsif dow.stable = 'BENEFIT01PAYMENT' then 
                     begin 
                     --проверка по суммам
                       --смотрим есть ли значени€ в возврате, доплате, удержании
                     	if (dow.col4::numeric is null or dow.col4::numeric = 0) and 
                     	   (dow.col7::numeric != 0 and dow.col7::numeric is not null 
                           or dow.col9::numeric != 0 and dow.col9::numeric is not null 
                           or dow.col11::numeric != 0 and dow.col11::numeric is not null) then
                        	--ищем записи по получателю, были ли выплаты ранее
                            IF (
                            select 1
                              from benefit01payment s,
                                   benefit01 t,
                                   child c
                             where s.paysum is not null
                               and t.id = s.benefit01id
                               and c.id = s.child01id
                               and c.benefitchildid = BENEFITCHILD_ID
                               and t.benefitsrecipientsid = BENEFITSRECIPIENTS_ID limit 1) = 1 THEN null;
                             ELSE    
                                SERRORS := SERRORS||CHR(13)||'ѕо '||temp||' выплат не обнаружено. –еестр загружен с предупреждением!';
                                if fl!=2 then FL:=1; end if;
                             END IF;
--          perform p_system_exception(1,'nzap = '||NZAP||' finded PAYS');          
                        end if; 
                     --
                      if (dow.col4::numeric = 0 or dow.col4 is null) and (dow.col7::numeric = 0 or dow.col7 is null) and (dow.col9::numeric = 0 or dow.col9 is null)and (dow.col11::numeric = 0 or dow.col11 is null) THEN raise using message = '¬се теги с суммами пустые!'; end if;
                      insert into BENEFIT01PAYMENT(uid,lid,benefit01id,coefficient,benefitforcoefficient,paydate,paysum,extradate,extrasum,returndate,returnsum,retentiondate,retentionsum,child01id)
                      values(nUSERID,nLID,benefitID,dow.col1::numeric,dow.col2::numeric,dow.col3,dow.col4::numeric,dow.col6,dow.col7::numeric,dow.col8,dow.col9::numeric,dow.col10,dow.col11::numeric,OLDbenefitID);
                     exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <periodpayments>';
                     end;
                    elsif dow.stable = 'REMARK' then  
                     insert into remark(hid,uid,lid,note,benefitsrecipientsid,benefitstypedirid,benefitspacketsid) 
                     values(null,nUSERID,nLID,dow.col1,BENEFITSRECIPIENTS_ID,NID,BENEFITSPACKETS_ID) RETURNING REMARK.ID INTO REMARK_ID;
                     update benefit01 s set remarkid = REMARK_ID where s.id = benefitID;
                    end if;
                end loop;
--               end loop;
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
     elsif sNODE = 'benefit02' then
--    for REC in (select S.NZAP from FILE_IMP S group by S.NZAP)
--    loop
--      insert into BENEFIT02 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT02.ID into BENEFITID;
      
      NZAP = -1;
      for DOW in (select * from FILE_IMP F order by F.NZAP, F.SORT)
      loop
        if NZAP <> DOW.NZAP then
          insert into BENEFIT02 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT02.ID into BENEFITID;
          NZAP = DOW.NZAP;
        end if;
        dow.col1:= nullif(dow.col1,'');
        dow.col2:= nullif(dow.col2,'');
        dow.col3:= nullif(dow.col3,'');
        dow.col4:= nullif(dow.col4,'');
        dow.col5:= nullif(dow.col5,'');
        dow.col6:= nullif(dow.col6,'');
        dow.col7:= nullif(dow.col7,'');
        dow.col8:= nullif(dow.col8,'');
        dow.col9:= nullif(dow.col9,'');
        dow.col10:= nullif(dow.col10,'');
        dow.col11:= nullif(dow.col11,'');
        dow.col12:= nullif(dow.col12,'');
        dow.col13:= nullif(dow.col13,'');
        if DOW.STABLE = 'BENEFITSRECIPIENTS'
        then
          --проверка 
          select p.name into SDOCTYPE from PERSONDOCUMENTDIR p where p.id = DOW.col9::bigint;
          temp := ' ‘»ќ: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col10::text,'')||' '||COALESCE(dow.col11::text,''); --берем данные на случай если возникнет ошибка
          begin
            select S.ID
              into STRICT BENEFITSRECIPIENTS_ID
              from BENEFITSRECIPIENTS S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and trim(S.PERSONDOCUMENTNUMBER) = trim(DOW.COL11)
               and trim(S.PERSONDOCUMENTSERIES) = trim(DOW.COL10);
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по получателю пособи€ (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, удостовер€ющего личность, не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --
              begin
               insert into BENEFITSRECIPIENTS
                (UID,LID,LASTNAME,FIRSTNAME,PATRONYMIC,CITIZENSHIP,SNILS,RECIPIENTSDATEBIRTH,RECIPIENTSCATEGORIESDIRID,RECIPIENTADDRESS,PERSONDOCUMENTTYPEID,PERSONDOCUMENTSERIES,PERSONDOCUMENTNUMBER,PERSONDOCUMENTDATE)
               values
                (NUSERID, NLID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL7, DOW.COL8, DOW.COL5 ::date, DOW.COL4 ::BIGINT, DOW.COL6, DOW.COL9 ::BIGINT, DOW.COL10, DOW.COL11, DOW.COL12 ::date)
                returning BENEFITSRECIPIENTS.ID into BENEFITSRECIPIENTS_ID;
/*исключени€*/     exception when others then
                        		  GET STACKED DIAGNOSTICS  
   /*копим ошибки*/               SMESSAGE_ERR = MESSAGE_TEXT,
                                  SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                                  SERR_TABLENAME = TABLE_NAME,
                                  SSQL_STATE = RETURNED_SQLSTATE; 
                                  FL:=2; 
                                  IF SSQL_STATE = '23505' THEN
                                     BENEFITSRECIPIENTS_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                                     SELECT 'в базе данных ‘»ќ: '||
                                            COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                            COALESCE(b.persondocumentseries,'')||' '||COALESCE(b.persondocumentnumber,'')
                                       into SINSTIGATOR
                                       FROM BENEFITSRECIPIENTS B
                                      WHERE B.ID = BENEFITSRECIPIENTS_ID;
                                  END IF;
                                  SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@Ќе соответствие данных: '||SINSTIGATOR||', в документе ';
                   end;
              --
            when too_many_rows then 
                    GET STACKED DIAGNOSTICS  
   /*копим ошибки*/ SMESSAGE_ERR = MESSAGE_TEXT;
                    FL:=2;
                    select string_agg(' ‘»ќ: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                        COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                        COALESCE(s.persondocumentseries,'')||' '||COALESCE(s.persondocumentnumber,''),';')
                      into SINSTIGATOR
                      from BENEFITSRECIPIENTS s,
                           PERSONDOCUMENTDIR p
                     where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                       and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                       and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                       and trim(s.persondocumentnumber) = trim(COALESCE(dow.col11,''))
                       and trim(s.persondocumentseries) = trim(COALESCE(dow.col10,''))
                       and p.id = s.persondocumenttypeid;
                    SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование получател€ пособи€: ¬ базе данных '||SINSTIGATOR||'. ¬ документе:'||temp;
          end;
          update BENEFIT02 S set BENEFITSRECIPIENTSID = BENEFITSRECIPIENTS_ID where S.ID = BENEFITID;
        elsif DOW.STABLE = 'BENEFIT01BASIS'
        then
          begin
          insert into BENEFIT02BASIS
            (UID, LID, BENEFIT02ID, DOCSZNREG, REGISTEREDDATE, DISMISSALNUMBER, DISMISSALDATE, DETAILSCERTDATE, DETAILSCERTNUM, DETAILSCERTMEDICALORG)
          values
            (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date, DOW.COL3, DOW.COL4 ::date, DOW.COL5 ::date, DOW.COL6, DOW.COL7);
          exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <benefitassignment>';
                     end;
        elsif DOW.STABLE = 'BENEFIT01PURPOSE'
        then
         begin
          insert into BENEFIT02PURPOSE (UID, LID, BENEFIT02ID, BENEFITPURPOSENUMBER, BENEFITPURPOSEDATE) values (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <payments>';
                     end;
        elsif DOW.STABLE = 'BENEFIT01PAYMENT'
        then
         begin
         --проверка по суммам
                       --смотрим есть ли значени€ в возврате, доплате, удержании
                     	if (dow.col4::numeric is null or dow.col4::numeric = 0)
                     	   and (dow.col7::numeric != 0 and dow.col7::numeric is not null 
                           or dow.col9::numeric != 0 and dow.col9::numeric is not null 
                           or dow.col11::numeric != 0 and dow.col11::numeric is not null) then
                        	--ищем записи по получателю, были ли выплаты ранее
                            IF (
                            select 1
                              from benefit02payment s,
                                   benefit02 t
                             where s.paysum is not null
                               and t.id = s.benefit02id
                               and t.benefitsrecipientsid = BENEFITSRECIPIENTS_ID limit 1) = 1 THEN null;
                             ELSE   
                                SERRORS := SERRORS||CHR(13)||'ѕо '||temp||' выплат не обнаружено. –еестр загружен с предупреждением!';
                                if fl!=2 then FL:=1; end if;
                             END IF;
                        end if; 
                     --
          if (dow.col4::numeric = 0 or dow.col4 is null) and (dow.col7::numeric = 0 or dow.col7 is null) and (dow.col9::numeric = 0 or dow.col9 is null)and (dow.col11::numeric = 0 or dow.col11 is null) THEN raise using message = '¬се теги с суммами пустые!'; end if;
          insert into BENEFIT02PAYMENT
            (UID, LID, BENEFIT02ID, COEFFICIENT, BENEFITFORCOEFFICIENT, PAYDATE, PAYSUM, BENEFIT02DATE, EXTRADATE, EXTRASUM, RETURNDATE, RETURNSUM, RETENTIONDATE, RETENTIONSUM)
          values
            (NUSERID,
             NLID,
             BENEFITID,
             DOW.COL1 ::numeric,
             DOW.COL2 ::numeric,
             DOW.COL3,
             DOW.COL4 ::numeric,
             DOW.COL5 ::date,
             DOW.COL6 ,
             DOW.COL7 ::numeric,
             DOW.COL8 ,
             DOW.COL9 ::numeric,
             DOW.COL10 ,
             DOW.COL11 ::numeric);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <periodpayments>';
                     end;
        elsif DOW.STABLE = 'REMARK'
        then
          insert into remark(hid,uid,lid,note,benefitsrecipientsid,benefitstypedirid,benefitspacketsid) 
                     values(null,nUSERID,nLID,dow.col1,BENEFITSRECIPIENTS_ID,NID,BENEFITSPACKETS_ID) RETURNING REMARK.ID INTO REMARK_ID;
                     update benefit02 s set remarkid = REMARK_ID where s.id = benefitID;
        end if;
      end loop;
--    end loop;
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ               
     elsif SNODE = 'benefit03'
  then
--    for REC in (select S.NZAP from FILE_IMP S group by S.NZAP)
--    loop
--      insert into BENEFIT03 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT03.ID into BENEFITID;

      NZAP = -1;
      for DOW in (select * from FILE_IMP F order by F.NZAP, F.SORT)
      loop
        if NZAP <> DOW.NZAP then
          insert into BENEFIT03 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT03.ID into BENEFITID;
          NZAP = DOW.NZAP;
        end if;
        dow.col1:= nullif(dow.col1,'');
        dow.col2:= nullif(dow.col2,'');
        dow.col3:= nullif(dow.col3,'');
        dow.col4:= nullif(dow.col4,'');
        dow.col5:= nullif(dow.col5,'');
        dow.col6:= nullif(dow.col6,'');
        dow.col7:= nullif(dow.col7,'');
        dow.col8:= nullif(dow.col8,'');
        dow.col9:= nullif(dow.col9,'');
        dow.col10:= nullif(dow.col10,'');
        dow.col11:= nullif(dow.col11,'');
        dow.col12:= nullif(dow.col12,'');
        dow.col13:= nullif(dow.col13,'');
        if DOW.STABLE = 'BENEFITSRECIPIENTS'
        then
          --проверка
          select p.name into SDOCTYPE from PERSONDOCUMENTDIR p where p.id = DOW.col9::bigint;
          temp := ' ‘»ќ: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col10::text,'')||' '||COALESCE(dow.col11::text,''); --берем данные на случай если возникнет ошибка 
          begin
            select S.ID
              into STRICT BENEFITSRECIPIENTS_ID
              from BENEFITSRECIPIENTS S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and trim(S.PERSONDOCUMENTNUMBER) = trim(DOW.COL11)
               and trim(S.PERSONDOCUMENTSERIES) = trim(DOW.COL10);
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по получателю пособи€ (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, удостовер€ющего личность, не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --
              begin
               insert into BENEFITSRECIPIENTS
                (UID,LID,LASTNAME,FIRSTNAME,PATRONYMIC,CITIZENSHIP,SNILS,RECIPIENTSDATEBIRTH,RECIPIENTSCATEGORIESDIRID,RECIPIENTADDRESS,PERSONDOCUMENTTYPEID,PERSONDOCUMENTSERIES,PERSONDOCUMENTNUMBER,PERSONDOCUMENTDATE)
               values
                (NUSERID, NLID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL7, DOW.COL8, DOW.COL5 ::date, DOW.COL4 ::BIGINT, DOW.COL6, DOW.COL9 ::BIGINT, DOW.COL10, DOW.COL11, DOW.COL12 ::date)
                returning BENEFITSRECIPIENTS.ID into BENEFITSRECIPIENTS_ID;
/*исключени€*/     exception when others then
                        		  GET STACKED DIAGNOSTICS  
   /*копим ошибки*/               SMESSAGE_ERR = MESSAGE_TEXT,
                                  SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                                  SERR_TABLENAME = TABLE_NAME,
                                  SSQL_STATE = RETURNED_SQLSTATE; 
                                  FL:=2; 
                                  IF SSQL_STATE = '23505' THEN
                                    BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                                    SELECT 'в базе данных ‘»ќ ребенка: '||
                                           COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                           COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                                      into SINSTIGATOR
                                      FROM BENEFITCHILD B
                                     WHERE B.ID = BENEFITCHILD_ID;
                                  END IF;
                                  SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
                   end;
              --
           when too_many_rows then 
                    GET STACKED DIAGNOSTICS  
   /*копим ошибки*/ SMESSAGE_ERR = MESSAGE_TEXT;
                    FL:=2;
                    select string_agg(' ‘»ќ: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                        COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                        COALESCE(s.persondocumentseries,'')||' '||COALESCE(s.persondocumentnumber,''),';')
                      into SINSTIGATOR
                      from BENEFITSRECIPIENTS s,
                           PERSONDOCUMENTDIR p
                     where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                       and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                       and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                       and trim(s.persondocumentnumber) = trim(COALESCE(dow.col11,''))
                       and trim(s.persondocumentseries) = trim(COALESCE(dow.col10,''))
                       and p.id = s.persondocumenttypeid;
                    SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование получател€ пособи€: ¬ базе данных '||SINSTIGATOR||'. ¬ документе:'||temp;      
          end;
          update BENEFIT03 S set BENEFITSRECIPIENTSID = BENEFITSRECIPIENTS_ID where S.ID = BENEFITID;
        elsif DOW.STABLE = 'BENEFIT01BASIS'
        then
        begin
          insert into BENEFIT03BASIS
            (UID, LID, BENEFIT03ID, REGISTEREDDATE, DISMISSALNUMBER, DISMISSALDATE, DETAILSCERTDATE, DETAILSCERTNUM, DETAILSCERTMEDICALORG)
          values
            (NUSERID, NLID, BENEFITID, DOW.COL2 ::date, DOW.COL3, DOW.COL4 ::date, DOW.COL5 ::date, DOW.COL6, DOW.COL7);
        exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <benefitassignment>';
                     end;
        elsif DOW.STABLE = 'BENEFIT01PURPOSE'
        then
         begin
          insert into BENEFIT03PURPOSE (UID, LID, BENEFIT03ID, BENEFITPURPOSENUMBER, BENEFITPURPOSEDATE) values (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <payments>';
         end;
        elsif DOW.STABLE = 'BENEFIT01PAYMENT'
        then
         begin
         --проверка по суммам
                       --смотрим есть ли значени€ в возврате, доплате, удержании
                     	if (dow.col4::numeric is null or dow.col4::numeric = 0) and
                     	    (dow.col7::numeric != 0 and dow.col7::numeric is not null 
                           or dow.col9::numeric != 0 and dow.col9::numeric is not null 
                           or dow.col11::numeric != 0 and dow.col11::numeric is not null) then
                        	--ищем записи по получателю, были ли выплаты ранее
                            IF (
                            select 1
                              from benefit03payment s,
                                   benefit03 t
                             where s.paysum is not null
                               and t.id = s.benefit03id
                               and t.benefitsrecipientsid = BENEFITSRECIPIENTS_ID limit 1) = 1 THEN null;
                             ELSE  
                                SERRORS := SERRORS||CHR(13)||'ѕо '||temp||' выплат не обнаружено. –еестр загружен с предупреждением!';
                                if fl!=2 then FL:=1; end if;
                             END IF;
                        end if; 
                     --
         if (dow.col4::numeric = 0 or dow.col4 is null) and (dow.col7::numeric = 0 or dow.col7 is null) and (dow.col9::numeric = 0 or dow.col9 is null)and (dow.col11::numeric = 0 or dow.col11 is null) THEN raise using message = '¬се теги с суммами пустые!'; end if;
          insert into BENEFIT03PAYMENT
            (UID, LID, BENEFIT03ID, COEFFICIENT, BENEFITFORCOEFFICIENT, PAYDATE, PAYSUM, EXTRADATE, EXTRASUM, RETURNDATE, RETURNSUM, RETENTIONDATE, RETENTIONSUM)
          /*date*/
          values
            (NUSERID, NLID, BENEFITID, DOW.COL1 ::numeric, DOW.COL2 ::numeric, DOW.COL3 ::date, DOW.COL4 ::numeric, DOW.COL6, DOW.COL7 ::numeric, DOW.COL8, DOW.COL9 ::numeric, DOW.COL10, DOW.COL11 ::numeric);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <periodpayments>';
                     end;
        elsif DOW.STABLE = 'REMARK'
        then
          insert into remark(hid,uid,lid,note,benefitsrecipientsid,benefitstypedirid,benefitspacketsid) 
                     values(null,nUSERID,nLID,dow.col1,BENEFITSRECIPIENTS_ID,NID,BENEFITSPACKETS_ID) RETURNING REMARK.ID INTO REMARK_ID;
                     update benefit03 s set remarkid = REMARK_ID where s.id = benefitID;
        end if;
      end loop;
--    end loop;  
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ       
     elsif SNODE = 'benefit04'
  then
--    for REC in (select S.NZAP from FILE_IMP S group by S.NZAP)
--    loop
--      insert into BENEFIT04 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT04.ID into BENEFITID;
       
      NZAP = -1;
      for DOW in (select * from FILE_IMP F order by F.NZAP, F.SORT)
      loop
        if NZAP <> DOW.NZAP then
          insert into BENEFIT04 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT04.ID into BENEFITID;
          NZAP = DOW.NZAP;
        end if;
        dow.col1:= nullif(dow.col1,'');
        dow.col2:= nullif(dow.col2,'');
        dow.col3:= nullif(dow.col3,'');
        dow.col4:= nullif(dow.col4,'');
        dow.col5:= nullif(dow.col5,'');
        dow.col6:= nullif(dow.col6,'');
        dow.col7:= nullif(dow.col7,'');
        dow.col8:= nullif(dow.col8,'');
        dow.col9:= nullif(dow.col9,'');
        dow.col10:= nullif(dow.col10,'');
        dow.col11:= nullif(dow.col11,'');
        dow.col12:= nullif(dow.col12,'');
        dow.col13:= nullif(dow.col13,'');
        if DOW.STABLE = 'BENEFITSRECIPIENTS'
        then
          --проверка
          select p.name into SDOCTYPE from PERSONDOCUMENTDIR p where p.id = DOW.col9::bigint;
          temp := ' ‘»ќ: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col10::text,'')||' '||COALESCE(dow.col11::text,''); --берем данные на случай если возникнет ошибка 
          begin
            select S.ID
              into STRICT BENEFITSRECIPIENTS_ID
              from BENEFITSRECIPIENTS S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and trim(S.PERSONDOCUMENTNUMBER) = trim(DOW.COL11)
               and trim(S.PERSONDOCUMENTSERIES) = trim(DOW.COL10);
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по получателю пособи€ (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, удостовер€ющего личность, не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --
              begin
                insert into BENEFITSRECIPIENTS
                  (UID,LID,LASTNAME,FIRSTNAME,PATRONYMIC,CITIZENSHIP,SNILS,RECIPIENTSDATEBIRTH,RECIPIENTSCATEGORIESDIRID,RECIPIENTADDRESS,PERSONDOCUMENTTYPEID,PERSONDOCUMENTSERIES,PERSONDOCUMENTNUMBER,PERSONDOCUMENTDATE)
                values
                  (NUSERID, NLID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL7, DOW.COL8, DOW.COL5 ::date, DOW.COL4 ::BIGINT, DOW.COL6, DOW.COL9 ::BIGINT, DOW.COL10, DOW.COL11, DOW.COL12 ::date)
                  returning BENEFITSRECIPIENTS.ID into BENEFITSRECIPIENTS_ID;
/*исключени€*/     exception when others then
                        		  GET STACKED DIAGNOSTICS  
   /*копим ошибки*/               SMESSAGE_ERR = MESSAGE_TEXT,
                                  SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                                  SERR_TABLENAME = TABLE_NAME,
                                  SSQL_STATE = RETURNED_SQLSTATE; 
                                  FL:=2; 
                                  IF SSQL_STATE = '23505' THEN
                                    BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                                    SELECT 'в базе данных ‘»ќ ребенка: '||
                                           COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                           COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                                      into SINSTIGATOR
                                      FROM BENEFITCHILD B
                                     WHERE B.ID = BENEFITCHILD_ID;
                                  END IF;
                                  SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
                   end;
              --
           when too_many_rows then 
                    GET STACKED DIAGNOSTICS  
   /*копим ошибки*/ SMESSAGE_ERR = MESSAGE_TEXT;
                    FL:=2;
                    select string_agg(' ‘»ќ: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                        COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                        COALESCE(s.persondocumentseries,'')||' '||COALESCE(s.persondocumentnumber,''),';')
                      into SINSTIGATOR
                      from BENEFITSRECIPIENTS s,
                           PERSONDOCUMENTDIR p
                     where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                       and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                       and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                       and trim(s.persondocumentnumber) = trim(COALESCE(dow.col11,''))
                       and trim(s.persondocumentseries) = trim(COALESCE(dow.col10,''))
                       and p.id = s.persondocumenttypeid;
                    SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование получател€ пособи€: ¬ базе данных '||SINSTIGATOR||'. ¬ документе:'||temp;       
          end;
          update BENEFIT04 S set BENEFITSRECIPIENTSID = BENEFITSRECIPIENTS_ID where S.ID = BENEFITID;
        elsif DOW.STABLE = 'BENEFITCHILD'
        then --raise using message = COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(DOW.COL3,'')||' '||COALESCE(DOW.COL7,'')||' '||COALESCE(DOW.COL6,'')||' @ '||COALESCE(BENEFITSRECIPIENTS_ID,0)::text;
          
          begin
          --if dow.col7 is null then fl:=2;SERRORS := SERRORS||CHR(13)|| temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' нет номера документа ребенка!'; end if;
          --if dow.col6 is null then fl:=2;SERRORS := SERRORS||CHR(13)|| temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' нет серии документа ребенка!'; end if;
             select S.ID
              into STRICT OLDBENEFITID
              from BENEFITCHILD S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and (trim(S.DOCBIRTHCHILDNUMBER) = trim(DOW.COL7) or DOW.COL7 is null)
               and (trim(S.DOCBIRTHCHILDSERIAL) = trim(DOW.COL6) or DOW.COL6 is null)
            and s.benefitsrecipientsid = BENEFITSRECIPIENTS_ID
            ;
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по ребенку (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, подтверждающего факт рождени€, дата рождени€ не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --
              begin
              --if dow.col9 is null then FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||'. ќтсутствует тег childNumber!'; end if;
               insert into BENEFITCHILD
                (UID, LID, BENEFITSRECIPIENTSID, LASTNAME, FIRSTNAME, PATRONYMIC, BENEFITCHILDDATEBIRTH, DOCBIRTHCHILDTYPEID, DOCBIRTHCHILDSERIAL, DOCBIRTHCHILDNUMBER, DOCBIRTHCHILDDATE, BENEFITCHILDUMBER)
               values
                (NUSERID, NLID, BENEFITSRECIPIENTS_ID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL4 ::date, DOW.COL5 ::BIGINT, DOW.COL6, DOW.COL7, DOW.COL8 ::date, DOW.COL9 ::integer);
              exception when others then  
                            GET STACKED DIAGNOSTICS  
   /*копим ошибки*/         SMESSAGE_ERR = MESSAGE_TEXT,
                            SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                            SERR_TABLENAME = TABLE_NAME,
                            SSQL_STATE = RETURNED_SQLSTATE; 
                            FL:=2; 
                            IF SSQL_STATE = '23505' THEN
                              BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                              SELECT 'в базе данных ‘»ќ ребенка: '||
                                     COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                     COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                                into SINSTIGATOR
                                FROM BENEFITCHILD B
                               WHERE B.ID = BENEFITCHILD_ID;
                            END IF;
                            SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
                       end;
              --
              select max(F.ID) into OLDBENEFITID from BENEFITCHILD F;
            when TOO_MANY_ROWS then
                    GET STACKED DIAGNOSTICS 
                    SMESSAGE_ERR = MESSAGE_TEXT;
                    FL:=2; 
                    select string_agg(' ‘»ќ ребенка: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                      COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                      COALESCE(s.docbirthchildserial,'')||' '||COALESCE(s.docbirthchildnumber,''),';')
                      into SINSTIGATOR 
                      from BENEFITCHILD s,
                           CERTIFICATEBIRTHDIR p
                     where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                       and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                       and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                       and trim(COALESCE(s.docbirthchildnumber,'')) = trim(COALESCE(dow.col7,''))
                       and trim(COALESCE(s.docbirthchildserial,'')) = trim(COALESCE(dow.col6,''))
                       and s.benefitsrecipientsid = BENEFITSRECIPIENTS_ID
                       and p.id = s.docbirthchildtypeid;
                       select p.name into SDOCTYPE from CERTIFICATEBIRTHDIR p where p.id = DOW.col5::bigint;
                       SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование ребенка получател€ пособи€:'||temp||'. ¬ базе данных: '||SINSTIGATOR||'. ¬ документе: ‘»ќ ребенка: '
                              ||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' '||SDOCTYPE||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
          end;
          --
          begin
           insert into CHILD04 (UID, LID, BENEFIT04ID, BENEFITCHILDID) values (NUSERID, NLID, BENEFITID, OLDBENEFITID);
          exception when others then  
                         GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                  SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
          end;
          --
          select max(F.ID) into OLDBENEFITID from CHILD04 F;
        elsif DOW.STABLE = 'BENEFIT01BASIS'
        then
          begin
          insert into BENEFIT04BASIS (UID, LID, BENEFIT04ID, TEMPORARYDISABILITYDOC, REGISTEREDDATE) values (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date);
          exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <benefitassignment>';
                     end;
        elsif DOW.STABLE = 'BENEFIT01PURPOSE'
        then
         begin
          insert into BENEFIT04PURPOSE (UID, LID, BENEFIT04ID, BENEFITPURPOSENUMBER, BENEFITPURPOSEDATE) values (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <payments>';
                     end;
        elsif DOW.STABLE = 'BENEFIT01PAYMENT'
        then
         begin
         --проверка по суммам
                       --смотрим есть ли значени€ в возврате, доплате, удержании
                     	if (dow.col4::numeric is null or dow.col4::numeric = 0) and 
                     	   (dow.col7::numeric != 0 and dow.col7::numeric is not null 
                           or dow.col9::numeric != 0 and dow.col9::numeric is not null 
                           or dow.col11::numeric != 0 and dow.col11::numeric is not null) then
                        	--ищем записи по получателю, были ли выплаты ранее
                            IF (
                            select 1
                              from benefit04payment s,
                                   benefit04 t,
                                   child04 c
                             where s.paysum is not null
                               and t.id = s.benefit04id
                               and c.id = s.child04id
                               and c.benefitchildid = BENEFITCHILD_ID
                               and t.benefitsrecipientsid = BENEFITSRECIPIENTS_ID limit 1) = 1 THEN null;
                               
                                SERRORS := SERRORS||CHR(13)||'ѕо '||temp||' выплат не обнаружено. –еестр загружен с предупреждением!';
                                if fl!=2 then FL:=1; end if;
                             END IF;
                        end if; 
                     --
          if (dow.col4::numeric = 0 or dow.col4 is null) and (dow.col7::numeric = 0 or dow.col7 is null) and (dow.col9::numeric = 0 or dow.col9 is null) and (dow.col11::numeric = 0 or dow.col11 is null) THEN raise using message = '¬се теги с суммами пустые!'; end if;
          insert into BENEFIT04PAYMENT
            (UID, LID, BENEFIT04ID, COEFFICIENT, BENEFITFORCOEFFICIENT, PAYDATE, PAYSUM, EXTRADATE, EXTRASUM, RETURNDATE, RETURNSUM, RETENTIONDATE, RETENTIONSUM, CHILD04ID)
          values
            (NUSERID,
             NLID,
             BENEFITID,
             DOW.COL1 ::numeric,
             DOW.COL2 ::numeric,
             DOW.COL3 ::date,
             DOW.COL4 ::numeric,
             DOW.COL6,
             DOW.COL7 ::numeric,
             DOW.COL8,
             DOW.COL9 ::numeric,
             DOW.COL10,
             DOW.COL11 ::numeric,
             OLDBENEFITID);
          exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <periodpayments>';
                     end;
        elsif DOW.STABLE = 'REMARK'
        then
          insert into remark(hid,uid,lid,note,benefitsrecipientsid,benefitstypedirid,benefitspacketsid) 
                     values(null,nUSERID,nLID,dow.col1,BENEFITSRECIPIENTS_ID,NID,BENEFITSPACKETS_ID) RETURNING REMARK.ID INTO REMARK_ID;
                     update benefit04 s set remarkid = REMARK_ID where s.id = benefitID;
        end if;
      end loop;
--    end loop;  
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ       
     elsif SNODE = 'benefit05'
  then
--    for REC in (select S.NZAP from FILE_IMP S group by S.NZAP)
--    loop
--      insert into BENEFIT05 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT05.ID into BENEFITID;

      NZAP = -1;
      for DOW in (select * from FILE_IMP F order by F.NZAP, F.SORT)
      loop
        if NZAP <> DOW.NZAP then
          insert into BENEFIT05 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT05.ID into BENEFITID;
          NZAP = DOW.NZAP;
        end if;
        dow.col1:= nullif(dow.col1,'');
        dow.col2:= nullif(dow.col2,'');
        dow.col3:= nullif(dow.col3,'');
        dow.col4:= nullif(dow.col4,'');
        dow.col5:= nullif(dow.col5,'');
        dow.col6:= nullif(dow.col6,'');
        dow.col7:= nullif(dow.col7,'');
        dow.col8:= nullif(dow.col8,'');
        dow.col9:= nullif(dow.col9,'');
        dow.col10:= nullif(dow.col10,'');
        dow.col11:= nullif(dow.col11,'');
        dow.col12:= nullif(dow.col12,'');
        dow.col13:= nullif(dow.col13,'');
        if DOW.STABLE = 'BENEFITSRECIPIENTS'
        then
          --проверка
          select p.name into SDOCTYPE from PERSONDOCUMENTDIR p where p.id = DOW.col9::bigint;
          temp := ' ‘»ќ: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col10::text,'')||' '||COALESCE(dow.col11::text,''); --берем данные на случай если возникнет ошибка 
          begin
            select S.ID
              into STRICT BENEFITSRECIPIENTS_ID
              from BENEFITSRECIPIENTS S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and trim(S.PERSONDOCUMENTNUMBER) = trim(DOW.COL11)
               and trim(S.PERSONDOCUMENTSERIES) = trim(DOW.COL10);
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по получателю пособи€ (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, удостовер€ющего личность, не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --
              begin
               insert into BENEFITSRECIPIENTS
                (UID,LID,LASTNAME,FIRSTNAME,PATRONYMIC,CITIZENSHIP,SNILS,RECIPIENTSDATEBIRTH,RECIPIENTSCATEGORIESDIRID,RECIPIENTADDRESS,PERSONDOCUMENTTYPEID,PERSONDOCUMENTSERIES,PERSONDOCUMENTNUMBER,PERSONDOCUMENTDATE)
               values
                (NUSERID, NLID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL7, DOW.COL8, DOW.COL5 ::date, DOW.COL4 ::BIGINT, DOW.COL6, DOW.COL9 ::BIGINT, DOW.COL10, DOW.COL11, DOW.COL12 ::date)
                returning BENEFITSRECIPIENTS.ID into BENEFITSRECIPIENTS_ID;
/*исключени€*/     exception when others then
                        		  GET STACKED DIAGNOSTICS  
   /*копим ошибки*/               SMESSAGE_ERR = MESSAGE_TEXT,
                                  SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                                  SERR_TABLENAME = TABLE_NAME,
                                  SSQL_STATE = RETURNED_SQLSTATE; 
                                  FL:=2; 
                                  IF SSQL_STATE = '23505' THEN
                                    BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                                    SELECT 'в базе данных ‘»ќ ребенка: '||
                                           COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                           COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                                      into SINSTIGATOR
                                      FROM BENEFITCHILD B
                                     WHERE B.ID = BENEFITCHILD_ID;
                                  END IF;
                                  SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
                   end;
              --
            when too_many_rows then 
                    GET STACKED DIAGNOSTICS  
   /*копим ошибки*/ SMESSAGE_ERR = MESSAGE_TEXT;
                    FL:=2;
                    select string_agg(' ‘»ќ: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                        COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                        COALESCE(s.persondocumentseries,'')||' '||COALESCE(s.persondocumentnumber,''),';')
                      into SINSTIGATOR
                      from BENEFITSRECIPIENTS s,
                           PERSONDOCUMENTDIR p
                     where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                       and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                       and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                       and trim(s.persondocumentnumber) = trim(COALESCE(dow.col11,''))
                       and trim(s.persondocumentseries) = trim(COALESCE(dow.col10,''))
                       and p.id = s.persondocumenttypeid;
                    SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование получател€ пособи€: ¬ базе данных '||SINSTIGATOR||'. ¬ документе:'||temp;     
          end;
          update BENEFIT05 S set BENEFITSRECIPIENTSID = BENEFITSRECIPIENTS_ID where S.ID = BENEFITID;
        elsif DOW.STABLE = 'BENEFITCHILD'
        then
          begin
          --if dow.col7 is null then fl:=2;SERRORS := SERRORS||CHR(13)||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' нет номера документа ребенка!'; end if;
          --if dow.col6 is null then fl:=2;SERRORS := SERRORS||CHR(13)||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' нет серии документа ребенка!'; end if;
             select S.ID
              into STRICT OLDBENEFITID
              from BENEFITCHILD S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and (trim(S.DOCBIRTHCHILDNUMBER) = trim(DOW.COL7) or DOW.COL7 is null)
               and (trim(S.DOCBIRTHCHILDSERIAL) = trim(DOW.COL6) or DOW.COL6 is null)
               and S.BENEFITSRECIPIENTSID = BENEFITSRECIPIENTS_ID;
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по ребенку (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, подтверждающего факт рождени€, дата рождени€ не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --
              begin
               --if dow.col9 is null then FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||'. ќтсутствует тег childNumber!'; end if;
               insert into BENEFITCHILD
                (UID, LID, BENEFITSRECIPIENTSID, LASTNAME, FIRSTNAME, PATRONYMIC, BENEFITCHILDDATEBIRTH, DOCBIRTHCHILDTYPEID, DOCBIRTHCHILDSERIAL, DOCBIRTHCHILDNUMBER, DOCBIRTHCHILDDATE, BENEFITCHILDUMBER)
               values
                (NUSERID, NLID, BENEFITSRECIPIENTS_ID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL4 ::date, DOW.COL5 ::BIGINT, DOW.COL6, DOW.COL7, DOW.COL8 ::date, DOW.COL9 ::integer);
              exception when others then  
                         GET STACKED DIAGNOSTICS  
   /*копим ошибки*/      SMESSAGE_ERR = MESSAGE_TEXT,
                         SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                         SERR_TABLENAME = TABLE_NAME,
                         SSQL_STATE = RETURNED_SQLSTATE; 
                         FL:=2; 
                         IF SSQL_STATE = '23505' THEN
                           BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                           SELECT 'в базе данных ‘»ќ ребенка: '||
                                  COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                  COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                             into SINSTIGATOR
                             FROM BENEFITCHILD B
                            WHERE B.ID = BENEFITCHILD_ID;
                         END IF;
                         SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
              end;
              --
              select max(F.ID) into OLDBENEFITID from BENEFITCHILD F;
            when TOO_MANY_ROWS then
                   GET STACKED DIAGNOSTICS 
                   SMESSAGE_ERR = MESSAGE_TEXT;
                   FL:=2; 
                   select string_agg(' ‘»ќ ребенка: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                     COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                     COALESCE(s.docbirthchildserial,'')||' '||COALESCE(s.docbirthchildnumber,''),';')
                     into SINSTIGATOR 
                     from BENEFITCHILD s,
                          CERTIFICATEBIRTHDIR p
                    where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                      and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                      and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                      and trim(COALESCE(s.docbirthchildnumber,'')) = trim(COALESCE(dow.col7,''))
                      and trim(COALESCE(s.docbirthchildserial,'')) = trim(COALESCE(dow.col6,''))
                      and s.benefitsrecipientsid = BENEFITSRECIPIENTS_ID
                      and p.id = s.docbirthchildtypeid;
                      select p.name into SDOCTYPE from CERTIFICATEBIRTHDIR p where p.id = DOW.col5::bigint;
                      SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование ребенка получател€ пособи€:'||temp||'. ¬ базе данных: '||SINSTIGATOR||'. ¬ документе: ‘»ќ ребенка: '
                             ||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' '||SDOCTYPE||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
          end;
          --
          begin
           insert into CHILD05 (UID, LID, BENEFIT05ID, BENEFITCHILDID) values (NUSERID, NLID, BENEFITID, OLDBENEFITID);
          exception when others then  
                         GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                  SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'');
          end;
          --
          select max(F.ID) into OLDBENEFITID from CHILD05 F;
        elsif DOW.STABLE = 'BENEFIT01BASIS'
        then
          begin
           insert into BENEFIT05BASIS
            (UID, LID, BENEFIT05ID, DETAILSCERTDATE, DETAILSCERTNUM, MILITARYNUMBER, MILITARYSTART, MILITARYEXPIRY, REGISTEREDDATE)
           values
            (NUSERID, NLID, BENEFITID, DOW.COL8 ::date, DOW.COL9, DOW.COL10, DOW.COL11 ::date, DOW.COL12 ::date, DOW.COL2 ::date);
          exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <benefitassignment>';
                     end;
        elsif DOW.STABLE = 'BENEFIT01PURPOSE'
        then
         begin
          insert into BENEFIT05PURPOSE (UID, LID, BENEFIT05ID, BENEFITPURPOSENUMBER, BENEFITPURPOSEDATE) values (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <payments>';
                     end;
        elsif DOW.STABLE = 'BENEFIT01PAYMENT'
        then
         begin
         --проверка по суммам
                       --смотрим есть ли значени€ в возврате, доплате, удержании
                     	if(dow.col4::numeric is null or dow.col4::numeric = 0) and 
                     	   (dow.col7::numeric != 0 and dow.col7::numeric is not null 
                           or dow.col9::numeric != 0 and dow.col9::numeric is not null 
                           or dow.col11::numeric != 0 and dow.col11::numeric is not null) then
                        	--ищем записи по получателю, были ли выплаты ранее
                            IF (
                            select 1
                              from benefit05payment s,
                                   benefit05 t,
                                   child05 c
                             where s.paysum is not null
                               and t.id = s.benefit05id
                               and c.id = s.child05id
                               and c.benefitchildid = BENEFITCHILD_ID
                               and t.benefitsrecipientsid = BENEFITSRECIPIENTS_ID) = 1 THEN null;
                             ELSE  
                                SERRORS := SERRORS||CHR(13)||'ѕо '||temp||' выплат не обнаружено. –еестр загружен с предупреждением!';
                                if fl!=2 then FL:=1; end if;
                             END IF;
                        end if; 
                     --
          insert into BENEFIT05PAYMENT
            (UID, LID, BENEFIT05ID, COEFFICIENT, BENEFITFORCOEFFICIENT, PAYDATE, PAYSUM, EXTRADATE, EXTRASUM, RETURNDATE, RETURNSUM, RETENTIONDATE, RETENTIONSUM, CHILD05ID)
          /*date*/
          values
            (NUSERID,
             NLID,
             BENEFITID,
             DOW.COL1 ::numeric,
             DOW.COL2 ::numeric,
             DOW.COL3,
             DOW.COL4 ::numeric,
             DOW.COL6 ,
             DOW.COL7 ::numeric,
             DOW.COL8 ,
             DOW.COL9 ::numeric,
             DOW.COL10 ,
             DOW.COL11 ::numeric,
             OLDBENEFITID);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <periodpayments>';
                     end;
        elsif DOW.STABLE = 'REMARK'
        then
          insert into remark(hid,uid,lid,note,benefitsrecipientsid,benefitstypedirid,benefitspacketsid) 
                     values(null,nUSERID,nLID,dow.col1,BENEFITSRECIPIENTS_ID,NID,BENEFITSPACKETS_ID) RETURNING REMARK.ID INTO REMARK_ID;
                     update benefit05 s set remarkid = REMARK_ID where s.id = benefitID;
        end if;
      end loop;
--    end loop;
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ       
     elsif SNODE = 'benefit06'
  then
--    for REC in (select S.NZAP from FILE_IMP S group by S.NZAP)
--    loop
--      insert into BENEFIT06 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT06.ID into BENEFITID;
     
      NZAP = -1;
      for DOW in (select * from FILE_IMP F order by F.NZAP, F.SORT)
      loop
        if NZAP <> DOW.NZAP then
          insert into BENEFIT06 (HID, UID, LID, BENEFITSTYPEDIRID, BENEFITSPACKETSID) values (null, NUSERID, NLID, NID, BENEFITSPACKETS_ID) returning BENEFIT06.ID into BENEFITID;
          NZAP = DOW.NZAP;
        end if;
        dow.col1:= nullif(dow.col1,'');
        dow.col2:= nullif(dow.col2,'');
        dow.col3:= nullif(dow.col3,'');
        dow.col4:= nullif(dow.col4,'');
        dow.col5:= nullif(dow.col5,'');
        dow.col6:= nullif(dow.col6,'');
        dow.col7:= nullif(dow.col7,'');
        dow.col8:= nullif(dow.col8,'');
        dow.col9:= nullif(dow.col9,'');
        dow.col10:= nullif(dow.col10,'');
        dow.col11:= nullif(dow.col11,'');
        dow.col12:= nullif(dow.col12,'');
        dow.col13:= nullif(dow.col13,'');
        if DOW.STABLE = 'BENEFITSRECIPIENTS'
        then
          --проверка
          select p.name into SDOCTYPE from PERSONDOCUMENTDIR p where p.id = DOW.col9::bigint;
          temp := ' ‘»ќ: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col10::text,'')||' '||COALESCE(dow.col11::text,''); --берем данные на случай если возникнет ошибка 
          begin
            select S.ID
              into STRICT BENEFITSRECIPIENTS_ID
              from BENEFITSRECIPIENTS S
             where trim(LOWER(COALESCE(S.LASTNAME, ''))) = LOWER(COALESCE(DOW.COL1, ''))
               and trim(LOWER(COALESCE(S.FIRSTNAME, ''))) = LOWER(COALESCE(DOW.COL2, ''))
               and trim(LOWER(COALESCE(S.PATRONYMIC, ''))) = LOWER(COALESCE(DOW.COL3, ''))
               and trim(S.PERSONDOCUMENTNUMBER) = trim(DOW.COL11)
               and trim(S.PERSONDOCUMENTSERIES) = trim(DOW.COL10);
          exception
            when NO_DATA_FOUND then
              if DOW.FLAG = 1
              then
                /*return*/SERRORS := SERRORS||CHR(13)||'ƒанные по получателю пособи€ (указываетс€ ‘амили€ »м€ ќтчество (при наличии), сери€ и номер документа, удостовер€ющего личность, не подтверждены). –еестр загружен с ошибкой.';
              fl:=1;
              end if;
              --
              begin
               insert into BENEFITSRECIPIENTS
                (UID,LID,LASTNAME,FIRSTNAME,PATRONYMIC,CITIZENSHIP,SNILS,RECIPIENTSDATEBIRTH,RECIPIENTSCATEGORIESDIRID,RECIPIENTADDRESS,PERSONDOCUMENTTYPEID,PERSONDOCUMENTSERIES,PERSONDOCUMENTNUMBER,PERSONDOCUMENTDATE)
               values
                (NUSERID, NLID, DOW.COL1, DOW.COL2, DOW.COL3, DOW.COL7, DOW.COL8, DOW.COL5 ::date, DOW.COL4 ::BIGINT, DOW.COL6, DOW.COL9 ::BIGINT, DOW.COL10, DOW.COL11, DOW.COL12 ::date)
                returning BENEFITSRECIPIENTS.ID into BENEFITSRECIPIENTS_ID;
/*исключени€*/     exception when others then
                        		  GET STACKED DIAGNOSTICS  
   /*копим ошибки*/               SMESSAGE_ERR = MESSAGE_TEXT,
                                  SDETAIL_ERR = PG_EXCEPTION_DETAIL,
                                  SERR_TABLENAME = TABLE_NAME,
                                  SSQL_STATE = RETURNED_SQLSTATE; 
                                  FL:=2; 
                                  IF SSQL_STATE = '23505' THEN
                                    BENEFITCHILD_ID:=p_tools_get_id_source_of_conflict(SERR_TABLENAME,SDETAIL_ERR);
                                    SELECT 'в базе данных ‘»ќ ребенка: '||
                                           COALESCE(b.lastname,'')||' '||COALESCE(b.firstname,'')||' '||COALESCE(b.patronymic,'')||' сери€ и номер документа: '||
                                           COALESCE(b.docbirthchildserial,'')||' '||COALESCE(b.docbirthchildnumber,'')||' очередность рождени€ - '||COALESCE(b.benefitchildumber::text,'')
                                      into SINSTIGATOR
                                      FROM BENEFITCHILD B
                                     WHERE B.ID = BENEFITCHILD_ID;
                                  END IF;
                                  SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||'. Ќе соответствие данных: '||SINSTIGATOR||', в документе ‘»ќ ребенка: '||COALESCE(dow.col1,'')||' '||COALESCE(dow.col2,'')||' '||COALESCE(dow.col3,'')||' сери€ и номер документа: '||COALESCE(dow.col6::text,'')||' '||COALESCE(dow.col7::text,'')||' очередность рождени€ - '||COALESCE(dow.col9,'');
                   end;
              --
           when too_many_rows then 
                    GET STACKED DIAGNOSTICS  
   /*копим ошибки*/ SMESSAGE_ERR = MESSAGE_TEXT;
                    FL:=2;
                    select string_agg(' ‘»ќ: '||COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||
                                        COALESCE(s.patronymic,'')||' '||COALESCE(p.name,'')||' сери€ и номер документа: '||
                                        COALESCE(s.persondocumentseries,'')||' '||COALESCE(s.persondocumentnumber,''),';')
                      into SINSTIGATOR
                      from BENEFITSRECIPIENTS s,
                           PERSONDOCUMENTDIR p
                     where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                       and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                       and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                       and trim(s.persondocumentnumber) = trim(COALESCE(dow.col11,''))
                       and trim(s.persondocumentseries) = trim(COALESCE(dow.col10,''))
                       and p.id = s.persondocumenttypeid;
                    SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@ƒублирование получател€ пособи€: ¬ базе данных '||SINSTIGATOR||'. ¬ документе:'||temp;       
          end;
          update BENEFIT06 S set BENEFITSRECIPIENTSID = BENEFITSRECIPIENTS_ID where S.ID = BENEFITID;
        elsif DOW.STABLE = 'BENEFIT01BASIS'
        then
          begin
           insert into BENEFIT06BASIS
            (UID,
             LID,
             BENEFIT06ID,
             TEMPORARYDISABILITYDOC,
             REGISTEREDDATE,
             MARRIAGECERTNUMBER,
             MARRIAGECERTDATE,
             MARRIAGEACTDATE,
             MARRIAGECERTSERIES,
             DETAILSCERTDATE,
             DETAILSCERTNUM,
             MILITARYNUMBER,
             MILITARYSTART,
             MILITARYEXPIRY)
          values
            (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date, DOW.COL3, DOW.COL4 ::date, DOW.COL5 ::date, DOW.COL6, DOW.COL8 ::date, DOW.COL9, DOW.COL10, DOW.COL11 ::date, DOW.COL12 ::date);
        exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <benefitassignment>';
                     end;
		elsif DOW.STABLE = 'BENEFIT01PURPOSE'
        then
         begin
          insert into BENEFIT06PURPOSE (UID, LID, BENEFIT06ID, BENEFITPURPOSENUMBER, BENEFITPURPOSEDATE) values (NUSERID, NLID, BENEFITID, DOW.COL1, DOW.COL2 ::date);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <payments>';
                     end;
        elsif DOW.STABLE = 'BENEFIT01PAYMENT'
        then
         begin
         --проверка по суммам
                       --смотрим есть ли значени€ в возврате, доплате, удержании
                     	if (dow.col4::numeric is null or dow.col4::numeric = 0) and 
                     	    (dow.col7::numeric != 0 and dow.col7::numeric is not null 
                           or dow.col9::numeric != 0 and dow.col9::numeric is not null 
                           or dow.col11::numeric != 0 and dow.col11::numeric is not null) then
                        	--ищем записи по получателю, были ли выплаты ранее
                            IF (
                            select 1
                              from benefit06payment s,
                                   benefit06 t
                             where s.paysum is not null
                               and t.id = s.benefit06id
                               and t.benefitsrecipientsid = BENEFITSRECIPIENTS_ID) = 1 THEN null;
                             ELSE  
                                SERRORS := SERRORS||CHR(13)||'ѕо '||temp||' выплат не обнаружено. –еестр загружен с предупреждением!'; --статус предупреждение
                                if fl!=2 then FL:=1; end if;
                             END IF;
                        end if; 
                     --
         if (dow.col4::numeric = 0 or dow.col4 is null) and (dow.col7::numeric = 0 or dow.col7 is null) and (dow.col9::numeric = 0 or dow.col9 is null)and (dow.col11::numeric = 0 or dow.col11 is null) THEN raise using message = '¬се теги с суммами пустые!'; end if;
          insert into BENEFIT06PAYMENT
            (UID, LID, BENEFIT06ID, COEFFICIENT, BENEFITFORCOEFFICIENT, PAYDATE, PAYSUM, EXTRADATE, EXTRASUM, RETURNDATE, RETURNSUM, RETENTIONDATE, RETENTIONSUM)
          /*date*/
          values
            (NUSERID, NLID, BENEFITID, DOW.COL1 ::numeric, DOW.COL2 ::numeric, DOW.COL3 ::date, DOW.COL4 ::numeric, DOW.COL6, DOW.COL7 ::numeric, DOW.COL8, DOW.COL9 ::numeric, DOW.COL10, DOW.COL11 ::numeric);
         exception when others then
                        			GET STACKED DIAGNOSTICS  
   /*копим ошибки*/                 SMESSAGE_ERR = MESSAGE_TEXT; FL:=2; SERRORS := SERRORS||CHR(13)||SMESSAGE_ERR||'@'||temp||' тег: <periodpayments>';
          end;
        elsif DOW.STABLE = 'REMARK'
        then
         insert into remark(hid,uid,lid,note,benefitsrecipientsid,benefitstypedirid,benefitspacketsid) 
                     values(null,nUSERID,nLID,dow.col1,BENEFITSRECIPIENTS_ID,NID,BENEFITSPACKETS_ID) RETURNING REMARK.ID INTO REMARK_ID;
                     update benefit06 s set remarkid = REMARK_ID where s.id = benefitID;
        end if;
      end loop;
--    end loop;
--ЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎЎ             
   end if; 
  perform p_system_exception(1,'end status fl='||fl);          

   -- откатываем транзакцию
   if fl = 2 then
     raise using message = 'Ќайдены не критические ошибки при загрузке. –еестр загружен с предупреждением!';
   end if;  

   exception when others then 
    GET STACKED DIAGNOSTICS   err_state = RETURNED_SQLSTATE,
         				err_table = TABLE_NAME,
      					tRETURN   = MESSAGE_TEXT;
    if fl <> 2 then      							
      if ERR_STATE = '23505'
      then
        for DOW in (select M.NAME
                      from METACLASS M
                     where M.CLASSNODE = 'TABLE'
                       and M.CODE = UPPER(ERR_TABLE))
        loop
          TRETURN = 'ќшибка: ƒублирование записи в таблице "' || COALESCE(DOW.NAME, ERR_TABLE) || '"';
        end loop;
      end if;
      
      update BENEFICIARIESREGISTERS S
         set WRONGLOADING = TRETURN,
             STATUS       = '02'
       where S.ID = NID;
       update BENEFITSPACKETS S set STATUSPACK  = '03' where S.ID = BENEFITSPACKETS_ID; --статус ошибка в пакетах реестра
       return TRETURN;
    end if;   
   end;

   if fl = 1 then
        update BENEFICIARIESREGISTERS S set WRONGLOADING = SERRORS, STATUS = '03' where S.ID = NID;  
        return 'Ќайдены не критические ошибки при загрузке. –еестр загружен с предупреждением!';     
   elsif fl = 2 then
        update BENEFICIARIESREGISTERS S set WRONGLOADING = SERRORS, STATUS = '02' where S.ID = NID;
        update BENEFITSPACKETS S set STATUSPACK  = '03' where S.ID = BENEFITSPACKETS_ID; --статус ошибка в пакетах реестра
        return 'Ќайдены критические ошибки при загрузке. –еестр не загружен!';
   end if;    
perform p_system_exception(1,'end');          

  
   return tRETURN;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_reestr_parse (id bigint, uid bigint)
  OWNER TO magicbox;