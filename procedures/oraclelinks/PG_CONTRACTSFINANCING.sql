create or replace view PG_CONTRACTSFINANCING as
select
  F.RN as RN,-- ������� ����
  F.PRN as PRN, -- ������� ���� ��������
  E.CODE_EX as KBK,                     -- ���
  F.SUMM as SUMM,                       -- ����� �������� �� ���
  F.EXEC_SUMM as SUMMPAID,              -- �������� �� ��������
  F.SUMM - F.EXEC_SUMM as SUMMBALANCE   -- ������� ������
from  GOVCNTRFIN F,
      EXPSTRUCT E
where F.EXPSTRUCT = E.RN(+);
