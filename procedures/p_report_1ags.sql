CREATE OR REPLACE FUNCTION public.p_report_1ags (
  dateofrequest text,
  clear boolean,
  yearconscription text,
  ident bigint
)
RETURNS void AS
$body$
declare 
  nident            bigint := ident;
  nyear             INTEGER:=yearconscription::integer;
  fed               record;
  reg               record;
  nreg_all          integer;
  in_org_all        integer;
  out_org           integer;
  in_org            integer;
  fire_ags          integer;
  timeout           integer;
  health            integer;
  family_drama      integer;
  others            integer;
  ends              integer;
  nrows             integer:=0;
begin
/*
CREATE TABLE public.report_1ags (
  ident BIGINT,
  fnames TEXT,
  names TEXT,
  reg_all INTEGER,
  in_org_all INTEGER,
  out_org INTEGER,
  in_org INTEGER,
  fire_ags INTEGER,
  timeout INTEGER,
  health INTEGER,
  family_drama INTEGER,
  others INTEGER,
  ends INTEGER,
  sort INTEGER
) 
WITH (oids = false);

ALTER TABLE public.report_1ags
  ALTER COLUMN names SET STATISTICS 0;
*/


  if CLEAR
  then
    -- чистка
    delete from report_1ags a where a.ident = NIDENT;
  --raise using message = NIDENT;
  else 
      for fed IN(
          select r.districtfederal,max(r.id) as regid,p_find_name_from_list('regiondir','districtfederal',r.districtfederal) as name_fed,
                 max(case r.districtfederal::integer
                    when 3 then 2
                    when 2 then 3
                    else r.districtfederal::integer
                  end) as sort
            from regiondir r
           where r.districtfederal::integer != 9
           group by r.districtfederal,p_find_name_from_list('regiondir','districtfederal',r.districtfederal)
           order by sort
      )    
      LOOP
        nrows:=nrows+1;
        --найдем всех граждан в периоде из параметров, 
        -- со статусом "зарегистрирован"
        select count(s.id) into nreg_all 
          from citizenry s, regiondir r 
         where r.id = s.regiondirid and r.districtfederal = fed.districtfederal and s.conscription = dateofrequest and s.yearconscription = nyear and s.statuscitizen = '1';
        -- в организации всего
        select count(s.id) into in_org_all 
          from citizenry s, regiondir r, DIRECTION p 
         where r.id = s.regiondirid and r.districtfederal = fed.districtfederal and s.conscription = dateofrequest and s.yearconscription = nyear and p.citizenryid = s.id;
        -- в другом местоположении
        select count(s.id) 
          into out_org 
        from citizenry s, 
             regiondir r,
             DIRECTION p,
             ORGANIZATION o,
             ORGANIZATIONDIR org
        where r.id = s.regiondirid
          and r.districtfederal = fed.districtfederal 
          and s.conscription = dateofrequest 
          and s.yearconscription = nyear 
          and p.citizenryid = s.id 
          and o.id = p.organizationid
          and org.id = o.organizationdirid
          and org.regiondirid != s.regiondirid;
        -- в своем местоположении
        select count(s.id)
          into in_org 
        from citizenry s,  
             regiondir r,
             DIRECTION p,
             ORGANIZATION o,
             ORGANIZATIONDIR org
        where r.id = s.regiondirid
          and r.districtfederal = fed.districtfederal
          and s.conscription = dateofrequest 
          and s.yearconscription = nyear 
          and p.citizenryid = s.id 
          and o.id = p.organizationid
          and org.id = o.organizationdirid
          and org.regiondirid = s.regiondirid;
        -- все уволенные
        select count(s.id)
          into fire_ags
          from citizenry s, 
               regiondir r,
               PASSAGEAGSCIT p
         where r.id = s.regiondirid
          and r.districtfederal = fed.districtfederal 
           and s.conscription = dateofrequest 
           and s.yearconscription = nyear 
           and p.citizenryid = s.id 
           and p.DATEOFDISMISSLA is not null
         limit 1;
        -- уволенный по истечении срока альтернативной гражданской службы
        select count(s.id)
          into timeout
          from citizenry s, 
               regiondir r,
               PASSAGEAGSCIT p
         where r.id = s.regiondirid
          and r.districtfederal = fed.districtfederal
           and s.conscription = dateofrequest 
           and s.yearconscription = nyear 
           and p.citizenryid = s.id 
           and p.DATEOFDISMISSLA is not null
           and p.basis4 = '1'
         limit 1;
        -- уволенный по состоянию здоровья
        select count(s.id)
          into health
          from citizenry s, 
               regiondir r,
               PASSAGEAGSCIT p
         where r.id = s.regiondirid
          and r.districtfederal = fed.districtfederal 
           and s.conscription = dateofrequest 
           and s.yearconscription = nyear 
           and p.citizenryid = s.id 
           and p.DATEOFDISMISSLA is not null
           and p.basis4 = '2'
         limit 1;
        -- уволенный по семейным обстоятельствам
        select count(s.id)
          into family_drama
          from citizenry s, 
               regiondir r,
               PASSAGEAGSCIT p
         where r.id = s.regiondirid
          and r.districtfederal = fed.districtfederal 
           and s.conscription = dateofrequest 
           and s.yearconscription = nyear 
           and p.citizenryid = s.id 
           and p.DATEOFDISMISSLA is not null
           and p.basis4 = '5'
         limit 1;
        -- уволенный по иным обстоятельствам
        select count(s.id)
          into others
          from citizenry s, 
               regiondir r,
               PASSAGEAGSCIT p
         where r.id = s.regiondirid
          and r.districtfederal = fed.districtfederal
           and s.conscription = dateofrequest 
           and s.yearconscription = nyear 
           and p.citizenryid = s.id 
           and p.DATEOFDISMISSLA is not null
           and p.basis4 = '6'
         limit 1;
         ends:=nreg_all+in_org_all-fire_ags;
        insert into report_1ags
        values(nident,fed.name_fed,null,nreg_all,in_org_all,out_org,in_org,fire_ags,timeout,health,family_drama,others,ends,nrows);
        
        for reg in (
            select r.districtfederal,max(r.id) as regid,name as name_reg
            from regiondir r
           where r.districtfederal = fed.districtfederal
           group by r.districtfederal, r.name
           order by r.name
        )
        LOOP
          nrows:=nrows+1;  
          select count(s.id) into nreg_all 
            from citizenry s, regiondir r 
            where r.id = s.regiondirid and r.name = reg.name_reg and s.conscription = dateofrequest and s.yearconscription = nyear and s.statuscitizen = '1';
           -- в организации всего
           select count(s.id) into in_org_all 
             from citizenry s, regiondir r, DIRECTION p 
            where r.id = s.regiondirid and r.name = reg.name_reg and s.conscription = dateofrequest and s.yearconscription = nyear and p.citizenryid = s.id;
           -- в другом местоположении
           select count(s.id) 
             into out_org 
           from citizenry s, 
                regiondir r,
                DIRECTION p,
                ORGANIZATION o,
                ORGANIZATIONDIR org
           where r.id = s.regiondirid
             and r.name = reg.name_reg 
             and s.conscription = dateofrequest 
             and s.yearconscription = nyear 
             and p.citizenryid = s.id 
             and o.id = p.organizationid
             and org.id = o.organizationdirid
             and org.regiondirid != s.regiondirid;
           -- в своем местоположении
           select count(s.id)
             into in_org 
           from citizenry s,  
                regiondir r,
                DIRECTION p,
                ORGANIZATION o,
                ORGANIZATIONDIR org
           where r.id = s.regiondirid
             and r.name = reg.name_reg
             and s.conscription = dateofrequest 
             and s.yearconscription = nyear 
             and p.citizenryid = s.id 
             and o.id = p.organizationid
             and org.id = o.organizationdirid
             and org.regiondirid = s.regiondirid;
              -- все уволенные
           select count(s.id)
             into fire_ags
             from citizenry s, 
                  regiondir r,
                  PASSAGEAGSCIT p
            where r.id = s.regiondirid
              and r.name = reg.name_reg
              and s.conscription = dateofrequest 
              and s.yearconscription = nyear 
              and p.citizenryid = s.id 
              and p.DATEOFDISMISSLA is not null
            limit 1;
           -- уволенный по истечении срока альтернативной гражданской службы
           select count(s.id)
             into timeout
             from citizenry s, 
                  regiondir r,
                  PASSAGEAGSCIT p
            where r.id = s.regiondirid
              and r.name = reg.name_reg
              and s.conscription = dateofrequest 
              and s.yearconscription = nyear 
              and p.citizenryid = s.id 
              and p.DATEOFDISMISSLA is not null
              and p.basis4 = '1'
            limit 1;
           -- уволенный по состоянию здоровья
           select count(s.id)
             into health
             from citizenry s, 
                  regiondir r,
                  PASSAGEAGSCIT p
            where r.id = s.regiondirid
              and r.name = reg.name_reg
              and s.conscription = dateofrequest 
              and s.yearconscription = nyear 
              and p.citizenryid = s.id 
              and p.DATEOFDISMISSLA is not null
              and p.basis4 = '2'
            limit 1;
           -- уволенный по семейным обстоятельствам
           select count(s.id)
             into family_drama
             from citizenry s, 
                  regiondir r,
                  PASSAGEAGSCIT p
            where r.id = s.regiondirid
              and r.name = reg.name_reg 
              and s.conscription = dateofrequest 
              and s.yearconscription = nyear 
              and p.citizenryid = s.id 
              and p.DATEOFDISMISSLA is not null
              and p.basis4 = '5'
            limit 1;
           -- уволенный по иным обстоятельствам
           select count(s.id)
             into others
             from citizenry s, 
                  regiondir r,
                  PASSAGEAGSCIT p
            where r.id = s.regiondirid
              and r.name = reg.name_reg
              and s.conscription = dateofrequest 
              and s.yearconscription = nyear 
              and p.citizenryid = s.id 
              and p.DATEOFDISMISSLA is not null
              and p.basis4 = '6'
            limit 1;
            ends:=nreg_all+in_org_all-fire_ags;
           insert into report_1ags
           values(nident,fed.name_fed,reg.name_reg,nreg_all,in_org_all,out_org,in_org,fire_ags,timeout,health,family_drama,others,ends,nrows);
        end loop;
        
        
      end loop;
  
  end if;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_report_1ags (dateofrequest text, clear boolean, yearconscription text, ident bigint)
  OWNER TO magicbox;