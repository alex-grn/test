CREATE FOREIGN TABLE DEMOCP_CONTRACTSSTAGES (
  rn bigint,
  prn bigint,
  name character varying,
  datestart date,
  datefinish date
) SERVER democp
OPTIONS (table 'PG_CONTRACTSSTAGES');

grant select on DEMOCP_CONTRACTSSTAGES to public;
