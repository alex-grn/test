CREATE OR REPLACE FUNCTION public.p_report_memorder (
  id bigint,
  memorderid bigint,
  begindate date,
  enddate date,
  print_typeexp boolean,
  gbpersonid bigint,
  postsid bigint,
  bpersonid bigint
)
RETURNS void AS
$body$
declare
  rDOC record;
  rACC record;/*Запись текущего счета (группировка 1)*/
  rGRP record;/*Запись текущего Юр.лица/Физ.лица/МОЛа (группировка 2)*/
  sPERIOD text;/*Период отчета для вывода в шапке*/
  sPROP text;
  nidx bigint;
  nidx_bgn bigint;
  nidx_end bigint;
  nACC_SP_COUNT bigint;/*Счетчик проводок для счета*/
  sprint_typeexp_sign text;/*Признак вывода направления расходов в проводках NULL или '' для склейки текста и управления видимостью*/
  nREST_BGN numeric;
  nREST_END numeric;
  bNULLREP boolean:=true;/*Признак пустого отчета для сообщения "Нет данных для печати"*/

  --константы настроек листа шаблона "Журнал операций"
  sSHEET               constant text := 'Журнал операций';
  sCELL_MEMORDERNUM    constant text := 'ЖурналНомер';
  sCELL_MEMORDERNAME   constant text := 'ЖурналНаименование';
  sCELL_DATE           constant text := 'Дата';
  sCELL_PERIOD         constant text := 'Период';
  sCELL_ORG            constant text := 'Учреждение';
  sCELL_UNIT           constant text := 'Подразделение';
  sCELL_BUDGET         constant text := 'Бюджет';
  sCELL_GBUH           constant text := 'Главбух';
  sCELL_BPOST          constant text := 'ИсполнительДолжность';
  sCELL_BPERS          constant text := 'ИсполнительПодпись';

  /*Основная спецификация*/
  sLINE_MAIN           constant text := 'СпецификацияОсновная';
  sCELL_LM_OPERDATE    constant text := 'ДатаОперации';
  sCELL_LM_DOCDATE     constant text := 'ДокументДата';
  sCELL_LM_DOCNUM      constant text := 'ДокументНомер';
  sCELL_LM_DOCNAME     constant text := 'ДокументНаименование';
  sCELL_LM_PROP        constant text := 'Показатель';
  sCELL_LM_NOTE        constant text := 'Содержание';
  sCELL_LM_REST_BGN_DB constant text := 'ОстатокНачалоДебет';
  sCELL_LM_REST_BGN_CR constant text := 'ОстатокНачалоКредит';
  sCELL_LM_ACC_DB      constant text := 'СчетДебет';
  sCELL_LM_ACC_CR      constant text := 'СчетКредит';
  sCELL_LM_SUM         constant text := 'Сумма';
  sCELL_LM_REST_END_DB constant text := 'ОстатокКонецДебет';
  sCELL_LM_REST_END_CR constant text := 'ОстатокКонецКредит';

  /*Спецификация оборотов для гл.книги*/
  sLINE_ALT            constant text := 'СпецификацияГлКнига';
  sCELL_LA_NOTE        constant text := 'ПримечаниеГлКнига';
  sCELL_LA_DB          constant text := 'ДебетГлКнига';
  sCELL_LA_CR          constant text := 'КредитГлКнига';
  sCELL_LA_SUM         constant text := 'СуммаГлКнига';


begin
  /*Общие настройки*/
  if print_typeexp
  then sprint_typeexp_sign:='';
  else sprint_typeexp_sign:=null;
  end if;
  --perform p_system_exception(0,'NULL'||sprint_typeexp_sign);

  /*Процедура для отчета "Журнал операций" [FD]*/
  perform p_excel_prepare();
  perform p_excel_sheet_select(sSHEET);

  /*Описание ячеек*/
  perform p_excel_cell_describe(sCELL_MEMORDERNUM);
  perform p_excel_cell_describe(sCELL_MEMORDERNAME);
  perform p_excel_cell_describe(sCELL_DATE);
  perform p_excel_cell_describe(sCELL_PERIOD);
  perform p_excel_cell_describe(sCELL_ORG);
  perform p_excel_cell_describe(sCELL_UNIT);
  perform p_excel_cell_describe(sCELL_BUDGET);
  perform p_excel_cell_describe(sCELL_GBUH);
  perform p_excel_cell_describe(sCELL_BPOST);
  perform p_excel_cell_describe(sCELL_BPERS);

  /*Основная спецификация*/
  perform p_excel_line_describe(sLINE_MAIN);
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_OPERDATE );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_DOCDATE );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_DOCNUM );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_DOCNAME );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_PROP );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_NOTE );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_BGN_DB );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_BGN_CR );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_ACC_DB );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_ACC_CR );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_SUM );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_END_DB );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_END_CR );

  /*Спецификация оборотов для гл.книги*/
  perform p_excel_line_describe(sLINE_ALT);
  perform p_excel_line_cell_describe(sLINE_ALT, sCELL_LA_NOTE );
  perform p_excel_line_cell_describe(sLINE_ALT, sCELL_LA_DB );
  perform p_excel_line_cell_describe(sLINE_ALT, sCELL_LA_CR );
  perform p_excel_line_cell_describe(sLINE_ALT, sCELL_LA_SUM );

  /*Цикл по текущему документу раздела "Журнал операций" для доступа к общим полям*/
  for rDOC in (SELECT t.id, t.electcampaignid, t.jurpersonsid,
                     c.name selectcampaign_name, /*Избирательная компания*/
                     /*Уровень избирательной кампании*/
                     case
                        when c.levelelcampaign='central' then 'Федеральный'
                        else 'Региональный'
                     end slevelelcampaign,
                     j.codejurpers sjurpersons_code, /*Принадлежность*/
                     (select m.code from memorder m where m.id=memorderid) sorder, /*Ордер*/
                     (select m.name from memorder m where m.id=memorderid) sorder_name, /*Наименование журнала*/
                     (select p.name from person p where p.id=gbpersonid)   sgbperson,/*Подпись для гл.буха*/
                     (select p.code from posts  p where p.id=postsid)      sposts,   /*Должность подписи для исполнителя*/
                     (select p.name from person p where p.id=bpersonid)    sbperson  /*Подпись для исполнителя*/

                FROM transactionlog t,
                     electcampaign c,
                     jurpersons j
               WHERE t.id=p_report_memorder.id
                 and c.id=t.electcampaignid
                 and j.id=t.jurpersonsid
             )
  loop
       /*Заголовок*/
       perform p_excel_cell_value_write(sCELL_MEMORDERNUM, rDOC.sorder);
       perform p_excel_cell_value_write(sCELL_MEMORDERNAME, rDOC.sorder_name);

       perform p_excel_cell_value_write(sCELL_DATE,  to_char(enddate,'dd.mm.yyyy'));

       /*Вычисляем период отчета, который будет либо месяц-год, либо с-по*/
       if (begindate=date_trunc('MONTH',begindate) /*begindate = началу месяца*/
          and
          enddate=(date_trunc('MONTH', begindate) + INTERVAL '1 MONTH - 1 day')::date)
       then/*Границы одного месяца*/
            sPERIOD:='за '||(ARRAY['январь','февраль','март','апрель','май','июнь','июль','август','сентябрь','октябрь','ноябрь','декабрь'])[to_char(CURRENT_DATE,'MM')::integer]||' '||to_char(CURRENT_DATE,'YYYY')||'г.';
       else sPERIOD:='за период с '||to_char(begindate,'dd.mm.yyyy')||' по '||to_char(enddate,'dd.mm.yyyy');
       end if;
       perform p_excel_cell_value_write(sCELL_PERIOD, sPERIOD);

       perform p_excel_cell_value_write(sCELL_ORG,    rDOC.selectcampaign_name);
       perform p_excel_cell_value_write(sCELL_UNIT,   rDOC.sjurpersons_code);
       perform p_excel_cell_value_write(sCELL_BUDGET, rDOC.slevelelcampaign);

       /*Подписи*/
       perform p_excel_cell_value_write(sCELL_GBUH,  rDOC.sgbperson);
       perform p_excel_cell_value_write(sCELL_BPOST, rDOC.sposts);
       perform p_excel_cell_value_write(sCELL_BPERS, rDOC.sbperson);
  end loop;

  /*Цикл по всем вариантам группировочных строк отчета (Счет без учета КОСГУ и Юр.лиц/Физ.лиц/МОЛ*/
  for rACC in (select p_get_acc_by_parts_code(m.nkfo::text,m.skps,m.sacc,NULL::text,'000'::text/*КОСГУ группы*/) sACCOUNT,
                      /*Остаток на начало*/
                      p_get_acc_rest(p_report_memorder.id, begindate, m.nKFO, m.nKPS, m.nACC, -1, -1, m.nAGENT_GRP, m.nPERSON_GRP, m.nMOL_GRP) nREST_BGN,
                      p_get_acc_rest(p_report_memorder.id, (enddate + INTERVAL '1 day')::date, m.nKFO, m.nKPS, m.nACC, -1, -1, m.nAGENT_GRP, m.nPERSON_GRP, m.nMOL_GRP) nREST_END,
                      m.*,
                      /*Признак первой подгруппы для счета*/
                      (array[1])[row_number() OVER(PARTITION by m.nKFO,/*КФО - id*/
                                                                m.sKPS,  /*КПС - код*/
                                                                m.sACC   /*Счет - код*/
                                        order by m.sGROUP /*Мнемокод подгруппы (Юр./Физ./МОЛ)*/
                      )] nFIRST_GRP,
                      /*Признак последней подгруппы для счета*/
                      (array[1])[row_number() OVER(PARTITION by m.nKFO,/*КФО - id*/
                                                                m.sKPS,  /*КПС - код*/
                                                                m.sACC   /*Счет - код*/
                                        order by m.sGROUP desc/*Мнемокод подгруппы (Юр./Физ./МОЛ)*/
                      )] nLAST_GRP

                 from (select /*Дебет*/
                              s.dtfinsecurity nKFO,     /*КФО - id*/
                              dacs.id         nKPS,     /*КПС - id*/
                              dacs.code       sKPS,     /*КПС - код*/
                              dt.id           nACC,     /*Счет - id*/
                              dt.accnumb      sACC,     /*Счет - код*/

                              /*Признаки группировки, обнуленные в случае ненадобности для мемориального ордера*/
                              case
                                when dmord.detail='2' then dagn.id /*Детализация по юр.лицу и физ.лицу (заполнено одно!?)*/
                                else -1 /*Любое значение*/
                              end             nAGENT_GRP,
                              case
                                when dmord.detail='1' then dprs.id /*Детализация по физ.лицу*/
                                when (dmord.detail='2' and dagn.id is null) then dprs.id /*Детализация по юр.лицу и физ.лицу (заполнено одно!?)*/
                                else -1 /*Любое значение*/
                              end             nPERSON_GRP,
                              case
                                when dmord.detail='3' then dm.id/*Детализация по МОЛ*/
                                else -1 /*Любое значение*/
                              end             nMOL_GRP,

                              /*Текстовое значение мнемокода поля для подгруппы согласно типу ордера счета (Юр/Физ/МОЛ)*/
                              case
                                when dmord.detail='1' then dprs.code /*Детализация по физ.лицу*/
                                when dmord.detail='2' then coalesce(nullif(dagn.code,''),dprs.code) /*Детализация по юр.лицу и физ.лицу (заполнено одно!?)*/
                                when dmord.detail='3' then dpm.code/*Детализация по МОЛ*/
                                else null
                              end             sGROUP,
                              dmord.detail    sDETAIL

                         from transactionlog t,
                              transactionlog_docs d,
                              transactionlog_stages s
                                 left join budgclass dacs on dacs.id=s.dtbudgclassid /*КПС-дебет*/
                                 left join dicaccs dt on dt.id=s.accountdtid /*Счет-дебет*/
                                 left join memorder dmord on dmord.id=dt.memorderid /*Мемориальный ордер счета-дебет*/
                                 left join typeexp dexp on dexp.id=s.dttypeexpid /*Направление расходов счета-дебет*/
                                 left join econclass dec on dec.id=s.dteconclassktid /*КОСГУ-дебет*/
                                 left join agent dagn on dagn.id=s.agentdtid /*Юр.лицо-дебет*/
                                 left join person dprs on dprs.id=s.persondtid /*Физ.лицо-дебет*/
                                 left join mtresponspers dm on dm.id=s.dtrespperson /*МОЛ-дебет*/
                                 left join person dpm on dpm.id=dm.personid /*Физ.лицо МОЛа-дебет*/

                        where t.id=p_report_memorder.id
                          and d.transactionlogid=t.id
                          and s.transactionlog_docsid=d.id

                          /*Проводки заданного мемориального ордера в дебете*/
                          and dt.memorderid=p_report_memorder.memorderid

                       union

                       select /*Кредит*/
                              s.ktfinsecurity nKFO,     /*КФО - id*/
                              kacs.id         nKPS,     /*КПС - id*/
                              kacs.code       sKPS,     /*КПС - код*/
                              kt.id           nACC,     /*Счет - id*/
                              kt.accnumb      sACC,     /*Счет - код*/

                              /*Признаки группировки, обнуленные в случае ненадобности для мемориального ордера*/
                              case
                                when kmord.detail='2' then kagn.id /*Детализация по юр.лицу и физ.лицу (заполнено одно!?)*/
                                else -1 /*Любое значение*/
                              end             nAGENT_GRP,
                              case
                                when kmord.detail='1' then kprs.id /*Детализация по физ.лицу*/
                                when (kmord.detail='2' and kagn.id is null) then kprs.id /*Детализация по юр.лицу и физ.лицу (заполнено одно!?)*/
                                else -1 /*Любое значение*/
                              end             nPERSON_GRP,
                              case
                                when kmord.detail='3' then km.id/*Детализация по МОЛ*/
                                else -1 /*Любое значение*/
                              end             nMOL_GRP,

                              /*Текстовое значение мнемокода поля для подгруппы согласно типу ордера счета (Юр/Физ/МОЛ)*/
                              case
                                when kmord.detail='1' then kprs.code /*Детализация по физ.лицу*/
                                when kmord.detail='2' then coalesce(nullif(kagn.code,''),kprs.code) /*Детализация по юр.лицу и физ.лицу (заполнено одно!?)*/
                                when kmord.detail='3' then kpm.code/*Детализация по МОЛ*/
                                else null
                              end             sGROUP,
                              kmord.detail    sDETAIL

                         from transactionlog t,
                              transactionlog_docs d,
                              transactionlog_stages s
                                 left join budgclass kacs on kacs.id=s.ktbudgclassid /*КПС-кредит*/
                                 left join dicaccs kt on kt.id=s.accountktid /*Счет-кредит*/
                                 left join memorder kmord on kmord.id=kt.memorderid /*Мемориальный ордер счета-кредит*/
                                 left join typeexp kexp on kexp.id=s.kttypeexpid /*Направление расходов счета-кредит*/
                                 left join econclass kec on kec.id=s.kteconclassktid /*КОСГУ-кредит*/
                                 left join agent kagn on kagn.id=s.agentktid /*Юр.лицо-кредит*/
                                 left join person kprs on kprs.id=s.personktid /*Физ.лицо-кредит*/
                                 left join mtresponspers km on km.id=s.ktrespperson /*Физ.лицо-кредит*/
                                 left join person kpm on kpm.id=km.personid /*Физ.лицо МОЛа-кредит*/

                        where t.id=p_report_memorder.id
                          and d.transactionlogid=t.id
                          and s.transactionlog_docsid=d.id

                          /*Проводки заданного мемориального ордера в кредите*/
                          and kt.memorderid=p_report_memorder.memorderid

                      ) m
                         /*Сортируем по счету и подгруппе*/
                order by m.nKFO,  /*КФО - id*/
                         m.sKPS,  /*КПС - код*/
                         m.sACC,  /*Счет - код*/
                         m.sGROUP /*Мнемокод подгруппы (Юр./Физ./МОЛ)*/
              )
  loop

       /*На первой группе счета с подгруппами выводим его заголовок общий с остатком*/
       if rACC.nFIRST_GRP=1 and rACC.sDETAIL in ('1','2','3')
       then
            /*Остаток по счету на начало периода*/
            nidx_bgn := p_excel_line_append(sLINE_MAIN);
            perform p_excel_cell_value_write(sCELL_LM_PROP , 0, nidx_bgn,    'Остаток на '||to_char(begindate,'dd.mm.yyyy'));
            perform p_excel_cell_value_write(sCELL_LM_NOTE , 0, nidx_bgn,    rACC.sACCOUNT);

            nREST_BGN:=p_get_acc_rest(p_report_memorder.id, begindate, rACC.nKFO, rACC.nKPS, rACC.nACC);
            if nREST_BGN>=0
            then
                 perform p_excel_cell_value_write(sCELL_LM_REST_BGN_DB , 0, nidx_bgn,    abs(nREST_BGN));
                 --perform p_excel_cell_value_write(sCELL_LM_REST_BGN_CR , 0, nidx_bgn,    0);
            else
                 --perform p_excel_cell_value_write(sCELL_LM_REST_BGN_DB , 0, nidx_bgn,    0);
                 perform p_excel_cell_value_write(sCELL_LM_REST_BGN_CR , 0, nidx_bgn,    abs(nREST_BGN));
            end if;

            /*Делаем шрифт жирным*/
            perform p_excel_cell_attribute_set(sCELL_LM_PROP , 0, nidx_bgn, 'Font.FontStyle', 'Bold');
            perform p_excel_cell_attribute_set(sCELL_LM_NOTE , 0, nidx_bgn, 'Font.FontStyle', 'Bold');
            /*Обнуляем счетчик для оборотов по счету*/
            nACC_SP_COUNT:=0;
       end if;

       /*Остаток на начало периода*/
       nidx := p_excel_line_append(sLINE_MAIN);
       perform p_excel_cell_value_write(sCELL_LM_PROP , 0, nidx,    rACC.sGROUP);
       perform p_excel_cell_value_write(sCELL_LM_NOTE , 0, nidx,    rACC.sACCOUNT);
       if rACC.nREST_BGN>=0
       then
            perform p_excel_cell_value_write(sCELL_LM_REST_BGN_DB , 0, nidx,    abs(rACC.nREST_BGN));
            --perform p_excel_cell_value_write(sCELL_LM_REST_BGN_CR , 0, nidx,    0);
       else
            --perform p_excel_cell_value_write(sCELL_LM_REST_BGN_DB , 0, nidx,    0);
            perform p_excel_cell_value_write(sCELL_LM_REST_BGN_CR , 0, nidx,    abs(rACC.nREST_BGN));
       end if;
       /*Делаем шрифт жирным*/
       perform p_excel_cell_attribute_set(sCELL_LM_PROP , 0, nidx, 'Font.FontStyle', 'Bold');
       perform p_excel_cell_attribute_set(sCELL_LM_NOTE , 0, nidx, 'Font.FontStyle', 'Bold');

       /*Цикл по проводкам текущего счета/группы*/
       for rDOC in (select /*Дебет*/
                           p_get_acc_by_parts_code(s.dtfinsecurity::text,dacs.code,dt.accnumb,sprint_typeexp_sign||dexp.code,dec.code) sDT_ACCOUNT,

                           s.dtfinsecurity nDT_KFO,     /*КФО - id*/
                           dacs.id         nDT_KPS,     /*КПС - id*/
                           dacs.code       sDT_KPS,     /*КПС - код*/
                           dt.id           nDT_ACC,     /*Счет - id*/
                           dt.accnumb      sDT_ACC,     /*Счет - код*/
                           dexp.id         nDT_EXP,     /*Направление расходов - id*/
                           dexp.code       sDT_EXP,     /*Направление расходов - код*/
                           dec.id          nDT_EC,      /*КОСГУ - id*/
                           dec.code        sDT_EC,      /*КОСГУ - код*/
                           dt.memorderid   nDT_MEMORDER,/*Ордер - id*/
                           dagn.id         nDT_AGNENT,  /*Юр.лицо - id*/
                           dagn.code       sDT_AGNENT,  /*Юр.лицо - код*/
                           dprs.id         nDT_PERSON,  /*Физ.лицо - id*/
                           dprs.code       sDT_PERSON,  /*Физ.лицо - код*/
                           dpm.id          nDT_MOL,     /*МОЛ - id*/
                           dpm.code        sDT_MOL,     /*МОЛ - код*/
                           /*Поле для группировки согласно типу ордера счета*/
                           case
                             when dmord.detail='1' then dprs.code /*Детализация по физ.лицу*/
                             when dmord.detail='2' then coalesce(nullif(dagn.code,''),dprs.code) /*Детализация по юр.лицу и физ.лицу (заполнено одно!?)*/
                             when dmord.detail='3' then dpm.code/*Детализация по МОЛ*/
                             else null
                           end             sDT_GROUP,
                           dmord.detail    sDT_DETAIL,
                           /*Контрагент-дебет*/
                           coalesce(dagn.code||' ','')||coalesce(dprs.code||' ','')||coalesce(dpm.code||' ','') sDT_AGN,

                           /*Кредит*/
                           p_get_acc_by_parts_code(s.ktfinsecurity::text,kacs.code,kt.accnumb,sprint_typeexp_sign||kexp.code,kec.code) sKT_ACCOUNT,
                           s.ktfinsecurity nKT_KFO,     /*КФО - id*/
                           kacs.id         nKT_KPS,     /*КПС - id*/
                           kacs.code       sKT_KPS,     /*КПС - код*/
                           kt.id           nKT_ACC,     /*Счет - id*/
                           kt.accnumb      sKT_ACC,     /*Счет - код*/
                           kexp.id         nKT_EXP,     /*Направление расходов - id*/
                           kexp.code       sKT_EXP,     /*Направление расходов - код*/
                           kec.id          nKT_EC,      /*КОСГУ - id*/
                           kec.code        sKT_EC,      /*КОСГУ - код*/
                           kt.memorderid   nKT_MEMORDER,/*Ордер - id*/
                           kagn.id         nKT_AGNENT,  /*Юр.лицо - id*/
                           kagn.code       sKT_AGNENT,  /*Юр.лицо - код*/
                           kprs.id         nKT_PERSON,  /*Физ.лицо - id*/
                           kprs.code       sKT_PERSON,  /*Физ.лицо - код*/
                           kpm.id          nKT_MOL,     /*МОЛ - id*/
                           kpm.code        sKT_MOL,     /*МОЛ - код*/
                           /*Поле для группировки согласно типу ордера счета*/
                           case
                             when kmord.detail='1' then kprs.code /*Детализация по физ.лицу*/
                             when kmord.detail='2' then coalesce(nullif(kagn.code,''),kprs.code) /*Детализация по юр.лицу и физ.лицу (заполнено одно!?)*/
                             when kmord.detail='3' then kpm.code/*Детализация по МОЛ*/
                             else null
                           end             sKT_GROUP,
                           kmord.detail    sKT_DETAIL,
                           /*Контрагент-кредит*/
                           coalesce(kagn.code||' ','')||coalesce(kprs.code||' ','')||coalesce(kpm.code||' ','') sKT_AGN,

                           s.*,
                           d.transactiondate  dTRANSACTIONDATE,
                           d.docdate          dDOCDATE,
                           d.docnumb          sDOCNUMB,
                           c.code             sDOCTYPES,
                           d.tponame          sTPONAME,

                           0 nidx
                      from transactionlog t,
                           transactionlog_docs d
                              left join doctypes c on c.id=d.doctypeid, /*Тип документа*/
                           transactionlog_stages s
                              left join budgclass dacs on dacs.id=s.dtbudgclassid /*КПС-дебет*/
                              left join dicaccs dt on dt.id=s.accountdtid /*Счет-дебет*/
                              left join memorder dmord on dmord.id=dt.memorderid /*Мемориальный ордер счета-дебет*/
                              left join typeexp dexp on dexp.id=s.dttypeexpid /*Направление расходов счета-дебет*/
                              left join econclass dec on dec.id=s.dteconclassktid /*КОСГУ-дебет*/
                              left join agent dagn on dagn.id=s.agentdtid /*Юр.лицо-дебет*/
                              left join person dprs on dprs.id=s.persondtid /*Физ.лицо-дебет*/
                              left join mtresponspers dm on dm.id=s.dtrespperson /*МОЛ-дебет*/
                              left join person dpm on dpm.id=dm.personid /*Физ.лицо МОЛа-дебет*/

                              left join budgclass kacs on kacs.id=s.ktbudgclassid /*КПС-кредит*/
                              left join dicaccs kt on kt.id=s.accountktid /*Счет-кредит*/
                              left join memorder kmord on kmord.id=kt.memorderid /*Мемориальный ордер счета-кредит*/
                              left join typeexp kexp on kexp.id=s.kttypeexpid /*Направление расходов счета-кредит*/
                              left join econclass kec on kec.id=s.kteconclassktid /*КОСГУ-кредит*/
                              left join agent kagn on kagn.id=s.agentktid /*Юр.лицо-кредит*/
                              left join person kprs on kprs.id=s.personktid /*Физ.лицо-кредит*/
                              left join mtresponspers km on km.id=s.ktrespperson /*Физ.лицо-кредит*/
                              left join person kpm on kpm.id=km.personid /*Физ.лицо МОЛа-кредит*/

                     where t.id=p_report_memorder.id
                       and d.transactionlogid=t.id
                       and s.transactionlog_docsid=d.id

                       /*Даты проводок в периоде отчета*/
                       and d.transactiondate BETWEEN p_report_memorder.begindate and p_report_memorder.enddate
                       /*Проводки заданного мемориального ордера*/
                       and (dt.memorderid=p_report_memorder.memorderid or kt.memorderid=p_report_memorder.memorderid)

                       /*Проводки текущего счета и подгруппы*/
                       and ((    s.dtfinsecurity=rACC.nKFO /*КФО - id*/
                             and dacs.id = rACC.nKPS       /*КПС - id*/
                             and dt.id   = rACC.nACC       /*Счет - id*/

                             and (rACC.nAGENT_GRP=-1 or coalesce(dagn.id,0)=coalesce(rACC.nAGENT_GRP,0))  /*Юр.лицо - id*/
                             and (rACC.nPERSON_GRP=-1 or coalesce(dprs.id,0)=coalesce(rACC.nPERSON_GRP,0)) /*Физ.лицо - id*/
                             and (rACC.nMOL_GRP=-1 or coalesce(dm.id,0)=coalesce(rACC.nMOL_GRP,0))     /*МОЛ - id*/
                            )
                            or
                            (    s.ktfinsecurity=rACC.nKFO /*КФО - id*/
                             and kacs.id = rACC.nKPS       /*КПС - id*/
                             and kt.id   = rACC.nACC       /*Счет - id*/

                             and (rACC.nAGENT_GRP=-1 or coalesce(kagn.id,0)=coalesce(rACC.nAGENT_GRP,0))  /*Юр.лицо - id*/
                             and (rACC.nPERSON_GRP=-1 or coalesce(kprs.id,0)=coalesce(rACC.nPERSON_GRP,0)) /*Физ.лицо - id*/
                             and (rACC.nMOL_GRP=-1 or coalesce(km.id,0)=coalesce(rACC.nMOL_GRP,0))     /*МОЛ - id*/
                            ))
                     order by d.transactiondate
                   )
       loop
            rDOC.nidx := p_excel_line_append(sLINE_MAIN);
            perform p_excel_cell_value_write(sCELL_LM_OPERDATE , 0, rDOC.nidx, to_char(rDOC.dTRANSACTIONDATE,'dd.mm.yyyy'));
            perform p_excel_cell_value_write(sCELL_LM_DOCDATE , 0, rDOC.nidx, to_char(rDOC.dDOCDATE,'dd.mm.yyyy'));
            perform p_excel_cell_value_write(sCELL_LM_DOCNUM , 0, rDOC.nidx, rDOC.sDOCNUMB);
            perform p_excel_cell_value_write(sCELL_LM_DOCNAME , 0, rDOC.nidx, rDOC.sDOCTYPES);

            /*В проводках без подгруппы выводим просто корреспондентов в операции*/
            if rDOC.sDT_AGN=rDOC.sKT_AGN
            then sPROP:=trim(rDOC.sDT_AGN);
            else sPROP:=trim(rDOC.sDT_AGN||' '||rDOC.sKT_AGN);
            end if;
            perform p_excel_cell_value_write(sCELL_LM_PROP , 0, rDOC.nidx, coalesce(nullif(rACC.sGROUP,''),nullif(sPROP,'')));

            perform p_excel_cell_value_write(sCELL_LM_NOTE , 0, rDOC.nidx, rDOC.sTPONAME);

            --sCELL_LM_REST_BGN_DB 'ОстатокНачалоДебет';
            --sCELL_LM_REST_BGN_CR 'ОстатокНачалоКредит';

            perform p_excel_cell_value_write(sCELL_LM_ACC_DB , 0, rDOC.nidx, rDOC.sDT_ACCOUNT); /*СчетДебет*/
            perform p_excel_cell_value_write(sCELL_LM_ACC_CR , 0, rDOC.nidx, rDOC.sKT_ACCOUNT); /*СчетКредит'*/
            perform p_excel_cell_value_write(sCELL_LM_SUM , 0, rDOC.nidx, rDOC.SUMM);        /*Сумма'*/

            --sCELL_LM_REST_END_DB 'ОстатокКонецДебет';
            --sCELL_LM_REST_END_CR 'ОстатокКонецКредит';

            nACC_SP_COUNT:=nACC_SP_COUNT+1;/*Подсчитываем количество оборотов по счету*/
            bNULLREP:=false;/*Отчет не пустой*/

       end loop;

       /*В случае нулевых остатков и отсутствия оборотов удаляем заголовок счета и не печатаем его подвал*/
       if rACC.nREST_BGN=0 and rACC.nREST_END=0 and rDOC.id is null /*Последняя запись цикла по проводкам доступна после тела цикла и ее отсутствие означает отсутствие проводок*/
       then perform p_excel_line_delete(sLINE_MAIN,nidx);
       else/*Остатки или обороты присутствуют - завершаем группу счета*/

            /*Остаток на конец периода*/
            nidx := p_excel_line_append(sLINE_MAIN);
            perform p_excel_cell_value_write(sCELL_LM_PROP , 0, nidx,    'Итого по '||rACC.sGROUP);
            perform p_excel_cell_value_write(sCELL_LM_NOTE , 0, nidx,    rACC.sACCOUNT);

            if rACC.nREST_END>=0
            then
                 perform p_excel_cell_value_write(sCELL_LM_REST_END_DB , 0, nidx,    abs(rACC.nREST_END));
                 --perform p_excel_cell_value_write(sCELL_LM_REST_END_CR , 0, nidx,    0);
            else
                 --perform p_excel_cell_value_write(sCELL_LM_REST_END_DB , 0, nidx,    0);
                 perform p_excel_cell_value_write(sCELL_LM_REST_END_CR , 0, nidx,    abs(rACC.nREST_END));
            end if;
            /*Делаем шрифт жирным*/
            perform p_excel_cell_attribute_set(sCELL_LM_PROP , 0, nidx, 'Font.FontStyle', 'Bold');
            perform p_excel_cell_attribute_set(sCELL_LM_NOTE , 0, nidx, 'Font.FontStyle', 'Bold');

            bNULLREP:=false;/*Отчет не пустой*/

       end if;

       /*На последней группе счета с подгруппами выводим его итог с остстком*/
       if rACC.nLAST_GRP=1 and rACC.sDETAIL in ('1','2','3')
       then
            /*Остаток по счету на окончание периода*/
            nREST_END:=p_get_acc_rest(p_report_memorder.id, (enddate + INTERVAL '1 day')::date, rACC.nKFO, rACC.nKPS, rACC.nACC);

            /*Если остатки по счету нулевые и небыло оборотов (ни по одной его подгруппе), то удаляем из отчета и сам счет */
            if nREST_BGN=0 and nREST_END=0 and nACC_SP_COUNT=0
            then perform p_excel_line_delete(sLINE_MAIN,nidx_bgn);
            else
                 nidx_end := p_excel_line_append(sLINE_MAIN);
                 perform p_excel_cell_value_write(sCELL_LM_PROP , 0, nidx_end,    'Остаток на '||to_char(enddate,'dd.mm.yyyy'));
                 perform p_excel_cell_value_write(sCELL_LM_NOTE , 0, nidx_end,    rACC.sACCOUNT);

                 if nREST_END>=0
                 then
                      perform p_excel_cell_value_write(sCELL_LM_REST_END_DB , 0, nidx_end,    abs(nREST_END));
                      --perform p_excel_cell_value_write(sCELL_LM_REST_END_CR , 0, nidx_end,    0);
                 else
                      --perform p_excel_cell_value_write(sCELL_LM_REST_END_DB , 0, nidx_end,    0);
                      perform p_excel_cell_value_write(sCELL_LM_REST_END_CR , 0, nidx_end,    abs(nREST_END));
                 end if;

                 /*Делаем шрифт жирным*/
                 perform p_excel_cell_attribute_set(sCELL_LM_PROP , 0, nidx_end, 'Font.FontStyle', 'Bold');
                 perform p_excel_cell_attribute_set(sCELL_LM_NOTE , 0, nidx_end, 'Font.FontStyle', 'Bold');

            end if;

       end if;

  end loop;

  /*Формируем спецификацию N2 - Обороты для главной книги*/
  /*Цикл по проводкам текущего счета/группы*/
  for rDOC in (select /*Дебет*/
                      p_get_acc_by_parts_code(s.dtfinsecurity::text,dacs.code,dt.accnumb,sprint_typeexp_sign||dexp.code,dec.code) sDT_ACCOUNT,
                      /*Кредит*/
                      p_get_acc_by_parts_code(s.ktfinsecurity::text,kacs.code,kt.accnumb,sprint_typeexp_sign||kexp.code,kec.code) sKT_ACCOUNT,

                      sum(s.SUMM)     nSUMM, /*Сумма*/

                      0 nidx

                 from transactionlog t,
                      transactionlog_docs d,
                      transactionlog_stages s
                         left join budgclass dacs on dacs.id=s.dtbudgclassid /*КПС-дебет*/
                         left join dicaccs dt on dt.id=s.accountdtid /*Счет-дебет*/
                         left join memorder dmord on dmord.id=dt.memorderid /*Мемориальный ордер счета-дебет*/
                         left join typeexp dexp on dexp.id=s.dttypeexpid /*Направление расходов счета-дебет*/
                         left join econclass dec on dec.id=s.dteconclassktid /*КОСГУ-дебет*/

                         left join budgclass kacs on kacs.id=s.ktbudgclassid /*КПС-кредит*/
                         left join dicaccs kt on kt.id=s.accountktid /*Счет-кредит*/
                         left join memorder kmord on kmord.id=kt.memorderid /*Мемориальный ордер счета-кредит*/
                         left join typeexp kexp on kexp.id=s.kttypeexpid /*Направление расходов счета-кредит*/
                         left join econclass kec on kec.id=s.kteconclassktid /*КОСГУ-кредит*/

                where t.id=p_report_memorder.id
                  and d.transactionlogid=t.id
                  and s.transactionlog_docsid=d.id

                  /*Даты проводок в периоде отчета*/
                  and d.transactiondate BETWEEN p_report_memorder.begindate and p_report_memorder.enddate
                  /*Проводки заданного ПРИНУДИТЕЛЬНО мемориального ордера*/
                  and s.memorderid=p_report_memorder.memorderid

                group by /*Дебет*/
                         sDT_ACCOUNT,
                         /*Кредит*/
                         sKT_ACCOUNT
                order by sDT_ACCOUNT, sKT_ACCOUNT
              )
  loop
       rDOC.nidx := p_excel_line_append(sLINE_ALT);
       perform p_excel_cell_value_write(sCELL_LA_DB , 0, rDOC.nidx, rDOC.sDT_ACCOUNT); /*СчетДебет*/
       perform p_excel_cell_value_write(sCELL_LA_CR , 0, rDOC.nidx, rDOC.sKT_ACCOUNT); /*СчетКредит'*/
       perform p_excel_cell_value_write(sCELL_LA_SUM , 0, rDOC.nidx, rDOC.nSUMM);        /*Сумма'*/
       /*На первой записи выводим подпись: "Обороты для главной книги"*/
       if rDOC.nidx=1
       then perform p_excel_cell_value_write(sCELL_LA_NOTE , 0, rDOC.nidx, 'Обороты для главной книги:');
       end if;
       bNULLREP:=false;/*Отчет не пустой*/
  end loop;

  /*В случае пустого отчета выводим сообщение с ошибкой "Нет данных для печати"*/
  if bNULLREP
  then perform p_system_exception(0,'Нет данных для печати!');
  end if;

  /*Удаляем оброзцы строк*/
  perform p_excel_line_delete(sLINE_MAIN);
  perform p_excel_line_delete(sLINE_ALT);

end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

COMMENT ON FUNCTION public.p_report_memorder(id bigint, memorderid bigint, begindate date, enddate date, print_typeexp boolean, gbpersonid bigint, postsid bigint, bpersonid bigint)
IS 'Процедура для отчета "Журнал операций"';

ALTER FUNCTION public.p_report_memorder (id bigint, memorderid bigint, begindate date, enddate date, print_typeexp boolean, gbpersonid bigint, postsid bigint, bpersonid bigint)
  OWNER TO postgres;