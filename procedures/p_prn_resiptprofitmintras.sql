CREATE OR REPLACE FUNCTION p_prn_resiptprofitmintras(date_to date) RETURNS void AS
$body$
DECLARE 
i_ident INTEGER ;
rec          record;
n_val4 NUMERIC(17,2) ;

BEGIN
i_ident = pg_backend_pid(); 
DELETE  from RESIPPROFITmintrasBUF WHERE ident = i_ident; 

 for rec in
      select  r.kbkinid,
							r.SUMM_PLAN as val3,
							r.SUMM_FACT as val5,
							r.PROC_FACT as val6
								from
								(
								select SUM(t.summ) SUMM_PLAN,
								SUM(PP.summ) SUMM_FACT,
	      cast((SUM(PP.summ) / SUM(t.summ)) *100 as NUMERIC(17,2)) PROC_FACT,
	      t.kbkinid
         from budgetlist doc,
	      budgetlistspc t,
	      paylist PL,
              postpay PP
	where doc.id=t.budgetlistid
	AND PL.ID=PP.paylistid
	AND PP.budgetlistspcid=T.ID
  and PL.docdate< to_date('01.01.'||to_char(date_to,'YYYY'),'dd.mm.yyyy') 
	and	PL.docdate >= (to_date('01.01.'||to_char(date_to,'YYYY'),'dd.mm.yyyy') - interval '1 year')
	and doc.docdate < to_date('01.01.'||to_char(date_to,'YYYY'),'dd.mm.yyyy') and
	    doc.docdate >= (to_date('01.01.'||to_char(date_to,'YYYY'),'dd.mm.yyyy') - interval '1 year')
	    GROUP BY  t.kbkinid
		) r
     loop
--просчет за декабрь 
        select 
							SUM(PP.summ)  into n_val4
         from budgetlist doc,
							budgetlistspc t,
							paylist PL,
              postpay PP
      	where doc.id=t.budgetlistid
	        AND PL.ID=PP.paylistid
					AND PP.budgetlistspcid=T.ID
					and t.kbkinid=rec.kbkinid
				  and PL.docdate< to_date('01.01.'||to_char(date_to,'YYYY'),'dd.mm.yyyy') 
					and	PL.docdate >= (to_date('01.12.'||to_char(date_to,'YYYY'),'dd.mm.yyyy') - interval '1 year')
					and doc.docdate < to_date('01.01.'||to_char(date_to,'YYYY'),'dd.mm.yyyy') 
					and	doc.docdate >= (to_date('01.12.'||to_char(date_to,'YYYY'),'dd.mm.yyyy') - interval '1 year')
	  GROUP BY  t.kbkinid;

 	INSERT INTO RESIPPROFITmintrasBUF (ident,val3,val4,val5,val6,kbkinid)
		VALUES(i_ident,rec.val3,n_val4,rec.val5,rec.val6,rec.kbkinid); 
     end loop;    

END; 
$body$
language plpgsql volatile;
