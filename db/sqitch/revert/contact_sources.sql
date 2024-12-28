-- Revert crm-for-devs:0004_contact_sources from pg

BEGIN;

    set search_path to crm;

    alter table contacts drop column source_id;
    drop table sources;

COMMIT;
