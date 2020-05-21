CREATE OR REPLACE FUNCTION public.p_action_stages_acts_work_serv_del (
  idlist text,
  tablename text,
  uid bigint
)
RETURNS void AS
$body$
declare
    rec record;
    d bigint;
    nUID bigint:=UID;
    MACTSDOCS BIGINT[];
begin
  if tablename ilike 'STAGES' then
    for rec in
        select s.id from STAGES s where s.ID = ANY(p_system_get_selectlist(idlist)) and not s.ACTSEXP
    LOOP
    raise using message ='1';
      -- получение ID
      MACTSDOCS     := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STAGES', REC.ID, 'ACTSDOCS');

	  if COALESCE(cardinality(P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STAGES', REC.ID, 'ACTSGOODS')),0) <> 0
      then
        -- проверяем на наличие исходяжих документов
        foreach D in array MACTSDOCS
        loop
          perform p_system_doclinks_out_check('ACTSDOCS', D);
        end loop;

        -- удаляем линк
        foreach D in array P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STAGES', REC.ID, 'ACTSGOODS')
        loop
          PERFORM P_SYSTEM_DOCLINKS_DEL('STAGES', REC.ID, 'ACTSGOODS', D);
        end loop;

        -- удаляем АКТА
        delete from ACTSDOCS where ACTSDOCS.id = ANY(MACTSDOCS);

        --Поставим в поле "учтено в акте" - "Нет"
        update STAGES s set ACTSEXP = false where s.ID = rec.STAGESID;
      end if;
    END LOOP;
  elsif tablename ilike 'PERSONS_STAGES' then
    for rec in (select s.id from PERSONS_STAGES s where s.ID = ANY(p_system_get_selectlist(idlist)) and not s.ACTSEXP)
    LOOP
      -- получение ID
      MACTSDOCS     := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('PERSONS_STAGES', REC.ID, 'PERS_ACTSDOCS');

	  if COALESCE(cardinality(P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('PERSONS_STAGES', REC.ID, 'PERS_ACTSGOODS')),0) <> 0
      then
        -- проверяем на наличие исходяжих документов
        foreach D in array MACTSDOCS
        loop
          perform p_system_doclinks_out_check('PERS_ACTSDOCS', D);
        end loop;

        -- удаляем линк
        foreach D in array P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('PERSONS_STAGES', REC.ID, 'PERS_ACTSGOODS')
        loop
          PERFORM P_SYSTEM_DOCLINKS_DEL('PERSONS_STAGES', REC.ID, 'PERS_ACTSGOODS', D);
        end loop;

        -- удаляем АКТА
        delete from PERS_ACTSDOCS where PERS_ACTSDOCS.id = ANY(MACTSDOCS);

        --Поставим в поле "учтено в акте" - "Нет"
        update PERSONS_STAGES s set ACTSEXP = false where s.ID = rec.STAGESID;
      end if;
     end loop;
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_stages_acts_work_serv_del (idlist text, tablename text, uid bigint)
  OWNER TO magicbox;