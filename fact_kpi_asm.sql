CREATE TABLE fact_kpi_asm (
	area_id varchar(3),
	sales_id int4,
	year_month int8,
	metric_id int4,
	value numeric,
	primary key (sales_id, year_month, metric_id)
);