CREATE OR REPLACE FUNCTION public.p_report_multiplepayments_prot (
  uid bigint
)
RETURNS void AS
$body$
declare
	rec record;
    i integer:=1;
begin
delete from t_report_multiplepayments_prot t where t.uid = p_report_multiplepayments_prot.uid;
for rec in(
    select 
                               case lag(dd.pfio) OVER () when dd.pfio then null else dd.pfio end as pfio,
                               case lag(dd.pfio) OVER () when dd.pfio then null else dd.pdoc_type end as pdoc_type,
                               case lag(dd.pfio) OVER () when dd.pfio then null else dd.pdoc_ser end as pdoc_ser,
                               case lag(dd.pfio) OVER () when dd.pfio then null else dd.pdoc_num end as pdoc_num,
                               case lag(dd.pfio) OVER () when dd.pfio then null else dd.pdoc_date end as pdoc_date,
                               case when lag(dd.pfio) OVER () = dd.pfio and lag(dd.cfio) OVER () = dd.cfio then null else dd.cfio end as cfio,
                               case when lag(dd.pfio) OVER () = dd.pfio 
                               		 and lag(dd.cfio) OVER () = dd.cfio 
                                     and lag(dd.cburn) OVER () = dd.cburn
                                     and lag(dd.cdoc_type) OVER () = dd.cdoc_type
                                     and lag(dd.cdoc_ser) OVER () = dd.cdoc_ser
                                     and lag(dd.cdoc_num) OVER () = dd.cdoc_num
                                     and lag(dd.cdoc_date) OVER () = dd.cdoc_date then null else dd.cburn end as cburn,
                               case when lag(dd.pfio) OVER () = dd.pfio 
                               		 and lag(dd.cfio) OVER () = dd.cfio 
                                     and lag(dd.cburn) OVER () = dd.cburn
                                     and lag(dd.cdoc_type) OVER () = dd.cdoc_type
                                     and lag(dd.cdoc_ser) OVER () = dd.cdoc_ser
                                     and lag(dd.cdoc_num) OVER () = dd.cdoc_num
                                     and lag(dd.cdoc_date) OVER () = dd.cdoc_date then null else dd.cdoc_type end as cdoc_type,
                               case when lag(dd.pfio) OVER () = dd.pfio 
                               		 and lag(dd.cfio) OVER () = dd.cfio 
                                     and lag(dd.cburn) OVER () = dd.cburn
                                     and lag(dd.cdoc_type) OVER () = dd.cdoc_type
                                     and lag(dd.cdoc_ser) OVER () = dd.cdoc_ser
                                     and lag(dd.cdoc_num) OVER () = dd.cdoc_num
                                     and lag(dd.cdoc_date) OVER () = dd.cdoc_date then null else dd.cdoc_ser end as cdoc_ser,
                               case when lag(dd.pfio) OVER () = dd.pfio 
                               		 and lag(dd.cfio) OVER () = dd.cfio 
                                     and lag(dd.cburn) OVER () = dd.cburn
                                     and lag(dd.cdoc_type) OVER () = dd.cdoc_type
                                     and lag(dd.cdoc_ser) OVER () = dd.cdoc_ser
                                     and lag(dd.cdoc_num) OVER () = dd.cdoc_num
                                     and lag(dd.cdoc_date) OVER () = dd.cdoc_date then null else dd.cdoc_num end as cdoc_num,
                               case when lag(dd.pfio) OVER () = dd.pfio 
                               		 and lag(dd.cfio) OVER () = dd.cfio 
                                     and lag(dd.cburn) OVER () = dd.cburn
                                     and lag(dd.cdoc_type) OVER () = dd.cdoc_type
                                     and lag(dd.cdoc_ser) OVER () = dd.cdoc_ser
                                     and lag(dd.cdoc_num) OVER () = dd.cdoc_num
                                     and lag(dd.cdoc_date) OVER () = dd.cdoc_date then null else dd.cdoc_date end as cdoc_date,
                               dd.per,
                               dd.summ,
                               dd.reg,
                               dd.vid
                        
                        from(		   
						    select COALESCE(s.lastname,'')||' '||COALESCE(s.firstname,'')||' '||COALESCE(s.patronymic,'') as pfio,
                                   (select x.name from PERSONDOCUMENTDIR x where x.id = s.persondocumenttypeid) as pdoc_type,
                                   s.persondocumentseries as pdoc_ser,
                                   s.persondocumentnumber as pdoc_num,
                                   to_char(s.persondocumentdate,'dd.mm.yyyy') as pdoc_date,
                                   COALESCE(c.lastname,'')||' '||COALESCE(c.firstname,'')||' '||COALESCE(c.patronymic,'') as cfio,
                                   COALESCE(to_char(c.benefitchilddatebirth,'dd.mm.yyyy'),'') as cburn,
							  	   (select x.name from PERSONDOCUMENTDIR x where x.id = c.docbirthchildtypeid) as cdoc_type,
                                   c.docbirthchildserial as cdoc_ser,
                                   c.docbirthchildnumber as cdoc_num,
                                   to_char(c.docbirthchilddate,'dd.mm.yyyy') as cdoc_date,
                                   ff.periodpay as per,
                                   ff.sumpay as summ,
                                   ss.name as reg,
                                   (select d.name from benefitstypedir d where d.id = f.benefitstypenamedirid) as vid
                              from MULTIPLEPAYMENTS f,
								   MULTIPLEPAYMENTSFOOTER ff,
								   benefitsrecipients s,
								   benefitchild c,
							       subjectsdir ss
						     where ff.MULTIPLEPAYMENTSid = f.id
							   and s.id = f.benefitsrecipientsid
							   and c.id = ff.benefitchildid
							   and ss.id = ff.subjectsdirid
                               and f.uid = p_report_multiplepayments_prot.uid
                               order by pfio,cfio,cdoc_ser,cdoc_num) dd )
                               loop
                                if rec.pfio is null then
                                  insert into t_report_multiplepayments_prot(uid,pp,pfio,pdoc_type,pdoc_ser,pdoc_num,pdoc_date,cfio,cburn,cdoc_type,cdoc_ser,cdoc_num,cdoc_date,per,summ,vid,reg)
                                         values(p_report_multiplepayments_prot.uid,null,rec.pfio,rec.pdoc_type,rec.pdoc_ser,rec.pdoc_num,rec.pdoc_date,rec.cfio,rec.cburn,rec.cdoc_type,rec.cdoc_ser,rec.cdoc_num,rec.cdoc_date,rec.per,rec.summ,rec.vid,rec.reg);
                                else
                                  insert into t_report_multiplepayments_prot(uid,pp,pfio,pdoc_type,pdoc_ser,pdoc_num,pdoc_date,cfio,cburn,cdoc_type,cdoc_ser,cdoc_num,cdoc_date,per,summ,vid,reg)
                                         values(p_report_multiplepayments_prot.uid,i::text,rec.pfio,rec.pdoc_type,rec.pdoc_ser,rec.pdoc_num,rec.pdoc_date,rec.cfio,rec.cburn,rec.cdoc_type,rec.cdoc_ser,rec.cdoc_num,rec.cdoc_date,rec.per,rec.summ,rec.vid,rec.reg);
                                  i:=i+1;
                                end if;
                                 
                               end loop;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_report_multiplepayments_prot (uid bigint)
  OWNER TO magicbox;