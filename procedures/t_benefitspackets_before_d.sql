CREATE OR REPLACE FUNCTION public.t_benefitspackets_before_d (
)
RETURNS trigger AS
$body$
    BEGIN  
        IF (select count(*) from BENEFICIARIESREGISTERS s where s.benefitspacketsid = COALESCE(OLD.id,-1)) > 0 THEN
       	   RAISE USING MESSAGE = 'Есть загруженные реестры получателей. Удаление запрещено!';
        END IF;
        RETURN old;
    END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.t_benefitspackets_before_d ()
  OWNER TO postgres;