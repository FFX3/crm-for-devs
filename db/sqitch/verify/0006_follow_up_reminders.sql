-- Verify crm-for-devs:0006_follow_up_reminders on pg

BEGIN;

    set search_path to crm;

    select
        contact_id
        notes,
        deferred,
        time
    from follow_up_reminders
    where false;

ROLLBACK;
