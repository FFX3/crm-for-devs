-- Deploy crm-for-devs:0004_contact_sources to pg
-- requires: 0001_contacts

BEGIN;

    set search_path to crm;

    create table sources (
        id serial primary key,
        name text not null,
        description text not null
    );

    alter table contacts add column source_id int not null references sources (id);

    grant all on sources to authenticated;
    alter table sources enable row level security;
    create policy "Open to authenticated" on sources
    for all
    to authenticated
    using(true)
    with check(true);

COMMIT;
