-- Revert crm-for-devs:0005_messages.sql from pg

BEGIN;

    set search_path to crm;

    drop view outbound_messages_with_no_response_per_contact_method;
    drop view outbound_messages_with_no_response;
    drop table messages;

COMMIT;
