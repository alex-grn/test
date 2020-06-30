CREATE OR REPLACE FUNCTION public.p_action_cancel_lastoperation (
  id bigint
)
RETURNS void AS
$body$
DECLARE 
    nid bigint = id;
    last_id bigint;
    last_status text;
    nINSPERSONID bigint;
BEGIN

  --возьмем ID 
  select F.ID, F.STATUSEAF
    into LAST_ID, LAST_STATUS
    from FINEHISTORY F
   where F.FINEID = NID
   order by F.ID desc limit 1;
  --Удаляем последнее изменение
  delete from FINEHISTORY F where F.ID = LAST_ID;
  --статус из последнего изменения
  select F.STATUSEAF, F.INSPERSONID
    into LAST_STATUS, nINSPERSONID
    from FINEHISTORY F
   where F.FINEID = NID
   order by F.ID desc limit 1; 
  if not exists(select 1 from FINEHISTORY F where F.FINEID = NID) then
      LAST_STATUS:='0';
  end if; 
  --Отменяем последнее изменение
  update FINE F set STATUSEAF = LAST_STATUS, INSPERSONID = COALESCE(nINSPERSONID,f.INSPERSONID) where F.ID = NID;
  
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


ALTER FUNCTION public.p_action_cancel_lastoperation (id bigint)
  OWNER TO magicbox;
