CREATE OR REPLACE FUNCTION public.p_schedule_employees_import(uid bigint DEFAULT 1) RETURNS text AS
$body$
declare
  nUID         bigint := UID;
  emp          record;
  nINS         bigint := 0;
  nUPD         bigint := 0;
  nlevaccessid bigint;
  nownerid     bigint;
begin
  -- загрузка сотрудников
  for emp in select m.*, 
                   (select k.keyin from keys k where k.tablenameout = m.tablenameout and k.keyout = m.rn::text) as id
              from (select 'DEMOCP_EMPLOYEES' as tablenameout, t.* from DEMOCP_EMPLOYEES t
                    union all
                    select 'ROSTRUD_EMPLOYEES' as tablenameout, t.* from ROSTRUD_EMPLOYEES t
                   ) m
  loop

     select l.id into nlevaccessid from levaccess l where l.name = emp.company;
     if nlevaccessid is null then
       insert into levaccess(name, uid) values (emp.company, nUID) returning id into nlevaccessid;
     end if;

     emp.owner = emp.company; -- ќказалось одно и тоже

     select w.id into nownerid from owner w where w.code = emp.owner;
     if nownerid is null then
       insert into owner(code, name, lid, uid) values (emp.owner, emp.owner, nlevaccessid, nUID) returning id into nownerid;
     end if;

     if emp.id is not null then
       update employees t
          set (ownerid, code, surname, firstname, middlename, post, establishment, datereceipt, datedismissal, condition)
            = (nownerid, emp.code, emp.surname, emp.firstname, emp.middlename, emp.post, emp.establishment, emp.datereceipt, emp.datedismissal, emp.condition)
        where t.id = emp.id returning id into emp.id;
       if emp.id is not null then
         nUPD = nUPD + 1;  
       else   
         delete from keys where tablenameout = emp.tablenameout and keyout = emp.rn::text;
       end if;  
     end if;

     if emp.id is null then
       insert into employees (ownerid, code, surname, firstname, middlename, post, establishment, datereceipt, datedismissal, condition, lid, uid)
         values (nownerid, emp.code, emp.surname, emp.firstname, emp.middlename, emp.post, emp.establishment, emp.datereceipt, emp.datedismissal, emp.condition, nlevaccessid, nUID) 
         returning id into emp.id;
       insert into keys (tablenameout, keyout, tablenamein, keyin, lid, uid) values (emp.tablenameout, emp.rn, 'EMPLOYEES', emp.id, nlevaccessid, nUID);
       nINS = nINS + 1;  
     else
     end if;   

  end loop;

  return '«агружено записей: '||nINS||', изменено записей: '||nUPD||'.';
end;
$body$
language plpgsql volatile;
