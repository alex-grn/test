CREATE OR REPLACE FUNCTION public.p_return_payaccounts_payer_data (
  npayaccountsid bigint,
  out selectcommittee text,
  out selcmtacccode text,
  out selectcommitteename text,
  out sinnec text,
  out skppec text,
  out sagentbanksec text,
  out sbicbankec text,
  out scorraccec text
)
RETURNS record AS
$body$
begin
  begin
    select k.code, -- "ELECTCOMMITTEE" name="Избирательная комиссия" caption="Юр. лицо"
           e.BANKACC, -- "ELCMTACCCODE" name="Расчетный счет избирательной комиссии" caption="Счет плательщика"
           k.name, -- "ELECTCOMMITTEENAME" name="Наименование плательщика" caption="Наименование плательщика"
           k.INN, -- "INNEC" name="ИНН" caption="ИНН"
           k.KPP, -- "KPPEC" name="КПП" caption="КПП"
           a.NAME, -- "AGENTBANKSEC" name="Банк плательщика" caption="Банк плательщика"
           b.BIC, -- "BICBANKEC" name="БИК" caption="БИК"
           b.CORRACC -- "CORRACCEC" name="Корр.счет" caption="Корр.счет"
      into strict sELECTCOMMITTEE,
                  sELCMTACCCODE,
                  sELECTCOMMITTEENAME,
                  sINNEC,
                  sKPPEC,
                  sAGENTBANKSEC,
                  sBICBANKEC,
                  sCORRACCEC
      from PAYACCOUNTS p
      left join JURPERSONS j on j.id = p.jurpersonsid
      left join ELECTCOMMITTEE k on k.id = j.electcommitteeid
      left join ELCMTACC e on e.id = p.elcmtaccid
      left join AGENTBANKS b on b.id = e.AGENTBANKSID
      left join AGENT a on a.id = b.agentid
     where p.id = nPAYACCOUNTSID;
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

ALTER FUNCTION public.p_return_payaccounts_payer_data (npayaccountsid bigint, out selectcommittee text, out selcmtacccode text, out selectcommitteename text, out sinnec text, out skppec text, out sagentbanksec text, out sbicbankec text, out scorraccec text)
  OWNER TO magicbox;