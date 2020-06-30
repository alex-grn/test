CREATE OR REPLACE FUNCTION public.p_action_status_change (
  idlist text,
  uid bigint,
  date_fix date,
  status_from text,
  status_to text,
  date_fix_auto boolean = false
)
RETURNS void AS
$body$
declare
    NUID bigint = uid;
    rec record;
    stin text;	--расшифровка статуса строки
    stout text = (select case status_to 
                         when '0' then 'новый' 
                         when '1' then 'не вступил в силу' 
                         when '2' then 'вступил в силу' 
                         when '3' then 'передан в суд' 
                         when '4' then 'передан судебным приставам' 
                         when '5' then 'отменен (списан)' 
                         when '6' then 'оплачен'
                        end);	--расшифровка статуса перехода;
begin
/*
	Процедура перехода статусов в разделе "Администрирование штрафов"
    Статусы:
    	0 - новый
		1 - не вступил в силу
		2 - вступил в силу
		3 - передан в суд
		4 - передан судебным приставам
		5 - отменен (списан)
		6 - оплачен
    Переходы:
    	0 -> 1;
    	1 -> 2;
        2 -> 3,4;
        3 -> 2;
    Данные по переходам получаем из входных параметров: status_from, status_to.
*/
  for rec in 
     select f.id,
            f.docdate,
            f.statuseaf,
            f.docdate,
            case f.statuseaf 
              when '0' then 'новый' 
              when '1' then 'не вступил в силу' 
              when '2' then 'вступил в силу' 
              when '3' then 'передан в суд' 
              when '4' then 'передан судебным приставам' 
              when '5' then 'отменен (списан)' 
              when '6' then 'оплачен'
            end as sstatus
       from fine f 
      where f.id = ANY(P_SYSTEM_GET_SELECTLIST(idlist))
  loop
    STIN := rec.SSTATUS;
    if STIN is NULL then 
      raise using message = 'Входящий(текущий) статус NULL!';
    end if;
    if STOUT is NULL then
      raise using message = 'Входящий статус NULL!';
    end if;
    --проверка по переходам статуса
    if rec.STATUSEAF not in (select REGEXP_SPLIT_TO_TABLE(STATUS_FROM, ';')) then
      raise using MESSAGE = 'Из статуса «' || STIN || '» нельзя выполнить переход в статус «' || STOUT || '».';
    end if;
    --проверка на корректность ввода даты во входной параметр
    if exists (select 1 from FINEHISTORY F where F.FINEID = rec.ID AND F.DATESTART > DATE_FIX) then
      raise using MESSAGE = 'Дата изменения статуса не может быть меньше, чем дата последнего изменения!';
    end if;
    if DATE_FIX_AUTO THEN
       date_fix:=null;
    end if;
    --если statusto2, тогда нужно прибавить 10 дней
    if status_to = '2' then
      rec.DOCDATE:=rec.DOCDATE + interval '10 days';
    end if;
    update FINE F set STATUSEAF = STATUS_TO where F.ID = rec.ID and F.STATUSEAF in (select REGEXP_SPLIT_TO_TABLE(STATUS_FROM, ';'));	
     insert into FINEHISTORY
      (UID, FINEID, DATESTART, STATUSEAF, INSPERSONID, SUMMNEW, OWNERID)
      select NUID,
             F.ID,
             COALESCE(DATE_FIX,rec.DOCDATE),
             STATUS_TO,  --статус
             F.INSPERSONID, --новый инспектор
             F.SUMMDOC,   --сумма документа
             F.OWNERID
        from FINE F
       where F.ID = rec.ID;
  end loop;	
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_status_change (idlist text, uid bigint, date_fix date, status_from text, status_to text, date_fix_auto boolean)
  OWNER TO magicbox;