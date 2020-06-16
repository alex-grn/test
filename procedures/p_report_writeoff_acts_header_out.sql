CREATE OR REPLACE FUNCTION public.p_report_writeoff_acts_header_out (
  idlist text,
  CHAIRMAN_POSTSID bigint,
  CHAIRMAN bigint,
  POSTSID_01 bigint,
  COMMISSION_01 bigint,
  POSTSID_02 bigint,
  COMMISSION_02 bigint,
  POSTSID_03 bigint,
  COMMISSION_03 bigint,
  POSTSID_04 bigint,
  COMMISSION_04 bigint,
  DIR_FIO bigint
)
RETURNS void AS
$body$
declare
  rec record;
  sp  record;
  nsum numeric;
  nr  integer;
  sdocnumb text;
  idx numeric;

  ssheet    constant text := 'DFT';
  cell_hdf  constant text := 'hdir_fio';
  cell_han  constant text := 'hact_numb';
  cell_had  constant text := 'hact_day';
  cell_ham  constant text := 'hact_month';
  cell_hay  constant text := 'hact_year';
  cell_had1 constant text := 'hact_day1';
  cell_ham1 constant text := 'hact_month1';
  cell_hay1 constant text := 'hact_year1';
  cell_hon  constant text := 'horg_name';
  cell_hoi  constant text := 'horg_inn';
  cell_hok  constant text := 'horg_kpp';
  cell_hmp  constant text := 'hmol_pers';

  line     constant text := 'data';
  cell_d01 constant text := 'd_01';
  cell_d02 constant text := 'd_02';
  cell_d03 constant text := 'd_03';
  cell_d04 constant text := 'd_04';
  cell_d05 constant text := 'd_05';
  cell_d06 constant text := 'd_06';
  cell_d07 constant text := 'd_07';
  cell_d08 constant text := 'd_08';
  cell_d09 constant text := 'd_09';
  cell_d10 constant text := 'd_10';

  cell_ts  constant text := 'total_sum';
  cell_ts1 constant text := 'total_sum1';
  cell_sp  constant text := 'sum_propis';

  cell_an  constant text := 'act_note';

  cell_fp01 constant text := 'fpost_01';
  cell_ff01 constant text := 'ffio_01';
  cell_fp02 constant text := 'fpost_02';
  cell_ff02 constant text := 'ffio_02';
  cell_fp03 constant text := 'fpost_03';
  cell_ff03 constant text := 'ffio_03';
  cell_fp04 constant text := 'fpost_04';
  cell_ff04 constant text := 'ffio_04';
  cell_fp05 constant text := 'fpost_05';
  cell_ff05 constant text := 'ffio_05';

  cell_fad constant text := 'fact_day';
  cell_fam constant text := 'fact_month';
  cell_fay constant text := 'fact_year';

begin

  perform p_excel_prepare();
  perform p_excel_sheet_select(ssheet);
  perform p_excel_cell_describe(cell_hdf  );
  perform p_excel_cell_describe(cell_han  );
  perform p_excel_cell_describe(cell_had  );
  perform p_excel_cell_describe(cell_ham  );
  perform p_excel_cell_describe(cell_hay  );
  perform p_excel_cell_describe(cell_had1 );
  perform p_excel_cell_describe(cell_ham1 );
  perform p_excel_cell_describe(cell_hay1 );
  perform p_excel_cell_describe(cell_hon  );
  perform p_excel_cell_describe(cell_hoi  );
  perform p_excel_cell_describe(cell_hok  );
  perform p_excel_cell_describe(cell_hmp  );

  perform p_excel_line_describe(line);
  perform p_excel_line_cell_describe(line, cell_d01);
  perform p_excel_line_cell_describe(line, cell_d02);
  perform p_excel_line_cell_describe(line, cell_d03);
  perform p_excel_line_cell_describe(line, cell_d04);
  perform p_excel_line_cell_describe(line, cell_d05);
  perform p_excel_line_cell_describe(line, cell_d06);
  perform p_excel_line_cell_describe(line, cell_d07);
  perform p_excel_line_cell_describe(line, cell_d08);
  perform p_excel_line_cell_describe(line, cell_d09);
  perform p_excel_line_cell_describe(line, cell_d10);

  perform p_excel_cell_describe(cell_ts );
  perform p_excel_cell_describe(cell_ts1);
  perform p_excel_cell_describe(cell_sp );

  perform p_excel_cell_describe(cell_an );

  perform p_excel_cell_describe(cell_fp01 );
  perform p_excel_cell_describe(cell_ff01 );
  perform p_excel_cell_describe(cell_fp02 );
  perform p_excel_cell_describe(cell_ff02 );
  perform p_excel_cell_describe(cell_fp03 );
  perform p_excel_cell_describe(cell_ff03 );
  perform p_excel_cell_describe(cell_fp04 );
  perform p_excel_cell_describe(cell_ff04 );
  perform p_excel_cell_describe(cell_fp05 );
  perform p_excel_cell_describe(cell_ff05 );

  perform p_excel_cell_describe(cell_fad );
  perform p_excel_cell_describe(cell_fam );
  perform p_excel_cell_describe(cell_fay );

  -- выборка документов
  for rec in
  (select wah.id,
          wah.docnumb,
          wah.docdate,
          ect.name as electcommittee,
          ect.inn,
          ect.kpp,
          p.name,
          wah.opinion,
          wah.reason
     from WRITEOFF_ACTS_HEADER WAH
     left join writeoff wo on wo.id = wah.writeoffid
     left join electcampaign ec on ec.id = wo.electcampaignid
     left join electcommittee ect on ect.id = ec.electcommitteeid
     left join MTRESPONSPERS mrp on mrp.id = wah.respperson
     left join person p on p.id = mrp.personid
    where 1 = 1
      and wah.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
      --and wah.status = '2' -- проведен в учете
    order by lpad(wAh.docnumb::text,20,'0')
   )
  loop

    sdocnumb := rec.docnumb::text;
    perform p_excel_sheet_copy(ssheet_name_from=>ssheet, ssheet_name_to=>sdocnumb, nmove_to_end=>1);
    perform p_excel_sheet_select(sdocnumb);

    perform p_excel_cell_value_write(cell_han , rec.docnumb::text);
    perform p_excel_cell_value_write(cell_had , to_char(rec.docdate,'dd'));
    perform p_excel_cell_value_write(cell_ham , p_tools_dmonth_to_smonth(rec.docdate, 1));
    perform p_excel_cell_value_write(cell_hay , to_char(rec.docdate,'yy'));
    perform p_excel_cell_value_write(cell_had1, to_char(rec.docdate,'dd'));
    perform p_excel_cell_value_write(cell_ham1, p_tools_dmonth_to_smonth(rec.docdate, 1));
    perform p_excel_cell_value_write(cell_hay1, to_char(rec.docdate,'yy'));
    perform p_excel_cell_value_write(cell_fad, to_char(rec.docdate,'dd'));
    perform p_excel_cell_value_write(cell_fam, p_tools_dmonth_to_smonth(rec.docdate, 1));
    perform p_excel_cell_value_write(cell_fay, to_char(rec.docdate,'yy'));
    perform p_excel_cell_value_write(cell_hon , rec.electcommittee);
    perform p_excel_cell_value_write(cell_hoi , rec.inn);
    perform p_excel_cell_value_write(cell_hok , rec.kpp);
    perform p_excel_cell_value_write(cell_hmp , rec.name);
    perform p_excel_cell_value_write(cell_an , rec.opinion);

    -- подписи
    perform p_excel_cell_value_write(cell_fp01, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||COALESCE(CHAIRMAN_POSTSID,-1)||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    perform p_excel_cell_value_write(cell_ff01, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||COALESCE(CHAIRMAN,-1)||']}', sselect=>'name')::json) as d(name text)));
    perform p_excel_cell_value_write(cell_fp02, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||COALESCE(POSTSID_01,-1)||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    perform p_excel_cell_value_write(cell_ff02, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||COALESCE(COMMISSION_01,-1)||']}', sselect=>'name')::json) as d(name text)));
    perform p_excel_cell_value_write(cell_fp03, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||COALESCE(POSTSID_02,-1)||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    perform p_excel_cell_value_write(cell_ff03, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||COALESCE(COMMISSION_02,-1)||']}', sselect=>'name')::json) as d(name text)));
    perform p_excel_cell_value_write(cell_fp04, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||COALESCE(POSTSID_03,-1)||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    perform p_excel_cell_value_write(cell_ff04, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||COALESCE(COMMISSION_03,-1)||']}', sselect=>'name')::json) as d(name text)));
    perform p_excel_cell_value_write(cell_fp05, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||COALESCE(POSTSID_04,-1)||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    perform p_excel_cell_value_write(cell_ff05, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||COALESCE(COMMISSION_04,-1)||']}', sselect=>'name')::json) as d(name text)));
    perform p_excel_cell_value_write(cell_hdf , (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||COALESCE(DIR_FIO,-1)||']}', sselect=>'name')::json) as d(name text)));

    -- спецификация накладное
    nr := 0;
    nsum := 0;
    -- проводуи
    for sp in
    (select dn.name,
            dm.code,
            wag.QUANTITY,
            round(wag.summ / case when wag.QUANTITY = 0 then 1 else wag.QUANTITY end,2) as price,
            wag.summ,
            p_transactionlog_stages_get_acc(ts.id,'KSC.|KOC.|ACC.|KUC.',0) as sdt,
            p_transactionlog_stages_get_acc(ts.id,'KSC.|KOC.|ACC.|KUC.',1) as skt
       from writeoff_acts_goods wag
       left join dicnomns dn on dn.id = wag.dicnomnsid
       left join DICMUNTS dm on dm.id = dn.dicmuntsid
       left join doclinks dl on dl.keyin = wag.id and dl.tablein = 'WRITEOFF_ACTS_GOODS' and dl.tableout = 'TRANSACTIONLOG_STAGES'
       left join TRANSACTIONLOG_STAGES ts on ts.id = dl.keyout
      where wag.writeoff_acts_headerid = rec.id
    )
    loop
      nr := nr + 1;
      nsum := nsum + sp.summ;
      idx := p_excel_line_continue(line);
	  perform p_excel_cell_value_write(cell_d01, 0, idx, sp.name);
	  --perform p_excel_cell_value_write(cell_d02, 0, idx, );
	  perform p_excel_cell_value_write(cell_d03, 0, idx, sp.code);
	  --perform p_excel_cell_value_write(cell_d04, 0, idx, sp.summ);
	  perform p_excel_cell_value_write(cell_d05, 0, idx, sp.QUANTITY);
	  perform p_excel_cell_value_write(cell_d06, 0, idx, sp.price);
	  perform p_excel_cell_value_write(cell_d07, 0, idx, sp.summ);
	  perform p_excel_cell_value_write(cell_d08, 0, idx, rec.reason);
	  perform p_excel_cell_value_write(cell_d09, 0, idx, sp.sdt);
	  perform p_excel_cell_value_write(cell_d10, 0, idx, sp.skt);
    end loop;
    -- пишем формулу итога
    perform p_excel_cell_formula_write(cell_ts, '=sum(R[-1]C:R[-'||nr::text||']C)');
    perform p_excel_cell_formula_write(cell_ts1, '=R[-2]C[24]');
    perform p_excel_cell_value_write(cell_sp, p_tools_to_propis(nsum));

    -- удаление оброзцов строк на листе
    perform p_excel_line_delete(line);
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

ALTER FUNCTION public.p_report_writeoff_acts_header_out (idlist text, CHAIRMAN_POSTSID bigint, CHAIRMAN bigint, POSTSID_01 bigint, COMMISSION_01 bigint, POSTSID_02 bigint, COMMISSION_02 bigint, POSTSID_03 bigint, COMMISSION_03 bigint, POSTSID_04 bigint, COMMISSION_04 bigint, DIR_FIO bigint)
  OWNER TO magicbox;