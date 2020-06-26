CREATE OR REPLACE FUNCTION public.p_report_sreport_error (
  REPYEAR integer,
  REPMONTHBY text
)
RETURNS void AS
$body$
declare
	rec record;
    tlist text[];
    sdf text := 'НЕ ОПРЕДЕЛЕНО!';
    idx integer;
    nbenefitstypenamedirid bigint;
    ssh text;
    ssubjectsdir text;
    stmp text;

    ssheet   constant text := 'dft';
    cell_rnm constant text := 'report_name';
    cell_rpr constant text := 'report_period';
    cell_rpt constant text := 'report_print';
    line 	 constant text := 'data';
    cell_d01 constant text := 'dcol_01';
    cell_d02 constant text := 'dcol_02';
    cell_d03 constant text := 'dcol_03';
begin
  -- наименования листа
  tlist[-1]:= sdf;
  tlist[00]:= sdf;
  tlist[01]:= 'ежемесячное по уходу до 1,5 лет';
  tlist[02]:= 'по беременности и родам';
  tlist[03]:= 'ранние сроки беременности';
  tlist[04]:= 'при рождении ребенка';
  tlist[05]:= 'ежемесячное военнослужащим';
  tlist[06]:= 'единовременное военнослужащим';

  perform p_excel_prepare();
  perform p_excel_sheet_select(ssheet);
  perform p_excel_cell_describe(cell_rnm);
  perform p_excel_cell_describe(cell_rpr);
  perform p_excel_cell_describe(cell_rpt);
  perform p_excel_line_describe(line);
  perform p_excel_line_cell_describe(line,cell_d01);
  perform p_excel_line_cell_describe(line,cell_d02);
  perform p_excel_line_cell_describe(line,cell_d03);

  -- выборка ошибок
  for rec in
  (
   select sd.name,
          COALESCE(br.benefitstypenamedirid, -1) as benefitstypenamedirid,
          COALESCE(btd.description, sdf) as description,
          regexp_split_to_table(br.wrongloading,chr(13)) as wrongloading
     from BENEFITSPACKETS bp
     inner join BENEFICIARIESREGISTERS br on br.benefitspacketsid = bp.id --and br.wrongloading is not null
     left join subjectsdir sd on sd.id = bp.subjectsdirid
     left join BENEFITSTYPEDIR btd on btd.id = br.benefitstypenamedirid
    where bp.repyear = p_report_sreport_error.REPYEAR
      and bp.repmonth = p_report_sreport_error.REPMONTHBY
    order by COALESCE(br.benefitstypenamedirid, -1), sd.code
  )
  loop
    if nbenefitstypenamedirid is null or nbenefitstypenamedirid <> rec.benefitstypenamedirid
    then
      if nbenefitstypenamedirid is not null
      then
        perform p_excel_line_delete(line);
      end if;
      nbenefitstypenamedirid := rec.benefitstypenamedirid;
      begin
        ssh := tlist[rec.benefitstypenamedirid];
      exception
        when no_data_found then
          perform p_system_exception(0, 'Тип реестра "'||text(rec.benefitstypenamedirid)||', не определен!"');
      end;
      perform p_excel_sheet_copy(ssheet_name_from => ssheet, ssheet_name_to => ssh, nmove_to_end => 1);
      perform p_excel_sheet_select(ssh);
      ssubjectsdir := rec.name;
    else
      if stmp is null or stmp <> rec.name
      then
        ssubjectsdir := rec.name;
        stmp := ssubjectsdir;
      else
        ssubjectsdir := null;
      end if;
    end if;

    idx := p_excel_line_continue(line);

    perform p_excel_cell_value_write(cell_d01, 0, idx, ssubjectsdir);
    perform p_excel_cell_value_write(cell_d02, 0, idx, split_part(rec.wrongloading,'@',1));
    perform p_excel_cell_value_write(cell_d03, 0, idx, split_part(rec.wrongloading,'@',2));
  end loop;

  if idx is not null
  then
    perform p_excel_line_delete(line);
    perform p_excel_sheet_delete(ssheet);
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_report_sreport_error (REPYEAR integer, REPMONTHBY text) OWNER TO magicbox;