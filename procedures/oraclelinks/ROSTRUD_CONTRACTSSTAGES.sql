CREATE FOREIGN TABLE ROSTRUD_CONTRACTSSTAGES (
  rn bigint,
  prn bigint,
  name character varying,
  datestart date,
  datefinish date
) SERVER rostrud
OPTIONS (table 'PG_CONTRACTSSTAGES');

grant select on ROSTRUD_CONTRACTSSTAGES to public;
