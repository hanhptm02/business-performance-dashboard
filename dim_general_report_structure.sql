create table dim_general_report_structure (
	id serial primary key,
	metric_id int8,
	metric_code varchar(1024),
	metric_name varchar(1024) unique,
	metric_unit varchar(1024),
	metric_parent_id int8,
	report_order int8 unique,
	section_level int4,
	section_name varchar(1024),
	is_metric boolean,
	created_at timestamp default now(),
	updated_at timestamp default now()
);