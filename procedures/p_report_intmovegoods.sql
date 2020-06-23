CREATE OR REPLACE FUNCTION public.p_report_intmovegoods (
  idlist text,
  epostsid bigint,
  epersonid bigint
)
RETURNS void AS
$body$
declare
  rec record;
  sp  record;
  i   record;
  nr  integer;
  sdocnumb text;
  idx numeric;

  ssheet    constant text := 'DFT';
  cell_numb constant text := 'h_numb';
  cell_hd   constant text := 'h_date_d';
  cell_hm   constant text := 'h_date_m';
  cell_hy   constant text := 'h_date_y';
  cell_date constant text := 'h_date';
  cell_org  constant text := 'h_org';
  cell_df   constant text := 'h_dept_from';
  cell_dt   constant text := 'h_dept_to';
  cell_val  constant text := 'h_valid';

  line0	    constant text := 'data0';
  cell_d001 constant text := 'd0_01';
  cell_d002 constant text := 'd0_02';
  cell_d003 constant text := 'd0_03';
  cell_d004 constant text := 'd0_04';
  cell_d005 constant text := 'd0_05';
  cell_d006 constant text := 'd0_06';
  cell_d007 constant text := 'd0_07';
  cell_d008 constant text := 'd0_08';

  cell_dtq  constant text := 'd_total_q';
  cell_dts  constant text := 'd_total_s';

  cell_dd   constant text := 'd_date_d';
  cell_dm   constant text := 'd_date_m';
  cell_dy   constant text := 'd_date_y';

  line1     constant text := 'data1';
  cell_d101 constant text := 'd1_01';
  cell_d102 constant text := 'd1_02';
  cell_d103 constant text := 'd1_03';

  cell_spost constant text := 'spost';
  cell_sfio  constant text := 'sfio';
  cell_apost constant text := 'apost';
  cell_afio  constant text := 'afio';
  cell_epost constant text := 'epost';
  cell_efio  constant text := 'efio';

  cell_fd   constant text := 'f_date_d';
  cell_fm   constant text := 'f_date_m';
  cell_fy   constant text := 'f_date_y';

begin
     /*
     delete from EXCEL_LINES;
     delete from EXCEL_COLUMNS;
     delete from EXCEL_CELLS;
     delete from EXCEL_COMMANDS;
     delete from EXCEL_SHEETS;
     */

  perform p_excel_prepare();
  perform p_excel_sheet_select(ssheet);
  perform p_excel_cell_describe(cell_numb);
  perform p_excel_cell_describe(cell_hd);
  perform p_excel_cell_describe(cell_hm);
  perform p_excel_cell_describe(cell_hy);
  perform p_excel_cell_describe(cell_date);
  perform p_excel_cell_describe(cell_org);
  perform p_excel_cell_describe(cell_df);
  perform p_excel_cell_describe(cell_dt);
  perform p_excel_cell_describe(cell_val);

  perform p_excel_line_describe(line0);
  perform p_excel_line_cell_describe(line0, cell_d001);
  perform p_excel_line_cell_describe(line0, cell_d002);
  perform p_excel_line_cell_describe(line0, cell_d003);
  perform p_excel_line_cell_describe(line0, cell_d004);
  perform p_excel_line_cell_describe(line0, cell_d005);
  perform p_excel_line_cell_describe(line0, cell_d006);
  perform p_excel_line_cell_describe(line0, cell_d007);
  perform p_excel_line_cell_describe(line0, cell_d008);

  perform p_excel_cell_describe(cell_dtq);
  perform p_excel_cell_describe(cell_dts);

  perform p_excel_cell_describe(cell_spost);
  perform p_excel_cell_describe(cell_sfio);
  perform p_excel_cell_describe(cell_apost);
  perform p_excel_cell_describe(cell_afio);
  perform p_excel_cell_describe(cell_epost);
  perform p_excel_cell_describe(cell_efio);
  perform p_excel_cell_describe(cell_dd);
  perform p_excel_cell_describe(cell_dm);
  perform p_excel_cell_describe(cell_dy);
  perform p_excel_cell_describe(cell_fd);
  perform p_excel_cell_describe(cell_fm);
  perform p_excel_cell_describe(cell_fy);

  perform p_excel_line_describe(line1);
  perform p_excel_line_cell_describe(line1, cell_d101);
  perform p_excel_line_cell_describe(line1, cell_d102);
  perform p_excel_line_cell_describe(line1, cell_d103);

  -- выборка документов
  for rec in
  (select wih.id,
          wih.docnumb,
          wih.docdate,
          ei.name,
	      ((select r.code
              from COMMITTEEMAN C
              left join ELECTCOMMITTEE R on r.id = c.electcommitteeid
             where c.id = (select max(cc.id)
                             from COMMITTEEMAN CC
                           where cc.personid = mrp0.personid and cc.postenddate >= NOW()))) as ELECTCOMMITTEE0,
	      ((select r.code
              from COMMITTEEMAN C
              left join ELECTCOMMITTEE R on r.id = c.electcommitteeid
             where c.id = (select max(cc.id)
                             from COMMITTEEMAN CC
                            where cc.personid = mrp1.personid and cc.postenddate >= NOW()))) as ELECTCOMMITTEE1,
	   	  wih.apostsid,
          wih.spostsid,
          p0.name as SPERSON,
          p1.name as APERSON,
          wih.validtext
     from WRITEOFF_INVOICE_HEADER WIH
     inner join WRITEOFF 		   W on w.id = wih.writeoffid
     left join electcampaign      EC on ec.id = w.electcampaignid
     left join electcommittee	   EI on ei.id = ec.electcommitteeid
     left join mtresponspers      MRP0 on mrp0.id = wih.respperson
     left join person			   p0 on p0.id = mrp0.personid
     left join mtresponspers      MRP1 on mrp1.id = wih.recipientrespperson
     left join person			   p1 on p1.id = mrp1.personid
    where 1=1
      and wih.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
    order by lpad(wih.docnumb::text,10,'0')
   )
  loop
    if (sdocnumb is null) or (rec.docnumb::text <> sdocnumb)
    then
      sdocnumb := rec.docnumb::text;
      perform p_excel_sheet_copy(ssheet_name_from=>ssheet, ssheet_name_to=>sdocnumb, nmove_to_end=>1);
      perform p_excel_sheet_select(sdocnumb);
    end if;
    perform p_excel_cell_value_write(cell_numb, rec.docnumb::text);
    perform p_excel_cell_value_write(cell_hd, to_char(rec.docdate,'dd'));
    perform p_excel_cell_value_write(cell_hm, p_tools_dmonth_to_smonth(rec.docdate, 1));
    perform p_excel_cell_value_write(cell_hy, to_char(rec.docdate,'yyyy'));
    perform p_excel_cell_value_write(cell_dd, to_char(rec.docdate,'dd'));
    perform p_excel_cell_value_write(cell_dm, p_tools_dmonth_to_smonth(rec.docdate, 1));
    perform p_excel_cell_value_write(cell_dy, to_char(rec.docdate,'yy'));
    perform p_excel_cell_value_write(cell_fd, to_char(rec.docdate,'dd'));
    perform p_excel_cell_value_write(cell_fm, p_tools_dmonth_to_smonth(rec.docdate, 1));
    perform p_excel_cell_value_write(cell_fy, to_char(rec.docdate,'yy'));
    perform p_excel_cell_value_write(cell_date, to_char(rec.docdate,'dd.mm.yyyy'));
    perform p_excel_cell_value_write(cell_org, rec.name);
    perform p_excel_cell_value_write(cell_df, rec.ELECTCOMMITTEE0);
    perform p_excel_cell_value_write(cell_dt, rec.ELECTCOMMITTEE1);
    perform p_excel_cell_value_write(cell_val, REC.VALIDTEXT);
    if REC.SPOSTSID is not null
    then
      perform p_excel_cell_value_write(cell_spost, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||REC.SPOSTSID||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    end if;
    if REC.APOSTSID is not null
    then
      perform p_excel_cell_value_write(cell_apost, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||REC.APOSTSID||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    end if;
    if EPOSTSID is not null
    then
      perform p_excel_cell_value_write(cell_epost, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||EPOSTSID||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    end if;
    if nullif(REC.SPERSON, '') is not null
    then
      perform p_excel_cell_value_write(cell_sfio, REC.SPERSON);
    end if;
    if nullif(REC.APERSON, '') is not null
    then
      perform p_excel_cell_value_write(cell_afio, REC.APERSON);
    end if;
    if EPERSONID is not null
    then
      perform p_excel_cell_value_write(cell_efio, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||EPERSONID||']}', sselect=>'name')::json) as d(name text)));
    end if;

    -- спецификация накладное
    nr := 0;
    for sp in
    (select dn.name,
	        dm.code,
       		dm.codeokei,
	   		case when wig.quantity = 0 then wig.summ else round(wig.summ/wig.quantity, 2) end as price,
       		wig.quantity,
       		wig.summ
  	   from WRITEOFF_INVOICE_GOODS WIG
  	   left join DICNOMNS		   DN on dn.id = wig.dicnomnsid
  	   left join DICMUNTS	       DM on dm.id = dn.dicmuntsid
 	  where 1=1
   		and wig.writeoff_invoice_headerid = rec.id)
    loop
      nr := nr + 1;
      idx := p_excel_line_append(line0);
      perform p_excel_cell_value_write(cell_d002, 0, idx, null);
      perform p_excel_cell_value_write(cell_d003, 0, idx, sp.code);
      perform p_excel_cell_value_write(cell_d004, 0, idx, sp.codeokei);
      perform p_excel_cell_value_write(cell_d005, 0, idx, sp.price);
      perform p_excel_cell_value_write(cell_d006, 0, idx, sp.quantity);
      perform p_excel_cell_value_write(cell_d007, 0, idx, sp.summ);
      perform p_excel_cell_value_write(cell_d008, 0, idx, null);
      perform p_excel_cell_value_write(cell_d001, 0, idx, sp.name);
    end loop;

    -- пишем формулу итога
    perform p_excel_cell_formula_write(cell_dtq, '=sum(R[-1]C:R[-'||nr::text||']C)');
    perform p_excel_cell_formula_write(cell_dts, '=sum(R[-1]C:R[-'||nr::text||']C)');

    -- проводуи
    for sp in
    (select tr.sdt, tr.skt, sum(tr.summ) as summ from(
     select p_transactionlog_stages_get_acc(ts.id,'KSC.|KOC.|ACC.|KUC.',0) as sdt,
            p_transactionlog_stages_get_acc(ts.id,'KSC.|KOC.|ACC.|KUC.',1) as skt,
            ts.summ
       from doclinks  	          dl,
            TRANSACTIONLOG_STAGES  ts
      where dl.tablein = 'WRITEOFF_INVOICE_HEADER'
        and dl.tableout = 'TRANSACTIONLOG_STAGES'
        and dl.keyin = rec.id
        and dl.keyout = ts.id) tr
    group by tr.sdt, tr.skt
    )
    loop
      idx := p_excel_line_append(line1);
	  perform p_excel_cell_value_write(cell_d101, 0, idx, sp.sdt);
	  perform p_excel_cell_value_write(cell_d102, 0, idx, sp.skt);
	  perform p_excel_cell_value_write(cell_d103, 0, idx, sp.summ);
    end loop;

    -- удаление оброзцов строк на листе
    perform p_excel_line_delete(line0);
    perform p_excel_line_delete(line1);
  end loop;

  -- удаление листа образца
  if sdocnumb is not null
  then
    perform p_excel_sheet_delete(ssheet);
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_report_intmovegoods (idlist text, epostsid bigint, epersonid bigint)
  OWNER TO magicbox;