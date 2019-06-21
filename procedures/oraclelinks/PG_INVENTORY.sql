create or replace view PG_INVENTORY as
select
  M.RN as RN,-- Внешний ключ
  C.NAME as COMPANY, -- Организация
  trim(M.OBJECT_NUMBER) as OBJNUMBER, -- Инвентарный номер
  trim(M.CARD_PREF)||'-'||trim(M.CARD_NUMB) as CARDNUMB, -- Номер инвентарной карты
  (select JP.CODE from JURPERSONS JP where JP.RN = M.JUR_PERS) as OWNER, -- Принадлежность
  (select N.NOMEN_NAME from DICNOMNS N where N.RN = M.NOMENCLATURE) as NAME, -- Наименование номенклатуры
  M.OBJECT_NOTE as OBJNOTE, -- Характеристика инвентарного объекта
  M.OBJECT_MODEL as OBJMODEL, -- Модель, марка
  K.CODE as OKOF, -- Код ОКОФ
  M.WORS_NUMBER as WORSNUMBER, -- Заводской номер
  (select PR.AGNABBR from AGNLIST PR where PR.RN = M.PRODUCER) as PRODUCER, -- Изготовитель
  (select AG.AGNABBR from AGNLIST AG where AG.RN = M.EXECUTIVE) as EXEC, -- Материально-ответственное лицо (МОЛ)
  (select DEP.CODE from INS_DEPARTMENT DEP where DEP.RN = M.SUBDIV) as ESTABLISHMENT, -- Подразделение
  M.RELEASE_DATE as DATEISSUE, -- Дата выпуска
  nvl((select H.ACTION_DATE from INVHIST H where H.PRN = M.RN and H.ACTION_TYPE = 0), M.INCOME_DATE) as DATECOMMISSIONING, -- Дата ввода в эксплуатацию
  M.AB_COST_BEGIN as SUMNEW, -- Начальная стоимость
  M.AB_AMORT_BEGIN as SUMAMORT, -- Начальный износ
  M.AB_AMORT_DURING as SUMAMORTNEW, -- Начисленная амортизация
  M.AB_COST_END as SUMPOST -- Остаточная стоимость
from  INVENTORY M,
      (select RN, CODE from OKOF where pr_strinlike(CODE, f_options_string_value(1,1, 'Inventory', 1, 'InventoryExportOKOF', null),';') = 1) K,
      COMPANIES C
where K.RN = M.OKOF
  and M.COMPANY = C.RN
  and C.NAME in ('Роструд');
  

