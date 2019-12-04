CREATE OR REPLACE FUNCTION public.p_action_unlawfulsurcharge_gen (
  uid bigint,
  benefitstypenamedirid bigint [],
  repyear bigint,
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
  hid bigint = NULL::bigint
)
RETURNS text AS
$body$
declare
    EX  				   record;
    PAY 				   record;
    NPAY 				   integer:= 0;
	NUID                   BIGINT := UID;
	NLID                   BIGINT := 1;
	NHID                   BIGINT := HID;
	NREPYEAR               BIGINT := REPYEAR;
    NUNLAWFULSURCHARGE	   BIGINT;
	ABENEFITSTYPENAMEDIRID BIGINT [] := P_ACTION_UNLAWFULSURCHARGE_GEN.BENEFITSTYPENAMEDIRID;
    NPERSONDOCUMENTTYPEID  BIGINT := P_ACTION_UNLAWFULSURCHARGE_GEN.PERSONDOCUMENTTYPEID;
    NDOCBIRTHCHILDTYPEID   BIGINT := P_ACTION_UNLAWFULSURCHARGE_GEN.DOCBIRTHCHILDTYPEID;
    BEXTRA				   BOOLEAN;
    --Сделаем массив для хранения выплат
    MPAYS				   INTEGER[];
    I					   INTEGER;
begin
	--RAISE using message = persondocumenttypeid;
	/*всегда очистка перед заполнением*/
	delete from UNLAWFULSURCHARGE U
	 where U.LID = NLID
		 and U.UID = NUID;
    --ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ РЕЕСТР 01 ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ
	/*доплаты*/
    I:=1;MPAYS[I]:=0;
	for EX in (select BTD.BENEFITSTYPENAMEDIRID,
	                  B01.BENEFITSRECIPIENTSID,
					  BC.ID as BENEFITCHILD,
					  BP.SUBJECTSDIRID,
                      B01P.PAYDATE,
                      B01P.PAYSUM,
					  B01P.EXTRADATE,
					  B01P.EXTRASUM,
                      B01P.ID AS PAYSID
	             from BENEFIT01              B01,
                      BENEFITSRECIPIENTS     BR,
					  BENEFITSPACKETS        BP,
					  BENEFICIARIESREGISTERS BTD,
					  BENEFIT01PAYMENT       B01P,
					  CHILD                  B01C,
					  BENEFITCHILD           BC
				where B01.BENEFITSRECIPIENTSID = BR.ID
				  and B01.BENEFITSPACKETSID = BP.ID
				  and BP.REPYEAR = NREPYEAR
				  and B01.BENEFITSTYPEDIRID = BTD.ID
				  and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				  and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				  and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				  and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				  and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				  and B01P.BENEFIT01ID = B01.ID
				  and COALESCE(B01P.EXTRASUM, 0) <> 0 -- сумма доплаты
				  and B01P.CHILD01ID = B01C.ID
				  and B01C.BENEFITCHILDID = BC.ID
				  and (NDOCBIRTHCHILDTYPEID is null or BC.DOCBIRTHCHILDTYPEID = NDOCBIRTHCHILDTYPEID)
				  and (LASTNAMEC is null or LOWER(BC.LASTNAME) like '%' || LOWER(LASTNAMEC) || '%')
				  and (FIRSTNAMEC is null or LOWER(BC.FIRSTNAME) like '%' || LOWER(FIRSTNAMEC) || '%')
				  and (PATRONYMICC is null or LOWER(BC.PATRONYMIC) like '%' || LOWER(PATRONYMICC) || '%'))
	loop
		/*выплаты для доплат*/
		BEXTRA := true;
		for PAY in (select BTD.BENEFITSTYPENAMEDIRID,
						   B01.BENEFITSRECIPIENTSID,
						   BC.ID as BENEFITCHILD,
						   BP.SUBJECTSDIRID,
                           B01P.EXTRADATE,
					  	   B01P.EXTRASUM,
						   B01P.PAYDATE,
						   B01P.PAYSUM,
                           B01P.ID AS PAYSID
		              from BENEFIT01              B01,
						   BENEFITSRECIPIENTS     BR,
						   BENEFITSPACKETS        BP,
						   BENEFICIARIESREGISTERS BTD,
						   BENEFIT01PAYMENT       B01P,
						   CHILD                  B01C,
						   BENEFITCHILD           BC
					 where B01.BENEFITSRECIPIENTSID = BR.ID
					   and B01.BENEFITSPACKETSID = BP.ID
					   and BP.REPYEAR = NREPYEAR
					   and B01.BENEFITSTYPEDIRID = BTD.ID
					   and BTD.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					   and B01P.BENEFIT01ID = B01.ID
					   and B01P.CHILD01ID = B01C.ID
					   and B01C.BENEFITCHILDID = BC.ID
					   and BC.ID = EX.BENEFITCHILD
					   -- пересечение периодов доплаты и выплаты
					   and TO_DATE(left(EX.EXTRADATE, 10), 'dd.mm.yyyy') <= TO_DATE(right(B01P.PAYDATE, 10), 'dd.mm.yyyy')
					   and TO_DATE(right(EX.EXTRADATE, 10), 'dd.mm.yyyy') >= TO_DATE(left(B01P.PAYDATE, 10), 'dd.mm.yyyy'))
		loop
            NPAY   := NPAY + 1;
			-- доплата
			-- определение заголовка
			if BEXTRA
			then
				select UP.ID
					into NUNLAWFULSURCHARGE
					from UNLAWFULSURCHARGE UP
				 where UP.LID = NLID
					 and UP.UID = NUID
					 and UP.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					 and UP.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID;
				if NUNLAWFULSURCHARGE is null
				then
					insert into UNLAWFULSURCHARGE
						(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
					values
						(NLID, NUID, EX.BENEFITSTYPENAMEDIRID, EX.BENEFITSRECIPIENTSID)
					returning ID into NUNLAWFULSURCHARGE;
				end if;
                IF EX.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN 
				insert into UNLAWFULSURCHARGEFOOTER
					(LID, UID, UNLAWFULSURCHARGEID, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
				values
				--	(NLID, NUID, NUNLAWFULSURCHARGE, EX.BENEFITCHILD, EX.SUBJECTSDIRID, null, null, EX.EXTRADATE, EX.EXTRASUM);
                 (NLID, NUID, NUNLAWFULSURCHARGE,EX.BENEFITCHILD, EX.SUBJECTSDIRID, EX.PAYDATE, EX.PAYSUM, EX.EXTRADATE, EX.EXTRASUM); MPAYS[I]:=EX.PAYSID; I:=I+1;
				END IF;
                BEXTRA := false;
            end if;

            -- выплата
            -- определение заголовка
            NUNLAWFULSURCHARGE := null;
            select UP.ID
			  into NUNLAWFULSURCHARGE
			  from UNLAWFULSURCHARGE UP
			 where UP.LID = NLID
			   and UP.UID = NUID
			   and UP.BENEFITSTYPENAMEDIRID = PAY.BENEFITSTYPENAMEDIRID
			   and UP.BENEFITSRECIPIENTSID = PAY.BENEFITSRECIPIENTSID;
			if NUNLAWFULSURCHARGE is null
			then
			  insert into UNLAWFULSURCHARGE
				(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
			  values
				(NLID, NUID, PAY.BENEFITSTYPENAMEDIRID, PAY.BENEFITSRECIPIENTSID)
			  returning ID into NUNLAWFULSURCHARGE;
			end if;
            IF PAY.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
			insert into UNLAWFULSURCHARGEFOOTER
			  (LID, UID, UNLAWFULSURCHARGEID, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
			values
			 -- (NLID, NUID, NUNLAWFULSURCHARGE, PAY.BENEFITCHILD, PAY.SUBJECTSDIRID, PAY.PAYDATE, PAY.PAYSUM, null, null);
             (NLID, NUID, NUNLAWFULSURCHARGE, PAY.BENEFITCHILD, PAY.SUBJECTSDIRID, PAY.PAYDATE, PAY.PAYSUM, PAY.EXTRADATE, PAY.EXTRASUM); MPAYS[I]:=PAY.PAYSID; I:=I+1;
			END IF;
        end loop;
	end loop;
--RAISE USING MESSAGE = MPAYS;
    --ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ РЕЕСТР 02 ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ
	/*доплаты*/
	for EX in (select BTD.BENEFITSTYPENAMEDIRID,
	                  B02.BENEFITSRECIPIENTSID,
					  BP.SUBJECTSDIRID,
					  B02P.EXTRADATE,
					  B02P.EXTRASUM,
                      B02P.PAYDATE,
					  B02P.PAYSUM
	             from BENEFIT02              B02,
                      BENEFITSRECIPIENTS     BR,
					  BENEFITSPACKETS        BP,
					  BENEFICIARIESREGISTERS BTD,
					  BENEFIT02PAYMENT       B02P
				where B02.BENEFITSRECIPIENTSID = BR.ID
				  and B02.BENEFITSPACKETSID = BP.ID
				  and BP.REPYEAR = NREPYEAR
				  and B02.BENEFITSTYPEDIRID = BTD.ID
				  and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				  and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				  and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				  and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				  and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				  and COALESCE(B02P.EXTRASUM, 0) <> 0 -- сумма доплаты
				  and B02P.BENEFIT02ID = B02.ID)
	loop
		/*выплаты для доплат*/
		BEXTRA := true;
		for PAY in (select BTD.BENEFITSTYPENAMEDIRID,
	                  	   B02.BENEFITSRECIPIENTSID,
					  	   BP.SUBJECTSDIRID,
					  	   B02P.PAYDATE,
					       B02P.PAYSUM,
                           B02P.EXTRADATE,
					  	   B02P.EXTRASUM
	                  from BENEFIT02              B02,
                           BENEFITSRECIPIENTS     BR,
					       BENEFITSPACKETS        BP,
					       BENEFICIARIESREGISTERS BTD,
					       BENEFIT02PAYMENT       B02P
				     where B02.BENEFITSRECIPIENTSID = BR.ID
				       and B02.BENEFITSPACKETSID = BP.ID
				       and BP.REPYEAR = NREPYEAR
				       and B02.BENEFITSTYPEDIRID = BTD.ID
				       and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				       and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				       and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				       and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				       and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				       and COALESCE(B02P.EXTRASUM, 0) <> 0 -- сумма доплаты
				       and B02P.BENEFIT02ID = B02.ID


                       and B02.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID
					   -- пересечение периодов доплаты и выплаты
					   and TO_DATE(left(EX.EXTRADATE, 10), 'dd.mm.yyyy') <= TO_DATE(right(B02P.PAYDATE, 10), 'dd.mm.yyyy')
					   and TO_DATE(right(EX.EXTRADATE, 10), 'dd.mm.yyyy') >= TO_DATE(left(B02P.PAYDATE, 10), 'dd.mm.yyyy'))
		loop
            NPAY   := NPAY + 1;
			-- доплата
			-- определение заголовка
			if BEXTRA
			then
				select UP.ID
					into NUNLAWFULSURCHARGE
					from UNLAWFULSURCHARGE UP
				 where UP.LID = NLID
					 and UP.UID = NUID
					 and UP.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					 and UP.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID;
				if NUNLAWFULSURCHARGE is null
				then
					insert into UNLAWFULSURCHARGE
						(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
					values
						(NLID, NUID, EX.BENEFITSTYPENAMEDIRID, EX.BENEFITSRECIPIENTSID)
					returning ID into NUNLAWFULSURCHARGE;
				end if;
                IF EX.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
				insert into UNLAWFULSURCHARGEFOOTER
					(LID, UID, UNLAWFULSURCHARGEID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
				values
					--(NLID, NUID, NUNLAWFULSURCHARGE, EX.SUBJECTSDIRID, null, null, EX.EXTRADATE, EX.EXTRASUM);
                    (NLID, NUID, NUNLAWFULSURCHARGE, EX.SUBJECTSDIRID, EX.PAYDATE, EX.PAYSUM, EX.EXTRADATE, EX.EXTRASUM);MPAYS[I]:=EX.PAYSID; I:=I+1;
				END IF;
                BEXTRA := false;
			end if;

            -- выплата
            -- определение заголовка
            NUNLAWFULSURCHARGE := null;
            select UP.ID
			  into NUNLAWFULSURCHARGE
			  from UNLAWFULSURCHARGE UP
			 where UP.LID = NLID
			   and UP.UID = NUID
			   and UP.BENEFITSTYPENAMEDIRID = PAY.BENEFITSTYPENAMEDIRID
			   and UP.BENEFITSRECIPIENTSID = PAY.BENEFITSRECIPIENTSID;
			if NUNLAWFULSURCHARGE is null
			then
			  insert into UNLAWFULSURCHARGE
				(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
			  values
				(NLID, NUID, PAY.BENEFITSTYPENAMEDIRID, PAY.BENEFITSRECIPIENTSID)
			  returning ID into NUNLAWFULSURCHARGE;
			end if;
            IF PAY.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
			insert into UNLAWFULSURCHARGEFOOTER
			  (LID, UID, UNLAWFULSURCHARGEID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
			values
			 -- (NLID, NUID, NUNLAWFULSURCHARGE, PAY.SUBJECTSDIRID, PAY.PAYDATE, PAY.PAYSUM, null, null);
             (NLID, NUID, NUNLAWFULSURCHARGE, PAY.SUBJECTSDIRID, PAY.PAYDATE, PAY.PAYSUM, PAY.EXTRADATE, PAY.EXTRASUM);MPAYS[I]:=PAY.PAYSID; I:=I+1;
            END IF;
		end loop;
	end loop;

    --ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ РЕЕСТР 03 ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ
	/*доплаты*/
	for EX in (select BTD.BENEFITSTYPENAMEDIRID,
	                  B03.BENEFITSRECIPIENTSID,
					  BP.SUBJECTSDIRID,
					  B03P.EXTRADATE,
					  B03P.EXTRASUM,
                      B03P.PAYDATE,
					  B03P.PAYSUM
	             from BENEFIT03              B03,
                      BENEFITSRECIPIENTS     BR,
					  BENEFITSPACKETS        BP,
					  BENEFICIARIESREGISTERS BTD,
					  BENEFIT03PAYMENT       B03P
				where B03.BENEFITSRECIPIENTSID = BR.ID
				  and B03.BENEFITSPACKETSID = BP.ID
				  and BP.REPYEAR = NREPYEAR
				  and B03.BENEFITSTYPEDIRID = BTD.ID
				  and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				  and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				  and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				  and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				  and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				  and COALESCE(B03P.EXTRASUM, 0) <> 0 -- сумма доплаты
				  and B03P.BENEFIT03ID = B03.ID)
	loop
		/*выплаты для доплат*/
		BEXTRA := true;
		for PAY in (select BTD.BENEFITSTYPENAMEDIRID,
	                       B03.BENEFITSRECIPIENTSID,
					  	   BP.SUBJECTSDIRID,
					  	   B03P.PAYDATE,
					  	   B03P.PAYSUM,
                           B03P.EXTRADATE,
					  	   B03P.EXTRASUM
	                  from BENEFIT03              B03,
                           BENEFITSRECIPIENTS     BR,
					  	   BENEFITSPACKETS        BP,
					  	   BENEFICIARIESREGISTERS BTD,
					  	   BENEFIT03PAYMENT       B03P
				     where B03.BENEFITSRECIPIENTSID = BR.ID
				  	   and B03.BENEFITSPACKETSID = BP.ID
				  	   and BP.REPYEAR = NREPYEAR
				  	   and B03.BENEFITSTYPEDIRID = BTD.ID
				  	   and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				  	   and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				       and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				       and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				       and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				       and COALESCE(B03P.EXTRASUM, 0) <> 0 -- сумма доплаты
				       and B03P.BENEFIT03ID = B03.ID

                       and B03.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID
					   -- пересечение периодов доплаты и выплаты
					   and B03P.PAYDATE between TO_DATE(left(EX.EXTRADATE, 10), 'dd.mm.yyyy') and TO_DATE(right(EX.EXTRADATE, 10), 'dd.mm.yyyy'))
		loop
            NPAY   := NPAY + 1;
			-- доплата
			-- определение заголовка
			if BEXTRA
			then
				select UP.ID
					into NUNLAWFULSURCHARGE
					from UNLAWFULSURCHARGE UP
				 where UP.LID = NLID
					 and UP.UID = NUID
					 and UP.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					 and UP.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID;
				if NUNLAWFULSURCHARGE is null
				then
					insert into UNLAWFULSURCHARGE
						(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
					values
						(NLID, NUID, EX.BENEFITSTYPENAMEDIRID, EX.BENEFITSRECIPIENTSID)
					returning ID into NUNLAWFULSURCHARGE;
				end if;
                IF EX.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
				insert into UNLAWFULSURCHARGEFOOTER
					(LID, UID, UNLAWFULSURCHARGEID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
				values
					(NLID, NUID, NUNLAWFULSURCHARGE, EX.SUBJECTSDIRID, EX.PAYDATE, EX.PAYSUM, EX.EXTRADATE, EX.EXTRASUM);MPAYS[I]:=EX.PAYSID; I:=I+1;
				END IF;
                BEXTRA := false;
			end if;

            -- выплата
            -- определение заголовка
            NUNLAWFULSURCHARGE := null;
            select UP.ID
			  into NUNLAWFULSURCHARGE
			  from UNLAWFULSURCHARGE UP
			 where UP.LID = NLID
			   and UP.UID = NUID
			   and UP.BENEFITSTYPENAMEDIRID = PAY.BENEFITSTYPENAMEDIRID
			   and UP.BENEFITSRECIPIENTSID = PAY.BENEFITSRECIPIENTSID;
			if NUNLAWFULSURCHARGE is null
			then
			  insert into UNLAWFULSURCHARGE
				(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
			  values
				(NLID, NUID, PAY.BENEFITSTYPENAMEDIRID, PAY.BENEFITSRECIPIENTSID)
			  returning ID into NUNLAWFULSURCHARGE;
			end if;
            IF PAY.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
			insert into UNLAWFULSURCHARGEFOOTER
			  (LID, UID, UNLAWFULSURCHARGEID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
			values
			  (NLID, NUID, NUNLAWFULSURCHARGE, PAY.SUBJECTSDIRID, PAY.PAYDATE, PAY.PAYSUM, PAY.EXTRADATE, PAY.EXTRASUM);MPAYS[I]:=PAY.PAYSID; I:=I+1;
            END IF;
		end loop;
	end loop;

    --ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ РЕЕСТР 04 ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ
	/*доплаты*/
	for EX in (select BTD.BENEFITSTYPENAMEDIRID,
	                  B04.BENEFITSRECIPIENTSID,
					  BC.ID as BENEFITCHILD,
					  BP.SUBJECTSDIRID,
					  B04P.EXTRADATE,
					  B04P.EXTRASUM,
                      B04P.PAYDATE,
					  B04P.PAYSUM
	             from BENEFIT04              B04,
                      BENEFITSRECIPIENTS     BR,
					  BENEFITSPACKETS        BP,
					  BENEFICIARIESREGISTERS BTD,
					  BENEFIT04PAYMENT       B04P,
					  CHILD04                B04C,
					  BENEFITCHILD           BC
				where B04.BENEFITSRECIPIENTSID = BR.ID
				  and B04.BENEFITSPACKETSID = BP.ID
				  and BP.REPYEAR = NREPYEAR
				  and B04.BENEFITSTYPEDIRID = BTD.ID
				  and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				  and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				  and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				  and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				  and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				  and B04P.BENEFIT04ID = B04.ID
				  and COALESCE(B04P.EXTRASUM, 0) <> 0 -- сумма доплаты
				  and B04P.CHILD04ID = B04C.ID
				  and B04C.BENEFITCHILDID = BC.ID
				  and (NDOCBIRTHCHILDTYPEID is null or BC.DOCBIRTHCHILDTYPEID = NDOCBIRTHCHILDTYPEID)
				  and (LASTNAMEC is null or LOWER(BC.LASTNAME) like '%' || LOWER(LASTNAMEC) || '%')
				  and (FIRSTNAMEC is null or LOWER(BC.FIRSTNAME) like '%' || LOWER(FIRSTNAMEC) || '%')
				  and (PATRONYMICC is null or LOWER(BC.PATRONYMIC) like '%' || LOWER(PATRONYMICC) || '%'))
	loop
		/*выплаты для доплат*/
		BEXTRA := true;
		for PAY in (select BTD.BENEFITSTYPENAMEDIRID,
						   B04.BENEFITSRECIPIENTSID,
						   BC.ID as BENEFITCHILD,
						   BP.SUBJECTSDIRID,
						   B04P.PAYDATE,
						   B04P.PAYSUM,
                           B04P.EXTRADATE,
					  	   B04P.EXTRASUM
		              from BENEFIT04              B04,
						   BENEFITSRECIPIENTS     BR,
						   BENEFITSPACKETS        BP,
						   BENEFICIARIESREGISTERS BTD,
						   BENEFIT04PAYMENT       B04P,
						   CHILD04                B04C,
						   BENEFITCHILD           BC
					 where B04.BENEFITSRECIPIENTSID = BR.ID
					   and B04.BENEFITSPACKETSID = BP.ID
					   and BP.REPYEAR = NREPYEAR
					   and B04.BENEFITSTYPEDIRID = BTD.ID
					   and BTD.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					   and B04P.BENEFIT04ID = B04.ID
					   and B04P.CHILD04ID = B04C.ID
					   and B04C.BENEFITCHILDID = BC.ID
					   and BC.ID = EX.BENEFITCHILD
					   -- пересечение периодов доплаты и выплаты
					   and B04P.PAYDATE between TO_DATE(left(EX.EXTRADATE, 10), 'dd.mm.yyyy') and TO_DATE(right(EX.EXTRADATE, 10), 'dd.mm.yyyy'))
		loop
            NPAY   := NPAY + 1;
			-- доплата
			-- определение заголовка
			if BEXTRA
			then
				select UP.ID
					into NUNLAWFULSURCHARGE
					from UNLAWFULSURCHARGE UP
				 where UP.LID = NLID
					 and UP.UID = NUID
					 and UP.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					 and UP.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID;
				if NUNLAWFULSURCHARGE is null
				then
					insert into UNLAWFULSURCHARGE
						(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
					values
						(NLID, NUID, EX.BENEFITSTYPENAMEDIRID, EX.BENEFITSRECIPIENTSID)
					returning ID into NUNLAWFULSURCHARGE;
				end if;
                IF EX.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
				insert into UNLAWFULSURCHARGEFOOTER
					(LID, UID, UNLAWFULSURCHARGEID, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
				values
					(NLID, NUID, NUNLAWFULSURCHARGE, EX.BENEFITCHILD, EX.SUBJECTSDIRID, EX.PAYDATE, EX.PAYSUM, EX.EXTRADATE, EX.EXTRASUM);MPAYS[I]:=EX.PAYSID; I:=I+1;
				END IF;
                BEXTRA := false;
			end if;

            -- выплата
            -- определение заголовка
            NUNLAWFULSURCHARGE := null;
            select UP.ID
			  into NUNLAWFULSURCHARGE
			  from UNLAWFULSURCHARGE UP
			 where UP.LID = NLID
			   and UP.UID = NUID
			   and UP.BENEFITSTYPENAMEDIRID = PAY.BENEFITSTYPENAMEDIRID
			   and UP.BENEFITSRECIPIENTSID = PAY.BENEFITSRECIPIENTSID;
			if NUNLAWFULSURCHARGE is null
			then
			  insert into UNLAWFULSURCHARGE
				(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
			  values
				(NLID, NUID, PAY.BENEFITSTYPENAMEDIRID, PAY.BENEFITSRECIPIENTSID)
			  returning ID into NUNLAWFULSURCHARGE;
			end if;
            IF PAY.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
			insert into UNLAWFULSURCHARGEFOOTER
			  (LID, UID, UNLAWFULSURCHARGEID, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
			values
			  (NLID, NUID, NUNLAWFULSURCHARGE, PAY.BENEFITCHILD, PAY.SUBJECTSDIRID, PAY.PAYDATE, PAY.PAYSUM, PAY.EXTRADATE, PAY.EXTRASUM);MPAYS[I]:=PAY.PAYSID; I:=I+1;
            END IF;
		end loop;
	end loop;

    --ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ РЕЕСТР 05 ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ
	/*доплаты*/
	for EX in (select BTD.BENEFITSTYPENAMEDIRID,
	                  B05.BENEFITSRECIPIENTSID,
					  BC.ID as BENEFITCHILD,
					  BP.SUBJECTSDIRID,
					  B05P.EXTRADATE,
					  B05P.EXTRASUM,
                      B05P.PAYDATE,
					  B05P.PAYSUM
	             from BENEFIT05              B05,
                      BENEFITSRECIPIENTS     BR,
					  BENEFITSPACKETS        BP,
					  BENEFICIARIESREGISTERS BTD,
					  BENEFIT05PAYMENT       B05P,
					  CHILD05                B05C,
					  BENEFITCHILD           BC
				where B05.BENEFITSRECIPIENTSID = BR.ID
				  and B05.BENEFITSPACKETSID = BP.ID
				  and BP.REPYEAR = NREPYEAR
				  and B05.BENEFITSTYPEDIRID = BTD.ID
				  and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				  and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				  and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				  and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				  and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				  and B05P.BENEFIT05ID = B05.ID
				  and COALESCE(B05P.EXTRASUM, 0) <> 0 -- сумма доплаты
				  and B05P.CHILD05ID = B05C.ID
				  and B05C.BENEFITCHILDID = BC.ID
				  and (NDOCBIRTHCHILDTYPEID is null or BC.DOCBIRTHCHILDTYPEID = NDOCBIRTHCHILDTYPEID)
				  and (LASTNAMEC is null or LOWER(BC.LASTNAME) like '%' || LOWER(LASTNAMEC) || '%')
				  and (FIRSTNAMEC is null or LOWER(BC.FIRSTNAME) like '%' || LOWER(FIRSTNAMEC) || '%')
				  and (PATRONYMICC is null or LOWER(BC.PATRONYMIC) like '%' || LOWER(PATRONYMICC) || '%'))
	loop
		/*выплаты для доплат*/
		BEXTRA := true;
		for PAY in (select BTD.BENEFITSTYPENAMEDIRID,
						   B05.BENEFITSRECIPIENTSID,
						   BC.ID as BENEFITCHILD,
						   BP.SUBJECTSDIRID,
						   B05P.PAYDATE,
						   B05P.PAYSUM,
                           B05P.EXTRADATE,
					  	   B05P.EXTRASUM
		              from BENEFIT05              B05,
						   BENEFITSRECIPIENTS     BR,
						   BENEFITSPACKETS        BP,
						   BENEFICIARIESREGISTERS BTD,
						   BENEFIT05PAYMENT       B05P,
						   CHILD05                B05C,
						   BENEFITCHILD           BC
					 where B05.BENEFITSRECIPIENTSID = BR.ID
					   and B05.BENEFITSPACKETSID = BP.ID
					   and BP.REPYEAR = NREPYEAR
					   and B05.BENEFITSTYPEDIRID = BTD.ID
					   and BTD.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					   and B05P.BENEFIT05ID = B05.ID
					   and B05P.CHILD05ID = B05C.ID
					   and B05C.BENEFITCHILDID = BC.ID
					   and BC.ID = EX.BENEFITCHILD
					   -- пересечение периодов доплаты и выплаты
					   and TO_DATE(left(EX.EXTRADATE, 10), 'dd.mm.yyyy') <= TO_DATE(right(B05P.PAYDATE, 10), 'dd.mm.yyyy')
                       and TO_DATE(right(EX.EXTRADATE, 10), 'dd.mm.yyyy') >= TO_DATE(left(B05P.PAYDATE, 10), 'dd.mm.yyyy')

                       )
		loop
            NPAY   := NPAY + 1;
			-- доплата
			-- определение заголовка
			if BEXTRA
			then
				select UP.ID
					into NUNLAWFULSURCHARGE
					from UNLAWFULSURCHARGE UP
				 where UP.LID = NLID
					 and UP.UID = NUID
					 and UP.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					 and UP.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID;
				if NUNLAWFULSURCHARGE is null
				then
					insert into UNLAWFULSURCHARGE
						(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
					values
						(NLID, NUID, EX.BENEFITSTYPENAMEDIRID, EX.BENEFITSRECIPIENTSID)
					returning ID into NUNLAWFULSURCHARGE;
				end if;
                IF EX.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
				insert into UNLAWFULSURCHARGEFOOTER
					(LID, UID, UNLAWFULSURCHARGEID, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
				values
					(NLID, NUID, NUNLAWFULSURCHARGE, EX.BENEFITCHILD, EX.SUBJECTSDIRID, EX.PAYDATE, EX.PAYSUM, EX.EXTRADATE, EX.EXTRASUM);MPAYS[I]:=EX.PAYSID; I:=I+1;
				END IF;
                BEXTRA := false;
			end if;

            -- выплата
            -- определение заголовка
            NUNLAWFULSURCHARGE := null;
            select UP.ID
			  into NUNLAWFULSURCHARGE
			  from UNLAWFULSURCHARGE UP
			 where UP.LID = NLID
			   and UP.UID = NUID
			   and UP.BENEFITSTYPENAMEDIRID = PAY.BENEFITSTYPENAMEDIRID
			   and UP.BENEFITSRECIPIENTSID = PAY.BENEFITSRECIPIENTSID;
			if NUNLAWFULSURCHARGE is null
			then
			  insert into UNLAWFULSURCHARGE
				(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
			  values
				(NLID, NUID, PAY.BENEFITSTYPENAMEDIRID, PAY.BENEFITSRECIPIENTSID)
			  returning ID into NUNLAWFULSURCHARGE;
			end if;
            IF PAY.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
			insert into UNLAWFULSURCHARGEFOOTER
			  (LID, UID, UNLAWFULSURCHARGEID, BENEFITCHILDID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
			values
			  (NLID, NUID, NUNLAWFULSURCHARGE, PAY.BENEFITCHILD, PAY.SUBJECTSDIRID, PAY.PAYDATE, PAY.PAYSUM, PAY.EXTRADATE, PAY.EXTRASUM);MPAYS[I]:=PAY.PAYSID; I:=I+1;
            END IF;
		end loop;
	end loop;

    --ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ РЕЕСТР 06 ШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШШ
	/*доплаты*/
	for EX in (select BTD.BENEFITSTYPENAMEDIRID,
	                  B06.BENEFITSRECIPIENTSID,
					  BP.SUBJECTSDIRID,
					  B06P.EXTRADATE,
					  B06P.EXTRASUM,
                      B06P.PAYDATE,
					  B06P.PAYSUM
	             from BENEFIT06              B06,
                      BENEFITSRECIPIENTS     BR,
					  BENEFITSPACKETS        BP,
					  BENEFICIARIESREGISTERS BTD,
					  BENEFIT06PAYMENT       B06P
				where B06.BENEFITSRECIPIENTSID = BR.ID
				  and B06.BENEFITSPACKETSID = BP.ID
				  and BP.REPYEAR = NREPYEAR
				  and B06.BENEFITSTYPEDIRID = BTD.ID
				  and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				  and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				  and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				  and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				  and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				  and COALESCE(B06P.EXTRASUM, 0) <> 0 -- сумма доплаты
				  and B06P.BENEFIT06ID = B06.ID)
	loop
		/*выплаты для доплат*/
		BEXTRA := true;
		for PAY in (select BTD.BENEFITSTYPENAMEDIRID,
	                  	   B06.BENEFITSRECIPIENTSID,
					  	   BP.SUBJECTSDIRID,
					  	   B06P.PAYDATE,
					       B06P.PAYSUM,
                           B06P.EXTRADATE,
					  	   B06P.EXTRASUM
	                  from BENEFIT06              B06,
                           BENEFITSRECIPIENTS     BR,
					       BENEFITSPACKETS        BP,
					       BENEFICIARIESREGISTERS BTD,
					       BENEFIT06PAYMENT       B06P
				     where B06.BENEFITSRECIPIENTSID = BR.ID
				       and B06.BENEFITSPACKETSID = BP.ID
				       and BP.REPYEAR = NREPYEAR
				       and B06.BENEFITSTYPEDIRID = BTD.ID
				       and BTD.BENEFITSTYPENAMEDIRID = any(ABENEFITSTYPENAMEDIRID)
				       and (NPERSONDOCUMENTTYPEID is null or BR.PERSONDOCUMENTTYPEID = NPERSONDOCUMENTTYPEID)
				       and (LASTNAMEB is null or LOWER(BR.LASTNAME) like '%' || LOWER(LASTNAMEB) || '%')
				       and (FIRSTNAMEB is null or LOWER(BR.FIRSTNAME) like '%' || LOWER(FIRSTNAMEB) || '%')
				       and (PATRONYMICB is null or LOWER(BR.PATRONYMIC) like '%' || LOWER(PATRONYMICB) || '%')
				       and COALESCE(B06P.EXTRASUM, 0) <> 0 -- сумма доплаты
				       and B06P.BENEFIT06ID = B06.ID


                       and B06.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID
					   -- пересечение периодов доплаты и выплаты
					   and B06P.PAYDATE between TO_DATE(left(EX.EXTRADATE, 10), 'dd.mm.yyyy') and TO_DATE(right(EX.EXTRADATE, 10), 'dd.mm.yyyy'))
		loop
            NPAY   := NPAY + 1;
			-- доплата
			-- определение заголовка
			if BEXTRA
			then
				select UP.ID
					into NUNLAWFULSURCHARGE
					from UNLAWFULSURCHARGE UP
				 where UP.LID = NLID
					 and UP.UID = NUID
					 and UP.BENEFITSTYPENAMEDIRID = EX.BENEFITSTYPENAMEDIRID
					 and UP.BENEFITSRECIPIENTSID = EX.BENEFITSRECIPIENTSID;
				if NUNLAWFULSURCHARGE is null
				then
					insert into UNLAWFULSURCHARGE
						(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
					values
						(NLID, NUID, EX.BENEFITSTYPENAMEDIRID, EX.BENEFITSRECIPIENTSID)
					returning ID into NUNLAWFULSURCHARGE;
				end if;
                IF EX.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
				insert into UNLAWFULSURCHARGEFOOTER
					(LID, UID, UNLAWFULSURCHARGEID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
				values
					(NLID, NUID, NUNLAWFULSURCHARGE, EX.SUBJECTSDIRID, EX.PAYDATE, EX.PAYSUM, EX.EXTRADATE, EX.EXTRASUM);MPAYS[I]:=EX.PAYSID; I:=I+1;
				END IF;
                BEXTRA := false;
			end if;

            -- выплата
            -- определение заголовка
            NUNLAWFULSURCHARGE := null;
            select UP.ID
			  into NUNLAWFULSURCHARGE
			  from UNLAWFULSURCHARGE UP
			 where UP.LID = NLID
			   and UP.UID = NUID
			   and UP.BENEFITSTYPENAMEDIRID = PAY.BENEFITSTYPENAMEDIRID
			   and UP.BENEFITSRECIPIENTSID = PAY.BENEFITSRECIPIENTSID;
			if NUNLAWFULSURCHARGE is null
			then
			  insert into UNLAWFULSURCHARGE
				(LID, UID, BENEFITSTYPENAMEDIRID, BENEFITSRECIPIENTSID) --
			  values
				(NLID, NUID, PAY.BENEFITSTYPENAMEDIRID, PAY.BENEFITSRECIPIENTSID)
			  returning ID into NUNLAWFULSURCHARGE;
			end if;
            IF PAY.PAYSID NOT IN (SELECT UNNEST(MPAYS)) THEN
			insert into UNLAWFULSURCHARGEFOOTER
			  (LID, UID, UNLAWFULSURCHARGEID, SUBJECTSDIRID, PERIODPAY, SUMPAY, PERIODEXTRA, SUMEXTRA)
			values
			  (NLID, NUID, NUNLAWFULSURCHARGE, PAY.SUBJECTSDIRID, PAY.PAYDATE, PAY.PAYSUM, PAY.EXTRADATE, PAY.EXTRASUM);MPAYS[I]:=PAY.PAYSID; I:=I+1;
            END IF;
		end loop;
	end loop;
    if NPAY = 0
    then
      return 'По заданным критериям случаев неправомерных доплат необнаружено.';
    else
      return null;
    end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_unlawfulsurcharge_gen (uid bigint, benefitstypenamedirid bigint [], repyear bigint, lastnameb text, firstnameb text, patronymicb text, persondocumenttypeid bigint, docseriesb text, docnumberb text, lastnamec text, firstnamec text, patronymicc text, docbirthchildtypeid bigint, docseriesc text, docnumberc text, birthdatec date, hid bigint)
  OWNER TO magicbox;