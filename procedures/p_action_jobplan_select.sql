CREATE OR REPLACE FUNCTION public.p_action_jobplan_select (
  citizenryid bigint,
  tablename text,
  checkbox1 boolean,
  checkbox2 boolean,
  checkbox3 boolean,
  uid bigint
)
RETURNS void AS
$body$
 declare
 sSQL text;
 nuid bigint:=uid;
 begin
  sSQL:='
                	insert into DIRECTION(CITIZENRYID,ORGANIZATIONDIRID,VACANCYORGID,STATUS,uid)
                      (select g.id as gid,s.ORGANIZATIONDIRID as sid,v.id as vid,5,'||nuid||'
                  from ORGANIZATION s,
                  	   CITIZENRY g,
                       VACANCYORG v';
  if checkbox2 or checkbox3 then
  sSQL:=sSQL||',EDUCATIONCIT e ';
  end if;                      
                      
  sSQL:=sSQL||' where g.id = '||p_action_jobplan_select.citizenryid||' 
                   and v.ORGANIZATIONid = s.id ';              	
  if checkbox1 then
  sSQL:=sSQL||' and s.regiondirid = g.regiondirid';
  end if;
  if checkbox2 or checkbox3 then
  sSQL:=sSQL||' and e.citizenryid = g.id
                and e.hidedate = (select max(hidedate) from EDUCATIONCIT ee where ee.citizenryid = e.citizenryid)';
  end if;
  if checkbox2 then
  sSQL:=sSQL||' and v.professiondirid = e.professiondirid';
  end if; 
  if checkbox3 then
  sSQL:=sSQL||' and v.leveleducation = e.leveleducation';
  end if;
  sSQL:=sSQL||');';                 
  execute sSQL;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_jobplan_select (citizenryid bigint, tablename text, checkbox1 boolean, checkbox2 boolean, checkbox3 boolean, uid bigint)
  OWNER TO magicbox;