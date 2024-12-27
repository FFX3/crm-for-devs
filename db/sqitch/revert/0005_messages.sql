-- Revert crm-for-devs:0005_messages.sql from pg

BEGIN;

    set search_path to crm;

    drop trigger prevent_inserts_trigger on type_no_response_count_per_contact;
    drop trigger prevent_inserts_trigger on type_no_response_count_per_contact_method;

    drop function prevent_inserts;

    drop function no_response_count_per_contact;
    drop table type_no_response_count_per_contact;

    drop function no_response_count_per_contact_method;
    drop table type_no_response_count_per_contact_method;

    drop table messages;

COMMIT;
