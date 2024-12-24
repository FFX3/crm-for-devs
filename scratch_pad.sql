
begin;

with 
new_source as (
	insert into crm.sources (
		"name",
		description
	) values (
		'reach out',
		'Direct reach out over social media'
	) returning id
),
new_pipeline as (
	insert into crm.pipelines (
		"name",
		description 
	) values (
		'skool',
		'The group for dev who want to keep pushing their career'
	) returning id
),
new_contact as (
	insert into crm.contacts (
		"name",
		source_id,
		pipeline_id
	) values (
		'Denis McIntyre',
		(select id from new_source),
		(select id from new_pipeline)
	) returning id
),
new_contact_method_meta as (
	insert into crm.contact_method_metas (
		"name",
		required_fields
	) values (
		'email',
		'{ "email_address": { "type": "text" }}'::jsonb
	) returning id
),
new_contact_method as (
	insert into crm.contact_methods (
		contact_method_meta_id,
		contact_id,
		fields
	) values (
		(select id from new_contact_method_meta),
		(select id from new_contact),
		'{ "email_address": [ "denis.mcintyre@umoncton.ca" ] }'::jsonb
	) returning id
)
insert into crm.messages (
	contact_method_id,
	"content",
	is_inbound,
	send_time
) values
(
	(select id from new_contact_method),
	'bingo',
	true,
	now()
);

rollback;


