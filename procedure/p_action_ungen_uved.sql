CREATE OR REPLACE FUNCTION public.p_action_ungen_uved (
  idlist text,
  tablename text
)
RETURNS void AS
$body$
declare 
  rec record;
  sp  record;
  sSQL text;
  sSQL_T text[];
  D bigint;
  nIDLIST bigint[]:=p_system_get_selectlist(idlist);
  MACTSDOCS bigint[];
begin
 if tablename ~~* 'REFINEREQ' then  
  for rec in 
     select r.id
       from REFINEREQ r
      where r.ID = ANY(nIDLIST)
  loop
     if not EXISTS(select 1 from doclinks d where d.tablein ~~* 'REFINEREQ' and d.keyin = rec.id and d.tableout ~~* 'REFINENOTIF') then 
        raise using message = 'Среди выбранных запросов нет уточненных';
     end if;
     delete from REFINENOTIF r where EXISTS(select 1
                                              from doclinks d
                                             where d.tablein ~~* 'REFINEREQ'
                                               and d.keyin = rec.id
                                               and d.tableout ~~* 'REFINENOTIF'
                                               and d.keyout = r.id);
     
     PERFORM p_system_doclinks_del('REFINEREQ',rec.id,'REFINENOTIF');
     update REFINEREQ r set status_zf = '0' where r.ID = rec.ID; 
  end loop;
 elsif upper(tablename) in ('JOURNALPAYS','JOURNALNOTIFMBT','JOURNALOTHERS','JOURNALPERSPAY') THEN
  if tablename ilike 'JOURNALPAYS' then
    sSQL_T[1]:=' INFOPAYDOC i,';
    sSQL_T[2]:=' i.ID = j.INFOPAYDOCID'||chr(13)||
                 ' and s.ID = i.STATEMENTADBDONEID';
  else 
    sSQL_T[1]:=' ';
    sSQL_T[2]:=' s.ID = j.STATEMENTADBDONEID'||chr(13);        
  end if;
  for rec in execute
    'select j.id, s.id as STATEMENTADBDONEID
       from '||tablename||' j, '||sSQL_T[1]||'
            STATEMENTADBDONE s
      where '||sSQL_T[2]||'
        and j.id = ANY('''||nIDLIST::text||''')'
  loop
     MACTSDOCS     := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST(tablename, REC.ID, 'REFINENOTIFNEW');
     if MACTSDOCS is not null then
        -- проверяем на наличие исходяжих документов
        foreach D in array MACTSDOCS
        loop
          perform P_SYSTEM_DOCLINKS_OUT_CHECK('REFINENOTIFNEW', D);
        end loop;

        -- удаляем линк
        foreach D in array MACTSDOCS
        loop
          PERFORM P_SYSTEM_DOCLINKS_DEL(tablename, REC.ID, 'REFINENOTIFNEW', D);
        end loop;
        
        delete from REFINENOTIF r where r.ID = ANY(P_SYSTEM_GET_DOCLINKS_OUT_IDLIST(tablename, REC.ID, 'REFINENOTIF'));
        
     end if;  
     MACTSDOCS:=null;
     MACTSDOCS     := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STATEMENTADBDONE', REC.STATEMENTADBDONEID, 'REFINENOTIFNEW');
     if MACTSDOCS is not null then
        -- удаляем линк
        foreach D in array MACTSDOCS
        loop
          PERFORM P_SYSTEM_DOCLINKS_DEL('STATEMENTADBDONE', REC.STATEMENTADBDONEID, 'REFINENOTIFNEW', D);
        end loop;
        update STATEMENTADBDONE s set STATUSDOC = '1' where s.id = REC.STATEMENTADBDONEID;
     else
       if upper(tablename) in ('JOURNALOTHERS','JOURNALPERSPAY') then
         for sp in execute 
          'select s.id, s.STATEMENTPBSVPKPID
             from '||tablename||' j,
                  STATEMENTPBSVPKPKBK s
            where s.STATEMENTPBSVPKPID = j.STATEMENTPBSVPKPID
              and j.id = ANY('''||nIDLIST::text||''')'
         loop
           MACTSDOCS     := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST('STATEMENTPBSVPKPKBK', sp.id, 'REFINENOTIFNEW'); 
           if MACTSDOCS is not null then
            -- удаляем линк
            foreach D in array MACTSDOCS
            loop
              PERFORM P_SYSTEM_DOCLINKS_DEL('STATEMENTPBSVPKPKBK', sp.id, 'REFINENOTIFNEW', D);
            end loop;
            update STATEMENTPBSVPKP s set STATUSDOC = '1' where s.id = sp.STATEMENTPBSVPKPID;
           end if;
         end loop;
         if tablename ~~* 'JOURNALOTHERS' then
           update JOURNALOTHERS j set status_other = '0' where j.id = rec.id;
         elsif tablename ~~* 'JOURNALPERSPAY' then 
           update JOURNALPERSPAY j set status_perspay = '0' where j.id = rec.id;
         end if;
       end if;
     end if;  
     if tablename ~~* 'JOURNALPAYS' then
       MACTSDOCS:=null;
       MACTSDOCS     := P_SYSTEM_GET_DOCLINKS_OUT_IDLIST(tablename, REC.ID, 'FINEPAY');
       if MACTSDOCS is not null THEN
         update JOURNALPAYS j set sign_fait = '0' where j.id = REC.ID;
       else
         update JOURNALPAYS j set sign_fait = '3' where j.id = REC.ID;
       end if; 
     end if;
     
  end loop;
 end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_ungen_uved (idlist text, tablename text)
  OWNER TO magicbox;