CREATE OR REPLACE FUNCTION public.p_action_change_insperson (
  idlist text,
  uid bigint,
  unit bigint,
  date date,
  inspersonid bigint,
  note text
)
RETURNS void AS
$body$
DECLARE  
    nUID   bigint := UID;
    RC     record; 
    dDATE  date:=date;
    nINSPERSONID bigint:=inspersonid;
    sNOTE TEXT:=note;
    nSUMMNEW numeric;
    nSUMMCANCEL numeric;
    --определение уровня доступа
    nLID   bigint:=P_SYSTEM_GEN_LID('FINEHISTORY',nUID,UNIT);
BEGIN
     
  for RC in
    select f.id as FINEID,
           f.OWNERID,
           f.STATUSEAF
      from fine f
     where f.id = ANY(p_system_get_selectlist(idlist))
  loop
     /*найти последнюю строку, и взять от туда суммы*/
     select f.SUMMNEW, f.SUMMCANCEL
       into nSUMMNEW, nSUMMCANCEL
       from finehistory f
      where f.FINEID = rc.FINEID
      order by f.ID desc
      limit 1;
     insert into finehistory(uid,lid,ownerid,fineid,datestart,statuseaf,inspersonid,summnew,summcancel,note)
     values(nUID,nLID,rc.OWNERID,rc.FINEID,dDATE,rc.STATUSEAF,nINSPERSONID,nSUMMNEW,nSUMMCANCEL,sNOTE);
     update fine f set INSPERSONID = nINSPERSONID where f.ID = RC.FINEID;
  end loop;
 
  
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_change_insperson (idlist text, uid bigint, unit bigint, date date, inspersonid bigint, note text)
  OWNER TO magicbox;