-- Verify crm-for-devs:0003_pipelines on pg

BEGIN;

    set search_path to crm;

    select pipeline_id from contacts;
    select id, name, description from pipelines;

ROLLBACK;
