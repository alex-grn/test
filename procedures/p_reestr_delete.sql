CREATE OR REPLACE FUNCTION public.p_reestr_delete (
  idlist text
)
RETURNS text AS
$body$
/* Процедура удаления реестров */
declare
   rec record;
   ben record;
begin

   for rec in 
      select b.id
        from BENEFICIARIESREGISTERS b
       where b.id = ANY(p_system_get_selectlist(idlist))
   loop
    --удаляем benefit01
    for ben in
       select b.id
         from BENEFIT01 b
        where b.BENEFITSTYPEDIRID = rec.id
    loop
        delete from BENEFIT01BASIS s where s.BENEFIT01ID = ben.id;
        delete from BENEFIT01PURPOSE s where s.BENEFIT01ID = ben.id;
        delete from BENEFIT01PAYMENT s where s.BENEFIT01ID = ben.id; 
        delete from CHILD s where s.BENEFIT01ID = ben.id;
        delete from BENEFIT01 s where s.id = ben.id;
    end loop;
    --удаляем benefit02
    for ben in
       select b.id
         from BENEFIT02 b
        where b.BENEFITSTYPEDIRID = rec.id
    loop
        delete from BENEFIT02BASIS s where s.BENEFIT02ID = ben.id;
        delete from BENEFIT02PURPOSE s where s.BENEFIT02ID = ben.id;
        delete from BENEFIT02PAYMENT s where s.BENEFIT02ID = ben.id;
        delete from BENEFIT02 s where s.id = ben.id;
    end loop;
    --удаляем benefit03
    for ben in
       select b.id
         from BENEFIT03 b
        where b.BENEFITSTYPEDIRID = rec.id
    loop
        delete from BENEFIT03BASIS s where s.BENEFIT03ID = ben.id;
        delete from BENEFIT03PURPOSE s where s.BENEFIT03ID = ben.id;
        delete from BENEFIT03PAYMENT s where s.BENEFIT03ID = ben.id; 
        delete from BENEFIT03 s where s.id = ben.id;
    end loop;
    --удаляем benefit04
    for ben in
       select b.id
         from BENEFIT04 b
        where b.BENEFITSTYPEDIRID = rec.id
    loop
        delete from BENEFIT04BASIS s where s.BENEFIT04ID = ben.id;
        delete from BENEFIT04PURPOSE s where s.BENEFIT04ID = ben.id;
        delete from BENEFIT04PAYMENT s where s.BENEFIT04ID = ben.id; 
        delete from CHILD04 s where s.BENEFIT04ID = ben.id;
        delete from BENEFIT04 s where s.id = ben.id;
    end loop;
    --удаляем benefit05
    for ben in
       select b.id
         from BENEFIT05 b
        where b.BENEFITSTYPEDIRID = rec.id
    loop
        delete from BENEFIT05BASIS s where s.BENEFIT05ID = ben.id;
        delete from BENEFIT05PURPOSE s where s.BENEFIT05ID = ben.id;
        delete from BENEFIT05PAYMENT s where s.BENEFIT05ID = ben.id; 
        delete from CHILD05 s where s.BENEFIT05ID = ben.id;
        delete from BENEFIT05 s where s.id = ben.id;
    end loop;
    --удаляем benefit06
    for ben in
       select b.id
         from BENEFIT06 b
        where b.BENEFITSTYPEDIRID = rec.id
    loop
        delete from BENEFIT06BASIS s where s.BENEFIT06ID = ben.id;
        delete from BENEFIT06PURPOSE s where s.BENEFIT06ID = ben.id;
        delete from BENEFIT06PAYMENT s where s.BENEFIT06ID = ben.id; 
        delete from BENEFIT06 s where s.id = ben.id;
    end loop;
    --удаляем benefit07
    for ben in
       select b.id
         from BENEFIT07 b
        where b.BENEFITSTYPEDIRID = rec.id
    loop
        delete from FAMILYMEMBERS s where s.BENEFIT07ID = ben.id;
        delete from BENEFIT07PURPOSE s where s.BENEFIT07ID = ben.id;
        delete from BENEFIT07PAYMENT s where s.BENEFIT07ID = ben.id; 
        delete from CHILD07 s where s.BENEFIT07ID = ben.id;
        delete from BENEFIT07 s where s.id = ben.id;
    end loop;
    
    delete from BENEFICIARIESREGISTERS s where s.id = rec.id;
   end loop;
   
   RETURN 'Удаление реестра выполнено!';
   
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.p_reestr_delete (idlist text)
  OWNER TO magicbox;