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

COMMIT;
