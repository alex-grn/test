CREATE OR REPLACE FUNCTION public.p_benefit05_rep (
  uid bigint,
  repyear integer,
  repmonth text,
  repmonthby text,
  clear boolean = false
)
RETURNS void AS
$body$
declare
  nmb  bigint := REPMONTH::bigint;
  nme  bigint := REPMONTHBY::bigint;
  ny   bigint := REPYEAR::bigint;
  nuid bigint := uid;
  rec record;
begin
    --raise using message = nuid;
  if CLEAR then
    -- чистка
    delete from BENEFIT05_REP BR where BR.UID = nuid;
  else
  -- чистка
  delete from BENEFIT05_REP BR where BR.UID = nuid;
  -- сохраним
  insert into BENEFIT05_REP
  (uid, ROW_PS0, ROW_PS1, CODE_AREA, CODE_REGION, REGION, PERS_COUNT, REG_COEFF, NORM_SUM, NORM_SUM_BY_REG_COEFF, PERS_SUM_BY_REG_COEFF, PAY_SUM, DIST_SUM)
  -- загруженные данные раздела
with FD as
	 (select L.CODE,
	         L.NAME,
			 L.FEDREG,
			 count(1) as PERS_COUNT,
			 L.COEFFICIENT,
			 L.MIN,
			 L.CALC_NORM,
			 round(count(1) * L.CALC_NORM, 2) as PERS_NORM,
			 sum(L.SUMM) as SUMM
	    from (select F.CODE,
			         F.NAME,
					 F.FEDREG,
					 F.benefitsrecipientsid,
					 F.COEFFICIENT,
					 F.MIN,
					 F.CALC_NORM,
					 sum(F.PAYSUM) as SUMM
		        from (select B05.benefitsrecipientsid,
				             SD.CODE,
							 SD.NAME,
							 SD.FEDREG,
							 B05P.COEFFICIENT,
							 (select BIDH.MIN
							    from BENEFITSINDEXDIR        BID,
								     BENEFITSTYPEDIR         BTD,
									 BENEFITSINDEXDIRHISTORY BIDH
							   where BID.BENEFITSTYPENAMEDIRID = BTD.ID
							     and BTD.ROSTERNUMBER = 5 /*пособие на ребенка военнослужащего*/
								 and BIDH.BENEFITSINDEXDIRID = BID.ID
								 and BIDH.PAYDATEFROM = (select max(BIDH2.PAYDATEFROM)
								                           from BENEFITSINDEXDIRHISTORY BIDH2
														  where BENEFITSINDEXDIRID = BID.ID
														    and BIDH2.PAYDATEFROM <= P_TOOLS_LAST_DAY(TO_DATE('01.' || LPAD(BP.REPMONTH, 2, '0') || '.' || BP.REPYEAR, 'dd.mm.yyyy')))),
							 round(B05P.COEFFICIENT *
							 (select BIDH.MIN
							    from BENEFITSINDEXDIR        BID,
									 BENEFITSTYPEDIR         BTD,
									 BENEFITSINDEXDIRHISTORY BIDH
							   where BID.BENEFITSTYPENAMEDIRID = BTD.ID
                                 and BTD.ROSTERNUMBER = 5 /*пособие на ребенка военнослужащего*/
								 and BIDH.BENEFITSINDEXDIRID = BID.ID
								 and BIDH.PAYDATEFROM = (select max(BIDH2.PAYDATEFROM)
                                                           from BENEFITSINDEXDIRHISTORY BIDH2
														  where BENEFITSINDEXDIRID = BID.ID
														    and BIDH2.PAYDATEFROM <= P_TOOLS_LAST_DAY(TO_DATE('01.' || LPAD(BP.REPMONTH, 2, '0') || '.' || BP.REPYEAR, 'dd.mm.yyyy')))), 2) as CALC_NORM,
							 COALESCE(B05P.PAYSUM, null, 0) as PAYSUM
				        from BENEFIT05        B05,
							 BENEFITSPACKETS  BP,
							 SUBJECTSDIR      SD,
							 BENEFIT05PAYMENT B05P
				      where BP.REPMONTH ::BIGINT between nmb and nme
					    and BP.REPYEAR = ny
						and BP.ID = B05.BENEFITSPACKETSID
						and SD.ID = BP.SUBJECTSDIRID
						and B05P.BENEFIT05ID = B05.ID
						and COALESCE(B05P.PAYSUM, null, 0) <> 0) F
				group by F.CODE,
						 F.NAME,
						 F.FEDREG,
						 F.benefitsrecipientsid,
						 F.COEFFICIENT,
						 F.MIN,
						 F.CALC_NORM) L
		 group by L.CODE,
				  L.NAME,
				  L.FEDREG,
				  L.COEFFICIENT,
				  L.MIN,
				  L.CALC_NORM)
	select nuid,
    	   3 as ROW0,
	       3 as ROW1,
		   FO.CODE as CODE_AREA,
		   SDD.CODE as CODE_REGION,
		   SDD.NAME,
		   COALESCE(FD.PERS_COUNT, 0) as PERS_COUNT, -- Численность получателе
		   COALESCE(FD.COEFFICIENT, 0) as REG_COEFF, -- Норматив пособия
		   COALESCE(FD.MIN, 0) as NORM_SUM, -- Районный коэфф.
		   COALESCE(FD.CALC_NORM, 0) as NORM_SUM_BY_REG_COEFF, -- Норматив с учетом районного коэффициента
		   COALESCE(FD.PERS_NORM, 0) as PERS_SUM_BY_REG_COEFF, -- Расчетная сумма выплат пособий
		   COALESCE(FD.SUMM, 0) as PAY_SUM, -- Объем выплаченных пособий
		   COALESCE(FD.PERS_NORM - FD.SUMM, 0) as DIST -- Разница между расчетной суммой выплат пособий и фактической выплатой пособий
	  from SUBJECTSDIR SDD
	left join FD on FD.NAME = SDD.NAME
	 inner join (select min(SD1.CODE) as CODE,
				        SD1.FEDREG
	               from SUBJECTSDIR SD1
				  group by SD1.FEDREG) FO on SDD.FEDREG = FO.FEDREG
	union all
  -- итоги по регионам
	select nuid,
    	   3,
	       2,
		   FO.CODE,
		   F.CODE,
		   F.NAME,
		   count(1),
		   null ::numeric,
		   null ::numeric,
		   null ::numeric,
		   0 ::numeric,
		   0 ::numeric,
		   0 ::numeric
	  from (select B05.benefitsrecipientsid,
	               SD.CODE,
				   SD.NAME,
				   SD.FEDREG
	          from BENEFIT05        B05,
			       BENEFITSPACKETS  BP,
				   SUBJECTSDIR      SD,
				   BENEFIT05PAYMENT B05P
			 where BP.REPMONTH ::BIGINT between nmb and nme
			   and BP.REPYEAR = ny
			   and BP.ID = B05.BENEFITSPACKETSID
			   and SD.ID = BP.SUBJECTSDIRID
			   and B05P.BENEFIT05ID = B05.ID
			   and COALESCE(B05P.PAYSUM, null, 0) <> 0
			 group by B05.benefitsrecipientsid,
			          SD.CODE,
					  SD.NAME,
					  SD.FEDREG) F
	 inner join (select min(SD1.CODE) as CODE,
					    SD1.FEDREG
	               from SUBJECTSDIR SD1
				  group by SD1.FEDREG) FO on F.FEDREG = FO.FEDREG
	 group by FO.CODE,
		      F.CODE,
			  F.NAME,
			  F.FEDREG
	union all
  -- итоги по округам
	select nuid,
    	   1,
		   1,
		   min(SD.CODE) as CODE,
		   0,
		   SD.FEDREG,
		   0, -- Численность получателе
		   null, -- Норматив пособия
		   null, -- Районный коэфф.
		   null, -- Норматив с учетом районного коэффициента
		   0, -- Расчетная сумма выплат пособий
		   0, -- Объем выплаченных пособий
		   0 -- Разница между расчетной суммой выплат пособий и фактической выплатой пособий
	  from SUBJECTSDIR SD
	 group by SD.FEDREG;

     -- итоги по регионам
     for rec in
     (select b05r.code_region,
             sum(b05r.pers_sum_by_reg_coeff) as pers_sum_by_reg_coeff,
             sum(b05r.pay_sum) as pay_sum,
             sum(b05r.dist_sum) as dist_sum
        from benefit05_rep b05r
 	   where b05r.uid = nuid
   	     and b05r.row_ps1 = 3 -- только детали по регионам
   		 and (b05r.pers_count <> 0 or b05r.pers_sum_by_reg_coeff <> 0 or b05r.pay_sum <> 0)
       group by b05r.code_region
     )
     loop
       -- итог по региону
       update benefit05_rep bb
          set pers_sum_by_reg_coeff = pers_sum_by_reg_coeff + rec.pers_sum_by_reg_coeff,
              pay_sum = pay_sum + rec.pay_sum,
              dist_sum = dist_sum + rec.dist_sum
        where bb.uid = nuid
          and bb.code_region = rec.code_region
          and bb.row_ps1 = 2; -- итоги по регионам
     end loop;

     -- итоги по округам
     for rec in
     (select b05r.code_area,
	         sum(b05r.pers_count) as pers_count,
             sum(b05r.pers_sum_by_reg_coeff) as pers_sum_by_reg_coeff,
             sum(b05r.pay_sum) as pay_sum,
             sum(b05r.dist_sum) as dist_sum
        from benefit05_rep b05r
 	   where b05r.uid = 1
   	     and b05r.row_ps1 = 2 -- только детали по регионам
   		 and (b05r.pers_count <> 0 or b05r.pers_sum_by_reg_coeff <> 0 or b05r.pay_sum <> 0)
       group by b05r.code_area
     )
     loop
       -- итог по округу
       update benefit05_rep bb
          set pers_count = pers_count + rec.pers_count,
              pers_sum_by_reg_coeff = pers_sum_by_reg_coeff + rec.pers_sum_by_reg_coeff,
              pay_sum = pay_sum + rec.pay_sum,
              dist_sum = dist_sum + rec.dist_sum
        where bb.uid = nuid
          and bb.code_area = rec.code_area
          and bb.row_ps0 = 1
          and bb.row_ps1 = 1; -- итоги по округу
     end loop;

     -- общий
     insert into BENEFIT05_REP
     (uid, ROW_PS0, ROW_PS1, CODE_AREA, CODE_REGION, REGION, PERS_COUNT, REG_COEFF, NORM_SUM, NORM_SUM_BY_REG_COEFF, PERS_SUM_BY_REG_COEFF, PAY_SUM, DIST_SUM)
     select nuid,
     		0,
            0,
            0,
            0,
            'Общий итог:',
            sum(b05r.pers_count),
            null,
            null,
            null,
            sum(b05r.pers_sum_by_reg_coeff),
            sum(b05r.pay_sum),
            sum(b05r.dist_sum)
       from benefit05_rep b05r
      where b05r.uid = nuid
        and b05r.row_ps1 = 2;
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_benefit05_rep (uid bigint, repyear integer, repmonth text, repmonthby text, clear boolean)
  OWNER TO magicbox;