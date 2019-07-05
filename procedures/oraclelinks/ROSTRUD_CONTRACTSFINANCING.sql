CREATE FOREIGN TABLE ROSTRUD_CONTRACTSFINANCING (
  rn bigint,
  prn bigint,
  kbk character varying,
  summ numeric(17,2),
  summpaid numeric(17,2),
  summbalance numeric(17,2)
) SERVER rostrud
OPTIONS (table 'PG_CONTRACTSFINANCING');

grant select on ROSTRUD_CONTRACTSFINANCING to public;
