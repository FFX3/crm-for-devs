-- Revert crm-for-devs:0001_contacts from pg

BEGIN;

    set search_path to crm;

    drop table contacts;

    drop type contact_status;

    drop schema crm;

COMMIT;
