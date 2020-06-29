CREATE OR REPLACE FUNCTION public.p_get_acc_turn (
  ntransactionlogid bigint,
  dbegin date,
  dend date,
  nfinsecurity numeric,
  nbudgclass numeric,
  ndicaccs numeric,
  ntypeexp numeric = '-1'::integer,
  neconclass numeric = '-1'::integer,
  nmemorder numeric = '-1'::integer,
  nsign numeric = 0,
  nagent numeric = '-1'::integer,
  nperson numeric = '-1'::integer,
  nmtresponspers numeric = '-1'::integer
)
RETURNS numeric AS
$body$
DECLARE
 nTURN_DB numeric:=0;
 nTURN_CR numeric:=0;
 nRESULT  numeric:=0;
BEGIN

     select sum(m.nSUM_DB),
            sum(m.nSUM_CR)
       into nTURN_DB,
            nTURN_CR
       from (select /*Дебет*/
                    s.summ          nSUM_DB,
                    0::numeric      nSUM_CR

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

                /*Проводки в периоде*/
                and d.transactiondate BETWEEN coalesce(dbegin,d.transactiondate) and coalesce(dend,d.transactiondate)
                
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
                /*Мемориальный ордер*/
                and (nmemorder=-1 or /*Любой ордер*/
                     s.memorderid=nmemorder or /*конкретный ордер*/
                     (nmemorder is null and s.memorderid is null)) /*Не задано*/
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
                    0::numeric      nSUM_DB,
                    s.summ          nSUM_CR

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

                /*Проводки в периоде*/
                and d.transactiondate BETWEEN coalesce(dbegin,d.transactiondate) and coalesce(dend,d.transactiondate)
                
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
                /*Мемориальный ордер*/
                and (nmemorder=-1 or /*Любой ордер*/
                     s.memorderid=nmemorder or /*конкретный ордер*/
                     (nmemorder is null and s.memorderid is null)) /*Не задано*/
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

  /*Забираем нужный оборот в зависимости от параметра nsign*/
  if nsign=1
  then nRESULT:=nTURN_DB;/*Дебет*/
  elsif nsign=2
  then nRESULT:=nTURN_CR;/*Кредит*/
  else nRESULT:=nTURN_DB-nTURN_CR;/*Дебет-Кредит*/
  end if;
  
  nRESULT:=COALESCE(nRESULT,0);
  return(nRESULT);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

COMMENT ON FUNCTION public.p_get_acc_turn(ntransactionlogid bigint, dbegin date, dend date, nfinsecurity numeric, nbudgclass numeric, ndicaccs numeric, ntypeexp numeric, neconclass numeric, nmemorder numeric, nsign numeric, nagent numeric, nperson numeric, nmtresponspers numeric)
IS 'Функция получения оборотов по заданному счету за период по зприси раздела "Журнал операций"
Параметр nsign in (0,1,2) => (Дебет-Кредит,Дебет,Кредит)
Необязательные поля параметров могут иметь 
"NULL"-значение (отбор проводок с атрибутом is NULL) или 
"-1"-значение, при котором поле в отборе не участвует.
Параметр nmemorder - id мемориального ордера проводки (принудительное включение)
';

ALTER FUNCTION public.p_get_acc_turn (ntransactionlogid bigint, dbegin date, dend date, nfinsecurity numeric, nbudgclass numeric, ndicaccs numeric, ntypeexp numeric, neconclass numeric, nmemorder numeric, nsign numeric, nagent numeric, nperson numeric, nmtresponspers numeric)
  OWNER TO postgres;