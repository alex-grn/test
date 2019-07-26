CREATE TRIGGER trg_benefitspackets_before_iu
  BEFORE INSERT OR UPDATE 
  ON public.benefitspackets
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.t_benefitspackets_before_iu();

