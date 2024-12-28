-- Revert crm-for-devs:0008_upwork from pg

BEGIN;

    drop function init_upwork;

    drop function add_contact_from_upwork_proposal;

COMMIT;
