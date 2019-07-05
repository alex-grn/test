create or replace view PG_EMPLOYEES as
select
  T.RN as RN,                                       -- ������� ����
  C.NAME as COMPANY,                                -- �����������
  (select JP.CODE from JURPERSONS JP where JP.COMPANY = M.COMPANY and JP.MAIN_SIGN=1) as OWNER, -- ��������������
  M.CODE as CODE,                                   -- ������� ������������
  AG.AGNFAMILYNAME as SURNAME,                      -- �������
  AG.AGNFIRSTNAME as FIRSTNAME,                     -- ���
  AG.AGNLASTNAME as MIDDLENAME,                     -- ��������
  PD1.PSDEP_NAME as POST,                           -- ���������
  D.NAME as ESTABLISHMENT,                          -- �������������
  T.BEGENG as DATERECEIPT,                          -- ���� ������
  T.ENDENG as DATEDISMISSAL,                        -- ���� ����������
  (select max(S.NAME)
     from CLNPSPFMST H, 
          PRPERFSTATES S 
    where H.PRN = T.RN 
      and H.PERFSTATE = S.RN 
      and H.BEGIN_DATE = (select max(H2.BEGIN_DATE)
                            from CLNPSPFMST H2
                           where H2.PRN = T.RN
                             and H2.END_DATE is null) 
   ) as CONDITION                                    -- ������ ���������� ���������
from  CLNPSPFM       T,
      COMPANIES      C,
      CLNPERSONS     PR,
      PREMPLFLS      M,
      INS_DEPARTMENT D,
      CLNPSDEP       PD1,
      AGNLIST        AG
where T.PERSRN         = PR.RN
  and PR.PERS_AGENT    = M.AGNLIST
  and M.COMPANY        = C.RN
  and T.COMPANY        = M.COMPANY
  and T.DEPTRN         = D.RN   (+)
  and T.PSDEPRN        = PD1.RN (+)
  and M.AGNLIST        = AG.RN
  and C.NAME       in ('�������');

