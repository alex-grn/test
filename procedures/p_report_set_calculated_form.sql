CREATE OR REPLACE FUNCTION public.p_report_set_calculated_form (
  id bigint
)
RETURNS void AS
$body$
declare
  nID bigint:=ID;
  rec record; 
  sp  record; 
  idx numeric;
  sELECTNAME text;
  --константы листа "Настройки ТИК"
  SHEET_OPTIONS_TIK             constant text := 'Настройки ТИК';
  OPTTIK_CELL_SUB_RF            constant text := 'sub_rf';
  OPTTIK_CELL_TER_KOM           constant text := 'ter_kom';
  OPTTIK_CELL_DOPPAY_CHRMN      constant text := 'dop_pay_chairman';
  OPTTIK_CELL_DOPPAY_PRCHRMN    constant text := 'dop_pay_prchairman';
  OPTTIK_CELL_DOPPAY_SCRT       constant text := 'dop_pay_secret';
  OPTTIK_CELL_NAME_CHOICE       constant text := 'name_choice';
  OPTTIK_CELL_MFIN              constant text := 'mfin';
  OPTTIK_CELL_DOF_CHOICE        constant text := 'date_of_choice';
  OPTTIK_CELL_BDATE_IK          constant text := 'bdate_ik';
  OPTTIK_CELL_WORK_DAY1         constant text := 'work_day1';
  OPTTIK_CELL_WORK_DAY2         constant text := 'work_day2';
  OPTTIK_CELL_R_COEF            constant text := 'r_coef';
  OPTTIK_CELL_PK_TIK            constant text := 'ПК_ТИК';
  OPTTIK_CELL_CHOISER           constant text := 'choiser';
  OPTTIK_CELL_ROD_TIK           constant text := 'rod_tik';
  OPTTIK_CELL_DAT_TIK           constant text := 'dat_tik';
  OPTTIK_CELL_TV_TIK            constant text := 'tv_tik';
  OPTTIK_CELL_CODE_DOC          constant text := 'code_doc';
  OPTTIK_CELL_EDATE_IK          constant text := 'edate_ik';
  OPTTIK_CELL_LEVEL_CAMP        constant text := 'level_camp';
  OPTTIK_CELL_DOPPAY_OTHRMAN    constant text := 'dop_pay_otherman';
  OPTTIK_CELL_COUNT_W           constant text := 'count_w';
  OPTTIK_CELL_ID_SUBRF          constant text := 'id_subrf';
  OPTTIK_CELL_ID_TER            constant text := 'id_ter';
  OPTTIK_CELL_ID_DOC            constant text := 'id_doc';
  OPTTIK_CELL_ID_CHOISE         constant text := 'id_choise';
  
  --константы листа "Настройки УИК"
  SHEET_OPTIONS_UIK             constant text := 'Настройки УИК';
  OPTUIK_CELL_NAME_IK           constant text := 'name_ik';
  OPTUIK_CELL_ROD_UIK           constant text := 'rod_uik';
  OPTUIK_CELL_DAT_UIK           constant text := 'dat_uik';
  OPTUIK_CELL_TV_UIK            constant text := 'tv_uik';
  OPTUIK_CELL_NUM_IK            constant text := 'num_ik';
  OPTUIK_CELL_COUNT_IK          constant text := 'count_ik';
  OPTUIK_CELL_ID_IK             constant text := 'id_ik';
  
  line_uik                      constant text := 'uik_line';
  OPTUIK_L_CELL_FIO_UIK         constant text := 'fio_uik';
  OPTUIK_L_CELL_BDATE1          constant text := 'bdate1';
  OPTUIK_L_CELL_EDATE1          constant text := 'edate1';
  OPTUIK_L_CELL_AVG_SUM1        constant text := 'avg_sum1';
  OPTUIK_L_CELL_POST1           constant text := 'post1';
  OPTUIK_L_CELL_ID_FIO1         constant text := 'id_fio1';
  
  --константы листа "Смета"
  SHEET_OPTIONS_SM              constant text := 'Смета';
  line_smet                     constant text := 'line_smet';
  OPTSM_L_CELL_SM_PP            constant text := 'sm_pp';
  OPTSM_L_CELL_SM_RASHOD        constant text := 'sm_rashod';
  OPTSM_L_CELL_SM_SUMM          constant text := 'sm_summ';
  OPTSM_L_CELL_SM_SUMM1         constant text := 'sm_summ1';
  OPTSM_L_CELL_SM_ID_RASHOD     constant text := 'sm_id_rashod';
  OPTSM_L_CELL_SM_TYPER         constant text := 'sm_typer';
  
  --константы листа "График работы"
  SHEET_OPTIONS_GR              constant text := 'График работы';
  line_gr                       constant text := 'gr_line';
  OPTGR_L_CELL_GR_DATE          constant text := 'gr_date';
  OPTGR_L_CELL_GR_TYPE          constant text := 'gr_type';
  
  --константы листа "Сведения ФОВ"
  SHEET_OPTIONS_SF              constant text := 'Сведения ФОВ';
  line_sf                       constant text := 'line_sf';
  OPTSF_L_CELL_SF_DATE          constant text := 'sf_date';
  OPTSF_L_CELL_SF_TYPE          constant text := 'sf_type';
  
  --константы листа "Фактические расходы"
  SHEET_OPTIONS_FR              constant text := 'Фактические расходы';
  line_fr                       constant text := 'line_fr';
  OPTFR_L_CELL_FR_PP            constant text := 'fr_pp';
  OPTFR_L_CELL_FR_RASHOD        constant text := 'fr_rashod';
  OPTFR_L_CELL_FR_NUMB          constant text := 'fr_numb';
  OPTFR_L_CELL_FR_TYPER         constant text := 'fr_typer';
 
begin
  perform p_excel_prepare();
  /* Настройки ТИК */
  perform p_excel_sheet_select(SHEET_OPTIONS_TIK);
  perform p_excel_cell_describe(OPTTIK_CELL_SUB_RF        );
  perform p_excel_cell_describe(OPTTIK_CELL_TER_KOM       );
  perform p_excel_cell_describe(OPTTIK_CELL_DOPPAY_CHRMN  );
  perform p_excel_cell_describe(OPTTIK_CELL_DOPPAY_PRCHRMN);
  perform p_excel_cell_describe(OPTTIK_CELL_DOPPAY_SCRT   );
  perform p_excel_cell_describe(OPTTIK_CELL_NAME_CHOICE   );
  perform p_excel_cell_describe(OPTTIK_CELL_MFIN          );
  perform p_excel_cell_describe(OPTTIK_CELL_DOF_CHOICE    );
  perform p_excel_cell_describe(OPTTIK_CELL_BDATE_IK      );
  perform p_excel_cell_describe(OPTTIK_CELL_WORK_DAY1     );
  perform p_excel_cell_describe(OPTTIK_CELL_WORK_DAY2     );
  perform p_excel_cell_describe(OPTTIK_CELL_R_COEF        );
  perform p_excel_cell_describe(OPTTIK_CELL_PK_TIK        );
  perform p_excel_cell_describe(OPTTIK_CELL_CHOISER       );
  perform p_excel_cell_describe(OPTTIK_CELL_ROD_TIK       );
  perform p_excel_cell_describe(OPTTIK_CELL_DAT_TIK       );
  perform p_excel_cell_describe(OPTTIK_CELL_TV_TIK        );
  perform p_excel_cell_describe(OPTTIK_CELL_CODE_DOC      );
  perform p_excel_cell_describe(OPTTIK_CELL_EDATE_IK      );
  perform p_excel_cell_describe(OPTTIK_CELL_LEVEL_CAMP    );
  perform p_excel_cell_describe(OPTTIK_CELL_DOPPAY_OTHRMAN);
  perform p_excel_cell_describe(OPTTIK_CELL_COUNT_W       );
  perform p_excel_cell_describe(OPTTIK_CELL_ID_SUBRF      );
  perform p_excel_cell_describe(OPTTIK_CELL_ID_TER        );
  perform p_excel_cell_describe(OPTTIK_CELL_ID_DOC        );
  perform p_excel_cell_describe(OPTTIK_CELL_ID_CHOISE     );
  
  
  for rec in
       select reg.name as sub_rf,
                      reg.code as id_subrf,
                      case  
                          when ik.levelelcommittee = 'district' then (select kk.name from ELECTCOMMITTEE kk where kk.idgasecom = ik.idgasparecom)
                          when ik.levelelcommittee = 'territory' or ik.levelelcommittee = 'circuit' then ik.name 
                      end as ter_kom,
                      case  
                          when ik.levelelcommittee = 'district' then (select kk.code from ELECTCOMMITTEE kk where kk.idgasecom = ik.idgasparecom)
                          when ik.levelelcommittee = 'territory' or ik.levelelcommittee = 'circuit' then ik.code 
                      end as id_ter,
                      e.name as name_choice,
                      e.code as id_choise,
                      d2s(e.electdate) as date_of_choice,
                      d2s(r.begindate) as bdate_ik,
                      d2s(r.enddate) as edate_ik,
                      (select xl.COUNTWD from (select w.COUNTWD, row_number() OVER(order by w.code) as sort from (select rrs.* from registerlist rrs where rrs.registerid = r.id limit 1) rs, COMMITTEEMAN cc, pays pl, slcompcharges sl, workcalendars w where cc.id = rs.committeemanid and pl.registerlistid = rs.id and sl.id = pl.slcompchargesid and sl.description = 'COMPENSATION' and w.id = pl.workcalendarsid order by w.code) xl where xl.sort = 1) as work_day1, 
                      (select xl.COUNTWD from (select w.COUNTWD, row_number() OVER(order by w.code) as sort from (select rrs.* from registerlist rrs where rrs.registerid = r.id limit 1) rs, COMMITTEEMAN cc, pays pl, slcompcharges sl, workcalendars w where cc.id = rs.committeemanid and pl.registerlistid = rs.id and sl.id = pl.slcompchargesid and sl.description = 'COMPENSATION' and w.id = pl.workcalendarsid order by w.code) xl where xl.sort = 2) as work_day2,
                      fk.value as compensation, --федеральная, а для региональной название колонки будет compensation_other
                      ik.discoefffed as r_coef, --федеральный коэффициент, для региона discoefreg 
                      fn.value as max_v_coef,   --предельный размер коффициента
                      f1.value as dop_pay_chairman,
                      f2.value as dop_pay_prchairman,
                      f3.value as dop_pay_secret,
                      f4.value as dop_pay_otherman,
                      case (select rs.leveldcchairman from registerlist rs, committeeman cc, posts p where rs.registerid = r.id and cc.id = rs.committeemanid and p.id = cc.postsid and upper(p.postprint) = 'CHAIRMAN' and p.levelelcommittee = 'district')
                          when 'territory' then 'ТИК'
                          when 'district' then 'УИК'
                          when 'region' then 'ИКСРФ'
                          when 'circuit' then 'ИКМО с полномочиями ТИК'
                      end as choiser,
                      case  
                          when ik.levelelcommittee = 'district' then (select kk.rnameec from ELECTCOMMITTEE kk where kk.idgasecom = ik.idgasparecom)
                          when ik.levelelcommittee = 'territory' or ik.levelelcommittee = 'circuit' then ik.rnameec 
                      end as rod_tik,
                      case  
                          when ik.levelelcommittee = 'district' then (select kk.dnameec from ELECTCOMMITTEE kk where kk.idgasecom = ik.idgasparecom)
                          when ik.levelelcommittee = 'territory' or ik.levelelcommittee = 'circuit' then ik.dnameec 
                      end as dat_tik,
                      case 
                          when ik.levelelcommittee = 'district' then (select kk.tnameec from ELECTCOMMITTEE kk where kk.idgasecom = ik.idgasparecom)
                          when ik.levelelcommittee = 'territory' or ik.levelelcommittee = 'circuit' then ik.tnameec 
                      end as tv_tik,
      case m.mfin when '1' then 'участник зарплатного проекта' when '2' then 'не участник зарплатного проекта' when '3' then 'участник зарплатного проекта и подотчетное лицо' end as mfin,
      case e.levelelcampaign when 'central' then 'федеральные выборы' else 'региональные, муниципальные выборы' end as level_campaign,
                      r.code as code_doc,
                      r.code as id_doc,
                      (select count(*)
                          from registerlist rs,
                               committeeman c,
                               posts p,
                               worktbl w
                         where rs.registerid = r.id
                           and c.id = rs.committeemanid
                           and p.id = c.postsid
                           and lower(p.postprint) = 'chairman'
                           and w.registerlistid = rs.id
                           and r.begindate = w.datetbl) as count_w
				from register r			--Расчетные документы
					inner join electcommincamp el on el.id = r.electcommincampid	--Избирательные комиссии, участвующие в кампании
					inner join ELECTCOMMITTEE IK on ik.id = el.electcommitteeid	--Избирательные комиссии
					inner join electcampaign e on e.id = r.electcampaignid		--Избирательные кампании
					inner join regionsrf reg on reg.id = ik.regionsrfid		--Субъекты Российской Федерации
					left join FEDELECCAMP f on f.id = e.fedeleccampid		--Федеральные избирательные кампании
					left join MFIN m on m.ELECTCOMMITTEEID = ik.id		--Порядок финансирования
					left join NORMSFEDEC fk on fk.fedeleccampid = f.id
											and fk.namenorms = 'limitcomp'  --Предельный размер компенсации за полный месяц работы для региона
											and fk.regionsrfid = reg.id	--Нормы оплаты труда при проведении федеральных выборов (для компенсации)
					left join NORMSFEDEC fn on fn.fedeleccampid = f.id
											and fn.namenorms = 'depcoeffmax'  --Предельный размер компенсации за полный месяц работы для региона
					left join NORMSFEDEC f1 on f1.fedeleccampid = f.id
                                              and f1.namenorms = 'reward'  --Предельный размер компенсации за полный месяц работы для региона
                                              and f1.postsid = (select p.id from posts p where upper(p.postprint) = 'CHAIRMAN' and p.levelelcommittee = ik.levelelcommittee)
                                              and f1.mcircuit = el.mcircuit
                      left join NORMSFEDEC f2 on f2.fedeleccampid = f.id
                                              and f2.namenorms = 'reward'  --Размер дополнительной оплаты труда (вознаграждения) за один час работы в будние дни с 6.00 до 22.00
                                              and f2.postsid = (select p.id from posts p where upper(p.postprint) = 'DEPCHAIRMAN' and p.levelelcommittee = ik.levelelcommittee)
                                              and f2.mcircuit = el.mcircuit
                      left join NORMSFEDEC f3 on  f3.fedeleccampid = f.id
                                              and f3.namenorms = 'reward'  --Размер дополнительной оплаты труда (вознаграждения) за один час работы в будние дни с 6.00 до 22.00
                                              and f3.postsid = (select p.id from posts p where upper(p.postprint) = 'SECRETARY' and p.levelelcommittee = ik.levelelcommittee)
                                              and f3.mcircuit = el.mcircuit
                      left join NORMSFEDEC f4 on  f4.fedeleccampid = f.id
                                              and f4.namenorms = 'reward'  --Размер дополнительной оплаты труда (вознаграждения) за один час работы в будние дни с 6.00 до 22.00
                                              and f4.postsid = (select p.id from posts p where upper(p.postprint) = 'ZOTHERCM' and p.levelelcommittee = ik.levelelcommittee)
                                              and f4.mcircuit = el.mcircuit
				where e.electdate >= m.begindate and (m.enddate >= e.electdate or m.enddate is null) and r.id = nID
  loop
  
      perform p_excel_cell_value_write(OPTTIK_CELL_SUB_RF          , rec.sub_rf);
      perform p_excel_cell_value_write(OPTTIK_CELL_TER_KOM         , rec.ter_kom);
      perform p_excel_cell_value_write(OPTTIK_CELL_DOPPAY_CHRMN    , rec.dop_pay_chairman);
      perform p_excel_cell_value_write(OPTTIK_CELL_DOPPAY_PRCHRMN  , rec.dop_pay_prchairman);
      perform p_excel_cell_value_write(OPTTIK_CELL_DOPPAY_SCRT     , rec.dop_pay_secret);
      perform p_excel_cell_value_write(OPTTIK_CELL_NAME_CHOICE     , rec.name_choice);
      perform p_excel_cell_value_write(OPTTIK_CELL_MFIN            , rec.mfin);
      perform p_excel_cell_value_write(OPTTIK_CELL_DOF_CHOICE      , rec.date_of_choice);
      perform p_excel_cell_value_write(OPTTIK_CELL_BDATE_IK        , rec.bdate_ik);
      perform p_excel_cell_value_write(OPTTIK_CELL_WORK_DAY1       , rec.work_day1);
      perform p_excel_cell_value_write(OPTTIK_CELL_WORK_DAY2       , rec.work_day2);
      perform p_excel_cell_value_write(OPTTIK_CELL_R_COEF          , rec.r_coef);
      perform p_excel_cell_value_write(OPTTIK_CELL_PK_TIK          , rec.max_v_coef);
      perform p_excel_cell_value_write(OPTTIK_CELL_CHOISER         , rec.choiser);
      perform p_excel_cell_value_write(OPTTIK_CELL_ROD_TIK         , rec.rod_tik);
      perform p_excel_cell_value_write(OPTTIK_CELL_DAT_TIK         , rec.dat_tik);
      perform p_excel_cell_value_write(OPTTIK_CELL_TV_TIK          , rec.tv_tik);
      perform p_excel_cell_value_write(OPTTIK_CELL_CODE_DOC        , rec.code_doc);
      perform p_excel_cell_value_write(OPTTIK_CELL_EDATE_IK        , rec.edate_ik);
      perform p_excel_cell_value_write(OPTTIK_CELL_LEVEL_CAMP      , rec.level_campaign);
      perform p_excel_cell_value_write(OPTTIK_CELL_DOPPAY_OTHRMAN  , rec.dop_pay_otherman);
      perform p_excel_cell_value_write(OPTTIK_CELL_COUNT_W         , rec.count_w);
      perform p_excel_cell_value_write(OPTTIK_CELL_ID_SUBRF        , rec.id_subrf);
      perform p_excel_cell_value_write(OPTTIK_CELL_ID_TER          , rec.id_ter);
      perform p_excel_cell_value_write(OPTTIK_CELL_ID_DOC          , rec.id_doc);
      perform p_excel_cell_value_write(OPTTIK_CELL_ID_CHOISE       , rec.id_choise);
      
  end loop;
  
   /* Настройки УИК */
  
  perform p_excel_sheet_select(SHEET_OPTIONS_UIK);
  perform p_excel_cell_describe(OPTUIK_CELL_NAME_IK    );
  perform p_excel_cell_describe(OPTUIK_CELL_ROD_UIK    );
  perform p_excel_cell_describe(OPTUIK_CELL_DAT_UIK    );
  perform p_excel_cell_describe(OPTUIK_CELL_TV_UIK     );
  perform p_excel_cell_describe(OPTUIK_CELL_NUM_IK     );
  perform p_excel_cell_describe(OPTUIK_CELL_COUNT_IK   );
  perform p_excel_cell_describe(OPTUIK_CELL_ID_IK      );
  perform p_excel_line_describe(line_uik);
  perform p_excel_line_cell_describe(line_uik, OPTUIK_L_CELL_FIO_UIK );
  perform p_excel_line_cell_describe(line_uik, OPTUIK_L_CELL_BDATE1  );
  perform p_excel_line_cell_describe(line_uik, OPTUIK_L_CELL_EDATE1  );
  perform p_excel_line_cell_describe(line_uik, OPTUIK_L_CELL_AVG_SUM1);
  perform p_excel_line_cell_describe(line_uik, OPTUIK_L_CELL_POST1   );
  perform p_excel_line_cell_describe(line_uik, OPTUIK_L_CELL_ID_FIO1 );
  
  for rec in 
    select IK.name as name_ik,
			IK.CODE AS id_ik,
			ik.elecdistnumb as num_ik,
			i.countvtr as count_ik,
			ik.rnameec as rod_uik,
			ik.dnameec as dat_uik,
			ik.tnameec as tv_uik
		from register r
		inner join electcampaign el on el.id = r.electcampaignid
		inner join electcommincamp i on i.id = r.electcommincampid
		inner join electcommittee ik on ik.id = i.electcommitteeid 
		left join mfin m on m.electcommitteeid = ik.id and now() >= m.begindate and (m.enddate >=now() or m.enddate is null) and m.mfin::integer in (1,3)
		where r.id = nID
   loop
        perform p_excel_cell_value_write(OPTUIK_CELL_NAME_IK , rec.name_ik);
        perform p_excel_cell_value_write(OPTUIK_CELL_ROD_UIK , rec.rod_uik);
        perform p_excel_cell_value_write(OPTUIK_CELL_DAT_UIK , rec.dat_uik);
        perform p_excel_cell_value_write(OPTUIK_CELL_TV_UIK  , rec.tv_uik);
        perform p_excel_cell_value_write(OPTUIK_CELL_NUM_IK  , rec.num_ik);
        perform p_excel_cell_value_write(OPTUIK_CELL_COUNT_IK, rec.count_ik);
        perform p_excel_cell_value_write(OPTUIK_CELL_ID_IK   , rec.id_ik);
   end loop;
  
  
   for rec in								
		select COALESCE(k.surname,'')||' '||COALESCE(k.firstname,'')||' '||COALESCE(k.middlename,'') as FIO_UIK, 
               case p.POSTPRINT 
                  when 'CHAIRMAN' then 'Председатель' 
                  when 'DEPCHAIRMAN' then 'Заместитель председателя' 
                  when 'SECRETARY' then 'Секретарь' 
                  when 'ZOTHERCM' then 'Член комиссии' 
               end as POST1,
               d2s(m.POSTBEGINDATE) as BDATE1,
               d2s(m.POSTENDDATE) as EDATE1,
               COALESCE(r.middlesalary,'0') as AVG_SUM1,
               M.CODE as ID_FIO1,
               m.POSTBEGINDATE
          from registerlist r,
               committeeman m,
               posts p,
               person k
         where r.registerid = nID
           and m.id = r.committeemanid
           and p.id = m.postsid
           and k.id = m.personid
         union 
        select null,'zzz',null,null,null,null,g
          from generate_series(s2d('01.01.5000'),s2d('18.01.5000'), '1 day') g
         order by postbegindate, POST1
         limit 18
   loop
        rec.POST1:=nullif(rec.POST1,'zzz');
        idx := p_excel_line_append(line_uik);
        perform p_excel_cell_value_write(OPTUIK_L_CELL_FIO_UIK , 0, idx, COALESCE(rec.FIO_UIK,' '));
        perform p_excel_cell_value_write(OPTUIK_L_CELL_BDATE1  , 0, idx, COALESCE(rec.BDATE1,' '));
        perform p_excel_cell_value_write(OPTUIK_L_CELL_EDATE1  , 0, idx, COALESCE(rec.EDATE1,' '));
        perform p_excel_cell_value_write(OPTUIK_L_CELL_AVG_SUM1, 0, idx, COALESCE(rec.AVG_SUM1::text,' '));
        perform p_excel_cell_value_write(OPTUIK_L_CELL_POST1   , 0, idx, COALESCE(rec.POST1,' '));
        perform p_excel_cell_value_write(OPTUIK_L_CELL_ID_FIO1 , 0, idx, COALESCE(rec.ID_FIO1,' '));
   end loop;
   perform p_excel_line_delete(line_uik);
  
  /*Смета*/
  
  perform p_excel_sheet_select(SHEET_OPTIONS_SM);
  perform p_excel_line_describe(line_smet);
  perform p_excel_line_cell_describe(line_smet, OPTSM_L_CELL_SM_PP );
  perform p_excel_line_cell_describe(line_smet, OPTSM_L_CELL_SM_RASHOD  );
  perform p_excel_line_cell_describe(line_smet, OPTSM_L_CELL_SM_SUMM  );
  perform p_excel_line_cell_describe(line_smet, OPTSM_L_CELL_SM_SUMM1    );
  perform p_excel_line_cell_describe(line_smet, OPTSM_L_CELL_SM_ID_RASHOD);
  perform p_excel_line_cell_describe(line_smet, OPTSM_L_CELL_SM_TYPER    );
  
  for rec in
       select t.numbestimate as pp, t.tcode as rashod,  t.tcode as id_rashod, t.typeestimate as typer,  s.summ, row_number() over(order by t.numbpp) as numb
            from (select t.numbestimate, string_agg(rf.idgasregionsrf,';') as regcode,
                         t.print_name as tcode, t.typeestimate, MAX(t.numbpp) as numbpp, fl.name as foldername
                    from TYPEEXP T,
                         REGIONSRF Rf,
                         folders fl
                   where not t.mestimate
                     and t.numbestimate not ilike '%АПУ%'
                     and rf.id = t.regionsrfid
                     and fl.id = t.hid
                  group by t.numbestimate, t.print_name, t.typeestimate, fl.name) T
            left join 
              (select case when (mf.mfin = '1' or mf.mfin = '3') then case when not f.typeexpid is null and tp.typeestimate = 'П' then COALESCE(f.sumfintikcen,0)+COALESCE(f.sumfinuik,0) else null end 
				else case when not f.typeexpid is null then COALESCE(f.sumfintikcen,0)+COALESCE(f.sumfinuik,0) else null end end   as summ, 
				rr.idgasregionsrf, tp.numbestimate, ec.levelelcampaign
                 from FOLDERS fol, TYPEEXP tp left join FINANCEELCOM f on f.typeexpid = tp.id, REGISTER r 
            left join ELECTCOMMINCAMP e on e.id = r.electcommincampid
            left join ELECTCOMMITTEE ik on ik.id = e.electcommitteeid
            left join MFIN mf on mf.ELECTCOMMITTEEID = ik.id
            left join REGIONSRF rr on rr.id = ik.regionsrfid
            left join ELECTCAMPAIGN ec on ec.id = e.electcampaignid
            where r.id = nID 
					    and fol.tablename='typeexp'
					    and (f.electcommincampid=r.electcommincampid or f.electcommincampid is null)
                        and tp.hid = (select case when ec.levelelcampaign = 'central' then (select ff.id from folders ff where ff.tablename='typeexp' and ff.name like '%Федерал%') else (select ff.id from folders ff where ff.tablename='typeexp' and ff.name like '%Регионал%') end as value)
                        and ec.electdate >= mf.begindate and (mf.enddate >= ec.electdate or mf.enddate is null)
                       group by tp.numbestimate, rr.idgasregionsrf, ec.levelelcampaign, f.typeexpid, tp.typeestimate, mf.mfin, f.sumfintikcen, f.sumfinuik) s on s.numbestimate = t.numbestimate
                       where (t.regcode ilike '%'||(select rf.idgasregionsrf
                                                    from register r,
                                                         ELECTCOMMINCAMP e,
                                                         ELECTCOMMITTEE ik,
                                                         REGIONSRF rf
                                                  where r.id = nID
                                                    and e.id = r.electcommincampid
                                                    and ik.id = e.electcommitteeid
                                                    and rf.id = ik.regionsrfid)||'%' or t.regcode ilike '%00%')
                         and (s.levelelcampaign ilike 'region' and t.foldername ilike '%Регион%' 
                           Or s.levelelcampaign not ilike 'region' and t.foldername ilike '%Федер%')
                       order by t.numbpp 
  loop
       idx := p_excel_line_append(line_smet);
       perform p_excel_cell_value_write(OPTSM_L_CELL_SM_PP     , 0, idx,    rec.pp);
       perform p_excel_cell_value_write(OPTSM_L_CELL_SM_RASHOD , 0, idx,    COALESCE(rec.rashod,' '));
       perform p_excel_cell_value_write(OPTSM_L_CELL_SM_SUMM   , 0, idx,    rec.summ); 
       perform p_excel_cell_value_write(OPTSM_L_CELL_SM_SUMM1     , 0, idx, rec.summ);
       perform p_excel_cell_value_write(OPTSM_L_CELL_SM_ID_RASHOD , 0, idx, rec.id_rashod);
       perform p_excel_cell_value_write(OPTSM_L_CELL_SM_TYPER   , 0, idx,   COALESCE(rec.typer,' '));
  
  end loop;
  perform p_excel_line_delete(line_smet);
  
  /*График работы*/
  
  perform p_excel_sheet_select(SHEET_OPTIONS_GR);
  perform p_excel_line_describe(line_gr);
  perform p_excel_line_cell_describe(line_gr, OPTGR_L_CELL_GR_DATE );
  perform p_excel_line_cell_describe(line_gr, OPTGR_L_CELL_GR_TYPE );
         
  for rec in
    select d2s(w.datetbl) as dates, t.code 
      from registerlist r
     inner join worktbl w on w.registerlistid = r.id
      left join typedays t on t.id = w.typedayid
     where r.registerid = nID
     group by w.datetbl, t.code
     order by dates
  loop
     idx := p_excel_line_append(line_gr);
     perform p_excel_cell_value_write(OPTGR_L_CELL_GR_DATE , 0, idx, COALESCE(rec.dates,' '));
     perform p_excel_cell_value_write(OPTGR_L_CELL_GR_TYPE , 0, idx, COALESCE(rec.code,' '));
  end loop;              
  perform p_excel_line_delete(line_gr);   
   
  /*Сведения ФОВ*/
   
  perform p_excel_sheet_select(SHEET_OPTIONS_SF);
  perform p_excel_line_describe(line_sf);
  perform p_excel_line_cell_describe(line_sf, OPTSF_L_CELL_SF_DATE );
  perform p_excel_line_cell_describe(line_sf, OPTSF_L_CELL_SF_TYPE );
         
  for rec in
    select d2s(w.datetbl) as dates, t.code 
      from registerlist r
     inner join worktbl w on w.registerlistid = r.id
      left join typedays t on t.id = w.typedayid
     where r.registerid = nID
     group by w.datetbl, t.code
     order by dates
  loop
     idx := p_excel_line_append(line_sf);
     perform p_excel_cell_value_write(OPTSF_L_CELL_SF_DATE , 0, idx, COALESCE(rec.dates,' '));
     perform p_excel_cell_value_write(OPTSF_L_CELL_SF_TYPE , 0, idx, COALESCE(rec.code,' '));
  end loop;              
  perform p_excel_line_delete(line_sf); 
  
  /*Фактические расходы*/
  
  perform p_excel_sheet_select(SHEET_OPTIONS_FR);
  perform p_excel_line_describe(line_fr);
  perform p_excel_line_cell_describe(line_fr, OPTFR_L_CELL_FR_PP );
  perform p_excel_line_cell_describe(line_fr, OPTFR_L_CELL_FR_RASHOD );
  perform p_excel_line_cell_describe(line_fr, OPTFR_L_CELL_FR_NUMB );
  perform p_excel_line_cell_describe(line_fr, OPTFR_L_CELL_FR_TYPER);
  for rec in
       select t.numbestimate::text as pp, t.tcode as rashod,  t.tcode as id_rashod, t.typeestimate as typer,  s.summ, row_number() over(order by t.numbpp) as numb
              from (select t.numbestimate, string_agg(rf.idgasregionsrf,';') as regcode,
                           t.print_name as tcode, t.typeestimate, MAX(t.numbpp) as numbpp, fl.name as foldername
                      from TYPEEXP T,
                           REGIONSRF Rf,
                           folders fl
                     where not t.NOACTUAL_COST
                       and t.numbestimate not ilike '%АПУ%'
                       and rf.id = t.regionsrfid
                       and fl.id = t.hid
                    group by t.numbestimate, t.print_name, t.typeestimate, fl.name) T
              left join 
                (select case when (mf.mfin = '1' or mf.mfin = '3') then case when not f.typeexpid is null and tp.typeestimate = 'П' then COALESCE(f.sumfintikcen,0)+COALESCE(f.sumfinuik,0) else null end 
				else case when not f.typeexpid is null then COALESCE(f.sumfintikcen,0)+COALESCE(f.sumfinuik,0) else null end end   as summ, 
				rr.idgasregionsrf, tp.numbestimate, ec.levelelcampaign
                   from FOLDERS fol, TYPEEXP tp left join FINANCEELCOM f on f.typeexpid = tp.id, REGISTER r 
              left join ELECTCOMMINCAMP e on e.id = r.electcommincampid
              left join ELECTCOMMITTEE ik on ik.id = e.electcommitteeid
              left join MFIN mf on mf.ELECTCOMMITTEEID = ik.id
              left join REGIONSRF rr on rr.id = ik.regionsrfid
              left join ELECTCAMPAIGN ec on ec.id = e.electcampaignid
              where r.id = nID 
				and fol.tablename='typeexp'
				and (f.electcommincampid=r.electcommincampid or f.electcommincampid is null)
                and tp.hid = (select case when ec.levelelcampaign = 'central' then (select ff.id from folders ff where ff.tablename='typeexp' and ff.name like '%Федерал%') else (select ff.id from folders ff where ff.tablename='typeexp' and ff.name like '%Регионал%') end as value)
                and ec.electdate >= mf.begindate and (mf.enddate >= ec.electdate or mf.enddate is null)
                      group by tp.numbestimate, rr.idgasregionsrf, ec.levelelcampaign, f.typeexpid, tp.typeestimate, mf.mfin, f.sumfintikcen, f.sumfinuik) s on s.numbestimate = t.numbestimate
                      where (t.regcode ilike '%'||(select rf.idgasregionsrf
                                                     from register r,
                                                          ELECTCOMMINCAMP e,
                                                          ELECTCOMMITTEE ik,
                                                          REGIONSRF rf
                                                   where r.id = nID
                                                     and e.id = r.electcommincampid
                                                     and ik.id = e.electcommitteeid
                                                     and rf.id = ik.regionsrfid)||'%' or t.regcode ilike '%00%')
                        and (s.levelelcampaign ilike 'region' and t.foldername ilike '%Регион%' 
                          Or s.levelelcampaign not ilike 'region' and t.foldername ilike '%Федер%')
                      order by t.numbpp 
  loop
     idx := p_excel_line_append(line_fr);
     perform p_excel_cell_value_write(OPTFR_L_CELL_FR_PP     , 0, idx, COALESCE(rec.pp,' '));
     perform p_excel_cell_value_write(OPTFR_L_CELL_FR_RASHOD , 0, idx, COALESCE(rec.rashod,' '));
     perform p_excel_cell_value_write(OPTFR_L_CELL_FR_NUMB   , 0, idx, COALESCE(rec.numb::text,' '));
     perform p_excel_cell_value_write(OPTFR_L_CELL_FR_TYPER  , 0, idx, COALESCE(rec.typer,' '));
  end loop;              
  perform p_excel_line_delete(line_fr); 
  
  
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_report_set_calculated_form (id bigint)
  OWNER TO magicbox;