CREATE OR REPLACE FUNCTION public.p_get_acc_rest (
  ntransactionlogid bigint,
  drestdate date,
  nfinsecurity numeric,
  nbudgclass bigint,
  ndicaccs bigint,
  ntypeexp bigint = '-1'::integer,
  neconclass bigint = '-1'::integer,
  nagent bigint = '-1'::integer,
  nperson bigint = '-1'::integer,
  nmtresponspers bigint = '-1'::integer
)
RETURNS numeric AS
$body$
DECLARE
   nSUM numeric;
BEGIN
     select sum(m.nsum)
       into nSUM
       from (select /*Дебет*/
                    /*Дебитовая сумма с плюсом*/
                    s.summ          nSUM

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

              where t.id=ntransactionlogid
                and d.transactionlogid=t.id
                and s.transactionlog_docsid=d.id

                /*Проводки до даты drestdate*/
                and d.transactiondate<drestdate
                
                and s.dtfinsecurity=nfinsecurity /*КФО*/
                and s.dtbudgclassid=nbudgclass /*КПС*/
                and s.accountdtid=ndicaccs /*Счет*/
                
                /*Направление расходов*/
                and (ntypeexp=-1 or /*любое (без учета направления)*/
                     s.dttypeexpid=ntypeexp or /*конкретное*/
                     (ntypeexp is null and s.dttypeexpid is null)) /*Не задано*/
                /*КОСГУ*/
                and (neconclass=-1 or /*любое (без учета КОСГУ)*/
                     s.dteconclassktid=neconclass or /*конкретное*/
                     (neconclass is null and s.dteconclassktid is null)) /*Не задано*/
                /*Юр.лицо*/
                and (nagent=-1 or /*любое (без учета юр.лица)*/
                     s.agentdtid=nagent or /*конкретное*/
                     (nagent is null and s.agentdtid is null)) /*Не задано*/
                /*Физ.лицо*/
                and (nperson=-1 or /*любое (без учета физ.лица)*/
                     s.persondtid=nperson or /*конкретное*/
                     (nperson is null and s.persondtid is null)) /*Не задано*/
                /*МОЛ*/
                and (nmtresponspers=-1 or /*любое (без учета МОЛ)*/
                     s.dtrespperson=nmtresponspers or /*конкретное*/
                     (nmtresponspers is null and s.dtrespperson is null)) /*Не задано*/

             union all

             select /*Кредит*/
                    /*Кредитовая сумма с минусом*/
                    -s.summ         nSUM

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

              where t.id=ntransactionlogid
                and d.transactionlogid=t.id
                and s.transactionlog_docsid=d.id

                /*Проводки до даты drestdate*/
                and d.transactiondate<drestdate
                
                and s.ktfinsecurity=nfinsecurity /*КФО*/
                and s.ktbudgclassid=nbudgclass /*КПС*/
                and s.accountktid=ndicaccs /*Счет*/
                
                /*Направление расходов*/
                and (ntypeexp=-1 or /*любое (без учета направления)*/
                     s.kttypeexpid=ntypeexp or /*конкретное*/
                     (ntypeexp is null and s.kttypeexpid is null)) /*Не задано*/
                /*КОСГУ*/
                and (neconclass=-1 or /*любое (без учета КОСГУ)*/
                     s.kteconclassktid=neconclass or /*конкретное*/
                     (neconclass is null and s.kteconclassktid is null)) /*Не задано*/
                /*Юр.лицо*/
                and (nagent=-1 or /*любое (без учета юр.лица)*/
                     s.agentktid=nagent or /*конкретное*/
                     (nagent is null and s.agentktid is null)) /*Не задано*/
                /*Физ.лицо*/
                and (nperson=-1 or /*любое (без учета физ.лица)*/
                     s.personktid=nperson or /*конкретное*/
                     (nperson is null and s.personktid is null)) /*Не задано*/
                /*МОЛ*/
                and (nmtresponspers=-1 or /*любое (без учета МОЛ)*/
                     s.ktrespperson=nmtresponspers or /*конкретное*/
                     (nmtresponspers is null and s.ktrespperson is null)) /*Не задано*/

            ) m;

    nSUM:=COALESCE(nSUM,0);
    return(nSUM);
               
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_get_acc_rest (ntransactionlogid bigint, drestdate date, nfinsecurity numeric, nbudgclass bigint, ndicaccs bigint, ntypeexp bigint, neconclass bigint, nagent bigint, nperson bigint, nmtresponspers bigint)
  OWNER TO postgres;