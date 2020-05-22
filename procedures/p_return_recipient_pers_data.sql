CREATE OR REPLACE FUNCTION public.p_return_recipient_pers_data (
  nagentid bigint,
  nagentaccid bigint,
  out sAGENTNAME text,
  out sINNAG text,
  out sKPPAG text,
  out sAGENTBANKSAGID text,
  out sBICBANKAGENT text,
  out sCORRACCAG text
)
RETURNS record AS
$body$
begin
  begin
    select p.NAME, -- "" name="Наименование получателя" caption="Наименование получателя"
           r.INN, -- "" name="ИНН" caption="ИНН"
           r.KPP, -- "" name="КПП" caption="КПП"
           r.NAME, -- "" name="Банк получателя" caption="Банк получателя"
           r.BIC, -- "" name="БИК" caption="БИК"
           r.CORRACC -- "" name="Корр.счет" caption="Корр.счет"
      into STRICT sAGENTNAME,
      			  sINNAG,
                  sKPPAG,
                  sAGENTBANKSAGID,
                  sBICBANKAGENT,
                  sCORRACCAG
      from person p
      left JOIN(select pa.personid,
                       pa.INN,
                       pa.KPP,
                       a.NAME,
                       b.BIC,
                       b.CORRACC
                  from personacc pa
                  left join AGENTBANKS b on b.ID = pa.AGENTBANKSID
                  left join AGENT a on a.id = b.agentid
                 where pa.ID = nagentaccid) r on r.personid = p.id
     where p.ID = nagentid;
  exception
    when no_data_found then
      null;
  end;
  return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_return_recipient_pers_data (nagentid bigint, nagentaccid bigint, out sAGENTNAME text, out sINNAG text, out sKPPAG text, out sAGENTBANKSAGID text, out sBICBANKAGENT text, out sCORRACCAG text)
  OWNER TO magicbox;