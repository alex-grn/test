CREATE OR REPLACE FUNCTION public.p_action_clear_records (
)
RETURNS void AS
$body$
declare
   RC RECORD;
begin
     DELETE FROM MULTIPLEPAYMENTS S;
     DELETE FROM UNLAWFULSURCHARGE S;
     
      FOR RC IN 
       SELECT s.id
         FROM BENEFITSRECIPIENTS S
          left join benefit01 b1 on b1.benefitsrecipientsid = s.id
          left join benefit02 b2 on b2.benefitsrecipientsid = s.id
          left join benefit03 b3 on b3.benefitsrecipientsid = s.id
          left join benefit04 b4 on b4.benefitsrecipientsid = s.id
          left join benefit05 b5 on b5.benefitsrecipientsid = s.id
          left join benefit06 b6 on b6.benefitsrecipientsid = s.id
          left join benefit07 b7 on b7.benefitsrecipientsid = s.id
         where COALESCE(b1.id,b2.id,b3.id,b4.id,b5.id,b6.id,b7.id) is null
    	LOOP
        	delete from BENEFITSRECIPIENTS b where b.id = rc.id;
        END LOOP;
     /*FOR RC IN (SELECT S.ID FROM BENEFITSRECIPIENTS S)
    	LOOP
        	IF (select case when sum(ssum) > 0 then 'true' 
			else 'false' 
			end 
			from   
            (select count(*) as ssum from benefit01 s where s.benefitsrecipientsid = RC.ID     
				union     
				select count(*) from benefit02 s where s.benefitsrecipientsid = RC.ID     
				union     
				select count(*) from benefit03 s where s.benefitsrecipientsid = RC.ID     
				union     
				select count(*) from benefit04 s where s.benefitsrecipientsid = RC.ID     
				union     
				select count(*) from benefit05 s where s.benefitsrecipientsid = RC.ID     
				union     
				select count(*) from benefit06 s where s.benefitsrecipientsid = RC.ID     
				union     
				select count(*) from benefit07 s where s.benefitsrecipientsid = RC.ID)SS) = 'false' THEN
                begin
                 DELETE FROM BENEFITSRECIPIENTS S WHERE S.ID = RC.ID;
                exception when others then null;
                end;
             END IF;
        END LOOP;*/
  	
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_clear_records ()
  OWNER TO magicbox;