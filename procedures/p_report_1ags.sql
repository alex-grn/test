CREATE OR REPLACE FUNCTION public.p_report_1ags (
  percalc text,
  clear boolean,
  yearcalc integer,
  ident bigint,
  recreate boolean,
  uid bigint = NULL::bigint
)
RETURNS void AS
$body$
begin
  if not clear
  then
    perform p_action_calctabags_calc(YEARCALC, PERCALC, RECREATE, UID);
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_report_1ags (percalc text, clear boolean, yearcalc integer, ident bigint, recreate boolean, uid bigint)
  OWNER TO magicbox;