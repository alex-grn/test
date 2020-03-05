CREATE OR REPLACE FUNCTION public.p_action_calctabags_calc (
  YEARCALC integer,
  PERCALC  TEXT,
  RECREATE BOOLEAN,
  UID 	   bigint default null
)
RETURNS void AS
$body$
 declare
 nYEARCALC   calctabags.yearcalc%type := YEARCALC;
 sPERCALC    calctabags.percalc%type := PERCALC;
 rCalctabags calctabags%ROWTYPE; -- запись раздела "Расчетная таблица 1 - АГС"
 sID 		 text;
 sSTATUSCALC calctabags.statuscalc%type := '2'; -- статус рассчитан
 sres        text = '';
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
       if sres = ''
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
     end if;

     -- основной сбор
     -- Граждане
     --<AI id="1" name="Весна"/>
     --<AI id="2" name="Осень"/>
     -- Расчетная таблица 1 - АГС
     --<AI id="1" name="Февраль - Июль"/>
     --<AI id="2" name="Август - Январь"/>
     --select * from REGAGS
      insert into REGAGS(lid, uid, calctabagsid, feddisid, quant, regiondirid)
      select rCalctabags.lid, rCalctabags.uid, rCalctabags.Id, rd.districtfederal::bigint, count(1), cy.regiondirid
        from CITIZENRY cy,
             regiondir rd
       where cy.statuscitizen = '3'
         and cy.yearconscription = YEARCALC
         and cy.conscription = PERCALC
         and cy.regiondirid = rd.id
         group by rd.districtfederal,
         		  cy.regiondirid;

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

ALTER FUNCTION public.p_action_calctabags_calc (YEARCALC integer, PERCALC TEXT, RECREATE BOOLEAN, UID bigint)
  OWNER TO magicbox;