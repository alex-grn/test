CREATE OR REPLACE FUNCTION public.p_report_general_ledger (
  id bigint,
  begindate date,
  enddate date,
  gbpersonid bigint,
  postsid bigint,
  bpersonid bigint
)
RETURNS void AS
$body$
DECLARE
  rDOC  record;/*Запись общих атрибутов отчета*/
  rACCTYPE record;/*Запись типов счетов*/
  rACC  record;/*Запись текущего счета*/
  rORD  record;/*Запись ордера*/
  sPERIOD text;/*Период отчета для вывода в шапке*/
  nidx_acc bigint;
  nidx bigint;
  nNUM bigint; /*Номер группы*/
  
  --константы настроек листа шаблона "Главная книга"
  sSHEET                constant text := 'Главная книга';
  sCELL_DATE            constant text := 'Дата';
  sCELL_PERIOD          constant text := 'Период';
  sCELL_ORG             constant text := 'Учреждение';
  sCELL_UNIT            constant text := 'Подразделение';
  sCELL_BUDGET          constant text := 'Бюджет';
  sCELL_GBUH            constant text := 'Главбух';
  sCELL_BPOST           constant text := 'ИсполнительДолжность';
  sCELL_BPERS           constant text := 'ИсполнительПодпись';

  /*Основная спецификация*/
  sLINE_MAIN            constant text := 'СтрокаСпецификации';
  sCELL_LM_NUM          constant text := 'НомерПП';
  sCELL_LM_ACC          constant text := 'Счет';
  sCELL_LM_REST_BGNY_DB constant text := 'ОстатокНачалоГодДебет';
  sCELL_LM_REST_BGNY_CR constant text := 'ОстатокНачалоГодКредит';
  sCELL_LM_REST_BGNP_DB constant text := 'ОстатокНачалоПериодДебет';
  sCELL_LM_REST_BGNP_CR constant text := 'ОстатокНачалоПериодКредит';
  sCELL_LM_TURN_P_DB    constant text := 'ОборотПериодДебет';
  sCELL_LM_TURN_P_CR    constant text := 'ОборотПериодКредит';
  sCELL_LM_TURN_Y_DB    constant text := 'ОборотГодДебет';
  sCELL_LM_TURN_Y_CR    constant text := 'ОборотГодКредит';
  sCELL_LM_REST_ENDP_DB constant text := 'ОстатокКонецПериодДебет';
  sCELL_LM_REST_ENDP_CR constant text := 'ОстатокКонецПериодКредит';
  sCELL_LM_ORDER        constant text := 'НомерЖурнала';
  

  /*Спецификация итогов*/
  sLINE_ITG             constant text := 'СтрокаИтого';
  sCELL_LI_ACC          constant text := 'ИтогоСчет';
  sCELL_LI_REST_BGNY_DB constant text := 'ИтогоОстатокНачалоГодДебет';
  sCELL_LI_REST_BGNY_CR constant text := 'ИтогоОстатокНачалоГодКредит';
  sCELL_LI_REST_BGNP_DB constant text := 'ИтогоОстатокНачалоПериодДебет';
  sCELL_LI_REST_BGNP_CR constant text := 'ИтогоОстатокНачалоПериодКредит';
  sCELL_LI_TURN_P_DB    constant text := 'ИтогоОборотПериодДебет';
  sCELL_LI_TURN_P_CR    constant text := 'ИтогоОборотПериодКредит';
  sCELL_LI_TURN_Y_DB    constant text := 'ИтогоОборотГодДебет';
  sCELL_LI_TURN_Y_CR    constant text := 'ИтогоОборотГодКредит';
  sCELL_LI_REST_ENDP_DB constant text := 'ИтогоОстатокКонецПериодДебет';
  sCELL_LI_REST_ENDP_CR constant text := 'ИтогоОстатокКонецПериодКредит';
  
  sLINE_SPLIT           constant text := 'СтрокаРазделитель';

BEGIN

  /*Процедура для отчета "Главная книга" [FD]*/
  perform p_excel_prepare();
  perform p_excel_sheet_select(sSHEET);

  /*Описание ячеек*/
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
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_NUM );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_ACC );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_BGNY_DB );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_BGNY_CR );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_BGNP_DB );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_BGNP_CR );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_TURN_P_DB );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_TURN_P_CR );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_TURN_Y_DB );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_TURN_Y_CR );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_ENDP_DB );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_REST_ENDP_CR );
  perform p_excel_line_cell_describe(sLINE_MAIN, sCELL_LM_ORDER );

  /*Спецификация итогов*/
  perform p_excel_line_describe(sLINE_ITG);
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_ACC );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_REST_BGNY_DB );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_REST_BGNY_CR );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_REST_BGNP_DB );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_REST_BGNP_CR );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_TURN_P_DB );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_TURN_P_CR );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_TURN_Y_DB );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_TURN_Y_CR );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_REST_ENDP_DB );
  perform p_excel_line_cell_describe(sLINE_ITG, sCELL_LI_REST_ENDP_CR );
  
  /*Строка-разделитель*/
  perform p_excel_line_describe(sLINE_SPLIT);

  /*Цикл по текущему документу раздела "Журнал операций" для доступа к общим полям отчета*/
  for rDOC in (SELECT t.id, t.electcampaignid, t.jurpersonsid,
                     c.name selectcampaign_name, /*Избирательная компания*/
                     /*Уровень избирательной кампании*/
                     case
                        when c.levelelcampaign='central' then 'Федеральный'
                        else 'Региональный'
                     end slevelelcampaign,
                     j.codejurpers sjurpersons_code, /*Принадлежность*/
                     (select p.name from person p where p.id=gbpersonid)   sgbperson,/*Подпись для гл.буха*/
                     (select p.code from posts  p where p.id=postsid)      sposts,   /*Должность подписи для исполнителя*/
                     (select p.name from person p where p.id=bpersonid)    sbperson  /*Подпись для исполнителя*/

                FROM transactionlog t,
                     electcampaign c,
                     jurpersons j
               WHERE t.id=p_report_general_ledger.id
                 and c.id=t.electcampaignid
                 and j.id=t.jurpersonsid
             )
  loop
       /*Заголовок*/
       /*Дата*/
       perform p_excel_cell_value_write(sCELL_DATE,  to_char(enddate,'dd.mm.yyyy'));

       /*Вычисляем период отчета, который будет либо месяц-год, либо с-по*/
       if (begindate=date_trunc('MONTH',begindate) /*begindate = началу месяца*/
          and
          enddate=(date_trunc('MONTH', begindate) + INTERVAL '1 MONTH - 1 day')::date)
       then/*Границы одного месяца*/
            sPERIOD:='за '||(ARRAY['январь','февраль','март','апрель','май','июнь','июль','август','сентябрь','октябрь','ноябрь','декабрь'])[to_char(enddate,'MM')::integer]||' '||to_char(enddate,'YYYY')||'г.';
       else sPERIOD:='за период с '||to_char(begindate,'dd.mm.yyyy')||' по '||to_char(enddate,'dd.mm.yyyy');
       end if;
       perform p_excel_cell_value_write(sCELL_PERIOD, sPERIOD);

       perform p_excel_cell_value_write(sCELL_ORG,    rDOC.sjurpersons_code /*selectcampaign_name*/);/*Наименование ТИК*/
       perform p_excel_cell_value_write(sCELL_UNIT,   rDOC.sjurpersons_code);
       perform p_excel_cell_value_write(sCELL_BUDGET, rDOC.slevelelcampaign);

       /*Подписи*/
       perform p_excel_cell_value_write(sCELL_GBUH,  rDOC.sgbperson);
       perform p_excel_cell_value_write(sCELL_BPOST, rDOC.sposts);
       perform p_excel_cell_value_write(sCELL_BPERS, rDOC.sbperson);
       
  end loop;

  /*Цикл по двум типам счетов: Балансовые и забалансовые для формирования отдельных таблиц*/
  for rACCTYPE in (select tp.*,
  
                          /*РАЗВЕРНУТЫЕ Итоги по балансовым/забалансовым счетам, расчитываемые в цикле*/
                          0::numeric  nREST_Y_BGN_DB,
                          0::numeric  nREST_Y_BGN_CR,
                          0::numeric  nREST_P_BGN_DB,
                          0::numeric  nREST_P_BGN_CR,
                          0::numeric  nREST_P_END_DB,
                          0::numeric  nREST_P_END_CR,
                          0::numeric  nTURN_P_DB,
                          0::numeric  nTURN_P_CR,
                          0::numeric  nTURN_Y_DB,
                          0::numeric  nTURN_Y_CR 
                          
                     from (select '1'::varchar accbalance,
                                  'Итого по балансовым счетам:' sFOOT
                            union all
                           select '0'::varchar accbalance,
                                  'Итого по забалансовым счетам:' sFOOT
                          ) tp
                  )
  loop

    nNUM:=0;
    /*Цикл по всем балансовым счетам, участвующим в проводках*/
    for rACC in (select p_get_acc_by_parts_code(m.nkfo::text, m.skps,m.sacc,NULL::text/*Направление расходов*/,'000'/*КОСГУ*/) sACC_GRP,
                        p_get_acc_by_parts_code(m.nkfo::text, m.skps,m.sacc,NULL::text/*Направление расходов*/,m.sEC/*КОСГУ*/) sACCOUNT,

                        /*Остаток на начало года(начало работы системы) всегда 0?????*/
                        0 nREST_Y_BGN,
                        
                        /*Остаток на начало периода*/
                        p_get_acc_rest(p_report_general_ledger.id, begindate, m.nKFO, m.nKPS, m.nACC, -1/*Направление расходов*/, m.nEC /*КОСГУ-id*/) nREST_P_BGN,
                        /*Остаток на конец периода*/
                        p_get_acc_rest(p_report_general_ledger.id, (enddate + INTERVAL '1 day')::date, m.nKFO, m.nKPS, m.nACC, -1/*Направление расходов*/, m.nEC /*КОСГУ-id*/) nREST_P_END,
                        
                        /*Обороты за период*/
                        /*Период-Дебет*/
                        p_get_acc_turn(p_report_general_ledger.id, 
                                       p_report_general_ledger.begindate,
                                       p_report_general_ledger.enddate,
                                       m.nKFO, /*КФО - id*/
                                       m.nKPS, /*КПС - id*/
                                       m.nACC, /*Счет - id*/
                                       -1,     /*Направление расходов*/
                                       m.nEC,  /*КОСГУ - id*/
                                       -1,     /*Ордер - id*/
                                       1       /*Дебетовый оборот*/
                                       ) nTURN_P_DB,
                        /*Период-Кредит*/
                        p_get_acc_turn(p_report_general_ledger.id, 
                                       p_report_general_ledger.begindate,
                                       p_report_general_ledger.enddate,
                                       m.nKFO, /*КФО - id*/
                                       m.nKPS, /*КПС - id*/
                                       m.nACC, /*Счет - id*/
                                       -1,     /*Направление расходов*/
                                       m.nEC,  /*КОСГУ - id*/
                                       -1,     /*Ордер - id*/
                                       2       /*Кредитовый оборот*/
                                       ) nTURN_P_CR,                      
                                       
                        /*Год-Дебет*/
                        p_get_acc_turn(p_report_general_ledger.id, 
                                       NULL::date,
                                       p_report_general_ledger.enddate,
                                       m.nKFO, /*КФО - id*/
                                       m.nKPS, /*КПС - id*/
                                       m.nACC, /*Счет - id*/
                                       -1,     /*Направление расходов*/
                                       m.nEC,  /*КОСГУ - id*/
                                       -1,     /*Ордер - id*/
                                       1       /*Дебетовый оборот*/
                                       ) nTURN_Y_DB,
                        /*Год-Кредит*/
                        p_get_acc_turn(p_report_general_ledger.id, 
                                       NULL::date,
                                       p_report_general_ledger.enddate,
                                       m.nKFO, /*КФО - id*/
                                       m.nKPS, /*КПС - id*/
                                       m.nACC, /*Счет - id*/
                                       -1,     /*Направление расходов*/
                                       m.nEC,  /*КОСГУ - id*/
                                       -1,     /*Ордер - id*/
                                       2       /*Кредитовый оборот*/
                                       ) nTURN_Y_CR,                      
                        
                        m.*,
                             
                        /*Признак первого КОСГУ для счета*/
                        (array[1])[row_number() OVER(PARTITION by m.nKFO, /*КФО - id*/
                                                                  m.sACC, /*Счет - код*/
                                                                  m.sKPS  /*КПС - код*/
                                                         order by m.sEC   /*КОСГУ - код*/
                        )] nFIRST_EC,
                        /*Признак последнего КОСГУ для счета*/
                        (array[1])[row_number() OVER(PARTITION by m.nKFO, /*КФО - id*/
                                                                  m.sACC, /*Счет - код*/
                                                                  m.sKPS  /*КПС - код*/
                                                         order by m.sEC   /*КОСГУ - код*/
                        )] nLAST_EC,
                        
                        /*Значения остатков и оборотов для счетов без КОСГУ, расчитываемые в цикле*/
                        0::numeric  nGRP_REST_Y_BGN,
                        0::numeric  nGRP_REST_P_BGN,
                        0::numeric  nGRP_REST_P_END,
                        0::numeric  nGRP_TURN_P_DB,
                        0::numeric  nGRP_TURN_P_CR,
                        0::numeric  nGRP_TURN_Y_DB,
                        0::numeric  nGRP_TURN_Y_CR 


                   from (select /*Дебет*/
                                s.dtfinsecurity nKFO,     /*КФО - id*/
                                dacs.id         nKPS,     /*КПС - id*/
                                dacs.code       sKPS,     /*КПС - код*/
                                dt.id           nACC,     /*Счет - id*/
                                dt.accnumb      sACC,     /*Счет - код*/
                                dec.id          nEC,      /*КОСГУ - id*/
                                dec.code        sEC       /*КОСГУ - код*/

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

                          where t.id=p_report_general_ledger.id
                            and d.transactionlogid=t.id
                            /*Проводки до даты "по"*/
                            and d.transactiondate<=p_report_general_ledger.enddate
                            and s.transactionlog_docsid=d.id
                            /*Проводки в дебет балансовых/забалансовых счетов*/
                            and dt.accbalance=rACCTYPE.accbalance

                         union

                         select /*Кредит*/
                                s.ktfinsecurity nKFO,     /*КФО - id*/
                                kacs.id         nKPS,     /*КПС - id*/
                                kacs.code       sKPS,     /*КПС - код*/
                                kt.id           nACC,     /*Счет - id*/
                                kt.accnumb      sACC,     /*Счет - код*/
                                kec.id          nEC,      /*КОСГУ - id*/
                                kec.code        sEC       /*КОСГУ - код*/

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

                          where t.id=p_report_general_ledger.id
                            and d.transactionlogid=t.id
                            /*Проводки до даты "по"*/
                            and d.transactiondate<=p_report_general_ledger.enddate
                            and s.transactionlog_docsid=d.id
                            /*Проводки в кредит балансовых/забалансовых счетов*/
                            and kt.accbalance=rACCTYPE.accbalance

                        ) m
                        
                           /*Сортируем по счету и КОСГУ*/
                  order by m.nKFO,  /*КФО - id*/
                           m.sACC,  /*Счет - код*/
                           m.sKPS,  /*КПС - код*/
                           m.sEC    /*КОСГУ - код*/
                )
    loop

         /*На первом КОСГУ счета выводим его общий заголовок*/
         if rACC.nFIRST_EC=1
         then
              /*Подсчитываем группы*/
              nNUM:=nNUM+1;
              
              /*Расчитаем суммы для итоговых счетов без КОСГУ. Возможно их можно было бы вывести формулой как сумма счетов с КОСГУ!*/
              rACC.nGRP_REST_Y_BGN:=0;
              rACC.nGRP_REST_P_BGN:=p_get_acc_rest(p_report_general_ledger.id, 
                                                  begindate, 
                                                  rACC.nKFO, 
                                                  rACC.nKPS, 
                                                  rACC.nACC, 
                                                  -1/*Направление расходов*/, 
                                                  -1/*КОСГУ-id*/);
              rACC.nGRP_REST_P_END:=p_get_acc_rest(p_report_general_ledger.id, 
                                                  (enddate + INTERVAL '1 day')::date, 
                                                  rACC.nKFO, 
                                                  rACC.nKPS, 
                                                  rACC.nACC, 
                                                  -1/*Направление расходов*/, 
                                                  -1/*КОСГУ-id*/);
              
              rACC.nGRP_TURN_P_DB:=p_get_acc_turn(p_report_general_ledger.id, 
                                                  p_report_general_ledger.begindate,
                                                  p_report_general_ledger.enddate,
                                                  rACC.nKFO, /*КФО - id*/
                                                  rACC.nKPS, /*КПС - id*/
                                                  rACC.nACC, /*Счет - id*/
                                                  -1,     /*Направление расходов*/
                                                  -1,     /*КОСГУ - id*/
                                                  -1,     /*Ордер - id*/
                                                   1      /*Дебетовый оборот*/
                                                  );
              rACC.nGRP_TURN_P_CR:=p_get_acc_turn(p_report_general_ledger.id, 
                                                  p_report_general_ledger.begindate,
                                                  p_report_general_ledger.enddate,
                                                  rACC.nKFO, /*КФО - id*/
                                                  rACC.nKPS, /*КПС - id*/
                                                  rACC.nACC, /*Счет - id*/
                                                  -1,     /*Направление расходов*/
                                                  -1,     /*КОСГУ - id*/
                                                  -1,     /*Ордер - id*/
                                                   2      /*Кредитовый оборот*/
                                                  );
              rACC.nGRP_TURN_Y_DB:=p_get_acc_turn(p_report_general_ledger.id, 
                                                  NULL::date,
                                                  p_report_general_ledger.enddate,
                                                  rACC.nKFO, /*КФО - id*/
                                                  rACC.nKPS, /*КПС - id*/
                                                  rACC.nACC, /*Счет - id*/
                                                  -1,     /*Направление расходов*/
                                                  -1,     /*КОСГУ - id*/
                                                  -1,     /*Ордер - id*/
                                                  1       /*Дебетовый оборот*/
                                                  );
              
              rACC.nGRP_TURN_Y_CR:=p_get_acc_turn(p_report_general_ledger.id, 
                                                  NULL::date,
                                                  p_report_general_ledger.enddate,
                                                  rACC.nKFO, /*КФО - id*/
                                                  rACC.nKPS, /*КПС - id*/
                                                  rACC.nACC, /*Счет - id*/
                                                  -1,     /*Направление расходов*/
                                                  -1,     /*КОСГУ - id*/
                                                  -1,     /*Ордер - id*/
                                                  2       /*Кредитовый оборот*/
                                                  );

              /*Заголовок счета без КОСГУ*/
              nidx_acc := p_excel_line_continue(sLINE_MAIN);
              perform p_excel_cell_value_write(sCELL_LM_NUM , 0, nidx_acc,  nNUM );
              perform p_excel_cell_value_write(sCELL_LM_ACC , 0, nidx_acc, rACC.sACC_GRP);
              
              /*Остаток на начало периода*/
              if rACC.nGRP_REST_P_BGN>=0
              then perform p_excel_cell_value_write(sCELL_LM_REST_BGNP_DB , 0, nidx_acc,   nullif(abs(rACC.nGRP_REST_P_BGN),0));
              else perform p_excel_cell_value_write(sCELL_LM_REST_BGNP_CR , 0, nidx_acc,    nullif(abs(rACC.nGRP_REST_P_BGN),0));
              end if;
              /*Остаток на конец периода*/
              if rACC.nGRP_REST_P_END>=0
              then perform p_excel_cell_value_write(sCELL_LM_REST_ENDP_DB , 0, nidx_acc,    nullif(abs(rACC.nGRP_REST_P_END),0));
              else perform p_excel_cell_value_write(sCELL_LM_REST_ENDP_CR , 0, nidx_acc,    nullif(abs(rACC.nGRP_REST_P_END),0));
              end if;
         
              /*Остаток на начало года*/
              if rACC.nGRP_REST_Y_BGN>=0
              then perform p_excel_cell_value_write(sCELL_LM_REST_BGNY_DB , 0, nidx_acc,    nullif(abs(rACC.nGRP_REST_Y_BGN),0));
              else perform p_excel_cell_value_write(sCELL_LM_REST_BGNY_CR , 0, nidx_acc,    nullif(abs(rACC.nGRP_REST_Y_BGN),0));
              end if;
              /*Остатка на конец года в таблице нет!*/
         
              /*Обороты за период*/
              /*Дебет*/
              if rACC.nGRP_TURN_P_DB<>0
              then perform p_excel_cell_value_write(sCELL_LM_TURN_P_DB , 0, nidx_acc,    rACC.nGRP_TURN_P_DB);
              end if;
              /*Кредит*/
              if rACC.nGRP_TURN_P_CR<>0
              then perform p_excel_cell_value_write(sCELL_LM_TURN_P_CR , 0, nidx_acc,    rACC.nGRP_TURN_P_CR);
              end if;
              /*Обороты за год*/
              /*Дебет*/
              if rACC.nGRP_TURN_Y_DB<>0
              then perform p_excel_cell_value_write(sCELL_LM_TURN_Y_DB , 0, nidx_acc,    rACC.nGRP_TURN_Y_DB);
              end if;
              /*Кредит*/
              if rACC.nGRP_TURN_Y_CR<>0
              then perform p_excel_cell_value_write(sCELL_LM_TURN_Y_CR , 0, nidx_acc,    rACC.nGRP_TURN_Y_CR);
              end if;

              /*Делаем шрифт жирным*/
              perform p_excel_cell_attribute_set(sCELL_LM_NUM , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_ACC , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              
              perform p_excel_cell_attribute_set(sCELL_LM_REST_BGNP_DB , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_REST_BGNP_CR , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_REST_ENDP_DB , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_REST_ENDP_CR , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_REST_BGNY_DB , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_REST_BGNY_CR , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_TURN_P_DB , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_TURN_P_CR , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_TURN_Y_DB , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              perform p_excel_cell_attribute_set(sCELL_LM_TURN_Y_CR , 0, nidx_acc, 'Font.FontStyle', 'Bold');
              
         end if;

         /*Данные текущего Счета+КОСГУ*/
         nidx := p_excel_line_continue(sLINE_MAIN);
         perform p_excel_cell_value_write(sCELL_LM_ACC , 0, nidx,    rACC.sACCOUNT);

         /*Остаток на начало периода*/
         if rACC.nREST_P_BGN>=0
         then perform p_excel_cell_value_write(sCELL_LM_REST_BGNP_DB , 0, nidx,   nullif(abs(rACC.nREST_P_BGN),0));
         else perform p_excel_cell_value_write(sCELL_LM_REST_BGNP_CR , 0, nidx,    nullif(abs(rACC.nREST_P_BGN),0));
         end if;
         /*Остаток на конец периода*/
         if rACC.nREST_P_END>=0
         then perform p_excel_cell_value_write(sCELL_LM_REST_ENDP_DB , 0, nidx,    nullif(abs(rACC.nREST_P_END),0));
         else perform p_excel_cell_value_write(sCELL_LM_REST_ENDP_CR , 0, nidx,    nullif(abs(rACC.nREST_P_END),0));
         end if;
         
         /*Остаток на начало года*/
         if rACC.nREST_Y_BGN>=0
         then perform p_excel_cell_value_write(sCELL_LM_REST_BGNY_DB , 0, nidx,    nullif(abs(rACC.nREST_Y_BGN),0));
         else perform p_excel_cell_value_write(sCELL_LM_REST_BGNY_CR , 0, nidx,    nullif(abs(rACC.nREST_Y_BGN),0));
         end if;
         /*Остатка на конец года в таблице нет!*/
         
         /*Обороты за период*/
         /*Дебет*/
         if rACC.nTURN_P_DB<>0
         then perform p_excel_cell_value_write(sCELL_LM_TURN_P_DB , 0, nidx,    rACC.nTURN_P_DB);
         end if;
         /*Кредит*/
         if rACC.nTURN_P_CR<>0
         then perform p_excel_cell_value_write(sCELL_LM_TURN_P_CR , 0, nidx,    rACC.nTURN_P_CR);
         end if;
         /*Обороты за год*/
         /*Дебет*/
         if rACC.nTURN_Y_DB<>0
         then perform p_excel_cell_value_write(sCELL_LM_TURN_Y_DB , 0, nidx,    rACC.nTURN_Y_DB);
         end if;
         /*Кредит*/
         if rACC.nTURN_Y_CR<>0
         then perform p_excel_cell_value_write(sCELL_LM_TURN_Y_CR , 0, nidx,    rACC.nTURN_Y_CR);
         end if;
         
         /*Накапливаем общие РАЗВЕРНУТЫЕ итоги по балансовым/забалансовым счетам*/
         if rACC.nREST_Y_BGN>=0
         then rACCTYPE.nREST_Y_BGN_DB := rACCTYPE.nREST_Y_BGN_DB + rACC.nREST_Y_BGN;
         else rACCTYPE.nREST_Y_BGN_CR := rACCTYPE.nREST_Y_BGN_CR + abs(rACC.nREST_Y_BGN);
         end if;
         if rACC.nREST_P_BGN>=0
         then rACCTYPE.nREST_P_BGN_DB := rACCTYPE.nREST_P_BGN_DB + rACC.nREST_P_BGN;
         else rACCTYPE.nREST_P_BGN_CR := rACCTYPE.nREST_P_BGN_CR + abs(rACC.nREST_P_BGN);
         end if;
         if rACC.nREST_P_END>=0
         then rACCTYPE.nREST_P_END_DB := rACCTYPE.nREST_P_END_DB + rACC.nREST_P_END;
         else rACCTYPE.nREST_P_END_CR := rACCTYPE.nREST_P_END_CR + abs(rACC.nREST_P_END);
         end if;
         
         rACCTYPE.nTURN_P_DB  := rACCTYPE.nTURN_P_DB  + rACC.nTURN_P_DB;
         rACCTYPE.nTURN_P_CR  := rACCTYPE.nTURN_P_CR  + rACC.nTURN_P_CR;
         rACCTYPE.nTURN_Y_DB  := rACCTYPE.nTURN_Y_DB  + rACC.nTURN_Y_DB;
         rACCTYPE.nTURN_Y_CR  := rACCTYPE.nTURN_Y_CR  + rACC.nTURN_Y_CR;

         /*Цикл по всем ордерам принудительного включения для проводок текущего счета+КОСГУ*/
         for rORD in (select /*Ордер проводки*/
                             m.id    nORDER,
                             m.code  sORDER,
                             m.name  sORDER_NAME,
                             
                             /*Обороты проводки в периодах*/
                             /*Период-Дебет*/
                             p_get_acc_turn(p_report_general_ledger.id, 
                                            p_report_general_ledger.begindate,
                                            p_report_general_ledger.enddate,
                                            rACC.nKFO, /*КФО - id*/
                                            rACC.nKPS, /*КПС - id*/
                                            rACC.nACC, /*Счет - id*/
                                            -1,        /*Направление расходов*/
                                            rACC.nEC,  /*КОСГУ - id*/
                                            m.id,      /*Ордер - id*/
                                            1          /*Дебетовый оборот*/
                                            ) nTURN_P_DB,
                             /*Период-Кредит*/
                             p_get_acc_turn(p_report_general_ledger.id, 
                                            p_report_general_ledger.begindate,
                                            p_report_general_ledger.enddate,
                                            rACC.nKFO, /*КФО - id*/
                                            rACC.nKPS, /*КПС - id*/
                                            rACC.nACC, /*Счет - id*/
                                            -1,        /*Направление расходов*/
                                            rACC.nEC,  /*КОСГУ - id*/
                                            m.id,      /*Ордер - id*/
                                            2          /*Кредитовый оборот*/
                                            ) nTURN_P_CR,

                             /*Год-Дебет*/
                             p_get_acc_turn(p_report_general_ledger.id, 
                                            NULL::date,
                                            p_report_general_ledger.enddate,
                                            rACC.nKFO, /*КФО - id*/
                                            rACC.nKPS, /*КПС - id*/
                                            rACC.nACC, /*Счет - id*/
                                            -1,        /*Направление расходов*/
                                            rACC.nEC,  /*КОСГУ - id*/
                                            m.id,      /*Ордер - id*/
                                            1          /*Дебетовый оборот*/
                                            ) nTURN_Y_DB,
                             /*Год-Кредит*/
                             p_get_acc_turn(p_report_general_ledger.id, 
                                            NULL::date,
                                            p_report_general_ledger.enddate,
                                            rACC.nKFO, /*КФО - id*/
                                            rACC.nKPS, /*КПС - id*/
                                            rACC.nACC, /*Счет - id*/
                                            -1,        /*Направление расходов*/
                                            rACC.nEC,  /*КОСГУ - id*/
                                            m.id,      /*Ордер - id*/
                                            2          /*Кредитовый оборот*/
                                            ) nTURN_Y_CR,

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
                                left join econclass kec on kec.id=s.kteconclassktid, /*КОСГУ-кредит*/
                             memorder m /*Ордер для проводки*/

                       where t.id=p_report_general_ledger.id
                         and d.transactionlogid=t.id
                         and s.transactionlog_docsid=d.id

                         /*Проводки до даты "По", т.к. нужны обороты и с начала года*/
                         and d.transactiondate <= p_report_general_ledger.enddate

                         /*Проводки текущего счета и КОСГУ*/
                         and ((    s.dtfinsecurity=rACC.nKFO /*КФО - id*/
                               and dacs.id = rACC.nKPS       /*КПС - id*/
                               and dt.id   = rACC.nACC       /*Счет - id*/
                               and dec.id  = rACC.nEC        /*КОСГУ - id*/
                              )
                              or
                              (    s.ktfinsecurity=rACC.nKFO /*КФО - id*/
                               and kacs.id = rACC.nKPS       /*КПС - id*/
                               and kt.id   = rACC.nACC       /*Счет - id*/
                               and kec.id  = rACC.nEC        /*КОСГУ - id*/
                              ))
                         and m.id=s.memorderid
                       group by m.id, m.code, m.name
                       order by m.code
                     )
         loop
              rORD.nidx := p_excel_line_continue(sLINE_MAIN);
              /*Обороты*/
              if rORD.nTURN_P_DB<>0
              then perform p_excel_cell_value_write(sCELL_LM_TURN_P_DB , 0, rORD.nidx, rORD.nTURN_P_DB);
              end if;
              if rORD.nTURN_P_CR<>0
              then perform p_excel_cell_value_write(sCELL_LM_TURN_P_CR , 0, rORD.nidx, rORD.nTURN_P_CR);
              end if;
              
              /*Обороты за год в ордерах не нужны	
              if rORD.nTURN_Y_DB<>0
              then perform p_excel_cell_value_write(sCELL_LM_TURN_Y_DB , 0, rORD.nidx, rORD.nTURN_Y_DB);
              end if;
              if rORD.nTURN_Y_CR<>0
              then perform p_excel_cell_value_write(sCELL_LM_TURN_Y_CR , 0, rORD.nidx, rORD.nTURN_Y_CR);
              end if;*/
              
              /*Ордер*/
              perform p_excel_cell_value_write(sCELL_LM_ORDER , 0, rORD.nidx, rORD.sORDER);

         end loop;

    end loop;
    
    /*РАЗВЕРНУТЫЕ Итоги по балансовым/забалансовым счетам, если они были*/
    if nNUM>0
    then
         nidx := p_excel_line_continue(sLINE_ITG);
         perform p_excel_cell_value_write(sCELL_LI_ACC , 0, nidx,    rACCTYPE.sFOOT);

         /*Остаток на начало периода*/
         perform p_excel_cell_value_write(sCELL_LI_REST_BGNP_DB , 0, nidx,   nullif(abs(rACCTYPE.nREST_P_BGN_DB),0));
         perform p_excel_cell_value_write(sCELL_LI_REST_BGNP_CR , 0, nidx,    nullif(abs(rACCTYPE.nREST_P_BGN_CR),0));
         /*Остаток на конец периода*/
         perform p_excel_cell_value_write(sCELL_LI_REST_ENDP_DB , 0, nidx,    nullif(abs(rACCTYPE.nREST_P_END_DB),0));
         perform p_excel_cell_value_write(sCELL_LI_REST_ENDP_CR , 0, nidx,    nullif(abs(rACCTYPE.nREST_P_END_CR),0));
         /*Остаток на начало года*/
         perform p_excel_cell_value_write(sCELL_LI_REST_BGNY_DB , 0, nidx,    nullif(abs(rACCTYPE.nREST_Y_BGN_DB),0));
         perform p_excel_cell_value_write(sCELL_LI_REST_BGNY_CR , 0, nidx,    nullif(abs(rACCTYPE.nREST_Y_BGN_CR),0));
         /*Остатка на конец года в таблице нет!*/
         
         /*Обороты за период*/
         /*Дебет*/
         if rACCTYPE.nTURN_P_DB<>0
         then perform p_excel_cell_value_write(sCELL_LI_TURN_P_DB , 0, nidx,    rACCTYPE.nTURN_P_DB);
         end if;
         /*Кредит*/
         if rACCTYPE.nTURN_P_CR<>0
         then perform p_excel_cell_value_write(sCELL_LI_TURN_P_CR , 0, nidx,    rACCTYPE.nTURN_P_CR);
         end if;
         /*Обороты за год*/
         /*Дебет*/
         if rACCTYPE.nTURN_Y_DB<>0
         then perform p_excel_cell_value_write(sCELL_LI_TURN_Y_DB , 0, nidx,    rACCTYPE.nTURN_Y_DB);
         end if;
         /*Кредит*/
         if rACCTYPE.nTURN_Y_CR<>0
         then perform p_excel_cell_value_write(sCELL_LI_TURN_Y_CR , 0, nidx,    rACCTYPE.nTURN_Y_CR);
         end if;
         
         /*Вставляем строку-разделитель*/
         nidx := p_excel_line_continue(sLINE_SPLIT);
    end if;
    
  end loop;

  /*Удаляем оброзцы строк*/
  perform p_excel_line_delete(sLINE_MAIN);
  perform p_excel_line_delete(sLINE_ITG);
  perform p_excel_line_delete(sLINE_SPLIT);
  

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

COMMENT ON FUNCTION public.p_report_general_ledger(id bigint, begindate date, enddate date, gbpersonid bigint, postsid bigint, bpersonid bigint)
IS 'Процедура для отчета "Главная книга"';

ALTER FUNCTION public.p_report_general_ledger (id bigint, begindate date, enddate date, gbpersonid bigint, postsid bigint, bpersonid bigint)
  OWNER TO postgres;