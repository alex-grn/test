CREATE FOREIGN TABLE ROSTRUD_INVENTORYHISTORY (
  rn bigint,
  prn bigint,
  typeoperation character varying,
  numboperation character varying,
  dateoperation date,
  doctype character varying,
  docnumb character varying,
  docdate date,
  sumnew numeric(17,2),
  sumamort numeric(17,2),
  sumamortnew numeric(17,2),
  sumpost numeric(17,2),
  execold character varying,
  execnew character varying,
  establishmentold character varying,
  establishmentnew character varying
) SERVER rostrud
OPTIONS (table 'PG_INVENTORYHISTORY');

grant select on ROSTRUD_INVENTORYHISTORY to public;
