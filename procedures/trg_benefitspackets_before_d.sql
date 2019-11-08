CREATE TRIGGER trg_benefitspackets_before_d
  BEFORE DELETE 
  ON public.benefitspackets
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.t_benefitspackets_before_d();
