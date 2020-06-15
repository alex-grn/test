CREATE OR REPLACE FUNCTION public.p_report_transactionlog_docs_accord (
  idlist text,
  POSTSID bigint,--Исполнитель (должность)
  BPERSONID bigint,--Исполнитель (расшифровка подписи)
  BKPOSTSID bigint,--Ответственный исполнитель (должность)
  BKPERSONID bigint,--Ответ.исполнитель (расшифровка подписи)
  GBPERSONID bigint --Главный бухгалтер
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

  ssheet         constant text := 'dft';
  cell_hmn0      constant text := 'hmn0';
  cell_hy0       constant text := 'hy0';
  cell_hdate0    constant text := 'hdate0';
  cell_horg_name constant text := 'horg_name';
  cell_horg_inn  constant text := 'horg_inn';
  cell_horg_kpp  constant text := 'horg_kpp';

  line           constant text := 'data';
  cell_dcol_01   constant text := 'dcol_01';
  cell_dcol_02   constant text := 'dcol_02';
  cell_dcol_03   constant text := 'dcol_03';
  cell_dcol_04   constant text := 'dcol_04';
  cell_dcol_05   constant text := 'dcol_05';
  cell_dcol_06   constant text := 'dcol_06';
  cell_total_06  constant text := 'total_06';

  cell_epost     constant text := 'epost';
  cell_efio      constant text := 'efio';
  cell_resp_post constant text := 'resp_post';
  cell_resp_fio  constant text := 'resp_fio';
  cell_fday_0 	 constant text := 'fday_0';
  cell_fmonth_0  constant text := 'fmonth_0';
  cell_fyear_0   constant text := 'fyear_0';
  cell_fday_1 	 constant text := 'fday_1';
  cell_fmonth_1  constant text := 'fmonth_1';
  cell_fyear_1   constant text := 'fyear_1';
  cell_fday_2 	 constant text := 'fday_2';
  cell_fmonth_2  constant text := 'fmonth_2';
  cell_fyear_2   constant text := 'fyear_2';
  cell_gb_fio    constant text := 'gb_fio';
begin
  perform p_excel_prepare();
  perform p_excel_sheet_select(ssheet);
  perform p_excel_cell_describe(cell_hmn0     );
  perform p_excel_cell_describe(cell_hy0      );
  perform p_excel_cell_describe(cell_hdate0   );
  perform p_excel_cell_describe(cell_horg_name);
  perform p_excel_cell_describe(cell_horg_inn );
  perform p_excel_cell_describe(cell_horg_kpp );

  perform p_excel_line_describe(line);
  perform p_excel_line_cell_describe(line, cell_dcol_01);
  perform p_excel_line_cell_describe(line, cell_dcol_02);
  perform p_excel_line_cell_describe(line, cell_dcol_03);
  perform p_excel_line_cell_describe(line, cell_dcol_04);
  perform p_excel_line_cell_describe(line, cell_dcol_05);
  perform p_excel_line_cell_describe(line, cell_dcol_06);
  perform p_excel_cell_describe(cell_total_06);

  perform p_excel_cell_describe(cell_epost      );
  perform p_excel_cell_describe(cell_efio       );
  perform p_excel_cell_describe(cell_resp_post  );
  perform p_excel_cell_describe(cell_resp_fio   );
  perform p_excel_cell_describe(cell_fday_0 	  );
  perform p_excel_cell_describe(cell_fmonth_0   );
  perform p_excel_cell_describe(cell_fyear_0    );
  perform p_excel_cell_describe(cell_fday_1 	  );
  perform p_excel_cell_describe(cell_fmonth_1   );
  perform p_excel_cell_describe(cell_fyear_1    );
  perform p_excel_cell_describe(cell_fday_2 	  );
  perform p_excel_cell_describe(cell_fmonth_2   );
  perform p_excel_cell_describe(cell_fyear_2    );
  perform p_excel_cell_describe(cell_gb_fio     );

  -- выборка документов
  for rec in
  (select TLD.ID,
          TLD.TRANSACTIONDATE,
          ECM.NAME as ELECTCOMMITTEE,
          ECM.INN,
          ECM.KPP,
          TLD.TPONAME,
          TLD.DOCNUMB,
          TLD.DOCDATE,
          TLD.transactionnumb
     from TRANSACTIONLOG_DOCS TLD
     left join TRANSACTIONLOG TL on TL.ID = TLD.TRANSACTIONLOGID
     left join ELECTCAMPAIGN EC on EC.ID = TL.ELECTCAMPAIGNID
     left join ELECTCOMMITTEE ECM on ECM.ID = EC.ELECTCOMMITTEEID
    where 1 = 1
      and TLD.ID = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
    order by TLD.transactionnumb
   )
  loop
    sdocnumb := rec.transactionnumb;

    perform p_excel_sheet_copy(ssheet_name_from=>ssheet, ssheet_name_to=>rec.transactionnumb, nmove_to_end=>1);
    perform p_excel_sheet_select(rec.transactionnumb);

    perform p_excel_cell_value_write(cell_hmn0, to_char(rec.TRANSACTIONDATE, 'dd')||' '||p_tools_dmonth_to_smonth(rec.TRANSACTIONDATE, 1));
    perform p_excel_cell_value_write(cell_hy0, to_char(rec.TRANSACTIONDATE, 'yy'));
    perform p_excel_cell_value_write(cell_hdate0, to_char(rec.TRANSACTIONDATE, 'dd.mm.yyyy'));
    perform p_excel_cell_value_write(cell_horg_name, rec.ELECTCOMMITTEE);
    perform p_excel_cell_value_write(cell_horg_inn, rec.inn);
    perform p_excel_cell_value_write(cell_horg_kpp, rec.kpp);

    perform p_excel_cell_value_write(cell_fday_0, to_char(rec.TRANSACTIONDATE, 'dd'));
    perform p_excel_cell_value_write(cell_fmonth_0, p_tools_dmonth_to_smonth(rec.TRANSACTIONDATE, 1));
    perform p_excel_cell_value_write(cell_fyear_0, to_char(rec.TRANSACTIONDATE,'yy'));
    perform p_excel_cell_value_write(cell_fday_1, to_char(rec.TRANSACTIONDATE, 'dd'));
    perform p_excel_cell_value_write(cell_fmonth_1, p_tools_dmonth_to_smonth(rec.TRANSACTIONDATE, 1));
    perform p_excel_cell_value_write(cell_fyear_1, to_char(rec.TRANSACTIONDATE,'yy'));
    perform p_excel_cell_value_write(cell_fday_2, to_char(rec.TRANSACTIONDATE, 'dd'));
    perform p_excel_cell_value_write(cell_fmonth_2, p_tools_dmonth_to_smonth(rec.TRANSACTIONDATE, 1));
    perform p_excel_cell_value_write(cell_fyear_2, to_char(rec.TRANSACTIONDATE,'yy'));

	if POSTSID is not null
    then
      perform p_excel_cell_value_write(cell_epost, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||POSTSID::text||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    end if;
    if BKPOSTSID is not null
    then
      perform p_excel_cell_value_write(cell_resp_post, (SELECT COALESCE(POSTPRINT_RET, NAME) FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'posts', sCOND_LIKE=>'{"id":['||BKPOSTSID||']}', sselect=>'POSTPRINT_RET, NAME')::json) as d(POSTPRINT_RET text, NAME text)));
    end if;

    if BPERSONID is not null
    then
      perform p_excel_cell_value_write(cell_efio, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||BPERSONID||']}', sselect=>'name')::json) as d(name text)));
    end if;
    if BKPERSONID is not null
    then
      perform p_excel_cell_value_write(cell_resp_fio, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||BKPERSONID||']}', sselect=>'name')::json) as d(name text)));
    end if;
    if GBPERSONID is not null
    then
      perform p_excel_cell_value_write(cell_gb_fio, (SELECT * FROM json_to_recordset(P_SYSTEM_GET_DATA_TABLE(stablename=>'person', sCOND_LIKE=>'{"id":['||GBPERSONID||']}', sselect=>'name')::json) as d(name text)));
    end if;

    -- спецификация накладное
    -- проводуи
    nr := 0;
    for sp in
    (select tr.sdt, tr.skt, sum(tr.summ) as summ from(
     select p_transactionlog_stages_get_acc(ts.id,'KSC.|KOC.|ACC.|KUC.',0) as sdt,
            p_transactionlog_stages_get_acc(ts.id,'KSC.|KOC.|ACC.|KUC.',1) as skt,
            ts.summ
       from TRANSACTIONLOG_STAGES  ts
      where ts.transactionlog_docsid = rec.id) tr
    group by tr.sdt, tr.skt
    )
    loop
      nr := nr + 1;
      idx := p_excel_line_continue(line);
	  perform p_excel_cell_value_write(cell_dcol_01, 0, idx, rec.TPONAME);
	  perform p_excel_cell_value_write(cell_dcol_02, 0, idx, rec.DOCNUMB);
	  perform p_excel_cell_value_write(cell_dcol_03, 0, idx, to_char(rec.DOCDATE,'dd.mm.yyyy'));
	  perform p_excel_cell_value_write(cell_dcol_04, 0, idx, sp.sdt);
	  perform p_excel_cell_value_write(cell_dcol_05, 0, idx, sp.skt);
	  perform p_excel_cell_value_write(cell_dcol_06, 0, idx, sp.summ);
    end loop;
    -- пишем формулу итога
    perform p_excel_cell_formula_write(cell_total_06, '=sum(R[-1]C:R[-'||nr::text||']C)');

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

ALTER FUNCTION public.p_report_transactionlog_docs_accord (idlist text, POSTSID bigint, BPERSONID bigint, BKPOSTSID bigint, BKPERSONID bigint, GBPERSONID bigint)
  OWNER TO magicbox;