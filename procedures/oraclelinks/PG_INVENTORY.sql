create or replace view PG_INVENTORY as
select
  M.RN as RN,-- ������� ����
  C.NAME as COMPANY, -- �����������
  trim(M.OBJECT_NUMBER) as OBJNUMBER, -- ����������� �����
  trim(M.CARD_PREF)||'-'||trim(M.CARD_NUMB) as CARDNUMB, -- ����� ����������� �����
  (select JP.CODE from JURPERSONS JP where JP.RN = M.JUR_PERS) as OWNER, -- ��������������
  (select N.NOMEN_NAME from DICNOMNS N where N.RN = M.NOMENCLATURE) as NAME, -- ������������ ������������
  M.OBJECT_NOTE as OBJNOTE, -- �������������� ������������ �������
  M.OBJECT_MODEL as OBJMODEL, -- ������, �����
  K.CODE as OKOF, -- ��� ����
  M.WORS_NUMBER as WORSNUMBER, -- ��������� �����
  (select PR.AGNABBR from AGNLIST PR where PR.RN = M.PRODUCER) as PRODUCER, -- ������������
  (select AG.AGNABBR from AGNLIST AG where AG.RN = M.EXECUTIVE) as EXEC, -- �����������-������������� ���� (���)
  (select DEP.CODE from INS_DEPARTMENT DEP where DEP.RN = M.SUBDIV) as ESTABLISHMENT, -- �������������
  M.RELEASE_DATE as DATEISSUE, -- ���� �������
  nvl((select H.ACTION_DATE from INVHIST H where H.PRN = M.RN and H.ACTION_TYPE = 0), M.INCOME_DATE) as DATECOMMISSIONING, -- ���� ����� � ������������
  M.AB_COST_BEGIN as SUMNEW, -- ��������� ���������
  M.AB_AMORT_BEGIN as SUMAMORT, -- ��������� �����
  M.AB_AMORT_DURING as SUMAMORTNEW, -- ����������� �����������
  M.AB_COST_END as SUMPOST -- ���������� ���������
from  INVENTORY M,
      (select RN, CODE from OKOF where pr_strinlike(CODE, f_options_string_value(1,1, 'Inventory', 1, 'InventoryExportOKOF', null),';') = 1) K,
      COMPANIES C
where K.RN = M.OKOF
  and M.COMPANY = C.RN
  and C.NAME in ('�������');
  

