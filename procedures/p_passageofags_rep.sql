CREATE OR REPLACE FUNCTION public.p_passageofags_rep (
  IDENT            bigint,
  YEARCONSCRIPTION bigint,
  CONSCRIPTION	   text,
  TYPEOFLEAVEDIRID text,
  BASIS2		   text,
  clear 	 	   boolean
)
RETURNS void AS
$body$
declare
  nident            bigint := ident;
  nYEARCONSCRIPTION bigint := YEARCONSCRIPTION;
  sCONSCRIPTION 	text := CONSCRIPTION;
  nTYPEOFLEAVEDIRID bigint := TYPEOFLEAVEDIRID;
  sBASIS2			text := BASIS2;
  rec record;
  nsort_row 	    bigint;
begin
  if CLEAR
  then
	-- чистка
	delete from PASSAGEOFAGS_REP PR where PR.id_rep = NIDENT;
  --raise using message = NIDENT;
  else
	-- чистка
	delete from PASSAGEOFAGS_REP PR where PR.id_rep = NIDENT;

    -- наполняем ФИО
    insert into PASSAGEOFAGS_REP
         select nident,
         		C.ID,
                0,
                case when trim(C.lastname) is not null then trim(C.lastname) else '' end ||' '||
                case when trim(C.firstname) is not null then trim(C.firstname) else '' end ||' '||
                case when trim(C.patronymic) is not null then trim(C.patronymic) else '' end as FIO,
                ltrim(case when trim(C.seriesp::text) is not null then trim(C.seriesp::text) else '' end||
                rtrim('-'||case when trim(C.numberp::text) is not null then trim(C.numberp::text) else '' end, '-'), '-') as pers_document
           from CITIZENRY C,
                PLANS	 P
          where C.plansid = P.ID
            and (nYEARCONSCRIPTION is null or p.yearconscription::bigint = nYEARCONSCRIPTION)
            and (sCONSCRIPTION is null or p.conscription::text = sCONSCRIPTION)
            and (nTYPEOFLEAVEDIRID is null and sBASIS2 is null or
                exists(select 1
                	     from PASSAGEAGSCIT PA
                        where PA.citizenryid = C.ID
                 	      and (nTYPEOFLEAVEDIRID is null or PA.typeofleavedirid = nTYPEOFLEAVEDIRID)
                 		  and (sBASIS2 is null or PA.basis2 = sBASIS2)));
    -- наполнение отпускми
    nsort_row := 0;
    for rec in
      (select PA.citizenryid,
      		  COALESCE(TD.name,'!Не определен') as vac_t,
              to_char(PA.vacations,'dd.mm.yyyy')||'-'||to_char(PA.vacationpo,'dd.mm.yyyy') as vac_p,
              case PA.basis2
                when '1' then
                'Дополнительный за особый характер работы'
                when '2' then
                'Дополнительный по семейным обстоятельствам'
                when '3' then
                'Дополнительный, обучающимся в учебных заведениях'
                when '4' then
                'Ежегодный'
                else
                '!Не определен'
              end as vac_v,
              null::bigint as ident_tmp
         from PASSAGEAGSCIT PA
         left join TYPEOFLEAVEDIR TD on PA.typeofleavedirid = TD.ID
         where EXISTS(select 1 from PASSAGEOFAGS_REP P where P.id_rep = NIDENT and PA.citizenryid = P.ID_ROW)
           and (PA.vacations is not null or PA.vacationpo is not null or PA.basis2 is not null or PA.typeofleavedirid is not null)
         order by PA.citizenryid, PA.vacations, PA.vacationpo)
    loop
      -- поиск
        select ru.id_rep
          into rec.ident_tmp
          from PASSAGEOFAGS_REP RU
         where RU.id_rep = NIDENT
           and RU.id_row = REC.citizenryid
           and RU.sort_row = nsort_row
           and ru.vac_period is null
           and ru.vac_type is null
           and ru.vac_valid is null;
      if rec.ident_tmp is not null then
        update PASSAGEOFAGS_REP RU
           set vac_period = rec.vac_p,
               vac_type	  = rec.vac_t,
               vac_valid  = rec.vac_v
         where RU.id_rep = NIDENT
           and RU.id_row = REC.citizenryid
           and RU.sort_row = nsort_row
           and ru.vac_period is null
           and ru.vac_type is null
           and ru.vac_valid is null;
      else
        insert into PASSAGEOFAGS_REP(id_rep, id_row, sort_row, vac_period, vac_type, vac_valid)
          values(nident, REC.citizenryid, nsort_row, rec.vac_p, rec.vac_t, rec.vac_v);
      end if;
	  nsort_row := nsort_row + 1;
    end loop;

    -- не засчитанные периоды
    nsort_row := 0;
    for rec in
      (select PA.citizenryid,
      		  to_char(PA.unpaidperiods,'dd.mm.yyyy')||'-'||to_char(PA.unpaidperiodpo,'dd.mm.yyyy') as unpaid_p,
              case PA.basis3
                when '1' then
                'Время нахождения в дополнительных отпусках, предостовляемых работодателем гражданам, обучающимся в образовательных учреждениях'
                when '2' then
                'Время нахождения в отпусках без сохранения заработной платы'
                when '3' then
                'Время отбывания уголовного или административного наказания в качестве ареста'
                when '4' then
                'Время отстранения от работы по причине алкогольного, наркотического или иного токсичного опьянения'
                when '5' then
                'Прогулы (отсутствие на рабочем месте без уважительных причин более четырех часов подряд в течении рабочего дня)'
                else
                '!Не определен'
              end as unpaid_v,
              null::bigint as ident_tmp
         from PASSAGEAGSCIT PA
         where EXISTS(select 1 from PASSAGEOFAGS_REP P where P.id_rep = NIDENT and PA.citizenryid = P.ID_ROW)
           and (PA.unpaidperiods is not null or PA.unpaidperiodpo is not null or PA.basis3 is not null)
         order by PA.citizenryid, PA.unpaidperiods, PA.unpaidperiodpo)
    loop
      -- поиск
        select ru.id_rep
          into rec.ident_tmp
          from PASSAGEOFAGS_REP RU
         where RU.id_rep = NIDENT
           and RU.id_row = REC.citizenryid
           and RU.sort_row = nsort_row
           and ru.unpaid_period is null
           and ru.unpaid_valid is null;
      if rec.ident_tmp is not null then
        update PASSAGEOFAGS_REP RU
           set unpaid_period = rec.unpaid_p,
               unpaid_valid  = rec.unpaid_v
         where RU.id_rep = NIDENT
           and RU.id_row = REC.citizenryid
           and RU.sort_row = nsort_row
           and ru.unpaid_period is null
           and ru.unpaid_valid is null;
      else
        insert into PASSAGEOFAGS_REP(id_rep, id_row, sort_row, unpaid_period, unpaid_valid)
          values(nident, REC.citizenryid, nsort_row, rec.unpaid_p, rec.unpaid_v);
      end if;
	  nsort_row := nsort_row + 1;
    end loop;
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_passageofags_rep (ident bigint, yearconscription bigint, conscription text, typeofleavedirid text, basis2 text, clear boolean)
  OWNER TO magicbox;