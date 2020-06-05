CREATE OR REPLACE FUNCTION public.p_action_move_repinc_uik2tik
(
  ident  bigint,
  uid 	 bigint
)
RETURNS void AS
$body$
 declare
   sql        TEXT;
   nuid   	  bigint := uid;
   rec    	  record;
   sp     	  record;
   stbl_f     text; -- номер таблицы
   ntblirep_f bigint; -- id отчета
   ntblm_f    bigint; -- id показателя
   stbln_f    text; -- имя таблицы
   ntbli_f    bigint; -- id таблицы
 begin
   -- создать времянку для линков
   sql = 'CREATE TEMPORARY TABLE REPINC_LINK_TMP (stbl text, stable_name text, nrep_id bigint, nmeasuresofshape bigint, nid_lnk bigint) WITH (oids = false) ON COMMIT DROP;';
   execute sql;
   sql = 'CREATE INDEX IR_REPINC_LINK_TMP ON REPINC_LINK_TMP USING btree (stbl, nrep_id, nmeasuresofshape);';
   execute sql;

   -- времянка
   -- СОХРАНЕНИЕ ID КУДА
   for rec in
   (select ri.report_id
      from REPORT_INCLUSION RI
     where ri.status = '1'
       and ri.cid = ident
     group by ri.report_id
   )
   loop
     -- таблица 1
     for sp in
     (select '1' as tbl, -- таблица 1
             'ACCOUNTABILITYTIKS1SD' as tbl_name,
     		 a1.id,
     	     a1.measuresofshapeid
        from ACCOUNTABILITYTIKS1SD a1
        inner join MEASURESOFSHAPE ms on ms.id = a1.measuresofshapeid and not ms.marktext
       where a1.accountabilitytikid = rec.report_id
       union all
      select '2' as tbl, -- таблица 2
             'ACCOUNTABILITYTIKS2AE' as tbl_name,
        	 a2.id,
             a2.measuresofshapeid
        from ACCOUNTABILITYTIKS2AE a2
        inner join MEASURESOFSHAPE ms on ms.id = a2.measuresofshapeid and not ms.marktext
       where a2.accountabilitytikid = rec.report_id
      union all
      select '11' as tbl, -- приложение 11
             'TIKPRIL11' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from TIKPRIL11 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilitytikid = rec.report_id)
     loop
       insert into REPINC_LINK_TMP(stbl, stable_name, nrep_id, nmeasuresofshape, nid_lnk)
       values(rec.tbl, rec.tbl_name, rec.report_id, sp.measuresofshapeid, sp.id);
     end loop;
   end loop;
   -- СОХРАНЕНИЕ ID КУДА

   -- ОСНОВНАЯ ВЫБОРКА ПО ОТЧЕТУ КУДА
   for rec in
   (select ri.cid,
   	       ri.report_id
      from REPORT_INCLUSION RI
     where ri.status = '1'
       and ri.cid = ident
     group by ri.cid,
     	      ri.report_id
   )
   loop
     for sp in
     (-- таблица 1
      select '1' as tbl,
             tbl1.accountabilityuikid,
             tbl1.id as id_from,
             'ACCOUNTABILITYUIKS1SD' as tbl_from,
             tbl1.measuresofshapeid,
             COALESCE(tbl1.total,0) as ngr03, -- графа 3
             0as ngr04,
             COALESCE(tbl1.uikreferendumcommission,0) as ngr07, -- графа 7
             0 as ngr13, -- графа 13,
             ms.code
        from ACCOUNTABILITYUIKS1SD tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.total,0) <> 0 or COALESCE(tbl1.uikreferendumcommission,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = '1'
                        and tbl1.accountabilityuikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
      union all
      -- таблица 2
      select '2',
             tbl2.accountabilityuikid,
             tbl2.id as id_from,
             'ACCOUNTABILITYUIKS2AE' as tbl_from,
             tbl2.measuresofshapeid,
             COALESCE(tbl2.total,0) as ngr03,
             0 as ngr04,
             0 as ngr07, -- графа 7
             COALESCE(tbl2.uikreferendumcommission,0) as ngr13,
             ms.code
        from ACCOUNTABILITYUIKS2AE tbl2
        inner join MEASURESOFSHAPE ms on ms.id = tbl2.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl2.total,0) <> 0 or COALESCE(tbl2.uikreferendumcommission,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = '1'
                        and tbl2.accountabilityuikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
      union all
      -- таблица 11
      select '11',
             tbl11.accountabilityuikid,
             tbl11.id as id_from,
             'UIKPRIL11' as tbl_from,
             tbl11.measuresofshapeid,
             COALESCE(tbl11.numofciviluik,0) as ngr03,
             COALESCE(tbl11.total,0) as ngr04,
             COALESCE(tbl11.uikreferendumcommission,0) as ngr07,
             0 as ngr13, -- графа 13
             ms.code
        from UIKPRIL11 tbl11
        inner join MEASURESOFSHAPE ms on ms.id = tbl11.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl11.numofciviluik,0) <> 0 or COALESCE(tbl11.total,0) <> 0 or COALESCE(tbl11.uikreferendumcommission,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = '1'
                        and tbl11.accountabilityuikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
       order by 1, 5
     )
     loop
       -- определение инфы исходящей таблицы
       if sp.tbl <> COALESCE(nullif(stbl_f,''),'-1') or rec.report_id <> COALESCE(ntblirep_f,-1) or sp.measuresofshapeid <> COALESCE(ntblm_f,-1)
       then
         begin
           select rlt.stable_name,
                  rlt.nid_lnk,
                  rlt.nmeasuresofshape,
                  rlt.nrep_id,
                  rlt.stbl
             into strict stbln_f,
                         ntbli_f,
               		     ntblm_f,
                         ntblirep_f,
                         stbl_f
             from REPINC_LINK_TMP rlt
            where rlt.stbl = sp.tbl
              and rlt.nrep_id = rec.report_id
              and rlt.nmeasuresofshape = sp.measuresofshapeid;
         exception
           when no_data_found then
             perform p_system_exception(0, 'Код строки "'||sp.code||'", первичных данных, таблицы "'||p_system_get_class_name(sp.tbl_from)||'", не найден в сводном отчет!');
         end;
       end if;

       -- запись значений
       if sp.tbl = '1'
       then
        -- using message = ntbli_f;
         update ACCOUNTABILITYTIKS1SD a1
            set total = COALESCE(a1.total,0) + sp.ngr03,
            	uikreferendumcommission_fromuik = COALESCE(a1.uikreferendumcommission_fromuik,0) + sp.ngr07
          where a1.id = ntbli_f;
       elsif sp.tbl = '2'
       then
         update ACCOUNTABILITYTIKS2AE a2
            set total = COALESCE(a2.total,0) + sp.ngr03,
            	uikreferendumcommission_fromuik = COALESCE(a2.uikreferendumcommission_fromuik,0) + sp.ngr13
          where a2.id = ntbli_f;
       elsif sp.tbl = '11'
       then
         update TIKPRIL11 a11
            set numofciviluik_uik = COALESCE(a11.numofciviluik_uik,0) + sp.ngr03,
            	total_uik = COALESCE(a11.total_uik,0) + sp.ngr04,
            	uikreferendumcommission_uik = COALESCE(a11.uikreferendumcommission_uik,0) + sp.ngr07/*,
                aveperperson_uik = (COALESCE(a11.total_uik,0) + sp.ngr04) / case when (COALESCE(a11.numofciviluik_uik,0) + sp.ngr03) = 0 then 1 else (COALESCE(a11.numofciviluik_uik,0) + sp.ngr03) end*/
          where a11.id = ntbli_f;
       else
         perform p_system_exception(0, 'Таблица отчета, неопределена!');
       end if;

       -- создание линка
       perform p_system_doclinks_add(stablein => sp.tbl_from, nkeyin => sp.id_from, stableout => stbln_f, nkeyout => ntbli_f, bcascade => false);
     end loop;

     -- смена статуса сводного отчета
     update ACCOUNTABILITYTIK set status = 10 where id = rec.report_id;

     -- смена статуса первичных отчетов
     for sp in
     (select ri.inc_rep_id
        from REPORT_INCLUSION RI
       where ri.status = '1'
         and ri.cid = ident
         and ri.report_id = rec.report_id
       group by ri.inc_rep_id
     )
     loop
       update ACCOUNTABILITYUIK set status = 6 where id = sp.inc_rep_id;
     end loop;
   end loop;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_move_repinc_uik2tik (ident bigint, uid bigint)
  OWNER TO magicbox;