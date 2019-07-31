CREATE OR REPLACE FUNCTION p_load_kbk(s_code text, s_name text, d_begindate date DEFAULT NULL::date) RETURNS void AS
$body$
DECLARE 
--разноска субкодов КБК по справочникам KBK10IN...KBK80IN
--при отсутствии - создание нового субкода
--по заполнении справочников - заненение КБК в KbkIn   
nKBK10Id bigint; -- 123
nKBK20Id bigint; --
nKBK30Id bigint; 
nKBK40Id bigint; 
nKBK50Id bigint; 
nKBK60Id bigint; 
nKBK70Id bigint; 
nKBK80Id bigint; 
scode text;
dbegindate date;

BEGIN
select coalesce(d_begindate, to_date('01.01.'||date_part('year',now()),'dd.mm.yyyy' ) ) into dbegindate;

--1-3
select substring(s_code,1,3) into scode;
  SELECT
	 t.id 
    INTO nKBK10Id
    FROM KBK10IN t
   WHERE t.CODE = scode; 
      if nKBK10Id is null then
 	 insert into KBK10IN(CODE,NAME) VALUES (scode,scode);
	 select id into nKBK10Id from KBK10IN where code = scode;
  end if; 
--4
select substring(s_code,4,1) into scode;
  SELECT
	 t.id 
    INTO nKBK20Id
    FROM KBK20IN t
   WHERE t.CODE = scode; 
      if nKBK20Id is null then
	 insert into KBK20IN(CODE,NAME) VALUES (scode,scode);
	 select id into nKBK20Id from KBK20IN where code = scode;
  end if; 
--5-6
select substring(s_code,5,2) into scode;
  SELECT
	 t.id 
    INTO nKBK30Id
    FROM KBK30IN t
   WHERE t.CODE = scode; 
      if nKBK30Id is null then
	     insert into KBK30IN(CODE,NAME) VALUES (scode,scode);
	     select id into nKBK30Id from KBK30IN where code = scode;
  end if; 
--7-8
select substring(s_code,7,2) into scode;
  SELECT
	 t.id 
    INTO nKBK40Id
    FROM KBK40IN t
   WHERE t.CODE = scode; 
      if nKBK40Id is null then
	     insert into KBK40IN(CODE,NAME) VALUES (scode,scode);
	     select id into nKBK40Id from KBK40IN where code = scode;
  end if; 
--9-11
select substring(s_code,9,3) into scode;
  SELECT
	 t.id 
    INTO nKBK50Id
    FROM KBK50IN t
   WHERE t.CODE = scode; 
      if nKBK50Id is null then
	     insert into KBK50IN(CODE,NAME) VALUES (scode,scode);
	     select id into nKBK50Id from KBK50IN where code = scode;
  end if; 
--12-13
select substring(s_code,12,2) into scode;
  SELECT
	 t.id 
    INTO nKBK60Id
    FROM KBK60IN t
   WHERE t.CODE = scode; 
      if nKBK60Id is null then
	     insert into KBK60IN(CODE,NAME) VALUES (scode,scode);
	     select id into nKBK60Id from KBK60IN where code = scode;
  end if; 
--14-17 
select substring(s_code,14,4) into scode;
  SELECT
	 t.id 
    INTO nKBK70Id
    FROM KBK70IN t
   WHERE t.CODE = scode; 
      if nKBK70Id is null then
	     insert into KBK70IN(CODE,NAME) VALUES (scode,scode);
	     select id into nKBK70Id from KBK70IN where code = scode;
  end if; 
--18-20	
select substring(s_code,18,20) into scode;
  SELECT
	 t.id 
    INTO nKBK80Id
    FROM KBK80IN t
   WHERE t.CODE = scode; 
      if nKBK80Id is null then
	     insert into KBK80IN(CODE,NAME) VALUES (scode,scode);
	     select id into nKBK80Id from KBK80IN where code = scode;
  end if; 

begin
-- неуникальные пропускаем
INSERT INTO public.kbkin
(
  begindate,
  kbk10in ,
  kbk20in ,
  kbk30in ,
  kbk40in ,
  kbk50in ,
  kbk60in ,
  kbk70in ,
  kbk80in ,
  name  
)
values
(
  dbegindate,
  nKBK10Id ,
  nKBK20Id , 
  nKBK30Id ,
  nKBK40Id ,
  nKBK50Id ,
  nKBK60Id ,
  nKBK70Id ,
  nKBK80Id ,
  s_name
);
EXCEPTION WHEN OTHERS THEN NULL; END ; 

END ; 
$body$
language plpgsql volatile;
