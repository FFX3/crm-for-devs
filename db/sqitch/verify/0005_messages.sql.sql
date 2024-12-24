-- Verify crm-for-devs:0005_messages.sql on pg

BEGIN;

    set search_path to crm;

    select
        id,
        contact_method_id,
        content,
        is_inbound,
        send_time
    from messages
    where false;

    select 
        contact_id,
        "count"
    from outbound_messages_with_no_response;

    select 
        contact_method_id,
        "count"
    from outbound_messages_with_no_response_per_contact_method;

ROLLBACK;
