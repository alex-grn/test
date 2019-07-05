create or replace view PG_CONTRACTS as
select
  M.RN as RN,-- ������� ����
  C.NAME as COMPANY,                                -- �����������
  (select JP.CODE from JURPERSONS JP where JP.RN = M.JUR_PERS) as OWNER, -- ��������������
  DT.DOCCODE as DOCTYPE,                            -- ��������
  trim(M.DOC_NUMB) as DOCNUMB,                      -- �����
  M.DOC_DATE as DOCDATE,                            -- ����
  (select AG.AGNABBR from AGNLIST AG where AG.RN = M.AGENT_CUST) as CLIENT,     -- ��������
  (select AG.AGNABBR from AGNLIST AG where AG.RN = M.AGENT_SUPP) as CONTRACTOR, -- ���������
  N.NOMEN_NAME as NAME,                             -- ������� ��������
  M.SUMM as SUMM,                                   -- ����� ��������
  M.DATE_FROM as DATESTART,                         -- ���� ������ ��������
  M.DATE_TO as DATEFINISH                           -- ���� ��������� ��������
from  GOVCNTR M,
      COMPANIES C,
      EXPSTRUCT EC,
      EXPTYPE ET,
      DOCTYPES DT,
      DICNOMNS N
where M.COMPANY = C.RN
  and M.DOC_TYPES = DT.RN(+)
  and M.NOMEN = N.RN(+)
  and M.EXPSTRUCT = EC.RN
  and EC.EXPSTYPE = ET.RN
  and ET.CODE_EX = '242'
  and C.NAME in ('�������');

