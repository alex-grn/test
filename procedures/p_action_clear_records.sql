CREATE OR REPLACE FUNCTION public.p_action_clear_records (
)
RETURNS void AS
$body$
declare
   RC RECORD;
begin
     DELETE FROM MULTIPLEPAYMENTS S;
     DELETE FROM UNLAWFULSURCHARGE S;
     FOR RC IN (SELECT S.ID FROM BENEFITSRECIPIENTS S)
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
        END LOOP;
  	
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_clear_records ()
  OWNER TO magicbox;