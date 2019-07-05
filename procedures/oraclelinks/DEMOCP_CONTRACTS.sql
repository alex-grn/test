CREATE FOREIGN TABLE DEMOCP_CONTRACTS (
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
) SERVER democp
OPTIONS (table 'PG_CONTRACTS');

grant select on DEMOCP_CONTRACTS to public;

