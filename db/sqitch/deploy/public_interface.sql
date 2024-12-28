-- Deploy crm-for-devs:0007_public_interface.sql to pg

BEGIN;

    create table crm.defaults (
        key text primary key,
        value text
    );

    grant all on crm.defaults to authenticated;
    alter table crm.defaults enable row level security;
    create policy "Open to authenticated" on crm.defaults
    for all
    to authenticated
    using(true)
    with check(true);

    create or replace view contacts
    with (security_invoker)
    as
    select 
      id,
      name,
      notes,
      status,
      source_id,
      pipeline_id
    from crm.contacts;

    create or replace view contact_methods
    with (security_invoker)
    as
    select 
      id,
      name,
      contact_method_meta_id,
      contact_id,
      fields
    from crm.contact_methods;

    create or replace view contact_method_metas
    with (security_invoker)
    as
    select 
      id,
      name,
      required_fields
    from crm.contact_method_metas;

    create or replace view contact_pipelines
    with (security_invoker)
    as
    select
        id,
        name,
        description
    from crm.pipelines;

    create or replace view contact_sources
    with (security_invoker)
    as
    select
        id,
        name,
        description
    from crm.sources;

    create or replace view contact_messages
    with (security_invoker)
    as
    select
        id,
        contact_method_id,
        content,
        is_inbound,
        send_time
    from crm.messages;

    create or replace view contact_follow_up_reminders
    with (security_invoker)
    as
    select
        id,
        contact_id,
        time,
        deferred,
        notes
    from crm.follow_up_reminders;

COMMIT;
