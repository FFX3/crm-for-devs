-- Deploy crm-for-devs:0005_messages.sql to pg
-- requires: 0001_contacts
-- requires: 0002_contact_method

BEGIN;

    set search_path to crm;

    create table messages (
        id serial primary key,
        contact_method_id bigint not null references contact_methods (id) on delete cascade,
        content text not null,
        is_inbound boolean not null,
        send_time timestamptz not null
    );

    create view outbound_messages_with_no_response as
    with
    messages_with_resets as (
        select
          m.id as message_id,
          contact_id,
          is_inbound,
          send_time,
          case when lag(is_inbound) over (
            partition by contact_id
            order by send_time
          ) <> is_inbound then 1 end as is_reset
        FROM
          crm.messages m
        join crm.contact_methods cm
            on m.contact_method_id  = cm.id
    ),
    squence_grouped as (
        select
            message_id,
            contact_id,
            is_inbound,
            send_time,
            is_reset,
            count(is_reset) over (
                partition by contact_id
                order by send_time
            ) as grp
        from messages_with_resets
    ),
    only_last_sequence_if_outbound as (
        select
            message_id,
            sg.contact_id,
            is_inbound,
            send_time,
            grp
        from squence_grouped sg
        join (
            select
                contact_id,
                max(grp) as max_grp
            from squence_grouped
            group by contact_id
        ) sg_with_max
        on 
            sg.contact_id = sg_with_max.contact_id 
            and sg.grp = sg_with_max.max_grp
        where not is_inbound
    )
    select contact_id, count(contact_id)
    from only_last_sequence_if_outbound
    group by (contact_id);

    create view outbound_messages_with_no_response_per_contact_method as
    with
    messages_with_resets as (
        select
          m.id as message_id,
          contact_method_id,
          is_inbound,
          send_time,
          case when lag(is_inbound) over (
            partition by contact_method_id
            order by send_time
          ) <> is_inbound then 1 end as is_reset
        FROM
          crm.messages m
    ),
    squence_grouped as (
        select
            message_id,
            contact_method_id,
            is_inbound,
            send_time,
            is_reset,
            count(is_reset) over (
                partition by contact_method_id
                order by send_time
            ) as grp
        from messages_with_resets
    ),
    only_last_sequence_if_outbound as (
        select
            message_id,
            sg.contact_method_id,
            is_inbound,
            send_time,
            grp
        from squence_grouped sg
        join (
            select
                contact_method_id,
                max(grp) as max_grp
            from squence_grouped
            group by contact_method_id
        ) sg_with_max
        on 
            sg.contact_method_id = sg_with_max.contact_method_id 
            and sg.grp = sg_with_max.max_grp
        where not is_inbound
    )
    select contact_method_id, count(contact_method_id)
    from only_last_sequence_if_outbound
    group by (contact_method_id);

COMMIT;
