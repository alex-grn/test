CREATE OR REPLACE FUNCTION f_inventory_get_link(id bigint) RETURNS boolean AS
$body$
declare
  /* Фунция проверяет существование ссылок на инвентарную карточку
  */
  nID  bigint = id;
begin

  return coalesce((select true
		    where exists(select 1 from EQUIPMENT where INVENTORYID = nID limit 1)
		       or exists(select 1 from SOFTWARE where INVENTORYID = nID limit 1)
		       or exists(select 1 from OFFICEEQUIPMENT where INVENTORYID = nID limit 1)
		       or exists(select 1 from NETWORKSEQUIPMENT where INVENTORYID = nID limit 1)
		       or exists(select 1 from COMMUNICATIONS where INVENTORYID = nID limit 1)), false);

end;
$body$
language plpgsql volatile;
