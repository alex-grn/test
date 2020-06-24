CREATE OR REPLACE FUNCTION public.p_get_acc_by_parts_code (
  sfinsecurity text,
  sbudgclass text,
  sdicaccs text,
  stypeexp text = NULL::text,
  seconclass text = NULL::text
)
RETURNS text AS
$body$
DECLARE
BEGIN
     /*Процедура формирования счета по его текстовым составляющим:
       sfinsecurity - КФО
       sbudgclass   - КПС
       sdicaccs     - Счет
       stypeexp     - Направление расходов
       seconclass   - КОСГУ
     */
     return (coalesce(sbudgclass,'')||
             coalesce('.'||sfinsecurity,'')||
             coalesce('.'||sdicaccs,'')||
             coalesce('.'||stypeexp,'')||
             coalesce('.'||seconclass,'')
            );
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_get_acc_by_parts_code (sfinsecurity text, sbudgclass text, sdicaccs text, stypeexp text, seconclass text)
  OWNER TO postgres;