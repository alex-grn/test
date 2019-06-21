CREATE OR REPLACE FUNCTION public.f_purchasefin_get_summ(id bigint, type integer) RETURNS numeric AS
$body$
declare
  /* Расчет суммы заявки
  */
  sTABLES_NEW text = 'pfequipment;pfsoftware;pfofficeequipment;pfnetworksequipment;pfcommunications;pfcomponents';
  sTABLES_OLD text = 'pfequipmentold;pfsoftwareold;pfofficeequipmentold;pfnetworksequipmentold;pfcommunicationsold';
  sTABLES     text;
  tab         record;
  nRESULT     numeric = 0;
  nSUMM       numeric;
begin
  if TYPE = 1 then 
     sTABLES = sTABLES_NEW;
  elseif TYPE = 2 then 
     sTABLES = sTABLES_OLD;
  else
     sTABLES = sTABLES_NEW||';'||sTABLES_OLD;
  end if;

  for tab in select unnest(string_to_array(sTABLES,';')) as name loop
    execute 'select sum(SUMM) from '|| quote_ident(tab.name)||' where PURCHASEFINID = $1 and cid = 0'
       into nSUMM using ID;
    if nSUMM <> 0 then
      nRESULT = nRESULT + nSUMM;
    end if;
  end loop;

  return nRESULT;
end;
$body$
language plpgsql volatile;
