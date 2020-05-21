CREATE OR REPLACE FUNCTION public.p_action_stages_inv_del (
  idlist text,
  uid bigint
)
RETURNS void AS
$body$
declare
  NUID            BIGINT := UID;
  REC             record;
  D               BIGINT;
  MINVENTORY      BIGINT[];
  MINVENTORY_DOCS BIGINT[];
begin

  for REC in (select S.ID,
                     ss.contrtype
                from STAGES S,
                     CONTRACTSDOCS SS
               where 1=1
                 and S.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
                 and SS.ID = S.CONTRACTSDOCSID
                 and s.actsexp)
  loop
    -- только на поставку товаров
    if rec.contrtype <> 'product'
    then
      raise using message = 'Расформирование Товарной накладной возможно только для договаров с типом "Поставка товара"!'||rec.contrtype;
    end if;

    -- получение ID
    MINVENTORY      := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STAGES', REC.ID, 'INVENTORY');
    MINVENTORY_DOCS := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STAGES', REC.ID, 'INVENTORY_DOCS');

	if COALESCE(cardinality(P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STAGES', REC.ID, 'INVENTORY_GOODS')), 0) <> 0
    then
      -- проверяем на наличие исходяжих документов
      foreach D in array MINVENTORY_DOCS
      loop
        perform p_system_doclinks_out_check('INVENTORY_DOCS', D);
      end loop;

      -- удаляем линк
      foreach D in array P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STAGES', REC.ID, 'INVENTORY_GOODS')
      loop
        PERFORM P_SYSTEM_DOCLINKS_DEL('STAGES', REC.ID, 'INVENTORY_GOODS', D);
      end loop;

      -- удаляем МЗ
      delete from INVENTORY_DOCS CH where CH.ID = ANY(MINVENTORY_DOCS);

      -- проверка и удаление заголовка
      delete from INVENTORY
       where INVENTORY.id = ANY(MINVENTORY)
         and not exists (select 1 from INVENTORY_DOCS where inventoryid = INVENTORY.ID)
         and not exists (select 1 from OTHER_INVENTORY_DOCS where inventoryid = INVENTORY.ID);

      update stages su set ACTSEXP = false where su.id = rec.id;
    end if;
  end loop;

end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_stages_inv_del (idlist text, uid bigint)
  OWNER TO magicbox;