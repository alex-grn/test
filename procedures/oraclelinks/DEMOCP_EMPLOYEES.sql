CREATE FOREIGN TABLE DEMOCP_EMPLOYEES (
  rn bigint,
  company character varying,
  owner character varying,
  code character varying,
  surname character varying,
  firstname character varying,
  middlename character varying,
  post character varying,
  establishment character varying,
  datereceipt date,
  datedismissal date,
  condition character varying
) SERVER democp
OPTIONS (table 'PG_EMPLOYEES');

grant select on DEMOCP_EMPLOYEES to public;
