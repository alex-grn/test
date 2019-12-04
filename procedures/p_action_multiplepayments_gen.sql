CREATE OR REPLACE FUNCTION public.p_action_multiplepayments_gen (
  benefitstypenamedirid bigint [],
  repyear integer,
  lastnameb text,
  firstnameb text,
  patronymicb text,
  persondocumenttypeid bigint,
  docseriesb text,
  docnumberb text,
  lastnamec text,
  firstnamec text,
  patronymicc text,
  docbirthchildtypeid bigint,
  docseriesc text,
  docnumberc text,
  birthdatec date,
  uid bigint
)
RETURNS void AS
$body$
declare
  BENEF        BIGINT;
  CHILDS       BIGINT;
  RNUMBER      INTEGER;
  NYEAR        INTEGER = REPYEAR;
  TBENEF       BIGINT [ ] = BENEFITSTYPENAMEDIRID;
  FL           INTEGER := 0;
  REC          RECORD;
  DUB          RECORD;
  OB           RECORD;
  NUID         BIGINT = UID;
  ALL_FIELDS_H INTEGER := 0; --human
  ALL_FIELDS_C INTEGER := 0; --child
  NPEKA        BIGINT;
  TPOSOB       BIGINT;
  SSQL         TEXT;
  --бфхырхь ьрёёшт фыџ ѕ№рэхэшџ тћяырђ
  MPAYS INTEGER [ ];
  I     INTEGER;
begin
  DELETE FROM MULTIPLEPAYMENTS S WHERE S.UID = NUID;
  IF LASTNAMEB IS NULL AND FIRSTNAMEB IS NULL AND PATRONYMICB IS NULL AND PERSONDOCUMENTTYPEID IS NULL AND DOCSERIESB IS NULL AND DOCNUMBERB IS NULL /* and docdateb is null*/
   THEN
    ALL_FIELDS_H := 1;
  END IF;
  IF LASTNAMEC IS NULL AND FIRSTNAMEC IS NULL AND PATRONYMICC IS NULL AND DOCBIRTHCHILDTYPEID IS NULL AND DOCSERIESC IS NULL AND DOCNUMBERC IS NULL AND BIRTHDATEC IS NULL THEN
    ALL_FIELDS_C := 1;
  END IF;
  IF ALL_FIELDS_H != 1 THEN
    BEGIN
      SELECT S.ID
        INTO STRICT BENEF
        FROM BENEFITSRECIPIENTS S
       WHERE (LOWER(S.LASTNAME) = LOWER(LASTNAMEB) OR LASTNAMEB IS NULL)
         AND (LOWER(S.FIRSTNAME) = LOWER(FIRSTNAMEB) OR FIRSTNAMEB IS NULL)
         AND (LOWER(S.PATRONYMIC) = LOWER(PATRONYMICB) OR PATRONYMICB IS NULL)
         AND (S.PERSONDOCUMENTTYPEID = P_ACTION_MULTIPLEPAYMENTS_GEN.PERSONDOCUMENTTYPEID OR P_ACTION_MULTIPLEPAYMENTS_GEN.PERSONDOCUMENTTYPEID IS NULL)
         AND (LOWER(S.PERSONDOCUMENTSERIES) = LOWER(DOCSERIESB) OR DOCSERIESB IS NULL)
         AND (LOWER(S.PERSONDOCUMENTNUMBER) = LOWER(DOCNUMBERB) OR DOCNUMBERB IS NULL);
      --  and (s.persondocumentdate = docdateb or docdateb is null);
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        RAISE
          USING MESSAGE = 'Яю чрфрээюьѓ ъ№шђх№шў эрщфхэю сюыќјх юфэюую яюыѓїрђхыџ яюёюсшџ!';
      WHEN NO_DATA_FOUND THEN
        BENEF := NULL;
    END; --raise using message = benef;
  END IF;
 IF ALL_FIELDS_C != 1 THEN
    BEGIN
      SELECT C.ID
        INTO STRICT CHILDS
        FROM BENEFITCHILD C
       WHERE (LOWER(C.LASTNAME) = LOWER(LASTNAMEC) OR LASTNAMEC IS NULL)
         AND (LOWER(C.FIRSTNAME) = LOWER(FIRSTNAMEC) OR FIRSTNAMEC IS NULL)
         AND (LOWER(C.PATRONYMIC) = LOWER(PATRONYMICC) OR PATRONYMICC IS NULL)
         AND (C.DOCBIRTHCHILDTYPEID = P_ACTION_MULTIPLEPAYMENTS_GEN.DOCBIRTHCHILDTYPEID OR P_ACTION_MULTIPLEPAYMENTS_GEN.DOCBIRTHCHILDTYPEID IS NULL)
         AND (LOWER(C.DOCBIRTHCHILDSERIAL) = LOWER(DOCSERIESC) OR DOCSERIESC IS NULL)
         AND (LOWER(C.DOCBIRTHCHILDNUMBER) = LOWER(DOCNUMBERC) OR DOCNUMBERC IS NULL)
            --  and (c.docbirthchilddate = docnumberc or docnumberc is null)
         AND (C.BENEFITCHILDDATEBIRTH = BIRTHDATEC OR BIRTHDATEC IS NULL)
         AND (C.BENEFITSRECIPIENTSID = BENEF OR BENEF = 0);
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        RAISE
          USING MESSAGE = 'Яю чрфрээюьѓ ъ№шђх№шў эрщфхэю сюыќјх юфэюую №хсхэър!';
      WHEN NO_DATA_FOUND THEN
        CHILDS := NULL;
    END;
  END IF;
  --raise using message = 'FFFFFF@$%^ '|| rNumber;
  /* select r.rosternumber::integer
     into rNumber
     from benefitstypedir r
    where r.id = tBenef;*/  
  --  
   FOR OB IN (SELECT R.ROSTERNUMBER ::INTEGER AS RNUMBER,
                     R.ID           AS TIR
                FROM BENEFITSTYPEDIR R
               WHERE R.ID = ANY(TBENEF))
  LOOP
 --ииииииииииииииииииииииииииииииииииииииииииииииииии аХХбва 01 ииииииииииииииииииииииииииииииииииииииииииииииииии    
 IF OB.RNUMBER = 1 THEN 
     I:=1;MPAYS[I]:=0;      
      FOR REC IN (SELECT B.BENEFITSRECIPIENTSID,
                     C.BENEFITCHILDID,
                     H.ID AS PAYSID,
                     P.SUBJECTSDIRID,
                     H.PAYDATE AS DDATE,
                     COALESCE(H.PAYSUM, 0) AS SSUM,
                     S.DOCBIRTHCHILDNUMBER,
                     S.DOCBIRTHCHILDSERIAL,
                     TO_DATE(LEFT(H.PAYDATE, 10), 'dd.mm.yyyy') AS DDATE1,
                     TO_DATE(RIGHT(H.PAYDATE, 10), 'dd.mm.yyyy') AS DDATE2
                FROM BENEFIT01        B,
                     BENEFITSPACKETS  P,
                     BENEFIT01PAYMENT H,
                     CHILD            C,
                     BENEFITCHILD     S
               WHERE (B.BENEFITSRECIPIENTSID = BENEF OR ALL_FIELDS_H = 1)
                 AND P.ID = B.BENEFITSPACKETSID
                 AND H.BENEFIT01ID = B.ID
                 AND C.ID = H.CHILD01ID
                 AND (C.BENEFITCHILDID = CHILDS OR ALL_FIELDS_C = 1)
                 AND P.REPYEAR = NYEAR
                 AND S.ID = C.BENEFITCHILDID
               GROUP BY B.BENEFITSRECIPIENTSID,
                        C.BENEFITCHILDID,
                        H.PAYDATE,
                        H.ID,
                        P.SUBJECTSDIRID,
                        S.DOCBIRTHCHILDNUMBER,
                        S.DOCBIRTHCHILDSERIAL)
       LOOP
    IF (SELECT COUNT(*)
        FROM BENEFIT01        B,
             BENEFITSPACKETS  P,
             BENEFIT01PAYMENT H,
             CHILD            C,
             BENEFITCHILD     S
       WHERE B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
         AND P.ID = B.BENEFITSPACKETSID
         AND H.BENEFIT01ID = B.ID
         AND C.ID = H.CHILD01ID
            --and c.benefitchildid = rec.benefitchildid
         AND S.ID = C.BENEFITCHILDID
         AND S.DOCBIRTHCHILDNUMBER = REC.DOCBIRTHCHILDNUMBER
         AND S.DOCBIRTHCHILDSERIAL = REC.DOCBIRTHCHILDSERIAL
         AND H.ID != REC.PAYSID
         AND P.REPYEAR = NYEAR
         AND (TO_DATE(LEFT(H.PAYDATE, 10), 'dd.mm.yyyy') BETWEEN REC.DDATE1 AND REC.DDATE2 OR TO_DATE(RIGHT(H.PAYDATE, 10), 'dd.mm.yyyy') BETWEEN REC.DDATE1 AND REC.DDATE2 OR
             (TO_DATE(LEFT(H.PAYDATE, 10), 'dd.mm.yyyy') >= REC.DDATE1 AND TO_DATE(RIGHT(H.PAYDATE, 10), 'dd.mm.yyyy') <= REC.DDATE2))) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) 
     THEN
       IF (SELECT COUNT(*)
             FROM MULTIPLEPAYMENTS M
       		WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
         	  AND M.BENEFITSTYPENAMEDIRID = OB.TIR
         	  AND M.UID = NUID) > 0 THEN
      	SELECT M.ID
          INTO NPEKA
          FROM MULTIPLEPAYMENTS M
         WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           AND M.BENEFITSTYPENAMEDIRID = OB.TIR
           AND M.UID = NUID;
      ELSE
        INSERT INTO MULTIPLEPAYMENTS (UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) VALUES (NUID, OB.TIR, REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA;
  		FL := 1;
      END IF;
      INSERT INTO MULTIPLEPAYMENTSFOOTER (MULTIPLEPAYMENTSID, REASON, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, UID) VALUES (NPEKA, 1, REC.BENEFITCHILDID, REC.SUBJECTSDIRID, REC.DDATE, REC.SSUM, NUID);
      FL := 1;MPAYS[I]:=REC.PAYSID; I:=I+1;
    END IF;
    IF (SELECT COUNT(*)
          FROM BENEFIT01 B, BENEFITSPACKETS P, BENEFIT01PAYMENT H, CHILD C, BENEFITCHILD S
         WHERE P.ID = B.BENEFITSPACKETSID
           AND H.BENEFIT01ID = B.ID
           AND C.ID = H.CHILD01ID
           AND S.ID = C.BENEFITCHILDID
           AND S.DOCBIRTHCHILDNUMBER = REC.DOCBIRTHCHILDNUMBER
           AND S.DOCBIRTHCHILDSERIAL = REC.DOCBIRTHCHILDSERIAL
           AND H.ID != REC.PAYSID
           AND P.REPYEAR = NYEAR
           AND (TO_DATE(LEFT(H.PAYDATE, 10), 'DD.MM.YYYY') BETWEEN REC.DDATE1 AND REC.DDATE2 
            OR TO_DATE(RIGHT(H.PAYDATE, 10), 'DD.MM.YYYY') BETWEEN REC.DDATE1 AND REC.DDATE2 
            OR (TO_DATE(LEFT(H.PAYDATE, 10), 'DD.MM.YYYY') >= REC.DDATE1 
            AND TO_DATE(RIGHT(H.PAYDATE, 10), 'DD.MM.YYYY') <= REC.DDATE2))) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) 
    THEN
      IF (SELECT COUNT(*)
            FROM MULTIPLEPAYMENTS M
           WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
             AND M.BENEFITSTYPENAMEDIRID = OB.TIR
             AND M.UID = NUID) > 0
      THEN
        SELECT M.ID
          INTO NPEKA
          FROM MULTIPLEPAYMENTS M
         WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           AND M.BENEFITSTYPENAMEDIRID = OB.TIR
           AND M.UID = NUID;
      ELSE
        INSERT INTO MULTIPLEPAYMENTS (UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) VALUES (NUID, OB.TIR, REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA;
        FL := 1;
      END IF;
      IF (SELECT COUNT(*)
            FROM MULTIPLEPAYMENTSFOOTER M
           WHERE M.MULTIPLEPAYMENTSID = NPEKA
             AND M.REASON = '1'
             AND M.BENEFITCHILDID = REC.BENEFITCHILDID
             AND M.SUBJECTSDIRID = DUB.SUBJECTSDIRID
             AND M.PERIODPAY = DUB.DDATE
             AND M.SUMPAY = DUB.SSUM
             AND M.UID = NUID) = 0
      THEN
        INSERT INTO MULTIPLEPAYMENTSFOOTER
          (MULTIPLEPAYMENTSID, REASON, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, UID)
        VALUES
          (NPEKA, 1, REC.BENEFITCHILDID, DUB.SUBJECTSDIRID, DUB.DDATE, DUB.SSUM, NUID);
        FL := 1;MPAYS[I]:=REC.PAYSID; I:=I+1;
      END IF;
    END IF;
  END LOOP;
            
                   
  --ииииииииииииииииииииииииииииииииииииииииииииииииии аХХбва 02 ииииииииииииииииииииииииииииииииииииииииииииииииии                 
    ELSIF OB.RNUMBER = 2 THEN
      I:=1;MPAYS[I]:=0;	       
      FOR REC IN (SELECT B.BENEFITSRECIPIENTSID,
                     H.ID AS PAYSID,
                     P.SUBJECTSDIRID,
                     H.PAYDATE AS DDATE,
                     COALESCE(H.PAYSUM, 0) AS SSUM,
                     P.SUBJECTSDIRID,
                     TO_DATE(LEFT(H.PAYDATE, 10), 'DD.MM.YYYY') AS DDATE1,
                     TO_DATE(RIGHT(H.PAYDATE, 10), 'DD.MM.YYYY') AS DDATE2
                FROM BENEFIT02 B, BENEFITSPACKETS P, BENEFIT02PAYMENT H
               WHERE (B.BENEFITSRECIPIENTSID = BENEF OR ALL_FIELDS_H = 1)
                 AND P.ID = B.BENEFITSPACKETSID
                 AND H.BENEFIT02ID = B.ID
                 AND P.REPYEAR = NYEAR
               GROUP BY B.BENEFITSRECIPIENTSID, H.PAYDATE, H.ID, P.SUBJECTSDIRID)
  LOOP
    IF (SELECT COUNT(*)
          FROM BENEFIT02 B, BENEFITSPACKETS P, BENEFIT02PAYMENT H
         WHERE B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           AND P.ID = B.BENEFITSPACKETSID
           AND H.BENEFIT02ID = B.ID
           AND H.ID != REC.PAYSID
           AND P.REPYEAR = NYEAR
           AND (TO_DATE(LEFT(H.PAYDATE, 10), 'DD.MM.YYYY') BETWEEN REC.DDATE1 AND REC.DDATE2 
             OR TO_DATE(RIGHT(H.PAYDATE, 10), 'DD.MM.YYYY') BETWEEN REC.DDATE1 AND REC.DDATE2 
             OR (TO_DATE(LEFT(H.PAYDATE, 10), 'DD.MM.YYYY') >= REC.DDATE1 
                 AND TO_DATE(RIGHT(H.PAYDATE, 10), 'DD.MM.YYYY') <= REC.DDATE2))) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) 
    THEN
      IF (SELECT COUNT(*) FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
        SELECT M.ID
          INTO NPEKA
          FROM MULTIPLEPAYMENTS M
         WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
           AND M.BENEFITSTYPENAMEDIRID = OB.TIR
           AND M.UID = NUID;
      ELSE
        INSERT INTO MULTIPLEPAYMENTS (UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) 
        VALUES (NUID, OB.TIR, REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA;
        FL := 1;
      END IF;
      INSERT INTO MULTIPLEPAYMENTSFOOTER (MULTIPLEPAYMENTSID, REASON, SUBJECTSDIRID, PERIODPAY, SUMPAY, UID) 
      VALUES (NPEKA, 1, REC.SUBJECTSDIRID, REC.DDATE, REC.SSUM, NUID);
      FL := 1;MPAYS[I]:=REC.PAYSID; I:=I+1;
    END IF;
  END LOOP;
  --ииииииииииииииииииииииииииииииииииииииииииииииииии аХХбва 03 ииииииииииииииииииииииииииииииииииииииииииииииииии   
    ELSIF OB.RNUMBER = 3 THEN 
       I:=1;MPAYS[I]:=0;
       FOR REC IN (
       				SELECT B.BENEFITSRECIPIENTSID, H.ID AS PAYSID, P.SUBJECTSDIRID, H.PAYDATE AS DDATE,
                    		COALESCE(H.PAYSUM,0) AS SSUM,
                           TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') AS DDATE1, TO_DATE(RIGHT(COALESCE(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),H.RETENTIONDATE,H.RETURNDATE,H.EXTRADATE),10),'DD.MM.YYYY') AS DDATE2
        	 		  FROM BENEFIT03 B, BENEFITSPACKETS P, BENEFIT03PAYMENT H
       				 WHERE (B.BENEFITSRECIPIENTSID = BENEF OR ALL_FIELDS_H = 1)
         	   		   AND P.ID = B.BENEFITSPACKETSID
               		   AND H.BENEFIT03ID = B.ID
          	  		   AND P.REPYEAR = NYEAR 
                       GROUP BY B.BENEFITSRECIPIENTSID,H.PAYDATE, H.ID, P.SUBJECTSDIRID
       			   ) 
                   LOOP
                   	  IF (
                      			   SELECT COUNT(*)
        	 		  				 FROM BENEFIT03 B, BENEFITSPACKETS P, BENEFIT03PAYMENT H
       				                WHERE B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
         	   		   				  AND P.ID = B.BENEFITSPACKETSID
               		                  AND H.BENEFIT03ID = B.ID
                                      AND H.ID != REC.PAYSID
          	  		                  AND P.REPYEAR = NYEAR 
                                      AND (TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE1
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE1
                                       OR TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE2
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE2
                                      OR TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE1
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE2)
                      			  ) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
                                  
                                  	IF( SELECT COUNT(*)
                                       FROM MULTIPLEPAYMENTS M
                                      WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
                                      SELECT M.ID INTO NPEKA FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID;
                                    ELSE
                                      INSERT INTO MULTIPLEPAYMENTS(UID,BENEFITSTYPENAMEDIRID,BENEFITSRECIPIENTSID) 
                                            VALUES(NUID,OB.TIR,REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA; FL:=1;
                                    END IF;
                                  	 INSERT INTO MULTIPLEPAYMENTSFOOTER(MULTIPLEPAYMENTSID,REASON,SUBJECTSDIRID,PERIODPAY,SUMPAY,UID)
                                         VALUES(NPEKA,1,REC.SUBJECTSDIRID,TO_CHAR(REC.DDATE,'DD.MM.YYYY'), REC.SSUM,NUID); FL:=1; MPAYS[I]:=REC.PAYSID; I:=I+1;
                                  END IF;
                   END LOOP;
  --ииииииииииииииииииииииииииииииииииииииииииииииииии аХХбва 04 ииииииииииииииииииииииииииииииииииииииииииииииииии                 
    ELSIF OB.RNUMBER = 4 THEN 
       I:=1;MPAYS[I]:=0;  
       FOR REC IN (
       				SELECT B.BENEFITSRECIPIENTSID, C.BENEFITCHILDID, H.ID AS PAYSID, P.SUBJECTSDIRID, H.PAYDATE AS DDATE,
                    		COALESCE(H.PAYSUM,0) AS SSUM, S.DOCBIRTHCHILDNUMBER, S.DOCBIRTHCHILDSERIAL,
                           TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') AS DDATE1, TO_DATE(RIGHT(COALESCE(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),H.RETENTIONDATE,H.RETURNDATE,H.EXTRADATE),10),'DD.MM.YYYY') AS DDATE2
        	 		  FROM BENEFIT04 B, BENEFITSPACKETS P, BENEFIT04PAYMENT H, CHILD04 C, BENEFITCHILD S
       				 WHERE (B.BENEFITSRECIPIENTSID = BENEF OR ALL_FIELDS_H = 1)
         	   		   AND P.ID = B.BENEFITSPACKETSID
               		   AND H.BENEFIT04ID = B.ID
               		   AND C.ID = H.CHILD04ID
               		   AND (C.BENEFITCHILDID = CHILDS OR ALL_FIELDS_C = 1)
          	  		   AND P.REPYEAR = NYEAR
                       AND S.ID = C.BENEFITCHILDID 
                       GROUP BY B.BENEFITSRECIPIENTSID,C.BENEFITCHILDID,H.PAYDATE, H.ID, P.SUBJECTSDIRID,S.DOCBIRTHCHILDNUMBER, S.DOCBIRTHCHILDSERIAL
       			   ) 
                   LOOP
                   	  IF (
                      			   SELECT COUNT(*)
        	 		  				 FROM BENEFIT04 B, BENEFITSPACKETS P, BENEFIT04PAYMENT H, CHILD04 C, BENEFITCHILD S
       				                WHERE B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
         	   		   				  AND P.ID = B.BENEFITSPACKETSID
               		                  AND H.BENEFIT04ID = B.ID
               		                  AND C.ID = H.CHILD04ID
                                      AND S.ID = C.BENEFITCHILDID
                                      AND S.DOCBIRTHCHILDNUMBER = REC.DOCBIRTHCHILDNUMBER
                                      AND S.DOCBIRTHCHILDSERIAL = REC.DOCBIRTHCHILDSERIAL
                                      AND H.ID != REC.PAYSID
          	  		                  AND P.REPYEAR = NYEAR 
                                      AND (TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE1
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE1
                                       OR TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE2
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE2
                                      OR TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE1
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE2)
                      			  ) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
                                  	IF( SELECT COUNT(*)
                                       FROM MULTIPLEPAYMENTS M
                                      WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
                                      SELECT M.ID INTO NPEKA FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID;
                                    ELSE
                                      INSERT INTO MULTIPLEPAYMENTS(UID,BENEFITSTYPENAMEDIRID,BENEFITSRECIPIENTSID) 
                                            VALUES(NUID,OB.TIR,REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA; FL:=1;
                                    END IF;
                                  	 INSERT INTO MULTIPLEPAYMENTSFOOTER(MULTIPLEPAYMENTSID,REASON,BENEFITCHILDID,SUBJECTSDIRID,PERIODPAY,SUMPAY,UID)
                                         VALUES(NPEKA,1,REC.BENEFITCHILDID,REC.SUBJECTSDIRID,TO_CHAR(REC.DDATE,'DD.MM.YYYY'), REC.SSUM,NUID); FL:=1; MPAYS[I]:=REC.PAYSID; I:=I+1;
                                  END IF;
                        IF (
                      			   SELECT COUNT(*)
        	 		  				 FROM BENEFIT04 B, BENEFITSPACKETS P, BENEFIT04PAYMENT H, CHILD04 C, BENEFITCHILD S
       				                WHERE P.ID = B.BENEFITSPACKETSID
               		                  AND H.BENEFIT04ID = B.ID
               		                  AND C.ID = H.CHILD04ID
               		                  --AND C.BENEFITCHILDID = REC.BENEFITCHILDID
                                      AND S.ID = C.BENEFITCHILDID
                                      AND S.DOCBIRTHCHILDNUMBER = REC.DOCBIRTHCHILDNUMBER
                                      AND S.DOCBIRTHCHILDSERIAL = REC.DOCBIRTHCHILDSERIAL
                                      AND H.ID != REC.PAYSID
          	  		                  AND P.REPYEAR = NYEAR 
                                      AND (TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE1
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE1
                                       OR TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE2
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE2
                                      OR TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE1
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE2)
                      			  ) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
                                  	IF( SELECT COUNT(*)
                                       FROM MULTIPLEPAYMENTS M
                                      WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
                                      SELECT M.ID INTO NPEKA FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID;
                                    ELSE
                                      INSERT INTO MULTIPLEPAYMENTS(UID,BENEFITSTYPENAMEDIRID,BENEFITSRECIPIENTSID) 
                                            VALUES(NUID,OB.TIR,REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA; FL:=1;
                                    END IF; 
                                  	 INSERT INTO MULTIPLEPAYMENTSFOOTER(MULTIPLEPAYMENTSID,REASON,BENEFITCHILDID,SUBJECTSDIRID,PERIODPAY,SUMPAY,UID)
                                         VALUES(NPEKA,1,REC.BENEFITCHILDID,REC.SUBJECTSDIRID,TO_CHAR(REC.DDATE,'DD.MM.YYYY'), REC.SSUM,NUID); FL:=1; MPAYS[I]:=REC.PAYSID; I:=I+1;
                                  END IF;
                   END LOOP;
  --ииииииииииииииииииииииииииииииииииииииииииииииииии аХХбва 05 ииииииииииииииииииииииииииииииииииииииииииииииииии                 
    ELSIF OB.RNUMBER = 5 THEN 
       I:=1;MPAYS[I]:=0;
       FOR REC IN (
       				SELECT B.BENEFITSRECIPIENTSID, C.BENEFITCHILDID, H.ID AS PAYSID, P.SUBJECTSDIRID, H.PAYDATE AS DDATE,
                    		COALESCE(H.PAYSUM,0) AS SSUM, S.DOCBIRTHCHILDNUMBER, S.DOCBIRTHCHILDSERIAL,
                           TO_DATE(LEFT(H.PAYDATE,10),'DD.MM.YYYY') AS DDATE1, TO_DATE(RIGHT(H.PAYDATE,10),'DD.MM.YYYY') AS DDATE2
        	 		  FROM BENEFIT05 B, BENEFITSPACKETS P, BENEFIT05PAYMENT H, CHILD05 C, BENEFITCHILD S
       				 WHERE (B.BENEFITSRECIPIENTSID = BENEF OR ALL_FIELDS_H = 1)
         	   		   AND P.ID = B.BENEFITSPACKETSID
               		   AND H.BENEFIT05ID = B.ID
               		   AND C.ID = H.CHILD05ID
               		   AND (C.BENEFITCHILDID = CHILDS OR ALL_FIELDS_C = 1)
          	  		   AND P.REPYEAR = NYEAR 
                       AND S.ID = C.BENEFITCHILDID
                       GROUP BY B.BENEFITSRECIPIENTSID,C.BENEFITCHILDID,H.PAYDATE, H.ID, P.SUBJECTSDIRID,S.DOCBIRTHCHILDNUMBER, S.DOCBIRTHCHILDSERIAL
       			   ) 
                   LOOP
                   	  IF (
                      			   SELECT COUNT(*)
        	 		  				 FROM BENEFIT05 B, BENEFITSPACKETS P, BENEFIT05PAYMENT H, CHILD05 C, BENEFITCHILD S
       				                WHERE B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
         	   		   				  AND P.ID = B.BENEFITSPACKETSID
               		                  AND H.BENEFIT05ID = B.ID
               		                  AND C.ID = H.CHILD05ID
                                      AND S.ID = C.BENEFITCHILDID
                                     AND S.DOCBIRTHCHILDNUMBER = REC.DOCBIRTHCHILDNUMBER
                                     AND S.DOCBIRTHCHILDSERIAL = REC.DOCBIRTHCHILDSERIAL
                                      AND H.ID != REC.PAYSID
          	  		                  AND P.REPYEAR = NYEAR 
                                      AND (TO_DATE(LEFT(H.PAYDATE,10),'DD.MM.YYYY') <= REC.DDATE1
                                      AND TO_DATE(RIGHT(H.PAYDATE,10),'DD.MM.YYYY') >= REC.DDATE1
                                       OR TO_DATE(LEFT(H.PAYDATE,10),'DD.MM.YYYY') <= REC.DDATE2
                                      AND TO_DATE(RIGHT(H.PAYDATE,10),'DD.MM.YYYY') >= REC.DDATE2
                                      OR TO_DATE(LEFT(H.PAYDATE,10),'DD.MM.YYYY') >= REC.DDATE1
                                      AND TO_DATE(RIGHT(H.PAYDATE,10),'DD.MM.YYYY') <= REC.DDATE2)
                      			  ) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
                                  	IF( SELECT COUNT(*)
                                       FROM MULTIPLEPAYMENTS M
                                      WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
                                      SELECT M.ID INTO NPEKA FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID;
                                    ELSE
                                      INSERT INTO MULTIPLEPAYMENTS(UID,BENEFITSTYPENAMEDIRID,BENEFITSRECIPIENTSID) 
                                            VALUES(NUID,OB.TIR,REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA; FL:=1;
                                    END IF;
                                  	IF (SELECT COUNT(*)
                                     	  FROM MULTIPLEPAYMENTSFOOTER M 
                                    	 WHERE M.MULTIPLEPAYMENTSID = NPEKA 
                                    	   AND M.REASON = '1'
                                           AND M.BENEFITCHILDID = REC.BENEFITCHILDID
                                           AND M.SUBJECTSDIRID = DUB.SUBJECTSDIRID
                                           AND M.PERIODPAY = DUB.DDATE
                                           AND M.SUMPAY = DUB.SSUM AND M.UID = NUID) = 0 THEN 
                                  	 INSERT INTO MULTIPLEPAYMENTSFOOTER(MULTIPLEPAYMENTSID,REASON,BENEFITCHILDID,SUBJECTSDIRID,PERIODPAY,SUMPAY,UID)
                                         VALUES(NPEKA,1,REC.BENEFITCHILDID,REC.SUBJECTSDIRID,REC.DDATE, REC.SSUM,NUID); FL:=1; MPAYS[I]:=REC.PAYSID; I:=I+1;
                                    END IF;
                                  END IF;
                        IF (
                      			   SELECT COUNT(*)
        	 		  				 FROM BENEFIT05 B, BENEFITSPACKETS P, BENEFIT05PAYMENT H, CHILD05 C, BENEFITCHILD S
       				                WHERE P.ID = B.BENEFITSPACKETSID
               		                  AND H.BENEFIT05ID = B.ID
               		                  AND C.ID = H.CHILD05ID
                                      AND S.ID = C.BENEFITCHILDID
                                     AND S.DOCBIRTHCHILDNUMBER = REC.DOCBIRTHCHILDNUMBER
                                     AND S.DOCBIRTHCHILDSERIAL = REC.DOCBIRTHCHILDSERIAL
                                      AND H.ID != REC.PAYSID
          	  		                  AND P.REPYEAR = NYEAR 
                                      AND (TO_DATE(LEFT(H.PAYDATE,10),'DD.MM.YYYY') <= REC.DDATE1
                                      AND TO_DATE(RIGHT(H.PAYDATE,10),'DD.MM.YYYY') >= REC.DDATE1
                                       OR TO_DATE(LEFT(H.PAYDATE,10),'DD.MM.YYYY') <= REC.DDATE2
                                      AND TO_DATE(RIGHT(H.PAYDATE,10),'DD.MM.YYYY') >= REC.DDATE2
                                      OR TO_DATE(LEFT(H.PAYDATE,10),'DD.MM.YYYY') >= REC.DDATE1
                                      AND TO_DATE(RIGHT(H.PAYDATE,10),'DD.MM.YYYY') <= REC.DDATE2)
                      			  ) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
                                  	IF( SELECT COUNT(*)
                                       FROM MULTIPLEPAYMENTS M
                                      WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
                                      SELECT M.ID INTO NPEKA FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID;
                                    ELSE
                                      INSERT INTO MULTIPLEPAYMENTS(UID,BENEFITSTYPENAMEDIRID,BENEFITSRECIPIENTSID) 
                                            VALUES(NUID,OB.TIR,REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA; FL:=1;
                                    END IF; 
                                  	 INSERT INTO MULTIPLEPAYMENTSFOOTER(MULTIPLEPAYMENTSID,REASON,BENEFITCHILDID,SUBJECTSDIRID,PERIODPAY,SUMPAY, UID)
                                         VALUES(NPEKA,1,REC.BENEFITCHILDID,REC.SUBJECTSDIRID,REC.DDATE, REC.SSUM,NUID); FL:=1; MPAYS[I]:=REC.PAYSID; I:=I+1;
                                END IF;
                   END LOOP;    
  --ииииииииииииииииииииииииииииииииииииииииииииииииии аХХбва 06 ииииииииииииииииииииииииииииииииииииииииииииииииии  
    ELSIF OB.RNUMBER = 6 THEN 
   	   I:=1;MPAYS[I]:=0;
       FOR REC IN (
       				SELECT B.BENEFITSRECIPIENTSID, H.ID AS PAYSID, P.SUBJECTSDIRID, H.PAYDATE AS DDATE,
                    		COALESCE(H.PAYSUM,0) AS SSUM,
                           TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') AS DDATE1, TO_DATE(RIGHT(COALESCE(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),H.RETENTIONDATE,H.RETURNDATE,H.EXTRADATE),10),'DD.MM.YYYY') AS DDATE2
        	 		  FROM BENEFIT06 B, BENEFITSPACKETS P, BENEFIT06PAYMENT H
       				 WHERE (B.BENEFITSRECIPIENTSID = BENEF OR ALL_FIELDS_H = 1)
         	   		   AND P.ID = B.BENEFITSPACKETSID
               		   AND H.BENEFIT06ID = B.ID
          	  		   AND P.REPYEAR = NYEAR 
                       GROUP BY B.BENEFITSRECIPIENTSID,H.PAYDATE, H.ID, P.SUBJECTSDIRID
       			   ) 
                   LOOP
                   	  IF (
                      			   SELECT COUNT(*)
        	 		  				 FROM BENEFIT06 B, BENEFITSPACKETS P, BENEFIT06PAYMENT H
       				                WHERE B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
         	   		   				  AND P.ID = B.BENEFITSPACKETSID
               		                  AND H.BENEFIT06ID = B.ID
                                      AND H.ID != REC.PAYSID
          	  		                  AND P.REPYEAR = NYEAR 
                                      AND (TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE1
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE1
                                       OR TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE2
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE2
                                      OR TO_DATE(LEFT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') >= REC.DDATE1
                                      AND TO_DATE(RIGHT(TO_CHAR(H.PAYDATE,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATE,'DD.MM.YYYY'),10),'DD.MM.YYYY') <= REC.DDATE2)
                      			  ) > 0 AND REC.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
                                  	IF( SELECT COUNT(*)
                                       FROM MULTIPLEPAYMENTS M
                                      WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
                                      SELECT M.ID INTO NPEKA FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID;
                                    ELSE
                                      INSERT INTO MULTIPLEPAYMENTS(UID,BENEFITSTYPENAMEDIRID,BENEFITSRECIPIENTSID) 
                                            VALUES(NUID,OB.TIR,REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA; FL:=1;
                                    END IF;
                                  	 INSERT INTO MULTIPLEPAYMENTSFOOTER(MULTIPLEPAYMENTSID,REASON,SUBJECTSDIRID,PERIODPAY,SUMPAY,UID)
                                         VALUES(NPEKA,1,REC.SUBJECTSDIRID,TO_CHAR(REC.DDATE,'DD.MM.YYYY'), REC.SSUM,NUID); FL:=1; MPAYS[I]:=REC.PAYSID; I:=I+1;
                                  END IF;
                   END LOOP;
    --ииииииииииииииииииииииииииииииииииииииииииииииииии аХХбва 07 ииииииииииииииииииииииииииииииииииииииииииииииииии               
    ELSIF OB.RNUMBER = 7 THEN 
   	   I:=1;MPAYS[I]:=0;
       FOR REC IN (
       				SELECT B.BENEFITSRECIPIENTSID, C.BENEFITCHILDID, H.ID AS PAYSID, P.SUBJECTSDIRID, COALESCE(TO_CHAR(H.PAYDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATETO,'DD.MM.YYYY'),TO_CHAR(H.SURCHARGEDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.SURCHARGEDATETO,'DD.MM.YYYY'),TO_CHAR(H.REFUNDDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.REFUNDDATETO,'DD.MM.YYYY'),TO_CHAR(H.HOLDDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.HOLDDATETO,'DD.MM.YYYY')) AS DDATE,
                    		COALESCE(H.PAYSUM,0) AS SSUM,
                           COALESCE(H.PAYDATEFROM,H.SURCHARGEDATEFROM,H.REFUNDDATEFROM,H.HOLDDATEFROM) AS DDATE1, COALESCE(H.PAYDATETO,H.SURCHARGEDATETO,H.REFUNDDATETO,H.HOLDDATETO) AS DDATE2
        	 		  FROM BENEFIT07 B, BENEFITSPACKETS P, BENEFIT07PAYMENT H, CHILD07 C
       				 WHERE (B.BENEFITSRECIPIENTSID = BENEF OR ALL_FIELDS_H = 1)
         	   		   AND P.ID = B.BENEFITSPACKETSID
               		   AND H.BENEFIT07ID = B.ID
               		   AND C.ID = H.CHILD07ID
               		   AND (C.BENEFITCHILDID = CHILDS OR ALL_FIELDS_C = 1)
          	  		   AND P.REPYEAR = NYEAR 
                       GROUP BY B.BENEFITSRECIPIENTSID,C.BENEFITCHILDID,COALESCE(TO_CHAR(H.PAYDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATETO,'DD.MM.YYYY'),TO_CHAR(H.SURCHARGEDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.SURCHARGEDATETO,'DD.MM.YYYY'),TO_CHAR(H.REFUNDDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.REFUNDDATETO,'DD.MM.YYYY'),TO_CHAR(H.HOLDDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.HOLDDATETO,'DD.MM.YYYY')), H.ID, P.SUBJECTSDIRID
       			   ) 
                   LOOP
                   	  FOR DUB IN (
                      			   SELECT B.BENEFITSRECIPIENTSID, COALESCE(TO_CHAR(H.PAYDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATETO,'DD.MM.YYYY'),TO_CHAR(H.SURCHARGEDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.SURCHARGEDATETO,'DD.MM.YYYY'),TO_CHAR(H.REFUNDDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.REFUNDDATETO,'DD.MM.YYYY'),TO_CHAR(H.HOLDDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.HOLDDATETO,'DD.MM.YYYY')) AS DDATE,
                                   		  COALESCE(H.PAYSUM,0) AS SSUM, P.SUBJECTSDIRID
        	 		  				 FROM BENEFIT07 B, BENEFITSPACKETS P, BENEFIT07PAYMENT H, CHILD07 C
       				                WHERE B.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID
         	   		   				  AND P.ID = B.BENEFITSPACKETSID
               		                  AND H.BENEFIT07ID = B.ID
               		                  AND C.ID = H.CHILD07ID
               		                  AND C.BENEFITCHILDID = REC.BENEFITCHILDID
                                      AND H.ID != REC.PAYSID
          	  		                  AND P.REPYEAR = NYEAR 
                                      AND (COALESCE(H.PAYDATEFROM,H.SURCHARGEDATEFROM,H.REFUNDDATEFROM,H.HOLDDATEFROM) <= REC.DDATE1
                                      AND COALESCE(H.PAYDATETO,H.SURCHARGEDATETO,H.REFUNDDATETO,H.HOLDDATETO) >= REC.DDATE1
                                       OR COALESCE(H.PAYDATEFROM,H.SURCHARGEDATEFROM,H.REFUNDDATEFROM,H.HOLDDATEFROM) <= REC.DDATE2
                                      AND COALESCE(H.PAYDATETO,H.SURCHARGEDATETO,H.REFUNDDATETO,H.HOLDDATETO) >= REC.DDATE2)
                      			  ) 
                                  LOOP
                                  	IF( SELECT COUNT(*)
                                       FROM MULTIPLEPAYMENTS M
                                      WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
                                      SELECT M.ID INTO NPEKA FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID;
                                    ELSE
                                      INSERT INTO MULTIPLEPAYMENTS(UID,BENEFITSTYPENAMEDIRID,BENEFITSRECIPIENTSID) 
                                            VALUES(NUID,OB.TIR,REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA; FL:=1;
                                    END IF;
                                  	IF (SELECT COUNT(*)
                                     	  FROM MULTIPLEPAYMENTSFOOTER M 
                                    	 WHERE M.MULTIPLEPAYMENTSID = NPEKA 
                                    	   AND M.REASON = '1'
                                           AND M.BENEFITCHILDID = REC.BENEFITCHILDID
                                           AND M.SUBJECTSDIRID = DUB.SUBJECTSDIRID
                                           AND M.PERIODPAY = DUB.DDATE
                                           AND M.SUMPAY = DUB.SSUM AND M.UID = NUID) = 0 THEN 
                                  	 INSERT INTO MULTIPLEPAYMENTSFOOTER(MULTIPLEPAYMENTSID,REASON,BENEFITCHILDID,SUBJECTSDIRID,PERIODPAY,SUMPAY,UID)
                                         VALUES(NPEKA,1,REC.BENEFITCHILDID,DUB.SUBJECTSDIRID,DUB.DDATE, DUB.SSUM,NUID); FL:=1; MPAYS[I]:=REC.PAYSID; I:=I+1;
                                    END IF;
                                  END LOOP;
                      FOR DUB IN (
                      			   SELECT B.BENEFITSRECIPIENTSID, COALESCE(TO_CHAR(H.PAYDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.PAYDATETO,'DD.MM.YYYY'),TO_CHAR(H.SURCHARGEDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.SURCHARGEDATETO,'DD.MM.YYYY'),TO_CHAR(H.REFUNDDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.REFUNDDATETO,'DD.MM.YYYY'),TO_CHAR(H.HOLDDATEFROM,'DD.MM.YYYY')||'-'||TO_CHAR(H.HOLDDATETO,'DD.MM.YYYY')) AS DDATE,
                                   		  COALESCE(H.PAYSUM,0) AS SSUM, P.SUBJECTSDIRID
        	 		  				 FROM BENEFIT07 B, BENEFITSPACKETS P, BENEFIT07PAYMENT H, CHILD07 C
       				                WHERE P.ID = B.BENEFITSPACKETSID
               		                  AND H.BENEFIT07ID = B.ID
               		                  AND C.ID = H.CHILD07ID
               		                  AND C.BENEFITCHILDID = REC.BENEFITCHILDID
                                      AND H.ID != REC.PAYSID
          	  		                  AND P.REPYEAR = NYEAR 
                                      AND (COALESCE(H.PAYDATEFROM,H.SURCHARGEDATEFROM,H.REFUNDDATEFROM,H.HOLDDATEFROM) <= REC.DDATE1
                                      AND COALESCE(H.PAYDATETO,H.SURCHARGEDATETO,H.REFUNDDATETO,H.HOLDDATETO) >= REC.DDATE1
                                       OR COALESCE(H.PAYDATEFROM,H.SURCHARGEDATEFROM,H.REFUNDDATEFROM,H.HOLDDATEFROM) <= REC.DDATE2
                                      AND COALESCE(H.PAYDATETO,H.SURCHARGEDATETO,H.REFUNDDATETO,H.HOLDDATETO) >= REC.DDATE2)
                      			  ) 
                                  LOOP
                                  	IF( SELECT COUNT(*)
                                       FROM MULTIPLEPAYMENTS M
                                      WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID) > 0 THEN
                                      SELECT M.ID INTO NPEKA FROM MULTIPLEPAYMENTS M WHERE M.BENEFITSRECIPIENTSID = REC.BENEFITSRECIPIENTSID AND M.BENEFITSTYPENAMEDIRID = OB.TIR AND M.UID = NUID;
                                    ELSE
                                      INSERT INTO MULTIPLEPAYMENTS(UID,BENEFITSTYPENAMEDIRID,BENEFITSRECIPIENTSID) 
                                            VALUES(NUID,OB.TIR,REC.BENEFITSRECIPIENTSID) RETURNING MULTIPLEPAYMENTS.ID INTO NPEKA; FL:=1;
                                    END IF;
                                  	IF (SELECT COUNT(*)
                                     	  FROM MULTIPLEPAYMENTSFOOTER M 
                                    	 WHERE M.MULTIPLEPAYMENTSID = NPEKA 
                                    	   AND M.REASON = '1'
                                           AND M.BENEFITCHILDID = REC.BENEFITCHILDID
                                           AND M.SUBJECTSDIRID = DUB.SUBJECTSDIRID
                                           AND M.PERIODPAY = DUB.DDATE
                                           AND M.SUMPAY = DUB.SSUM AND M.UID = NUID) = 0 THEN 
                                  	 INSERT INTO MULTIPLEPAYMENTSFOOTER(MULTIPLEPAYMENTSID,REASON,BENEFITCHILDID,SUBJECTSDIRID,PERIODPAY,SUMPAY, UID)
                                         VALUES(NPEKA,1,REC.BENEFITCHILDID,DUB.SUBJECTSDIRID,DUB.DDATE, DUB.SSUM, NUID); FL:=1; MPAYS[I]:=REC.PAYSID; I:=I+1;
                                    END IF;
                                  END LOOP;
                   END LOOP;
    
    END IF;
    END LOOP; 
    if fl = 0 then raise using message = 'Яю чрфрээћь ъ№шђх№шџь фѓсыш№ютрэшџ тћяырђ эх юсэр№ѓцхэю'; end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_multiplepayments_gen (benefitstypenamedirid bigint [], repyear integer, lastnameb text, firstnameb text, patronymicb text, persondocumenttypeid bigint, docseriesb text, docnumberb text, lastnamec text, firstnamec text, patronymicc text, docbirthchildtypeid bigint, docseriesc text, docnumberc text, birthdatec date, uid bigint)
  OWNER TO magicbox;