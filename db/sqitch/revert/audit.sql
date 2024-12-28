-- Revert crm-for-devs:audit from pg

BEGIN;

    set search_path to crm;

    drop trigger audit_trigger on contacts;
    drop trigger audit_trigger on contact_methods;
    drop trigger audit_trigger on contact_method_metas;
    drop trigger audit_trigger on follow_up_reminders;
    drop trigger audit_trigger on messages;
    drop trigger audit_trigger on pipelines;
    drop trigger audit_trigger on sources;

    drop function audit_operation;

    drop table audits;

COMMIT;
