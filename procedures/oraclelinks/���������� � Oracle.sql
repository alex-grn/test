-- Загрузка расширения
CREATE EXTENSION oracle_fdw;

-- Подключение базы DEMOCP
CREATE SERVER democp
FOREIGN DATA WRAPPER oracle_fdw
OPTIONS (dbserver '192.168.1.222:1521/DEMOCP');

GRANT USAGE ON FOREIGN SERVER democp TO postgres;
GRANT USAGE ON FOREIGN SERVER democp TO magicbox;

CREATE USER MAPPING FOR postgres
SERVER democp
OPTIONS (user 'parus', password 'p8applicati0n');

CREATE USER MAPPING FOR magicbox
SERVER democp
OPTIONS (user 'parus', password 'p8applicati0n');

SELECT oracle_diag('democp');

CREATE FOREIGN TABLE DEMOCP_COMPANIES (
  dummy     VARCHAR(160) not null,
  rn       bigint,
  name     VARCHAR(160) not null,
  fullname VARCHAR(160) not null,
  agent    bigint
) SERVER democp
OPTIONS (table 'COMPANIES');

select * from DEMOCP_COMPANIES ;


-- Подключение базы ROSTRUD
CREATE SERVER rostrud
FOREIGN DATA WRAPPER oracle_fdw
OPTIONS (dbserver '192.168.1.222:1521/ROSTRUD');

GRANT USAGE ON FOREIGN SERVER rostrud TO postgres;
GRANT USAGE ON FOREIGN SERVER rostrud TO magicbox;

CREATE USER MAPPING FOR postgres
SERVER rostrud
OPTIONS (user 'parus', password 'p8applicati0n');

CREATE USER MAPPING FOR magicbox
SERVER rostrud
OPTIONS (user 'parus', password 'p8applicati0n');

SELECT oracle_diag('rostrud');

CREATE FOREIGN TABLE ROSTRUD_COMPANIES (
  dummy     VARCHAR(160) not null,
  rn       bigint,
  name     VARCHAR(160) not null,
  fullname VARCHAR(160) not null,
  agent    bigint
) SERVER rostrud
OPTIONS (table 'COMPANIES');

select * from ROSTRUD_COMPANIES ;


-- Подключение базы PFIN02

CREATE SERVER pfin02
FOREIGN DATA WRAPPER oracle_fdw
OPTIONS (dbserver '192.168.22.143:1521/PFIN02');

GRANT USAGE ON FOREIGN SERVER pfin02 TO postgres;
GRANT USAGE ON FOREIGN SERVER pfin02 TO magicbox;

CREATE USER MAPPING FOR postgres
SERVER pfin02
OPTIONS (user 'parus', password '7328063');

CREATE USER MAPPING FOR magicbox
SERVER pfin02
OPTIONS (user 'parus', password '7328063');

SELECT oracle_diag('pfin02');

CREATE FOREIGN TABLE COMPANIES (
  dummy     VARCHAR(160) not null,
  rn       bigint,
  name     VARCHAR(160) not null,
  fullname VARCHAR(160) not null,
  agent    bigint
) SERVER pfin02
--OPTIONS (schema 'DEVSYS', table 'TEST1') ;
OPTIONS (table 'COMPANIES');
select * from COMPANIES ;

