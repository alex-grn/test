CREATE OR REPLACE FUNCTION public.t_benefitspackets_before_ui (
)
RETURNS trigger AS
$body$
    BEGIN  
        if TO_NUMBER(TO_CHAR(NOW(), 'dd'), '99') > 11
        			or new.repmonth::numeric != TO_NUMBER(TO_CHAR(NOW() - interval '1 month', 'mm'), '99') or new.repyear != TO_NUMBER(TO_CHAR(NOW() - interval '1 month', 'yyyy'), '9999')
  			then
    	--мац 3684 добавили после 1-ого числа, ставим нарушение сроков
    			new.TERMSVIOLATION = true;
             else new.TERMSVIOLATION = false;
            -- RETURN old;  	 
  		end if;  
        RETURN new;
    END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.t_benefitspackets_before_ui ()
  OWNER TO postgres;