CREATE OR REPLACE FUNCTION public.p_action_create_repinc_by_iksrf
(
  idlist text,
  ident  bigint,
  uid 	 bigint
)
RETURNS void AS
$body$
 declare
   nuid bigint := uid;
   rec  record;
   tik  record;
 begin
   for rec in
   (select rf.id,
           rf.electcampaignid,
   		   ec.idgasecom
   	  from ACCOUNTABILITYIKSRF rf
     inner join electcommittee ec on ec.id = rf.electcommitteeid
     where rf.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST)))
   loop
     for tik in
     (SELECT *
        FROM json_to_recordset
             (P_SYSTEM_GET_DATA_TABLE(stablename=>'accountabilitytik',
                                      sCOND_LIKE=>'{"electcampaignid":['||rec.electcampaignid||'],"status":[12],"typedoc":[3]}', -- тип отчета 3, статус 12
									  swhere=> 'exists(select 1 from ELECTCOMMITTEE ee where ee.id = ELECTCOMMITTEEID and ee.IDGASPARECOM = '||rec.idgasecom||'::text)',
                                      sselect=>'ID, ELECTCAMPAIGNID, LEVELELCAMPAIGN, DATECREATE, ELECTCOMMITTEEID, STATUSREPORT, TESTED, SUBMITTED, CHECKED')::json)
                                      as d(id BIGINT,
                                           ELECTCAMPAIGNID bigint,
                                           LEVELELCAMPAIGN text,
                                           DATECREATE date,
                                           ELECTCOMMITTEEID bigint,
                                           STATUSREPORT text,
                                           TESTED text,
                                           SUBMITTED text,
                                           CHECKED text)
     )
     loop
       insert into REPORT_INCLUSION(cid, uid, electcampaignid, datecreate, electcommitteeid, status, statusreport, tested, checked, submitted, inc_tbl, inc_rep_id, rep_tbl, report_id)
            values(ident, nuid, tik.electcampaignid, tik.datecreate, tik.electcommitteeid, '0', tik.statusreport, tik.tested, tik.checked, tik.submitted,'ACCOUNTABILITYTIK',tik.id,'ACCOUNTABILITYIKSRF', rec.id);
     end loop;
   end loop;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_create_repinc_by_iksrf (idlist text, ident bigint, uid bigint)
  OWNER TO magicbox;