create view vw_rpt_asm_ranking as 
select 
	year_month,
	area_id,
	area_name,
	sales_id,
	sales_email,
	rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl_truoc_wo_luy_ke
		+ rank_cir + rank_margin + rank_hs_von + rank_hsbq_nhan_su as "Tổng điểm",
	rank() over (partition by year_month order by 
		(rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl_truoc_wo_luy_ke
		+ rank_cir + rank_margin + rank_hs_von + rank_hsbq_nhan_su)) as rank_final,
	ltn_avg,
	rank_ltn_avg,
	psdn_avg,
	rank_psdn_avg,
	approval_rate_avg,
	rank_approval_rate_avg,
	npl_truoc_wo_luy_ke,
	rank_npl_truoc_wo_luy_ke,
	rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl_truoc_wo_luy_ke as "Điểm Quy Mô",
	rank () over (partition by year_month 
		order by (rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl_truoc_wo_luy_ke)) as rank_ptkd,
	cir::float8 as cir,
	rank_cir,
	margin::float8 as margin,
	rank_margin,
	hs_von::float8 as hs_von,
	rank_hs_von,
	hsbq_nhan_su::float8 as hsbq_nhan_su,
	rank_hsbq_nhan_su,
	rank_cir + rank_margin + rank_hs_von + rank_hsbq_nhan_su as "Điểm FIN",
	rank () over (partition by year_month 
		order by (rank_cir + rank_margin + rank_hs_von + rank_hsbq_nhan_su)) as rank_fin,
	case 
		when 
		rank() over (partition by year_month order by 
			(rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl_truoc_wo_luy_ke
			+ rank_cir + rank_margin + rank_hs_von + rank_hsbq_nhan_su)) <= 5
		then 'good'
		when
		rank() over (partition by year_month order by 
			(rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl_truoc_wo_luy_ke
			+ rank_cir + rank_margin + rank_hs_von + rank_hsbq_nhan_su) desc) <= 5
		then 'bad'
		else 'mid'
		end as performance_tier,
	case 
	when 
	rank() over (partition by year_month order by 
		(rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl_truoc_wo_luy_ke
		+ rank_cir + rank_margin + rank_hs_von + rank_hsbq_nhan_su)) = 1 then 'top'
	when 
	rank() over (partition by year_month order by 
		(rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl_truoc_wo_luy_ke
		+ rank_cir + rank_margin + rank_hs_von + rank_hsbq_nhan_su) desc) = 1 then 'bot'	
	end as top_bot_asm
from 
	(
	select 
		year_month,
		area_id,
		area_name,
		sales_id,
		sales_email,
		ltn_avg,
		rank () over (partition by year_month order by ltn_avg desc) as rank_ltn_avg,
		psdn_avg,
		rank () over (partition by year_month order by psdn_avg desc) as rank_psdn_avg,
		approval_rate_avg,
		rank () over (partition by year_month order by approval_rate_avg desc) as rank_approval_rate_avg,
		npl_truoc_wo_luy_ke,
		rank () over (partition by year_month order by npl_truoc_wo_luy_ke) as rank_npl_truoc_wo_luy_ke,
		cir,
		dense_rank () over (partition by year_month order by cir) as rank_cir,
		margin,
		dense_rank () over (partition by year_month order by margin desc) as rank_margin,
		hs_von,
		dense_rank () over (partition by year_month order by hs_von desc) as rank_hs_von,
		hsbq_nhan_su,
		dense_rank () over (partition by year_month order by hsbq_nhan_su desc) as rank_hsbq_nhan_su
	from 
		(
		select distinct
			fka.year_month,
			fka.area_id,
			da.area_name,
			fka.sales_id,
			fa.sales_email,
			ltn.value as ltn_avg,
			psdn.value as psdn_avg,
			ar.value as approval_rate_avg,
			tap.value as npl_truoc_wo_luy_ke,
			cc.value as cir,
			cm.value as margin,
			chtv.value as hs_von,
			chbn.value as hsbq_nhan_su
		from fact_kpi_asm fka
		left join dim_asm fa on fa.id = fka.sales_id
		left join dim_area da on da.id = fka.area_id
		left join (select sales_id, value, month_end 
				   from fact_asm_metrics_monthly 
				   where metric_id = 33) ltn on ltn.sales_id = fka.sales_id and ltn.month_end = fka.year_month
		left join (select sales_id, value, month_end 
				   from fact_asm_metrics_monthly 
				   where metric_id = 34) psdn on psdn.sales_id = fka.sales_id and psdn.month_end = fka.year_month
		left join (select sales_id, value, month_end
				   from fact_asm_metrics_monthly 
				   where metric_id = 35) ar on ar.sales_id = fka.sales_id and ar.month_end = fka.year_month
		left join (select area_id, value, yearmonth
				  from fact_area_metrics_monthly 
				  where metric_id = 32) tap on tap.area_id = fka.area_id and tap.yearmonth = fka.year_month
		left join (select area_id, value, yearmonth
				  from fact_area_metrics_monthly 
				  where metric_id = 28) cc on cc.area_id = fka.area_id and cc.yearmonth = fka.year_month
		left join (select area_id, value, yearmonth
				  from fact_area_metrics_monthly 
				  where metric_id = 29) cm on cm.area_id = fka.area_id and cm.yearmonth = fka.year_month
		left join (select area_id, value, yearmonth
				  from fact_area_metrics_monthly 
				  where metric_id = 30) chtv on chtv.area_id = fka.area_id and chtv.yearmonth = fka.year_month
		left join (select area_id, value, yearmonth
				  from fact_area_metrics_monthly 
				  where metric_id = 31) chbn on chbn.area_id = fka.area_id and chbn.yearmonth = fka.year_month
--		where fka.year_month = 202302
		)
	);