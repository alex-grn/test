CREATE OR REPLACE FUNCTION p_reestr_parse(id bigint) RETURNS text AS
$body$
 declare
   nID bigint = id;
   file_xml xml;
   file_text text;
   sql	     text;
   dow 		 record;
   nRZ		 bigint;
   benefitID bigint;
   nREG		 bigint;
   nType	 bigint;
   nPACK     bigint;
   tRETURN	 text;
   err_table text;
   err_state text;
 begin
   tRETURN:='Загрузка успешно завершена';
   select P_SYSTEM_FILE_TO_TEXT(f.bfile)
     into file_text
     from filebuffer f 
    where f.id = (select max(f2.id) from filebuffer f2 where f2.cid = nID);
   delete from filebuffer f where f.cid = nID;
   if file_text is null then
     raise using MESSAGE = 'Файл реестра отсутствует.';
   end if;
   begin
     file_xml = cast(replace(file_text,'xmlns','name') as xml);
   exception
     when others then
       raise using MESSAGE = 'Некорректная структура XML-файла.';
   end;
    sql = 'CREATE TEMPORARY TABLE file_imp (
    	         stable		text UNIQUE,
                 sort		integer,
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
                 col12      text
                 ) 
                 WITH (oids = false) ON COMMIT DROP;';
     execute sql;
   perform p_reestr_parse_xml(file_xml);
   begin
   select max(s.id) into benefitID from benefit07 s;
   select max(s.id) into nREG from BENEFICIARIESREGISTERS s;
   select s1.id,s.benefitstypenamedirid into nPACK,nType from BENEFICIARIESREGISTERS s,benefitspackets s1 where s1.id = s.benefitspacketsid and s.id = nreg;
    for dow in (select stable,col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11,col12 
    			  from file_imp f
                  order by f.sort
                )
                loop
                   if dow.col1 = ''  then dow.col1  := null;end if;
                   if dow.col2 = ''  then dow.col2  := null;end if;
                   if dow.col3 = ''  then dow.col3  := null;end if;
                   if dow.col4 = ''  then dow.col4  := null;end if;
                   if dow.col5 = ''  then dow.col5  := null;end if;
                   if dow.col6 = ''  then dow.col6  := null;end if;
                   if dow.col7 = ''  then dow.col7  := null;end if;
                   if dow.col8 = ''  then dow.col8  := null;end if;
                   if dow.col9 = ''  then dow.col9  := null;end if;
                   if dow.col10 = '' then dow.col10 := null;end if;
                   if dow.col11 = '' then dow.col11 := null;end if;
                   if dow.col12 = '' then dow.col12 := null;end if;
                
                	if dow.stable = 'BENEFITSRECIPIENTS' then
                      --проверка 
                      BEGIN
                      select s.id
                        into STRICT nRZ
                        from BENEFITSRECIPIENTS s
                       where trim(lower(s.lastname)) = lower(dow.col1)
                         and trim(lower(s.firstname)) = lower(dow.col2)
                         and trim(lower(s.patronymic)) = lower(dow.col3)
                         and trim(s.persondocumentnumber) = trim(dow.col11)
                         and trim(s.persondocumentseries) = trim(dow.col10);
                      exception when no_data_found then 
                        insert into BENEFITSRECIPIENTS(lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                      	VALUES(dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date);
                        select max(s.id) into nRZ from BENEFITSRECIPIENTS s;
                      			when too_many_rows then raise using MESSAGE = 'Найдены дубликаты критическая ошибка! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        update benefit07 s set benefitsrecipientsid = nRZ where s.id = benefitID;
                    elsif dow.stable = 'BENEFITCHILD' then
                      begin
                     select s.id
                       into STRICT nRZ 
                       from BENEFITCHILD s
                      where trim(lower(s.lastname)) = lower(dow.col1)
                        and trim(lower(s.firstname)) = lower(dow.col2) 
                        and trim(lower(s.patronymic)) = lower(dow.col3)
                        and trim(s.docbirthchildnumber) = trim(dow.col7) 
                        and trim(s.docbirthchildserial) = trim(dow.col6)
                        and s.benefitsrecipientsid = nRZ;
                      exception when no_data_found then
                      	insert into BENEFITCHILD(benefitsrecipientsid,lastname,firstname,patronymic,benefitchilddatebirth,docbirthchildtypeid,docbirthchildserial,docbirthchildnumber,docbirthchilddate)
                        values(nRZ,dow.col1,dow.col2,dow.col3,dow.col4::date,dow.col5::bigint,dow.col6,dow.col7,dow.col8::date);
                        		when too_many_rows then raise using MESSAGE = 'Найдены дубликаты критическая ошибка! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                    elsif dow.stable = 'FAMILYMEMBERS' then
                     insert into FAMILYMEMBERS(benefit07id,familymembercount,totalincome,averageincome,fio,incomecertificatenumber,incomecertificatedate,registereddate)
                     values(benefitID,dow.col1::integer,dow.col6::numeric,dow.col7::numeric,dow.col4,dow.col2,dow.col3::date,dow.col5::date);
                    elsif dow.stable = 'BENEFIT07PURPOSE' then
                     insert into BENEFIT07PURPOSE(benefit07id,benefitpurposenumber,benefitpurposedate)
                     values(benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT07PAYMENT' then 
                     insert into BENEFIT07PAYMENT(benefit07id,coefficient,benefitforcoefficient,subsistence,paydate,paysum,extradate,extrasum,returndate,returnsum,retentiondate,retentionsum)
                     values(benefitID,dow.col2::numeric,dow.col3::numeric,dow.col1::numeric,dow.col4,dow.col5::numeric,dow.col6,dow.col7::numeric,dow.col8,dow.col9::numeric,dow.col10,dow.col11::numeric);
                     insert into remark(hid) values(null);
        											   update remark s set note = dow.col12,
                                                       					   benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s),
                                                                           benefitstypedirid    = (select max(s.id) from BENEFICIARIESREGISTERS s),
                                                                           benefitspacketsid    = (select x.id from benefitspackets x, 
                                                                           									        BENEFICIARIESREGISTERS x1 
                                                                                                              where x1.benefitspacketsid = x.id
                                                                                                                and x1.id = (select max(s.id) from BENEFICIARIESREGISTERS s))
                                                                     where s.id = (select max(x.id) from remark x); 
                                                        update benefit07 s set remarkid = (select max(s.id) from remark s) where s.id = benefitID;
                    end if;
                end loop;
                 update BENEFICIARIESREGISTERS s set status = '02' where s.id = nREG;
   exception when others then 
      GET STACKED DIAGNOSTICS   err_state = RETURNED_SQLSTATE,
      							err_table = TABLE_NAME,
      							tRETURN = MESSAGE_TEXT;
      update BENEFICIARIESREGISTERS s set status = '03' where s.id = nREG;
      if err_state='23505' then  
             for dow in select m.name from metaclass m where m.classnode='TABLE' and m.code = upper(err_table)
             loop
               tRETURN = 'Ошибка: Дублирование записи в таблице "'||coalesce(dow.name,err_table)||'"';
             end loop;
      end if; 
      insert into WRONGLOADING( benefitspacketsid,wrong,benefitstypenamedirid) values( nPACK,tRETURN,nType);
   end;
  
   return tRETURN;
 end;
$body$
language plpgsql volatile;
/ 
