CREATE TRIGGER trg_beneficiariesregisters_before_iu
  BEFORE INSERT OR UPDATE 
  ON public.beneficiariesregisters
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.t_beneficiariesregisters_before_iu();

