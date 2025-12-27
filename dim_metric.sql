create table dim_metric (
	metric_id serial primary key,
	metric_code varchar(1024) unique,
	metric_name varchar(1024) unique,
	description varchar(1024),
	unit varchar(1024),
	created_at timestamp default now(),
	updated_at timestamp default now()
);