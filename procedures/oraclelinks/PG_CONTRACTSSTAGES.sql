create or replace view PG_CONTRACTSSTAGES as
select
  S.RN as RN,-- Внешний ключ
  S.PRN as PRN, -- Внешний ключ родителя
  S.NAME as NAME,                   -- Наименование этапа
  S.FIN_DATE as DATESTART,          -- Дата начала действия
  S.END_DATE as DATEFINISH          -- Дата окончания действия
from  GOVCNTRSTG S;
