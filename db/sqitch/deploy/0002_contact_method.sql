-- Deploy crm-for-devs:0002_contact_method to pg

BEGIN;

    set search_path to crm;

    create table contact_method_metas (
      id bigint primary key generated always as identity,
      name text not null,
      required_fields jsonb not null
    );

    create table contact_methods (
      id bigint primary key generated always as identity,
      name text,
      contact_method_meta_id bigint not null references contact_method_metas (id),
      contact_id bigint not null references contacts (id),
      fields jsonb
    );

    alter table contacts add column primary_contact_method_id bigint references contact_methods (id);

    /*************
    fields: {
      [key]: value | value[]
    }

    required_field: {
      [key]: {
        type:           text | md | link | select | radio | checkbox,
        options?:       text[] -- for select, radio, and checkbox
        max_selections: int    -- for select, and checkbox
      }
    }
    *************/
    CREATE FUNCTION validate_fields() 
    RETURNS trigger 
    set search_path to crm
    AS $$
    DECLARE

    fields jsonb;
    required_fields jsonb;
    keys text[];
    key text;

    BEGIN

        fields := NEW.fields;

        required_fields := (
            SELECT cmm.required_fields 
            FROM crm.contact_method_metas cmm
            WHERE id = NEW.contact_method_meta_id
        );

        keys := ARRAY(SELECT jsonb_object_keys(required_fields));

        IF NOT fields ?& keys THEN
            RAISE EXCEPTION 'Missing key in required fields';
        END IF;

        FOREACH key IN ARRAY keys LOOP 

            IF jsonb_typeof(fields->key) <> 'array' THEN
                RAISE EXCEPTION 'Field % must be an array', key;
            END IF;

            CONTINUE WHEN required_fields->key->>'type' = ANY(ARRAY['text', 'md', 'link']);

            IF NOT (fields->key <@ (required_fields->key->'options')) THEN
                RAISE EXCEPTION 'Invalid key options for field %', key;
            END IF;

            IF jsonb_array_length(fields->key) > (required_fields->key->'max_selections')::int THEN
                RAISE EXCEPTION 'Too many selected options for field %', key;
            END IF;

        END LOOP;

        RETURN NEW;

    END;
    $$ LANGUAGE plpgsql;

    create trigger validate_fields_trigger before insert
    or
    update on contact_methods for each row
    execute function validate_fields ();

    CREATE FUNCTION validate_required_fields() 
    RETURNS trigger 
    set search_path to crm
    AS $$
    DECLARE
        key text;
        field jsonb;
        valid_types text[] := ARRAY['text', 'md', 'link', 'select', 'radio', 'checkbox'];
    BEGIN
        FOR key IN SELECT jsonb_object_keys(new.required_fields) LOOP

            field := new.required_fields->key;

            IF NOT (field ? 'type') THEN
                RAISE EXCEPTION 'Missing type for field %', key;
            END IF;

            IF NOT (field->>'type' = ANY(valid_types)) THEN
                RAISE EXCEPTION 'Invalid type for field %: %', key, field->>'type';
            END IF;

            -- Check 'options' and 'max_selections' for 'select', 'radio', and 'checkbox'
            IF field->>'type' = ANY(ARRAY['select', 'radio', 'checkbox']) THEN

                IF NOT (field ? 'options') THEN
                    RAISE EXCEPTION 'Missing options for field %', key;
                END IF;

                IF jsonb_typeof(field->'options') <> 'array' THEN
                    RAISE EXCEPTION 'Options must be an array for field %', key;
                END IF;

                IF field->>'type' = ANY(ARRAY['select', 'checkbox']) THEN
                    IF NOT (field ? 'max_selections') THEN
                        RAISE EXCEPTION 'Missing max_selections for field %', key;
                    END IF;

                    IF jsonb_typeof(field->'max_selections') <> 'number' THEN
                        RAISE EXCEPTION 'max_selections must be a number for field %', key;
                    END IF;
                END IF;

            END IF;

        END LOOP;
        return new;
    END;
    $$ LANGUAGE plpgsql;

    create trigger validate_required_fields_trigger before insert
    or
    update on contact_method_metas for each row
    execute function validate_required_fields ();

    -- used for search
    create table contact_method_field_values_normalized (
        contact_id bigint not null references contacts (id) on delete cascade,
        contact_method_id bigint not null references contact_methods (id) on delete cascade,
        key text,
        value text,
        PRIMARY KEY (contact_id, contact_method_id, key)
    );

    CREATE INDEX idx_contact_method_fields_value ON contact_method_field_values_normalized(value);

    CREATE FUNCTION update_contact_method_field_values_normalized() 
    RETURNS trigger 
    set search_path to crm
    AS $$
    BEGIN
        INSERT INTO crm.contact_method_field_values_normalized (
            contact_id,
            contact_method_id,
            key,
            value
        )
        SELECT
            new.contact_id,
            new.id,
            kv.key,
            kv.value
        FROM
            jsonb_each(new.fields) as kv;

        return new;
    END;
    $$ LANGUAGE plpgsql;

    create trigger update_contact_method_field_values_normalized_trigger after insert
    or
    update on contact_methods for each row
    execute function update_contact_method_field_values_normalized ();

COMMIT;
