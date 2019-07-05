CREATE OR REPLACE FUNCTION p_schedule_oracle_import(uid bigint DEFAULT 1) RETURNS text AS
$body$
begin
  -- загрузка сотрудников
  return 'Импорт договоров. '||p_schedule_contracts_import(uid)||chr(10)
           ||'Импорт инвентарных карточек. '||p_schedule_inventory_import(uid)||chr(10)
           ||'Импорт сотрудников. '||p_schedule_employees_import(uid);
end;
$body$
language plpgsql volatile;
