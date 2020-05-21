create or replace function PUBLIC.P_ACTION_SHEETDETAILS_FORM_PP_DEL
(
  IDLIST  TEXT,
  UID    BIGINT
) RETURNS VOID as
  $BODY$
  declare
  NUID           BIGINT := UID;
  REC            record;
  D              BIGINT;
  MPAYACCOUNTS   BIGINT[];
  MPAYDOCS		 BIGINT[];
begin
  for REC in (select S.ID from SHEETDETAILS S where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST)))
  loop
    -- получение ID
    MPAYACCOUNTS := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('SHEETDETAILS', REC.ID, 'PAYACCOUNTS');
    MPAYDOCS     := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('SHEETDETAILS', REC.ID, 'PAYDOCS');

    if COALESCE(cardinality(P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('SHEETDETAILS', REC.ID, 'PAYDOCSCONS')),0) <> 0
    then
      -- проверяем на наличие исходяжих документов
      foreach D in array MPAYDOCS
      loop
        perform p_system_doclinks_out_check('PAYDOCS', D);
      end loop;

      -- чистим ссылку
      update SHEETDETAILS set paydocsid = null where id = REC.ID;

      -- удаляем линк
      foreach D in array P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('SHEETDETAILS', REC.ID, 'PAYDOCSCONS')
      loop
        PERFORM P_SYSTEM_DOCLINKS_DEL('SHEETDETAILS', REC.ID, 'PAYDOCSCONS', D);
      end loop;

      -- удаляем ПП
      delete from PAYDOCS where PAYDOCS.id = ANY(MPAYDOCS);

      -- проверка и удаление Расчетные (лицевые) счета в банке
      delete from PAYACCOUNTS
       where PAYACCOUNTS.id = ANY(MPAYACCOUNTS)
         and not exists (select 1 from RECEIPTSDOCS where payaccountsid = PAYACCOUNTS.ID)
         and not exists (select 1 from PAYDOCS where payaccountsid = PAYACCOUNTS.ID);
    end if;
  end loop;
end;
$BODY$
language 'plpgsql' VOLATILE CALLED on null INPUT SECURITY INVOKER COST 100;

ALTER FUNCTION public.p_action_sheetdetails_form_pp_del (idlist text, uid bigint)
  OWNER TO magicbox;