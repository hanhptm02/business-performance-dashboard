create view vw_rpt_general_report as
select
	yearmonth,
	section_name,
	metric_name,
	metric_unit,
	round("HEAD"::numeric) as "HEAD",
	round("Total_PB"::numeric) as "Total_PB",
	round("Đông Bắc Bộ"::numeric, 2) as "Đông Bắc Bộ",
	round("Tây Bắc Bộ"::numeric, 2) as "Tây Bắc Bộ",
	round("Đồng Bằng Sông Hồng"::numeric, 2) as "Đồng Bằng Sông Hồng",
	round("Bắc Trung Bộ"::numeric, 2) as "Bắc Trung Bộ",
	round("Nam Trung Bộ"::numeric, 2) as "Nam Trung Bộ",
	round("Tây Nam Bộ"::numeric, 2) as "Tây Nam Bộ",
	round("Đông Nam Bộ"::numeric, 2) as "Đông Nam Bộ",
	round("Total_KVML"::numeric, 2) as "Total_KVML",
	report_order,
	section_level
from 
	(
	select
		m.yearmonth,
		dgrs.section_name,
		dgrs.metric_code,
		dgrs.metric_name,
		dgrs.metric_unit,
		dgrs.report_order,
		dgrs.section_level,
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = '0' then value else 0 end) as "HEAD",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'TPB' then value else 0 end) as "Total_PB",
		-- sum(case when frm.area_id = 'A' then value else 0 end) as "Hội Sở",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'B' then value else 0 end) as "Đông Bắc Bộ",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'C' then value else 0 end) as "Tây Bắc Bộ",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'D' then value else 0 end) as "Đồng Bằng Sông Hồng",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'E' then value else 0 end) as "Bắc Trung Bộ",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'F' then value else 0 end) as "Nam Trung Bộ",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'G' then value else 0 end) as "Tây Nam Bộ",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'H' then value else 0 end) as "Đông Nam Bộ",
		sum(case 
			when dgrs.is_metric = false then null
			when frm.area_id = 'All' then value else 0 end) as "Total_KVML"
	from dim_general_report_structure dgrs
	cross join 
		(select distinct yearmonth from fact_area_metrics_monthly) m
	left join fact_area_metrics_monthly frm 
		on frm.metric_id = dgrs.metric_id 
		and frm.yearmonth = m.yearmonth 
	group by 1, 2, 3, 4, 5, 6, 7
	order by dgrs.report_order
	);