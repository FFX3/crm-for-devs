-- Revert crm-for-devs:0003_pipelines from pg

BEGIN;

    set search_path to crm;

    alter table contacts drop column pipeline_id;
    drop table pipelines;

COMMIT;
