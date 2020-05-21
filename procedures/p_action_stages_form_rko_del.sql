CREATE OR REPLACE FUNCTION public.p_action_stages_form_rko_del
(
  idlist text,
  uid bigint
)
RETURNS void AS
$body$
declare
  NUID                BIGINT := UID;
  REC                 record;
  D              	  BIGINT;
  MCASHDOCS           BIGINT[];
  MCASHPAYMENT_HEADER BIGINT[];
begin
  for REC in (select S.ID from PERSONS_STAGES S where S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST)))
  loop
    -- получение ID
    MCASHDOCS           := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('PERSONS_STAGES', REC.ID, 'CASHDOCS');
    MCASHPAYMENT_HEADER := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('PERSONS_STAGES', REC.ID, 'CASHPAYMENT_HEADER');

    if COALESCE(cardinality(P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('PERSONS_STAGES', REC.ID, 'CASHPAYMENT')), 0) <> 0
    then
      -- проверяем на наличие исходяжих документов
      foreach D in array MCASHPAYMENT_HEADER
      loop
        perform p_system_doclinks_out_check('CASHPAYMENT_HEADER', D);
      end loop;

      -- удаляем линк
      foreach D in array P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('PERSONS_STAGES', REC.ID, 'CASHPAYMENT')
      loop
        PERFORM P_SYSTEM_DOCLINKS_DEL('PERSONS_STAGES', REC.ID, 'CASHPAYMENT', D);
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
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_stages_form_rko_del (idlist text, uid bigint)
  OWNER TO magicbox;