-- Function: public.p_action_financeelcom_block_cells(bigint)

-- DROP FUNCTION public.p_action_financeelcom_block_cells(bigint);

CREATE OR REPLACE FUNCTION public.p_action_financeelcom_block_cells(id bigint)
  RETURNS text AS
$BODY$
declare
  result text;
  nID bigint:=ID;
begin
  select replace(K.LEVELELCOMMITTEE, 'circuit', 'territory') 
       || '/' || 
       case K.LEVELELCOMMITTEE
         when 'district' then
          M.MFIN
         else
          ''
       end 
       || '/' || 
       case K.LEVELELCOMMITTEE
         when 'district' then
          (case V.TYPEEXPENSES
            when 'product' then
             ''
            when 'service' then
             ''
            when 'worksexec' then
             ''
            else
             COALESCE(V.TYPEEXPENSES, '')
          end)
         else
          ''
       end 
       || '/' || 
       case K.LEVELELCOMMITTEE
         when 'district' then
          (case V.NUMBESTIMATE::TEXT ||lower(e.levelelcampaign)
            when '3central' then
             '10'
            when '5central' then
             '10'
            when '10central' then
             '10'
           /* when '9central' then
             '10'*/
            else
             ''
          end)
         else
          ''
       end
  into result
  from FINANCEELCOM    F,
       ELECTCOMMINCAMP T,
       ELECTCAMPAIGN   E,
       ELECTCOMMITTEE  K,
       TYPEEXP         V,
       MFIN            M
 where F.ID = nID
   and T.ID = F.ELECTCOMMINCAMPID
   and E.ID = T.ELECTCAMPAIGNID
   and K.ID = T.ELECTCOMMITTEEID
   and V.ID = F.TYPEEXPID
   and M.ELECTCOMMITTEEID = K.ID
   and F.DOCDATE >= M.BEGINDATE
   and (M.ENDDATE >= F.DOCDATE or M.ENDDATE is null);
  return result;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_financeelcom_block_cells(bigint)
  OWNER TO magicbox;
