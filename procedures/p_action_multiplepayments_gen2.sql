CREATE OR REPLACE FUNCTION public.p_action_multiplepayments_gen2 (
  benefitstypenamedirid bigint,
  repyear integer,
  lastnameb text,
  firstnameb text,
  patronymicb text,
  persondocumenttypeid bigint,
  docseriesb text,
  docnumberb text,
  lastnamec text,
  firstnamec text,
  patronymicc text,
  docbirthchildtypeid bigint,
  docseriesc text,
  docnumberc text,
  birthdatec date,
  uid bigint
)
RETURNS void AS
$body$
declare
	benef bigint:=0;
    childs bigint:=0;
    rNumber integer;
    nYEAR integer = repyear;
    tBenef bigint = benefitstypenamedirid;
    fl integer:=0;
    rec record;
    dub record;
    ob record;
    nUID	bigint = UID;
    all_fields_h integer:=0;  --human
    all_fields_c integer:=0;  --child
    nPeka	bigint;
    tPOSOB bigint;
    sSQL text:='';
    err_state text;
    err_table text;
    tRETURN text;
begin

if lastnameb is null and firstnameb is null and patronymicb is null and persondocumenttypeid is null and docseriesb is null and docnumberb is null/* and docdateb is null*/ then
      all_fields_h:=1;
end if;
if lastnamec is null and firstnamec is null and patronymicc is null and docbirthchildtypeid is null and docseriesc is null and docnumberc is null and birthdatec is null then
      all_fields_c:=1;
end if;
if all_fields_h != 1 then
  begin
   select s.id
     into strict benef
     from BENEFITSRECIPIENTS s
    where (lower(s.lastname) = lower(lastnameb) or lastnameb is null)
      and (lower(s.firstname) = lower(firstnameb) or firstnameb is null)
      and (lower(s.patronymic) = lower(patronymicb) or patronymicb is null)
      and (s.persondocumenttypeid = p_action_multiplepayments_gen2.persondocumenttypeid or p_action_multiplepayments_gen2.persondocumenttypeid is null)
      and (lower(s.persondocumentseries) = lower(docseriesb) or docseriesb is null)
      and (lower(s.persondocumentnumber) = lower(docnumberb) or docnumberb is null);
    --  and (s.persondocumentdate = docdateb or docdateb is null);
  exception when too_many_rows then raise using message = 'По заданному критерию найдено больше одного получателя пособия!';
  			when no_data_found then benef:=0;
  end;	 --raise using message = benef;
end if;
if all_fields_c != 1 then
  begin	
   select c.id
     into strict childs
     from benefitchild c 
    where (lower(c.lastname) = lower(lastnamec) or lastnamec is null)
      and (lower(c.firstname) = lower(firstnamec) or firstnamec is null)
      and (lower(c.patronymic) = lower(patronymicc) or patronymicc is null)
      and (c.docbirthchildtypeid = p_action_multiplepayments_gen2.docbirthchildtypeid or p_action_multiplepayments_gen2.docbirthchildtypeid is null)
      and (lower(c.docbirthchildserial) = lower(docseriesc) or docseriesc is null)
      and (lower(c.docbirthchildnumber) = lower(docnumberc) or docnumberc is null)
    --  and (c.docbirthchilddate = docnumberc or docnumberc is null)
      and (c.benefitchilddatebirth = birthdatec or birthdatec is null)
      and (c.benefitsrecipientsid = benef or benef = 0);
  exception when too_many_rows then raise using message = 'По заданному критерию найдено больше одного ребенка!';
  			when no_data_found then childs:=0;
  end;  
end if;
  --raise using message = 'FFFFFF@$%^ '|| rNumber;
  /* select r.rosternumber::integer
     into rNumber
     from benefitstypedir r
    where r.id = tBenef;*/  
  --  
  fl:=0;
   for ob in(
   select r.rosternumber::integer as rNumber, r.id as tIR
     from benefitstypedir r
    where r.id = tBenef
   )
   loop
    for rec in execute 'select s.id from benefit0'||ob.rnumber||' s where s.benefitsrecipientsid = '||benef||' limit 1'
       loop
         insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                  			   values(nUID,ob.tIR,benef) 
                            returning MULTIPLEPAYMENTS.id
                                 into nPeka; fl:=1;
       end loop;
       if ob.rnumber = 4 then
       	sSQL:='04';
       elsif ob.rnumber = 5 then
        sSQL:='05';
       elsif ob.rnumber = 7 then
       	sSQL:='07';
       end if;
    --   begin
    if ob.rnumber in (1,4,5) then
      for rec in execute 
      			  'select p.subjectsdirid,
      					 n.paydate,
                         n.paysum,
                         c.benefitchildid,
                         b.benefitsrecipientsid
       				from benefit0'||ob.rnumber||' b,
                    	 child'||sSQL||' c,
                         benefitspackets p,
                         benefit0'||ob.rnumber||'payment n
                   where (c.benefitchildid = '||childs||' or '||childs||' = 0 and '||benef||' != 0)
                     and b.id = c.benefit0'||ob.rnumber||'id
                     and p.id = b.benefitspacketsid
                     and n.benefit0'||ob.rnumber||'id = b.id 
                     and n.child0'||ob.rnumber||'id = c.id
                     and (b.benefitsrecipientsid = '||benef||' or '||benef||' = 0)'
                     
        	loop
                 if nPeka is null then
                 	insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                  			   values(nUID,ob.tIR,rec.benefitsrecipientsid) 
                            returning MULTIPLEPAYMENTS.id
                                 into nPeka;
                 end if;
            	 insert into 
                 	MULTIPLEPAYMENTSFOOTER(multiplepaymentsid/*,reason*/,benefitchildid,subjectsdirid,periodpay,sumpay,uid)
                                    values(nPeka, /*1,*/rec.benefitchildid,rec.subjectsdirid,rec.paydate, rec.paysum, nUID); fl:=1;
            end loop;
       end if;
       -- exception when others then raise using message = childs; end;
     end loop;
    if fl = 0 then raise using message = 'По заданным критериям дублирования выплат не обнаружено'; end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_multiplepayments_gen2 (benefitstypenamedirid bigint, repyear integer, lastnameb text, firstnameb text, patronymicb text, persondocumenttypeid bigint, docseriesb text, docnumberb text, lastnamec text, firstnamec text, patronymicc text, docbirthchildtypeid bigint, docseriesc text, docnumberc text, birthdatec date, uid bigint)
  OWNER TO magicbox;