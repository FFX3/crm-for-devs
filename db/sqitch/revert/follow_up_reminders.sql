-- Revert crm-for-devs:0006_follow_up_reminders from pg

BEGIN;

    set search_path to crm;

    drop table follow_up_reminders;

COMMIT;
