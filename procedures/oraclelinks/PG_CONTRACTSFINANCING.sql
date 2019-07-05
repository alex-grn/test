create or replace view PG_CONTRACTSFINANCING as
select
  F.RN as RN,-- Внешний ключ
  F.PRN as PRN, -- Внешний ключ родителя
  E.CODE_EX as KBK,                     -- КБК
  F.SUMM as SUMM,                       -- Сумма договора по КБК
  F.EXEC_SUMM as SUMMPAID,              -- Оплачено по договору
  F.SUMM - F.EXEC_SUMM as SUMMBALANCE   -- Остаток оплаты
from  GOVCNTRFIN F,
      EXPSTRUCT E
where F.EXPSTRUCT = E.RN(+);
