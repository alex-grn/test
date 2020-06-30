CREATE OR REPLACE FUNCTION public.p_action_gen_uved (
  idlist text,
  uid bigint,
  unit bigint,
  tablename text,
  cname_ubp bigint,
  inn_ubp text,
  kpp_ubp text,
  okato text,
  ls_ubp text,
  kbr_id bigint = NULL::bigint,
  bkd_id bigint = NULL::bigint,
  add_klass bigint = NULL::bigint,
  fund_source text = NULL::text,
  purpose text = NULL::text,
  agent_accid bigint = NULL::bigint
)
RETURNS void AS
$body$
declare 
  nUID bigint:=UID;
  nIDLIST bigint[]:=p_system_get_selectlist(idlist);
  nLID_REFINENOTIF bigint:=P_SYSTEM_GEN_LID('REFINENOTIF',nUID,UNIT);
  nLID_REFINENOTIFPP bigint:=P_SYSTEM_GEN_LID('REFINENOTIFPP',nUID,UNIT);
  nLID_REFINENOTIFNEW bigint:=P_SYSTEM_GEN_LID('REFINENOTIFNEW',nUID,UNIT);
  rec  record;
  sp   record;
  nID  bigint;
  sACC text;
  sSQL text;
  sSQL_T TEXT[];
  sTYPEPAYDOC text;
  nREFINENOTIFID bigint;
  nREFINENOTIFPPID bigint;
  nREFINENOTIFNEWID bigint;
  sCNAME_UBP TEXT:=(select a.NAME from AGENT a where a.ID = p_action_gen_uved.CNAME_UBP); --Возьмем наименование юридического лица
  sTYPE_KBK TEXT:=(select case when KBR_ID is not null then '10' when BKD_ID is not null then '20' end); --Тип кбк
  sADD_CLASS TEXT:=(select a.CODE from ACODES a where a.id = ADD_KLASS);
  sKBK_CODE TEXT:=(select b.code from bkd b where b.id = bkd_id);
  next_num text;
  fl boolean:=false;
begin
 if tablename ilike 'REFINEREQ' then
  for rec in
     select r.id,
            '0' as STATUS_UF,
            current_date as DATE_UF,
            r.OWNERID,
            r.NAME_UBP,
            r.KOD_UBP,
            (select ac.BANK_ACC from agent_acc ac where ac.id = p_action_gen_uved.agent_accid) as LS_UBP,
            r.NAME_GRS,
            r.KOD_GRS as GLAVA_GRS,
            r.NAME_BUD,
            r.NAME_UBP_FO,
            r.OKPO_FO,
            r.NAME_TOFK,
            r.KOD_TOFK,
            r.NOM_ZF,
            r.DATE_ZF,
            r.CNAME_PL,
            r.INN_PL,
            r.KPP_PL,
            r.PASP,
            r.TYPE_KBK,
            r.ADD_KLASS,
            r.KBK_PP,
            r.INN_PP,
            r.KPP_PP
       from REFINEREQ r
      where r.ID = ANY(p_system_get_selectlist(idlist))
      loop
           --ищем расчетный счет в спецификации (во всех спецификациях должен быть один).
           begin
              select r.BS_PAY
                into strict sACC
                from REFINEREQPP r 
               where r.refinereqid = rec.id
               group by r.BS_PAY;
           exception when too_many_rows then raise using message = 'Счета в строках запроса не совпадают. Обратитесь к ответсвенному исполнителю запроса.';
                     when no_data_found then raise using message = 'Нет информации о платежном документе!';
           end;
           --ищем следующий номер
           select coalesce(regexp_replace(max(lpad(f.nom_uf,80,' ')), '[^0-9]', '', 'g')::numeric+1,1) into next_num from REFINENOTIF f;
           --добавляем запись в уведомления об уточнении вида и принадлежности платежа
           insert into REFINENOTIF(uid,lid,ownerid,status_uf,nom_uf,date_uf,name_ubp,kod_ubp,ls_ubp,name_grs,glava_grs,name_bud,name_ubp_fo,
                                   okpo_fo,name_tofk,kod_tofk,nom_zf,date_zf,cname_pl,inn_pl,kpp_pl,pasp,bs_pl)
                      values(nUID,nLID_REFINENOTIF,rec.OWNERID,rec.STATUS_UF,next_num,rec.DATE_UF,rec.NAME_UBP,rec.KOD_UBP,rec.LS_UBP,rec.NAME_GRS,rec.GLAVA_GRS,rec.NAME_BUD,rec.NAME_UBP_FO,
                             rec.OKPO_FO,rec.NAME_TOFK,rec.KOD_TOFK,rec.NOM_ZF,rec.DATE_ZF,rec.CNAME_PL,rec.INN_PL,rec.KPP_PL,rec.PASP,sACC)
                      RETURNING REFINENOTIF.ID into nREFINENOTIFID;
           
           for sp in 
              select r.ID,
                     r.BS_PAY,
                     r.NUM_PP,
                     r.DATE_PP,
                     r.CNAME_UBP_RCP as CNAME_PP,
                     r.OKATO,
                     r.SUM_PP,
                     r.GUID,
                     COALESCE((select k.code from kbr k where k.id = p_action_gen_uved.KBR_ID),(select k.code from bkd k where k.id = p_action_gen_uved.BKD_ID)) as kbk
                from REFINEREQPP r 
               where r.refinereqid = rec.id
           loop
               --ищем следующий номер
               select coalesce(max(f.line_nom)+1,1)::text into next_num from REFINENOTIFPP f where f.refinenotifid = rec.id;
               --заполняем реквизиты уточняемого платежного документа
               insert into REFINENOTIFPP(uid,lid,refinenotifid,ownerid,line_nom,guid,kod_doc,name_pp,nom_pp,date_pp,cname_pp,inn_pp,kpp_pp,okato,kbk,type_kbk,add_klass,sum_pp)
               values(nUID,nLID_REFINENOTIFPP,nREFINENOTIFID,rec.OWNERID,next_num::numeric,sp.GUID,'PP','Платежное поручение',sp.NUM_PP,sp.DATE_PP,sp.CNAME_PP,rec.INN_PP,rec.KPP_PP,sp.OKATO,rec.KBK_PP,rec.TYPE_KBK,rec.ADD_KLASS,sp.SUM_PP)
               returning REFINENOTIFPP.ID into nREFINENOTIFPPID;
               
                --заполняем новые реквизиты платежного документа
               insert into REFINENOTIFNEW(uid,lid,refinenotifppid,ownerid,line_nom,cname_ubp,inn_ubp,kpp_ubp,okato,kbk,type_kbk,add_klass,purpose,fund_source,ls_ubp)
               values(nUID,nLID_REFINENOTIFNEW,nREFINENOTIFPPID,rec.OWNERID,next_num::numeric,sCNAME_UBP,p_action_gen_uved.INN_UBP,p_action_gen_uved.KPP_UBP,p_action_gen_uved.OKATO,sp.kbk,sTYPE_KBK,sADD_CLASS,p_action_gen_uved.PURPOSE,p_action_gen_uved.FUND_SOURCE,p_action_gen_uved.LS_UBP)
               returning REFINENOTIFNEW.ID into nREFINENOTIFNEWID;
               --создаем связь
               PERFORM p_system_doclinks_add('REFINEREQPP',sp.ID,'REFINENOTIFNEW',nREFINENOTIFNEWID);
           end loop;
           update REFINEREQ r set STATUS_ZF = '1' where r.ID = rec.ID;
      end loop;
 
 elsif upper(tablename) in ('JOURNALPAYS','JOURNALNOTIFMBT','JOURNALOTHERS','JOURNALPERSPAY') then
   if tablename ilike 'JOURNALPAYS' then
      sSQL_T[1]:=' INFOPAYDOC i,';
      sSQL_T[2]:=' i.ID = j.INFOPAYDOCID'||chr(13)||
                 ' and s.ID = i.STATEMENTADBDONEID';
   else 
      sSQL_T[1]:=' ';
      sSQL_T[2]:=' s.ID = j.STATEMENTADBDONEID'||chr(13);        
   end if;
   sSQL:='select j.id,
            s.OWNERID,
            ''0'' as STATUS_UF,
            current_date as DATE_UF,
            st.NAME_UBP_ADB,
            st.KOD_UBP_ADB,
            st.LS_ADB,
            st.NAME_GADB,
            st.KOD_GADB,
            st.NAME_BUD,
            st.NAME_FO,
            st.OKPO_FO,
            st.NAME_TOFK_SLAVE,
            st.KOD_TOFK_SLAVE,
             s.CNAME_PAY,
             s.INN_PAY,
             s.KPP_PAY,
             s.BS_PAY,
             --
             s.guid,
             s.kod_doc,
             s.nom_doc,
             s.date_doc,
             s.cname_ubp_rcp,
             s.inn_adb,
             s.kpp_adb,
             s.okato,
             s.kbk,
             s.type_kbk,
             s.add_klass,
             COALESCE(s.sum_in,s.sum_zach) as sum_in,
             s.id as STATEMENTADBDONEID
       from '||tablename||' j, '||sSQL_T[1]||'
            STATEMENTADBDONE s,
            STATEMENTADB st
      where '||sSQL_T[2]||'
        and st.ID = s.STATEMENTADBID
        and j.id = any('''||nIDLIST::text||''')';
   for rec in execute sSQL
   loop
     --следующий номер
     select coalesce(regexp_replace(max(lpad(r.nom_uf,15,' ')), '[^0-9]', '', 'g')::numeric+1,1) into next_num from REFINENOTIF r where r.ownerid=rec.ownerid;
     --добавим строку в заголовок уведомления
      insert into REFINENOTIF(uid,lid,OWNERID,STATUS_UF,NOM_UF,DATE_UF,NAME_UBP,KOD_UBP,LS_UBP,NAME_GRS,GLAVA_GRS,
                              NAME_BUD,NAME_UBP_FO,OKPO_FO,NAME_TOFK,KOD_TOFK,CNAME_PL,INN_PL,KPP_PL,BS_PL)
      VALUES(nuid,nLID_REFINENOTIF,rec.OWNERID,rec.STATUS_UF,next_num,rec.DATE_UF,rec.NAME_UBP_ADB,rec.KOD_UBP_ADB,rec.LS_ADB,rec.NAME_GADB,rec.KOD_GADB,
             rec.NAME_BUD,rec.NAME_FO,rec.OKPO_FO,rec.NAME_TOFK_SLAVE,rec.KOD_TOFK_SLAVE,rec.CNAME_PAY,rec.INN_PAY,rec.KPP_PAY,rec.BS_PAY)
      RETURNING REFINENOTIF.ID into nREFINENOTIFID;
     --добавим строку в спецификацию уведомления       
      insert into REFINENOTIFPP(uid,lid,refinenotifid,OWNERID,LINE_NOM,GUID,KOD_DOC,NOM_PP,DATE_PP,CNAME_PP,INN_PP,KPP_PP,OKATO,KBK,TYPE_KBK,ADD_KLASS,SUM_PP)
      VALUES(nuid,nLID_REFINENOTIFPP,nREFINENOTIFID,rec.OWNERID,1,rec.GUID,rec.KOD_DOC,rec.NOM_DOC,rec.DATE_DOC,rec.CNAME_UBP_RCP,rec.INN_ADB,rec.KPP_ADB,rec.OKATO,rec.KBK,rec.TYPE_KBK,rec.ADD_KLASS,rec.SUM_IN)
      RETURNING REFINENOTIFPP.ID into nREFINENOTIFPPID;    
     --добавим строку спецификации спецификации уведомления
      if p_action_gen_uved.CNAME_UBP is not null and p_action_gen_uved.INN_UBP is not null 
         and p_action_gen_uved.KPP_UBP is not null and p_action_gen_uved.OKATO is not null
         and p_action_gen_uved.LS_UBP is not null then
         rec.sum_in:=null;
      end if;
      insert into REFINENOTIFNEW(uid,lid,refinenotifppid,OWNERID,LINE_NOM,CNAME_UBP,INN_UBP,KPP_UBP,OKATO,KBK,TYPE_KBK,ADD_KLASS,SUM)   
      VALUES(nUID,nLID_REFINENOTIFNEW,nREFINENOTIFPPID,rec.OWNERID,1,sCNAME_UBP,p_action_gen_uved.INN_UBP,p_action_gen_uved.KPP_UBP,p_action_gen_uved.OKATO,sKBK_CODE,'20',sADD_CLASS,rec.sum_in)
      RETURNING REFINENOTIFNEW.ID into nREFINENOTIFNEWID;
      PERFORM p_system_doclinks_add('STATEMENTADBDONE',rec.STATEMENTADBDONEID,'REFINENOTIFNEW',nREFINENOTIFNEWID);
      update STATEMENTADBDONE s set STATUSDOC = '2' where s.id = REC.STATEMENTADBDONEID;
      PERFORM p_system_doclinks_add(tablename,rec.ID,'REFINENOTIFNEW',nREFINENOTIFNEWID);
      if tablename ~~* 'JOURNALPAYS' then
        update JOURNALPAYS s set SIGN_FAIT = '1' where s.id = rec.id;
      elsif tablename ~~* 'JOURNALOTHERS' then
        update JOURNALOTHERS s set STATUS_OTHER = '1' where s.id = rec.id;
      elsif tablename ~~* 'JOURNALPERSPAY' then
        update JOURNALPERSPAY s set STATUS_PERSPAY = '1' where s.id = rec.id;
      end if;
      fl:=true;  
   end loop;
 end if;  
 --если не сформировалось по STATEMENTADBDONE, сформируем по STATEMENTPBSVPKP 
 if upper(tablename) in ('JOURNALOTHERS','JOURNALPERSPAY') and not fl then
   for rec in execute
     'select st.ownerid,
            ''0'' as STATUS_UF,
            current_date as DATE_UF,
            st.NAME_UBP_PBS,
            st.KOD_UBP_PBS,
            st.LS_ADB,
            st.NAME_GRBS,
            st.GLAVA_GRBS,
            st.NAME_BUD,
            st.NAME_FO,
            st.OKPO_FO,
            st.NAME_TOFK,
            st.KOD_TOFK,
             s.CNAME_PAY,
             s.INN_PAY,
             s.KPP_PAY,
             s.BS_PAY,
             --
             s.guid,
             s.num_doc,
             s.date_doc,
             s.cname_ubp_rcp,
             s.inn_rcp,
             s.kpp_rcp,
             s.okato,
             --
             s.id as STATEMENTPBSVPKPID
        from '||tablename||' j,
             STATEMENTPBSVPKP s,
             STATEMENTPBS st
       where s.ID = j.STATEMENTPBSVPKPID
         and st.ID = s.STATEMENTPBSID
         and j.ID = ANY('''||nIDLIST::text||''')'
     loop
       --следующий номер
      select coalesce(regexp_replace(max(lpad(r.nom_uf,15,' ')), '[^0-9]', '', 'g')::numeric+1,1) into next_num from REFINENOTIF r where r.ownerid=rec.ownerid;
      --добавим строку в заголовок уведомления
      insert into REFINENOTIF(uid,lid,OWNERID,STATUS_UF,NOM_UF,DATE_UF,NAME_UBP,KOD_UBP,LS_UBP,NAME_GRS,GLAVA_GRS,
                              NAME_BUD,NAME_UBP_FO,OKPO_FO,NAME_TOFK,KOD_TOFK,CNAME_PL,INN_PL,KPP_PL,BS_PL)
      VALUES(nuid,nLID_REFINENOTIF,rec.OWNERID,rec.STATUS_UF,next_num,rec.DATE_UF,rec.NAME_UBP_PBS,rec.KOD_UBP_PBS,rec.LS_ADB,rec.NAME_GRBS,rec.GLAVA_GRBS,
             rec.NAME_BUD,rec.NAME_FO,rec.OKPO_FO,rec.NAME_TOFK,rec.KOD_TOFK,rec.CNAME_PAY,rec.INN_PAY,rec.KPP_PAY,rec.BS_PAY)
      RETURNING REFINENOTIF.ID into nREFINENOTIFID;
      for sp in 
        select k.kbk,k.type_kbk,k.add_klass,k.sum,k.id
          from STATEMENTPBSVPKPKBK k
         where k.STATEMENTPBSVPKPID = rec.STATEMENTPBSVPKPID
      loop
        select MAX(p.line_nom)::text into next_num from REFINENOTIFPP p where p.refinenotifid = nREFINENOTIFID;
        --добавим строку в спецификацию уведомления       
        insert into REFINENOTIFPP(uid,lid,refinenotifid,OWNERID,LINE_NOM,GUID,NOM_PP,DATE_PP,CNAME_PP,INN_PP,KPP_PP,OKATO,KBK,TYPE_KBK,ADD_KLASS,SUM_PP)
        VALUES(nuid,nLID_REFINENOTIFPP,nREFINENOTIFID,rec.OWNERID,COALESCE(next_num,'1')::INTEGER,rec.GUID,rec.NUM_DOC,rec.DATE_DOC,rec.CNAME_UBP_RCP,rec.INN_RCP,rec.KPP_RCP,rec.OKATO,sp.KBK,sp.TYPE_KBK,sp.ADD_KLASS,sp.SUM)
        RETURNING REFINENOTIFPP.ID into nREFINENOTIFPPID;    
        --добавим строку спецификации спецификации уведомления
        if p_action_gen_uved.CNAME_UBP is not null and p_action_gen_uved.INN_UBP is not null 
           and p_action_gen_uved.KPP_UBP is not null and p_action_gen_uved.OKATO is not null
           and p_action_gen_uved.LS_UBP is not null then
           rec.sum:=null;
        end if;
        insert into REFINENOTIFNEW(uid,lid,refinenotifppid,OWNERID,LINE_NOM,CNAME_UBP,INN_UBP,KPP_UBP,OKATO,KBK,TYPE_KBK,ADD_KLASS,SUM)   
        VALUES(nUID,nLID_REFINENOTIFNEW,nREFINENOTIFPPID,rec.OWNERID,COALESCE(next_num,'1')::INTEGER,sCNAME_UBP,p_action_gen_uved.INN_UBP,p_action_gen_uved.KPP_UBP,p_action_gen_uved.OKATO,sKBK_CODE,'20',sADD_CLASS,rec.sum)
        RETURNING REFINENOTIFNEW.ID into nREFINENOTIFNEWID;
        PERFORM p_system_doclinks_add('STATEMENTPBSVPKPKBK',sp.ID,'REFINENOTIFNEW',nREFINENOTIFNEWID);
        PERFORM p_system_doclinks_add(TABLENAME,rec.ID,'REFINENOTIFNEW',nREFINENOTIFNEWID);
      end loop;
      update STATEMENTPBSVPKP s set STATUSDOC = '2' where s.id = rec.STATEMENTPBSVPKPID;
      if tablename ~~* 'JOURNALOTHERS' then
        update JOURNALOTHERS s set STATUS_OTHER = '1' where s.id = rec.id;
      elsif tablename ~~* 'JOURNALPERSPAY' then
        update JOURNALPERSPAY s set STATUS_PERSPAY = '1' where s.id = rec.id;
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

ALTER FUNCTION public.p_action_gen_uved (idlist text, uid bigint, unit bigint, tablename text, cname_ubp bigint, inn_ubp text, kpp_ubp text, okato text, ls_ubp text, kbr_id bigint, bkd_id bigint, add_klass bigint, fund_source text, purpose text, agent_accid bigint)
  OWNER TO magicbox;