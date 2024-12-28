-- Deploy crm-for-devs:0001_contacts to pg

BEGIN;

    create schema crm;

    set search_path to crm;

    create type contact_status as enum(
      'client',
      'prospect',
      'disqualified',
      'non-responsive',
      'said-no'
    );

    create table contacts (
      id bigint primary key generated always as identity,
      name text not null,
      notes text,
      status contact_status not null default 'prospect'
    );

    grant all on contacts to authenticated;
    alter table contacts enable row level security;
    create policy "Open to authenticated" on contacts
    for all
    to authenticated
    using(true)
    with check(true);

COMMIT;
