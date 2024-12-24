-- Verify crm-for-devs:0002_contact_method on pg

BEGIN;

    set search_path to crm;

    select
        id,
        contact_id,
        contact_method_meta_id,
        fields
    from contact_methods
    where false;

    select primary_contact_method_id
    from contacts
    where false;

    select 
        id,
        name,
        required_fields
    from contact_method_metas
    where false;

    insert into contact_method_metas (
        name,
        required_fields
    ) values (
        'contact_method_name',
        '{
            "key1": {
                "type": "md"
            },
            "key2": {
                "type": "select",
                "options": ["a", "b", "c"],
                "max_selections": 3
            }
        }'::jsonb
    );

    with new_contact 
        as (insert into contacts (name) values ('contact_1') returning id)
    insert into contact_methods (
        contact_method_meta_id,
        contact_id,
        fields
    ) values (
        1,
        (select id from new_contact),
        '{
            "key1": ["some text"],
            "key2": ["a", "b", "c"]
        }'::jsonb
    );

    do $$
    begin
        assert (2 = (select count(*) from contact_method_field_values_normalized)), 
            'Normalized field value tables was not created properly';
    end;
    $$ language plpgsql;

    create or replace function pg_temp.assert_bad_formating_is_stopped() 
    returns void as $$
    declare
        fails boolean := false;
    begin
        begin
            insert into contact_method_metas (
                name,
                required_fields
            ) values (
                'contact_method_name',
                '{
                    "normal_object": {
                        "type": "md"
                    },
                    "invalid_object": {
                        "random_key": "Type key is missing"
                    }
                }'::jsonb
            );
        exception 
        when raise_exception then
            fails := true;
        end;

        if not fails then
            raise exception 'Object is missing type key was not blocked';
        end if;

        fails := false;

        begin
            insert into contact_method_metas (
                name,
                required_fields
            ) values (
                'contact_method_name',
                '{
                    "missing_options": {
                        "type": "radio",
                        "options": "not an array"
                    }
                }'::jsonb
            );
        exception 
        when raise_exception then
            fails := true;
        end;

        if not fails then
            raise exception 'Object is missing option array was not blocked';
        end if;

        fails := false;

        begin
            insert into contact_method_metas (
                name,
                required_fields
            ) values (
                'contact_method_name',
                '{
                    "missing_options": {
                        "type": "select",
                        "options": ["a", "b", "c"],
                        "max_selections": "not a number"
                    }
                }'::jsonb
            );
        exception 
        when raise_exception then
            fails := true;
        end;

        if not fails then
            raise exception 'Object with invalid max_selections was not blocked';
        end if;

    end;
    $$ language plpgsql;

    select pg_temp.assert_bad_formating_is_stopped();

ROLLBACK;
