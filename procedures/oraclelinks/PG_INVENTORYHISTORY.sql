create or replace view PG_INVENTORYHISTORY as
select
  H.RN as RN,   -- ������� ����
  H.PRN as PRN, -- ������� ���� ��������
  to_char(H.ACTION_TYPE) as TYPEOPERATION, -- ��� ��������
	H.NUMB as NUMBOPERATION,                 -- ����� ��������
  H.ACTION_DATE as DATEOPERATION,          -- ���� ��������
  DT.DOCCODE as DOCTYPE,                   -- ��������
  H.VDOC_NUMB as DOCNUMB,                  -- �����
  H.VDOC_DATE as DOCDATE,                  -- ����
  H.NEW_AB_COST_BEGIN as SUMNEW,           -- ����� ��������� ���������
  H.NEW_AB_AMORT_BEGIN as SUMAMORT,        -- ����� ��������� �����
  H.NEW_AB_AMORT_DURING as SUMAMORTNEW,    -- ����� ����������� �����������
  H.NEW_AB_COST_END as SUMPOST,            -- ����� ���������� ���������
  (select AG.AGNABBR from AGNLIST AG where AG.RN = H.AGENT_FROM) as EXECOLD, -- �����������-������������� ���� �� ��������
  (select AG.AGNABBR from AGNLIST AG where AG.RN = H.AGENT_TO) as EXECNEW,   -- �����������-������������� ���� ����� ��������
  (select DEP.CODE from INS_DEPARTMENT DEP where DEP.RN = H.SUBDIV_OLD) as ESTABLISHMENTOLD, -- ������������� �� ��������
  (select DEP.CODE from INS_DEPARTMENT DEP where DEP.RN = H.SUBDIV_NEW) as ESTABLISHMENTNEW  -- ������������� ����� ��������
from  PG_INVENTORY M,
      INVHIST H,
      DOCTYPES DT
where H.PRN = M.RN
  and H.VDOC_TYPE = DT.RN(+)
