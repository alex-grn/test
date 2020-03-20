CREATE OR REPLACE FUNCTION public.p_action_gen_consol_report (
  repyear integer,
  repmonthby text,
  uid bigint,
  clear boolean
)
RETURNS void AS
$body$
declare
   NUID BIGINT:=UID;
   NREPYEAR integer:=repyear;
   RC  RECORD;
   BEN INTEGER;
begin
    /* Табличка 
   CREATE TABLE public.t_report_consol (
  id BIGSERIAL,
  uid BIGINT,
  list TEXT,
  line TEXT,
  month INTEGER,
  tcol TEXT,
  tcol2 TEXT,
  col1 NUMERIC(9,2),
  col2 NUMERIC(9,2),
  col3 NUMERIC(9,2),
  col4 NUMERIC(9,2),
  col5 NUMERIC(9,2),
  col6 NUMERIC(9,2),
  sort TEXT
) 
WITH (oids = false);
CREATE INDEX line_idx ON public.t_report_consol
  USING btree (line COLLATE pg_catalog."default");
CREATE INDEX list_idx ON public.t_report_consol
  USING btree (list COLLATE pg_catalog."default");
CREATE INDEX month_idx ON public.t_report_consol
  USING btree (month);
CREATE INDEX uid_idx ON public.t_report_consol
  USING btree (uid);
ALTER TABLE public.t_report_consol
  OWNER TO magicbox;
    */
  IF clear THEN
    -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
    execute 'set application_name = CLEARDATA';
    -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
    --DELETE FROM T_REPORT_CONSOL tr where tr.uid = NUID;
  ELSE
    -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
    execute 'set application_name = CLEARDATA';
    -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
    DELETE FROM T_REPORT_CONSOL tr where tr.uid = NUID;
    --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO1-->ШШШШШШШШШШШШШШШШШШШШШШШШШ
    FOR I IN 1..REPMONTHBY::integer
    LOOP
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      execute 'set application_name = BENEFIT01M'||I::text;
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      -- Детали
      INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,sort,TCOL,TCOL2,COL1,COL2,COL3,COL4,COL5,COL6)
      select NUID,'1',3,i,r.CODE,R.NAME as SUBJECTSDIR1,
             R.FEDREG as SUBJECTSDIR,
             (select count(DISTINCT x.benefitsrecipientsid)
                              from BENEFIT01       X,
                                    BENEFITSPACKETS XX,
                                    SUBJECTSDIR     D
                              where XX.ID = X.BENEFITSPACKETSID
                                and D.ID = XX.SUBJECTSDIRID
                                and xx.repyear = NREPYEAR
                                and xx.repmonth = i::text
                                and D.code = R.code) as NUMBER_OF_RECIPIENTS1,
             COALESCE(sum((select count(DISTINCT dd.benefitsrecipientsid)
                            from CHILD        D
                            join BENEFITCHILD DD on DD.ID = D.BENEFITCHILDID and DD.BENEFITCHILDUMBER = 1
                           where D.BENEFIT01ID = B.ID
                           group by D.BENEFIT01ID)),
                      0) as BENEF_CHILD1_1,
             COALESCE(sum((select count(DISTINCT dd.benefitsrecipientsid)
                            from CHILD        D
                            join BENEFITCHILD DD on DD.ID = D.BENEFITCHILDID and DD.BENEFITCHILDUMBER >= 2
                           where D.BENEFIT01ID = B.ID
                           group by D.BENEFIT01ID)),
                      0) as BENEF_CHILD1_2,
             COALESCE(sum((select sum(COALESCE(P.PAYSUM + P.extrasum - P.retentionsum - P.returnsum, 0))
                            from CHILD            D
                            join BENEFIT01PAYMENT P on P.BENEFIT01ID = B.ID and P.CHILD01ID = D.ID
                           where B.ID = D.BENEFIT01ID
                           group by D.BENEFIT01ID)),
                      0) as BENEFITS_PAID,
                      0,
                      0
        from SUBJECTSDIR R
        left join BENEFITSPACKETS Z
          on Z.SUBJECTSDIRID = R.ID
         and Z.REPYEAR = NREPYEAR
         and Z.REPMONTH = i::text
        left join BENEFIT01 B
          on B.BENEFITSPACKETSID = Z.ID
       group by r.CODE, R.NAME, R.FEDREG;

      --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO2-->ШШШШШШШШШШШШШШШШШШШШШШШШШ    
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      execute 'set application_name = BENEFIT02M'||I::text;
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      --Заполняем 3 линию
      INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,sort,TCOL,TCOL2,COL1,COL2,COL3,COL4,COL5,COL6)
      select NUID,'2',3,I,r.CODE,
             R.NAME as FED,
             R.FEDREG,
             (select count(DISTINCT x.benefitsrecipientsid)
                from BENEFIT02       X,
                     BENEFITSPACKETS XX,
                     SUBJECTSDIR     D
               where XX.ID = X.BENEFITSPACKETSID
                 and D.ID = XX.SUBJECTSDIRID
                 and XX.REPYEAR = NREPYEAR
                 and XX.REPMONTH = i::text
                 and D.code = R.code
                 ) as NUMBER_OF_RECIPIENTS,
             COALESCE(sum((select sum(COALESCE(P.PAYSUM + P.extrasum - P.retentionsum - P.returnsum, 0)) from BENEFIT02PAYMENT P where B.ID = P.BENEFIT02ID)), 0) as BENEFITS_PAID,0,0,0,0
        from SUBJECTSDIR R
        left join BENEFITSPACKETS Z
          on R.ID = Z.SUBJECTSDIRID
         and Z.REPYEAR = NREPYEAR
         and Z.REPMONTH = I::text
        left join BENEFIT02 B
          on B.BENEFITSPACKETSID = Z.ID
       group by r.CODE, R.NAME, R.FEDREG;

      --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO3-->ШШШШШШШШШШШШШШШШШШШШШШШШШ    
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      execute 'set application_name = BENEFIT03M'||I::text;
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      --Заполняем 3 линию
      INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,sort,TCOL,TCOL2,COL1,COL2,COL3,COL4,COL5,COL6)
      select NUID,'3',3,I,r.CODE,
             R.NAME as FED,
             R.FEDREG,
             (select count(DISTINCT x.benefitsrecipientsid)
                from BENEFIT03       X,
                     BENEFITSPACKETS XX,
                     SUBJECTSDIR     D
               where XX.ID = X.BENEFITSPACKETSID
                 and D.ID = XX.SUBJECTSDIRID
                 and XX.REPYEAR = NREPYEAR
                 and XX.REPMONTH = I::text
                 and D.CODE = R.CODE
                 ) as NUMBER_OF_RECIPIENTS,
             COALESCE(sum((select sum(COALESCE(P.PAYSUM + P.extrasum - P.retentionsum - P.returnsum, 0)) from BENEFIT03PAYMENT P where B.ID = P.BENEFIT03ID)), 0) as BENEFITS_PAID,0,0,0,0
        from SUBJECTSDIR R
        left join BENEFITSPACKETS Z
          on R.ID = Z.SUBJECTSDIRID
         and Z.REPYEAR = NREPYEAR
         and Z.REPMONTH = I::text
        left join BENEFIT03 B
          on B.BENEFITSPACKETSID = Z.ID
       group by r.CODE, R.NAME,R.FEDREG;

      --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO4-->ШШШШШШШШШШШШШШШШШШШШШШШШШ   
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      execute 'set application_name = BENEFIT04M'||I::text;
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      --Заполняем 3 линию
      INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,sort,TCOL,TCOL2,COL1,COL2,COL3,COL4,COL5,COL6)
      select NUID,'4',3,I,r.CODE,
             R.NAME as FED,
             R.FEDREG,
             (select count(DISTINCT x.benefitsrecipientsid)
                from BENEFIT04       X,
                     BENEFITSPACKETS XX,
                     SUBJECTSDIR     D
               where XX.ID = X.BENEFITSPACKETSID
                 and D.ID = XX.SUBJECTSDIRID
                 and XX.REPYEAR = NREPYEAR
                 and XX.REPMONTH = I::text
                 and D.code = R.code
                 ) as NUMBER_OF_RECIPIENTS,
             COALESCE(sum((select sum(COALESCE(P.PAYSUM + P.extrasum - P.retentionsum - P.returnsum, 0)) from BENEFIT04PAYMENT P where B.ID = P.BENEFIT04ID)), 0) as BENEFITS_PAID,
             sum((select count(DISTINCT c.benefitchildid)
                    from BENEFIT04PAYMENT P,
                         child04 		  c
                   where B.ID = P.BENEFIT04ID
                     and c.id = p.child04id)) as count_r,0,0,0
        from SUBJECTSDIR R
        left join BENEFITSPACKETS Z
          on R.ID = Z.SUBJECTSDIRID
         and Z.REPYEAR = NREPYEAR
         and Z.REPMONTH = I::text
        left join BENEFIT04 B
          on B.BENEFITSPACKETSID = Z.ID
       group by r.CODE, R.NAME, R.FEDREG;

      --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO5-->ШШШШШШШШШШШШШШШШШШШШШШШШШ    
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      execute 'set application_name = BENEFIT05M'||I::text;
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      --Заполняем 3 линию
      INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,sort,TCOL,TCOL2,COL1,COL2,COL3,COL4,COL5,COL6)
      select NUID,'5',3,I,r.CODE,
             R.NAME as FED,
             R.FEDREG,
             (select count(DISTINCT x.benefitsrecipientsid)
                from BENEFIT05       X,
                     BENEFITSPACKETS XX,
                     SUBJECTSDIR     D
               where XX.ID = X.BENEFITSPACKETSID
                 and D.ID = XX.SUBJECTSDIRID
                 and XX.REPYEAR = NREPYEAR
                 and XX.REPMONTH = I::text
                 and D.CODE = R.CODE) as NUMBER_OF_RECIPIENTS,
             COALESCE(sum((select sum(COALESCE(P.PAYSUM + P.extrasum - P.retentionsum - P.returnsum, 0)) from BENEFIT05PAYMENT P where B.ID = P.BENEFIT05ID)), 0) as BENEFITS_PAID,0,0,0,0
        from SUBJECTSDIR R
        left join BENEFITSPACKETS Z
          on R.ID = Z.SUBJECTSDIRID
         and Z.REPYEAR = NREPYEAR
         and Z.REPMONTH = I::text
        left join BENEFIT05 B
          on B.BENEFITSPACKETSID = Z.ID
       group by r.CODE, R.NAME,R.FEDREG;

      --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO6-->ШШШШШШШШШШШШШШШШШШШШШШШШШ    
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      execute 'set application_name = BENEFIT06M'||I::text;
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      --Заполняем 3 линию
      INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,sort,TCOL,TCOL2,COL1,COL2,COL3,COL4,COL5,COL6)
      select NUID,'6',3,I,r.CODE,
             R.NAME as FED,
             R.FEDREG,
             (select count(DISTINCT x.benefitsrecipientsid)
                from BENEFIT06       X,
                     BENEFITSPACKETS XX,
                     SUBJECTSDIR     D
               where XX.ID = X.BENEFITSPACKETSID
                 and D.ID = XX.SUBJECTSDIRID
                 and XX.REPYEAR = NREPYEAR
                 and XX.REPMONTH = I::text
                 and D.CODE = R.CODE) as NUMBER_OF_RECIPIENTS,
             COALESCE(sum((select sum(COALESCE(P.PAYSUM + P.extrasum - P.retentionsum - P.returnsum, 0)) from BENEFIT06PAYMENT P where B.ID = P.BENEFIT06ID)), 0) as BENEFITS_PAID,0,0,0,0
        from SUBJECTSDIR R
        left join BENEFITSPACKETS Z
          on R.ID = Z.SUBJECTSDIRID
         and Z.REPYEAR = NREPYEAR
         and Z.REPMONTH = I::text
        left join BENEFIT06 B
          on B.BENEFITSPACKETSID = Z.ID
       group by r.CODE, R.NAME,R.FEDREG;
    END LOOP;


    -- Итоги
    For BEN in 1..6
    loop
        -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      execute 'set application_name = TOTALROW'||BEN::text;
      -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
      -- итоги по округам
      INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,sort,TCOL,COL1,COL2,COL3,COL4,COL5,COL6)
      SELECT NUID,T.LIST,2,t.month,min(t.sort::int),TCOL2,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3),SUM(T.COL4),SUM(T.COL5),SUM(T.COL6)
        FROM T_REPORT_CONSOL T
       WHERE T.UID = NUID
         AND T.LIST = BEN::text
         AND T.LINE = '3'
         and t.month <= 12
       group by T.LIST, t.month, T.TCOL2;
                     
      -- полный итог
      INSERT INTO T_REPORT_CONSOL(uid,list,line,month,sort,COL1,COL2,COL3,COL4,COL5,COL6)
      SELECT NUID,T.LIST,1,t.month,min(t.sort::int),SUM(T.COL1),SUM(T.COL2),SUM(T.COL3),SUM(T.COL4),SUM(T.COL5),SUM(T.COL6)
        FROM T_REPORT_CONSOL T
       WHERE T.UID = NUID
         AND T.LIST = BEN::text
         AND T.LINE = '2'
         and t.month <= 12
       group by T.LIST, t.month;
                 
        -- итоги по всем месяцам
       INSERT INTO T_REPORT_CONSOL(uid,list,line,month,sort,COL1,COL2,COL3,COL4,COL5,COL6)
       SELECT NUID,T.LIST,1,13,min(t.sort::int),SUM(T.COL1),SUM(T.COL2),SUM(T.COL3),SUM(T.COL4),SUM(T.COL5),SUM(T.COL6)
         FROM T_REPORT_CONSOL T
        WHERE T.UID = NUID
         AND T.LIST = BEN::text
          AND T.LINE = '1'
        GROUP BY T.LIST;
       INSERT INTO T_REPORT_CONSOL(uid,list,line,month,sort,TCOL,COL1,COL2,COL3,COL4,COL5,COL6)
       SELECT NUID,T.LIST,2,13,min(t.sort::int),TCOL,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3),SUM(T.COL4),SUM(T.COL5),SUM(T.COL6)
         FROM T_REPORT_CONSOL T
        WHERE T.UID = NUID
         AND T.LIST = BEN::text
          AND T.LINE = '2'
        GROUP BY T.LIST, TCOL;
       INSERT INTO T_REPORT_CONSOL(uid,list,line,month,sort,TCOL,TCOL2,COL1,COL2,COL3,COL4,COL5,COL6)
       SELECT NUID,T.LIST,3,13,min(t.sort::int),TCOL,TCOL2,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3),SUM(T.COL4),SUM(T.COL5),SUM(T.COL6)
         FROM T_REPORT_CONSOL T
        WHERE T.UID = NUID
          AND T.LIST = BEN::text
          AND T.LINE = '3'
        GROUP BY T.LIST, TCOL,TCOL2;
    end loop;
  END IF;
  -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
  execute 'set application_name = "pgAdmin III"';
  -- ############# ОТОБРАЖЕНИЕ ПРОЦЕССА #############
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_gen_consol_report (repyear integer, repmonthby text, uid bigint, clear boolean)
  OWNER TO magicbox;