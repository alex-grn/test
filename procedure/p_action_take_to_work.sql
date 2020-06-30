CREATE OR REPLACE FUNCTION public.p_action_take_to_work (
  idlist text,
  uid bigint,
  unit bigint,
  tablename text,
  destination text
)
RETURNS void AS
$body$
declare 
  nUID bigint:=UID;
  nLID bigint;
  rec  record;
  nID  bigint;
  sTYPEPAYDOC text;
  sNOM_PP  text;
  dDATE_PP date;
  sNOM_ZF text;
  dDATE_ZF date;
  sNOM_UF text;
  dDATE_UF date;
begin
 if tablename ~~* 'STATEMENTADBDONE' then 
  if destination = '0' then
    nLID:=P_SYSTEM_GEN_LID('INFOPAYDOC',nUID,UNIT);
  elsif destination = '1' then
    nLID:=P_SYSTEM_GEN_LID('JOURNALNOTIFMBT',nUID,UNIT);
  elsif destination = '2' then
    nLID:=P_SYSTEM_GEN_LID('JOURNALPERSPAY',nUID,UNIT);
  end if; 
  for rec in 
      select nUID,
           s.STATEMENTADBID,
           s.ID,
           s.KOD_DOC_ADB,
           s.KOD_DOC,
           s.OWNERID,
           s.NOM_DOC,
           s.DATE_DOC,
           s.CNAME_PAY,
           s.INN_PAY,
           s.KPP_PAY,
           s.PURPOSE,
           s.KBK,
           s.ADD_KLASS,
           case when COALESCE(s.SUM_IN,0) != 0 then s.SUM_IN
                when COALESCE(s.SUM_OUT,0) != 0 then -s.SUM_OUT
                when COALESCE(s.SUM_ZACH,0) != 0 then s.SUM_ZACH
           end as DOCSUM,
           s.OKATO,
           st.DATE_OTCH,
           st.LS_ADB,
           case 
             when s.kod_doc_adb ~* 'zv' or s.kod_doc_adb ~* 'pp' then s.nom_doc
           end as nom_doc,
           case 
             when s.kod_doc_adb ~* 'zv' or s.kod_doc_adb ~* 'pp' then s.date_doc
           end as date_doc,
           s.NOTE
      from STATEMENTADBDONE s,
           STATEMENTADB st
     where s.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
       and st.id = s.STATEMENTADBID
  loop
   
     --определим тип
     if rec.KOD_DOC_ADB ilike '%ZV%' THEN
        sTYPEPAYDOC:='4';
     elsif rec.KOD_DOC_ADB ilike '%UF%' or rec.KOD_DOC_ADB ilike '%UN%' or rec.KOD_DOC_ADB ilike '%UM%' THEN
        sTYPEPAYDOC:='3';   
     elsif nullif(rec.KOD_DOC_ADB,'') is null then 
        if rec.KOD_DOC ilike '%PP%' THEN
         if destination = '3' THEN
           sTYPEPAYDOC:='0';
         else
           sTYPEPAYDOC:='2';
         end if;
        elsif rec.KOD_DOC ilike '%UF%' or rec.KOD_DOC ilike '%UN%' THEN 
           sTYPEPAYDOC:='3';
        end if;
     end if;
     if destination = '0' then
       insert into INFOPAYDOC(uid, lid, statementadbid, statementadbdoneid, sign_fait, typepaydoc, ownerid)
       values(nUID, nLID, rec.STATEMENTADBID, rec.ID, '0', sTYPEPAYDOC, rec.OWNERID) returning INFOPAYDOC.ID into nID;
       perform p_system_doclinks_add('STATEMENTADBDONE'::text,rec.ID,'INFOPAYDOC'::text,nID,false,current_date);
       update STATEMENTADBDONE s set statusdoc = '1' where s.id = rec.id;
     elsif destination = '1' then
       insert into JOURNALNOTIFMBT(uid,lid,ownerid,typepaydoc,statementadbdoneid,nom_doc,date_doc,cname_pay,inn_pay,kpp_pay,purpose,kbk,add_klass,docsum,oktmo)
       values(nUID,nLID,rec.OWNERID,sTYPEPAYDOC,rec.ID,rec.NOM_DOC,rec.DATE_DOC,rec.CNAME_PAY,rec.INN_PAY,rec.KPP_PAY,rec.PURPOSE,rec.KBK,rec.ADD_KLASS,rec.DOCSUM,rec.OKATO)
       returning JOURNALNOTIFMBT.ID into nID;
       perform p_system_doclinks_add('STATEMENTADBDONE'::text,rec.ID,'JOURNALNOTIFMBT'::text,nID);   
       update STATEMENTADBDONE s set statusdoc = '1' where s.id = rec.id;
     elsif destination = '2' then
       if rec.KOD_DOC_ADB ~* 'uf' or rec.KOD_DOC_ADB ~* 'um' then
          select r.NOM_PP, r.DATE_PP
            into sNOM_PP, dDATE_PP
            from doclinks d,
                 REFINENOTIFPP r 
           where d.tableout ~~* 'STATEMENTADBDONE' 
             and d.keyout = s.id
             and d.tablein ~~* 'REFINENOTIFPP'
             and r.id = d.keyin;
       end if;
       select r.NOM_ZF, r.DATE_ZF, r.NOM_UF, r.DATE_UF
         into sNOM_ZF, dDATE_ZF, sNOM_UF, dDATE_UF
         from doclinks d,
              REFINENOTIF r 
        where d.tableout ~~* 'STATEMENTADBDONE' 
          and d.keyout = rec.id
          and d.tablein ~~* 'REFINENOTIF'
          and r.id = d.keyin;
       insert into JOURNALPERSPAY(uid,lid,ownerid,statementadbdoneid,DOC_DATE_STATE,LS,DIR_SUM,NOM_DOC_PP,DATE_DOC_PP,NOM_DOC_ZF,
              DATE_DOC_ZF,NOM_DOC_UF,DATE_DOC_UF,CNAME_PAY,INN_PAY,KPP_PAY,PURPOSE,NOTE,KBK,ADD_KLASS,DOCSUM,OKTMO)
       values(nUID,nLID,rec.OWNERID,rec.ID,rec.DATE_OTCH,rec.LS_ADB,rec.DIR_SUM,COALESCE(rec.nom_doc,sNOM_PP),COALESCE(rec.date_doc,dDATE_PP),sNOM_ZF,
              dDATE_ZF,sNOM_UF,dDATE_UF,rec.CNAME_PAY,rec.INN_PAY,rec.KPP_PAY,rec.PURPOSE,rec.NOTE,rec.KBK,rec.ADD_KLASS,rec.DOCSUM,rec.OKATO)
       returning JOURNALPERSPAY.ID into nID;
       perform p_system_doclinks_add('STATEMENTADBDONE'::text,rec.ID,'JOURNALPERSPAY'::text,nID);   
       update STATEMENTADBDONE s set statusdoc = '1' where s.id = rec.id;
     elsif destination = '3' then
       insert into JOURNALOTHERS(uid,lid,ownerid,STATEMENTADBDONEID,DOC_DATE_STATE,LS,DIR_SUM,TYPEPAYDOC,NOM_DOC,DATE_DOC,CNAME_PAY,INN_PAY,
                                 KPP_PAY,PURPOSE,NOTE,KBK,ADD_KLASS,DOCSUM,OKTMO) 
       values(nUID,nLID,rec.OWNERID,rec.ID,rec.DATE_OTCH,rec.LS_ADB,rec.DIR_SUM,sTYPEPAYDOC,rec.NOM_DOC,rec.DATE_DOC,rec.CNAME_PAY,rec.INN_PAY,
              rec.KPP_PAY,rec.PURPOSE,rec.NOTE,rec.KBK,rec.ADD_KLASS,rec.DOCSUM,rec.OKATO)
       returning JOURNALOTHERS.ID into nID;                          
       perform p_system_doclinks_add('STATEMENTADBDONE'::text,rec.ID,'JOURNALOTHERS'::text,nID);   
       update STATEMENTADBDONE s set statusdoc = '1' where s.id = rec.id;
     end if;
  end loop;
 elsif tablename ~~* 'STATEMENTPBSVPKP' then
   nLID:=P_SYSTEM_GEN_LID('JOURNALPERSPAY',nUID,UNIT);
   for rec in 
     select st.ownerid,
            st.id,
            s.date_otch,
            s.ls,
            sp.dir_sum,
            st.num_doc,
            st.date_doc,
            st.cname_pay,
            st.inn_pay,
            st.kpp_pay,
            st.purpose,
            st.note,
            sp.kbk,
            sp.add_klass,
            sp.sum,
            sp.oktmo,
            st.id as STATEMENTPBSVPKPID,
            sp.id as STATEMENTPBSVPKPKBKID
       from STATEMENTPBSVPKP st,
            STATEMENTPBS s,
            STATEMENTPBSVPKPKBK sp
      where st.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
        and s.id = st.STATEMENTPBSID
        and sp.STATEMENTPBSVPKPID = st.id
   loop
     select r.NOM_ZF, r.DATE_ZF, r.NOM_UF, r.DATE_UF
         into sNOM_ZF, dDATE_ZF, sNOM_UF, dDATE_UF
         from doclinks d,
              REFINENOTIF r 
        where d.tableout ~~* 'STATEMENTPBSVPKP' 
          and d.keyout = rec.STATEMENTPBSVPKPID
          and d.tablein ~~* 'REFINENOTIF'
          and r.id = d.keyin;
     if destination = '2' then     
       insert into JOURNALPERSPAY(uid,lid,ownerid,statementpbsvpkpid,DOC_DATE_STATE,LS,DIR_SUM,NOM_DOC_PP,DATE_DOC_PP,NOM_DOC_ZF,
              DATE_DOC_ZF,NOM_DOC_UF,DATE_DOC_UF,CNAME_PAY,INN_PAY,KPP_PAY,PURPOSE,NOTE,KBK,ADD_KLASS,DOCSUM,OKTMO)
       values(nUID,nLID,rec.OWNERID,rec.STATEMENTPBSVPKPID,rec.DATE_OTCH,rec.LS,rec.DIR_SUM,COALESCE(rec.num_doc,sNOM_PP),COALESCE(rec.date_doc,dDATE_PP),sNOM_ZF,
              dDATE_ZF,sNOM_UF,dDATE_UF,rec.CNAME_PAY,rec.INN_PAY,rec.KPP_PAY,rec.PURPOSE,rec.NOTE,rec.KBK,rec.ADD_KLASS,rec.SUM,rec.OKTMO)
       returning JOURNALPERSPAY.ID into nID;
       perform p_system_doclinks_add('STATEMENTPBSVPKPKBK'::text,rec.STATEMENTPBSVPKPKBKID,'JOURNALPERSPAY'::text,nID);  
     elsif destination = '3' then
       insert into JOURNALOTHERS(uid,lid,ownerid,statementpbsvpkpid,DOC_DATE_STATE,LS,DIR_SUM,NOM_DOC,DATE_DOC,CNAME_PAY,INN_PAY,
                                 KPP_PAY,PURPOSE,NOTE,KBK,ADD_KLASS,DOCSUM,OKTMO) 
       values(nUID,nLID,rec.OWNERID,rec.STATEMENTPBSVPKPID,rec.DATE_OTCH,rec.LS,rec.DIR_SUM,rec.NUM_DOC,rec.DATE_DOC,rec.CNAME_PAY,rec.INN_PAY,
              rec.KPP_PAY,rec.PURPOSE,rec.NOTE,rec.KBK,rec.ADD_KLASS,rec.SUM,rec.OKTMO)
       returning JOURNALOTHERS.ID into nID;                          
       perform p_system_doclinks_add('STATEMENTPBSVPKPKBK'::text,rec.STATEMENTPBSVPKPKBKID,'JOURNALOTHERS'::text,nID);  
     end if;   
       update STATEMENTPBSVPKP s set statusdoc = '1' where s.id = rec.STATEMENTPBSVPKPID;
   end loop;
 elsif tablename ~~* 'STATEMENTPBSVPPP' then
   nLID:=P_SYSTEM_GEN_LID('JOURNALPERSPAY',nUID,UNIT);
   for rec in 
     select st.ownerid,
            st.id,
            s.date_otch,
            s.ls,
            sp.dir_sum,
            st.num_doc,
            st.date_doc,
            st.cname_pay,
            st.inn_pay,
            st.kpp_pay,
            st.purpose,
            st.note,
            sp.kbk,
            sp.add_klass,
            sp.sum,
            sp.oktmo,
            st.id as STATEMENTPBSVPPPID,
            sp.id as STATEMENTPBSVPPPKBKID
       from STATEMENTPBSVPPP st,
            STATEMENTPBS s,
            STATEMENTPBSVPPPKBK sp
      where st.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
        and s.id = st.STATEMENTPBSID
        and sp.STATEMENTPBSVPPPID = st.id
   loop
     select r.NOM_ZF, r.DATE_ZF, r.NOM_UF, r.DATE_UF
         into sNOM_ZF, dDATE_ZF, sNOM_UF, dDATE_UF
         from doclinks d,
              REFINENOTIF r 
        where d.tableout ~~* 'STATEMENTPBSVPPP' 
          and d.keyout = rec.STATEMENTPBSVPPPID
          and d.tablein ~~* 'REFINENOTIF'
          and r.id = d.keyin;
     if destination = '2' then     
       insert into JOURNALPERSPAY(uid,lid,ownerid,statementpbsvpppid,DOC_DATE_STATE,LS,DIR_SUM,NOM_DOC_PP,DATE_DOC_PP,NOM_DOC_ZF,
              DATE_DOC_ZF,NOM_DOC_UF,DATE_DOC_UF,CNAME_PAY,INN_PAY,KPP_PAY,PURPOSE,NOTE,KBK,ADD_KLASS,DOCSUM,OKTMO)
       values(nUID,nLID,rec.OWNERID,rec.STATEMENTPBSVPPPID,rec.DATE_OTCH,rec.LS,rec.DIR_SUM,COALESCE(rec.num_doc,sNOM_PP),COALESCE(rec.date_doc,dDATE_PP),sNOM_ZF,
              dDATE_ZF,sNOM_UF,dDATE_UF,rec.CNAME_PAY,rec.INN_PAY,rec.KPP_PAY,rec.PURPOSE,rec.NOTE,rec.KBK,rec.ADD_KLASS,rec.SUM,rec.OKTMO)
       returning JOURNALPERSPAY.ID into nID;
       perform p_system_doclinks_add('STATEMENTPBSVPPPKBK'::text,rec.STATEMENTPBSVPPPKBKID,'JOURNALPERSPAY'::text,nID);   
     elsif destination = '3' then
       insert into JOURNALOTHERS(uid,lid,ownerid,statementpbsvpkpid,DOC_DATE_STATE,LS,DIR_SUM,NOM_DOC,DATE_DOC,CNAME_PAY,INN_PAY,
                                 KPP_PAY,PURPOSE,NOTE,KBK,ADD_KLASS,DOCSUM,OKTMO) 
       values(nUID,nLID,rec.OWNERID,rec.STATEMENTPBSVPKPID,rec.DATE_OTCH,rec.LS,rec.DIR_SUM,rec.NUM_DOC,rec.DATE_DOC,rec.CNAME_PAY,rec.INN_PAY,
              rec.KPP_PAY,rec.PURPOSE,rec.NOTE,rec.KBK,rec.ADD_KLASS,rec.SUM,rec.OKTMO)
       returning JOURNALOTHERS.ID into nID;                          
       perform p_system_doclinks_add('STATEMENTPBSVPPPKBK'::text,rec.STATEMENTPBSVPKPKBKID,'JOURNALOTHERS'::text,nID);  
     end if;   
       update STATEMENTPBSVPPP s set statusdoc = '1' where s.id = rec.STATEMENTPBSVPPPID;
   end loop;
 end if; 

end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_take_to_work (idlist text, uid bigint, unit bigint, tablename text, destination text)
  OWNER TO magicbox;