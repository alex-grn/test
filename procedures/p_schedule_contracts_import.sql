CREATE OR REPLACE FUNCTION p_schedule_contracts_import(uid bigint DEFAULT 1) RETURNS text AS
$body$
declare
  nUID         bigint := UID;
  cont         record;
  nINS         bigint := 0;
  nUPD         bigint := 0;
  nlevaccessid bigint;
  nlevcommon   bigint;
  ndoctypeid   bigint;
  nownerid     bigint;
  fin          record;
  stag         record;
begin
  -- уровень доступа к словарям
  select coalesce(min(id),1) into nlevcommon from levaccess where name = 'Справочники (общие)';
    
  -- загрузка договоров
  for cont in select m.*, 
                    (select k.keyin from keys k where k.tablenameout = m.tablenameout and k.keyout = m.rn::text) as id
              from (select 'DEMOCP_CONTRACTS' as tablenameout, t.* from DEMOCP_CONTRACTS t
                    union all
                    select 'ROSTRUD_CONTRACTS' as tablenameout, t.* from ROSTRUD_CONTRACTS t
                   ) m
  loop
     select l.id into nlevaccessid from levaccess l where l.name = cont.company;
     if nlevaccessid is null then
       insert into levaccess(name, uid) values (cont.company, nUID) returning id into nlevaccessid;
     end if;

     cont.owner = cont.company; -- Оказалось одно и тоже

     select w.id into nownerid from owner w where w.code = cont.owner;
     if nownerid is null then
         insert into owner(code, name, lid, uid) values (cont.owner, cont.owner, nlevaccessid, nUID) returning id into nownerid;
     end if;
     
     if trim(cont.doctype) is not null then
       select d.id into ndoctypeid from doctypes d where d.code = cont.doctype;
       if ndoctypeid is null then
         insert into doctypes(code, name, lid, uid) values (cont.doctype, cont.doctype, nlevcommon, nUID) returning id into ndoctypeid;
       end if;
     else
       ndoctypeid = null;
     end if;  

     if cont.id is not null then
       update contracts t
          set (ownerid, doctypeid, docnumb, docdate, client, contractor, name, summ, datestart, datefinish)
            = (nownerid, ndoctypeid, cont.docnumb, cont.docdate, cont.client, cont.contractor, cont.name, cont.summ, cont.datestart, cont.datefinish)
        where t.id = cont.id returning id into cont.id;
       if cont.id is not null then
         nUPD = nUPD + 1;  
       else   
         delete from keys where tablenameout = cont.tablenameout and keyout = cont.rn::text;
       end if;  
     end if;

     if cont.id is null then
       insert into contracts (ownerid, doctypeid, docnumb, docdate, client, contractor, name, summ, datestart, datefinish, lid, uid)
         values (nownerid, ndoctypeid, cont.docnumb, cont.docdate, cont.client, cont.contractor, cont.name, cont.summ, cont.datestart, cont.datefinish, nlevaccessid, nUID) 
         returning id into cont.id;
       insert into keys (tablenameout, keyout, tablenamein, keyin, lid, uid) values (cont.tablenameout, cont.rn, 'CONTRACTS', cont.id, nlevaccessid, nUID);
       nINS = nINS + 1;  
     else
     end if;   

     -- загрузка финансирования
     for fin in select m.*, 
                       (select k.keyin from keys k where k.tablenameout = m.tablenameout and k.keyout = m.rn::text) as id
                  from (select 'DEMOCP_CONTRACTSFINANCING' as tablenameout, t.* from DEMOCP_CONTRACTSFINANCING t where t.prn = cont.rn
                        union all
                        select 'ROSTRUD_CONTRACTSFINANCING' as tablenameout, t.* from ROSTRUD_CONTRACTSFINANCING t where t.prn = cont.rn
                       ) m
     loop
     
       if fin.id is not null then
         update contractsfinancing t
            set (contractsid, kbk, summ, summpaid, summbalance)
              = (cont.id, fin.kbk, fin.summ, fin.summpaid, fin.summbalance)
          where t.id = fin.id returning id into fin.id;
         if fin.id is not null then
           nUPD = nUPD + 1;  
         else   
           delete from keys where tablenameout = fin.tablenameout and keyout = fin.rn::text;
         end if;  
       end if;

       if fin.id is null then
         insert into contractsfinancing (contractsid, kbk, summ, summpaid, summbalance, lid, uid)
           values (cont.id,  fin.kbk,  fin.summ,  fin.summpaid,  fin.summbalance, nlevaccessid, nUID) 
           returning id into fin.id;
         insert into keys (tablenameout, keyout, tablenamein, keyin, lid, uid) values (fin.tablenameout, fin.rn, 'CONTRACTSFINANCING', fin.id, nlevaccessid, nUID);
         nINS = nINS + 1;  
       end if;   
     end loop;                 

     -- загрузка этапов
     for stag in select m.*, 
                       (select k.keyin from keys k where k.tablenameout = m.tablenameout and k.keyout = m.rn::text) as id
                  from (select 'DEMOCP_CONTRACTSSTAGES' as tablenameout, t.* from DEMOCP_CONTRACTSSTAGES t where t.prn = cont.rn
                        union all
                        select 'ROSTRUD_CONTRACTSSTAGES' as tablenameout, t.* from ROSTRUD_CONTRACTSSTAGES t where t.prn = cont.rn
                       ) m
     loop
     
       if stag.id is not null then
         update contractsstages t
            set (contractsid, name, datestart, datefinish)
              = (cont.id, stag.name, stag.datestart, stag.datefinish)
          where t.id = stag.id returning id into stag.id;
         if stag.id is not null then
           nUPD = nUPD + 1;  
         else   
           delete from keys where tablenameout = stag.tablenameout and keyout = stag.rn::text;
         end if;  
       end if;

       if stag.id is null then
         insert into contractsstages (contractsid, name, datestart, datefinish, lid, uid)
           values (cont.id, stag.name, stag.datestart, stag.datefinish, nlevaccessid, nUID) 
           returning id into stag.id;
         insert into keys (tablenameout, keyout, tablenamein, keyin, lid, uid) values (stag.tablenameout, stag.rn, 'CONTRACTSSTAGES', stag.id, nlevaccessid, nUID);
         nINS = nINS + 1;  
       end if;   
     end loop;                 

  end loop;

  return 'Загружено записей: '||nINS||', изменено записей: '||nUPD||'.';
end;
$body$
language plpgsql volatile;
