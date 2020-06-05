CREATE OR REPLACE FUNCTION public.p_action_move_repinc_tik2iksrf
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
     (select 't1' as tbl, -- таблица 1
             'ACCOUNTABILITYIKSRFS1SD' as tbl_name,
     		 a1.id,
     	     a1.measuresofshapeid
        from ACCOUNTABILITYIKSRFS1SD a1
        inner join MEASURESOFSHAPE ms on ms.id = a1.measuresofshapeid and not ms.marktext
       where a1.accountabilityiksrfid = rec.report_id
      union all
      select 't2' as tbl, -- таблица 2
             'ACCOUNTABILITYIKSRFS2AE' as tbl_name,
        	 a2.id,
             a2.measuresofshapeid
        from ACCOUNTABILITYIKSRFS2AE a2
        inner join MEASURESOFSHAPE ms on ms.id = a2.measuresofshapeid and not ms.marktext
       where a2.accountabilityiksrfid = rec.report_id
      union all
      select 'p2' as tbl, -- Приложение 2
             'IKSRFPRIL2' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL2 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p4' as tbl, -- Приложение 4
             'IKSRFPRIL4' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL4 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p5' as tbl, -- Приложение 5
             'IKSRFPRIL5' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL5 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
	  union all
      select 'p6' as tbl, -- Приложение 6
             'IKSRFPRIL6' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL6 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
	  union all
      select 'p7' as tbl, -- Приложение 7
             'IKSRFPRIL7' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL7 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p8' as tbl, -- Приложение 8
             'IKSRFPRIL8' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL8 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p9' as tbl, -- Приложение 9
             'IKSRFPRIL9' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL9 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
	  union all
      select 'p10' as tbl, -- Приложение 10
             'IKSRFPRIL10' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL10 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p11' as tbl, -- приложение 11
             'IKSRFPRIL11' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL11 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p12' as tbl, -- приложение 12
             'IKSRFPRIL12' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL12 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p13' as tbl, -- приложение 13
             'IKSRFPRIL13' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL13 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p14' as tbl, -- приложение 14
             'IKSRFPRIL14' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL14 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
      union all
      select 'p15' as tbl, -- приложение 15
             'IKSRFPRIL15' as tbl_name,
             a11.id,
     	     a11.measuresofshapeid
        from IKSRFPRIL15 a11
        inner join MEASURESOFSHAPE ms on ms.id = a11.measuresofshapeid and not ms.marktext
       where a11.accountabilityiksrfid = rec.report_id
     )
     loop
       insert into REPINC_LINK_TMP(stbl, stable_name, nrep_id, nmeasuresofshape, nid_lnk)
       values(sp.tbl, sp.tbl_name, rec.report_id, sp.measuresofshapeid, sp.id);
     end loop;
   end loop;

   /*for sp in
   (select count(*) ncnt from REPINC_LINK_TMP)
   loop
     perform p_system_exception(0, sp.ncnt::text);
   end loop;*/

   -- СОХРАНЕНИЕ ID КУДА'

   -- ОСНОВНАЯ ВЫБОРКА ПО ОТЧЕТУ КУДА
   for rec in
   (select ri.cid,
   	       ri.report_id,
           ri.status
      from REPORT_INCLUSION RI
     where ri.status = '1'
       and ri.cid = ident
     group by ri.cid,
     	      ri.report_id,
              ri.status
   )
   loop
     for sp in
     (-- таблица 1
      select 't1' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'ACCOUNTABILITYTIKS1SD' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             0 as ngr04,
             0 as ngr05,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) as ngr06, -- графа 6
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION_FROMUIK,0) as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             0 as ngr10,
             0 as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from ACCOUNTABILITYTIKS1SD tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0 or COALESCE(tbl1.UIKREFERENDUMCOMMISSION_FROMUIK,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
      union all
      -- таблица 2  3,10,11,12,13
      select 't2' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'ACCOUNTABILITYTIKS2AE' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             0 as ngr04,
             0 as ngr05,
             0 as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             COALESCE(tbl1.SUM,0) as ngr10,
             COALESCE(tbl1.EXPENSESTIK,0) as ngr11,
             COALESCE(tbl1.EXPENSESUIK,0) as ngr12,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION_FROMUIK,0) as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from ACCOUNTABILITYTIKS2AE tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.SUM,0) <> 0 or
             COALESCE(tbl1.EXPENSESTIK,0) <> 0 or
             COALESCE(tbl1.EXPENSESUIK,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION_FROMUIK,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
      union all
      -- приложение 2 8,9,10,11
      select 'p2' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL2' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             0 as ngr04,
             0 as ngr05,
             0 as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) as ngr09,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) as ngr10,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL2 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
      union all
      -- приложение 4
      select 'p4' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL4' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             COALESCE(tbl1.CIRCULATION,0) as ngr04,
             0 as ngr05,
             0 as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             0 as ngr10,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) as ngr11,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL4 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.CIRCULATION,0) <> 0 or
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
      union all
      -- приложение 5
      select 'p5' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL5' as tbl_from,
             tbl1.measuresofshapeid,
             COALESCE(tbl1.TOTALLEN,0) as ngr03,
             COALESCE(tbl1.TOTNUMOFVOTE,0) as ngr04,
             0 as ngr05,
             COALESCE(tbl1.INFLIGHT,0) as ngr06, -- графа 6
             COALESCE(tbl1.CAMPS,0) as ngr07, -- графа 7
             0 as ngr08,
             COALESCE(tbl1.TOTALCOSTOFEXPENSES,0) as ngr09,
             0 as ngr10,
             0 as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL5 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.TOTALLEN,0) <> 0 or
             COALESCE(tbl1.TOTNUMOFVOTE,0) <> 0 or
             COALESCE(tbl1.INFLIGHT,0) <> 0 or
             COALESCE(tbl1.CAMPS,0) <> 0 or
             COALESCE(tbl1.TOTALCOSTOFEXPENSES,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
      union all
      -- приложение 6
      select 'p6' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL6' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             0 as ngr04,
             0 as ngr05,
             0 as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) as ngr09,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) as ngr10,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL6 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id
                        and ri.report_id = rec.report_id)
      union all
      -- приложение 7
      select 'p7' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL7' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             0 as ngr04,
             0 as ngr05,
             COALESCE(tbl1.PURCHASEDEQUIPMENT,0) as ngr06, -- графа 6
             COALESCE(tbl1.TOTAL,0) as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             0 as ngr10,
             0 as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL7 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.PURCHASEDEQUIPMENT,0) <> 0 or
             COALESCE(tbl1.TOTAL,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)
      union all
      -- приложение 8 3-5,10,11,13; 4
      select 'p8' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL8' as tbl_from,
             tbl1.measuresofshapeid,
             COALESCE(tbl1.QUANT,0) as ngr03,
             0 as ngr04,
             0 as ngr05,
             0 as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             0 as ngr10,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) as ngr11,
             0 as ngr12,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL8 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.QUANT,0) <> 0 or
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)
      union all
      -- приложение 9 4, 11-14
      select 'p9' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL9' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             COALESCE(tbl1.QUANTITY,0) as ngr04,
             0 as ngr05,
             0 as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             0 as ngr10,
             0 as ngr11,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) as ngr12,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) as ngr13,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL9 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.QUANTITY,0) <> 0 or
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)
      union all
      -- приложение 10
      select 'p10' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL10' as tbl_from,
             tbl1.measuresofshapeid,
             COALESCE(tbl1.QUANT,0) as ngr03,
             0 as ngr04,
             0 as ngr05,
             0 as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0)  as ngr10,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0)  as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL10 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.QUANT,0) <> 0 or
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)
      union all
      -- приложение 11
      select 'p11' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL11' as tbl_from,
             tbl1.measuresofshapeid,
             COALESCE(tbl1.NUMOFCIVILUIK_UIK,0) as ngr03,
             0 as ngr04,
             0 as ngr05,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION_UIK,0) as ngr06, -- графа 6
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION_UIK,0) as ngr07, -- графа 7
             0 as ngr08,
             COALESCE(tbl1.NUMOFCIVIL,0) as ngr09,
             0 as ngr10,
             0 as ngr11,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL11 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.NUMOFCIVILUIK_UIK,0) <> 0 or
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION_UIK,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION_UIK,0) <> 0 or
             COALESCE(tbl1.NUMOFCIVIL,0) <> 0 or
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)
      union all
      -- приложение 12
      select 'p12' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL12' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             0 as ngr04,
             COALESCE(tbl1.CIRCULATIONPRINTED,0) as ngr05,
             COALESCE(tbl1.TOTAL,0) as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             0 as ngr10,
             0 as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL12 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.CIRCULATIONPRINTED,0) <> 0 or
             COALESCE(tbl1.TOTAL,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)
      union all
      -- приложение 13
      select 'p13' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL13' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             0 as ngr04,
             COALESCE(tbl1.QUANT,0) as ngr05,
             COALESCE(tbl1.TOTAL,0) as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             COALESCE(tbl1.QUANT2,0) as ngr08,
             COALESCE(tbl1.TOTAL2,0) as ngr09,
             0 as ngr10,
             COALESCE(tbl1.QUANT3,0) as ngr11,
             COALESCE(tbl1.TOTAL3,0) as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL13 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.QUANT,0) <> 0 or
             COALESCE(tbl1.TOTAL,0) <> 0 or
             COALESCE(tbl1.QUANT2,0) <> 0 or
             COALESCE(tbl1.TOTAL2,0) <> 0 or
             COALESCE(tbl1.QUANT3,0) <> 0 or
             COALESCE(tbl1.TOTAL3,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)
      union all
      -- приложение 14
      select 'p14' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL14' as tbl_from,
             tbl1.measuresofshapeid,
             COALESCE(tbl1.COSTOFMANUFACT,0) as ngr03,
             COALESCE(tbl1.QUANT,0) as ngr04,
             COALESCE(tbl1.COSTOFREPLICATION,0) as ngr05,
             0 as ngr06, -- графа 6
             COALESCE(tbl1.COSTPLACEMENTS,0) as ngr07, -- графа 7
             0 as ngr08,
             0 as ngr09,
             0 as ngr10,
             0 as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL14 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.COSTOFMANUFACT,0) <> 0 or
             COALESCE(tbl1.QUANT,0) <> 0 or
             COALESCE(tbl1.COSTOFREPLICATION,0) <> 0 or
             COALESCE(tbl1.COSTPLACEMENTS,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)
      union all
      -- приложение 15
      select 'p15' as tbl,
             tbl1.accountabilitytikid,
             tbl1.id as id_from,
             'TIKPRIL15' as tbl_from,
             tbl1.measuresofshapeid,
             0 as ngr03,
             0 as ngr04,
             0 as ngr05,
             0 as ngr06, -- графа 6
             0 as ngr07, -- графа 7
             0 as ngr08,
             COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) as ngr09,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) as ngr10,
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) as ngr11,
             0 as ngr12,
             0 as ngr13,
             0 as ngr14,
             0 as ngr17,
             0 as ngr18,
             0 as ngr19,
             ms.code
        from TIKPRIL15 tbl1
        inner join MEASURESOFSHAPE ms on ms.id = tbl1.measuresofshapeid and not ms.marktext
       where 1=1
         and (COALESCE(tbl1.TIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSION,0) <> 0 or
             COALESCE(tbl1.UIKREFERENDUMCOMMISSIONFROMUIK,0) <> 0)
         and exists (select 1
                       from REPORT_INCLUSION RI
                      where ri.cid = rec.cid
                        and ri.status = rec.status
                        and tbl1.accountabilitytikid = ri.inc_rep_id)

       order by 1, 5
     )
     loop
       -- определение инфы исходящей таблицы
       if sp.tbl <> COALESCE(stbl_f,'-1') or rec.report_id <> COALESCE(ntblirep_f,-1) or sp.measuresofshapeid <> COALESCE(ntblm_f,-1)
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
       if sp.tbl = 't1'
       then
        --raise using message = sp.tbl;
         update ACCOUNTABILITYIKSRFS1SD a1
            set TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a1.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr06,
            	UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a1.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr07
          where a1.id = ntbli_f;
       elsif sp.tbl = 't2'
       then
         update ACCOUNTABILITYIKSRFS2AE a2
            set SUM_FROMTIK = COALESCE(a2.SUM_FROMTIK,0) + sp.ngr10,
                EXPENSESTIK_FROMTIK = COALESCE(a2.EXPENSESTIK_FROMTIK,0) + sp.ngr11,
                EXPENSESUIK_FROMTIK = COALESCE(a2.EXPENSESUIK_FROMTIK,0) + sp.ngr12,
                UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr13
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p2'
       then
         update IKSRFPRIL2 a2
            set TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr09,
                UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr10,
                UIKREFERENDUMCOMMISSION_FROMUIKANDTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMUIKANDTIK,0) + sp.ngr11
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p4'
       then
         update IKSRFPRIL4 a2
            set TOTAL = COALESCE(a2.TOTAL,0) + sp.ngr04,
                TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr11,
                UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr12
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p5'
       then
         update IKSRFPRIL5 a2
            set TOTALLEN = COALESCE(a2.TOTALLEN,0) + sp.ngr03,
            	NUMOFVOTE = COALESCE(a2.NUMOFVOTE,0) + sp.ngr04,
                INFLIGHT = COALESCE(a2.INFLIGHT,0) + sp.ngr06,
                CAMPS = COALESCE(a2.CAMPS,0) + sp.ngr07,
                TOTALCOSTOFEXPENSES = COALESCE(a2.TOTALCOSTOFEXPENSES,0) + sp.ngr09
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p6'
       then
         update IKSRFPRIL6 a2
            set TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr09,
            	UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr10,
                UIKREFERENDUMCOMMISSION_FROMUIKANDTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMUIKANDTIK,0) + sp.ngr11
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p7'
       then
         update IKSRFPRIL7 a2
            set PURCHASEDEQUIPMENT_FROMTIK = COALESCE(a2.PURCHASEDEQUIPMENT_FROMTIK,0) + sp.ngr06,
            	TOTAL_FROMTIK = COALESCE(a2.TOTAL_FROMTIK,0) + sp.ngr07
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p8'
       then
         update IKSRFPRIL8 a2
            set QUANT = COALESCE(a2.QUANT,0) + sp.ngr03,
            	TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr11,
            	UIKREFERENDUMCOMMISSION_FROMUIKANDTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMUIKANDTIK,0) + sp.ngr13
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p9'
       then
         update IKSRFPRIL9 a2
            set QUANTITY = COALESCE(a2.QUANTITY,0) + sp.ngr04,
            	TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr12,
            	UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr13,
            	UIKREFERENDUMCOMMISSION_FROMUIKANDTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMUIKANDTIK,0) + sp.ngr14
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p10'
       then
         update IKSRFPRIL10 a2
            set QUANT = COALESCE(a2.QUANT,0) + sp.ngr03,
            	TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr10,
            	UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr11
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p11'
       then
         update IKSRFPRIL11 a2
            set NUMOFCIVILUIK_FROMTIK = COALESCE(a2.NUMOFCIVILUIK_FROMTIK,0) + sp.ngr03,
            	TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr06,
            	UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr07,
            	NUMOFCIVIL_FROMTIK = COALESCE(a2.NUMOFCIVIL_FROMTIK,0) + sp.ngr09,
            	TIKREFERENDUMCOMMISSION_FROMTIK2 = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK2,0) + sp.ngr12
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p12'
       then
         update IKSRFPRIL12 a2
            set CIRCULATIONPRINTED = COALESCE(a2.CIRCULATIONPRINTED,0) + sp.ngr05,
            	TOTAL = COALESCE(a2.TOTAL,0) + sp.ngr06
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p13'
       then
         update IKSRFPRIL13 a2
            set QUANT = COALESCE(a2.QUANT,0) + sp.ngr05,
            	TOTAL = COALESCE(a2.TOTAL,0) + sp.ngr06,
            	QUANT2 = COALESCE(a2.QUANT2,0) + sp.ngr08,
            	TOTAL2 = COALESCE(a2.TOTAL2,0) + sp.ngr09,
            	QUANT3 = COALESCE(a2.QUANT3,0) + sp.ngr11,
            	TOTAL3 = COALESCE(a2.TOTAL3,0) + sp.ngr12
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p14'
       then
         update IKSRFPRIL14 a2
            set COSTOFMANUFACT = COALESCE(a2.COSTOFMANUFACT,0) + sp.ngr03,
            	QUANT = COALESCE(a2.QUANT,0) + sp.ngr04,
            	COSTREPLICATION = COALESCE(a2.COSTREPLICATION,0) + sp.ngr05,
            	COSTPLACEMENTS = COALESCE(a2.COSTPLACEMENTS,0) + sp.ngr07
          where a2.id = ntbli_f;
       elsif sp.tbl = 'p15'
       then
         update IKSRFPRIL15 a2
            set TIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.TIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr09,
            	UIKREFERENDUMCOMMISSION_FROMTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMTIK,0) + sp.ngr10,
            	UIKREFERENDUMCOMMISSION_FROMUIKANDTIK = COALESCE(a2.UIKREFERENDUMCOMMISSION_FROMUIKANDTIK,0) + sp.ngr11
          where a2.id = ntbli_f;
       else
         perform p_system_exception(0, 'Таблица отчета, неопределена!');
       end if;

       -- создание линка
       perform p_system_doclinks_add(stablein => sp.tbl_from, nkeyin => sp.id_from, stableout => stbln_f, nkeyout => ntbli_f, bcascade => false);
     end loop;

     -- смена статуса сводного отчета
     update ACCOUNTABILITYIKSRF set status = 10 where id = rec.report_id;

     -- смена статуса первичных отчетов
     for sp in
     (select ri.inc_rep_id
        from REPORT_INCLUSION RI
       where ri.status = rec.status
         and ri.cid = ident
         and ri.report_id = rec.report_id
       group by ri.inc_rep_id
     )
     loop
       update ACCOUNTABILITYTIK set status = 13 where id = sp.inc_rep_id;
     end loop;
   end loop;
 end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_action_move_repinc_tik2iksrf (ident bigint, uid bigint)
  OWNER TO magicbox;