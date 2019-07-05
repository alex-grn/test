CREATE FOREIGN TABLE ROSTRUD_CONTRACTS (
  rn bigint,
  company character varying,
  owner character varying,
  doctype character varying,
  docnumb character varying,
  docdate date,
  client character varying,
  contractor character varying,
  name character varying,
  summ numeric(17,2),
  datestart date,
  datefinish date
) SERVER rostrud
OPTIONS (table 'PG_CONTRACTS');

grant select on ROSTRUD_CONTRACTS to public;

