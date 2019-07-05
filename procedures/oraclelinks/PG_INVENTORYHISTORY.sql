create or replace view PG_INVENTORYHISTORY as
select
  H.RN as RN,   -- Внешний ключ
  H.PRN as PRN, -- Внешний ключ родителя
  to_char(H.ACTION_TYPE) as TYPEOPERATION, -- Тип операции
	H.NUMB as NUMBOPERATION,                 -- Номер операции
  H.ACTION_DATE as DATEOPERATION,          -- Дата операции
  DT.DOCCODE as DOCTYPE,                   -- Документ
  H.VDOC_NUMB as DOCNUMB,                  -- Номер
  H.VDOC_DATE as DOCDATE,                  -- Дата
  H.NEW_AB_COST_BEGIN as SUMNEW,           -- Новая начальная стоимость
  H.NEW_AB_AMORT_BEGIN as SUMAMORT,        -- Новый начальный износ
  H.NEW_AB_AMORT_DURING as SUMAMORTNEW,    -- Новая начисленная амортизация
  H.NEW_AB_COST_END as SUMPOST,            -- Новая остаточная стоимость
  (select AG.AGNABBR from AGNLIST AG where AG.RN = H.AGENT_FROM) as EXECOLD, -- Материально-ответственное лицо до операции
  (select AG.AGNABBR from AGNLIST AG where AG.RN = H.AGENT_TO) as EXECNEW,   -- Материально-ответственное лицо после операции
  (select DEP.CODE from INS_DEPARTMENT DEP where DEP.RN = H.SUBDIV_OLD) as ESTABLISHMENTOLD, -- Подразделение до операции
  (select DEP.CODE from INS_DEPARTMENT DEP where DEP.RN = H.SUBDIV_NEW) as ESTABLISHMENTNEW  -- Подразделение после операции
from  PG_INVENTORY M,
      INVHIST H,
      DOCTYPES DT
where H.PRN = M.RN
  and H.VDOC_TYPE = DT.RN(+)
