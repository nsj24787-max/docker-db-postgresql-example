do $$
begin
    if not exists (select from pg_roles where rolname = 'gaon') then
        create role gaon login password 'gaon';
    end if;
end
$$;

do $$
begin
    if not exists (select from pg_roles where rolname = 'mes21') then
        create role mes21 login password 'mes7033';
    end if;
end
$$;

alter schema public owner to mes21;

grant usage, create on schema public to mes21;
grant usage on schema public to gaon;

grant connect on database hgf_mes to mes21;
grant connect on database hgf_mes to gaon;

grant select, insert, update, delete on all tables in schema public to mes21;
grant usage, select on all sequences in schema public to mes21;

alter default privileges in schema public grant select, insert, update, delete on tables to mes21;
alter default privileges in schema public grant usage, select on sequences to mes21;