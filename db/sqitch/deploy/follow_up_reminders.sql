-- Deploy crm-for-devs:0006_follow_up_reminders to pg
-- requires: 0001_contacts
-- requires: 0002_contact_method

BEGIN;

    set search_path to crm;

    create table follow_up_reminders (
        id serial primary key,
        contact_id bigint not null references contacts (id) on delete cascade,
        time timestamptz not null,
        deferred boolean not null default false,
        notes text
    );

    grant all on follow_up_reminders to authenticated;
    alter table follow_up_reminders enable row level security;
    create policy "Open to authenticated" on follow_up_reminders
    for all
    to authenticated
    using(true)
    with check(true);

COMMIT;
