-- Function: public.p_action_financeelcom_recount_updigit(bigint)

-- DROP FUNCTION public.p_action_financeelcom_recount_updigit(bigint);

CREATE OR REPLACE FUNCTION public.p_action_financeelcom_recount_updigit(id bigint)
  RETURNS void AS
$BODY$
declare
  rec record;
  nELECTCOMMINCAMPID bigint:=(select f.ELECTCOMMINCAMPID from FINANCEELCOM f where f.ID = P_ACTION_FINANCEELCOM_RECOUNT_UPDIGIT.ID);
begin

 for rec in (
     select f.ID,
            sum(COALESCE(f1.SUMFINTIK,0)) as sumfintik, 
            sum(COALESCE(f1.SUMFINTIKCEN,0)) as sumfintikcen,
            sum(COALESCE(f1.SUMFINUIK,0)) as sumfinuik,
            f1.docdate
       from FINANCEELCOM f,
            TYPEEXP t,
            TYPEEXPCMP sp,
            FINANCEELCOM f1
      where f.ELECTCOMMINCAMPID = nELECTCOMMINCAMPID
        and t.ID = f.TYPEEXPID
        and sp.TYPEEXPID = t.ID
        and f1.TYPEEXPID = sp.TYPEEXPCMPID
        and f.docdate = f1.docdate
        and f1.ELECTCOMMINCAMPID = f.ELECTCOMMINCAMPID
   group by f.ID, f1.docdate
 )
 loop
     update FINANCEELCOM f set SUMFINTIK = rec.SUMFINTIK, SUMFINTIKCEN = rec.SUMFINTIKCEN, SUMFINUIK = rec.SUMFINUIK where f.ID = rec.ID and f.docdate = rec.docdate;
 end loop; 
  
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_financeelcom_recount_updigit(bigint)
  OWNER TO magicbox;
