CREATE OR REPLACE FUNCTION public.p_report_budget_exp (
  idlist text,
  stype_be text
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

  ssheet   constant text := 'DFT';
  cell_d   constant text := 'decision';
  cell_et  constant text := 'el_type';
  cell_enb constant text := 'el_numb';  --1
  cell_lu  constant text := 'lw_uik';   --2
  cell_enm constant text := 'el_name';  --2
  cell_eft constant text := 'el_fd_type';

  line	   constant text := 'data';
  cell_nr  constant text := 'num_row';
  cell_ne  constant text := 'name_exp';
  cell_sf  constant text := 'sumfin';
  cell_tsf constant text := 'tsumfin';

begin
  perform p_excel_prepare();
  perform p_excel_sheet_select(ssheet);
  perform p_excel_cell_describe(cell_d  );
  perform p_excel_cell_describe(cell_et );
  if stype_be = 'UIK'
  then
    perform p_excel_cell_describe(cell_enb);
  end if;
  if stype_be = 'TIK_UIK'
  then
    perform p_excel_cell_describe(cell_lu );
    perform p_excel_cell_describe(cell_enm);
  elsif stype_be = 'TIK'
  then
    perform p_excel_cell_describe(cell_enm);
  end if;
  perform p_excel_cell_describe(cell_eft);

  perform p_excel_line_describe(line);
  perform p_excel_line_cell_describe(line, cell_nr);
  perform p_excel_line_cell_describe(line, cell_ne);
  perform p_excel_line_cell_describe(line, cell_sf);

  perform p_excel_cell_describe(cell_tsf);

  -- выборка документов
  for rec in
  (select ecmc.id,
          ec1.rnameec as ecme_parent,
          (SELECT LEVELELCAMPAIGN_RET
             FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'ELECTCAMPAIGN',
                                                          sCOND_LIKE=>'{"id":['||eca.ID||']}',
                                                          sselect=>'LEVELELCAMPAIGN_RET')::json) as d(LEVELELCAMPAIGN_RET text)) as LEVELELCAMPAIGN_RET,
          COALESCE(ec.ELECDISTNUMB::text, ecmc.id::text) as ELECDISTNUMB,
          ec.rnameec as ecme_curent,
          ec.name,
          eca.name as electcampaign
     from ELECTCOMMINCAMP ecmc
     left join ELECTCAMPAIGN eca on eca.id = ecmc.electcampaignid
     left join ELECTCOMMITTEE ec on ec.id = ecmc.electcommitteeid
     left join ELECTCOMMITTEE ec1 on ec1.idgasecom = ec.idgasparecom
    where 1=1
      and ecmc.id = any(P_SYSTEM_GET_SELECTLIST(IDLIST))
    order by COALESCE(ec.ELECDISTNUMB::text, ecmc.id::text)
   )
  loop
    sdocnumb := rec.ELECDISTNUMB::text;
    perform p_excel_sheet_copy(ssheet_name_from=>ssheet, ssheet_name_to=>sdocnumb, nmove_to_end=>1);
    perform p_excel_sheet_select(sdocnumb);

    if stype_be = 'UIK'
    then
      perform p_excel_cell_value_write(cell_d  , rec.ecme_parent);
    else
      perform p_excel_cell_value_write(cell_d  , rec.ecme_curent);
    end if;

    if lower(rec.LEVELELCAMPAIGN_RET) like '%едеральн%'
    then
      perform p_excel_cell_value_write(cell_et , 'федеральных');
    elsif lower(rec.LEVELELCAMPAIGN_RET) like '%егиональн%'
    then
      perform p_excel_cell_value_write(cell_et , 'региональных');
    else
      perform p_excel_cell_value_write(cell_et , 'ПУСТО!');
    end if;

    if stype_be = 'UIK'
    then
      perform p_excel_cell_value_write(cell_enb, rec.ELECDISTNUMB);
    end if;
    if stype_be = 'TIK_UIK'
    then
      perform p_excel_cell_value_write(cell_lu , 'за нижестоящие избирательные комиссии (комиссии референдума)');
      perform p_excel_cell_value_write(cell_enm, rec.name);
    elsif stype_be = 'TIK'
    then
      perform p_excel_cell_value_write(cell_enm, rec.name);
    end if;
    perform p_excel_cell_value_write(cell_eft, rec.electcampaign);

    -- спецификация накладное
    nr := 0;
    for sp in
    (select TE.NUMBESTIMATE,
	        (SELECT TYPEEXPID_RET
               FROM json_to_recordset (P_SYSTEM_GET_DATA_TABLE(stablename=>'FINANCEELCOM',
                                                               sCOND_LIKE=>'{"id":['||fc.ID||']}',
                                                               sselect=>'TYPEEXPID_RET')::json) as d(TYPEEXPID_RET text)) as TYPEEXPID_RET,
            fc.SUMFINUIK,
       		fc.SUMFINTIK,
       		fc.SUMFINTIKCEN
       from FINANCEELCOM FC
      inner join TYPEEXP TE on TE.ID = FC.typeexpid and ((stype_be = 'UIK' and not te.mestimate) or (not te.MESTIMATETIK))
      where fc.electcommincampid = rec.id
      order by TE.numbpp
   )
    loop
      nr := nr + 1;
      idx := p_excel_line_continue(line);
      perform p_excel_cell_value_write(cell_nr, 0, idx, sp.NUMBESTIMATE);
      perform p_excel_cell_value_write(cell_ne, 0, idx, sp.TYPEEXPID_RET);
      if stype_be = 'UIK'
      then
        perform p_excel_cell_value_write(cell_sf, 0, idx, sp.SUMFINUIK);
      elsif stype_be = 'TIK'
      then
        perform p_excel_cell_value_write(cell_sf, 0, idx, sp.SUMFINTIK);
      elsif stype_be = 'TIK_UIK'
      then
        perform p_excel_cell_value_write(cell_sf, 0, idx, sp.SUMFINTIKCEN);
      end if;
    end loop;

    -- пишем формулу итога
    --if nr <> 0 then
      --perform p_excel_cell_formula_write(cell_tsf, '=sum(R[-1]C:R[-'||nr::text||']C)');
    --end if;
    --perform p_excel_cell_formula_write(cell_tsf, '=sum(R[-1]C:R[-'||nr::text||']C)');
    if stype_be = 'UIK'
    then
      perform p_excel_cell_value_write(cell_tsf, (select round(sum(COALESCE(f.SUMFINUIK,0)),2)
                                                    from financeelcom f
                                                   where f.electcommincampid = rec.id
                                                     and not exists(select 1 from TYPEEXP t where t.ID = f.TYPEEXPID and t.NUMBESTIMATE  like '%.%')));
    elsif stype_be = 'TIK_UIK'
    then
      perform p_excel_cell_value_write(cell_tsf , (select round(sum(COALESCE(f.SUMFINTIKCEN,0)),2)
                                                    from financeelcom f
      											   where f.electcommincampid = rec.id
                                                     and not exists(select 1 from TYPEEXP t where t.ID = f.TYPEEXPID and t.NUMBESTIMATE  like '%.%')));
    elsif stype_be = 'TIK'
    then
      perform p_excel_cell_value_write(cell_tsf, (select round(sum(COALESCE(f.SUMFINTIK,0)),2)
                                                    from financeelcom f
                                                   where f.electcommincampid = rec.id
                                                     and not exists(select 1 from TYPEEXP t where t.ID = f.TYPEEXPID and t.NUMBESTIMATE  like '%.%')));
    end if;


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

ALTER FUNCTION public.p_report_budget_exp (idlist text, stype_be text)
  OWNER TO magicbox;