CREATE OR REPLACE FUNCTION p_schedule_oracle_import(uid bigint DEFAULT 1) RETURNS text AS
$body$
begin
  -- �������� �����������
  return '������ ���������. '||p_schedule_contracts_import(uid)||chr(10)
           ||'������ ����������� ��������. '||p_schedule_inventory_import(uid)||chr(10)
           ||'������ �����������. '||p_schedule_employees_import(uid);
end;
$body$
language plpgsql volatile;
