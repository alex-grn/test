CREATE TRIGGER trg_benefitspackets_before_ui
  BEFORE INSERT OR UPDATE 
  ON public.benefitspackets
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.t_benefitspackets_before_ui();
