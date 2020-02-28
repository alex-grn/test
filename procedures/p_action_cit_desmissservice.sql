CREATE OR REPLACE FUNCTION public.p_action_cit_desmissservice (
  id bigint,
  dateofdismissla date,
  basis4 TEXT,
  UNIT bigint default null,
  UID bigint default null
)
RETURNS void AS
$body$
 declare
 sID text;
 nID bigint := id;
 sql text;
 begin
   -- добавление сведений об увольнении "Прохождение АГС"
   sID = P_SYSTEM_ACTION_DO('insert', 'passageagscit', '{"citizenryid":"'||nID||'","dateofdismissla":"'||dateofdismissla||'","basis4":"'||basis4||'"}', UNIT, UID);
   -- смена статуса
   update Citizenry s set statuscitizen = 4 where s.id = nID;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_cit_desmissservice (id bigint, dateofdismissla date, basis4 TEXT, UNIT bigint, UID bigint)
  OWNER TO magicbox;