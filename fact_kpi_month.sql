CREATE TABLE fact_kpi_month (
	kpi_month int8,
	pos_cde varchar(1024),
	city_id text,
	application_id int8,
	outstanding_principal int8,
	write_off_month int8,
	write_off_balance_principal int8,
	psdn int8,
	max_bucket int8,
	primary key (kpi_month, application_id)
);