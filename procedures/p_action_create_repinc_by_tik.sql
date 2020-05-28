CREATE OR REPLACE FUNCTION public.p_action_create_repinc_by_tik
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
   uik  record;
 begin
   for rec in
   (select at.id,
           at.electcampaignid,
   		   ec.idgasecom
   	  from ACCOUNTABILITYTIK at
     inner join electcommittee ec on ec.id = at.electcommitteeid
     where at.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST)))
   loop
     for uik in
     (SELECT *
        FROM json_to_recordset
             (P_SYSTEM_GET_DATA_TABLE(stablename=>'accountabilityuik',
                                      sCOND_LIKE=>'{"electcampaignid":['||rec.electcampaignid||'],"status":[5]}', -- статус 5
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
            values(ident, nuid, uik.electcampaignid, uik.datecreate, uik.electcommitteeid, '0', uik.statusreport, uik.tested, uik.checked, uik.submitted,'ACCOUNTABILITYUIK',uik.id,'ACCOUNTABILITYTIK', rec.id);
     end loop;
   end loop;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_create_repinc_by_tik (idlist text, ident bigint, uid bigint)
  OWNER TO magicbox;