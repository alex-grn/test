CREATE FOREIGN TABLE DEMOCP_CONTRACTSFINANCING (
  rn bigint,
  prn bigint,
  kbk character varying,
  summ numeric(17,2),
  summpaid numeric(17,2),
  summbalance numeric(17,2)
) SERVER democp
OPTIONS (table 'PG_CONTRACTSFINANCING');

grant select on DEMOCP_CONTRACTSFINANCING to public;

