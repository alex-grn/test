CREATE TRIGGER trg_committeeman_before_iu
  before INSERT OR UPDATE
  ON public.committeeman

FOR EACH ROW
  EXECUTE PROCEDURE public.t_committeeman_before_iu();
