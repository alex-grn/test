CREATE OR REPLACE FUNCTION public.p_action_calctabags_calc (
  yearcalc integer,
  percalc text,
  recreate boolean,
  uid bigint = NULL::bigint
)
RETURNS void AS
$body$
 declare
 nYEARCALC    calctabags.yearcalc%type := YEARCALC;
 sPERCALC     calctabags.percalc%type := PERCALC;
 rCalctabags  calctabags%ROWTYPE; -- запись раздела "Расчетная таблица 1 - АГС"
 sID 		  text;
 sSTATUSCALC  calctabags.statuscalc%type := '2'; -- статус рассчитан
 sres         text = '';
 nreg_all	  integer;
 out_org      integer;
 in_org       integer;
 fire_ags     integer;
 timeout      integer;
 health       integer;
 family_drama integer;
 others       integer;
 ends         integer;
 rg			  record;
 ddism_bgn	  date;
 ddism_end	  date;

 begin
   -- наличие расчетной таблицы
   select *
     into rCalctabags
     from calctabags c
    where c.yearcalc = nYEARCALC
      and c.percalc = sPERCALC;

   -- формирование/Переформирование раздела "Расчетная таблица 1 - АГС"
   if rCalctabags.Id is null or (rCalctabags.Id is not null and RECREATE)
   then
     -- создание заголовка
     if rCalctabags.Id is null
     then
       rCalctabags.uid := UID;
       sres := P_SYSTEM_TABLE_GET_LEVACCESS('calctabags', rCalctabags.uid);
       if sres = '' or sres is null
       then
         sres := '1';
       elsif strpos(sres, ';')
       then
         raise using MESSAGE = 'Некоректная настройка прав для выполнения действия.';
       end if;
       rCalctabags.lid := sres::bigint;

       --sID = P_SYSTEM_ACTION_DO('insert', 'calctabags', '{"yearcalc":"'||YEARCALC||'","percalc":"'||PERCALC||'"}', UNIT, UID);
       insert into calctabags(lid, PERCALC, YEARCALC)values(rCalctabags.lid, sPERCALC, nYEARCALC) returning id into rCalctabags.id;
     else
       delete from REGAGS where calctabagsid = rCalctabags.Id;
       delete from REGAGSEDUC where calctabagsid = rCalctabags.Id;
     end if;

     -- определение периода увольнения
     if sPERCALC = '1'
     then
       ddism_bgn := to_date('01.02.'||nYEARCALC::text,'dd.mm.yyyy');
       ddism_end := to_date('31.07.'||nYEARCALC::text,'dd.mm.yyyy');
     elsif sPERCALC = '2'
     then
       ddism_bgn := to_date('01.08.'||nYEARCALC::text,'dd.mm.yyyy');
       ddism_end := to_date('31.01.'||(nYEARCALC+1)::text,'dd.mm.yyyy');
     end if;
--  raise using message = ddism_end ;

     -- основной сбор
     -- Граждане
     --<AI id="1" name="Весна"/>
     --<AI id="2" name="Осень"/>
     -- Расчетная таблица 1 - АГС
     --<AI id="1" name="Февраль - Июль"/>
     --<AI id="2" name="Август - Январь"/>
     --select * from REGAGS
     for rg in
     (select r.districtfederal::bigint as districtfederal, r.id
        from regiondir r
       group by r.districtfederal::bigint, r.id)
     loop
       -- графа 3
       select count(s.id)
         into nreg_all
         from citizenry s,
              regiondir r,
              EDUCATIONCIT e
         where r.id = s.regiondirid
           and split_part(age(now(),s.birthdate)::text,' ',1)::integer>=18
           and r.id = rg.id
           and s.conscription = PERCALC
           and s.statuscitizen = '3'
           and e.citizenryid = s.id
           and e.hidedate = (select max(x.hidedate) from EDUCATIONCIT x where x.citizenryid = e.citizenryid)
           and e.leveleducation in ('2','3','4','5','6','8');

       -- гравы 5 и 6
       select sum(case when org.regiondirid != s.regiondirid then 1 else 0 end), --
              sum(case when org.regiondirid = s.regiondirid then 1 else 0 end) --
         into out_org,
              in_org
         from citizenry s,
              regiondir r,
              DIRECTION p,
              ORGANIZATION o,
              ORGANIZATIONDIR org,
              EDUCATIONCIT e
         where r.id = s.regiondirid
           and split_part(age(now(),s.birthdate)::text,' ',1)::integer>=18
           and r.id = rg.id
           and s.conscription = percalc
           and s.yearconscription = yearcalc
           and p.citizenryid = s.id
           and o.id = p.organizationid
           and org.id = o.organizationdirid
           and s.statuscitizen = '3'
           and e.citizenryid = s.id
           and e.hidedate = (select max(x.hidedate) from EDUCATIONCIT x where x.citizenryid = e.citizenryid)
           and e.leveleducation in ('2','3','4','5','6','8');

       select sum(case when p.basis4 = '1' then 1 else 0 end),
              sum(case when p.basis4 = '2' then 1 else 0 end),
           	  sum(case when p.basis4 = '5' then 1 else 0 end),
           	  sum(case when p.basis4 = '6' then 1 else 0 end)
         into timeout,
              health,
              family_drama,
              others
         from citizenry s,
              regiondir r,
              PASSAGEAGSCIT p,
              EDUCATIONCIT e
        where r.id = s.regiondirid
          and split_part(age(now(),s.birthdate)::text,' ',1)::integer >= 18
          and r.id = rg.id
          --and s.conscription = PERCALC
          --and s.yearconscription = yearcalc
          and p.citizenryid = s.id
          and p.DATEOFDISMISSLA is not null
          and p.DATEOFDISMISSLA between ddism_bgn and ddism_end
          and s.statuscitizen = '4'
          and e.citizenryid = s.id
          and e.hidedate = (select max(x.hidedate) from EDUCATIONCIT x where x.citizenryid = e.citizenryid)
          and e.leveleducation in ('2','3','4','5','6','8');

       -- добавляем запись в первую таблица
       nreg_all      := COALESCE(nreg_all, 0);
       out_org       := COALESCE(out_org, 0);
       in_org        := COALESCE(in_org, 0);
	   timeout       := COALESCE(timeout, 0);
       health        := COALESCE(health, 0);
       family_drama  := COALESCE(family_drama, 0);
       others        := COALESCE(others, 0);
       insert into REGAGS(lid, uid, calctabagsid, feddisid, regiondirid, person_on, permanent_residents_rus, permanent_residents_not_rus, circumstances_others, health, end_service, circumstances_family)
                   values(rCalctabags.lid, rCalctabags.uid, rCalctabags.Id, rg.districtfederal, rg.id, nreg_all, in_org, out_org, others, health, timeout, family_drama);

      for voz in 0..2
      loop
      for ed in 1..7
      loop
      --для таблицы 2
      select
       (select count(s.id)
          from citizenry s,
               regiondir r,
               EDUCATIONCIT e
         where r.id = s.regiondirid
           and r.id = rg.id
         and r.districtfederal::integer != 9
         and s.conscription = PERCALC
         and s.yearconscription = yearcalc
         and (split_part(age(now(),s.birthdate)::text,' ',1)::integer>=18 and 20 >= split_part(age(now(),s.birthdate)::text,' ',1)::integer and voz = 0
          or split_part(age(now(),s.birthdate)::text,' ',1)::integer>=21 and 25 >= split_part(age(now(),s.birthdate)::text,' ',1)::integer and voz = 1
          or split_part(age(now(),s.birthdate)::text,' ',1)::integer>=26 and voz = 2
          --or voz = 1 and split_part(age(now(),s.birthdate)::text,' ',1)::integer>=18
          )
         and s.statuscitizen = '3'
         and e.citizenryid = s.id
         and e.hidedate = (select max(x.hidedate) from EDUCATIONCIT x where x.citizenryid = e.citizenryid)
         and (e.leveleducation = '2' and ed = 2
         or e.leveleducation = '3' and ed = 3
         or e.leveleducation = '4' and ed = 4
         or e.leveleducation = '5' and ed = 5
         or e.leveleducation = '6' and ed = 6
         or e.leveleducation = '8' and ed = 7
         or ed = 1 and e.leveleducation in ('2','3','4','5','6','8')) ) +
        (select count(s.id)
          from citizenry s,
               regiondir r,
               DIRECTION p,
			   ORGANIZATION o,
			   ORGANIZATIONDIR org,
               EDUCATIONCIT e
         where r.id = s.regiondirid
         and r.id = rg.id
         and r.districtfederal::integer != 9
         and s.conscription = PERCALC
         and s.yearconscription = yearcalc
         and o.id = p.organizationid
		 and org.id = o.organizationdirid
         and (split_part(age(now(),s.birthdate)::text,' ',1)::integer>=18 and 20 >= split_part(age(now(),s.birthdate)::text,' ',1)::integer and voz = 0
          or split_part(age(now(),s.birthdate)::text,' ',1)::integer>=21 and 25 >= split_part(age(now(),s.birthdate)::text,' ',1)::integer and voz = 1
          or split_part(age(now(),s.birthdate)::text,' ',1)::integer>=26 and voz = 2
          --or voz = 1 and split_part(age(now(),s.birthdate)::text,' ',1)::integer>=18
          )
		 and s.statuscitizen = '3'
         and p.citizenryid = s.id
         and e.citizenryid = s.id
         and e.hidedate = (select max(x.hidedate) from EDUCATIONCIT x where x.citizenryid = e.citizenryid)
         and (e.leveleducation = '2' and ed = 2
         or e.leveleducation = '3' and ed = 3
         or e.leveleducation = '4' and ed = 4
         or e.leveleducation = '5' and ed = 5
         or e.leveleducation = '6' and ed = 6
         or e.leveleducation = '8' and ed = 7
         or ed = 1 and e.leveleducation in ('2','3','4','5','6','8'))) -
        (select count(s.id)
          --into fire_ags
          from citizenry s,
               regiondir r,
               PASSAGEAGSCIT p,
               EDUCATIONCIT e
         where r.id = s.regiondirid
         and r.id = rg.id
           and r.districtfederal::integer != 9
           --and s.conscription = PERCALC
           --and s.yearconscription = yearcalc
           and p.citizenryid = s.id
           and (split_part(age(now(),s.birthdate)::text,' ',1)::integer>=18 and 20 >= split_part(age(now(),s.birthdate)::text,' ',1)::integer and voz = 0
           or split_part(age(now(),s.birthdate)::text,' ',1)::integer>=21 and 25 >= split_part(age(now(),s.birthdate)::text,' ',1)::integer and voz = 1
           or split_part(age(now(),s.birthdate)::text,' ',1)::integer>=26 and voz = 2
           --or voz = 1 and split_part(age(now(),s.birthdate)::text,' ',1)::integer>=18
           )
           and p.basis4 in ('1','2','5','6')
           and p.DATEOFDISMISSLA is not null
           and p.DATEOFDISMISSLA between ddism_bgn and ddism_end
           and s.statuscitizen = '4'
           and e.citizenryid = s.id
           and e.hidedate = (select max(x.hidedate) from EDUCATIONCIT x where x.citizenryid = e.citizenryid)
           and (e.leveleducation = '2' and ed = 2
           or e.leveleducation = '3' and ed = 3
           or e.leveleducation = '4' and ed = 4
           or e.leveleducation = '5' and ed = 5
           or e.leveleducation = '6' and ed = 6
           or e.leveleducation = '8' and ed = 7
           or ed = 1 and e.leveleducation in ('2','3','4','5','6','8'))
         limit 1)
         into ends;
         if ed = 1 THEN
           nreg_all:=ends;
         elsif ed = 2 THEN
           nreg_all:=ends;
         elsif ed = 3 THEN
           out_org:=ends;
         elsif ed = 4 THEN
           in_org:=ends;
         elsif ed = 5 THEN
           fire_ags:=ends;
         elsif ed = 6 THEN
           timeout:=ends;
         elsif ed = 7 THEN
           health:=ends;
         end if;

      end loop;
        insert into REGAGSEDUC(lid, uid, calctabagsid, feddisid, regiondirid,
        educage, -- 'Возраст';
		educ_no, -- 'Отсутствие образования';
	    educ_bgn_gen, -- 'Начальное общее';
		educ_main_gen, -- 'Основное общее';
		educ_mdl_full_gen, -- 'Среднее(полное) общее';
		educ_bgn_prof, -- 'Начальное профессиональное';
		educ_mdl_prof, -- 'Среднее профессиональное';
		educ_hgh_prof -- 'Высшее профессиональное';
        )
        values(rCalctabags.lid, rCalctabags.uid, rCalctabags.Id, rg.districtfederal, rg.id, voz, 0, nreg_all, out_org, in_org, fire_ags, timeout, health);
      end loop;
     end loop;

     -- смена статуса
     update calctabags s set statuscalc = sSTATUSCALC where s.id = rCalctabags.Id;
   end if;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_calctabags_calc (yearcalc integer, percalc text, recreate boolean, uid bigint)
  OWNER TO magicbox;