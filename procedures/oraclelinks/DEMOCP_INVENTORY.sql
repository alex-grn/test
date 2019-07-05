CREATE FOREIGN TABLE DEMOCP_INVENTORY (
  rn bigint,
  company character varying,
  objnumber character varying,
  cardnumb character varying,
  owner character varying,
  name character varying,
  objnote character varying,
  objmodel character varying,
  okof character varying,
  worsnumber character varying,
  producer character varying,
  "exec" character varying,
  establishment character varying,
  dateissue date,
  datecommissioning date,
  sumnew numeric(17,2),
  sumamort numeric(17,2),
  sumamortnew numeric(17,2),
  sumpost numeric(17,2)
) SERVER democp
OPTIONS (table 'PG_INVENTORY');

grant select on DEMOCP_INVENTORY to public;
