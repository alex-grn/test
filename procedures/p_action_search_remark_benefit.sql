CREATE OR REPLACE FUNCTION public.p_action_search_remark_benefit (
  numreestr integer,
  periodpay text,
  periodextra text,
  subject bigint
)
RETURNS text AS
$body$
declare
   RC RECORD;
   tmp text;
   period1 text;
   period2 text;
   
begin

if numreestr in (3,4) then
	tmp:='to_char(pp.paydate,''dd.mm.yyyy'')';
else
	tmp:='pp.paydate';
end if;
if periodpay is null then
	period1 := tmp||' is null';
else 
	period1 := tmp||' = '''||COALESCE(periodpay,'')||'''';
end if;
if periodextra is null then
	period2 := 'pp.extradate is null';
else
	period2 := 'pp.extradate = '''||COALESCE(periodextra,'')||'''';
end if;

    for RC in execute ' select r.note
                           from benefit0'||numreestr||' b,
                                remark r,
                                benefitspackets p,
                                benefit0'||numreestr||'payment pp
                          where r.id = b.remarkid
                            and p.id = b.benefitspacketsid
                            and p.subjectsdirid = '||subject||'
                            and pp.benefit0'||numreestr||'id = b.id
                            and '||period1||'
                            and '||period2
    	loop
        	return RC.NOTE;
        end loop;
        
  	return null;
    
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_search_remark_benefit (numreestr integer, periodpay text, periodextra text, subject bigint)
  OWNER TO magicbox;