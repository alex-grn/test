-- Function: public.p_action_status_cln_events(text, text, text, numeric, text)

-- DROP FUNCTION public.p_action_status_cln_events(text, text, text, numeric, text);

CREATE OR REPLACE FUNCTION public.p_action_status_cln_events(
    idlist text,
    tablename text,
    status_cln_events text,
    executor_id numeric,
    note text)
  RETURNS bigint AS
$BODY$
declare
sCurrStatus character;
sNote text = note;
nCounter numeric;
rec record;
  /* Процедура меняет значение статуса в таблице и заполняет историю стаусов TABLENAME_STATUS   */
begin

/*        
--считываем текущий статус
BEGIN
  execute 'select status from '|| quote_ident(TABLENAME)||' where ID = ANY(P_SYSTEM_GET_SELECTLIST($1))' into sCurrStatus  using idlist;
--state_to - карта переходов
select count(*):: numeric into nCounter from
(
with r AS (
  select '0' code,'Архив' state_from, ARRAY[ '1','2'] state_to union
  select '1'     ,'Черновик'       ,ARRAY['2','0'] union
  select '2'	 ,'На согласовании'        ,ARRAY['3','1','0'] union 
  select '3'	 ,'Согласовано' ,ARRAY['2','1','0']  
 ) 
SELECT unnest(r.state_to) as state_to
  FROM r where  r.code = sCurrStatus 
) t where  t.state_to = status; 
  
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
     RAISE EXCEPTION 'Запись % id= % не найдена', tablename, idlist;
  WHEN TOO_MANY_ROWS THEN
            RAISE EXCEPTION 'Найдено много записей %  id= % ',tablename, idlist;
  WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка поиска записей %  id= % ', tablename, idlist;
END;

  if nCounter=0 then
     BEGIN   RAISE EXCEPTION 'Переход: % -> % не предусмотрен', 
             (select coalesce((array['Архив', 'Черновик', 'На согласовании','Согласовано' ])[sCurrStatus::INTEGER+1], 'Null') ), 
             (select coalesce((array['Архив', 'Черновик', 'На согласовании','Согласовано' ])[status::INTEGER+1], 'Null') )
           ; 
     END;
  else
       execute 'update '|| quote_ident(TABLENAME)||' set STATUS = $1 where ID = ANY(P_SYSTEM_GET_SELECTLIST($2))' using status, idlist;
   end if;
*/
execute 'update cln_events set status_cln_events = $1 ,  executor_id = $2 where ID = ANY(P_SYSTEM_GET_SELECTLIST($3))' 
using status_cln_events, executor_id, idlist;

  for rec in (
    select max(id) as id from cln_events_hist where cln_events_ID = ANY(P_SYSTEM_GET_SELECTLIST(idlist)) 
    )
    loop
          update cln_events_hist set note = sNote  where id=rec.id;
    end loop;

/*
     r=P_SYSTEM_GET_SELECTLIST(idlist);
     FOR i IN 1..array_length(r, 1) LOOP
 --    execute ' insert into '|| quote_ident( TABLENAME) ||'_STATUS ( ' || quote_ident( TABLENAME) ||'_ID, status, note ) values ( '||cast(r[i]  as text )||', $1, $2 )' using '0', note;
     execute 'update '|| quote_ident( TABLENAME) ||'_STATUS  set NOTE = $1  where  ' || quote_ident( TABLENAME) ||'_ID = '||cast(r[i]  as text )||
			' and NOTE is not null' using  note;
    END LOOP;


if status = 'Согласовано' then
--по каждому ФКУ (сделать раздельный доступ)
select p_set_levaccess_doc_fku( idlist ::text, tablename ::text);

end if;
*/

  return null;
end;
 $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_status_cln_events(text, text, text, numeric, text)
  OWNER TO magicbox;





-- Function: public.p_action_status_doc(text, text, text, text)

-- DROP FUNCTION public.p_action_status_doc(text, text, text, text);

CREATE OR REPLACE FUNCTION public.p_action_status_doc(
    idlist text,
    tablename text,
    status text,
    note text)
  RETURNS bigint AS
$BODY$
declare
sCurrStatus character;
nCounter numeric;
  /* Процедура меняет значение статуса в таблице и заполняет историю стаусов TABLENAME_STATUS   */
begin

/*        
--считываем текущий статус
BEGIN
  execute 'select status from '|| quote_ident(TABLENAME)||' where ID = ANY(P_SYSTEM_GET_SELECTLIST($1))' into sCurrStatus  using idlist;
--state_to - карта переходов
select count(*):: numeric into nCounter from
(
with r AS (
  select '0' code,'Архив' state_from, ARRAY[ '1','2'] state_to union
  select '1'     ,'Черновик'       ,ARRAY['2','0'] union
  select '2'	 ,'На согласовании'        ,ARRAY['3','1','0'] union 
  select '3'	 ,'Согласовано' ,ARRAY['2','1','0']  
 ) 
SELECT unnest(r.state_to) as state_to
  FROM r where  r.code = sCurrStatus 
) t where  t.state_to = status; 
  
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
     RAISE EXCEPTION 'Запись % id= % не найдена', tablename, idlist;
  WHEN TOO_MANY_ROWS THEN
            RAISE EXCEPTION 'Найдено много записей %  id= % ',tablename, idlist;
  WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка поиска записей %  id= % ', tablename, idlist;
END;

  if nCounter=0 then
     BEGIN   RAISE EXCEPTION 'Переход: % -> % не предусмотрен', 
             (select coalesce((array['Архив', 'Черновик', 'На согласовании','Согласовано' ])[sCurrStatus::INTEGER+1], 'Null') ), 
             (select coalesce((array['Архив', 'Черновик', 'На согласовании','Согласовано' ])[status::INTEGER+1], 'Null') )
           ; 
     END;
  else
       execute 'update '|| quote_ident(TABLENAME)||' set STATUS = $1 where ID = ANY(P_SYSTEM_GET_SELECTLIST($2))' using status, idlist;
   end if;
*/
execute 'update '|| quote_ident(TABLENAME)||' set STATUS = $1 where ID = ANY(P_SYSTEM_GET_SELECTLIST($2))' using status, idlist;


/*
     r=P_SYSTEM_GET_SELECTLIST(idlist);
     FOR i IN 1..array_length(r, 1) LOOP
 --    execute ' insert into '|| quote_ident( TABLENAME) ||'_STATUS ( ' || quote_ident( TABLENAME) ||'_ID, status, note ) values ( '||cast(r[i]  as text )||', $1, $2 )' using '0', note;
     execute 'update '|| quote_ident( TABLENAME) ||'_STATUS  set NOTE = $1  where  ' || quote_ident( TABLENAME) ||'_ID = '||cast(r[i]  as text )||
			' and NOTE is not null' using  note;
    END LOOP;
*/


  return null;
end;
 $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_action_status_doc(text, text, text, text)
  OWNER TO magicbox;



-- Function: public.p_errlog_ins(text, text, text, text, date)

-- DROP FUNCTION public.p_errlog_ins(text, text, text, text, date);

CREATE OR REPLACE FUNCTION public.p_errlog_ins(
    s_unit text,
    s_code text,
    s_name text,
    s_note text,
    d_docdate date DEFAULT NULL::date)
  RETURNS void AS
$BODY$
DECLARE 
--INSERT_SQL text := 'insert into errlog (docdate, unit, code, name, note ) values( cast( '''||to_char(d_docdate,'dd.mm.yyyy')||''' as date)||'','''||s_unit||''','''||s_code||''','''||s_name||''','''||s_note||''' )';

begin


insert into errlog(
	docdate,-- Дата
	unit, -- Раздел
	code, -- Мнемокод
	name, -- Наименование
	note  -- Примечание
)
values(
	d_docdate ,
	s_unit  ,
	s_code  ,
	s_name  ,
	s_note  
);


-- PERFORM dblink_exec( 'dbname=' ||current_database() ::text,  INSERT_SQL ::text);

END ; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_errlog_ins(text, text, text, text, date)
  OWNER TO magicbox;



-- Function: public.p_get_status_cln_events_name(text)

-- DROP FUNCTION public.p_get_status_cln_events_name(text);

CREATE OR REPLACE FUNCTION public.p_get_status_cln_events_name(s_id text)
  RETURNS text AS
$BODY$
DECLARE sRESULT TEXT ;
BEGIN
	sRESULT = NULL ;
SELECT (case s_id
when '0' then 'Аннулировано' 
when '1' then 'Новое' 
when '2' then 'В работе' 
when '3' then 'На уточнении' 
when '4' then 'На доработке' 
when '5' then 'Исполнено' 
else null
end ) ::text INTO sRESULT;

	RETURN trim(sRESULT);
END ; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_get_status_cln_events_name(text)
  OWNER TO magicbox;


-- Function: public.p_translit(character varying)

-- DROP FUNCTION public.p_translit(character varying);

CREATE OR REPLACE FUNCTION public.p_translit(p_string character varying)
  RETURNS character varying AS
$BODY$
--Транслитерация
--Отличие от ГОСТ 7.79-2000
--ё = e, а не yo
--ы = y`, а не y'
select 
replace(
replace(
replace(
replace(
replace(
replace(
replace(
replace(
replace(
translate(lower($1), 
'абвгдеёзийклмнопрстуфхцьъ ', 'abvgdeezijklmnoprstufхc_i_'),
'ж', 'zh'),
'ч', 'ch'),
'ш', 'sh'),
'щ', 'shh'),
'ы', 'y'),
'э', 'e'),
'ю', 'yu'),
'я', 'ya'),
'.', '')
;

$BODY$
  LANGUAGE sql IMMUTABLE
  COST 100;
ALTER FUNCTION public.p_translit(character varying)
  OWNER TO postgres;



-- Function: public.p_yes_no(bigint)

-- DROP FUNCTION public.p_yes_no(bigint);

CREATE OR REPLACE FUNCTION public.p_yes_no(n_val bigint)
  RETURNS boolean AS
$BODY$  
BEGIN

RETURN CASE WHEN sign(n_val) = 0  THEN FALSE 
		WHEN sign(n_val) = 1  THEN TRUE 
		ELSE NULL END ; 
END ; 		
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.p_yes_no(bigint)
  OWNER TO magicbox;

-- Function: public.t_cln_events_au()

-- DROP FUNCTION public.t_cln_events_au();

CREATE OR REPLACE FUNCTION public.t_cln_events_au()
  RETURNS trigger AS
$BODY$
 declare
  res text;
 begin 
   if (new.docdate <> old.docdate) or
(new.depart_id <> old.depart_id) or
(new.person_id <> old.person_id) or
(new.status_cln_events <> old.status_cln_events) or
(new.executor_id <> old.executor_id) or
(new.description <> old.description) or
(new.note <> old.note)   
   then
      --new.lid=1;
      insert into cln_events_hist (
		cln_events_id , -- События
		depart_id , -- Подразделения
		person_id , -- Автор
		status_cln_events  , -- Статус
		executor_id , -- Исполнитель
		description  , -- Описание
		note  -- Примечание
      )
values
(
		old.id , -- События
		old.depart_id , -- Подразделения
		old.person_id , -- Автор
		old.status_cln_events  , -- Статус
		old.executor_id , -- Исполнитель
		old.description  , -- Описание
		old.note  -- Примечание
);
   end if;
   return new;
 end;
 $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.t_cln_events_au()
  OWNER TO magicbox;



-- Function: public.t_message_au()

-- DROP FUNCTION public.t_message_au();

CREATE OR REPLACE FUNCTION public.t_message_au()
  RETURNS trigger AS
$BODY$
 declare
  res text;
 begin 
   if (new.status = '0')    
   then
      new.DATE_ARCHIVE=now();
   end if;
   return new;
 end;
 $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.t_message_au()
  OWNER TO magicbox;
