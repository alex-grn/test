CREATE OR REPLACE FUNCTION public.p_action_multiplepayments_gen (
  benefitstypenamedirid bigint [],
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
	benef bigint;
    childs bigint;
    rNumber integer;
    nYEAR integer = repyear;
    tBenef bigint[] = benefitstypenamedirid;
    fl integer:=0;
    rec record;
    dub record;
    ob record;
    nUID	bigint = UID;
    all_fields_h integer:=0;  --human
    all_fields_c integer:=0;  --child
    nPeka	bigint;
    tPOSOB bigint;
    sSQL text;
begin
delete from MULTIPLEPAYMENTS s where s.uid = nUID; 
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
    where (s.lastname = lastnameb or lastnameb is null)
      and (s.firstname = firstnameb or firstnameb is null)
      and (s.patronymic = patronymicb or patronymicb is null)
      and (s.persondocumenttypeid = p_action_multiplepayments_gen.persondocumenttypeid or p_action_multiplepayments_gen.persondocumenttypeid is null)
      and (s.persondocumentseries = docseriesb or docseriesb is null)
      and (s.persondocumentnumber = docnumberb or docnumberb is null);
    --  and (s.persondocumentdate = docdateb or docdateb is null);
  exception when too_many_rows then raise using message = 'По заданному критерию найдено больше одного получателя пособия!';
  			when no_data_found then benef:=null;
  end;	 --raise using message = benef;
end if;
if all_fields_c != 1 then
  begin	
   select c.id
     into strict childs
     from benefitchild c 
    where (c.lastname = lastnamec or lastnamec is null)
      and (c.firstname = firstnamec or firstnamec is null)
      and (c.patronymic = patronymicc or patronymicc is null)
      and (c.docbirthchildtypeid = p_action_multiplepayments_gen.docbirthchildtypeid or p_action_multiplepayments_gen.docbirthchildtypeid is null)
      and (c.docbirthchildserial = docseriesc or docseriesc is null)
      and (c.docbirthchildnumber = docnumberc or docnumberc is null)
    --  and (c.docbirthchilddate = docnumberc or docnumberc is null)
      and (c.benefitchilddatebirth = birthdatec or birthdatec is null)
      and (c.benefitsrecipientsid = benef or benef is null);
  exception when too_many_rows then raise using message = 'По заданному критерию найдено больше одного ребенка!';
  			when no_data_found then childs:=null;
  end;  
end if;
  --raise using message = 'FFFFFF@$%^ '|| rNumber;
  /* select r.rosternumber::integer
     into rNumber
     from benefitstypedir r
    where r.id = tBenef;*/  
  --  
   for ob in(
   select r.rosternumber::integer as rNumber, r.id as tIR
     from benefitstypedir r
    where r.id = any( tBenef)
   )
   loop
     
 if ob.rnumber = 1 then 
           
       for REC in (select B.BENEFITSRECIPIENTSID,
                     C.BENEFITCHILDID,
                     H.ID as PAYSID,
                     P.SUBJECTSDIRID,
                     H.PAYDATE as DDATE,
                     COALESCE(H.PAYSUM, 0) as SSUM,
                     S.DOCBIRTHCHILDNUMBER,
                     S.DOCBIRTHCHILDSERIAL,
                     TO_DATE(left(H.PAYDATE, 10), 'dd.mm.yyyy') as DDATE1,
                     TO_DATE(right(H.PAYDATE, 10), 'dd.mm.yyyy') as DDATE2
                from BENEFIT01 B, BENEFITSPACKETS P, BENEFIT01PAYMENT H, CHILD C, BENEFITCHILD S
               where (B.BENEFITSRECIPIENTSID = BENEF or ALL_FIELDS_H = 1)
                 and P.ID = B.BENEFITSPACKETSID
                 and H.BENEFIT01ID = B.ID
                 and C.ID = H.CHILD01ID
                 and (C.BENEFITCHILDID = CHILDS or ALL_FIELDS_C = 1)
                 and P.REPYEAR = NYEAR
                 and S.ID = C.BENEFITCHILDID
               group by B.BENEFITSRECIPIENTSID, C.BENEFITCHILDID, H.PAYDATE, H.ID, P.SUBJECTSDIRID, S.DOCBIRTHCHILDNUMBER, S.DOCBIRTHCHILDSERIAL)
  loop
    if (select count(*)
          from BENEFIT01 B, BENEFITSPACKETS P, BENEFIT01PAYMENT H, CHILD C, BENEFITCHILD S
         where B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           and P.ID = B.BENEFITSPACKETSID
           and H.BENEFIT01ID = B.ID
           and C.ID = H.CHILD01ID
              --and c.benefitchildid = rec.benefitchildid
           and S.ID = C.BENEFITCHILDID
           and S.DOCBIRTHCHILDNUMBER = REC.DOCBIRTHCHILDNUMBER
           and S.DOCBIRTHCHILDSERIAL = REC.DOCBIRTHCHILDSERIAL
           and H.ID != REC.PAYSID
           and P.REPYEAR = NYEAR
           and (TO_DATE(left(H.PAYDATE, 10), 'dd.mm.yyyy') between REC.DDATE1 and REC.DDATE2 
            or TO_DATE(right(H.PAYDATE, 10), 'dd.mm.yyyy') between REC.DDATE1 and REC.DDATE2 
            or (TO_DATE(left(H.PAYDATE, 10), 'dd.mm.yyyy') >= REC.DDATE1 
            and TO_DATE(right(H.PAYDATE, 10), 'dd.mm.yyyy') <= REC.DDATE2))) > 0
    then
      if (select count(*)
            from MULTIPLEPAYMENTS M
           where M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
             and M.BENEFITSTYPENAMEDIRID = OB.TIR
             and M.UID = NUID) > 0
      then
        select M.ID
          into NPEKA
          from MULTIPLEPAYMENTS M
         where M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           and M.BENEFITSTYPENAMEDIRID = OB.TIR
           and M.UID = NUID;
      else
        insert into MULTIPLEPAYMENTS (UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) values (NUID, OB.TIR, REC.BENEFITSRECIPIENTSID) returning MULTIPLEPAYMENTS.ID into NPEKA;
        FL := 1;
      end if;
      insert into MULTIPLEPAYMENTSFOOTER (MULTIPLEPAYMENTSID, REASON, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, UID) values (NPEKA, 1, REC.BENEFITCHILDID, REC.SUBJECTSDIRID, REC.DDATE, REC.SSUM, NUID);
      FL := 1;
    end if;
    if (select count(*)
          from BENEFIT01 B, BENEFITSPACKETS P, BENEFIT01PAYMENT H, CHILD C, BENEFITCHILD S
         where P.ID = B.BENEFITSPACKETSID
           and H.BENEFIT01ID = B.ID
           and C.ID = H.CHILD01ID
           and S.ID = C.BENEFITCHILDID
           and S.DOCBIRTHCHILDNUMBER = REC.DOCBIRTHCHILDNUMBER
           and S.DOCBIRTHCHILDSERIAL = REC.DOCBIRTHCHILDSERIAL
           and H.ID != REC.PAYSID
           and P.REPYEAR = NYEAR
           and (TO_DATE(left(H.PAYDATE, 10), 'dd.mm.yyyy') between REC.DDATE1 and REC.DDATE2 
            or TO_DATE(right(H.PAYDATE, 10), 'dd.mm.yyyy') between REC.DDATE1 and REC.DDATE2 
            or (TO_DATE(left(H.PAYDATE, 10), 'dd.mm.yyyy') >= REC.DDATE1 
            and TO_DATE(right(H.PAYDATE, 10), 'dd.mm.yyyy') <= REC.DDATE2))) > 0
    then
      if (select count(*)
            from MULTIPLEPAYMENTS M
           where M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
             and M.BENEFITSTYPENAMEDIRID = OB.TIR
             and M.UID = NUID) > 0
      then
        select M.ID
          into NPEKA
          from MULTIPLEPAYMENTS M
         where M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           and M.BENEFITSTYPENAMEDIRID = OB.TIR
           and M.UID = NUID;
      else
        insert into MULTIPLEPAYMENTS (UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) values (NUID, OB.TIR, REC.BENEFITSRECIPIENTSID) returning MULTIPLEPAYMENTS.ID into NPEKA;
        FL := 1;
      end if;
      if (select count(*)
            from MULTIPLEPAYMENTSFOOTER M
           where M.MULTIPLEPAYMENTSID = NPEKA
             and M.REASON = '1'
             and M.BENEFITCHILDID = REC.BENEFITCHILDID
             and M.SUBJECTSDIRID = DUB.SUBJECTSDIRID
             and M.PERIODPAY = DUB.DDATE
             and M.SUMPAY = DUB.SSUM
             and M.UID = NUID) = 0
      then
        insert into MULTIPLEPAYMENTSFOOTER
          (MULTIPLEPAYMENTSID, REASON, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, UID)
        values
          (NPEKA, 1, REC.BENEFITCHILDID, DUB.SUBJECTSDIRID, DUB.DDATE, DUB.SSUM, NUID);
        FL := 1;
      end if;
    end if;
  end loop;
                   
                   
                   
                   
    elsif ob.rnumber = 2 then
    	       
      for REC in (select B.BENEFITSRECIPIENTSID,
                     H.ID as PAYSID,
                     P.SUBJECTSDIRID,
                     H.PAYDATE as DDATE,
                     COALESCE(H.PAYSUM, 0) as SSUM,
                     P.SUBJECTSDIRID,
                     TO_DATE(left(H.PAYDATE, 10), 'dd.mm.yyyy') as DDATE1,
                     TO_DATE(right(H.PAYDATE, 10), 'dd.mm.yyyy') as DDATE2
                from BENEFIT02 B, BENEFITSPACKETS P, BENEFIT02PAYMENT H
               where (B.BENEFITSRECIPIENTSID = BENEF or ALL_FIELDS_H = 1)
                 and P.ID = B.BENEFITSPACKETSID
                 and H.BENEFIT02ID = B.ID
                 and P.REPYEAR = NYEAR
               group by B.BENEFITSRECIPIENTSID, H.PAYDATE, H.ID, P.SUBJECTSDIRID)
  loop
    if (select count(*)
          from BENEFIT02 B, BENEFITSPACKETS P, BENEFIT02PAYMENT H
         where B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           and P.ID = B.BENEFITSPACKETSID
           and H.BENEFIT02ID = B.ID
           and H.ID != REC.PAYSID
           and P.REPYEAR = NYEAR
           and (TO_DATE(left(H.PAYDATE, 10), 'dd.mm.yyyy') between REC.DDATE1 and REC.DDATE2 
             or TO_DATE(right(H.PAYDATE, 10), 'dd.mm.yyyy') between REC.DDATE1 and REC.DDATE2 
             or (TO_DATE(left(H.PAYDATE, 10), 'dd.mm.yyyy') >= REC.DDATE1 
                 and TO_DATE(right(H.PAYDATE, 10), 'dd.mm.yyyy') <= REC.DDATE2))) > 0
    then
      if (select count(*) from MULTIPLEPAYMENTS M where M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID and M.BENEFITSTYPENAMEDIRID = OB.TIR and M.UID = NUID) > 0 then
        select M.ID
          into NPEKA
          from MULTIPLEPAYMENTS M
         where M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           and M.BENEFITSTYPENAMEDIRID = OB.TIR
           and M.UID = NUID;
      else
        insert into MULTIPLEPAYMENTS (UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) 
        values (NUID, OB.TIR, REC.BENEFITSRECIPIENTSID) returning MULTIPLEPAYMENTS.ID into NPEKA;
        FL := 1;
      end if;
      insert into MULTIPLEPAYMENTSFOOTER (MULTIPLEPAYMENTSID, REASON, SUBJECTSDIRID, PERIODPAY, SUMPAY, UID) 
      values (NPEKA, 1, REC.SUBJECTSDIRID, REC.DDATE, REC.SSUM, NUID);
      FL := 1;
    end if;
  end loop;
    
    elsif ob.rnumber = 3 then 
   
       for rec in (
       				select b.benefitsrecipientsid, h.id as paysID, p.subjectsdirid, h.paydate as ddate,
                    		COALESCE(h.paysum,0) as ssum,
                           to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') as ddate1, to_date(right(COALESCE(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),h.retentiondate,h.returndate,h.extradate),10),'dd.mm.yyyy') as ddate2
        	 		  from benefit03 b, benefitspackets p, benefit03payment h
       				 where (b.benefitsrecipientsid = benef or all_fields_h = 1)
         	   		   and p.id = b.benefitspacketsid
               		   and h.benefit03id = b.id
          	  		   and p.repyear = nYEAR 
                       group by b.benefitsrecipientsid,h.paydate, h.id, p.subjectsdirid
       			   ) 
                   loop
                   	  if (
                      			   select count(*)
        	 		  				 from benefit03 b, benefitspackets p, benefit03payment h
       				                where b.benefitsrecipientsid = rec.benefitsrecipientsid
         	   		   				  and p.id = b.benefitspacketsid
               		                  and h.benefit03id = b.id
                                      and h.id != rec.paysID
          	  		                  and p.repyear = nYEAR 
                                      and (to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate1
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate1
                                       or to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate2
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate2
                                      or to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate1
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate2)
                      			  ) > 0 then
                                  
                                  	if( select count(*)
                                       from MULTIPLEPAYMENTS m
                                      where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID) > 0 then
                                      select m.id into nPeka from MULTIPLEPAYMENTS m where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID;
                                    else
                                      insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                                            values(nUID,ob.tIR,rec.benefitsrecipientsid) RETURNING MULTIPLEPAYMENTS.id into nPeka; fl:=1;
                                    end if;
                                  	 insert into MULTIPLEPAYMENTSFOOTER(multiplepaymentsid,reason,subjectsdirid,periodpay,sumpay,uid)
                                         values(nPeka,1,rec.subjectsdirid,to_char(rec.ddate,'dd.mm.yyyy'), rec.ssum,nuid); fl:=1;
                                  end if;
                   end loop;
                   
    elsif ob.rnumber = 4 then 
         
       for rec in (
       				select b.benefitsrecipientsid, c.benefitchildid, h.id as paysID, p.subjectsdirid, h.paydate as ddate,
                    		COALESCE(h.paysum,0) as ssum, s.docbirthchildnumber, s.docbirthchildserial,
                           to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') as ddate1, to_date(right(COALESCE(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),h.retentiondate,h.returndate,h.extradate),10),'dd.mm.yyyy') as ddate2
        	 		  from benefit04 b, benefitspackets p, benefit04payment h, child04 c, benefitchild s
       				 where (b.benefitsrecipientsid = benef or all_fields_h = 1)
         	   		   and p.id = b.benefitspacketsid
               		   and h.benefit04id = b.id
               		   and c.id = h.child04id
               		   and (c.benefitchildid = childs or all_fields_c = 1)
          	  		   and p.repyear = nYEAR
                       and s.id = c.benefitchildid 
                       group by b.benefitsrecipientsid,c.benefitchildid,h.paydate, h.id, p.subjectsdirid,s.docbirthchildnumber, s.docbirthchildserial
       			   ) 
                   loop
                   	  if (
                      			   select count(*)
        	 		  				 from benefit04 b, benefitspackets p, benefit04payment h, child04 c, benefitchild s
       				                where b.benefitsrecipientsid = rec.benefitsrecipientsid
         	   		   				  and p.id = b.benefitspacketsid
               		                  and h.benefit04id = b.id
               		                  and c.id = h.child04id
                                      and s.id = c.benefitchildid
                                      and s.docbirthchildnumber = rec.docbirthchildnumber
                                      and s.docbirthchildserial = rec.docbirthchildserial
                                      and h.id != rec.paysID
          	  		                  and p.repyear = nYEAR 
                                      and (to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate1
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate1
                                       or to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate2
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate2
                                      or to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate1
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate2)
                      			  ) > 0 then
                                  	if( select count(*)
                                       from MULTIPLEPAYMENTS m
                                      where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID) > 0 then
                                      select m.id into nPeka from MULTIPLEPAYMENTS m where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID;
                                    else
                                      insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                                            values(nUID,ob.tIR,rec.benefitsrecipientsid) RETURNING MULTIPLEPAYMENTS.id into nPeka; fl:=1;
                                    end if;
                                  	 insert into MULTIPLEPAYMENTSFOOTER(multiplepaymentsid,reason,benefitchildid,subjectsdirid,periodpay,sumpay,uid)
                                         values(nPeka,1,rec.benefitchildid,rec.subjectsdirid,to_char(rec.ddate,'dd.mm.yyyy'), rec.ssum,nuid); fl:=1;
                                  end if;
                        if (
                      			   select count(*)
        	 		  				 from benefit04 b, benefitspackets p, benefit04payment h, child04 c, benefitchild s
       				                where p.id = b.benefitspacketsid
               		                  and h.benefit04id = b.id
               		                  and c.id = h.child04id
               		                  --and c.benefitchildid = rec.benefitchildid
                                      and s.id = c.benefitchildid
                                      and s.docbirthchildnumber = rec.docbirthchildnumber
                                      and s.docbirthchildserial = rec.docbirthchildserial
                                      and h.id != rec.paysID
          	  		                  and p.repyear = nYEAR 
                                      and (to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate1
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate1
                                       or to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate2
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate2
                                      or to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate1
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate2)
                      			  ) > 0 then
                                  	if( select count(*)
                                       from MULTIPLEPAYMENTS m
                                      where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID) > 0 then
                                      select m.id into nPeka from MULTIPLEPAYMENTS m where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID;
                                    else
                                      insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                                            values(nUID,ob.tIR,rec.benefitsrecipientsid) RETURNING MULTIPLEPAYMENTS.id into nPeka; fl:=1;
                                    end if; 
                                  	 insert into MULTIPLEPAYMENTSFOOTER(multiplepaymentsid,reason,benefitchildid,subjectsdirid,periodpay,sumpay,uid)
                                         values(nPeka,1,rec.benefitchildid,rec.subjectsdirid,to_char(rec.ddate,'dd.mm.yyyy'), rec.ssum,nuid); fl:=1;
                                  end if;
                   end loop;
                   
    elsif ob.rnumber = 5 then 
    
       for rec in (
       				select b.benefitsrecipientsid, c.benefitchildid, h.id as paysID, p.subjectsdirid, h.paydate as ddate,
                    		COALESCE(h.paysum,0) as ssum, s.docbirthchildnumber, s.docbirthchildserial,
                           to_date(left(h.paydate,10),'dd.mm.yyyy') as ddate1, to_date(right(h.paydate,10),'dd.mm.yyyy') as ddate2
        	 		  from benefit05 b, benefitspackets p, benefit05payment h, child05 c, benefitchild s
       				 where (b.benefitsrecipientsid = benef or all_fields_h = 1)
         	   		   and p.id = b.benefitspacketsid
               		   and h.benefit05id = b.id
               		   and c.id = h.child05id
               		   and (c.benefitchildid = childs or all_fields_c = 1)
          	  		   and p.repyear = nYEAR 
                       and s.id = c.benefitchildid
                       group by b.benefitsrecipientsid,c.benefitchildid,h.paydate, h.id, p.subjectsdirid,s.docbirthchildnumber, s.docbirthchildserial
       			   ) 
                   loop
                   	  if (
                      			   select count(*)
        	 		  				 from benefit05 b, benefitspackets p, benefit05payment h, child05 c, benefitchild s
       				                where b.benefitsrecipientsid = rec.benefitsrecipientsid
         	   		   				  and p.id = b.benefitspacketsid
               		                  and h.benefit05id = b.id
               		                  and c.id = h.child05id
                                      and s.id = c.benefitchildid
                                     and s.docbirthchildnumber = rec.docbirthchildnumber
                                     and s.docbirthchildserial = rec.docbirthchildserial
                                      and h.id != rec.paysID
          	  		                  and p.repyear = nYEAR 
                                      and (to_date(left(h.paydate,10),'dd.mm.yyyy') <= rec.ddate1
                                      and to_date(right(h.paydate,10),'dd.mm.yyyy') >= rec.ddate1
                                       or to_date(left(h.paydate,10),'dd.mm.yyyy') <= rec.ddate2
                                      and to_date(right(h.paydate,10),'dd.mm.yyyy') >= rec.ddate2
                                      OR to_date(left(h.paydate,10),'dd.mm.yyyy') >= rec.ddate1
                                      and to_date(right(h.paydate,10),'dd.mm.yyyy') <= rec.ddate2)
                      			  ) > 0 then
                                  	if( select count(*)
                                       from MULTIPLEPAYMENTS m
                                      where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID) > 0 then
                                      select m.id into nPeka from MULTIPLEPAYMENTS m where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID;
                                    else
                                      insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                                            values(nUID,ob.tIR,rec.benefitsrecipientsid) RETURNING MULTIPLEPAYMENTS.id into nPeka; fl:=1;
                                    end if;
                                  	if (select count(*)
                                     	  from MULTIPLEPAYMENTSFOOTER m 
                                    	 where m.multiplepaymentsid = nPeka 
                                    	   and m.reason = '1'
                                           and m.benefitchildid = rec.benefitchildid
                                           and m.subjectsdirid = dub.subjectsdirid
                                           and m.periodpay = dub.ddate
                                           and m.sumpay = dub.ssum and m.uid = nUID) = 0 then 
                                  	 insert into MULTIPLEPAYMENTSFOOTER(multiplepaymentsid,reason,benefitchildid,subjectsdirid,periodpay,sumpay,uid)
                                         values(nPeka,1,rec.benefitchildid,rec.subjectsdirid,rec.ddate, rec.ssum,nuid); fl:=1;
                                    end if;
                                  end if;
                        if (
                      			   select count(*)
        	 		  				 from benefit05 b, benefitspackets p, benefit05payment h, child05 c, benefitchild s
       				                where p.id = b.benefitspacketsid
               		                  and h.benefit05id = b.id
               		                  and c.id = h.child05id
                                      and s.id = c.benefitchildid
                                     and s.docbirthchildnumber = rec.docbirthchildnumber
                                     and s.docbirthchildserial = rec.docbirthchildserial
                                      and h.id != rec.paysID
          	  		                  and p.repyear = nYEAR 
                                      and (to_date(left(h.paydate,10),'dd.mm.yyyy') <= rec.ddate1
                                      and to_date(right(h.paydate,10),'dd.mm.yyyy') >= rec.ddate1
                                       or to_date(left(h.paydate,10),'dd.mm.yyyy') <= rec.ddate2
                                      and to_date(right(h.paydate,10),'dd.mm.yyyy') >= rec.ddate2
                                      OR to_date(left(h.paydate,10),'dd.mm.yyyy') >= rec.ddate1
                                      and to_date(right(h.paydate,10),'dd.mm.yyyy') <= rec.ddate2)
                      			  ) > 0 then
                                  	if( select count(*)
                                       from MULTIPLEPAYMENTS m
                                      where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID) > 0 then
                                      select m.id into nPeka from MULTIPLEPAYMENTS m where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID;
                                    else
                                      insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                                            values(nUID,ob.tIR,rec.benefitsrecipientsid) RETURNING MULTIPLEPAYMENTS.id into nPeka; fl:=1;
                                    end if; 
                                  	 insert into MULTIPLEPAYMENTSFOOTER(multiplepaymentsid,reason,benefitchildid,subjectsdirid,periodpay,sumpay, uid)
                                         values(nPeka,1,rec.benefitchildid,rec.subjectsdirid,rec.ddate, rec.ssum,nuid); fl:=1;
                                  end if;
                   end loop;    
    
    elsif ob.rnumber = 6 then 
   
       for rec in (
       				select b.benefitsrecipientsid, h.id as paysID, p.subjectsdirid, h.paydate as ddate,
                    		COALESCE(h.paysum,0) as ssum,
                           to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') as ddate1, to_date(right(COALESCE(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),h.retentiondate,h.returndate,h.extradate),10),'dd.mm.yyyy') as ddate2
        	 		  from benefit06 b, benefitspackets p, benefit06payment h
       				 where (b.benefitsrecipientsid = benef or all_fields_h = 1)
         	   		   and p.id = b.benefitspacketsid
               		   and h.benefit06id = b.id
          	  		   and p.repyear = nYEAR 
                       group by b.benefitsrecipientsid,h.paydate, h.id, p.subjectsdirid
       			   ) 
                   loop
                   	  if (
                      			   select count(*)
        	 		  				 from benefit06 b, benefitspackets p, benefit06payment h
       				                where b.benefitsrecipientsid = rec.benefitsrecipientsid
         	   		   				  and p.id = b.benefitspacketsid
               		                  and h.benefit06id = b.id
                                      and h.id != rec.paysID
          	  		                  and p.repyear = nYEAR 
                                      and (to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate1
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate1
                                       or to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate2
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate2
                                      or to_date(left(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') >= rec.ddate1
                                      and to_date(right(to_char(h.paydate,'dd.mm.yyyy')||'-'||to_char(h.paydate,'dd.mm.yyyy'),10),'dd.mm.yyyy') <= rec.ddate2)
                      			  ) > 0 then
                                  	if( select count(*)
                                       from MULTIPLEPAYMENTS m
                                      where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID) > 0 then
                                      select m.id into nPeka from MULTIPLEPAYMENTS m where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID;
                                    else
                                      insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                                            values(nUID,ob.tIR,rec.benefitsrecipientsid) RETURNING MULTIPLEPAYMENTS.id into nPeka; fl:=1;
                                    end if;
                                  	 insert into MULTIPLEPAYMENTSFOOTER(multiplepaymentsid,reason,subjectsdirid,periodpay,sumpay,uid)
                                         values(nPeka,1,rec.subjectsdirid,to_char(rec.ddate,'dd.mm.yyyy'), rec.ssum,nuid); fl:=1;
                                  end if;
                   end loop;
                   
    elsif ob.rnumber = 7 then 
   
       for rec in (
       				select b.benefitsrecipientsid, c.benefitchildid, h.id as paysID, p.subjectsdirid, COALESCE(to_char(h.paydatefrom,'dd.mm.yyyy')||'-'||to_char(h.paydateto,'dd.mm.yyyy'),to_char(h.surchargedatefrom,'dd.mm.yyyy')||'-'||to_char(h.surchargedateto,'dd.mm.yyyy'),to_char(h.refunddatefrom,'dd.mm.yyyy')||'-'||to_char(h.refunddateto,'dd.mm.yyyy'),to_char(h.holddatefrom,'dd.mm.yyyy')||'-'||to_char(h.holddateto,'dd.mm.yyyy')) as ddate,
                    		COALESCE(h.paysum,0) as ssum,
                           COALESCE(h.paydatefrom,h.surchargedatefrom,h.refunddatefrom,h.holddatefrom) as ddate1, COALESCE(h.paydateto,h.surchargedateto,h.refunddateto,h.holddateto) as ddate2
        	 		  from benefit07 b, benefitspackets p, benefit07payment h, child07 c
       				 where (b.benefitsrecipientsid = benef or all_fields_h = 1)
         	   		   and p.id = b.benefitspacketsid
               		   and h.benefit07id = b.id
               		   and c.id = h.child07id
               		   and (c.benefitchildid = childs or all_fields_c = 1)
          	  		   and p.repyear = nYEAR 
                       group by b.benefitsrecipientsid,c.benefitchildid,COALESCE(to_char(h.paydatefrom,'dd.mm.yyyy')||'-'||to_char(h.paydateto,'dd.mm.yyyy'),to_char(h.surchargedatefrom,'dd.mm.yyyy')||'-'||to_char(h.surchargedateto,'dd.mm.yyyy'),to_char(h.refunddatefrom,'dd.mm.yyyy')||'-'||to_char(h.refunddateto,'dd.mm.yyyy'),to_char(h.holddatefrom,'dd.mm.yyyy')||'-'||to_char(h.holddateto,'dd.mm.yyyy')), h.id, p.subjectsdirid
       			   ) 
                   loop
                   	  for dub in (
                      			   select b.benefitsrecipientsid, COALESCE(to_char(h.paydatefrom,'dd.mm.yyyy')||'-'||to_char(h.paydateto,'dd.mm.yyyy'),to_char(h.surchargedatefrom,'dd.mm.yyyy')||'-'||to_char(h.surchargedateto,'dd.mm.yyyy'),to_char(h.refunddatefrom,'dd.mm.yyyy')||'-'||to_char(h.refunddateto,'dd.mm.yyyy'),to_char(h.holddatefrom,'dd.mm.yyyy')||'-'||to_char(h.holddateto,'dd.mm.yyyy')) as ddate,
                                   		  COALESCE(h.paysum,0) as ssum, p.subjectsdirid
        	 		  				 from benefit07 b, benefitspackets p, benefit07payment h, child07 c
       				                where b.benefitsrecipientsid = rec.benefitsrecipientsid
         	   		   				  and p.id = b.benefitspacketsid
               		                  and h.benefit07id = b.id
               		                  and c.id = h.child07id
               		                  and c.benefitchildid = rec.benefitchildid
                                      and h.id != rec.paysID
          	  		                  and p.repyear = nYEAR 
                                      and (COALESCE(h.paydatefrom,h.surchargedatefrom,h.refunddatefrom,h.holddatefrom) <= rec.ddate1
                                      and COALESCE(h.paydateto,h.surchargedateto,h.refunddateto,h.holddateto) >= rec.ddate1
                                       or COALESCE(h.paydatefrom,h.surchargedatefrom,h.refunddatefrom,h.holddatefrom) <= rec.ddate2
                                      and COALESCE(h.paydateto,h.surchargedateto,h.refunddateto,h.holddateto) >= rec.ddate2)
                      			  ) 
                                  loop
                                  	if( select count(*)
                                       from MULTIPLEPAYMENTS m
                                      where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID) > 0 then
                                      select m.id into nPeka from MULTIPLEPAYMENTS m where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID;
                                    else
                                      insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                                            values(nUID,ob.tIR,rec.benefitsrecipientsid) RETURNING MULTIPLEPAYMENTS.id into nPeka; fl:=1;
                                    end if;
                                  	if (select count(*)
                                     	  from MULTIPLEPAYMENTSFOOTER m 
                                    	 where m.multiplepaymentsid = nPeka 
                                    	   and m.reason = '1'
                                           and m.benefitchildid = rec.benefitchildid
                                           and m.subjectsdirid = dub.subjectsdirid
                                           and m.periodpay = dub.ddate
                                           and m.sumpay = dub.ssum and m.uid = nUID) = 0 then 
                                  	 insert into MULTIPLEPAYMENTSFOOTER(multiplepaymentsid,reason,benefitchildid,subjectsdirid,periodpay,sumpay,uid)
                                         values(nPeka,1,rec.benefitchildid,dub.subjectsdirid,dub.ddate, dub.ssum,nuid); fl:=1;
                                    end if;
                                  end loop;
                      for dub in (
                      			   select b.benefitsrecipientsid, COALESCE(to_char(h.paydatefrom,'dd.mm.yyyy')||'-'||to_char(h.paydateto,'dd.mm.yyyy'),to_char(h.surchargedatefrom,'dd.mm.yyyy')||'-'||to_char(h.surchargedateto,'dd.mm.yyyy'),to_char(h.refunddatefrom,'dd.mm.yyyy')||'-'||to_char(h.refunddateto,'dd.mm.yyyy'),to_char(h.holddatefrom,'dd.mm.yyyy')||'-'||to_char(h.holddateto,'dd.mm.yyyy')) as ddate,
                                   		  COALESCE(h.paysum,0) as ssum, p.subjectsdirid
        	 		  				 from benefit07 b, benefitspackets p, benefit07payment h, child07 c
       				                where p.id = b.benefitspacketsid
               		                  and h.benefit07id = b.id
               		                  and c.id = h.child07id
               		                  and c.benefitchildid = rec.benefitchildid
                                      and h.id != rec.paysID
          	  		                  and p.repyear = nYEAR 
                                      and (COALESCE(h.paydatefrom,h.surchargedatefrom,h.refunddatefrom,h.holddatefrom) <= rec.ddate1
                                      and COALESCE(h.paydateto,h.surchargedateto,h.refunddateto,h.holddateto) >= rec.ddate1
                                       or COALESCE(h.paydatefrom,h.surchargedatefrom,h.refunddatefrom,h.holddatefrom) <= rec.ddate2
                                      and COALESCE(h.paydateto,h.surchargedateto,h.refunddateto,h.holddateto) >= rec.ddate2)
                      			  ) 
                                  loop
                                  	if( select count(*)
                                       from MULTIPLEPAYMENTS m
                                      where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID) > 0 then
                                      select m.id into nPeka from MULTIPLEPAYMENTS m where m.benefitsrecipientsid = rec.benefitsrecipientsid and m.benefitstypenamedirid = ob.tIR and m.uid = nUID;
                                    else
                                      insert into MULTIPLEPAYMENTS(uid,benefitstypenamedirid,benefitsrecipientsid) 
                                            values(nUID,ob.tIR,rec.benefitsrecipientsid) RETURNING MULTIPLEPAYMENTS.id into nPeka; fl:=1;
                                    end if;
                                  	if (select count(*)
                                     	  from MULTIPLEPAYMENTSFOOTER m 
                                    	 where m.multiplepaymentsid = nPeka 
                                    	   and m.reason = '1'
                                           and m.benefitchildid = rec.benefitchildid
                                           and m.subjectsdirid = dub.subjectsdirid
                                           and m.periodpay = dub.ddate
                                           and m.sumpay = dub.ssum and m.uid = nUID) = 0 then 
                                  	 insert into MULTIPLEPAYMENTSFOOTER(multiplepaymentsid,reason,benefitchildid,subjectsdirid,periodpay,sumpay, uid)
                                         values(nPeka,1,rec.benefitchildid,dub.subjectsdirid,dub.ddate, dub.ssum, nuid); fl:=1;
                                    end if;
                                  end loop;
                   end loop;
    
    end if;
    end loop; 
    if fl = 0 then raise using message = 'По заданным критериям дублирования выплат не обнаружено'; end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_multiplepayments_gen (benefitstypenamedirid bigint [], repyear integer, lastnameb text, firstnameb text, patronymicb text, persondocumenttypeid bigint, docseriesb text, docnumberb text, lastnamec text, firstnamec text, patronymicc text, docbirthchildtypeid bigint, docseriesc text, docnumberc text, birthdatec date, uid bigint)
  OWNER TO magicbox;