-- Deploy crm-for-devs:0003_pipelines to pg
-- requires: 0001_contacts

BEGIN;

    set search_path to crm;

    create table pipelines (
        id serial primary key,
        name text not null,
        description text not null
    );

    alter table contacts add column pipeline_id int not null references pipelines (id);

    grant all on pipelines to authenticated;
    alter table pipelines enable row level security;
    create policy "Open to authenticated" on pipelines
    for all
    to authenticated
    using(true)
    with check(true);

COMMIT;
