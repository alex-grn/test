CREATE OR REPLACE FUNCTION public.p_statusepf_set_0(idlist text, tablename text) RETURNS bigint AS
$body$
declare
  /* ��������� ������ �������� ������� � �������
  */
begin
  execute 'update '|| quote_ident(TABLENAME)||' set STATUSEPF = $1 where ID = ANY(P_SYSTEM_GET_SELECTLIST($2))'
    using '0', idlist;
  return null;
end;
$body$
language plpgsql volatile;
