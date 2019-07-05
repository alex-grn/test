CREATE OR REPLACE FUNCTION p_statusepf_set_1(idlist text, tablename text) RETURNS bigint AS
$body$
declare
  /* Процедура меняет значение статуса в таблице
  */
begin
  execute 'update '|| quote_ident(TABLENAME)||' set STATUSEPF = $1 where ID = ANY(P_SYSTEM_GET_SELECTLIST($2)) and STATUSEPF = $3'
     using '1', idlist, '0';
  return null;
end;
$body$
language plpgsql volatile;
