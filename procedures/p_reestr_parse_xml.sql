CREATE OR REPLACE FUNCTION p_reestr_parse_xml(file_xml xml, pos integer DEFAULT 1) RETURNS void AS
$body$
 declare 
   snode text; 
   child record; 
   attr record; 
   rec record;
   tHead text;
   sqlTable text;
   nID	bigint;
   fl integer:=0;
   tBUF text[];
   
 begin 
   
   -- текущий узел
   select cast((xpath('name(/*)', file_xml))[1] as text) into snode;
      
     if lower(snode) = 'header'          then insert into benefit07(hid)          VALUES(null); select max(s.id) into nID from benefit07 s;          end if;
   -- атрибуты текущего узла
   for attr in
     select lower(cast((xpath('name(/'||snode||'/@*['||i||'])', file_xml))[1] as text)) sprop, svalue
       from unnest(cast(xpath('/'||snode||'/@*', file_xml) as text[])) with ordinality as a(svalue,i)
      order by i
   loop
     --insert into test21(sprop,svalue) VALUES(attr.sprop,attr.svalue);
     -- обработка значений атрибутов ...  
        if lower(snode) = 'header' then 
           if attr.sprop = 'from'       then tHead:=attr.svalue;
        elsif attr.sprop = 'sendertype' then tHead:=tHead||attr.svalue;
        --elsif attr.sprop = 'to' then tHead:=tHead||attr.svalue;
        elsif attr.sprop = 'date'       then --tHead:=tHead||attr.svalue; 
        			                    update BENEFICIARIESREGISTERS s set dateform = attr.svalue::date where s.id = (select max(id) from BENEFICIARIESREGISTERS);
        elsif attr.sprop = 'month' then tHead:=tHead||attr.svalue;
        elsif attr.sprop = 'year' then tHead:=tHead||attr.svalue;
        elsif attr.sprop = 'reestrpersondocumentnumber' then for rec in(select s.id
        													    from BENEFITSTYPEDIR s
                                                               where s.rosternumber = attr.svalue::integer)
                                                               loop
                                                                 update BENEFICIARIESREGISTERS s set benefitstypenamedirid = rec.id where s.id = (select max(id) from BENEFICIARIESREGISTERS);
                                                               end loop;
           for rec in (select x.id as xid,reg.id as regid,lower(se.name)||se.code||x.repyear||lpad(x.repmonth,2,'0') as cod
                 	     from benefitspackets x,  
                      		  BENEFICIARIESREGISTERS reg,
                      		  SUBJECTSDIR se  
               		    where reg.benefitspacketsid = x.id
                    	  and se.id  = x.subjectsdirid
                  	      and reg.id = (select max(id) from BENEFICIARIESREGISTERS) )
                  		 loop
                          if rec.cod <> lower(tHead) then
                          	raise using MESSAGE = 'Выбранный пакет реестра не соответствует пакету реестра в файле! ';
                          end if;
                          update benefit07 s set benefitspacketsid = rec.xid,benefitstypedirid = rec.regid where s.id = (select max(s.id) from benefit07 s);
                     end loop;
       end if;
     elsif lower(snode) = 'benefitreceiver' then 
           if attr.sprop = 'lastname'  			  then tBUF[1]:=attr.svalue; 
        elsif attr.sprop = 'firstname' 			  then tBUF[2]:=attr.svalue; 
        elsif attr.sprop = 'patronymic'           then tBUF[3]:=attr.svalue; 
        elsif attr.sprop = 'recipientscategories' then for rec in(select x.id
                                                          from RECIPIENTSCATEGORIESDIR x
                                                         where x.code = attr.svalue::integer)
                                                        loop 
                                                         tBUF[4]:=rec.id; 
                                                        end loop; 
        elsif attr.sprop = 'birthdate'            then tBUF[5]:=attr.svalue; 
        elsif attr.sprop = 'recipientaddress'     then tBUF[6]:=attr.svalue; 
        elsif attr.sprop = 'citizenship' 		  then tBUF[7]:=attr.svalue; 
        elsif attr.sprop = 'snils' 	              then tBUF[8]:=attr.svalue;
                                                       --update benefit07 s set benefitsrecipientsid = nID where s.id = (select max(s.id) from benefit07 s); 
       end if; 
           
     elsif lower(snode) = 'persondocument' then
           if attr.sprop = 'persondocumenttype'   then for rec in(select x.id
                                                          from PERSONDOCUMENTDIR x
                                                         where x.code = attr.svalue::integer)
                                                        loop 
                                                         tBUF[9]:=rec.id; 
                                                        end loop;
        elsif attr.sprop = 'persondocumentseries' then tBUF[10]:=attr.svalue;
        elsif attr.sprop = 'persondocumentnumber' then tBUF[11]:=attr.svalue;
        elsif attr.sprop = 'persondocumentdate'   then tBUF[12]:=attr.svalue;
       end if;
     elsif lower(snode) = 'child' then
     	   if attr.sprop = 'lastname'	          then tBUF[1]:=attr.svalue; 
           											   --update BENEFITCHILD s set benefitsrecipientsid = (select max(s.id) from BENEFITSRECIPIENTS s); 
        elsif attr.sprop = 'firstname'	          then tBUF[2]:=attr.svalue;
        elsif attr.sprop = 'patronymic'	          then tBUF[3]:=attr.svalue;
        elsif attr.sprop = 'birthdate'	          then tBUF[4]:=attr.svalue;
       end if;
     elsif lower(snode) = 'childdocument' then
           if attr.sprop = 'childdocumenttype'	  then for rec in(select x.id
                                                          from CERTIFICATEBIRTHDIR x
                                                         where x.code = attr.svalue::integer)
                                                        loop 
                                                         tBUF[5]:=rec.id;
                                                        end loop;
        elsif attr.sprop = 'childdocumentseries'  then tBUF[6]:=attr.svalue;
        elsif attr.sprop = 'childdocumentnumber'  then tBUF[7]:=attr.svalue; 
        elsif attr.sprop = 'childdocumentdate'	  then tBUF[8]:=attr.svalue;
       end if;
     elsif lower(snode) = 'familymembers' then
           if attr.sprop = 'familymembercount'	  then tBUF[1]:=attr.svalue;
           											   --update FAMILYMEMBERS s set benefit07id = (select max(x.id) from benefit07 x); 
        elsif attr.sprop = 'incomecertificatenumber' then tBUF[2]:=attr.svalue;
        elsif attr.sprop = 'incomecertificatedate' then tBUF[3]:=attr.svalue;
        elsif attr.sprop = 'fullname'	  		   then tBUF[4]:=attr.svalue; 
        elsif attr.sprop = 'registereddate'	       then tBUF[5]:=attr.svalue;
        elsif attr.sprop = 'totalincome'	       then tBUF[6]:=replace(attr.svalue,',','.');  
        elsif attr.sprop = 'averageincome'	       then tBUF[7]:=replace(attr.svalue,',','.');  
       end if; 
     elsif lower(snode) = 'purpose' then
           if attr.sprop = 'purposenumber'        then tBUF[1]:=attr.svalue;
           											   --update BENEFIT07PURPOSE s set benefit07id = (select max(x.id) from benefit07 x); 
        elsif attr.sprop = 'purposedate'          then tBUF[2]:=attr.svalue;
       end if;
     elsif lower(snode) = 'payment' then
     	   if attr.sprop = 'subsistence'          then tBUF[1]:=replace(attr.svalue,',','.'); 
           											   --update BENEFIT07PAYMENT s set benefit07id = (select max(x.id) from benefit07 x);
        elsif attr.sprop = 'regionalcoefficient'  then tBUF[2]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'benefitforcoefficient' then tBUF[3]:=replace(attr.svalue,',','.'); 
       end if;
     elsif lower(snode) = 'paymentperiod' then
           if attr.sprop = 'paydate'              then tBUF[4]:=attr.svalue;
        elsif attr.sprop = 'paysum'               then tBUF[5]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'extradate'            then tBUF[6]:=attr.svalue;
        elsif attr.sprop = 'extrapay'             then tBUF[7]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'returndate'           then tBUF[8]:=attr.svalue;
        elsif attr.sprop = 'returnsum'            then tBUF[9]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'retentiondate'        then tBUF[10]:=attr.svalue;
        elsif attr.sprop = 'retentionsum'         then tBUF[11]:=replace(attr.svalue,',','.'); 
        elsif attr.sprop = 'comment'              then tBUF[12]:=attr.svalue;
       end if;
     end if;
   end loop;

   -- insert into file_imp(TABLE,col1,col2,col3,col4)
     if lower(snode) = 'header'          then 
     	null;
  elsif lower(snode) = 'benefitreceiver' then 
  		insert into file_imp(sTABLE,sort,col1,col2,col3,col4,col5,col6,col7,col8) 
        values('BENEFITSRECIPIENTS',1,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8]);
  elsif lower(snode) = 'persondocument'  then 
  		insert into file_imp(stable,col9,col10,col11,col12)
        values('BENEFITSRECIPIENTS',tBUF[9],tBUF[10],tBUF[11],tBUF[12])
        on conflict (stable) do UPDATE set col9 = tBUF[9],col10 = tBUF[10],col11 = tBUF[11],col12 = tBUF[12];
  elsif lower(snode) = 'child' 		     then   
  		insert into file_imp(stable,sort,col1,col2,col3,col4)
        values('BENEFITCHILD',2,tBUF[1],tBUF[2],tBUF[3],tBUF[4]);
  elsif lower(snode) = 'childdocument' 	 then
  		insert into file_imp(stable,col5,col6,col7,col8)
        values('BENEFITCHILD',tBUF[5],tBUF[6],tBUF[7],tBUF[8])
        on conflict (stable) do update set col5 = tBUF[5],col6 = tBUF[6],col7 = tBUF[7],col8 = tBUF[8];
  elsif lower(snode) = 'familymembers'   then 
  		insert into file_imp(stable,sort,col1,col2,col3,col4,col5,col6,col7)
        values('FAMILYMEMBERS',3,tBUF[1],tBUF[2],tBUF[3],tBUF[4],tBUF[5],tBUF[6],tBUF[7]);    
  elsif lower(snode) = 'purpose'         then 
  		insert into file_imp(stable,sort,col1,col2)
        VALUES('BENEFIT07PURPOSE',4,tBUF[1],tBUF[2]);
  elsif lower(snode) = 'payment' 	     then 
  		insert into file_imp(stable,sort,col1,col2,col3)
  		VALUES('BENEFIT07PAYMENT',5,tBUF[1],tBUF[2],tBUF[3]);
  elsif lower(snode) = 'paymentperiod'   then
  		insert into file_imp(stable,col4,col5,col6,col7,col8,col9,col10,col11,col12)
        values('BENEFIT07PAYMENT',tBUF[4],tBUF[5],tBUF[6],tBUF[7],tBUF[8],tBUF[9],tBUF[10],tBUF[11],tBUF[12])
        on conflict (stable) do update set col4 = tBUF[4],col5 = tBUF[5],col6 = tBUF[6],col7 = tBUF[7],col8 = tBUF[8],col9 = tBUF[9],col10 = tBUF[10],col11 = tBUF[11],col12 = tBUF[12];
  end if;
   -- values();  
   --raise using MESSAGE = 'kurLbIk'; 
   --insert into test21(sprop) VALUES('/'||snode);
   -- обработка текущего узла ...
   null;
  
   -- рекурсивная обработка дочерних узлов
   for child in
     select node, cast(i as int) i
       from unnest(xpath('/'||snode||'/*', file_xml)) with ordinality as c(node,i) 
      order by i
   loop
     perform p_reestr_parse_xml(child.node, child.i);
   end loop;    
 end;
$body$
language plpgsql volatile;
