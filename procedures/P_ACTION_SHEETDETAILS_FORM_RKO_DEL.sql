create or replace function PUBLIC.P_ACTION_SHEETDETAILS_FORM_RKO_DEL
(
  IDLIST  TEXT,
  UID    BIGINT
) RETURNS VOID as
  $BODY$
  declare
  NUID                BIGINT := UID;
  REC            	  record;
  D              	  BIGINT;
  MCASHDOCS           BIGINT[];
  MCASHPAYMENT_HEADER BIGINT[];
begin
  for REC in (select S.ID from SHEETDETAILS S where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST)))
  loop
    -- получение ID
    MCASHDOCS           := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('SHEETDETAILS', REC.ID, 'CASHDOCS');
    MCASHPAYMENT_HEADER := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('SHEETDETAILS', REC.ID, 'CASHPAYMENT_HEADER');

    if COALESCE(cardinality(P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('SHEETDETAILS', REC.ID, 'CASHPAYMENT')),0) <> 0
    then
      -- чистим ссылку
      update SHEETDETAILS set cashpaymentheaderid = null where id = REC.ID;

      -- удаляем линк
      foreach D in array P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('SHEETDETAILS', REC.ID, 'CASHPAYMENT')
      loop
        PERFORM P_SYSTEM_DOCLINKS_DEL('SHEETDETAILS', REC.ID, 'CASHPAYMENT', D);
      end loop;

      -- удаляем РКО
      delete from CASHPAYMENT_HEADER CH where CH.ID = ANY(MCASHPAYMENT_HEADER);

      -- проверка и удаление Расчетные (лицевые) счета в банке
      delete from CASHDOCS
       where CASHDOCS.id = ANY(MCASHDOCS)
         and not exists (select 1 from CASHPAYMENT_HEADER where cashdocsid = CASHDOCS.ID)
         and not exists (select 1 from CASHRECEIPT_HEADER where cashdocsid = CASHDOCS.ID)
         and not exists (select 1 from STATEMENT_HEADER where cashdocsid = CASHDOCS.ID)
         and not exists (select 1 from CASHCONTRIBUTION_HEADER where cashdocsid = CASHDOCS.ID)
         and not exists (select 1 from REPORTCASHBOOKS where cashdocsid = CASHDOCS.ID);
    end if;
  end loop;
end;
$BODY$
language 'plpgsql' VOLATILE CALLED on null INPUT SECURITY INVOKER COST 100;

ALTER FUNCTION public.P_ACTION_SHEETDETAILS_FORM_RKO_DEL(idlist text, uid bigint)
  OWNER TO magicbox;