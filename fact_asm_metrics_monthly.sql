create table fact_asm_metrics_monthly (
	sales_id int8,
	metric_id int8,
	value float8,
	month_end int8,
	primary key (sales_id, metric_id, month_end)
);