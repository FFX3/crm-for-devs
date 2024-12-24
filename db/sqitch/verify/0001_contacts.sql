-- Verify crm-for-devs:0001_contacts on pg

BEGIN;

    set search_path to crm;

    select
        name,
        notes,
        status
    from contacts
    where false;


ROLLBACK;
