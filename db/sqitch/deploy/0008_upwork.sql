-- Deploy crm-for-devs:0008_upwork to pg

BEGIN;

    create function init_upwork ()
    returns void
    language plpgsql
    set search_path from current
    as $$
    begin

        if 0 = (select count(*) from crm.sources where name = 'Upwork') then
            insert into crm.sources (
                name,
                description
            ) values (
                'Upwork',
                'Upwork the freelance platform based in California.'
            );
        end if;

        if 0 = (select count(*) from crm.contact_method_metas where name = 'Upwork proposal') then
            insert into crm.contact_method_metas (
                name,
                required_fields
            ) values (
                'Upwork proposal',
                '{ "proposal_url": { "type": "link" } }'
            );
        end if;

        if 0 = (select count(*) from crm.defaults where key = 'default-upwork-pipeline') then
            with default_upwork_pipeline as (
                insert into crm.pipelines (
                    name,
                    description
                ) values (
                    'Upwork app development',
                    'My app development service on upwork'
                ) returning id
            )
            insert into crm.defaults (
                key,
                value
            ) values (
               'default-upwork-pipeline',
                (select id from default_upwork_pipeline)
            );
        end if;

    end;
    $$;
    
    create function add_contact_from_upwork_proposal(proposal_link text)
    returns bigint
    language plpgsql
    set search_path from current
    as $$
    declare
        _pipeline_id bigint;
        _source_id bigint;
        _contact_method_meta_id bigint; 
        _new_contact_id bigint;
    begin

        _pipeline_id := (select value from crm.defaults where key = 'default-upwork-pipeline');
        _source_id := (select id from crm.sources cs where name = 'Upwork');
        _contact_method_meta_id := (select cmm.id from crm.contact_method_metas cmm where name = 'Upwork proposal');

        if _pipeline_id is null then
            RAISE EXCEPTION 'Set default-pipeline in crm.defaults to call this function. Have you run init_upwork?';
        end if;

        if _source_id is null then
            RAISE EXCEPTION 'No sourced called "Upwork". Have you run init_upwork?';
        end if;

        if _contact_method_meta_id is null then
            RAISE EXCEPTION 'No contact method called "Upwork proposal". Have you run init_upwork?';
        end if;

        insert into crm.contacts (
          name,
          notes,
          source_id,
          pipeline_id
        ) values (
          concat('upwork_anon_', (select uuid_generate_v1())),
          'Proposal recipient on upwork',
          _source_id,
          _pipeline_id
        ) returning id into _new_contact_id;

        insert into crm.contact_methods (
          contact_id,
          contact_method_meta_id,
          fields
        ) values (
          _new_contact_id,
          _contact_method_meta_id,
          json_build_object('proposal_url', array[proposal_link])
        );

        return _new_contact_id;

    end
    $$;

COMMIT;
