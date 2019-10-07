CREATE TABLE public.passageofags_rep (
  ident                 BIGINT,
  id_row				BIGINT,
  sort_row				BIGINT,
  fio 			    	VARCHAR,
  pers_document			VARCHAR,
  vac_period			VARCHAR,
  vac_type				VARCHAR,
  vac_valid				VARCHAR,
  unpaid_period			VARCHAR,
  unpaid_valid			VARCHAR
);
COMMENT ON TABLE public.passageofags_rep                IS 'Отчет по пособиям на ребенка военнослужащего';
COMMENT ON COLUMN public.passageofags_rep.ident    		IS 'Идентификатор формирования';
COMMENT ON COLUMN public.passageofags_rep.id_row   		IS 'Идентификатор записи';
COMMENT ON COLUMN public.passageofags_rep.sort_row 		IS 'Сортировка';
COMMENT ON COLUMN public.passageofags_rep.fio 			IS 'Фио';
COMMENT ON COLUMN public.passageofags_rep.pers_document	IS 'Паспортные данные';
COMMENT ON COLUMN public.passageofags_rep.vac_period	IS 'Период отпуска';
COMMENT ON COLUMN public.passageofags_rep.vac_type		IS 'Вид отпуска';
COMMENT ON COLUMN public.passageofags_rep.vac_valid	    IS 'Основание отпуска';
COMMENT ON COLUMN public.passageofags_rep.unpaid_period IS 'Не засчитываемые периоды';
COMMENT ON COLUMN public.passageofags_rep.unpaid_valid  IS 'Основание не засчитываемых периодов';

ALTER TABLE public.passageofags_rep OWNER TO magicbox;