CREATE OR REPLACE FUNCTION public.p_action_registerstransfers_roll_back (
  idlist text
)
RETURNS void AS
$body$
declare
  --Действие "Расформировать ведомость" в разделе "Реестры перечислений" REGISTERSTRANSFERS
  REC record;
  NID BIGINT; --id таблицы заполения;
  D bigint;
begin
  update SHEETDETAILS S
     set SUMTRN               = null,
         REGISTERSTRANSFERSID = null
   where S.REGISTERSTRANSFERSID = any(P_SYSTEM_GET_SELECTLIST(IDLIST));
  delete from REGISTERSTRANSFERS S where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST));
  FOREACH D in array P_SYSTEM_GET_SELECTLIST(IDLIST)
  loop
    perform p_system_doclinks_del('SHEETS',null,'REGISTERSTRANSFERS',D);
  end loop;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_registerstransfers_roll_back (idlist text)
  OWNER TO magicbox;