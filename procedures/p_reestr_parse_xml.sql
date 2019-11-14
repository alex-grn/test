CREATE OR REPLACE FUNCTION public.p_reestr_parse_xml (
  file_xml xml,
  id bigint,
  pos integer = 1,
  fio text = ''::text,
  fio_r text = ''::text
)
RETURNS void AS
$body$
declare
  SNODE    TEXT;
  CHILD    record;
  ATTR     record;
  REC      record;
  THEAD    TEXT;
  SQLTABLE TEXT;
  NID      BIGINT := ID;
  FL       integer := 0;
  TBUF     TEXT [ ];
  NLEVEL   integer [ ];
  NPOS     integer;
  FLAG     integer := 0;
  sERRORS  TEXT := '';
  sFIO	   TEXT := fio;					--ФИО получателя пособия (для адресации ошибок)
  sFIO_R   TEXT := fio_r;				--ФИО ребенка получателя пособия (для адресации ошибок)
begin
  -- текущий узел
  select cast((XPATH('name(/*)', FILE_XML)) [ 1 ] as TEXT) into SNODE;  
  --raise using message = 'boom';
   -- атрибуты текущего узла
   for attr in (select LOWER(cast((XPATH('name(/' || SNODE || '/@*[' || I || '])', FILE_XML)) [ 1 ] as TEXT)) SPROP, SVALUE
                from UNNEST(cast(XPATH('/' || SNODE || '/@*', FILE_XML) as TEXT [ ])) with ORDINALITY as A(SVALUE, I)
               order by I)
   loop
     --insert into test21(val1,val2,val3) VALUES(attr.sprop,attr.svalue,snode);
     -- обработка значений атрибутов ...  
      if lower(SNODE) = 'header' then 
           if ATTR.SPROP = 'from'         then tBUF[1]:=ATTR.SVALUE;
        elsif ATTR.SPROP = 'sendertype'   then tBUF[2]:=ATTR.SVALUE;
        --elsif attr.sprop = 'to' then tHead:=tHead||attr.svalue; 
        elsif ATTR.SPROP = 'date'         then update BENEFICIARIESREGISTERS s set DATEFORM = ATTR.SVALUE::date where s.id = NID;
        elsif ATTR.SPROP = 'month' 		  then tBUF[3]:=ATTR.SVALUE;
        elsif ATTR.SPROP = 'year' 		  then tBUF[4]:=ATTR.SVALUE; 
        elsif ATTR.SPROP = 'reestrnumber' then for rec in(select S.ID
        													from BENEFITSTYPEDIR s
                                                           where s.rosternumber = attr.svalue::integer)
                                                            loop
                                                                 update BENEFICIARIESREGISTERS s set benefitstypenamedirid = rec.id where s.id = NID; flag := 2;
                                                        end loop;
                                                        if flag <> 2 then raise using message = 'Номер реестра не соответствует. Реестр не загружен!'; flag := 0; end if;
           for rec in (select x.id as xid,reg.id as regid, lower(se.name) as fromm, se.code as sender, x.repyear, x.repmonth::integer as smonths 
                 	     from benefitspackets x,  
                      		  BENEFICIARIESREGISTERS reg,
                      		  SUBJECTSDIR se  
               		    where reg.benefitspacketsid = x.id
                    	  and se.id  = x.subjectsdirid
                  	      and reg.id = NID)
                  		 loop
                          if rec.sender <> tBUF[2]::integer THEN /*raise using message = */sERRORS:=sERRORS||chr(13)||'Код отправителя не соответствует отправителю. Реестр не загружен.';
                          elsif rec.repyear <> tBUF[4]::integer THEN /*raise using message = */sERRORS:=sERRORS||chr(13)||'Год отчетного периода в реестре не соответствует отчетному периоду. Реестр не загружен!';
                          elsif rec.smonths <> tBUF[3]::integer THEN /*raise using message = */sERRORS:=sERRORS||chr(13)||'Месяц отчетного периода в реестре не соответствует отчетному периоду. Реестр не загружен.';
                          end if;flag:=1;
                         -- update benefit07 s set benefitspacketsid = rec.xid,benefitstypedirid = rec.regid where s.id = (select max(s.id) from benefit07 s);
                     end loop;
                     if flag = 0 then raise using MESSAGE = 'Отсутствует заголовок!'; end if;
       end if;
      elsif lower(snode) = 'benefitreceiver' then 
         -- raise using message = attr.sprop;
           if attr.sprop = 'lastname'  			  then tBUF[1]:=attr.svalue; 
        elsif attr.sprop = 'firstname' 			  then tBUF[2]:=attr.svalue; 
        elsif attr.sprop = 'patronymic'           then tBUF[3]:=attr.svalue; sFIO:=COALESCE(tBUF[1],'')||' '||COALESCE(tBUF[2],'')||' '||COALESCE(tBUF[3],'');
        elsif attr.sprop = 'recipientscategories' or attr.sprop = 'receivercategory' then for rec in(select x.id  --benefit07 or benefit01
                                                          from RECIPIENTSCATEGORIESDIR x
                                                         where x.code = attr.svalue::integer)
                                                        loop 
                                                         tBUF[4]:=rec.id; flag := 2;
                                                        end loop; 
                                                        if flag <> 2 then /*raise using message =*/sERRORS:=sERRORS||chr(13)||'Категория получателя пособия '||sFIO||' не соответствует. Реестр не загружен!'; flag := 0; end if;
        elsif attr.sprop = 'birthdate'            then tBUF[5]:=attr.svalue; 
        elsif attr.sprop = 'recipientaddress' or attr.sprop = 'address' then tBUF[6]:=attr.svalue; --benefit07 or benefit01
        elsif attr.sprop = 'citizenship' 		  then tBUF[7]:=attr.svalue; 
        elsif attr.sprop = 'snils' 	              then tBUF[8]:=attr.svalue;
                                                       --update benefit07 s set benefitsrecipientsid = nID where s.id = (select max(s.id) from benefit07 s); 
       end if; 
       --benefit07
       elsif lower(snode) = 'persondocument'      then
           if attr.sprop = 'persondocumenttype'   then for rec in(select x.id
                                                          from PERSONDOCUMENTDIR x
                                                         where x.code = attr.svalue::integer)
                                                        loop 
                                                         tBUF[9]:=rec.id; flag := 2;
                                                        end loop;
                                                        if flag <> 2 then /*raise using message =*/sERRORS:=sERRORS||chr(13)||'Вид документа, удостоверяющего личность получателя '||sFIO||', не соответствует. Реестр не загружен!'; flag := 0; end if;
        elsif attr.sprop = 'persondocumentseries' then tBUF[10]:=attr.svalue;
        elsif attr.sprop = 'persondocumentnumber' then tBUF[11]:=attr.svalue;
        elsif attr.sprop = 'persondocumentdate'   then tBUF[12]:=attr.svalue;
       end if;
       --
       --benefit01
       elsif lower(snode) = 'receivercredential'  then
           if attr.sprop = 'credentialtype'       then for rec in(select x.id
                                                          from PERSONDOCUMENTDIR x
                                                         where x.code = attr.svalue::integer)
                                                        loop 
                                                         tBUF[9]:=rec.id; flag := 2;
                                                        end loop;
                                                        if flag <> 2 then /*raise using message =*/sERRORS:=sERRORS||chr(13)||'Вид документа, удостоверяющего личность получателя '||sFIO||', не соответствует. Реестр не загружен!'; flag := 0; end if;
        elsif attr.sprop = 'series' 			  then tBUF[10]:=attr.svalue;
        elsif attr.sprop = 'number' 			  then tBUF[11]:=attr.svalue;
        elsif attr.sprop = 'persondocumentdate'   then tBUF[12]:=attr.svalue;
       end if;
       --   
     elsif lower(snode) = 'child' then
     	   if attr.sprop = 'lastname'	          then tBUF[1]:=attr.svalue; 
           											   --update BENEFITCHILD s set benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s); 
        elsif attr.sprop = 'firstname'	          then tBUF[2]:=attr.svalue;
        elsif attr.sprop = 'patronymic'	          then tBUF[3]:=attr.svalue; sFIO_R:=COALESCE(tBUF[1],'')||' '||COALESCE(tBUF[2],'')||' '||COALESCE(tBUF[3],'');
        elsif attr.sprop = 'birthdate' or attr.sprop = 'dateofbirth' then tBUF[4]:=attr.svalue;  --benefit07 or benefit01
        elsif attr.sprop = 'childnumber'		  then tBUF[9]:=attr.svalue; if tBUF[9] = '' then tBUF[9] = '0';  end if; --if tBUF[9]::numeric <= 0  then /*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' childnumber очередность рождения ребенка не может быть 0 или пустой. Реестр не загружен!'; end if;--benefit01
       end if;
     --benefit07
     elsif lower(snode) = 'childdocument' then
           if attr.sprop = 'childdocumenttype'	  then for rec in(select x.id
                                                          from CERTIFICATEBIRTHDIR x
                                                         where x.code = attr.svalue::integer)
                                                        loop 
                                                         tBUF[5]:=rec.id; flag := 2;
                                                        end loop;
                                                        if flag <> 2 then /*raise using message =*/sERRORS:=sERRORS||chr(13)||'Вид документа, подтверждающего факт рождения ребенка '||sFIO_R||', не соответствует. Реестр не загружен!'; flag := 0; end if;
        elsif attr.sprop = 'childdocumentseries'  then tBUF[6]:=attr.svalue;
        elsif attr.sprop = 'childdocumentnumber'  then tBUF[7]:=attr.svalue; 
        elsif attr.sprop = 'childdocumentdate'	  then tBUF[8]:=attr.svalue;
       end if;
     --benefit01
     elsif lower(snode) = 'certificateofbirth' then 
           if attr.sprop = 'certificatetype'   then for rec in(select x.id
                                                          from CERTIFICATEBIRTHDIR x
                                                         where x.code = attr.svalue::integer)
                                                        loop 
                                                         tBUF[5]:=rec.id; flag := 2;
                                                        end loop;
                                                        if flag <> 2 then /*raise using message =*/sERRORS:=sERRORS||chr(13)||'Вид документа, подтверждающего факт рождения ребенка '||sFIO_R||', не соответствует. Реестр не загружен!'; flag := 0; end if;
        elsif attr.sprop = 'serial' 		   then tBUF[6]:=attr.svalue;
        elsif attr.sprop = 'number' 		   then tBUF[7]:=attr.svalue;
        elsif attr.sprop = 'certificatedate'   then tBUF[8]:=attr.svalue; 
       end if;
     elsif lower(snode) = 'benefitassignment'  then  
           if attr.sprop = 'joblessdocument' or attr.sprop = 'pregnancydocument'   then tBUF[1]:=attr.svalue; 
        elsif attr.sprop = 'registereddate'     then tBUF[2]:=attr.svalue;
        elsif attr.sprop = 'dismissionnumber' or attr.sprop = 'certificatenumber'  then tBUF[3]:=attr.svalue;
        elsif attr.sprop = 'dismissiondate'  or attr.sprop = 'certificatemarriagedate'  then tBUF[4]:=attr.svalue;
        elsif attr.sprop = 'documentdate'    or attr.sprop = 'marriagedate'  then tBUF[5]:=attr.svalue;
        elsif attr.sprop = 'documentnumber'   or attr.sprop = 'certificateseries' then tBUF[6]:=attr.svalue;
        elsif attr.sprop = 'documentregistered' or attr.sprop = 'adressdocument' then tBUF[7]:=attr.svalue;
        elsif attr.sprop = 'militarydate'  	   then tBUF[8]:=attr.svalue;
        elsif attr.sprop = 'militarynumber'    then tBUF[9]:=attr.svalue;
        elsif attr.sprop = 'militaryregistered' then tBUF[10]:=attr.svalue;
        elsif attr.sprop = 'militarybegindate' then tBUF[11]:=attr.svalue;
        elsif attr.sprop = 'militaryenddate'   then tBUF[12]:=attr.svalue;
       end if;     
     --
     elsif lower(snode) = 'familymembers' then
           if attr.sprop = 'familymembercount'	  then tBUF[1]:=attr.svalue;
           											   --update FAMILYMEMBERS s set benefit07id = (select max(x.id) from benefit07 x); 
        elsif attr.sprop = 'incomecertificatenumber' then tBUF[2]:=attr.svalue;
        elsif attr.sprop = 'incomecertificatedate' then tBUF[3]:=attr.svalue;
        elsif attr.sprop = 'fullname'	  		   then tBUF[4]:=attr.svalue; 
        elsif attr.sprop = 'registereddate'	       then tBUF[5]:=attr.svalue;
        elsif attr.sprop = 'totalincome'	       then tBUF[6]:=replace(attr.svalue,',','.');  
        elsif attr.sprop = 'averageincome'	       then tBUF[7]:=replace(attr.svalue,',','.'); if replace(attr.svalue,',','.')::numeric <= 0 then /*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Суммы при заполнении должны быть больше нуля. Реестр не загружен!'; end if; 
       end if; 
     elsif lower(snode) = 'purpose' then
           if attr.sprop = 'purposenumber'        then tBUF[1]:=attr.svalue;
           											   --update BENEFIT07PURPOSE s set benefit07id = (select max(x.id) from benefit07 x); 
        elsif attr.sprop = 'purposedate'          then tBUF[2]:=attr.svalue;
        elsif attr.sprop = 'subsistenceworking'	  then tBUF[3]:=replace(attr.svalue,',','.');
       end if;
     --benefit07
     elsif lower(snode) = 'payment' then
     	   if attr.sprop = 'subsistencechild'/*'subsistence'*/          then tBUF[1]:=replace(attr.svalue,',','.'); if tBUF[1] = '' then tBUF[1] = '0'; flag:=2; end if; if tBUF[1]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message = */sERRORS:=sERRORS||chr(13)||'Суммы при заполнении должны быть больше нуля. Реестр не загружен!'; end if;
           											   --update BENEFIT07PAYMENT s set benefit07id = (select max(x.id) from benefit07 x);
        /*elsif attr.sprop = 'regionalcoefficient'  then tBUF[2]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'benefitforcoefficient' then tBUF[3]:=replace(attr.svalue,',','.'); */
       end if;
    /* elsif lower(snode) = 'paymentperiod' then
           if attr.sprop = 'paydate'              then tBUF[4]:=attr.svalue;
        elsif attr.sprop = 'paysum'               then tBUF[5]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'extradate'            then tBUF[6]:=attr.svalue;
        elsif attr.sprop = 'extrapay'             then tBUF[7]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'returndate'           then tBUF[8]:=attr.svalue;
        elsif attr.sprop = 'returnsum'            then tBUF[9]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'retentiondate'        then tBUF[10]:=attr.svalue;
        elsif attr.sprop = 'retentionsum'         then tBUF[11]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'comment'              then tBUF[12]:=attr.svalue;*/
       elsif lower(snode) = 'pay' then
           if attr.sprop = 'paydatefrom' 	      then tBUF[2]:=attr.svalue;
        elsif attr.sprop = 'paydateto' 	      	  then tBUF[3]:=attr.svalue;
        elsif attr.sprop = 'paysum' 	          then tBUF[4]:=replace(attr.svalue,',','.'); if tBUF[4] = '' then tBUF[4] = '0'; flag:=2; end if; if tBUF[4]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' sumPay при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        end if;
       elsif lower(snode) = 'surcharge' then
           if attr.sprop = 'surchargedatefrom' 	  then tBUF[5]:=attr.svalue;
        elsif attr.sprop = 'surchargedateto' 	  then tBUF[6]:=attr.svalue;
        elsif attr.sprop = 'surchargesum' 	      then tBUF[7]:=replace(attr.svalue,',','.'); if tBUF[7] = '' then tBUF[7] = '0'; flag:=2; end if; if tBUF[7]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' surchargesum при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        end if;
       elsif lower(snode) = 'refund' then
           if attr.sprop = 'refunddatefrom' 	  then tBUF[8]:=attr.svalue;
        elsif attr.sprop = 'refunddateto' 	      then tBUF[9]:=attr.svalue;
        elsif attr.sprop = 'refundsum' 	          then tBUF[10]:=replace(attr.svalue,',','.'); if tBUF[10] = '' then tBUF[10] = '0'; flag:=2; end if; if tBUF[10]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' refundsum при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        end if; 
       elsif lower(snode) = 'holddate' then
           if attr.sprop = 'holddatefrom' 	      then tBUF[11]:=attr.svalue;
        elsif attr.sprop = 'holddateto' 	      then tBUF[12]:=attr.svalue;
        elsif attr.sprop = 'holdsum' 	          then tBUF[13]:=replace(attr.svalue,',','.'); if tBUF[13] = '' then tBUF[13] = '0'; flag:=2; end if; if tBUF[13]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' holdsum при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        end if; 
       elsif lower(snode) = 'comment' then
           if attr.sprop = 'comment' 			  then tBUF[1]:=attr.svalue;
        end if;
     --benefit01
     elsif lower(snode) = 'payments' then
     	   if attr.sprop = 'resolutionnumber' 	      then tBUF[1]:=attr.svalue;
        elsif attr.sprop = 'resolutiondate' 	  then tBUF[2]:=attr.svalue;
        end if;
     elsif lower(snode) = 'periodpayments' then
     	   if attr.sprop = 'regionalcoefficient'  then tBUF[1]:=attr.svalue;
        elsif attr.sprop = 'sumtotal' 	  		  then tBUF[2]:=replace(attr.svalue,',','.'); if tBUF[2] = '' then tBUF[2] = '0'; flag:=2; end if; if tBUF[2]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' sumtotal при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        elsif attr.sprop = 'datepay' 	  	      then tBUF[3]:=attr.svalue;
        elsif attr.sprop = 'sumpay' 	  		  then tBUF[4]:=replace(attr.svalue,',','.'); if tBUF[4] = '' then tBUF[4] = '0'; flag:=2; end if; if tBUF[4]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' sumPay при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        elsif attr.sprop = 'date' 				  then tBUF[5]:=attr.svalue;
        elsif attr.sprop = 'dateextra' 			  then tBUF[6]:=attr.svalue;
        elsif attr.sprop = 'extrapay' 			  then tBUF[7]:=replace(attr.svalue,',','.'); if tBUF[7] = '' then tBUF[7] = '0'; flag:=2; end if; if tBUF[7]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' extrapay при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        elsif attr.sprop = 'datereturn' 		  then tBUF[8]:=attr.svalue;
        elsif attr.sprop = 'sumreturn' 			  then tBUF[9]:=replace(attr.svalue,',','.'); if tBUF[9] = '' then tBUF[9] = '0'; flag:=2;  end if; if tBUF[9]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' sumreturn при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        elsif attr.sprop = 'dateretention' 		  then tBUF[10]:=attr.svalue;
        elsif attr.sprop = 'sumretention' 		  then tBUF[11]:=replace(attr.svalue,',','.'); if tBUF[11] = '' then tBUF[11] = '0'; flag:=2; end if; if tBUF[11]::numeric <= 0 and flag <> 2 then flag:=0;/*raise using message =*/sERRORS:=sERRORS||chr(13)|| 'Для '||sFIO||' sumretention при заполнении должно быть больше нуля. Реестр не загружен!'; end if;
        end if; 
     end if;
   end loop;
    select count(*) into npos from file_imp s  where s.stable = 'BENEFITSRECIPIENTS';  nlevel[1]:=npos;  --тут ищем количество записей чтоб корректно обновлять таблицу
    select count(*) into npos from file_imp s  where s.stable = 'BENEFITCHILD';	       nlevel[2]:=npos;
    select count(*) into npos from file_imp s  where s.stable = 'FAMILYMEMBERS';       nlevel[3]:=npos;
    select count(*) into npos from file_imp s  where s.stable = 'BENEFIT07PURPOSE';    nlevel[4]:=npos;
    select count(*) into npos from file_imp s  where s.stable = 'BENEFIT07PAYMENT';    nlevel[5]:=npos;
    select count(*) into npos from file_imp s  where s.stable = 'REMARK'; 			   nlevel[6]:=npos;
    select count(*) into npos from file_imp s  where s.stable = 'BENEFITSRECIPIENTS';
    
   -- insert into file_imp(TABLE,col1,col2,col3,col4)
  /*   if lower(snode) = 'header'          then 
     	null;
  elsif lower(snode) = 'benefitreceiver' then 
  		insert into file_imp(sTABLE,nzap,sort,LEVEL,col1,col2,col3,col4,col5,col6,col7,col8) 
        values('BENEFITSRECIPIENTS',npos+1,1,nlevel[1]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8]);
  elsif lower(snode) = 'persondocument' or lower(snode) = 'receivercredential'  then 
        update file_imp s set col9 = tBUF[9],col10 = tBUF[10],col11 = tBUF[11],col12 = tBUF[12] where s.stable = 'BENEFITSRECIPIENTS' and s.level = nlevel[1];
  elsif lower(snode) = 'child' 		     then   
  		insert into file_imp(stable,nzap,sort,LEVEL,col1,col2,col3,col4,col9)
        values('BENEFITCHILD',npos,2,nlevel[2]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[9]);
  elsif lower(snode) = 'childdocument' or lower(snode) = 'certificateofbirth' then
        update file_imp s set col5 = tBUF[5],col6 = tBUF[6],col7 = tBUF[7],col8 = tBUF[8] where s.stable = 'BENEFITCHILD' and s.level = nlevel[2];
  elsif lower(snode) = 'familymembers'   then 
  		insert into file_imp(stable,nzap,sort,LEVEL,col1,col2,col3,col4,col5,col6,col7)
        values('FAMILYMEMBERS',npos,3,nlevel[3]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7]);    
  elsif lower(snode) = 'purpose'         then 
  		insert into file_imp(stable,nzap,sort,LEVEL,col1,col2,col3)
        VALUES('BENEFIT07PURPOSE',npos,4,nlevel[4]+1,tBUF[1],tBUF[2],tBUF[3]);
  elsif lower(snode) = 'payment' 	     then 
  		insert into file_imp(stable,nzap,sort,LEVEL,col1)
  		VALUES('BENEFIT07PAYMENT',npos,5,nlevel[5]+1,tBUF[1]);
  elsif lower(snode) = 'pay' 	     then 
        update file_imp s set col2 = tBUF[2],col3 = tBUF[3],col4 = tBUF[4] where s.stable = 'BENEFIT07PAYMENT' and s.level = nlevel[5];
  elsif lower(snode) = 'surcharge' 	     then 
        update file_imp s set col5 = tBUF[5],col6 = tBUF[6],col7 = tBUF[7] where s.stable = 'BENEFIT07PAYMENT' and s.level = nlevel[5];
        if tBUF[5] is not null or tBUF[6] is not null or tBUF[7] is not null THEN
        update file_imp s set flag = 1 where s.stable = 'BENEFITSRECIPIENTS' or s.stable = 'BENEFITCHILD'; end if; 
  elsif lower(snode) = 'refund' 	     then 
        update file_imp s set col8 = tBUF[8],col9 = tBUF[9],col10 = tBUF[10] where s.stable = 'BENEFIT07PAYMENT' and s.level = nlevel[5];
        if tBUF[8] is not null or tBUF[9] is not null or tBUF[10] is not null THEN
        update file_imp s set flag = 1 where s.stable = 'BENEFITSRECIPIENTS' or s.stable = 'BENEFITCHILD'; end if; 
  elsif lower(snode) = 'holddate' 	     then 
        update file_imp s set col11 = tBUF[11],col12 = tBUF[12],col13 = tBUF[13] where s.stable = 'BENEFIT07PAYMENT' and s.level = nlevel[5];
        if tBUF[11] is not null or tBUF[12] is not null or tBUF[13] is not null THEN
        update file_imp s set flag = 1 where s.stable = 'BENEFITSRECIPIENTS' or s.stable = 'BENEFITCHILD'; end if; 
  elsif lower(snode) = 'comment' 	     then 
  		insert into file_imp(stable,nzap,sort,LEVEL,col1)
  		VALUES('REMARK',npos,6,nlevel[6],tBUF[1]);
  --benefit01 or benefit02
  elsif lower(snode) = 'benefitassignment' 	     then 
  		insert into file_imp(stable,nzap,sort,LEVEL,col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11,col12,col13)
  		VALUES('BENEFIT01BASIS',npos,3,nlevel[3]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8],tBUF[9],tBUF[10],tBUF[11],tBUF[12],tBUF[13]);
  elsif lower(snode) = 'payments' 	     then 
  		insert into file_imp(stable,nzap,sort,LEVEL,col1,col2)
  		VALUES('BENEFIT01PURPOSE',npos,4,nlevel[4]+1,tBUF[1],tBUF[2]);
  elsif lower(snode) = 'periodpayments' 	     then 
  	    insert into file_imp(stable,nzap,sort,LEVEL,col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11)
  		VALUES('BENEFIT01PAYMENT',npos,5,nlevel[5]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8],tBUF[9],tBUF[10],tBUF[11]);   
  /*elsif lower(snode) = 'paymentperiod'   then
  		insert into file_imp(stable,col4,col5,col6,col7,col8,col9,col10,col11,col12)
        values('BENEFIT07PAYMENT',tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8],tBUF[9],tBUF[10],tBUF[11],tBUF[12])
        on conflict (stable) do update set col4 = tBUF[4],col5 = tBUF[5],col6 = tBUF[6],col7 = tBUF[7],col8 = tBUF[8],col9 = tBUF[9],col10 = tBUF[10],col11 = tBUF[11],col12 = tBUF[12];*/
  end if;*/
     if lower(snode) = 'header'          then 
     	null;
  elsif lower(snode) = 'benefitreceiver' then 
  		insert into file_imp(sTABLE,nzap,LEVEL,col1,col2,col3,col4,col5,col6,col7,col8) 
        values('BENEFITSRECIPIENTS',npos+1,nlevel[1]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8]);
  elsif lower(snode) = 'persondocument' or lower(snode) = 'receivercredential'  then 
        update file_imp s set col9 = tBUF[9],col10 = tBUF[10],col11 = tBUF[11],col12 = tBUF[12] where s.stable = 'BENEFITSRECIPIENTS' and s.level = nlevel[1];
  elsif lower(snode) = 'child' 		     then   
  		insert into file_imp(stable,nzap,LEVEL,col1,col2,col3,col4,col9)
        values('BENEFITCHILD',npos,nlevel[2]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[9]);
  elsif lower(snode) = 'childdocument' or lower(snode) = 'certificateofbirth' then
        update file_imp s set col5 = tBUF[5],col6 = tBUF[6],col7 = tBUF[7],col8 = tBUF[8] where s.stable = 'BENEFITCHILD' and s.level = nlevel[2];
  elsif lower(snode) = 'familymembers'   then 
  		insert into file_imp(stable,nzap,LEVEL,col1,col2,col3,col4,col5,col6,col7)
        values('FAMILYMEMBERS',npos,nlevel[3]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7]);    
  elsif lower(snode) = 'purpose'         then 
  		insert into file_imp(stable,nzap,LEVEL,col1,col2,col3)
        VALUES('BENEFIT07PURPOSE',npos,nlevel[4]+1,tBUF[1],tBUF[2],tBUF[3]);
  elsif lower(snode) = 'payment' 	     then 
  		insert into file_imp(stable,nzap,LEVEL,col1)
  		VALUES('BENEFIT07PAYMENT',npos,nlevel[5]+1,tBUF[1]);
  elsif lower(snode) = 'pay' 	     then 
        update file_imp s set col2 = tBUF[2],col3 = tBUF[3],col4 = tBUF[4] where s.stable = 'BENEFIT07PAYMENT' and s.level = nlevel[5];
  elsif lower(snode) = 'surcharge' 	     then 
        update file_imp s set col5 = tBUF[5],col6 = tBUF[6],col7 = tBUF[7] where s.stable = 'BENEFIT07PAYMENT' and s.level = nlevel[5];
        if tBUF[5] is not null or tBUF[6] is not null or tBUF[7] is not null THEN
        update file_imp s set flag = 1 where s.stable = 'BENEFITSRECIPIENTS' or s.stable = 'BENEFITCHILD'; end if; 
  elsif lower(snode) = 'refund' 	     then 
        update file_imp s set col8 = tBUF[8],col9 = tBUF[9],col10 = tBUF[10] where s.stable = 'BENEFIT07PAYMENT' and s.level = nlevel[5];
        if tBUF[8] is not null or tBUF[9] is not null or tBUF[10] is not null THEN
        update file_imp s set flag = 1 where s.stable = 'BENEFITSRECIPIENTS' or s.stable = 'BENEFITCHILD'; end if; 
  elsif lower(snode) = 'holddate' 	     then 
        update file_imp s set col11 = tBUF[11],col12 = tBUF[12],col13 = tBUF[13] where s.stable = 'BENEFIT07PAYMENT' and s.level = nlevel[5];
        if tBUF[11] is not null or tBUF[12] is not null or tBUF[13] is not null THEN
        update file_imp s set flag = 1 where s.stable = 'BENEFITSRECIPIENTS' or s.stable = 'BENEFITCHILD'; end if; 
  elsif lower(snode) = 'comment' 	     then 
  		insert into file_imp(stable,nzap,LEVEL,col1)
  		VALUES('REMARK',npos,nlevel[6],tBUF[1]);
  --benefit01 or benefit02
  elsif lower(snode) = 'benefitassignment' 	     then 
  		insert into file_imp(stable,nzap,LEVEL,col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11,col12,col13)
  		VALUES('BENEFIT01BASIS',npos,nlevel[3]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8],tBUF[9],tBUF[10],tBUF[11],tBUF[12],tBUF[13]);
  elsif lower(snode) = 'payments' 	     then 
  		insert into file_imp(stable,nzap,LEVEL,col1,col2)
  		VALUES('BENEFIT01PURPOSE',npos,nlevel[4]+1,tBUF[1],tBUF[2]);
  elsif lower(snode) = 'periodpayments' 	     then 
  	    insert into file_imp(stable,nzap,LEVEL,col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11)
  		VALUES('BENEFIT01PAYMENT',npos,nlevel[5]+1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8],tBUF[9],tBUF[10],tBUF[11]);   
  /*elsif lower(snode) = 'paymentperiod'   then
  		insert into file_imp(stable,col4,col5,col6,col7,col8,col9,col10,col11,col12)
        values('BENEFIT07PAYMENT',tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8],tBUF[9],tBUF[10],tBUF[11],tBUF[12])
        on conflict (stable) do update set col4 = tBUF[4],col5 = tBUF[5],col6 = tBUF[6],col7 = tBUF[7],col8 = tBUF[8],col9 = tBUF[9],col10 = tBUF[10],col11 = tBUF[11],col12 = tBUF[12];*/
  end if;
   -- values();  
   --raise using MESSAGE = 'kurLbIk'; 
   --insert into test21(sprop) VALUES('/'||snode);
   -- обработка текущего узла ...
   null;
   --raise using message = sERRORS||' @';
   if sERRORS != '' then 
   	insert into file_imp(stable,col1)	
    values('ERRORS',sERRORS);
   end if;
   -- рекурсивная обработка дочерних узлов
   for child in
     select node, cast(i as int) i
       from unnest(xpath('/'||snode||'/*', file_xml)) with ordinality as c(node,i) 
      order by i
   loop
     perform p_reestr_parse_xml(child.node, nid, child.i,sFIO,sFIO_R);
   end loop;  
   --exception when others then raise using message = tBUF[1]||' '||tBUF[2]||' '||tBUF[3]||' '||tBUF[4]||' '||tBUF[5]||' '||tBUF[6]||' '||tBUF[7]||' '||tBUF[8]||' '||tBUF[9]||' '||tBUF[10]||' '||tBUF[11]||' '||tBUF[12]||' '||tBUF[13];  
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_reestr_parse_xml (file_xml xml, id bigint, pos integer, fio text, fio_r text)
  OWNER TO magicbox;