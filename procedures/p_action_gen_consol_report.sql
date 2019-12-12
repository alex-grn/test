CREATE OR REPLACE FUNCTION public.p_action_gen_consol_report (
  repyear integer,
  repmonthby text,
  uid bigint
)
RETURNS void AS
$body$
declare
   NUID BIGINT:=UID;
   NREPYEAR integer:=repyear;
   RC RECORD;
   BEN RECORD; --ПОСОБИЕ
begin
    /* Табличка 
   CREATE TABLE public.t_report_consol (
  id BIGINT DEFAULT nextval('t_report_consol_id_seq'::regclass) NOT NULL,
  uid BIGINT,
  list TEXT,
  line TEXT,
  month INTEGER,
  tcol TEXT,
  col1 NUMERIC(9,2),
  col2 NUMERIC(9,2),
  col3 NUMERIC(9,2),
  col4 NUMERIC(9,2),
  col5 NUMERIC(9,2),
  col6 NUMERIC(9,2),
  tcol2 TEXT
) 
WITH (oids = false);

ALTER TABLE public.t_report_consol
  OWNER TO magicbox;
    */
 DELETE FROM T_REPORT_CONSOL;
    FOR BEN IN (
    	SELECT T.ROSTERNUMBER AS NUM --Номер реестра
          FROM BENEFITSTYPEDIR T
    )
    LOOP
    --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO1-->ШШШШШШШШШШШШШШШШШШШШШШШШШ
    	IF BEN.NUM = 1 THEN
        	FOR I IN 1..REPMONTHBY::integer+1
             LOOP
              IF I != 13 THEN
              --Заполняем первую линию
        	  INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2,COL3,COL4)
                       (select NUID,BEN.NUM,1,I,
                         COALESCE(sum((select count(*) OVER()
                                        from BENEFITCHILD DD,
                                             CHILD        D
                                       where DD.ID = D.BENEFITCHILDID
                                         and B.ID = D.BENEFIT01ID
                                       group by D.BENEFIT01ID)),
                                  0) as NUMBER_OF_RECIPIENTS1, 
                         COALESCE(sum((select count(*)
                                        from BENEFITCHILD DD,
                                             CHILD        D
                                       where DD.ID = D.BENEFITCHILDID
                                         and DD.BENEFITCHILDUMBER = 1
                                         and B.ID = D.BENEFIT01ID
                                       group by D.BENEFIT01ID)),
                                  0) as BENEF_CHILD1_1,
                         
                         COALESCE(sum((select count(*)
                                        from BENEFITCHILD DD,
                                             CHILD        D
                                       where DD.ID = D.BENEFITCHILDID
                                         and DD.BENEFITCHILDUMBER >= 2
                                         and B.ID = D.BENEFIT01ID
                                       group by D.BENEFIT01ID)),
                                  0) as BENEF_CHILD1_2,
                         COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0))
                                        from BENEFITCHILD     DD,
                                             BENEFIT01PAYMENT P,
                                             CHILD            D
                                       where DD.ID = D.BENEFITCHILDID
                                         and B.ID = P.BENEFIT01ID
                                         and P.CHILD01ID = D.ID
                                         and DD.BENEFITCHILDUMBER = 1
                                         and B.ID = D.BENEFIT01ID
                                       group by D.BENEFIT01ID)),
                                  0) +
                         COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0))
                                        from BENEFITCHILD     DD,
                                             BENEFIT01PAYMENT P,
                                             CHILD            D
                                       where DD.ID = D.BENEFITCHILDID
                                         and B.ID = P.BENEFIT01ID
                                         and P.CHILD01ID = D.ID
                                         and DD.BENEFITCHILDUMBER >= 2
                                         and B.ID = D.BENEFIT01ID
                                       group by D.BENEFIT01ID)),
                                  0) as BENEFITS_PAID
                    from SUBJECTSDIR R
                    left join BENEFITSPACKETS Z
                      on R.ID = Z.SUBJECTSDIRID
                     and Z.REPMONTH::integer = I
                     and Z.REPYEAR = NREPYEAR
                    left join BENEFIT01 B
                      on B.BENEFITSPACKETSID = Z.ID);
                      
               --Заполняем вторую линию
               INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2,COL3,COL4)
               select NUID,BEN.NUM,2,I,
               		  R.FEDREG as SUBJECTSDIR,
                      COALESCE(sum((select count(*) OVER()
                                     from BENEFITCHILD DD,
                                          CHILD        D
                                    where DD.ID = D.BENEFITCHILDID
                                      and B.ID = D.BENEFIT01ID
                                    group by D.BENEFIT01ID)),
                               0) as NUMBER_OF_RECIPIENTS1,
                      COALESCE(sum((select count(*)
                                     from BENEFITCHILD DD,
                                          CHILD        D
                                    where DD.ID = D.BENEFITCHILDID
                                      and DD.BENEFITCHILDUMBER = 1
                                      and B.ID = D.BENEFIT01ID
                                    group by D.BENEFIT01ID)),
                               0) as BENEF_CHILD1_1,
                      COALESCE(sum((select count(*)
                                     from BENEFITCHILD DD,
                                          CHILD        D
                                    where DD.ID = D.BENEFITCHILDID
                                      and DD.BENEFITCHILDUMBER >= 2
                                      and B.ID = D.BENEFIT01ID
                                    group by D.BENEFIT01ID)),
                               0) as BENEF_CHILD1_2,
                      COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0))
                                     from BENEFITCHILD     DD,
                                          BENEFIT01PAYMENT P,
                                          CHILD            D
                                    where DD.ID = D.BENEFITCHILDID
                                      and B.ID = P.BENEFIT01ID
                                      and P.CHILD01ID = D.ID
                                      and DD.BENEFITCHILDUMBER = 1
                                      and B.ID = D.BENEFIT01ID
                                    group by D.BENEFIT01ID)),
                               0) +
                      COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0))
                                     from BENEFITCHILD     DD,
                                          BENEFIT01PAYMENT P,
                                          CHILD            D
                                    where DD.ID = D.BENEFITCHILDID
                                      and B.ID = P.BENEFIT01ID
                                      and P.CHILD01ID = D.ID
                                      and DD.BENEFITCHILDUMBER >= 2
                                      and B.ID = D.BENEFIT01ID
                                    group by D.BENEFIT01ID)),
                               0) as BENEFITS_PAID
                 from SUBJECTSDIR R
                 left join BENEFITSPACKETS Z
                   on R.ID = Z.SUBJECTSDIRID
                  and Z.REPMONTH::integer = I
                  and Z.REPYEAR = NREPYEAR
                 left join BENEFIT01 B
                   on B.BENEFITSPACKETSID = Z.ID
                group by R.FEDREG;
              --Заполняем 3 линию
              INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,TCOL,TCOL2,COL1,COL2,COL3,COL4)
              select NUID,BEN.NUM,3,I,
              		 R.NAME as SUBJECTSDIR1,
                     R.FEDREG as SUBJECTSDIR,
                     COALESCE(sum((select count(*) OVER()
                                    from BENEFITCHILD DD,
                                         CHILD        D
                                   where DD.ID = D.BENEFITCHILDID
                                     and B.ID = D.BENEFIT01ID
                                   group by D.BENEFIT01ID)),
                              0) as NUMBER_OF_RECIPIENTS1,
                     COALESCE(sum((select count(*)
                                    from BENEFITCHILD DD,
                                         CHILD        D
                                   where DD.ID = D.BENEFITCHILDID
                                     and DD.BENEFITCHILDUMBER = 1
                                     and B.ID = D.BENEFIT01ID
                                   group by D.BENEFIT01ID)),
                              0) as BENEF_CHILD1_1,
                     COALESCE(sum((select count(*)
                                    from BENEFITCHILD DD,
                                         CHILD        D
                                   where DD.ID = D.BENEFITCHILDID
                                     and DD.BENEFITCHILDUMBER >= 2
                                     and B.ID = D.BENEFIT01ID
                                   group by D.BENEFIT01ID)),
                              0) as BENEF_CHILD1_2,
                     
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0))
                                    from BENEFITCHILD     DD,
                                         BENEFIT01PAYMENT P,
                                         CHILD            D
                                   where DD.ID = D.BENEFITCHILDID
                                     and B.ID = P.BENEFIT01ID
                                     and P.CHILD01ID = D.ID
                                     and DD.BENEFITCHILDUMBER = 1
                                     and B.ID = D.BENEFIT01ID
                                   group by D.BENEFIT01ID)),
                              0) +
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0))
                                    from BENEFITCHILD     DD,
                                         BENEFIT01PAYMENT P,
                                         CHILD            D
                                   where DD.ID = D.BENEFITCHILDID
                                     and B.ID = P.BENEFIT01ID
                                     and P.CHILD01ID = D.ID
                                     and DD.BENEFITCHILDUMBER >= 2
                                     and B.ID = D.BENEFIT01ID
                                   group by D.BENEFIT01ID)),
                              0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT01 B
                  on B.BENEFITSPACKETSID = Z.ID
             --  where R.FEDREG = ${SPEC.SUBJECTSDIR}
               group by R.NAME, R.FEDREG;


            ELSE
            
            	INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2,COL3,COL4)
                SELECT NUID,BEN.NUM,1,I,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3),SUM(T.COL4)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '1';
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2,COL3,COL4)
                SELECT NUID,BEN.NUM,2,I,TCOL,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3),SUM(T.COL4)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '2'
                   GROUP BY TCOL;
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,TCOL2,COL1,COL2,COL3,COL4)
                SELECT NUID,BEN.NUM,3,I,TCOL,TCOL2,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3),SUM(T.COL4)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '3'
                   GROUP BY TCOL,TCOL2;
                
        	END IF;
            END LOOP;
    --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO2-->ШШШШШШШШШШШШШШШШШШШШШШШШШ    
        ELSIF BEN.NUM = 2 THEN
    		FOR I IN 1..REPMONTHBY::integer+1
             LOOP
              IF I != 13 THEN
              --Заполняем первую линию
        	  INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2)
                       select NUID,BEN.NUM,1,I,
                             (select count(*)
                                from BENEFIT02       X,
                                     BENEFITSPACKETS XX
                               where XX.ID = X.BENEFITSPACKETSID
                                 and XX.REPMONTH::integer = I
                  		 		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                             COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT02PAYMENT P where B.ID = P.BENEFIT02ID)), 0) as BENEFITS_PAID
                        from SUBJECTSDIR R
                        left join BENEFITSPACKETS Z
                          on R.ID = Z.SUBJECTSDIRID
                         and Z.REPMONTH::integer = I
                  		 and Z.REPYEAR = NREPYEAR
                        left join BENEFIT02 B
                          on B.BENEFITSPACKETSID = Z.ID;

               --Заполняем вторую линию
               INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2)
               select NUID,BEN.NUM,2,I,
               		  R.FEDREG as FED,
                     (select count(*)
                        from BENEFIT02       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.FEDREG = R.FEDREG
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT02PAYMENT P where B.ID = P.BENEFIT02ID)), 0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT02 B
                  on B.BENEFITSPACKETSID = Z.ID
               group by R.FEDREG;
              --Заполняем 3 линию
              INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,TCOL,TCOL2,COL1,COL2)
              select NUID,BEN.NUM,3,I,
              		 R.NAME as FED,
                     R.FEDREG,
                     (select count(*)
                        from BENEFIT02       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.NAME = R.NAME
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT02PAYMENT P where B.ID = P.BENEFIT02ID)), 0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT02 B
                  on B.BENEFITSPACKETSID = Z.ID
               --where R.FEDREG = ${SPEC1.FED}
               group by R.NAME,R.FEDREG;

            ELSE
            
            	INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2)
                SELECT NUID,BEN.NUM,1,I,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '1';
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2)
                SELECT NUID,BEN.NUM,2,I,TCOL,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '2'
                   GROUP BY TCOL;
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,TCOL2,COL1,COL2)
                SELECT NUID,BEN.NUM,3,I,TCOL,TCOL2,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '3'
                   GROUP BY TCOL,TCOL2;
                
        	END IF;
            END LOOP;
    
    --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO3-->ШШШШШШШШШШШШШШШШШШШШШШШШШ    
        ELSIF BEN.NUM = 3 THEN
    		FOR I IN 1..REPMONTHBY::integer+1
             LOOP
              IF I != 13 THEN
              --Заполняем первую линию
        	  INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2)
                       select NUID,BEN.NUM,1,I,
                             (select count(*)
                                from BENEFIT03       X,
                                     BENEFITSPACKETS XX
                               where XX.ID = X.BENEFITSPACKETSID
                                 and XX.REPMONTH::integer = I
                  		 		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                             COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT03PAYMENT P where B.ID = P.BENEFIT03ID)), 0) as BENEFITS_PAID
                        from SUBJECTSDIR R
                        left join BENEFITSPACKETS Z
                          on R.ID = Z.SUBJECTSDIRID
                         and Z.REPMONTH::integer = I
                  		 and Z.REPYEAR = NREPYEAR
                        left join BENEFIT03 B
                          on B.BENEFITSPACKETSID = Z.ID;

               --Заполняем вторую линию
               INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2)
               select NUID,BEN.NUM,2,I,
               		  R.FEDREG as FED,
                     (select count(*)
                        from BENEFIT03       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.FEDREG = R.FEDREG
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT03PAYMENT P where B.ID = P.BENEFIT03ID)), 0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT03 B
                  on B.BENEFITSPACKETSID = Z.ID
               group by R.FEDREG;
              --Заполняем 3 линию
              INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,TCOL,TCOL2,COL1,COL2)
              select NUID,BEN.NUM,3,I,
              		 R.NAME as FED,
                     R.FEDREG,
                     (select count(*)
                        from BENEFIT03       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.NAME = R.NAME
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT03PAYMENT P where B.ID = P.BENEFIT03ID)), 0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT03 B
                  on B.BENEFITSPACKETSID = Z.ID
               --where R.FEDREG = ${SPEC1.FED}
               group by R.NAME,R.FEDREG;

            ELSE
            
            	INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2)
                SELECT NUID,BEN.NUM,1,I,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '1';
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2)
                SELECT NUID,BEN.NUM,2,I,TCOL,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '2'
                   GROUP BY TCOL;
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,TCOL2,COL1,COL2)
                SELECT NUID,BEN.NUM,3,I,TCOL,TCOL2,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '3'
                   GROUP BY TCOL,TCOL2;
                
        	END IF;
            END LOOP;
    
    --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO4-->ШШШШШШШШШШШШШШШШШШШШШШШШШ   
        ELSIF BEN.NUM = 4 THEN
    		FOR I IN 1..REPMONTHBY::integer+1
             LOOP
              IF I != 13 THEN
              --Заполняем первую линию
        	  INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2,COL3)
                       select NUID,BEN.NUM,1,I,
                             (select count(*)
                                from BENEFIT04       X,
                                     BENEFITSPACKETS XX
                               where XX.ID = X.BENEFITSPACKETSID
                                 and XX.REPMONTH::integer = I
                  		 		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                             COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT04PAYMENT P where B.ID = P.BENEFIT04ID)), 0) as BENEFITS_PAID,
                             sum((select count(p.id) from BENEFIT04PAYMENT P where B.ID = P.BENEFIT04ID)) as count_r
                        from SUBJECTSDIR R
                        left join BENEFITSPACKETS Z
                          on R.ID = Z.SUBJECTSDIRID
                         and Z.REPMONTH::integer = I
                  		 and Z.REPYEAR = NREPYEAR
                        left join BENEFIT04 B
                          on B.BENEFITSPACKETSID = Z.ID;

               --Заполняем вторую линию
               INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2,COL3)
               select NUID,BEN.NUM,2,I,
               		  R.FEDREG as FED,
                     (select count(*)
                        from BENEFIT04       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.FEDREG = R.FEDREG
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT04PAYMENT P where B.ID = P.BENEFIT04ID)), 0) as BENEFITS_PAID,
                     sum((select count(p.id) from BENEFIT04PAYMENT P where B.ID = P.BENEFIT04ID)) as count_r
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT04 B
                  on B.BENEFITSPACKETSID = Z.ID
               group by R.FEDREG;
              --Заполняем 3 линию
              INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,TCOL,TCOL2,COL1,COL2,COL3)
              select NUID,BEN.NUM,3,I,
              		 R.NAME as FED,
                     R.FEDREG,
                     (select count(*)
                        from BENEFIT04       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.NAME = R.NAME
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT04PAYMENT P where B.ID = P.BENEFIT04ID)), 0) as BENEFITS_PAID,
                     sum((select count(p.id) from BENEFIT04PAYMENT P where B.ID = P.BENEFIT04ID)) as count_r
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT04 B
                  on B.BENEFITSPACKETSID = Z.ID
               --where R.FEDREG = ${SPEC1.FED}
               group by R.NAME,R.FEDREG;

            ELSE
            
            	INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2,COL3)
                SELECT NUID,BEN.NUM,1,I,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '1';
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2,COL3)
                SELECT NUID,BEN.NUM,2,I,TCOL,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '2'
                   GROUP BY TCOL;
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,TCOL2,COL1,COL2,COL3)
                SELECT NUID,BEN.NUM,3,I,TCOL,TCOL2,SUM(T.COL1),SUM(T.COL2),SUM(T.COL3)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '3'
                   GROUP BY TCOL,TCOL2;
                
        	END IF;
            END LOOP;
    
    --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO5-->ШШШШШШШШШШШШШШШШШШШШШШШШШ    
        ELSIF BEN.NUM = 5 THEN
    		FOR I IN 1..REPMONTHBY::integer+1
             LOOP
              IF I != 13 THEN
              --Заполняем первую линию
        	  INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2)
                       select NUID,BEN.NUM,1,I,
                             (select count(*)
                                from BENEFIT05       X,
                                     BENEFITSPACKETS XX
                               where XX.ID = X.BENEFITSPACKETSID
                                 and XX.REPMONTH::integer = I
                  		 		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                             COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT05PAYMENT P where B.ID = P.BENEFIT05ID)), 0) as BENEFITS_PAID
                        from SUBJECTSDIR R
                        left join BENEFITSPACKETS Z
                          on R.ID = Z.SUBJECTSDIRID
                         and Z.REPMONTH::integer = I
                  		 and Z.REPYEAR = NREPYEAR
                        left join BENEFIT05 B
                          on B.BENEFITSPACKETSID = Z.ID;

               --Заполняем вторую линию
               INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2)
               select NUID,BEN.NUM,2,I,
               		  R.FEDREG as FED,
                     (select count(*)
                        from BENEFIT05       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.FEDREG = R.FEDREG
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT05PAYMENT P where B.ID = P.BENEFIT05ID)), 0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT05 B
                  on B.BENEFITSPACKETSID = Z.ID
               group by R.FEDREG;
              --Заполняем 3 линию
              INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,TCOL,TCOL2,COL1,COL2)
              select NUID,BEN.NUM,3,I,
              		 R.NAME as FED,
                     R.FEDREG,
                     (select count(*)
                        from BENEFIT05       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.NAME = R.NAME
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT05PAYMENT P where B.ID = P.BENEFIT05ID)), 0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT05 B
                  on B.BENEFITSPACKETSID = Z.ID
               --where R.FEDREG = ${SPEC1.FED}
               group by R.NAME,R.FEDREG;

            ELSE
            
            	INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2)
                SELECT NUID,BEN.NUM,1,I,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '1';
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2)
                SELECT NUID,BEN.NUM,2,I,TCOL,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '2'
                   GROUP BY TCOL;
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,TCOL2,COL1,COL2)
                SELECT NUID,BEN.NUM,3,I,TCOL,TCOL2,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '3'
                   GROUP BY TCOL,TCOL2;
                
        	END IF;
            END LOOP;
    
    --ШШШШШШШШШШШШШШШШШШШШШШШШШ<--BENEFITO6-->ШШШШШШШШШШШШШШШШШШШШШШШШШ    
        ELSIF BEN.NUM = 6 THEN
        	FOR I IN 1..REPMONTHBY::integer+1
             LOOP
              IF I != 13 THEN
              --Заполняем первую линию
        	  INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2)
                       select NUID,BEN.NUM,1,I,
                             (select count(*)
                                from BENEFIT06       X,
                                     BENEFITSPACKETS XX
                               where XX.ID = X.BENEFITSPACKETSID
                                 and XX.REPMONTH::integer = I
                  		 		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                             COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT06PAYMENT P where B.ID = P.BENEFIT06ID)), 0) as BENEFITS_PAID
                        from SUBJECTSDIR R
                        left join BENEFITSPACKETS Z
                          on R.ID = Z.SUBJECTSDIRID
                         and Z.REPMONTH::integer = I
                  		 and Z.REPYEAR = NREPYEAR
                        left join BENEFIT06 B
                          on B.BENEFITSPACKETSID = Z.ID;

               --Заполняем вторую линию
               INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2)
               select NUID,BEN.NUM,2,I,
               		  R.FEDREG as FED,
                     (select count(*)
                        from BENEFIT06      X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.FEDREG = R.FEDREG
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT06PAYMENT P where B.ID = P.BENEFIT06ID)), 0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT06 B
                  on B.BENEFITSPACKETSID = Z.ID
               group by R.FEDREG;
              --Заполняем 3 линию
              INSERT INTO T_REPORT_CONSOL(UID,LIST,LINE,MONTH,TCOL,TCOL2,COL1,COL2)
              select NUID,BEN.NUM,3,I,
              		 R.NAME as FED,
                     R.FEDREG,
                     (select count(*)
                        from BENEFIT06       X,
                             BENEFITSPACKETS XX,
                             SUBJECTSDIR     D
                       where XX.ID = X.BENEFITSPACKETSID
                         and D.ID = XX.SUBJECTSDIRID
                         and D.NAME = R.NAME
                         and XX.REPMONTH::integer = I
                  		 and XX.REPYEAR = NREPYEAR) as NUMBER_OF_RECIPIENTS,
                     COALESCE(sum((select sum(COALESCE(P.PAYSUM, 0)) from BENEFIT06PAYMENT P where B.ID = P.BENEFIT06ID)), 0) as BENEFITS_PAID
                from SUBJECTSDIR R
                left join BENEFITSPACKETS Z
                  on R.ID = Z.SUBJECTSDIRID
                 and Z.REPMONTH::integer = I
                 and Z.REPYEAR = NREPYEAR
                left join BENEFIT06 B
                  on B.BENEFITSPACKETSID = Z.ID
               --where R.FEDREG = ${SPEC1.FED}
               group by R.NAME,R.FEDREG;

            ELSE
            
            	INSERT INTO T_REPORT_CONSOL(uid,list,line,month,COL1,COL2)
                SELECT NUID,BEN.NUM,1,I,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '1';
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,COL1,COL2)
                SELECT NUID,BEN.NUM,2,I,TCOL,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '2'
                   GROUP BY TCOL;
                INSERT INTO T_REPORT_CONSOL(uid,list,line,month,TCOL,TCOL2,COL1,COL2)
                SELECT NUID,BEN.NUM,3,I,TCOL,TCOL2,SUM(T.COL1),SUM(T.COL2)
                  FROM T_REPORT_CONSOL T
                 WHERE T.UID = NUID
                   AND T.LIST = BEN.NUM::TEXT 
                   AND T.LINE = '3'
                   GROUP BY TCOL,TCOL2;
                
        	END IF;
            END LOOP;
        END IF;
    
    END LOOP;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_gen_consol_report (repyear integer, repmonthby text, uid bigint)
  OWNER TO magicbox;