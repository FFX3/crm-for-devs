-- Deploy crm-for-devs:audit to pg
-- requires: contacts
-- requires: contact_method
-- requires: pipelines
-- requires: contact_sources
-- requires: messages
-- requires: follow_up_reminders

BEGIN;

    set search_path to crm;

    create table audits (
        id serial primary key,
        operation text,
        table_name text not null,
        before jsonb,
        after jsonb,
        session_user_name text not null,
        jwt_claim jsonb,
        at timestamptz default current_timestamp
    );

    create function audit_operation()
    returns trigger
    language plpgsql
    set search_path from current
    as $$
    begin

        insert into audits (
            operation,
            table_name,
            before,
            after,
            session_user_name,
            jwt_claim
        ) values (
            TG_OP,
            TG_TABLE_NAME,
            row_to_json(old),
            row_to_json(new),
            (select session_user),
            (select auth.jwt())
        );

        return new;

    end;
    $$;

    CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON contacts
    FOR EACH ROW EXECUTE FUNCTION audit_operation();

    CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON contact_methods
    FOR EACH ROW EXECUTE FUNCTION audit_operation();

    CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON contact_method_metas
    FOR EACH ROW EXECUTE FUNCTION audit_operation();

    CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON messages
    FOR EACH ROW EXECUTE FUNCTION audit_operation();

    CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON sources
    FOR EACH ROW EXECUTE FUNCTION audit_operation();

    CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON pipelines
    FOR EACH ROW EXECUTE FUNCTION audit_operation();

    CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON follow_up_reminders
    FOR EACH ROW EXECUTE FUNCTION audit_operation();

COMMIT;
