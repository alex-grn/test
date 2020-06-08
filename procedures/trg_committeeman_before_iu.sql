CREATE TRIGGER trg_committeeman_before_iu
  AFTER INSERT OR UPDATE
  ON public.committeeman

FOR EACH ROW
  EXECUTE PROCEDURE public.t_committeeman_before_iu();
