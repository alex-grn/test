CREATE OR REPLACE FUNCTION public.p_action_citizenryorg_fill (
  id bigint
)
RETURNS void AS
$body$
 declare
 /*создание записей "Организации гражданина"*/
 nID           bigint := id;
 sql           text;
 nCITIZENRYORG bigint; -- идентификатор "Организации гражданина"
 rec 		   record;
 begin
   -- запись гражданина в подчиненный раздел организаций "Организации гражданина"
   -- наличие включенного гражданина
   for rec in
   (select D.*,
           C.statuscitizen
      from direction d,
           citizenry C
     where d.citizenryid = nID
       and d.citizenryid = C.id
    union all
    select D.*,
           C.statuscitizen
      from direction d,
           citizenry C
     where d.id = nID
       and d.citizenryid = C.id)
   loop
     select O.id
       into nCITIZENRYORG
       from CITIZENRYORG O
      where O.organizationid = rec.organizationid
        and O.citizenryid = rec.citizenryid;
     if nCITIZENRYORG is null
     then
       insert into CITIZENRYORG(organizationid, statuscitizen, citizenryid, tariffrate, vacancyorgid)
         values(rec.organizationid, rec.statuscitizen, rec.citizenryid, 0, rec.vacancyorgid);
     end if;
   end loop;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_citizenryorg_fill (id bigint)
  OWNER TO magicbox;