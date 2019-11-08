CREATE OR REPLACE FUNCTION public.t_beneficiariesregisters_before_iu (
)
RETURNS trigger AS
$body$
    DECLARE
		sSTATUSPACK varchar;
    BEGIN
        select s.STATUSPACK into sSTATUSPACK from BENEFITSPACKETS s where s.id = new.benefitspacketsid; --получаем статус из пакета реестра
        IF sSTATUSPACK = '01' THEN  --утверждено
           RAISE USING MESSAGE = 'Загрузка реестра не возможна, обратитесь к своему куратору в Федеральную службу по труду и занятости!';
        END IF;
        RETURN NEW;
    END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.t_beneficiariesregisters_before_iu ()
  OWNER TO postgres;