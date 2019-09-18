CREATE OR REPLACE FUNCTION public.p_action_jobplan_select_clear (
  citizenryid bigint
)
RETURNS void AS
$body$
 declare

 begin
   delete from DIRECTION s where s.status = '5' and s.citizenryid = p_action_jobplan_select_clear.citizenryid;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_jobplan_select_clear (citizenryid bigint)
  OWNER TO magicbox;