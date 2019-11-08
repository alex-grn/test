CREATE TRIGGER trg_beneficiariesregisters_before_iu
  AFTER INSERT OR UPDATE 
  ON public.beneficiariesregisters
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.t_beneficiariesregisters_before_iu();
