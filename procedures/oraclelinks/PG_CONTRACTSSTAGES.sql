create or replace view PG_CONTRACTSSTAGES as
select
  S.RN as RN,-- ������� ����
  S.PRN as PRN, -- ������� ���� ��������
  S.NAME as NAME,                   -- ������������ �����
  S.FIN_DATE as DATESTART,          -- ���� ������ ��������
  S.END_DATE as DATEFINISH          -- ���� ��������� ��������
from  GOVCNTRSTG S;
