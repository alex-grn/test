CREATE OR REPLACE FUNCTION public.p_schedule_inventory_import(uid bigint DEFAULT 1) RETURNS text AS
$body$
declare
  nUID         bigint := UID;
  inv          record;
  nINS         bigint := 0;
  nUPD         bigint := 0;
  nlevaccessid bigint;
  nownerid     bigint;
  hist         record;
  ndoctypeid   bigint;
begin
  -- загрузка инвентарной картотеки
  for inv in select m.*, 
                    (select k.keyin from keys k where k.tablenameout = m.tablenameout and k.keyout = m.rn::text) as id
              from (select 'DEMOCP_INVENTORY' as tablenameout, t.* from DEMOCP_INVENTORY t
                    union all
                    select 'ROSTRUD_INVENTORY' as tablenameout, t.* from ROSTRUD_INVENTORY t
                   ) m
  loop

     select l.id into nlevaccessid from levaccess l where l.name = inv.company;
     if nlevaccessid is null then
         insert into levaccess(name, uid) values (inv.company, nUID) returning id into nlevaccessid;
     end if;

     inv.owner = inv.company; -- Оказалось одно и тоже

     select w.id into nownerid from owner w where w.code = inv.owner;
     if nownerid is null then
       insert into owner(code, name, lid, uid) values (inv.owner, inv.owner, nlevaccessid, nUID) returning id into nownerid;
     end if;

     if inv.id is not null then
       update inventory t
          set (objnumber, cardnumb, ownerid, name, objnote, objmodel, okof, worsnumber, producer, "exec", 
               establishment, dateissue, datecommissioning, sumnew, sumamort, sumamortnew, sumpost)
            = (inv.objnumber, inv.cardnumb, nownerid, inv.name, inv.objnote, inv.objmodel, inv.okof, inv.worsnumber, inv.producer, inv."exec", 
               inv.establishment, inv.dateissue, inv.datecommissioning, inv.sumnew, inv.sumamort, inv.sumamortnew, inv.sumpost)
        where t.id = inv.id returning id into inv.id;
       if inv.id is not null then
         nUPD = nUPD + 1;  
       else   
         delete from keys where tablenameout = inv.tablenameout and keyout = inv.rn::text;
       end if;  
     end if;
     
     if inv.id is null then
       insert into inventory (objnumber, cardnumb, ownerid, name, objnote, objmodel, okof, worsnumber, producer, "exec", 
                              establishment, dateissue, datecommissioning, sumnew, sumamort, sumamortnew, sumpost, lid, uid)
         values (inv.objnumber, inv.cardnumb, nownerid, inv.name, inv.objnote, inv.objmodel, inv.okof, inv.worsnumber, inv.producer, inv."exec", 
                 inv.establishment, inv.dateissue, inv.datecommissioning, inv.sumnew, inv.sumamort, inv.sumamortnew, inv.sumpost, nlevaccessid, nUID) 
         returning id into inv.id;
       insert into keys (tablenameout, keyout, tablenamein, keyin, lid, uid) values (inv.tablenameout, inv.rn, 'INVENTORY', inv.id, nlevaccessid, nUID);
       nINS = nINS + 1;  
     else
     end if;   

     -- загрузка истории инвентарной картотеки
     for hist in select m.*, 
                        (select k.keyin from keys k where k.tablenameout = m.tablenameout and k.keyout = m.rn::text) as id
                   from (select 'DEMOCP_INVENTORYHISTORY' as tablenameout, t.* from DEMOCP_INVENTORYHISTORY t where t.prn = inv.rn
                         union all
                         select 'ROSTRUD_INVENTORYHISTORY' as tablenameout, t.* from ROSTRUD_INVENTORYHISTORY t where t.prn = inv.rn
                        ) m
     loop
     
       if trim(hist.doctype) is not null then
         select d.id into ndoctypeid from doctypes d where d.code = hist.doctype;
         if ndoctypeid is null then
           insert into doctypes(code, name, lid, uid) values (hist.doctype, hist.doctype, nlevaccessid, nUID) returning id into ndoctypeid;
         end if;
       else
         ndoctypeid = null;
       end if;  

       if hist.id is not null then
         update inventoryhistory t
            set (inventoryid, typeoperation, numboperation, dateoperation, doctypeid, docnumb, docdate, 
                 sumnew, sumamort, sumamortnew, sumpost, execold, execnew, establishmentold, establishmentnew)
              = (inv.id, hist.typeoperation, hist.numboperation, hist.dateoperation, ndoctypeid, hist.docnumb, hist.docdate, 
                   hist.sumnew, hist.sumamort, hist.sumamortnew, hist.sumpost, hist.execold, hist.execnew, hist.establishmentold, hist.establishmentnew)
          where t.id = hist.id returning id into hist.id;
         if hist.id is not null then
           nUPD = nUPD + 1;  
         else   
           delete from keys where tablenameout = hist.tablenameout and keyout = hist.rn::text;
         end if;  
       end if;

       if hist.id is null then
         insert into inventoryhistory (inventoryid, typeoperation, numboperation, dateoperation, doctypeid, docnumb, docdate, 
                                       sumnew, sumamort, sumamortnew, sumpost, execold, execnew, establishmentold, establishmentnew, lid, uid)
           values (inv.id, hist.typeoperation, hist.numboperation, hist.dateoperation, ndoctypeid, hist.docnumb, hist.docdate, 
                   hist.sumnew, hist.sumamort, hist.sumamortnew, hist.sumpost, hist.execold, hist.execnew, hist.establishmentold, hist.establishmentnew, nlevaccessid, nUID) 
           returning id into hist.id;
         insert into keys (tablenameout, keyout, tablenamein, keyin, lid, uid) values (hist.tablenameout, hist.rn, 'INVENTORYHISTORY', hist.id, nlevaccessid, nUID);
         nINS = nINS + 1;  
       end if;   
     end loop;                 

  end loop;

  return 'Загружено записей: '||nINS||', изменено записей: '||nUPD||'.';
end;
$body$
language plpgsql volatile;
