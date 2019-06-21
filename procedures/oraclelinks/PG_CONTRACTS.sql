create or replace view PG_CONTRACTS as
select
  M.RN as RN,-- Внешний ключ
  C.NAME as COMPANY,                                -- Организация
  (select JP.CODE from JURPERSONS JP where JP.RN = M.JUR_PERS) as OWNER, -- Принадлежность
  DT.DOCCODE as DOCTYPE,                            -- Документ
  trim(M.DOC_NUMB) as DOCNUMB,                      -- Номер
  M.DOC_DATE as DOCDATE,                            -- Дата
  (select AG.AGNABBR from AGNLIST AG where AG.RN = M.AGENT_CUST) as CLIENT,     -- Заказчик
  (select AG.AGNABBR from AGNLIST AG where AG.RN = M.AGENT_SUPP) as CONTRACTOR, -- Поставщик
  N.NOMEN_NAME as NAME,                             -- Предмет договора
  M.SUMM as SUMM,                                   -- Сумма договора
  M.DATE_FROM as DATESTART,                         -- Дата начала действия
  M.DATE_TO as DATEFINISH                           -- Дата окончания действия
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
  and C.NAME in ('Роструд');

