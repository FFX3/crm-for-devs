-- Revert crm-for-devs:0007_public_interface.sql from pg

BEGIN;

    drop table crm.defaults;

    drop view contacts;

    drop view contact_methods;

    drop view contact_method_metas;

    drop view contact_pipelines;

    drop view contact_sources;

    drop view contact_messages;

    drop view contact_follow_up_reminders;

COMMIT;
