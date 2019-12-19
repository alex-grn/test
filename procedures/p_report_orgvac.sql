CREATE OR REPLACE FUNCTION public.p_report_orgvac (
  ident bigint,
  executivebody text,
  departmentdirid bigint,
  yearconscription bigint,
  conscription text,
  clear boolean
)
RETURNS void AS
$body$
declare
  nident            bigint := ident;
  nYEARCONSCRIPTION bigint := YEARCONSCRIPTION;
  sCONSCRIPTION 	text   := CONSCRIPTION;
  sEXECUTIVEBODY 	text   := EXECUTIVEBODY;
  nDEPARTMENTDIRID  bigint := DEPARTMENTDIRID;
  norganizationid	bigint;
  rec record;
  nsort_row 	    bigint;
begin
  if CLEAR
  then
	-- чистка
    null;
	delete from report_orgvac ro where ro.ident = NIDENT;
  --raise using message = NIDENT;
  else
	-- чистка
	--delete from report_orgvac ro where ro.ident = NIDENT;

    -- наполняем организации
    insert into report_orgvac
          select NIDENT,
          		 O.ID,
                 0,
                 DD.LEVELSIGNIFICANCE,
                 OD.NAME,
                 case
                     when OD.COINCIDENCE then
                        RD.NAME
                     else
                        COALESCE(RD2.NAME, RD.NAME)
                 end REG_NAME,
                 case
                     when OD.COINCIDENCE then
                        'Юр.адрес: ' || COALESCE(OD.POSTCODE ::TEXT, '') || COALESCE(rtrim(', ' || RD.NAME, ', '), '') || COALESCE(rtrim(', ' || OD.SETTLEMENT, ', '), '') ||
                        COALESCE(rtrim(', ул.' || OD.STREET, ', ул.'), '') || COALESCE(rtrim(', д.' || OD.HOUSE, ', д.'), '') || COALESCE(rtrim(', корп.' || OD.HOUSING, ', корп.'), '') ||
                        COALESCE(rtrim(', стр.' || OD.BUILDING, ', стр.'), '') || '; Факт. адрес совпадает.'
                     else
                        case
                            when COALESCE(OD.POSTCODE ::TEXT, '') || COALESCE(rtrim(', ' || RD.NAME, ', '), '') || COALESCE(rtrim(', ' || OD.SETTLEMENT, ', '), '') || COALESCE(rtrim(', ул.' || OD.STREET, ', ул.'), '') ||
                                     COALESCE(rtrim(', д.' || OD.HOUSE, ', д.'), '') || COALESCE(rtrim(', корп.' || OD.HOUSING, ', корп.'), '') || COALESCE(rtrim(', стр.' || OD.BUILDING, ', стр.'), '') =
                                     COALESCE(OD.POSTCODE2 ::TEXT, '') || COALESCE(rtrim(', ' || RD2.NAME, ', '), '') || COALESCE(rtrim(', ' || OD.SETTLEMENT2, ', '), '') || COALESCE(rtrim(', ул.' || OD.STREET2, ', ул.'), '') ||
                                     COALESCE(rtrim(', д.' || OD.HOUSE2, ', д.'), '') || COALESCE(rtrim(', корп.' || OD.HOUSING2, ', корп.'), '') || COALESCE(rtrim(', стр.' || OD.BUILDING2, ', стр.'), '') then
                             'Юр.адрес: ' || COALESCE(OD.POSTCODE ::TEXT, '') || COALESCE(rtrim(', ' || RD.NAME, ', '), '') || COALESCE(rtrim(', ' || OD.SETTLEMENT, ', '), '') ||
                             COALESCE(rtrim(', ул.' || OD.STREET, ', ул.'), '') || COALESCE(rtrim(', д.' || OD.HOUSE, ', д.'), '') || COALESCE(rtrim(', корп.' || OD.HOUSING, ', корп.'), '') ||
                             COALESCE(rtrim(', стр.' || OD.BUILDING, ', стр.'), '') || '; Факт. адрес совпадает.'
                            else
                             'Юр.адрес: ' || COALESCE(OD.POSTCODE ::TEXT, '') || COALESCE(rtrim(', ' || RD.NAME, ', '), '') || COALESCE(rtrim(', ' || OD.SETTLEMENT, ', '), '') ||
                             COALESCE(rtrim(', ул.' || OD.STREET, ', ул.'), '') || COALESCE(rtrim(', д.' || OD.HOUSE, ', д.'), '') || COALESCE(rtrim(', корп.' || OD.HOUSING, ', корп.'), '') ||
                             COALESCE(rtrim(', стр.' || OD.BUILDING, ', стр.'), '') || CHR(10) || 'Факт.адрес: ' || COALESCE(OD.POSTCODE2 ::TEXT, '') || COALESCE(rtrim(', ' || RD2.NAME, ', '), '') ||
                             COALESCE(rtrim(', ' || OD.SETTLEMENT2, ', '), '') || COALESCE(rtrim(', ул.' || OD.STREET2, ', ул.'), '') || COALESCE(rtrim(', д.' || OD.HOUSE2, ', д.'), '') ||
                             COALESCE(rtrim(', корп.' || OD.HOUSING2, ', корп.'), '') || COALESCE(rtrim(', стр.' || OD.BUILDING2, ', стр.'), '')
                        end
                 end as ORG_ADDR
        from ORGANIZATION O
     inner join PLANS P
            on P.ID = O.PLANSID
        left join ORGANIZATIONDIR OD
            on OD.ID = O.ORGANIZATIONDIRID
        left join DEPARTMENTDIR DD
            on DD.ID = OD.DEPARTMENTDIRID
        left join REGIONDIR RD
            on RD.ID = OD.REGIONDIRID
        left join REGIONDIR RD2
            on RD2.ID = OD.REGIONDIR2ID
     where /*(nYEARCONSCRIPTION is null or P.YEARCONSCRIPTION = nYEARCONSCRIPTION::bigint)
         and (sCONSCRIPTION = '' or sCONSCRIPTION is null or p.conscription::text = sCONSCRIPTION)
         -- ведомство
         and*/ (nDEPARTMENTDIRID is null or OD.departmentdirid = nDEPARTMENTDIRID)
         -- Исполнительный орган
         and (sEXECUTIVEBODY = '' or sEXECUTIVEBODY is null or DD.LEVELSIGNIFICANCE = sEXECUTIVEBODY)
         and exists (select 1 from VACANCYORG V where V.ORGANIZATIONID = O.ID AND (V.CONSCRIPTION = P_REPORT_ORGVAC.CONSCRIPTION OR P_REPORT_ORGVAC.CONSCRIPTION IS NULL) 
         																	  AND (V.YEARCONSCRIPTION = P_REPORT_ORGVAC.YEARCONSCRIPTION OR P_REPORT_ORGVAC.YEARCONSCRIPTION IS NULL));
     
    -- наполнение отпускми
    for rec in
      (select V.organizationid,
              PD.name as post_name,
              V.justspring + V.justautumn as post_cnt,
              null::bigint as ident_tmp
         from VACANCYORG    V,
              professiondir pd
        where V.professiondirid = pd.id
          and (V.YEARCONSCRIPTION = P_REPORT_ORGVAC.YEARCONSCRIPTION OR P_REPORT_ORGVAC.YEARCONSCRIPTION IS NULL)
          AND (V.CONSCRIPTION = P_REPORT_ORGVAC.CONSCRIPTION OR P_REPORT_ORGVAC.CONSCRIPTION IS NULL) 
          and exists(select 1
                       from report_orgvac ro
                      where ro.ident = nident
                        and ro.id_row = V.organizationid)
        order by V.organizationid)
    loop
      if norganizationid is null or rec.organizationid <> norganizationid
      then
        nsort_row       := 0;
        norganizationid := rec.organizationid;
      end if;
      -- поиск
        select ru.ident
          into rec.ident_tmp
          from report_orgvac RU
         where RU.ident = NIDENT
           and RU.id_row = REC.organizationid
           and RU.sort_row = nsort_row
           and ru.org_vac_name is null
           and ru.org_vac_gen_count is null;
      if rec.ident_tmp is not null then
        update report_orgvac RU
           set org_vac_name	      = rec.post_name,
               org_vac_gen_count  = rec.post_cnt
         where RU.ident = NIDENT
           and RU.id_row = REC.organizationid
           and RU.sort_row = nsort_row
           and ru.org_vac_name is null
           and ru.org_vac_gen_count is null;
      else
        insert into report_orgvac(ident, id_row, sort_row, org_vac_name, org_vac_gen_count)
          values(nident, REC.organizationid, nsort_row, rec.post_name, rec.post_cnt);
      end if;
	  nsort_row := nsort_row + 1;
    end loop;
    
    -- меняем порядковый номер
    nsort_row :=0;
    for rec in
    (select *
       from report_orgvac ro
      where ro.ident = nident
        and EXISTS(select 1 from report_orgvac r where r.ident = ro.ident and r.id_row = ro.id_row and r.levelsignificance = '1')
        and ro.sort_row = 0
      order by ro.id_row)
  	loop
      nsort_row := nsort_row + 1;
      update report_orgvac ru
         set num_pp = nsort_row
       where ru.ident = rec.ident
         and ru.id_row = rec.id_row
         and ru.sort_row = rec.sort_row;
    end loop;
    nsort_row :=0;
    for rec in
    (select *
       from report_orgvac ro
      where ro.ident = nident
        and EXISTS(select 1 from report_orgvac r where r.ident = ro.ident and r.id_row = ro.id_row and r.levelsignificance = '2')
        and ro.sort_row = 0
      order by ro.id_row, ro.sort_row)
  	loop
      nsort_row := nsort_row + 1;
      update report_orgvac ru
         set num_pp = nsort_row
       where ru.ident = rec.ident
         and ru.id_row = rec.id_row
         and ru.sort_row = rec.sort_row;
    end loop;
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_report_orgvac (ident bigint, executivebody text, departmentdirid bigint, yearconscription bigint, conscription text, clear boolean)
  OWNER TO magicbox;