CREATE OR REPLACE FUNCTION public.p_benefit_temp_create (
)
RETURNS void AS
$body$
declare
 rr						 record;
 s						 TEXT;
begin
  truncate sz_benefitperson_tmp;
  truncate sz_bpdate_tmp;

  for rr in
    select sz.RT_REGKEY, count(1) ncnt from SZ_BenefitPerson sz /*where sz.rt_regkey in (99, 83, 87, 49, 79, 41, 92, 8, 53)*/ group by sz.RT_REGKEY order by 2
  loop
    -- собираем времянки
    s:= 'RR'||RR.RT_REGKEY::text||'createtemp01';
    execute 'set application_name = '||s;

  --select tr.regkey, count(1) from sz_benefitperson_tmp tr group by tr.regkey
    insert into sz_benefitperson_tmp
    select p2.ID,
           p2.RT_RegKey,
           rr.RT_REGKEY
      from SZ_BenefitPerson p
      join SZ_BenefitPerson p2 on (COALESCE(p.LNAME,'-')=COALESCE(p2.LNAME,'-') /*or dbo.MatchApprox(COALESCE(p.LNAME,'-'), COALESCE(p2.LNAME,'-')) = 1*/)
                                               and (COALESCE(p.FNAME,'-')=COALESCE(p2.FNAME,'-') /*or dbo.MatchApprox(COALESCE(p.FNAME,'-'), COALESCE(p2.FNAME,'-')) = 1*/)
                                               and (COALESCE(p.MNAME,'-')=COALESCE(p2.MNAME,'-') /*or dbo.MatchApprox(COALESCE(p.MNAME,'-'), COALESCE(p2.MNAME,'-')) = 1*/)
                                               and p.DocTypeId = p2.DocTypeId
                                               and COALESCE(p.SDoc,'-')=COALESCE(p2.SDoc,'-')
                                               and COALESCE(p.NDoc,'-')=COALESCE(p2.NDoc,'-')
    where p.RT_RegKey = rr.RT_REGKEY
    group by p2.ID,
             p2.RT_RegKey
    having p2.RT_RegKey = rr.RT_REGKEY;

    s:= 'RR'||RR.RT_REGKEY::text||'createtemp02';
    execute 'set application_name = '||s;

    insert into sz_bpdate_tmp
    Select ben.Id,
           min(coalesce(pay.payDateBegin, pay.surchargeDateBegin, pay.refundDateBegin, pay.detentionDateBegin, pay.DateFrom)) as Date1,
                        Case
                          When max(coalesce(pay.payDateEnd, pay.surchargeDateEnd, pay.refundDateEnd, pay.detentionDateEnd, pay.DateTo)) Is Null
                            Then max(coalesce(pay.payDateBegin, pay.surchargeDateBegin, pay.refundDateBegin, pay.detentionDateBegin, pay.DateFrom))
                          Else
                            max(coalesce(pay.payDateEnd, pay.surchargeDateEnd, pay.refundDateEnd, pay.detentionDateEnd, pay.DateTo))
                        End Date2,
           rr.RT_REGKEY
      From sz_benefitperson_tmp p
      join SZ_Benefit ben on ben.PersonId = p.pers_id and ben.RT_RegKey = p.RT_RegKey
      left Join SZ_Payment pay On pay.BenefitId = ben.Id And pay.RT_RegKey = ben.RT_RegKey
     where p.regkey = rr.RT_REGKEY
     Group By ben.Id;
  end loop;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_benefit_temp_create ()
  OWNER TO magicbox;