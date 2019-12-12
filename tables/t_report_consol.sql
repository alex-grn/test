CREATE TABLE public.t_report_consol (
  id BIGSERIAL,
  uid BIGINT,
  list TEXT,
  line TEXT,
  month INTEGER,
  tcol TEXT,
  tcol2 TEXT,
  col1 NUMERIC(9,2),
  col2 NUMERIC(9,2),
  col3 NUMERIC(9,2),
  col4 NUMERIC(9,2),
  col5 NUMERIC(9,2),
  col6 NUMERIC(9,2)
) 
WITH (oids = false);

CREATE INDEX line_idx ON public.t_report_consol
  USING btree (line COLLATE pg_catalog."default");

CREATE INDEX list_idx ON public.t_report_consol
  USING btree (list COLLATE pg_catalog."default");

CREATE INDEX month_idx ON public.t_report_consol
  USING btree (month);

CREATE INDEX uid_idx ON public.t_report_consol
  USING btree (uid);

ALTER TABLE public.t_report_consol
  OWNER TO magicbox;