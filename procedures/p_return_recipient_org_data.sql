CREATE OR REPLACE FUNCTION public.p_return_recipient_org_data (
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
    select a.name, -- "" name="Наименование получателя" caption="Наименование получателя"
           a.INN, -- "" name="ИНН" caption="ИНН"
           a.KPP, -- "" name="КПП" caption="КПП"
           r.name, -- "" name="Банк получателя" caption="Банк получателя"
           r.bic, -- "" name="БИК" caption="БИК"
           r.corracc-- "" name="Корр.счет" caption="Корр.счет"
      into STRICT sAGENTNAME,
      			  sINNAG,
                  sKPPAG,
                  sAGENTBANKSAGID,
                  sBICBANKAGENT,
                  sCORRACCAG
      from agent a
      left join (select p.agentid, p.ID, b.bic, b.corracc, ab.NAME
                   from AGENTACC   p
                   left join AGENTBANKS b on b.ID = p.AGENTBANKSID
                   left join AGENT      ab on ab.id = b.agentid
             where p.ID = nagentaccid) r on r.agentid = a.id
     where a.id = nagentid;
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

ALTER FUNCTION public.p_return_recipient_org_data (nagentid bigint, nagentaccid bigint, out sAGENTNAME text, out sINNAG text, out sKPPAG text, out sAGENTBANKSAGID text, out sBICBANKAGENT text, out sCORRACCAG text)
  OWNER TO magicbox;