CREATE TABLE public.report_orgvac (
  ident         	BIGINT,
  id_row			BIGINT,
  sort_row	    	BIGINT,
  levelsignificance VARCHAR,
  org_name 	   		VARCHAR,
  reg_name			VARCHAR,
  org_addr			VARCHAR,
  org_vac_name		VARCHAR,
  org_vac_gen_count	NUMERIC,
  num_pp			NUMERIC
);
COMMENT ON TABLE public.report_orgvac                	 IS 'Отчет "Организации и Вакансии"';
COMMENT ON COLUMN public.report_orgvac.ident    	 	 IS 'Идентификатор формирования';
COMMENT ON COLUMN public.report_orgvac.id_row   	 	 IS 'Идентификатор записи';
COMMENT ON COLUMN public.report_orgvac.sort_row 	 	 IS 'Сортировка';
COMMENT ON COLUMN public.report_orgvac.levelsignificance IS 'Исполнительный орган';
COMMENT ON COLUMN public.report_orgvac.org_name 		 IS 'Наименование организации';
COMMENT ON COLUMN public.report_orgvac.reg_name 		 IS 'Наименование региона';
COMMENT ON COLUMN public.report_orgvac.org_addr	 		 IS 'Адрес организации';
COMMENT ON COLUMN public.report_orgvac.org_vac_name		 IS 'Наименование вакантной должности';
COMMENT ON COLUMN public.report_orgvac.org_vac_gen_count IS 'Общее кол-во по должности';

ALTER TABLE public.report_orgvac OWNER TO magicbox;