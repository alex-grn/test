CREATE OR REPLACE FUNCTION public.p_reestr_parse (
  id bigint,
  uid bigint
)
RETURNS text AS
$body$
declare
   nID bigint = id;
   nUSERID bigint = uid;
   file_xml xml;
   file_text text;
   sql       text;
   dow     record;
   rec     record;
   dr    record;
   nRZ     bigint;
   OLDbenefitID bigint;
   benefitID bigint;
   nREG    bigint;
   nType   bigint;
   nPACK     bigint;
   tRETURN   text;
   err_table text;
   err_state text;
   nTEMP   numeric = 0;
   sNODE   text;
   sRESULT   text;
   bufID   bigint;
 begin
 --������� ������� ���� � ��������
 delete from filebuffer where cid = ident; 
-- insert into filebuffer(cid, code, tablename, filename, bfile) values (ident, 'BFILE', 'errors', 'errors.txt', P_SYSTEM_FILE_FROM_TEXT('TEsting'));
-- return 'test';
 --
 insert into filebuffer(cid, code, tablename, filename, bfile) values (ident, 'BFILE', 'ErrorsProtocol', 'ErrorsProtocol.txt', P_SYSTEM_FILE_FROM_TEXT('')) returning filebuffer.id into bufID;
 
   if (select count(s.id) from senders s, users u where u.id = nUSERID and s.userid = u.id and s.banload = true)>0 and to_number(to_char(now(),'dd'),'99')>11 then
    tRETURN:= '�������� ������� ����� 11 ����� �������� ������ ���������!'; 
    delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x); return tRETURN; end if;
   tRETURN:='�������� ������� ���������';
   update BENEFICIARIESREGISTERS s set status = '01' where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x);
   if (select s.statuspack 
         from BENEFITSPACKETS s,
          BENEFICIARIESREGISTERS r where s.id = r.benefitspacketsid
                               and r.id = (select max(x.id) from BENEFICIARIESREGISTERS x)) = '01' then 
                                         tRETURN = '�������� ������� �� ��������, ���������� � ������ �������� � ����������� ������ �� ����� � ���������';
                                         update filebuffer s set bfile = P_SYSTEM_FILE_FROM_TEXT(tRETURN) where s.id = bufID;
                                         delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x); return tRETURN;
   end if;
   begin
   select P_SYSTEM_FILE_TO_TEXT(convert(F.bfile,'WIN1251','UTF8'))
     into file_text
     from filebuffer f 
    where f.id = (select max(f2.id) from filebuffer f2 where f2.cid = nID);
   delete from filebuffer f where f.cid = nID;
   if file_text is null  then
     delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x);
     tRETURN = '������: ���� ������� �����������.'; update filebuffer s set bfile = P_SYSTEM_FILE_FROM_TEXT(tRETURN) where s.id = bufID;return tRETURN;
   end if;
   begin
     file_xml = cast(replace(file_text,'xmlns','name') as xml);
   exception
     when others then
       delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x);
       tRETURN = '������: ������������ ��������� XML-�����.';update filebuffer s set bfile = P_SYSTEM_FILE_FROM_TEXT(tRETURN) where s.id = bufID;return tRETURN;
   end;
   exception when others then 
        GET STACKED DIAGNOSTICS   err_state = RETURNED_SQLSTATE,
                      err_table = TABLE_NAME,
                      tRETURN = MESSAGE_TEXT;
       delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x); raise using message = 'others';return tRETURN;
   end;
    sql = 'CREATE TEMPORARY TABLE file_imp (
               stable   text,
                 sort   integer,
                 nzap   integer,
                 level    integer,
                 flag   integer,
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
   -- DELETE FROM FILE_IMP;
   begin
   perform p_reestr_parse_xml(file_xml,bufID);
   
   exception when others then
   GET STACKED DIAGNOSTICS   err_state = RETURNED_SQLSTATE,
                    err_table = TABLE_NAME,
                    tRETURN = MESSAGE_TEXT;
    delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x); 
    return tRETURN;
    end;
    select lower(cast((xpath('name(/*)', file_xml))[1] as text)) into sNODE; 
   begin
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
   tRETURN = '';
   if sNODE = 'benefit07' then
   --select max(s.id) into benefitID from benefit07 s;
   for rec in (select S.NZAP from file_imp s group by s.NZAP) 
   loop insert into benefit07(hid,uid) VALUES(null,nUSERID);select max(s.id) into benefitID from benefit07 s;
   for dr in (select x.id as xid,reg.id as regid,lower(se.name)||se.code||x.repyear||lpad(x.repmonth,2,'0') as cod
                       from benefitspackets x,  
                            BENEFICIARIESREGISTERS reg,
                            SUBJECTSDIR se  
                      where reg.benefitspacketsid = x.id
                        and se.id  = x.subjectsdirid
                          and reg.id = (select max(r.id) from BENEFICIARIESREGISTERS r) )
                       loop
                          update benefit07 s set benefitspacketsid = dr.xid,benefitstypedirid = dr.regid where s.id = benefitID;
                     end loop; 
   select max(s.id) into nREG from BENEFICIARIESREGISTERS s;
   select s1.id,s.benefitstypenamedirid into nPACK,nType from BENEFICIARIESREGISTERS s,benefitspackets s1 where s1.id = s.benefitspacketsid and s.id = nreg;
    for dow in (select * 
            from file_imp f WHERE F.nzap = rec.nzap
                  order by f.nzap,f.sort
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
                   if dow.col13 = '' then dow.col13 := null;end if;
                  if dow.stable = 'BENEFITSRECIPIENTS' then
                      --�������� 
                      BEGIN
                      select s.id
                        into STRICT nRZ
                        from BENEFITSRECIPIENTS s
                       where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                         and trim(s.persondocumentnumber) = trim(dow.col11)
                         and trim(s.persondocumentseries) = trim(dow.col10);
                      exception when no_data_found then 
                        if dow.flag = 1 then return '������ �� ���������� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ��������, �� ������������). ������ �������� � �������.'; end if;
                        insert into BENEFITSRECIPIENTS(uid,lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                        VALUES(nUSERID,dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date);
                        select max(s.id) into nRZ from BENEFITSRECIPIENTS s;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        update benefit07 s set benefitsrecipientsid = nRZ where s.id = benefitID;
                        /*for dr in(
                        select s.benefitspacketsid,s.benefitstypedirid,s.benefitsrecipientsid
                          from benefit07 s
                        where s.id = benefitID )
                        loop
                        OLDbenefitID:=benefitID;
                          begin                               --��� �������� �� ������ ���� �����
                          select x.id 
                            into benefitID
                            from benefit07 x
                           where x.benefitspacketsid = dr.benefitspacketsid
                             and x.benefitsrecipientsid = dr.benefitsrecipientsid;
                          exception when no_data_found then null;
                          end;
                          if OLDbenefitID <> benefitID then
                            delete from benefit07 x where x.id = OLDbenefitID;
                          end if;
                        end loop;*/
                    elsif dow.stable = 'BENEFITCHILD' then
                      begin
                     select s.id
                       into STRICT OLDbenefitID 
                       from BENEFITCHILD s
                      where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                        and trim(s.docbirthchildnumber) = trim(dow.col7) 
                        and trim(s.docbirthchildserial) = trim(dow.col6)
                       /* and s.benefitsrecipientsid = nRZ*/;
                      exception when no_data_found then
                      if dow.flag = 1 then return '������ �� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ���� ��������, ���� �������� �� ������������). ������ �������� � �������.'; end if;
                      --raise using MESSAGE =nRZ||' '||dow.col1||' '||dow.col2||' '||dow.col3||' '||dow.col7||' '||dow.col6;
                        insert into BENEFITCHILD(uid,benefitsrecipientsid,lastname,firstname,patronymic,benefitchilddatebirth,docbirthchildtypeid,docbirthchildserial,docbirthchildnumber,docbirthchilddate,benefitchildumber) 
                        values(nUSERID,nRZ,dow.col1,dow.col2,dow.col3,dow.col4::date,dow.col5::bigint,dow.col6,dow.col7,dow.col8::date,1); select max(f.id) into OLDbenefitID from BENEFITCHILD f;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        insert into child07(uid,benefit07id,benefitchildid) values(nUSERID,benefitID,OLDbenefitID); select max(f.id) into OLDbenefitID from child f;
                    elsif dow.stable = 'FAMILYMEMBERS' then
                    if dow.col7::numeric <> dow.col6::numeric / dow.col1::integer then tRETURN = ltrim(tRETURN||chr(13)||'������������� ����� ������ ����� �� ������������� ��������� �������. ������ �� ��������!',chr(13));
                                                    delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x); 
                                            /*return tRETURN;*/ end if;
                     insert into FAMILYMEMBERS(uid,benefit07id,familymembercount,totalincome,averageincome,fio,incomecertificatenumber,incomecertificatedate,registereddate07)
                     values(nUSERID,benefitID,dow.col1::integer,dow.col6::numeric,dow.col7::numeric,dow.col4,dow.col2,dow.col3::date,dow.col5::date); nTEMP:=dow.col7::numeric;
                    elsif dow.stable = 'BENEFIT07PURPOSE' then
                    if dow.col3::numeric > 1.5 * nTEMP then tRETURN = ltrim(tRETURN||chr(13)||'������������� ����� ������ ����� ������ ���� �� ������, ��� � 1,5 ����, ������� ������������ �������� ��������������� ���������. ������ �� ��������!',chr(13));
                                                    delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x); 
                                            /*return tRETURN;*/ end if;
                     insert into BENEFIT07PURPOSE(uid,benefit07id,benefitpurposenumber,benefitpurposedate,benefitsubsistenceworking)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date,dow.col3::numeric); 
                     --on CONFLICT (benefitpurposenumber, benefitpurposedate, cid) do update set benefitpurposenumber = dow.col1, benefitpurposedate = dow.col2::date, benefitsubsistenceworking = dow.col3::numeric;
                    elsif dow.stable = 'BENEFIT07PAYMENT' then 
                     insert into BENEFIT07PAYMENT(uid,benefit07id,subsistencechild,paydatefrom,paydateto,paysum,surchargedatefrom,surchargedateto,surchargesum,refunddatefrom,refunddateto,refundsum,holddatefrom,holddateto,holdsum,child07id)
                     values(nUSERID,benefitID,dow.col1::numeric,dow.col2::date,dow.col3::date,dow.col4::numeric,dow.col5::date,dow.col6::date,dow.col7::numeric,dow.col8::date,dow.col9::date,dow.col10::numeric,dow.col11::date,dow.col12::date,dow.col13::numeric,OLDbenefitID);
                    elsif dow.stable = 'REMARK' then  
                     insert into remark(hid,uid) values(null,nUSERID);
                                 update remark s set note = dow.col1,
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
               end loop;
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
     elsif sNODE = 'benefit01' then
     for rec in (select S.NZAP from file_imp s group by s.NZAP) 
   loop  insert into benefit01(hid,uid) VALUES(null,nUSERID);select max(s.id) into benefitID from benefit01 s;
   for dr in (select x.id as xid,reg.id as regid,lower(se.name)||se.code||x.repyear||lpad(x.repmonth,2,'0') as cod
                       from benefitspackets x,  
                            BENEFICIARIESREGISTERS reg,
                            SUBJECTSDIR se  
                      where reg.benefitspacketsid = x.id
                        and se.id  = x.subjectsdirid
                          and reg.id = (select max(r.id) from BENEFICIARIESREGISTERS r) )
                       loop
                          update benefit01 s set benefitspacketsid = dr.xid,benefitstypedirid = dr.regid where s.id = benefitID;
                     end loop; 
   select max(s.id) into nREG from BENEFICIARIESREGISTERS s;
   select s1.id,s.benefitstypenamedirid into nPACK,nType from BENEFICIARIESREGISTERS s,benefitspackets s1 where s1.id = s.benefitspacketsid and s.id = nreg;
    for dow in (select * 
            from file_imp f WHERE F.nzap = rec.nzap
                  order by f.nzap,f.sort
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
                   if dow.col13 = '' then dow.col13 := null;end if;
                  if dow.stable = 'BENEFITSRECIPIENTS' then
                      --�������� 
                      BEGIN
                      select s.id
                        into STRICT nRZ
                        from BENEFITSRECIPIENTS s
                       where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                         and trim(s.persondocumentnumber) = trim(dow.col11)
                         and trim(s.persondocumentseries) = trim(dow.col10);
                      exception when no_data_found then 
                        if dow.flag = 1 then return '������ �� ���������� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ��������, �� ������������). ������ �������� � �������.'; end if;                      
                        insert into BENEFITSRECIPIENTS(uid,lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                        VALUES(nUSERID,dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date);
                        select max(s.id) into nRZ from BENEFITSRECIPIENTS s;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        update benefit01 s set benefitsrecipientsid = nRZ where s.id = benefitID;
                    elsif dow.stable = 'BENEFITCHILD' then
                      begin
                     select s.id
                       into STRICT OLDbenefitID 
                       from BENEFITCHILD s
                      where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                        and trim(s.docbirthchildnumber) = trim(dow.col7) 
                        and trim(s.docbirthchildserial) = trim(dow.col6)
                        /*and s.benefitsrecipientsid = nRZ*/;
                      exception when no_data_found then
                        if dow.flag = 1 then return '������ �� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ���� ��������, ���� �������� �� ������������). ������ �������� � �������.'; end if;
                        insert into BENEFITCHILD(uid,benefitsrecipientsid,lastname,firstname,patronymic,benefitchilddatebirth,docbirthchildtypeid,docbirthchildserial,docbirthchildnumber,docbirthchilddate,benefitchildumber) 
                        values(nUSERID,nRZ,dow.col1,dow.col2,dow.col3,dow.col4::date,dow.col5::bigint,dow.col6,dow.col7,dow.col8::date,dow.col9::integer); select max(f.id) into OLDbenefitID from BENEFITCHILD f;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        insert into child(uid,benefit01id,benefitchildid) values(nUSERID,benefitID,OLDbenefitID); select max(f.id) into OLDbenefitID from child f;
                    elsif dow.stable = 'BENEFIT01BASIS' then
                     insert into BENEFIT01BASIS(uid,benefit01id,docchildcohabitation,registereddate)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PURPOSE' then 
                     insert into BENEFIT01PURPOSE(uid,benefit01id,benefitpurposenumber,benefitpurposedate)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PAYMENT' then 
                     insert into BENEFIT01PAYMENT(uid,benefit01id,coefficient,benefitforcoefficient,paydate,paysum,extradate,extrasum,returndate,returnsum,retentiondate,retentionsum,child01id)
                     values(nUSERID,benefitID,dow.col1::numeric,dow.col2::numeric,dow.col3,dow.col4::numeric,dow.col6::date,dow.col7::numeric,dow.col8::date,dow.col9::numeric,dow.col10::date,dow.col11::numeric,OLDbenefitID);
                    elsif dow.stable = 'REMARK' then  
                     insert into remark(hid,uid) values(null,nUSERID);
                                 update remark s set note = dow.col1,
                                                                   benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s),
                                                                           benefitstypedirid    = (select max(s.id) from BENEFICIARIESREGISTERS s),
                                                                           benefitspacketsid    = (select x.id from benefitspackets x, 
                                                                                                    BENEFICIARIESREGISTERS x1 
                                                                                                              where x1.benefitspacketsid = x.id
                                                                                                                and x1.id = (select max(s.id) from BENEFICIARIESREGISTERS s))
                                                                     where s.id = (select max(x.id) from remark x); 
                                                        update benefit01 s set remarkid = (select max(s.id) from remark s) where s.id = benefitID;
                    end if;
                end loop;
               end loop;
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
     elsif sNODE = 'benefit02' then
     for rec in (select S.NZAP from file_imp s group by s.NZAP) 
   loop insert into benefit02(hid,uid) VALUES(null,nUSERID);select max(s.id) into benefitID from benefit02 s;
   for dr in (select x.id as xid,reg.id as regid,lower(se.name)||se.code||x.repyear||lpad(x.repmonth,2,'0') as cod
                       from benefitspackets x,  
                            BENEFICIARIESREGISTERS reg,
                            SUBJECTSDIR se  
                      where reg.benefitspacketsid = x.id
                        and se.id  = x.subjectsdirid
                          and reg.id = (select max(r.id) from BENEFICIARIESREGISTERS r) )
                       loop
                          update benefit02 s set benefitspacketsid = dr.xid,benefitstypedirid = dr.regid where s.id = benefitID;
                     end loop; 
   select max(s.id) into nREG from BENEFICIARIESREGISTERS s;
   select s1.id,s.benefitstypenamedirid into nPACK,nType from BENEFICIARIESREGISTERS s,benefitspackets s1 where s1.id = s.benefitspacketsid and s.id = nreg;
    for dow in (select * 
            from file_imp f WHERE F.nzap = rec.nzap
                  order by f.nzap,f.sort
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
                   if dow.col13 = '' then dow.col13 := null;end if;
                  if dow.stable = 'BENEFITSRECIPIENTS' then
                      --�������� 
                      BEGIN
                      select s.id
                        into STRICT nRZ
                        from BENEFITSRECIPIENTS s
                       where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                         and trim(s.persondocumentnumber) = trim(dow.col11)
                         and trim(s.persondocumentseries) = trim(dow.col10);
                      exception when no_data_found then 
                        if dow.flag = 1 then return '������ �� ���������� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ��������, �� ������������). ������ �������� � �������.'; end if;                      
                        insert into BENEFITSRECIPIENTS(uid,lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                        VALUES(nUSERID,dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date);
                        select max(s.id) into nRZ from BENEFITSRECIPIENTS s;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        update benefit02 s set benefitsrecipientsid = nRZ where s.id = benefitID;
                    elsif dow.stable = 'BENEFIT01BASIS' then
                     insert into BENEFIT02BASIS(uid,benefit02id,docsznreg,registereddate,dismissalnumber,dismissaldate,detailscertdate,detailscertnum,detailscertmedicalorg)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date,dow.col3,dow.col4::date,dow.col5::date,dow.col6,dow.col7);
                    elsif dow.stable = 'BENEFIT01PURPOSE' then 
                     insert into BENEFIT02PURPOSE(uid,benefit02id,benefitpurposenumber,benefitpurposedate)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PAYMENT' then 
                     insert into BENEFIT02PAYMENT(uid,benefit02id,coefficient,benefitforcoefficient,paydate,paysum,benefit02date,extradate,extrasum,returndate,returnsum,retentiondate,retentionsum)
                     values(nUSERID,benefitID,dow.col1::numeric,dow.col2::numeric,dow.col3,dow.col4::numeric,dow.col5::date,dow.col6::date,dow.col7::numeric,dow.col8::date,dow.col9::numeric,dow.col10::date,dow.col11::numeric);
                    elsif dow.stable = 'REMARK' then  
                     insert into remark(hid,uid) values(null,nUSERID);
                                 update remark s set note = dow.col1,
                                                                   benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s),
                                                                           benefitstypedirid    = (select max(s.id) from BENEFICIARIESREGISTERS s),
                                                                           benefitspacketsid    = (select x.id from benefitspackets x, 
                                                                                                    BENEFICIARIESREGISTERS x1 
                                                                                                              where x1.benefitspacketsid = x.id
                                                                                                                and x1.id = (select max(s.id) from BENEFICIARIESREGISTERS s))
                                                                     where s.id = (select max(x.id) from remark x); 
                                                        update benefit02 s set remarkid = (select max(s.id) from remark s) where s.id = benefitID;
                    end if;
                end loop;
               end loop;
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������               
     elsif sNODE = 'benefit03' then
     for rec in (select S.NZAP from file_imp s group by s.NZAP) 
   loop insert into benefit03(hid,uid) VALUES(null,nUSERID);select max(s.id) into benefitID from benefit03 s;
   for dr in (select x.id as xid,reg.id as regid,lower(se.name)||se.code||x.repyear||lpad(x.repmonth,2,'0') as cod
                       from benefitspackets x,  
                            BENEFICIARIESREGISTERS reg,
                            SUBJECTSDIR se  
                      where reg.benefitspacketsid = x.id
                        and se.id  = x.subjectsdirid
                          and reg.id = (select max(r.id) from BENEFICIARIESREGISTERS r) )
                       loop
                          update benefit03 s set benefitspacketsid = dr.xid,benefitstypedirid = dr.regid where s.id = benefitID;
                     end loop; 
   select max(s.id) into nREG from BENEFICIARIESREGISTERS s;
   select s1.id,s.benefitstypenamedirid into nPACK,nType from BENEFICIARIESREGISTERS s,benefitspackets s1 where s1.id = s.benefitspacketsid and s.id = nreg;
    for dow in (select * 
            from file_imp f WHERE F.nzap = rec.nzap
                  order by f.nzap,f.sort
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
                   if dow.col13 = '' then dow.col13 := null;end if;
                  if dow.stable = 'BENEFITSRECIPIENTS' then
                      --�������� 
                      BEGIN
                      select s.id
                        into STRICT nRZ
                        from BENEFITSRECIPIENTS s
                       where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                         and trim(s.persondocumentnumber) = trim(dow.col11)
                         and trim(s.persondocumentseries) = trim(dow.col10);
                      exception when no_data_found then 
                        if dow.flag = 1 then return '������ �� ���������� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ��������, �� ������������). ������ �������� � �������.'; end if;                      
                        insert into BENEFITSRECIPIENTS(uid,lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                        VALUES(nUSERID,dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date);
                        select max(s.id) into nRZ from BENEFITSRECIPIENTS s;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        update benefit03 s set benefitsrecipientsid = nRZ where s.id = benefitID; 
                    elsif dow.stable = 'BENEFIT01BASIS' then
                     insert into BENEFIT03BASIS(uid,benefit03id,registereddate,dismissalnumber,dismissaldate,detailscertdate,detailscertnum,detailscertmedicalorg)
                     values(nUSERID,benefitID,dow.col2::date,dow.col3,dow.col4::date,dow.col5::date,dow.col6,dow.col7);
                    elsif dow.stable = 'BENEFIT01PURPOSE' then 
                     insert into BENEFIT03PURPOSE(uid,benefit03id,benefitpurposenumber,benefitpurposedate)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PAYMENT' then 
                     insert into BENEFIT03PAYMENT(uid,benefit03id,coefficient,benefitforcoefficient,paydate,paysum,extradate,extrasum,returndate,returnsum,retentiondate,retentionsum)
       /*date*/      values(nUSERID,benefitID,dow.col1::numeric,dow.col2::numeric,dow.col3::date,dow.col4::numeric,dow.col6::date,dow.col7::numeric,dow.col8::date,dow.col9::numeric,dow.col10::date,dow.col11::numeric);
                    elsif dow.stable = 'REMARK' then  
                     insert into remark(hid,uid) values(null,nUSERID);
                                 update remark s set note = dow.col1,
                                                                   benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s),
                                                                           benefitstypedirid    = (select max(s.id) from BENEFICIARIESREGISTERS s),
                                                                           benefitspacketsid    = (select x.id from benefitspackets x, 
                                                                                                    BENEFICIARIESREGISTERS x1 
                                                                                                              where x1.benefitspacketsid = x.id
                                                                                                                and x1.id = (select max(s.id) from BENEFICIARIESREGISTERS s))
                                                                     where s.id = (select max(x.id) from remark x); 
                                                        update benefit03 s set remarkid = (select max(s.id) from remark s) where s.id = benefitID;
                    end if;
                end loop;
               end loop;  
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������       
     elsif sNODE = 'benefit04' then
     for rec in (select S.NZAP from file_imp s group by s.NZAP) 
   loop insert into benefit04(hid,uid) VALUES(null,nUSERID);select max(s.id) into benefitID from benefit04 s;
   for dr in (select x.id as xid,reg.id as regid,lower(se.name)||se.code||x.repyear||lpad(x.repmonth,2,'0') as cod
                       from benefitspackets x,  
                            BENEFICIARIESREGISTERS reg,
                            SUBJECTSDIR se  
                      where reg.benefitspacketsid = x.id
                        and se.id  = x.subjectsdirid
                          and reg.id = (select max(r.id) from BENEFICIARIESREGISTERS r) )
                       loop
                          update benefit04 s set benefitspacketsid = dr.xid,benefitstypedirid = dr.regid where s.id = benefitID;
                     end loop; 
   select max(s.id) into nREG from BENEFICIARIESREGISTERS s;
   select s1.id,s.benefitstypenamedirid into nPACK,nType from BENEFICIARIESREGISTERS s,benefitspackets s1 where s1.id = s.benefitspacketsid and s.id = nreg;
    for dow in (select * 
            from file_imp f WHERE F.nzap = rec.nzap
                  order by f.nzap,f.sort
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
                   if dow.col13 = '' then dow.col13 := null;end if;
                  if dow.stable = 'BENEFITSRECIPIENTS' then
                      --�������� 
                      BEGIN
                      select s.id
                        into STRICT nRZ
                        from BENEFITSRECIPIENTS s
                       where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                         and trim(s.persondocumentnumber) = trim(dow.col11)
                         and trim(s.persondocumentseries) = trim(dow.col10);
                      exception when no_data_found then 
                        if dow.flag = 1 then return '������ �� ���������� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ��������, �� ������������). ������ �������� � �������.'; end if;                      
                        begin
                        insert into BENEFITSRECIPIENTS(uid,lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                        VALUES(nUSERID,dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date);
                        exception when others then raise using message = COALESCE(dow.col1,'@')||' '||COALESCE(dow.col2,'@')||' '||COALESCE(dow.col3,'@')||' '||COALESCE(dow.col9,'@')||' '||COALESCE(dow.col10,'@')||' '||COALESCE(dow.col11,'@')||' '||COALESCE(dow.col12,'@') ; end;
                        select max(s.id) into nRZ from BENEFITSRECIPIENTS s;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        update benefit04 s set benefitsrecipientsid = nRZ where s.id = benefitID;
                    elsif dow.stable = 'BENEFITCHILD' then
                      begin
                     select s.id
                       into STRICT OLDbenefitID 
                       from BENEFITCHILD s
                      where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                        and trim(s.docbirthchildnumber) = trim(dow.col7) 
                        and trim(s.docbirthchildserial) = trim(dow.col6)
                        /*and s.benefitsrecipientsid = nRZ*/;
                      exception when no_data_found then
                        if dow.flag = 1 then return '������ �� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ���� ��������, ���� �������� �� ������������). ������ �������� � �������.'; end if;
                        insert into BENEFITCHILD(uid,benefitsrecipientsid,lastname,firstname,patronymic,benefitchilddatebirth,docbirthchildtypeid,docbirthchildserial,docbirthchildnumber,docbirthchilddate,benefitchildumber) 
                        values(nUSERID,nRZ,dow.col1,dow.col2,dow.col3,dow.col4::date,dow.col5::bigint,dow.col6,dow.col7,dow.col8::date,dow.col9::integer); select max(f.id) into OLDbenefitID from BENEFITCHILD f;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        insert into child04(uid,benefit04id,benefitchildid) values(nUSERID,benefitID,OLDbenefitID);  select max(f.id) into OLDbenefitID from child04 f;
                    elsif dow.stable = 'BENEFIT01BASIS' then
                     insert into BENEFIT04BASIS(uid,benefit04id,temporarydisabilitydoc,registereddate)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PURPOSE' then 
                     insert into BENEFIT04PURPOSE(uid,benefit04id,benefitpurposenumber,benefitpurposedate)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PAYMENT' then 
                     insert into BENEFIT04PAYMENT(uid,benefit04id,coefficient,benefitforcoefficient,paydate,paysum,extradate,extrasum,returndate,returnsum,retentiondate,retentionsum,child04id)
                     values(nUSERID,benefitID,dow.col1::numeric,dow.col2::numeric,dow.col3::date,dow.col4::numeric,dow.col6::date,dow.col7::numeric,dow.col8::date,dow.col9::numeric,dow.col10::date,dow.col11::numeric,OLDbenefitID);
                    elsif dow.stable = 'REMARK' then  
                     insert into remark(hid,uid) values(null,nUSERID);
                                 update remark s set note = dow.col1,
                                                                   benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s),
                                                                           benefitstypedirid    = (select max(s.id) from BENEFICIARIESREGISTERS s),
                                                                           benefitspacketsid    = (select x.id from benefitspackets x, 
                                                                                                    BENEFICIARIESREGISTERS x1 
                                                                                                              where x1.benefitspacketsid = x.id
                                                                                                                and x1.id = (select max(s.id) from BENEFICIARIESREGISTERS s))
                                                                     where s.id = (select max(x.id) from remark x); 
                                                        update benefit04 s set remarkid = (select max(s.id) from remark s) where s.id = benefitID;
                    end if;
                end loop;
               end loop;  
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������       
     elsif sNODE = 'benefit05' then
     for rec in (select S.NZAP from file_imp s group by s.NZAP) 
   loop insert into benefit05(hid,uid) VALUES(null,nUSERID);select max(s.id) into benefitID from benefit05 s;
   for dr in (select x.id as xid,reg.id as regid,lower(se.name)||se.code||x.repyear||lpad(x.repmonth,2,'0') as cod
                       from benefitspackets x,  
                            BENEFICIARIESREGISTERS reg,
                            SUBJECTSDIR se  
                      where reg.benefitspacketsid = x.id
                        and se.id  = x.subjectsdirid
                          and reg.id = (select max(r.id) from BENEFICIARIESREGISTERS r) )
                       loop
                          update benefit05 s set benefitspacketsid = dr.xid,benefitstypedirid = dr.regid where s.id = benefitID;
                     end loop; 
   select max(s.id) into nREG from BENEFICIARIESREGISTERS s;
   select s1.id,s.benefitstypenamedirid into nPACK,nType from BENEFICIARIESREGISTERS s,benefitspackets s1 where s1.id = s.benefitspacketsid and s.id = nreg;
    for dow in (select * 
            from file_imp f WHERE F.nzap = rec.nzap
                  order by f.nzap,f.sort
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
                   if dow.col13 = '' then dow.col13 := null;end if;
                  if dow.stable = 'BENEFITSRECIPIENTS' then
                      --�������� 
                      BEGIN
                      select s.id
                        into STRICT nRZ
                        from BENEFITSRECIPIENTS s
                       where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                         and trim(s.persondocumentnumber) = trim(dow.col11)
                         and trim(s.persondocumentseries) = trim(dow.col10);
                      exception when no_data_found then 
                        if dow.flag = 1 then return '������ �� ���������� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ��������, �� ������������). ������ �������� � �������.'; end if;                      
                        insert into BENEFITSRECIPIENTS(uid,lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                        VALUES(nUSERID,dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date);
                        select max(s.id) into nRZ from BENEFITSRECIPIENTS s;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        update benefit05 s set benefitsrecipientsid = nRZ where s.id = benefitID;
                    elsif dow.stable = 'BENEFITCHILD' then
                      begin
                     select s.id
                       into STRICT OLDbenefitID 
                       from BENEFITCHILD s
                      where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                        and trim(s.docbirthchildnumber) = trim(dow.col7) 
                        and trim(s.docbirthchildserial) = trim(dow.col6)
                        and s.benefitsrecipientsid = nRZ;
                      exception when no_data_found then
                        if dow.flag = 1 then return '������ �� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ���� ��������, ���� �������� �� ������������). ������ �������� � �������.'; end if;
                        insert into BENEFITCHILD(uid,benefitsrecipientsid,lastname,firstname,patronymic,benefitchilddatebirth,docbirthchildtypeid,docbirthchildserial,docbirthchildnumber,docbirthchilddate,benefitchildumber) 
                        values(nUSERID,nRZ,dow.col1,dow.col2,dow.col3,dow.col4::date,dow.col5::bigint,dow.col6,dow.col7,dow.col8::date,dow.col9::integer); select max(f.id) into OLDbenefitID from BENEFITCHILD f;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        insert into child05(uid,benefit05id,benefitchildid) values(nUSERID,benefitID,OLDbenefitID); select max(f.id) into OLDbenefitID from child05 f;
                    elsif dow.stable = 'BENEFIT01BASIS' then
                     insert into BENEFIT05BASIS(uid,benefit05id,detailscertdate,detailscertnum,militarynumber,militarystart,militaryexpiry,registereddate)
                     values(nUSERID,benefitID,dow.col8::date,dow.col9,dow.col10,dow.col11::date,dow.col12::date,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PURPOSE' then 
                     insert into BENEFIT05PURPOSE(uid,benefit05id,benefitpurposenumber,benefitpurposedate)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PAYMENT' then 
                     insert into BENEFIT05PAYMENT(uid,benefit05id,coefficient,benefitforcoefficient,paydate,paysum,extradate,extrasum,returndate,returnsum,retentiondate,retentionsum,child05id)
   /*date*/          values(nUSERID,benefitID,dow.col1::numeric,dow.col2::numeric,dow.col3,dow.col4::numeric,dow.col6::date,dow.col7::numeric,dow.col8::date,dow.col9::numeric,dow.col10::date,dow.col11::numeric,OLDbenefitID);
                    elsif dow.stable = 'REMARK' then  
                     insert into remark(hid,uid) values(null,nUSERID);
                                 update remark s set note = dow.col1,
                                                                   benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s),
                                                                           benefitstypedirid    = (select max(s.id) from BENEFICIARIESREGISTERS s),
                                                                           benefitspacketsid    = (select x.id from benefitspackets x, 
                                                                                                    BENEFICIARIESREGISTERS x1 
                                                                                                              where x1.benefitspacketsid = x.id
                                                                                                                and x1.id = (select max(s.id) from BENEFICIARIESREGISTERS s))
                                                                     where s.id = (select max(x.id) from remark x); 
                                                        update benefit05 s set remarkid = (select max(s.id) from remark s) where s.id = benefitID;
                    end if;
                end loop;
               end loop;
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������
--����������������������������������������������������������������������������������������������������������������������������������������������������������������������       
     elsif sNODE = 'benefit06' then
     for rec in (select S.NZAP from file_imp s group by s.NZAP) 
   loop insert into benefit06(hid,uid) VALUES(null,nUSERID);select max(s.id) into benefitID from benefit06 s;
   for dr in (select x.id as xid,reg.id as regid,lower(se.name)||se.code||x.repyear||lpad(x.repmonth,2,'0') as cod
                       from benefitspackets x,  
                            BENEFICIARIESREGISTERS reg,
                            SUBJECTSDIR se  
                      where reg.benefitspacketsid = x.id
                        and se.id  = x.subjectsdirid
                          and reg.id = (select max(r.id) from BENEFICIARIESREGISTERS r) )
                       loop
                          update benefit06 s set benefitspacketsid = dr.xid,benefitstypedirid = dr.regid where s.id = benefitID;
                     end loop; 
   select max(s.id) into nREG from BENEFICIARIESREGISTERS s;
   select s1.id,s.benefitstypenamedirid into nPACK,nType from BENEFICIARIESREGISTERS s,benefitspackets s1 where s1.id = s.benefitspacketsid and s.id = nreg;
    for dow in (select * 
            from file_imp f WHERE F.nzap = rec.nzap
                  order by f.nzap,f.sort
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
                   if dow.col13 = '' then dow.col13 := null;end if;
                  if dow.stable = 'BENEFITSRECIPIENTS' then
                      --�������� 
                      BEGIN
                      select s.id
                        into STRICT nRZ
                        from BENEFITSRECIPIENTS s
                       where trim(lower(COALESCE(s.lastname,''))) = lower(COALESCE(dow.col1,''))
                         and trim(lower(COALESCE(s.firstname,''))) = lower(COALESCE(dow.col2,''))
                         and trim(lower(COALESCE(s.patronymic,''))) = lower(COALESCE(dow.col3,''))
                         and trim(s.persondocumentnumber) = trim(dow.col11)
                         and trim(s.persondocumentseries) = trim(dow.col10);
                      exception when no_data_found then 
                        if dow.flag = 1 then return '������ �� ���������� ������� (����������� ������� ��� �������� (��� �������), ����� � ����� ���������, ��������������� ��������, �� ������������). ������ �������� � �������.'; end if;                      
                        insert into BENEFITSRECIPIENTS(uid,lastname,firstname,patronymic,citizenship,snils,recipientsdatebirth,recipientscategoriesdirid,recipientaddress,persondocumenttypeid,persondocumentseries,persondocumentnumber,persondocumentdate)
                        VALUES(nUSERID,dow.col1,dow.col2,dow.col3,dow.col7,dow.col8,dow.col5::date,dow.col4::bigint,dow.col6,dow.col9::bigint,dow.col10,dow.col11,dow.col12::date);
                        select max(s.id) into nRZ from BENEFITSRECIPIENTS s;
                            when too_many_rows then raise using MESSAGE = '������� ��������� ����������� ������! '||dow.col1||' '||dow.col2||' '||dow.col3;
                      end;
                        update benefit06 s set benefitsrecipientsid = nRZ where s.id = benefitID; 
                    elsif dow.stable = 'BENEFIT01BASIS' then
                     insert into BENEFIT06BASIS(uid,benefit06id,temporarydisabilitydoc,registereddate,marriagecertnumber,marriagecertdate,marriageactdate,marriagecertseries,detailscertdate,detailscertnum,militarynumber,militarystart,militaryexpiry)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date,dow.col3,dow.col4::date,dow.col5::date,dow.col6,dow.col8::date,dow.col9,dow.col10,dow.col11::date,dow.col12::date);
                    elsif dow.stable = 'BENEFIT01PURPOSE' then 
                     insert into BENEFIT06PURPOSE(uid,benefit06id,benefitpurposenumber,benefitpurposedate)
                     values(nUSERID,benefitID,dow.col1,dow.col2::date);
                    elsif dow.stable = 'BENEFIT01PAYMENT' then 
                     insert into BENEFIT06PAYMENT(uid,benefit06id,coefficient,benefitforcoefficient,paydate,paysum,extradate,extrasum,returndate,returnsum,retentiondate,retentionsum)
   /*date*/          values(nUSERID,benefitID,dow.col1::numeric,dow.col2::numeric,dow.col3::date,dow.col4::numeric,dow.col6::date,dow.col7::numeric,dow.col8::date,dow.col9::numeric,dow.col10::date,dow.col11::numeric);
                    elsif dow.stable = 'REMARK' then  
                     insert into remark(hid,uid) values(null,nUSERID);
                                 update remark s set note = dow.col1,
                                                                   benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s),
                                                                           benefitstypedirid    = (select max(s.id) from BENEFICIARIESREGISTERS s),
                                                                           benefitspacketsid    = (select x.id from benefitspackets x, 
                                                                                                    BENEFICIARIESREGISTERS x1 
                                                                                                              where x1.benefitspacketsid = x.id
                                                                                                                and x1.id = (select max(s.id) from BENEFICIARIESREGISTERS s))
                                                                     where s.id = (select max(x.id) from remark x); 
                                                        update benefit05 s set remarkid = (select max(s.id) from remark s) where s.id = benefitID;
                    end if;
                end loop;
               end loop;                
     end if;
     if tRETURN <> '' then
       update filebuffer s set bfile = P_SYSTEM_FILE_FROM_TEXT(tRETURN) where s.id = bufID;
     end if;
   exception when others then 
      GET STACKED DIAGNOSTICS   err_state = RETURNED_SQLSTATE,
                    err_table = TABLE_NAME,
                    tRETURN = MESSAGE_TEXT;
      if err_state='23505' then  
             for dow in select m.name from metaclass m where m.classnode='TABLE' and m.code = upper(err_table)
             loop
               tRETURN = '������: ������������ ������ � ������� "'||coalesce(dow.name,err_table)||'"';
             end loop;
      end if; 
      update BENEFICIARIESREGISTERS s set wrongloading = tRETURN, status = '02' where s.id = nREG;
     --insert into WRONGLOADING( benefitspacketsid,wrong,benefitstypenamedirid) values( nPACK,tRETURN,nType);
   end;
   if (select count(*) from filebuffer s where s.id = bufID and s.bfile = P_SYSTEM_FILE_FROM_TEXT('')) != 0 then delete from filebuffer s where s.id = bufID; else  delete from BENEFICIARIESREGISTERS s where s.id = (select max(x.id) from BENEFICIARIESREGISTERS x);  tRETURN:='�������� ������ ��� �������� �������!';  end if;
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