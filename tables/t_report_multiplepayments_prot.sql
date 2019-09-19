CREATE TABLE public.t_report_multiplepayments_prot (
  uid BIGINT,
  pp TEXT,
  pfio TEXT,
  pdoc_type TEXT,
  pdoc_ser TEXT,
  pdoc_num TEXT,
  pdoc_date TEXT,
  cfio TEXT,
  cburn TEXT,
  cdoc_type TEXT,
  cdoc_ser TEXT,
  cdoc_num TEXT,
  cdoc_date TEXT,
  per TEXT,
  summ NUMERIC,
  vid TEXT,
  reg TEXT
) 
WITH (oids = false);

ALTER TABLE public.t_report_multiplepayments_prot
  OWNER TO magicbox;