-- Revert crm-for-devs:0002_contact_method from pg

BEGIN;

    set search_path to crm;

    alter table contacts drop column primary_contact_method_id;
    drop table contact_method_field_values_normalized;

    drop trigger update_contact_method_field_values_normalized_trigger on contact_methods;
    drop function update_contact_method_field_values_normalized;
    drop trigger validate_fields_trigger on contact_methods;
    drop function validate_fields;
    drop table contact_methods;

    drop trigger validate_required_fields_trigger on contact_method_metas;
    drop function validate_required_fields;
    drop table contact_method_metas;

COMMIT;
