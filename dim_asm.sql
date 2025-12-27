create table dim_asm (
	id serial primary key,
	sales_name varchar(1024),
	sales_email varchar(1024) unique
);