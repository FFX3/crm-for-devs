-- Verify crm-for-devs:0004_contact_sources on pg

BEGIN;

    set search_path to crm;

    select source_id from contacts;
    select id, name, description from sources;

ROLLBACK;
