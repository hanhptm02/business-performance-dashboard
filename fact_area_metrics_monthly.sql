create table fact_area_metrics_monthly (
	area_id varchar(3),
	metric_id int8,
	value float8,
	yearmonth int8,
	primary key (area_id, metric_id, yearmonth)
);