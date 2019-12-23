CREATE OR REPLACE FUNCTION public.p_action_get_adress (
  nid bigint,
  type integer = 0
)
RETURNS text AS
$body$
--Действие "подтверждение"
DECLARE
/*
	type - тип адреса: 0 - юридический, 1 - фактический.
*/
 
sADR text;

BEGIN

  if type = 0 then
	select trim(COALESCE(		   NULLIF(NULLIF(g.postcode::text,  '<Не указано>'),'')||',','')||
    			COALESCE(' '     ||NULLIF(NULLIF(g.settlement,		'<Не указано>'),'')||',','')||
    	   		COALESCE(' ул. ' ||NULLIF(NULLIF(g.street,    		'<Не указано>'),'')||',','')||
           		COALESCE(' д. '  ||NULLIF(NULLIF(g.house,     		'<Не указано>'),'')||',','')||
           		COALESCE(' к. '  ||NULLIF(NULLIF(g.housing,   		'<Не указано>'),'')||',','')||
           		COALESCE(' стр. '||NULLIF(NULLIF(g.building,  		'<Не указано>'),'')||',',''),',') as adr_org
      into sADR
      from ORGANIZATIONDIR g
     where g.id = nid;
 elsif type = 1 then
 	select trim(COALESCE(		   NULLIF(NULLIF(g.postcode2::text,  '<Не указано>'),'')||',','')||
    			COALESCE(' '     ||NULLIF(NULLIF(g.settlement2,		 '<Не указано>'),'')||',','')||
    	   		COALESCE(' ул. ' ||NULLIF(NULLIF(g.street2,    		 '<Не указано>'),'')||',','')||
           		COALESCE(' д. '  ||NULLIF(NULLIF(g.house2,     		 '<Не указано>'),'')||',','')||
           		COALESCE(' к. '  ||NULLIF(NULLIF(g.housing2,   		 '<Не указано>'),'')||',','')||
           		COALESCE(' стр. '||NULLIF(NULLIF(g.building2,  		 '<Не указано>'),'')||',',''),',') as adr_org
      into sADR
      from ORGANIZATIONDIR g
     where g.id = nid;
 else raise using message = 'Не верный тип адреса! Может быть только 0 - юридический, 1 - фактический! По умолчанию 0!';
 end if;
 
	return sADR;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_get_adress (nid bigint, type integer)
  OWNER TO magicbox;