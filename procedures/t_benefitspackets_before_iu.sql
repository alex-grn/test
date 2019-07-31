CREATE OR REPLACE FUNCTION public.t_benefitspackets_before_iu (
)
RETURNS trigger AS
$body$
    BEGIN
        -- Ругаться когда документ утвержден
        IF OLD.STATUSPACK = '01' and NEW.STATUSPACK = '01' THEN
           RAISE USING MESSAGE = 'Документ утвержден. Действия по данному реестру заблокированы.';
        END IF;
        
        RETURN NEW;
    END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.t_benefitspackets_before_iu ()
  OWNER TO postgres;