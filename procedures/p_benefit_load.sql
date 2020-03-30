CREATE OR REPLACE FUNCTION public.p_benefit_load (
  nrt_regkey bigint
)
RETURNS void AS
$body$
declare
 nBENEFITSPACKETS        BIGINT;
 nfilelinks              BIGINT;
 nBENEFICIARIESREGISTERS BIGINT;
 nBENEFITSRECIPIENTS	 BIGINT;
 nPersonDocType			 BIGINT;
 nDocTypeId				 BIGINT;
 nBENEFITCHILD			 BIGINT;
 nbenefit01			 	 BIGINT;
 nCHILD					 BIGINT;
 nBENEFIT01BASIS		 BIGINT;
 nBENEFIT01PURPOSE		 BIGINT;
 spaydate				 TEXT;
 dpaydate				 date;
 nbenefit02			 	 BIGINT;
 nBENEFIT02BASIS		 BIGINT;
 nBENEFIT02PURPOSE		 BIGINT;
 nbenefit03			 	 BIGINT;
 nBENEFIT03BASIS		 BIGINT;
 nBENEFIT03PURPOSE		 BIGINT;
 nbenefit04			 	 BIGINT;
 nCHILD04				 BIGINT;
 nBENEFIT04BASIS		 BIGINT;
 nBENEFIT04PURPOSE		 BIGINT;
 nbenefit05			 	 BIGINT;
 nCHILD05				 BIGINT;
 nBENEFIT05BASIS		 BIGINT;
 nBENEFIT05PURPOSE		 BIGINT;
 nbenefit06			 	 BIGINT;
 nBENEFIT06BASIS		 BIGINT;
 nBENEFIT06PURPOSE		 BIGINT;
 nlid                    BIGINT := 6; -- права Сотрудник ЦА
 n						 INTEGER:= 0;
 s						 TEXT;
 dfilelinks				 date := to_date('01.01.1900', 'dd.mm.yyyy'); -- дата псевдо файла
 --r					     record; -- регионы
 rr						 record;
 pl					     record; -- люди
 rec 					 record; -- все, пособия, дети, получатели, документы
begin
-- псевдофайл
-- поиск
select id
  into nfilelinks
  from filelinks f
 where f.description = 'Конвертация'
   and f.filename = 'Конвертация'
   and f.size = 0
   and f.cid = 0
   and f.docdate = dfilelinks;
-- добавление
if nfilelinks is null
then
  insert into filelinks(lid, description, filename, size, docdate)
                 values(nlid, 'Конвертация', 'Конвертация', 0, dfilelinks) returning id into nfilelinks;
end if;

-- регионы
for rr in
    select sz.RT_REGKEY, count(1) ncnt from SZ_BenefitPerson sz where sz.rt_regkey = nrt_regkey/*in (99, 83, 87, 49, 79, 41, 92, 8, 53)*/ group by sz.RT_REGKEY order by 2
loop
    n:=0;
      for rec in
        select distinct null as 	TBL$PAYMENTS,
                                BEN.PERSONID as ID,
                    PAY.ID as PAYMENTID,
                    BEN.ID as BENEFITID,
                    REESTR.DATETO as "Отчетный период",
                    REESTR.DATETO,
                    to_char(REESTR.DATETO, 'YYYY')::int  as NYEAR,
                    to_char(REESTR.DATETO, 'MM')::int::text as NMONTH,
                    BEN.RT_REGKEY,-- as "№ Регион",
                    BENTYPE.ReestrNumberId,-- as "№ Реестра",
                    BENTYPE.NAME as "Наименование пособия",
                    --Получатель пособия
                    bp.dateofbirth,-- as "Дата рождения ПП",
                    bp.LNAME,-- as "Фамилия ПП",
                    bp.FNAME,-- as "Имя ПП",
                    bp.MNAME,-- as "Отчество ПП",
                    bp.address,-- as "Адрес ПП",
                    dpdt.Id as PersonDocType,--as "ID Тип док ПП",
                    dpdt.name as PersonDocType_Name,--"Тип документа ПП",
                    BP.sdoc,-- as "Серия док ПП",
                    BP.ndoc,-- as "№ док ПП",
                    BP.ddoc,-- as "Дата док ПП",
                    BEN.KatPolId,-- as "ID Категория ПП",
                    DKL.Name as "Категория ПП",
                    --Дети
                    CHILD.LNAME as CHILD_LNAME,
                    CHILD.FNAME as CHILD_FNAME,
                    CHILD.MNAME as CHILD_MNAME,
                    CHILD.Num::int as CHILD_Num,--"Очередность рождения ребенка",
                    CHILD.BDate as CHILD_BDate,--"Дата рожд",
                    CHILD.DocTypeId,-- as "ID Тип док",
                    CHILDDT.Name as DocTypeId_name,-- as "Тип док",
                    CHILD.SDoc as CHILD_SDoc,--"Серия док/рожд",
                    CHILD.NDoc as CHILD_NDoc,--"№ док/рожд",
                    CHILD.DDoc as CHILD_DDoc,--"Дата док/рожд",
                    --Основание получения
                    BA.addressdocument,-- as "Справка ФСС/ОГСЗН",
                    BA.joblessdocument,-- as "Справка о составе семьи",
                    BA.dismissionnumber,-- as "№ приказа об увольнении",
                    BA.dismissiondate,-- as "Дата приказа об увольнении",
                    BA.registereddate,-- as "Дата приема заявления ПП",
                    BA.documentregistered,-- as "Мед орг",
                    BA.documentnumber,-- as "№ справки",
                    BA.documentdate,-- as "Дата выдачи справки",
                    BA.militaryregistered,-- as "№ и наименование в/ч",
                    BA.militarynumber,-- as "№ справки из в/ч",
                    BA.militarydate,-- as "Дата выдачи справки из в/ч",
                    BA.militarybegindate,-- as "Дата начала службы",
                    BA.militaryenddate,-- as "Дата окончания службы",
                    BA.pregnancydocument,-- as "Рек справки о берем от 180 дней",
                    BA.certificateseries,-- as "Cерия cвид о браке",
                    BA.certificatenumber,-- as "№ свид о браке",
                    BA.certificatedate,-- as "Дата выдачи cвид о браке",
                    BA.marriagedate,-- as "Дата составления акта о браке",
                    --Назначение пособия
                    BEN.BNDOC as BEN_BNDOC,-- "№ решения о назначении пособия",
                    BEN.BDDOC as BEN_BDDOC,-- "Дата решения о назначении пособия",
                    PAY.COMMENT as "Примечание",
                    --Выплата пособия
                    PAY.RCOEF as PAY_RCOEF,--"Рег коэф",
                    PAY.RSUM as PAY_RSUM,--"Пособие*коэф",
                    PAY.TOTAL as PAY_TOTAL,--"Пособие*коэф2",
                    PAY.DATE as PAY_DATE,--"Дата Выплаты", --Для Пособие по беременности и родам ( реестр 2)
                    PAY.SUMTHISMONTH as PAY_SUMTHISMONTH,--"Сумма в этом месяце",
                    PAY.SUM as PAY_SUM,--"Сумма в этом месяце2",
                    -- Выплата
                    case
                      when PK.ID_PACKETTYPE > 70 then
                        PAY.INCLUDINGPAYMENT
                      else
                        case
                          when PAY.RNUM = '1' and PAY.sum > 0 and PAY.DATEFROM between REESTR.DATEFROM and REESTR.DATETO and PAY.DATETO between REESTR.DATEFROM and REESTR.DATETO then
                            PAY.sum
                          else
                            0
                        end
                    end as PAY_INCLUDINGPAYMENT,--"Выплата",
                    COALESCE(PAY.PAYDATEBEGIN, PAY.SURCHARGEDATEBEGIN, PAY.REFUNDDATEBEGIN, PAY.DETENTIONDATEBEGIN, PAY.DATEFROM) as date_from0,--"Дата с",
                    PAY.PAYDATEBEGIN as PAY_PAYDATEBEGIN,--"Дата с2",
                    case BENTYPE.ISONCE
                      when '1' then
                        null
                      else
                        COALESCE(PAY.PAYDATEEND, PAY.SURCHARGEDATEEND, PAY.REFUNDDATEEND, PAY.DETENTIONDATEEND, PAY.DATETO)
                    end as date_to0,--"Дата по",
                    PAY.PAYDATEEND as PAY_PAYDATEEND,--"Дата по2",
                    to_char(PAY.PAYDATEBEGIN, 'yyyy.mm.dd') || (case
                                                                 when PAY.PAYDATEEND is not null then
                                                                   ' - ' || to_char(PAY.PAYDATEEND, 'yyyy.mm.dd')
                                                                 else
                                                                   ''
                                                               end) as PAY_PAYPERIOD,--"Период выплаты",
                    -- Доплата
                    case
                      when PK.ID_PACKETTYPE > 70 then
                        PAY.INCLUDINGSURCHARGE
                      else
                        case
                          when PAY.RNUM = '1' and PAY.sum > 0 and (not (PAY.DATEFROM between REESTR.DATEFROM and REESTR.DATETO) or not (PAY.DATETO between REESTR.DATEFROM and REESTR.DATETO)) then
                            PAY.sum
                          else
                            0
                        end
                    end as PAY_INCLUDINGSURCHARGE,--"Доплата",
                    to_char(PAY.SURCHARGEDATEBEGIN, 'yyyy.mm.dd') || (case
                                                                       when PAY.SURCHARGEDATEEND is not null then
                                                                         ' - ' || to_char(PAY.SURCHARGEDATEEND, 'yyyy.mm.dd')
                                                                       else
                                                                         ''
                                                                     end) as PAY_INCLUDINGSURCHARGE_PERIOD,--"Период доплаты",

                    -- Возврат
                    case
                      when PK.ID_PACKETTYPE > 70 then
                        PAY.INCLUDINGREFUND
                      else
                        case
                          when PAY.RNUM = '1' and PAY.sum < 0 then
                            ABS(PAY.sum)
                        else
                          0
                        end
                    end as PAY_INCLUDINGREFUND,--"Возврат",
                    to_char(PAY.REFUNDDATEBEGIN, 'yyyy.mm.dd') || (case
                                                                     when PAY.REFUNDDATEEND is not null then
                                                                       ' - ' || to_char(PAY.REFUNDDATEEND, 'yyyy.mm.dd')
                                                                     else
                                                                       ''
                                                                   end) as PAY_INCLUDINGREFUND_PERIOD,--"Период возврата",
                    -- Удержание
                    case
                      when PK.ID_PACKETTYPE > 70 then
                        PAY.INCLUDINGDETENTION
                      else
                        case
                          when PAY.RNUM = '2' then
                            ABS(PAY.sum)
                          else
                          0
                        end
                    end as PAY_INCLUDINGDETENTION,--"Удержание",
                    to_char(PAY.DETENTIONDATEBEGIN, 'yyyy.mm.dd') || (case
                                                                        when PAY.DETENTIONDATEEND is not null then
                                                                          ' - ' || to_char(PAY.DETENTIONDATEEND, 'yyyy.mm.dd')
                                                                        else
                                                                          ''
                                                                      end) as PAY_INCLUDINGDETENTION_PERIOD,--"Период удержания",
             null ::int as CHILD_Num_exists,
             SD.ID as subjectsdir_id,
             count(1) over() as full_row
        from SZ_PAYMENT PAY
        left join SZ_BENEFIT BEN on BEN.ID = PAY.BENEFITID and BEN.RT_REGKEY = PAY.RT_REGKEY
        left join subjectsdir SD on SD.CODE = BEN.RT_REGKEY and SD.CID = 0
        	 join sz_benefitperson_tmp RECV on BEN.PERSONID = RECV.pers_id and PAY.RT_REGKEY = RECV.RT_REGKEY and RECV.regkey = RR.RT_REGKEY
             join COL_PACKET PK on PAY.ID_PACKET = PK.ID
        left join SZ_BENEFITCHILD CHILD on CHILD.ID = BEN.CHILDID and CHILD.RT_REGKEY = BEN.RT_REGKEY
        left join sz_bpdate_tmp BDATES on BDATES.BENEFIT_ID = BEN.ID and BDATES.regkey = RR.RT_REGKEY
        left join SZ_DICT_BENEFITTYPE BENTYPE on BENTYPE.ID = BEN.BENEFITTYPEID
        left join SZ_REESTR REESTR on PAY.ID_REESTR = REESTR.ID and PAY.RT_REGKEY = REESTR.RT_REGKEY
        left join SZ_BenefitPerson bp on RECV.pers_id = bp.id and recv.rt_regkey = bp.rt_regkey
        left join SZ_DICT_ChildDocType CHILDDT on CHILDDT.id = CHILD.DocTypeId
        left join SZ_DICT_PersonDocType dPDT on dPDT.id = BP.doctypeid
        left join SZ_DICT_KATPOL DKL on DKL.ID = BEN.KatPolId
        left join sz_benefitassignment ba on ba.id = ben.benefitassignmentid and ba.rt_regkey = ben.rt_regkey
       order by REESTR.DATETO, CHILD.BDate
      loop
    begin
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      n := n + 1;
      s := 'RR'||RR.RT_REGKEY||'PLP'||RR.NCNT||'REC'||REC.full_row::TEXT||'calc'||n::text;
      execute 'set application_name = '||s;
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############

        null;
      -- ######################################### СОЗДАНИЕ ПАКЕТОВ РЕЕСТРОВ #########################################
        -- заголовок пакета реестра
        -- поиск
        select id
          into nBENEFITSPACKETS
          from BENEFITSPACKETS B
         where B.subjectsdirid = rec.subjectsdir_id
           and B.repyear = rec.nyear
           and B.repmonth = rec.nmonth
           and B.cid = 0;
        -- добавление
        if nBENEFITSPACKETS is null
        then
          insert into BENEFITSPACKETS(lid, subjectsdirid, repyear, repmonth, termsviolation, statuspack)
                               values(nlid, rec.subjectsdir_id, rec.nyear, rec.nmonth, false, '02') returning id into nBENEFITSPACKETS;
          --nBENEFITSPACKETS = execute("SELECT currval('benefitspackets_id_seq')");
        end if;

        -- реестр получателя
        -- поиск
        select id
          into nBENEFICIARIESREGISTERS
          from BENEFICIARIESREGISTERS G
         where G.benefitspacketsid = nBENEFITSPACKETS
           and G.benefitstypenamedirid = rec.ReestrNumberId
           and G.cid = 0
           and G.dateform = rec.DATETO;
        -- добавление
        if nBENEFICIARIESREGISTERS is null
        then
          insert into BENEFICIARIESREGISTERS(lid, BENEFITSPACKETSid, filelinksid, BENEFITSTYPENAMEDIRID, dateform, status, wrongloading)
                                      values(nlid, nBENEFITSPACKETS, nfilelinks, rec.ReestrNumberId, rec.DATETO, '01', false) returning id into nBENEFICIARIESREGISTERS;
        end if;

      -- ######################################### СОЗДАНИЕ ПАКЕТОВ РЕЕСТРОВ #########################################

      -- ############################################ СОЗДАНИЕ ПОЛУЧАТЕЛЯ ############################################
      /*if rec.LNAME = 'Чупова' then
        raise using message := pl.id;
      end if;
      --ОШИБКА:  22226
      --ОШИБКА:  null*/
        -- поиск типа документа
        if rec.PersonDocType = 0 then
          rec.PersonDocType := 99;
        end if;
        select id
          into nPersonDocType
          from persondocumentdir pd
         where pd.code = rec.PersonDocType
           and pd.cid = 0;
        if nPersonDocType is null
        then
          raise using message := 'Тип персонального документа "'||COALESCE(nullif(rec.PersonDocType_Name,''),'<NULL>')||'", не определен!';
        end if;

        -- поиск получателя
        select id
          into nBENEFITSRECIPIENTS
          from BENEFITSRECIPIENTS BR
         where br.persondocumenttypeid = nPersonDocType
           and COALESCE(nullif(br.lastname,''),'-') = COALESCE(nullif(rec.LNAME,''),'-')
           and COALESCE(nullif(br.firstname,''),'-') = COALESCE(nullif(rec.FNAME,''),'-')
           and COALESCE(nullif(br.patronymic,''),'-') = COALESCE(nullif(rec.MNAME,''),'-')
           and COALESCE(nullif(br.persondocumentseries,''),'-') = COALESCE(nullif(rec.sdoc,''),'-')
           and COALESCE(nullif(br.persondocumentnumber,''),'-') = COALESCE(nullif(rec.ndoc,''),'-')
           and br.cid = 0;

        -- добавление получателя
        if nBENEFITSRECIPIENTS is null
        then
          insert into BENEFITSRECIPIENTS
          (lid,
           lastname,-- 'Фамилия';
           firstname,-- 'Имя';
           patronymic,-- 'Отчество';
           citizenship,-- 'Гражданство';
           recipientsdatebirth,-- 'Дата рождения';
           recipientscategoriesdirid,-- 'Категория получателя';
           recipientaddress,-- 'Адрес получателя';
           persondocumenttypeid,-- 'Вид';
           persondocumentseries,-- 'Cерия';
           persondocumentnumber,-- 'Номер';
           persondocumentdate-- 'Дата выдачи';
          )
          VALUES
          (
          nlid,
          rec.LNAME,-- as "Фамилия ПП",
          rec.FNAME,-- as "Имя ПП",
          rec.MNAME,-- as "Отчество ПП",
          1,
          to_date(rec.dateofbirth, 'yyyy-mm-dd'),-- as "Дата рождения ПП",
          rec.KatPolId,
          rec.address,-- as "Адрес ПП",
          nPersonDocType,
          rec.sdoc,-- as "Серия док ПП",
          rec.ndoc,-- as "№ док ПП",
          to_date(rec.ddoc, 'yyyy-mm-dd')-- as "Дата док ПП"
          ) returning id into nBENEFITSRECIPIENTS;
        end if;
      -- ############################################ СОЗДАНИЕ ПОЛУЧАТЕЛЯ ############################################

      -- ######################################## СОЗДАНИЕ СВЕДЕНИЙ О РЕБЕНКЕ ########################################
        if nullif(rec.CHILD_LNAME, '') is not null or
           nullif(rec.CHILD_FNAME, '') is not null or
           nullif(rec.CHILD_MNAME, '') is not null or
           /*nullif(rec.CHILD_Num, '') is not null or */rec.CHILD_Num is not null or
           nullif(rec.CHILD_BDate, '') is not null or
           rec.DocTypeId is not null or
           nullif(rec.CHILD_sdoc, '') is not null or
           nullif(rec.CHILD_ndoc, '') is not null or
           nullif(rec.CHILD_ddoc, '') is not null
        then
          -- поиск типа документа факта рождения
          if rec.DocTypeId = 0 then
            rec.DocTypeId := 99;
          end if;
          select id
            into nDocTypeId
            from certificatebirthdir pd
           where pd.code = rec.DocTypeId
             and pd.cid = 0;
          if nDocTypeId is null
          then
            raise using message := 'Тип документа, подтверждающего факт рождения, "'||COALESCE(nullif(rec.DocTypeId_name,''),'<NULL>')||'", не определен!';
          end if;
          -- поиск ребенка
          select id
            into nBENEFITCHILD
            from BENEFITCHILD BC
           where bc.benefitsrecipientsid = nBENEFITSRECIPIENTS
             and bc.docbirthchildtypeid = nDocTypeId
             and COALESCE(nullif(bc.docbirthchildserial,''),'-') = COALESCE(nullif(rec.CHILD_SDoc,''),'-')
             and COALESCE(nullif(bc.docbirthchildnumber,''),'-') = COALESCE(nullif(rec.CHILD_NDoc,''),'-')
             and bc.cid = 0;
          -- очередность рождения
          if nBENEFITCHILD is null
          then
            -- наличие очередности
            select count(1)
              into rec.CHILD_Num_exists
              from BENEFITCHILD BC
             where bc.benefitsrecipientsid = nBENEFITSRECIPIENTS
               and bc.cid = 0
               and bc.benefitchildumber = rec.CHILD_Num;
            if rec.CHILD_Num_exists <> 0
            then
              select max(benefitchildumber) + 1
                into rec.CHILD_Num
                from BENEFITCHILD BC
               where bc.benefitsrecipientsid = nBENEFITSRECIPIENTS
                 and bc.cid = 0;
            end if;
          else
            -- считываем ранее присвоенную очередность
            select benefitchildumber
              into rec.CHILD_Num
              from BENEFITCHILD BC
             where bc.cid = 0
               and bc.benefitsrecipientsid = nBENEFITSRECIPIENTS
               and bc.id = nBENEFITCHILD;
          end if;
          -- добавление получателя
          if nBENEFITCHILD is null
          then
            if nullif(rec.CHILD_LNAME,'') is not null or
               nullif(rec.CHILD_FNAME,'') is not null or
               nullif(rec.CHILD_MNAME,'') is not null or
               rec.CHILD_Num is not null or
               nullif(rec.CHILD_BDate,'') is not null or
               nDocTypeId is not null or
               nullif(rec.CHILD_sdoc,'') is not null or
               nullif(rec.CHILD_ndoc,'') is not null or
               nullif(rec.CHILD_ddoc,'') is not null
            then
              insert into BENEFITCHILD
              (lid,
               benefitsrecipientsid, -- 'Получатель пособия';
               lastname, -- 'Фамилия';
               firstname, -- 'Имя';
               patronymic, -- 'Отчество';
               benefitchildumber, -- 'Очередность рождения (усыновления)';
               benefitchilddatebirth, -- 'Дата рождения (усыновления)';
               docbirthchildtypeid, --  'Вид';
               docbirthchildserial, -- 'Серия';
               docbirthchildnumber, -- 'Номер';
               docbirthchilddate --  'Дата выдачи';
              )
              VALUES
              (
              nlid,
              nBENEFITSRECIPIENTS,
              rec.CHILD_LNAME,
              rec.CHILD_FNAME,
              rec.CHILD_MNAME,
              rec.CHILD_Num,
              to_date(rec.CHILD_BDate, 'yyyy-mm-dd'),-- as "Дата рождения ПП",
              nDocTypeId,
              rec.CHILD_sdoc,-- as "Серия док ПП",
              rec.CHILD_ndoc,-- as "№ док ПП",
              to_date(rec.CHILD_ddoc, 'yyyy-mm-dd')-- as "Дата док ПП"
              ) returning id into nBENEFITCHILD;
            end if;
          else
            update BENEFITCHILD bcu
               set lastname = COALESCE(nullif(lastname, ''), rec.CHILD_LNAME),-- 'Фамилия';
             	   firstname = COALESCE(nullif(firstname, ''), rec.CHILD_FNAME),-- 'Имя';
             	   patronymic = COALESCE(nullif(patronymic, ''), rec.CHILD_MNAME),-- 'Отчество';
             	   benefitchildumber = COALESCE(benefitchildumber, rec.CHILD_Num),-- 'Очередность рождения (усыновления)';
             	   benefitchilddatebirth = COALESCE(benefitchilddatebirth, to_date(rec.CHILD_BDate, 'yyyy-mm-dd')),-- 'Дата рождения (усыновления)';
             	   docbirthchildtypeid = COALESCE(docbirthchildtypeid, nDocTypeId),--  'Вид';
             	   docbirthchildserial = COALESCE(nullif(docbirthchildserial, ''), rec.CHILD_sdoc),-- 'Серия';
             	   docbirthchildnumber = COALESCE(nullif(docbirthchildnumber, ''), rec.CHILD_ndoc),-- 'Номер';
             	   docbirthchilddate = COALESCE(docbirthchilddate, to_date(rec.CHILD_ddoc, 'yyyy-mm-dd'))--  'Дата выдачи';
             where bcu.id = nBENEFITCHILD;
          end if;
        end if;
      -- ######################################## СОЗДАНИЕ СВЕДЕНИЙ О РЕБЕНКЕ ########################################

      -- ############################################ СОЗДАНИЕ BENEFIT01 #############################################
        if rec.ReestrNumberId = 1 then
          -- поиск записи пособия
          select id
            into nbenefit01
            from benefit01 b01
           where b01.benefitspacketsid = nBENEFITSPACKETS
             and b01.benefitsrecipientsid = nBENEFITSRECIPIENTS
             and b01.benefitstypedirid = nBENEFICIARIESREGISTERS
             and b01.cid = 0;
          -- добавелние записи пособия
          if nbenefit01 is null
          then
            insert into benefit01(lid, benefitstypedirid, BENEFITSPACKETSid, benefitsrecipientsid)
                           values(nlid, nBENEFICIARIESREGISTERS, nBENEFITSPACKETS, nBENEFITSRECIPIENTS) returning id into nbenefit01;
          end if;

          -- сведения о ребенке
          if nBENEFITCHILD is not null
          then
            insert into CHILD(lid, benefit01id, benefitchildid)values(nlid, nbenefit01, nBENEFITCHILD) returning id into nCHILD;
          else
            nCHILD := null;
          end if;

          -- назначение пособия
          select id
            into nBENEFIT01PURPOSE
            from BENEFIT01PURPOSE b01p
           where b01p.benefit01id = nbenefit01
             and (b01p.benefitpurposenumber = REC.BEN_BNDOC or (nullif(b01p.benefitpurposenumber,'') is null and nullif(REC.BEN_BNDOC,'') is null))
             and (b01p.benefitpurposedate = to_date(REC.BEN_BDDOC,'yyyy-mm-dd') or (b01p.benefitpurposedate is null and nullif(REC.BEN_BDDOC,'') is null))
             and b01p.cid = 0;
          if nBENEFIT01PURPOSE is null
          then
            insert into BENEFIT01PURPOSE(lid, benefit01id, benefitpurposenumber, benefitpurposedate)
                                  values(nlid, nbenefit01, REC.BEN_BNDOC, to_date(REC.BEN_BDDOC,'yyyy-mm-dd')) returning id into nBENEFIT01PURPOSE ;
          end if;


          -- основание получения
          if nullif(rec.addressdocument,'') is not null or
          	 nullif(rec.joblessdocument,'') is not null or
          	 nullif(rec.dismissionnumber,'') is not null or
          	 nullif(rec.dismissiondate,'') is not null or
          	 nullif(rec.registereddate,'') is not null
          then
            -- поиск записи
            select id
              into nBENEFIT01BASIS
              from BENEFIT01BASIS BB
             where bb.benefit01id = nbenefit01
               and (bb.docfssreg = rec.addressdocument or (nullif(bb.docfssreg,'') is null and nullif(rec.addressdocument,'') is null))
               and (bb.docchildcohabitation = rec.joblessdocument or (nullif(bb.docchildcohabitation,'') is null and nullif(rec.joblessdocument,'') is null))
               and (bb.dismissalnumber = rec.dismissionnumber or (nullif(bb.dismissalnumber,'') is null and nullif(rec.dismissionnumber,'') is null))
               and (bb.dismissaldate  = to_date(rec.dismissiondate, 'yyyy-mm-dd') or (bb.dismissaldate is null and nullif(rec.dismissiondate,'') is null))
               and (bb.registereddate = to_date(rec.registereddate, 'yyyy-mm-dd') or (bb.registereddate is null and nullif(rec.registereddate,'') is null))
               and bb.cid = 0;
            -- добавляем запись
            if nBENEFIT01BASIS is null
            then
              insert into BENEFIT01BASIS(lid, benefit01id, docfssreg, docchildcohabitation, dismissalnumber, dismissaldate, registereddate)
                                  values(nlid, nbenefit01, rec.addressdocument, rec.joblessdocument, rec.dismissionnumber, to_date(rec.dismissiondate, 'yyyy-mm-dd'), to_date(rec.registereddate, 'yyyy-mm-dd')) returning id into nBENEFIT01BASIS;
            end if;
          end if;

          -- Выплата пособия
          if rec.date_from0 is not null and rec.date_to0 is not null
          then
            spaydate := to_char(rec.date_from0, 'dd.mm.yyyy')||'-'||to_char(rec.date_to0, 'dd.mm.yyyy');
          else
            if REC.PAY_PAYDATEBEGIN is not null and REC.PAY_PAYDATEEND is not null
            then
              spaydate := to_char(rec.PAY_PAYDATEBEGIN, 'dd.mm.yyyy')||'-'||to_char(rec.PAY_PAYDATEEND, 'dd.mm.yyyy');
            else
              spaydate := REC.PAY_PAYPERIOD;
            end if;
          end if;

          if nullif(spaydate, '') is null or spaydate is null
          then
            spaydate := COALESCE(to_char(rec.date_from0, 'dd.mm.yyyy'), to_char(rec.PAY_PAYDATEBEGIN, 'dd.mm.yyyy'), to_char(rec.date_to0, 'dd.mm.yyyy'), to_char(rec.PAY_PAYDATEEND, 'dd.mm.yyyy'));
          end if;

		  insert into BENEFIT01PAYMENT
          (
           lid,
           benefit01id, -- 'Пособие по уходу за ребенком';
           child01id, -- 'Ребенок';
           coefficient, -- 'Районный коэффициент';
           benefitforcoefficient, -- 'Пособие с учетом коэффициента (руб.)';
           benefittotalsum, -- 'Общая сумма в отчетном месяце';
           paydate, -- 'Период выплаты';
           paysum, -- 'Сумма выплаты';
           extradate, -- 'Период доплаты';
           extrasum, -- 'Сумма доплаты';
           returndate, -- 'Период возврата';
           returnsum, -- 'Сумма возврата';
           retentiondate, -- 'Период удержания';
           retentionsum -- 'Сумма удержания';
          )
          values
          (
           nlid,
           nbenefit01,
           nCHILD,
           REC.PAY_RCOEF,
           COALESCE(REC.PAY_TOTAL, REC.PAY_RSUM),
           COALESCE(REC.PAY_SUM, REC.PAY_SUMTHISMONTH),
           spaydate,
           rec.PAY_INCLUDINGPAYMENT,
           REC.PAY_INCLUDINGSURCHARGE_PERIOD,
           REC.PAY_INCLUDINGSURCHARGE,
           REC.PAY_INCLUDINGREFUND_PERIOD,
           REC.PAY_INCLUDINGREFUND,
           REC.PAY_INCLUDINGDETENTION_PERIOD,
           REC.PAY_INCLUDINGDETENTION
          );
        end if;
      -- ############################################ СОЗДАНИЕ BENEFIT01 #############################################

      -- ############################################ СОЗДАНИЕ BENEFIT02 #############################################
        if rec.ReestrNumberId = 2 then
          -- поиск записи пособия
          select id
            into nbenefit02
            from benefit02 b02
           where b02.benefitspacketsid = nBENEFITSPACKETS
             and b02.benefitsrecipientsid = nBENEFITSRECIPIENTS
             and b02.benefitstypedirid = nBENEFICIARIESREGISTERS
             and b02.cid = 0;
          -- добавелние записи пособия
          if nbenefit02 is null
          then
            insert into benefit02(lid, benefitstypedirid, BENEFITSPACKETSid, benefitsrecipientsid)
                           values(nlid, nBENEFICIARIESREGISTERS, nBENEFITSPACKETS, nBENEFITSRECIPIENTS) returning id into nbenefit02;
          end if;

          -- назначение пособия
          select id
            into nBENEFIT02PURPOSE
            from BENEFIT02PURPOSE b02p
           where b02p.benefit02id = nbenefit02
             and (b02p.benefitpurposenumber = REC.BEN_BNDOC or (nullif(b02p.benefitpurposenumber,'') is null and nullif(REC.BEN_BNDOC,'') is null))
             and (b02p.benefitpurposedate = to_date(REC.BEN_BDDOC,'yyyy-mm-dd') or (b02p.benefitpurposedate is null and nullif(REC.BEN_BDDOC,'') is null))
             and b02p.cid = 0;
          if nBENEFIT02PURPOSE is null
          then
            insert into BENEFIT02PURPOSE(lid, benefit02id, benefitpurposenumber, benefitpurposedate)
                                  values(nlid, nbenefit02, REC.BEN_BNDOC, to_date(REC.BEN_BDDOC,'yyyy-mm-dd')) returning id into nBENEFIT02PURPOSE ;
          end if;


          -- основание получения
          if nullif(rec.joblessdocument,'') is not null or
          	 nullif(rec.documentregistered,'') is not null or
          	 nullif(rec.documentnumber,'') is not null or
          	 nullif(rec.documentdate,'') is not null or
          	 nullif(rec.dismissionnumber,'') is not null or
          	 nullif(rec.dismissiondate,'') is not null or
          	 nullif(rec.registereddate,'') is not null
          then
            -- поиск записи
            select id
              into nBENEFIT02BASIS
              from BENEFIT02BASIS BB
             where bb.benefit02id = nbenefit02
               and (bb.docsznreg = rec.joblessdocument or (nullif(bb.docsznreg,'') is null and nullif(rec.joblessdocument,'') is null))
               and (bb.detailscertmedicalorg = rec.documentregistered or (nullif(bb.detailscertmedicalorg,'') is null and nullif(rec.documentregistered,'') is null))
               and (bb.detailscertnum = rec.documentnumber or (nullif(bb.detailscertnum,'') is null and nullif(rec.documentnumber,'') is null))
               and (bb.detailscertdate = to_date(rec.documentdate, 'yyyy-mm-dd') or (bb.detailscertdate is null and nullif(rec.documentdate,'') is null))
               and (bb.dismissalnumber = rec.dismissionnumber or (nullif(bb.dismissalnumber,'') is null and nullif(rec.dismissionnumber,'') is null))
               and (bb.dismissaldate  = to_date(rec.dismissiondate, 'yyyy-mm-dd') or (bb.dismissaldate is null and nullif(rec.dismissiondate,'') is null))
               and (bb.registereddate = to_date(rec.registereddate, 'yyyy-mm-dd') or (bb.registereddate is null and nullif(rec.registereddate,'') is null))
               and BB.cid = 0;
            -- добавляем запись
            if nBENEFIT02BASIS is null
            then
              insert into BENEFIT02BASIS
              			  (
                           lid,
                           benefit02id,
                           docsznreg,
                           detailscertmedicalorg,
                           detailscertnum,
                           detailscertdate,
                           dismissalnumber,
                           dismissaldate,
                           registereddate
                          )
                          values
                          (
                           nlid,
                           nbenefit02,
                           rec.joblessdocument,
                           rec.documentregistered,
                           rec.documentnumber,
                           to_date(rec.documentdate, 'yyyy-mm-dd'),
                           rec.dismissionnumber,
                           to_date(rec.dismissiondate, 'yyyy-mm-dd'),
                           to_date(rec.registereddate, 'yyyy-mm-dd')
                          ) returning id into nBENEFIT02BASIS;
            end if;
          end if;

          -- Выплата пособия
          if rec.date_from0 is not null and rec.date_to0 is not null
          then
            spaydate := to_char(rec.date_from0, 'dd.mm.yyyy')||'-'||to_char(rec.date_to0, 'dd.mm.yyyy');
          else
            if REC.PAY_PAYDATEBEGIN is not null and REC.PAY_PAYDATEEND is not null
            then
              spaydate := to_char(rec.PAY_PAYDATEBEGIN, 'dd.mm.yyyy')||'-'||to_char(rec.PAY_PAYDATEEND, 'dd.mm.yyyy');
            else
              spaydate := COALESCE(REC.PAY_PAYPERIOD, to_char(rec.date_from0, 'dd.mm.yyyy'), to_char(rec.PAY_PAYDATEBEGIN, 'dd.mm.yyyy'));
            end if;
          end if;

          if nullif(spaydate, '') is null or spaydate is null
          then
            spaydate := COALESCE(to_char(rec.date_from0, 'dd.mm.yyyy'), to_char(rec.PAY_PAYDATEBEGIN, 'dd.mm.yyyy'), to_char(rec.date_to0, 'dd.mm.yyyy'), to_char(rec.PAY_PAYDATEEND, 'dd.mm.yyyy'));
          end if;

		  insert into BENEFIT02PAYMENT
          (
           lid,
           benefit02id, -- 'Пособие по уходу за ребенком';
           coefficient, -- 'Районный коэффициент';
           benefit02date, --
           benefitforcoefficient, -- 'Пособие с учетом коэффициента (руб.)';
           benefittotalsum, -- 'Общая сумма в отчетном месяце';
           paydate, -- 'Период выплаты';
           paysum, -- 'Сумма выплаты';
           extradate, -- 'Период доплаты';
           extrasum, -- 'Сумма доплаты';
           returndate, -- 'Период возврата';
           returnsum, -- 'Сумма возврата';
           retentiondate, -- 'Период удержания';
           retentionsum -- 'Сумма удержания';
          )
          values
          (
           nlid,
           nbenefit02,
           REC.PAY_RCOEF,
           REC.PAY_DATE,
           COALESCE(REC.PAY_TOTAL, REC.PAY_RSUM),
           COALESCE(REC.PAY_SUM, REC.PAY_SUMTHISMONTH),
           spaydate,
           rec.PAY_INCLUDINGPAYMENT,
           REC.PAY_INCLUDINGSURCHARGE_PERIOD,
           REC.PAY_INCLUDINGSURCHARGE,
           REC.PAY_INCLUDINGREFUND_PERIOD,
           REC.PAY_INCLUDINGREFUND,
           REC.PAY_INCLUDINGDETENTION_PERIOD,
           REC.PAY_INCLUDINGDETENTION
          );
        end if;
      -- ############################################ СОЗДАНИЕ BENEFIT02 #############################################

      -- ############################################ СОЗДАНИЕ BENEFIT03 #############################################
        if rec.ReestrNumberId = 3 then
          -- поиск записи пособия
          select id
            into nbenefit03
            from benefit03 b03
           where b03.benefitspacketsid = nBENEFITSPACKETS
             and b03.benefitsrecipientsid = nBENEFITSRECIPIENTS
             and b03.benefitstypedirid = nBENEFICIARIESREGISTERS
             and b03.cid = 0;
          -- добавелние записи пособия
          if nbenefit03 is null
          then
            insert into benefit03(lid, benefitstypedirid, BENEFITSPACKETSid, benefitsrecipientsid)
                           values(nlid, nBENEFICIARIESREGISTERS, nBENEFITSPACKETS, nBENEFITSRECIPIENTS) returning id into nbenefit03;
          end if;

          -- назначение пособия
          select id
            into nBENEFIT03PURPOSE
            from BENEFIT03PURPOSE b03p
           where b03p.benefit03id = nbenefit03
             and (b03p.benefitpurposenumber = REC.BEN_BNDOC or (nullif(b03p.benefitpurposenumber,'') is null and nullif(REC.BEN_BNDOC,'') is null))
             and (b03p.benefitpurposedate = to_date(REC.BEN_BDDOC,'yyyy-mm-dd') or (b03p.benefitpurposedate is null and nullif(REC.BEN_BDDOC,'') is null))
             and b03p.cid = 0;
          if nBENEFIT03PURPOSE is null
          then
            insert into BENEFIT03PURPOSE(lid, benefit03id, benefitpurposenumber, benefitpurposedate)
                                  values(nlid, nbenefit03, REC.BEN_BNDOC, to_date(REC.BEN_BDDOC,'yyyy-mm-dd')) returning id into nBENEFIT03PURPOSE ;
          end if;


          -- основание получения
          if nullif(rec.documentregistered,'') is not null or
          	 nullif(rec.documentnumber,'') is not null or
          	 nullif(rec.documentdate,'') is not null or
          	 nullif(rec.dismissionnumber,'') is not null or
          	 nullif(rec.dismissiondate,'') is not null or
          	 nullif(rec.registereddate,'') is not null
          then
            -- поиск записи
            select id
              into nBENEFIT03BASIS
              from BENEFIT03BASIS BB
             where BB.cid = 0
               and bb.benefit03id = nbenefit03
               and (bb.detailscertmedicalorg = rec.documentregistered or (nullif(bb.detailscertmedicalorg,'') is null and nullif(rec.documentregistered,'') is null))
               and (bb.detailscertnum = rec.documentnumber or (nullif(bb.detailscertnum,'') is null and nullif(rec.documentnumber,'') is null))
               and (bb.detailscertdate = to_date(rec.documentdate, 'yyyy-mm-dd') or (bb.detailscertdate is null and nullif(rec.documentdate,'') is null))
               and (bb.dismissalnumber = rec.dismissionnumber or (nullif(bb.dismissalnumber,'') is null and nullif(rec.dismissionnumber,'') is null))
               and (bb.dismissaldate  = to_date(rec.dismissiondate, 'yyyy-mm-dd') or (bb.dismissaldate is null and nullif(rec.dismissiondate,'') is null))
               and (bb.registereddate = to_date(rec.registereddate, 'yyyy-mm-dd') or (bb.registereddate is null and nullif(rec.registereddate,'') is null))
               and bb.cid = 0;
            -- добавляем запись
            if nBENEFIT03BASIS is null
            then
              insert into BENEFIT03BASIS
              			  (
                           lid,
                           benefit03id,
                           detailscertmedicalorg,
                           detailscertnum,
                           detailscertdate,
                           dismissalnumber,
                           dismissaldate,
                           registereddate
                          )
                          values
                          (
                           nlid,
                           nbenefit03,
                           rec.documentregistered,
                           rec.documentnumber,
                           to_date(rec.documentdate, 'yyyy-mm-dd'),
                           rec.dismissionnumber,
                           to_date(rec.dismissiondate, 'yyyy-mm-dd'),
                           to_date(rec.registereddate, 'yyyy-mm-dd')
                          ) returning id into nBENEFIT03BASIS;
            end if;
          end if;

          -- Выплата пособия
          dpaydate := COALESCE(rec.date_from0, REC.PAY_PAYDATEBEGIN);
		  insert into BENEFIT03PAYMENT
          (
           lid,
           benefit03id, -- 'Пособие по уходу за ребенком';
           coefficient, -- 'Районный коэффициент';
           benefitforcoefficient, -- 'Пособие с учетом коэффициента (руб.)';
           benefittotalsum, -- 'Общая сумма в отчетном месяце';
           paydate, -- 'Период выплаты';
           paysum, -- 'Сумма выплаты';
           extradate, -- 'Период доплаты';
           extrasum, -- 'Сумма доплаты';
           returndate, -- 'Период возврата';
           returnsum, -- 'Сумма возврата';
           retentiondate, -- 'Период удержания';
           retentionsum -- 'Сумма удержания';
          )
          values
          (
           nlid,
           nbenefit03,
           REC.PAY_RCOEF,
           COALESCE(REC.PAY_TOTAL, REC.PAY_RSUM),
           COALESCE(REC.PAY_SUM, REC.PAY_SUMTHISMONTH),
           dpaydate,
           rec.PAY_INCLUDINGPAYMENT,
           REC.PAY_INCLUDINGSURCHARGE_PERIOD,
           REC.PAY_INCLUDINGSURCHARGE,
           REC.PAY_INCLUDINGREFUND_PERIOD,
           REC.PAY_INCLUDINGREFUND,
           REC.PAY_INCLUDINGDETENTION_PERIOD,
           REC.PAY_INCLUDINGDETENTION
          );
        end if;
      -- ############################################ СОЗДАНИЕ BENEFIT03 #############################################

      -- ############################################ СОЗДАНИЕ BENEFIT04 #############################################
        if rec.ReestrNumberId = 4 then
          -- поиск записи пособия
          select id
            into nbenefit04
            from benefit04 b04
           where b04.benefitspacketsid = nBENEFITSPACKETS
             and b04.benefitsrecipientsid = nBENEFITSRECIPIENTS
             and b04.benefitstypedirid = nBENEFICIARIESREGISTERS
             and b04.cid = 0;
          -- добавелние записи пособия
          if nbenefit04 is null
          then
            insert into benefit04(lid, benefitstypedirid, BENEFITSPACKETSid, benefitsrecipientsid)
                           values(nlid, nBENEFICIARIESREGISTERS, nBENEFITSPACKETS, nBENEFITSRECIPIENTS) returning id into nbenefit04;
          end if;

          -- сведения о ребенке
          if nBENEFITCHILD is not null
          then
            insert into CHILD04(lid, benefit04id, benefitchildid)values(nlid, nbenefit04, nBENEFITCHILD) returning id into nCHILD04;
          else
            nCHILD04 := null;
          end if;

          -- основание получения
          if nullif(rec.joblessdocument,'') is not null or
          	 nullif(rec.registereddate,'') is not null
          then
            -- поиск записи
            select id
              into nBENEFIT04BASIS
              from BENEFIT04BASIS BB
             where bb.benefit04id = nbenefit04
               and (bb.TEMPORARYDISABILITYDOC = rec.joblessdocument or (nullif(bb.TEMPORARYDISABILITYDOC,'') is null and nullif(rec.joblessdocument,'') is null))
               and (bb.registereddate = to_date(rec.registereddate, 'yyyy-mm-dd') or (bb.registereddate is null and nullif(rec.registereddate,'') is null))
               and BB.cid = 0;
            -- добавляем запись
            if nBENEFIT04BASIS is null
            then
              insert into BENEFIT04BASIS(lid, benefit04id, TEMPORARYDISABILITYDOC, registereddate)
                                  values(nlid, nbenefit04, rec.joblessdocument, to_date(rec.registereddate, 'yyyy-mm-dd')) returning id into nBENEFIT04BASIS;
            end if;
          end if;

          -- назначение пособия
          select id
            into nBENEFIT04PURPOSE
            from BENEFIT04PURPOSE b04p
           where b04p.benefit04id = nbenefit04
             and (b04p.benefitpurposenumber = REC.BEN_BNDOC or (nullif(b04p.benefitpurposenumber,'') is null and nullif(REC.BEN_BNDOC,'') is null))
             and (b04p.benefitpurposedate = to_date(REC.BEN_BDDOC,'yyyy-mm-dd') or (b04p.benefitpurposedate is null and nullif(REC.BEN_BDDOC,'') is null));
          if nBENEFIT04PURPOSE is null
          then
            insert into BENEFIT04PURPOSE(lid, benefit04id, benefitpurposenumber, benefitpurposedate)
                                  values(nlid, nbenefit04, REC.BEN_BNDOC, to_date(REC.BEN_BDDOC,'yyyy-mm-dd')) returning id into nBENEFIT04PURPOSE ;
          end if;

          -- Выплата пособия
          dpaydate := COALESCE(rec.date_from0, REC.PAY_PAYDATEBEGIN);
		  insert into BENEFIT04PAYMENT
          (
           lid,
           benefit04id, -- 'Пособие по уходу за ребенком';
           child04id, -- 'Ребенок';
           coefficient, -- 'Районный коэффициент';
           benefitforcoefficient, -- 'Пособие с учетом коэффициента (руб.)';
           benefittotalsum, -- 'Общая сумма в отчетном месяце';
           paydate, -- 'Период выплаты';
           paysum, -- 'Сумма выплаты';
           extradate, -- 'Период доплаты';
           extrasum, -- 'Сумма доплаты';
           returndate, -- 'Период возврата';
           returnsum, -- 'Сумма возврата';
           retentiondate, -- 'Период удержания';
           retentionsum -- 'Сумма удержания';
          )
          values
          (
           nlid,
           nbenefit04,
           nCHILD04,
           REC.PAY_RCOEF,
           COALESCE(REC.PAY_TOTAL, REC.PAY_RSUM),
           COALESCE(REC.PAY_SUM, REC.PAY_SUMTHISMONTH),
           dpaydate,
           rec.PAY_INCLUDINGPAYMENT,
           REC.PAY_INCLUDINGSURCHARGE_PERIOD,
           REC.PAY_INCLUDINGSURCHARGE,
           REC.PAY_INCLUDINGREFUND_PERIOD,
           REC.PAY_INCLUDINGREFUND,
           REC.PAY_INCLUDINGDETENTION_PERIOD,
           REC.PAY_INCLUDINGDETENTION
          );
        end if;
      -- ############################################ СОЗДАНИЕ BENEFIT04 #############################################

      -- ############################################ СОЗДАНИЕ BENEFIT05 #############################################
        if rec.ReestrNumberId = 5 then
          -- поиск записи пособия
          select id
            into nbenefit05
            from benefit05 b05
           where b05.benefitspacketsid = nBENEFITSPACKETS
             and b05.benefitsrecipientsid = nBENEFITSRECIPIENTS
             and b05.benefitstypedirid = nBENEFICIARIESREGISTERS
             and b05.cid = 0;
          -- добавелние записи пособия
          if nbenefit05 is null
          then
            insert into benefit05(lid, benefitstypedirid, BENEFITSPACKETSid, benefitsrecipientsid)
                           values(nlid, nBENEFICIARIESREGISTERS, nBENEFITSPACKETS, nBENEFITSRECIPIENTS) returning id into nbenefit05;
          end if;

          -- сведения о ребенке
          if nBENEFITCHILD is not null
          then
            insert into CHILD05(lid, benefit05id, benefitchildid)values(nlid, nbenefit05, nBENEFITCHILD) returning id into nCHILD05;
          else
            nCHILD05 := null;
          end if;

          -- основание получения
          if nullif(rec.militaryregistered,'') is not null or
          	 nullif(rec.militarynumber,'') is not null or
          	 nullif(rec.militarydate,'') is not null or
          	 nullif(rec.militarybegindate,'') is not null or
          	 nullif(rec.militaryenddate,'') is not null or
          	 nullif(rec.registereddate,'') is not null
          then
            -- поиск записи
            select id
              into nBENEFIT05BASIS
              from BENEFIT05BASIS BB
             where bb.benefit05id = nbenefit05
               and (bb.militarynumber = rec.militaryregistered or (nullif(bb.militarynumber,'') is null and nullif(rec.militaryregistered,'') is null))
               and (bb.detailscertnum = rec.militarynumber or (nullif(bb.detailscertnum,'') is null and nullif(rec.militarynumber,'') is null))
               and (bb.detailscertdate = to_date(rec.militarydate, 'yyyy-mm-dd') or (bb.detailscertdate is null and nullif(rec.militarydate,'') is null))
               and (bb.militarystart = to_date(rec.militarybegindate, 'yyyy-mm-dd') or (bb.militarystart is null and nullif(rec.militarybegindate,'') is null))
               and (bb.militaryexpiry = to_date(rec.militaryenddate, 'yyyy-mm-dd') or (bb.militaryexpiry is null and nullif(rec.militaryenddate,'') is null))
               and (bb.registereddate = to_date(rec.registereddate, 'yyyy-mm-dd') or (bb.registereddate is null and nullif(rec.registereddate,'') is null))
               and BB.cid = 0;
            -- добавляем запись
            if nBENEFIT05BASIS is null
            then
              insert into BENEFIT05BASIS
                          (
                           lid, benefit05id, militarynumber, detailscertnum, detailscertdate, militarystart, militaryexpiry, registereddate
                          )
                    values(
                           nlid,
                    	   nbenefit05,
                           rec.militaryregistered,
                           rec.militarynumber,
                           to_date(rec.militarydate, 'yyyy-mm-dd'),
                           to_date(rec.militarybegindate, 'yyyy-mm-dd'),
                           to_date(rec.militaryenddate, 'yyyy-mm-dd'),
                           to_date(rec.registereddate, 'yyyy-mm-dd')
                          ) returning id into nBENEFIT05BASIS;
            end if;
          end if;

          -- назначение пособия
          select id
            into nBENEFIT05PURPOSE
            from BENEFIT05PURPOSE b05p
           where b05p.benefit05id = nbenefit05
             and (b05p.benefitpurposenumber = REC.BEN_BNDOC or (nullif(b05p.benefitpurposenumber,'') is null and nullif(REC.BEN_BNDOC,'') is null))
             and (b05p.benefitpurposedate = to_date(REC.BEN_BDDOC,'yyyy-mm-dd') or (b05p.benefitpurposedate is null and nullif(REC.BEN_BDDOC,'') is null))
             and b05p.cid = 0;
          if nBENEFIT05PURPOSE is null
          then
            insert into BENEFIT05PURPOSE(lid, benefit05id, benefitpurposenumber, benefitpurposedate)
                                  values(nlid, nbenefit05, REC.BEN_BNDOC, to_date(REC.BEN_BDDOC,'yyyy-mm-dd')) returning id into nBENEFIT05PURPOSE ;
          end if;

          -- Выплата пособия
          if rec.date_from0 is not null and rec.date_to0 is not null
          then
            spaydate := to_char(rec.date_from0, 'dd.mm.yyyy')||'-'||to_char(rec.date_to0, 'dd.mm.yyyy');
          else
            if REC.PAY_PAYDATEBEGIN is not null and REC.PAY_PAYDATEEND is not null
            then
              spaydate := to_char(rec.PAY_PAYDATEBEGIN, 'dd.mm.yyyy')||'-'||to_char(rec.PAY_PAYDATEEND, 'dd.mm.yyyy');
            else
              spaydate := REC.PAY_PAYPERIOD;
            end if;
          end if;

          if nullif(spaydate, '') is null or spaydate is null
          then
            spaydate := COALESCE(to_char(rec.date_from0, 'dd.mm.yyyy'), to_char(rec.PAY_PAYDATEBEGIN, 'dd.mm.yyyy'), to_char(rec.date_to0, 'dd.mm.yyyy'), to_char(rec.PAY_PAYDATEEND, 'dd.mm.yyyy'));
          end if;

		  insert into BENEFIT05PAYMENT
          (
           lid,
           benefit05id, -- 'Пособие по уходу за ребенком';
           child05id, -- 'Ребенок';
           coefficient, -- 'Районный коэффициент';
           benefitforcoefficient, -- 'Пособие с учетом коэффициента (руб.)';
           benefittotalsum, -- 'Общая сумма в отчетном месяце';
           paydate, -- 'Период выплаты';
           paysum, -- 'Сумма выплаты';
           extradate, -- 'Период доплаты';
           extrasum, -- 'Сумма доплаты';
           returndate, -- 'Период возврата';
           returnsum, -- 'Сумма возврата';
           retentiondate, -- 'Период удержания';
           retentionsum -- 'Сумма удержания';
          )
          values
          (
           nlid,
           nbenefit05,
           nCHILD05,
           REC.PAY_RCOEF,
           COALESCE(REC.PAY_TOTAL, REC.PAY_RSUM),
           COALESCE(REC.PAY_SUM, REC.PAY_SUMTHISMONTH),
           spaydate,
           rec.PAY_INCLUDINGPAYMENT,
           REC.PAY_INCLUDINGSURCHARGE_PERIOD,
           REC.PAY_INCLUDINGSURCHARGE,
           REC.PAY_INCLUDINGREFUND_PERIOD,
           REC.PAY_INCLUDINGREFUND,
           REC.PAY_INCLUDINGDETENTION_PERIOD,
           REC.PAY_INCLUDINGDETENTION
          );
        end if;
      -- ############################################ СОЗДАНИЕ BENEFIT05 #############################################

      -- ############################################ СОЗДАНИЕ BENEFIT06 #############################################
        if rec.ReestrNumberId = 6 then
          -- поиск записи пособия
          select id
            into nbenefit06
            from benefit06 b06
           where b06.benefitspacketsid = nBENEFITSPACKETS
             and b06.benefitsrecipientsid = nBENEFITSRECIPIENTS
             and b06.benefitstypedirid = nBENEFICIARIESREGISTERS
             and b06.cid = 0;
          -- добавелние записи пособия
          if nbenefit06 is null
          then
            insert into benefit06(lid, benefitstypedirid, BENEFITSPACKETSid, benefitsrecipientsid)
                           values(nlid, nBENEFICIARIESREGISTERS, nBENEFITSPACKETS, nBENEFITSRECIPIENTS) returning id into nbenefit06;
          end if;

          -- основание получения
          if nullif(rec.pregnancydocument,'') is not null or
          	 nullif(rec.militaryregistered,'') is not null or
          	 nullif(rec.militarynumber,'') is not null or
          	 nullif(rec.militarydate,'') is not null or
          	 nullif(rec.militarybegindate,'') is not null or
          	 nullif(rec.militaryenddate,'') is not null or
          	 nullif(rec.registereddate,'') is not null or
          	 nullif(rec.certificateseries,'') is not null or
          	 nullif(rec.certificatenumber,'') is not null or
          	 nullif(rec.certificatedate,'') is not null or
          	 nullif(rec.marriagedate,'') is not null
          then
            -- поиск записи
            select id
              into nBENEFIT06BASIS
              from BENEFIT06BASIS BB
             where bb.benefit06id = nbenefit06
               and (bb.temporarydisabilitydoc = rec.pregnancydocument or (nullif(bb.temporarydisabilitydoc,'') is null and nullif(rec.pregnancydocument,'') is null))
               and (bb.militarynumber = rec.militaryregistered or (nullif(bb.militarynumber,'') is null and nullif(rec.militaryregistered,'') is null))
               and (bb.detailscertnum = rec.militarynumber or (nullif(bb.detailscertnum,'') is null and nullif(rec.militarynumber,'') is null))
               and (bb.detailscertdate = to_date(rec.militarydate, 'yyyy-mm-dd') or (bb.detailscertdate is null and nullif(rec.militarydate,'') is null))
               and (bb.militarystart = to_date(rec.militarybegindate, 'yyyy-mm-dd') or (bb.militarystart is null and nullif(rec.militarybegindate,'') is null))
               and (bb.militaryexpiry = to_date(rec.militaryenddate, 'yyyy-mm-dd') or (bb.militaryexpiry is null and nullif(rec.militaryenddate,'') is null))
               and (bb.registereddate = to_date(rec.registereddate, 'yyyy-mm-dd') or (bb.registereddate is null and nullif(rec.registereddate,'') is null))
               and (bb.marriagecertseries = rec.certificateseries or (nullif(bb.marriagecertseries,'') is null and nullif(rec.certificateseries,'') is null))
               and (bb.marriagecertnumber = rec.certificatenumber or (nullif(bb.marriagecertnumber,'') is null and nullif(rec.certificatenumber,'') is null))
               and (bb.marriagecertdate = to_date(rec.certificatedate, 'yyyy-mm-dd') or (bb.marriagecertdate is null and nullif(rec.certificatedate,'') is null))
               and (bb.marriageactdate = to_date(rec.marriagedate, 'yyyy-mm-dd') or (bb.marriageactdate is null and nullif(rec.marriagedate,'') is null))
               and bb.cid = 0;
            -- добавляем запись
            if nBENEFIT06BASIS is null
            then
              insert into BENEFIT06BASIS
                          (
                           lid,
                           benefit06id,
                           temporarydisabilitydoc,
                           militarynumber,
                           detailscertnum,
                           detailscertdate,
                           militarystart,
                           militaryexpiry,
                           registereddate,
                           marriagecertseries,
                           marriagecertnumber,
                           marriagecertdate,
                           marriageactdate
                          )
                    values(
                           nlid,
                    	   nbenefit06,
                           rec.pregnancydocument,
                           rec.militaryregistered,
                           rec.militarynumber,
                           to_date(rec.militarydate, 'yyyy-mm-dd'),
                           to_date(rec.militarybegindate, 'yyyy-mm-dd'),
                           to_date(rec.militaryenddate, 'yyyy-mm-dd'),
                           to_date(rec.registereddate, 'yyyy-mm-dd'),
                           rec.certificateseries,
                           rec.certificatenumber,
                           to_date(rec.certificatedate, 'yyyy-mm-dd'),
                           to_date(rec.marriagedate, 'yyyy-mm-dd')
                          ) returning id into nBENEFIT06BASIS;
            end if;
          end if;

          -- назначение пособия
          select id
            into nBENEFIT06PURPOSE
            from BENEFIT06PURPOSE b06p
           where b06p.benefit06id = nbenefit06
             and (b06p.benefitpurposenumber = REC.BEN_BNDOC or (nullif(b06p.benefitpurposenumber,'') is null and nullif(REC.BEN_BNDOC,'') is null))
             and (b06p.benefitpurposedate = to_date(REC.BEN_BDDOC,'yyyy-mm-dd') or (b06p.benefitpurposedate is null and nullif(REC.BEN_BDDOC,'') is null));
          if nBENEFIT06PURPOSE is null
          then
            insert into BENEFIT06PURPOSE(lid, benefit06id, benefitpurposenumber, benefitpurposedate)
                                  values(nlid, nbenefit06, REC.BEN_BNDOC, to_date(REC.BEN_BDDOC,'yyyy-mm-dd')) returning id into nBENEFIT06PURPOSE ;
          end if;

          -- Выплата пособия
          dpaydate := COALESCE(rec.date_from0, REC.PAY_PAYDATEBEGIN);
		  insert into BENEFIT06PAYMENT
          (
           lid,
           benefit06id, -- 'Пособие по уходу за ребенком';
           coefficient, -- 'Районный коэффициент';
           benefitforcoefficient, -- 'Пособие с учетом коэффициента (руб.)';
           benefittotalsum, -- 'Общая сумма в отчетном месяце';
           paydate, -- 'Период выплаты';
           paysum, -- 'Сумма выплаты';
           extradate, -- 'Период доплаты';
           extrasum, -- 'Сумма доплаты';
           returndate, -- 'Период возврата';
           returnsum, -- 'Сумма возврата';
           retentiondate, -- 'Период удержания';
           retentionsum -- 'Сумма удержания';
          )
          values
          (
           nlid,
           nbenefit06,
           REC.PAY_RCOEF,
           COALESCE(REC.PAY_TOTAL, REC.PAY_RSUM),
           COALESCE(REC.PAY_SUM, REC.PAY_SUMTHISMONTH),
           dpaydate,
           rec.PAY_INCLUDINGPAYMENT,
           REC.PAY_INCLUDINGSURCHARGE_PERIOD,
           REC.PAY_INCLUDINGSURCHARGE,
           REC.PAY_INCLUDINGREFUND_PERIOD,
           REC.PAY_INCLUDINGREFUND,
           REC.PAY_INCLUDINGDETENTION_PERIOD,
           REC.PAY_INCLUDINGDETENTION
          );
        end if;
      -- ############################################ СОЗДАНИЕ BENEFIT06 #############################################
    exception
      when others then
        raise using message := s||rec.id::text||'oERRo'||sqlerrm;
    end;
      end loop; -- REC
end loop; -- RR
set application_name = '';
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_benefit_load (nrt_regkey bigint)
  OWNER TO magicbox;