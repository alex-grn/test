-- Function: public.p_action_financeelcom_recount_fprov(bigint)

-- DROP FUNCTION public.p_action_financeelcom_recount_fprov(bigint);

CREATE OR REPLACE FUNCTION public.p_action_financeelcom_recount_fprov(id bigint)
  RETURNS void AS
$BODY$
declare
  rec record;
  nELECTCOMMINCAMPID bigint:=(select f.ELECTCOMMINCAMPID from FINANCEELCOM f where f.ID = P_ACTION_FINANCEELCOM_RECOUNT_FPROV.ID);
begin

  for rec in (
      select t.id, sum(COALESCE(fk.SUMFINTIKCEN,0)) as summ1, fk.DOCDATE
        from FINANCEELCOM f,
             TYPEEXP t,
             ELECTCOMMINCAMP e,
             ELECTCOMMITTEE i,
             ELECTCOMMITTEE ik,
             ELECTCOMMINCAMP ek,
             FINANCEELCOM fk
       where f.ELECTCOMMINCAMPID = nELECTCOMMINCAMPID
         and t.ID = f.TYPEEXPID
         and t.TYPEEXPENSES ilike 'salary'
         and e.ID = f.ELECTCOMMINCAMPID
         and i.ID = e.ELECTCOMMITTEEID
         and (i.LEVELELCOMMITTEE ilike 'territory' or i.LEVELELCOMMITTEE ilike 'circuit')
         and ik.idgasparecom = i.idgasecom
         and ek.electcampaignid = e.electcampaignid
         and ek.ELECTCOMMITTEEID = ik.id
         and fk.ELECTCOMMINCAMPID = ek.id
         and fk.TYPEEXPID = t.id
         and F.DOCDATE = fk.DOCDATE
         group by t.id, fk.DOCDATE
  )
  LOOP
       update FINANCEELCOM f set SUMFINTIKCEN = rec.summ1 where f.ELECTCOMMINCAMPID = nELECTCOMMINCAMPID and f.typeexpid = rec.id and F.DOCDATE = REC.DOCDATE;
  END LOOP;
  
  for rec in (
      select t.id,sum(COALESCE(fk.sumfinuik,0)) as summ, fk.DOCDATE
        from FINANCEELCOM f,
             TYPEEXP t,
             ELECTCOMMINCAMP e,
             ELECTCOMMITTEE i,
             ELECTCOMMITTEE ik,
             ELECTCOMMINCAMP ek,
             FINANCEELCOM fk
       where f.ELECTCOMMINCAMPID = nELECTCOMMINCAMPID
         and t.ID = f.TYPEEXPID
         and e.ID = f.ELECTCOMMINCAMPID
         and i.ID = e.ELECTCOMMITTEEID
         and (i.LEVELELCOMMITTEE ilike 'territory' or i.LEVELELCOMMITTEE ilike 'circuit')
         and ik.idgasparecom = i.idgasecom
         and ek.electcampaignid = e.electcampaignid
         and ek.ELECTCOMMITTEEID = ik.id
         and fk.ELECTCOMMINCAMPID = ek.id
         and fk.TYPEEXPID = t.id
         and F.DOCDATE = fk.DOCDATE
         group by t.id, fk.DOCDATE
  )
  LOOP
       update FINANCEELCOM f set sumfinuik = rec.summ where f.ELECTCOMMINCAMPID = nELECTCOMMINCAMPID and f.typeexpid = rec.id and F.DOCDATE = REC.DOCDATE;
  END LOOP;
  
  
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_financeelcom_recount_fprov(bigint)
  OWNER TO magicbox;
