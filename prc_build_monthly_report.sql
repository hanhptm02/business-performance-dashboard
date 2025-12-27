create or replace procedure prc_build_monthly_report (i_date date default current_date - 1)
language plpgsql
as $$
declare 
	v_yearmonth int8;
	v_first_yearmonth int8;
	v_log_id int;
	v_prc_name varchar(1024) := 'prc_build_monthly_report';
begin 
	/* =======================================================
	 * --- Author --------------------------------------------
	 * created by: Hanh Pham
	 * created at: 2025-10-08 21:00:00
	 * --- Change log ----------------------------------------
	 * updated by  | updated at           | update reason
	 * Hanh Pham   | 2025-10-15 21:00:00  | chỉnh sửa logic
	 * --- Summary steps -------------------------------------
	 * STEP 1: Ghi thông tin thời gian bắt đầu call procedure
	 * STEP 2: Tính các chỉ số theo vùng monthly
	 * STEP 3: Tính các chỉ số theo asm monthly
	 * STEP 4: Ghi log sau khi kết thúc
	 * =======================================================
	 */
	-- STEP 1: Ghi thông tin thời gian bắt đầu call procedure
	insert into proc_execution_log 
	(prc_name, param_value, start_at)
	values 
	(v_prc_name, i_date, now())
	returning id into v_log_id;

	-- LOGIC chính
	begin
		-- Giả định lỗi
--		select 1/0;
		
		-- Đặt biến
		if i_date >= current_date then
			RAISE EXCEPTION 'Invalid param: i_date (%) cannot be current date or future date (today = %). Only T-1 or earlier is allowed.',
        		i_date, CURRENT_DATE;
			i_date := current_date - 1;
		end if;
		v_yearmonth := to_char(i_date, 'YYYYMM')::int8;
		v_first_yearmonth := (v_yearmonth/100)*100+1;
		
		-- STEP 2: Tính các chỉ số theo vùng monthly
		-- STEP 2.1: Lưu thông tin hệ số phân bổ
		truncate table temp_allocation_ratio;
	
		insert into temp_allocation_ratio
		-- Phân bổ theo Tỷ lệ SDCK bình quân sau WO nhóm 1
		select 
			area_id,
			'Tỷ lệ SDCK bình quân sau WO nhóm 1' as allocation_principle,
			(avg(outstanding_principal) / sum(avg(outstanding_principal)) over()) as allocation_ratio
		from 
			(
			select 
				kpi_month,
				dp.area_id,
				sum(outstanding_principal) outstanding_principal
			from fact_kpi_month fkm
			left join dim_pos dp on dp.pos_code = fkm.pos_cde
			where kpi_month between v_first_yearmonth and v_yearmonth
			and coalesce(max_bucket, 1) = 1
			group by 1, 2	
			)
		group by 1;
		
		insert into temp_allocation_ratio
		-- Phân bổ theo Tỷ lệ SDCK bình quân sau WO nhóm 2
		select 
			area_id,
			'Tỷ lệ SDCK bình quân sau WO nhóm 2' as allocation_principle,
			(avg(outstanding_principal) / sum(avg(outstanding_principal)) over()) as allocation_ratio
		from 
			(
			select 
				kpi_month,
				dp.area_id,
				sum(outstanding_principal) outstanding_principal
			from fact_kpi_month fkm
			left join dim_pos dp on dp.pos_code = fkm.pos_cde
			where kpi_month between v_first_yearmonth and v_yearmonth
			and coalesce(max_bucket, 1) = 2
			group by 1, 2	
			)
		group by 1;
		
		insert into temp_allocation_ratio
		-- Phân bổ theo Tỷ lệ Thẻ PSDN
		select
			area_id,
			'Tỷ lệ Thẻ PSDN' as allocation_principle,
			avg(psdn) /sum(avg(psdn)) over () as allocation_ratio
		from 
			(
			select 
				kpi_month,
				dp.area_id,
				sum(psdn) as psdn
			from fact_kpi_month fkm
			left join dim_pos dp on dp.pos_code = fkm.pos_cde
			where kpi_month between v_first_yearmonth and v_yearmonth
			group by 1, 2	
			)
		group by 1;
		
		insert into temp_allocation_ratio
		-- Phân bổ theo Tỷ lệ SDCK bình quân sau WO nhóm 2 - 5
		select 
			area_id,
			'Tỷ lệ SDCK bình quân sau WO nhóm 2 - 5' as allocation_principle,
			(avg(outstanding_principal) / sum(avg(outstanding_principal)) over()) as allocation_ratio
		from 
			(
			select 
				kpi_month,
				dp.area_id,
				sum(outstanding_principal) outstanding_principal
			from fact_kpi_month fkm
			left join dim_pos dp on dp.pos_code = fkm.pos_cde
			where kpi_month between v_first_yearmonth and v_yearmonth
			and coalesce(max_bucket, 1) in (2, 3, 4, 5)
			group by 1, 2	
			)
		group by 1;
		
		insert into temp_allocation_ratio
		-- Phân bổ theo Tỷ lệ SDCK bình quân sau WO
		select 
			area_id,
			'Tỷ lệ SDCK bình quân sau WO' as allocation_principle,
			(avg(outstanding_principal) / sum(avg(outstanding_principal)) over()) as allocation_ratio
		from 
			(
			select 
				kpi_month,
				dp.area_id,
				sum(outstanding_principal) outstanding_principal
			from fact_kpi_month fkm
			left join dim_pos dp on dp.pos_code = fkm.pos_cde
			where kpi_month between v_first_yearmonth and v_yearmonth
			group by 1, 2	
			)
		group by 1;
	
		insert into temp_allocation_ratio
		--  Phân bổ theo Tỷ lệ số lượng nhân viên
		select 
			area_id,
			'Tỷ lệ số lượng nhân viên' as allocation_principle,
			avg(slnv) / sum(avg(slnv)) over () as allocation_ratio
		from 
			(
			select 
				year_month,
				area_id as area_id,
				count(distinct sales_id) as slnv
			from fact_kpi_asm fka
			where year_month between v_first_yearmonth and v_yearmonth
			group by 1, 2	
			)
		group by 1;
		
		insert into temp_allocation_ratio
		--  Phân bổ theo Tỷ lệ SDCK bình quân lũy kế truớc WO nhóm 2-5
		select
			area_id,
			'Tỷ lệ SDCK bình quân lũy kế truớc WO nhóm 2-5' as allocation_principle,
			sum(outstanding_principal + cum_sum_wo) / sum(total_outstanding_principal + cum_sum_total_wo) as allocation_ratio
		from 
			(
			-- tính cumulative sum
			select 
				kpi_month,
				area_id,
				outstanding_principal,
				write_off_balance_principal,
				sum(write_off_balance_principal) over (partition by area_id order by kpi_month) as cum_sum_wo,
				total_outstanding_principal,
				total_write_off_balance_principal,
				sum(total_write_off_balance_principal) over (partition by area_id order by kpi_month) as cum_sum_total_wo
			from 
				(
				-- tính dư nợ của toàn vùng
				select 
					kpi_month,
					area_id,
					outstanding_principal,
					write_off_balance_principal,
					sum(outstanding_principal) over (partition by kpi_month) as total_outstanding_principal,
					sum(write_off_balance_principal) over (partition by kpi_month) as total_write_off_balance_principal
				from 
					(
					-- tính dư nợ từng vùng
					select 
						kpi_month,
						dp.area_id,
						sum(case 
							 when coalesce(max_bucket, 1) in (2, 3, 4, 5)
							 then outstanding_principal 
							 else 0 
							 end) outstanding_principal,
						sum(case 
							when kpi_month = write_off_month 
							then write_off_balance_principal
							else 0 
							end) write_off_balance_principal
					from fact_kpi_month fkm
					left join dim_pos dp on dp.pos_code = fkm.pos_cde
					where kpi_month between v_first_yearmonth and v_yearmonth
		--			and coalesce(max_bucket, 1) in (2, 3, 4, 5)
					group by 1, 2
					)
				)	
			)
		group by 1;
	
		insert into temp_allocation_ratio
		-- Phân bổ theo Tỷ trọng dư nợ sau WO vùng lũy kế trên tổng dư nợ sau WO lũy kế
		select
			area_id,
			'Tỷ trọng dư nợ sau WO vùng lũy kế trên tổng dư nợ sau WO lũy kế' as allocation_principle,
			sum(region_outstanding_principal) / sum (outstanding_principal) as allocation_ratio
		from 
			(
			select 
				*,
				sum(region_outstanding_principal) over (partition by kpi_month) as outstanding_principal
			from 
				(
				select 
					kpi_month,
					dp.area_id,
					sum(outstanding_principal) region_outstanding_principal
				from fact_kpi_month fkm
				left join dim_pos dp on dp.pos_code = fkm.pos_cde
				where kpi_month between v_first_yearmonth and v_yearmonth
				group by 1, 2
				)
			)
		group by 1;
	
		-- STEP 2.2: Lưu giá trị chưa phân bổ
		truncate table temp_unallocated_report_metrics;
	
		insert into temp_unallocated_report_metrics
		select 
			substring(analysis_code, 9, 1) as area_id,
			case 
				-- Thu nhập từ hoạt động thẻ 
				when account_code in ('702000030002', '702000030001', '702000030102') then 4
				when account_code in ('702000030012', '702000030112') then 5
				when account_code in ('716000000001') then 6
				when account_code in ('719000030002') then 7
				when account_code in ('719000030003', '719000030103', '790000030003', 
									  '790000030103', '790000030004', '790000030104') then 8
				--  Chi phí thuần hoạt động khác 
				when account_code in ('702000010001', '702000010002', '704000000001',
									  '705000000001', '709000000001', '714000000002', 
									  '714000000003', '714037000001', '714000000004', 
									  '714014000001', '715000000001', '715037000001', 
									  '719000000001', '709000000101', '719000000101') then 17
				when account_code in ('816000000001', '816000000002', '816000000003') then 18
				when account_code in ('809000000002', '809000000001', '811000000001', 
									  '811000000102', '811000000002', '811014000001', 
									  '811037000001', '811039000001', '811041000001', 
									  '815000000001', '819000000002', '819000000003', 
									  '819000000001', '790000000003', '790000050101', 
									  '790000000101', '790037000001', '849000000001', 
									  '899000000003', '899000000002', '811000000101', 
									  '819000060001') then 19
				-- Tổng chi phí hoạt động
				when account_code in ('831000000001', '831000000002', '832000000101', 
									  '832000000001', '831000000102') then 22
			    when account_code::varchar like '85%' then 23
			    when account_code::varchar like '86%' then 24
			    when account_code::varchar like '87%' then 25
			    -- Chi phí dự phòng
			    when account_code in ('790000050001', '882200050001', '790000030001', 
			    					  '882200030001', '790000000001', '790000020101', 
			    					  '882200000001', '882200050101', '882200020101', 
			    				      '882200060001', '790000050101', '882200030101') then 26
			    -- Chi phí thuần KDV 
			    when account_code in ('803000000001') then 13
			    when account_code in ('802000000002', '802000000003', '802014000001', 
			    				 	  '802037000001') then 12
			    when account_code in ('801000000001', '802000000001' ) then 11
				when account_code in ('702000040001','702000040002','703000000001',
			    					  '703000000002','703000000003','703000000004', 
			    					  '721000000041','721000000037','721000000039',
			    					  '721000000013','721000000014','721000000036',
			    					  '723000000014', '723000000037','821000000014',
			    					  '821000000037','821000000039','821000000041',
			    					  '821000000013','821000000036','823000000014',
			    					  '823000000037','741031000001','741031000002',
			    					  '841000000001','841000000005','841000000004',
		        					  '701000000001','701000000002','701037000001',
		        					  '701037000002','701000000101') then 10
			else
				NULL
			end as metric_id,
			sum(amount)/1000000 as value
		from fact_txn_month txm 
		where TO_CHAR(transaction_date, 'YYYYMM')::INT8 between v_first_yearmonth and v_yearmonth
		group by 1, 2;
	
		-- STEP 2.3: Insert thông tin chỉ sổ theo vùng monthly vào bảng fact
		delete from fact_area_metrics_monthly
		where yearmonth = v_yearmonth;
	
		-- Tính giá trị sau phân bổ của từng hệ số độc lập
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			coalesce(turm.value, 0)
				+ coalesce(tar.allocation_ratio, 0)*sum(case 
														when turm.area_id = '0' 
														then value else 0
														end) over (partition by dm.metric_id) as value,
			v_yearmonth as yearmonth
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		left join temp_allocation_ratio tar on tar.area_id = da.id and tar.allocation_principle = 'Tỷ lệ SDCK bình quân sau WO nhóm 1'
		where dm.metric_id in (4, 7);
	
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			coalesce(turm.value, 0)
				+ coalesce(tar.allocation_ratio, 0)*sum(case 
														when turm.area_id = '0' 
														then value else 0
														end) over (partition by dm.metric_id) as value,
			v_yearmonth as yearmonth
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		left join temp_allocation_ratio tar on tar.area_id = da.id and tar.allocation_principle = 'Tỷ lệ SDCK bình quân sau WO nhóm 2'
		where dm.metric_id in (5);
		
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			coalesce(turm.value, 0)
				+ coalesce(tar.allocation_ratio, 0)*sum(case 
														when turm.area_id = '0' 
														then value else 0
														end) over (partition by dm.metric_id) as value,
			v_yearmonth as yearmonth
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		left join temp_allocation_ratio tar on tar.area_id = da.id and tar.allocation_principle = 'Tỷ lệ Thẻ PSDN'
		where dm.metric_id in (6);
		
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			coalesce(turm.value, 0)
				+ coalesce(tar.allocation_ratio, 0)*sum(case 
														when turm.area_id = '0' 
														then value else 0
														end) over (partition by dm.metric_id) as value,
			v_yearmonth as yearmonth
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		left join temp_allocation_ratio tar on tar.area_id = da.id and tar.allocation_principle = 'Tỷ lệ SDCK bình quân sau WO nhóm 2 - 5'
		where dm.metric_id in (8);
		
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			0 as value,
			v_yearmonth as yearmonth
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		where dm.metric_id in (10, 15, 16);
		
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			coalesce(turm.value, 0)
				+ coalesce(tar.allocation_ratio, 0)*sum(case 
														when turm.area_id = '0' 
														then value else 0
														end) over (partition by dm.metric_id) as value,
			v_yearmonth as yearmonth											
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		left join temp_allocation_ratio tar on tar.area_id = da.id and tar.allocation_principle = 'Tỷ trọng dư nợ sau WO vùng lũy kế trên tổng dư nợ sau WO lũy kế'
		where dm.metric_id in (11, 12, 13);
		
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			coalesce(turm.value, 0)
				+ coalesce(tar.allocation_ratio, 0)*sum(case 
														when turm.area_id = '0' 
														then value else 0
														end) over (partition by dm.metric_id) as value,
			v_yearmonth as yearmonth											
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		left join temp_allocation_ratio tar on tar.area_id = da.id and tar.allocation_principle = 'Tỷ lệ SDCK bình quân sau WO'
		where dm.metric_id in (17, 18, 19, 20);
		
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			coalesce(turm.value, 0)
				+ coalesce(tar.allocation_ratio, 0)*sum(case 
														when turm.area_id = '0' 
														then value else 0
														end) over (partition by dm.metric_id) as value,
			v_yearmonth as yearmonth										
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		left join temp_allocation_ratio tar on tar.area_id = da.id and tar.allocation_principle = 'Tỷ lệ số lượng nhân viên'
		where dm.metric_id in (22, 23, 24, 25);
		
		insert into fact_area_metrics_monthly
		select
			da.id as area_id,
			dm.metric_id,
			count(distinct fka.sales_id) as value,
			v_yearmonth as yearmonth
		from dim_area da 
		cross join dim_metric dm	
		left join fact_kpi_asm fka on fka.area_id = da.id and fka.year_month = v_yearmonth
		where dm.metric_id in (27)
		group by 1, 2;
		
		insert into fact_area_metrics_monthly
		select 
			da.id as area_id,
			dm.metric_id,
			coalesce(turm.value, 0)
				+ coalesce(tar.allocation_ratio, 0)*sum(case 
														when turm.area_id = '0' 
														then value else 0
														end) over (partition by dm.metric_id) as value,
			v_yearmonth as yearmonth										
		from dim_area da 
		cross join dim_metric dm												
		left join temp_unallocated_report_metrics turm on turm.area_id = da.id and turm.metric_id = dm.metric_id
		left join temp_allocation_ratio tar on tar.area_id = da.id and tar.allocation_principle = 'Tỷ lệ SDCK bình quân lũy kế truớc WO nhóm 2-5'
		where dm.metric_id in (26);
		
		-- Tính các chỉ tiêu phụ thuộc
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			3 as metric_id,
			sum(value) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (4, 5, 6, 7, 8)
			and frm.yearmonth = v_yearmonth 
		group by 1, 4;
		
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			9 as metric_id,
			sum(value) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (10, 11, 12, 13)
			and frm.yearmonth = v_yearmonth 
		group by 1, 4;
		
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			14 as metric_id,
			sum(value) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (15, 16, 17, 18, 19, 20)
			and frm.yearmonth = v_yearmonth 
		group by 1, 4;
		
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			2 as metric_id,
			sum(value) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (3, 9, 14)
			and frm.yearmonth = v_yearmonth 
		group by 1, 4;
		
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			21 as metric_id,
			sum(value) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (22, 23, 24, 25)
			and frm.yearmonth = v_yearmonth 
		group by 1, 4;
		
		-- Tính LNTT lũy kế
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			1 as metric_id,
			sum(value) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (2, 21, 26)
			and frm.yearmonth = v_yearmonth 
		group by 1, 4;
	
		-- Tính tổng theo từng area
		insert into fact_area_metrics_monthly
		select 
			'All' as area_id,
			frm.metric_id,
			sum(value) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.area_id in ('B', 'C', 'D', 'E', 'F', 'G', 'H')
			and frm.yearmonth = v_yearmonth 
		group by 2, 4;
	
		-- Tính tổng phần cần phân bổ
		insert into fact_area_metrics_monthly
		select 
			'TPB' as area_id,
			frm.metric_id,
			sum(value) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.area_id in ('0')
			and frm.yearmonth = v_yearmonth 
		group by 2, 4;
	
		update fact_area_metrics_monthly
		set value = (select value 
					 from fact_area_metrics_monthly 
					 where metric_id = 27 and area_id = 'All' and yearmonth = v_yearmonth)
		where metric_id = 27 and area_id = 'TPB' and yearmonth = v_yearmonth;
		
		-- Tính các chỉ tiêu tài chính (dạng số tương đối)
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			28 as metric_id,
			- sum(case when frm.metric_id = 21 then frm.value else 0 end) * 100
			/
			nullif(sum(case when frm.metric_id = 2 then frm.value else 0 end), 0) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (2, 21)
			and frm.yearmonth = v_yearmonth 
			and frm.area_id not in ('0')
		group by 1, 4;
		
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			29 as metric_id,
			sum(case when frm.metric_id = 1 then frm.value else 0 end) * 100
			/
			nullif(sum(case when frm.metric_id in (3, 17) then frm.value else 0 end), 0) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (1, 3, 17)
			and frm.yearmonth = v_yearmonth 
			and frm.area_id not in ('0')
		group by 1, 4;
		
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			30 as metric_id,
			- sum(case when frm.metric_id = 1 then frm.value else 0 end) * 100
			/
			nullif(sum(case when frm.metric_id in (9) then frm.value else 0 end), 0) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (1, 9)
			and frm.yearmonth = v_yearmonth 
			and frm.area_id not in ('0')
		group by 1, 4;
		
		insert into fact_area_metrics_monthly
		select 
			frm.area_id,
			31 as metric_id,
			sum(case when frm.metric_id = 1 then frm.value else 0 end)
			/
			nullif(sum(case when frm.metric_id in (27) then frm.value else 0 end), 0) as value,
			frm.yearmonth
		from fact_area_metrics_monthly frm
		where frm.metric_id in (1, 27)
			and frm.yearmonth = v_yearmonth 
			and frm.area_id not in ('0')
		group by 1, 4;
	
		-- NPL before WO lũy kế cho báo cáo xếp hạng
		-- du no xau
		insert into fact_area_metrics_monthly
		select
			mvp.area_id,
			48 as metric_id,
			sum(ftm.outstanding_principal) as value,
			v_yearmonth as yearmonth 
		from fact_kpi_month ftm
		left join dim_pos mvp on mvp.pos_code = ftm.pos_cde 
		where ftm.kpi_month = v_yearmonth
			and coalesce(ftm.max_bucket) in (3, 4, 5)
		group by 1, 2, 4;
		
		-- tong du no
		insert into fact_area_metrics_monthly
		select
			mvp.area_id,
			49 as metric_id,
			sum(ftm.outstanding_principal) as value,
			v_yearmonth as yearmonth 
		from fact_kpi_month ftm
		left join dim_pos mvp on mvp.pos_code = ftm.pos_cde 
		where ftm.kpi_month = v_yearmonth
		group by 1, 2, 4;
		
		-- du no wo luy ke
		insert into fact_area_metrics_monthly
		select
			mvp.area_id,
			50 as metric_id,
			sum(ftm.write_off_balance_principal) as value,
			v_yearmonth as yearmonth 
		from fact_kpi_month ftm
		left join dim_pos mvp on mvp.pos_code = ftm.pos_cde 
		where ftm.kpi_month between v_first_yearmonth and v_yearmonth
			and ftm.kpi_month = write_off_month
		group by 1, 2, 4;
			
		insert into fact_area_metrics_monthly
		select 
			area_id,
			32 as metric_id,
			(sum(no_xau) + sum(wo_luy_ke))*100/(sum(tong_no) + sum(wo_luy_ke)) as value,
			v_yearmonth as yearmonth 
		from 
			(
			select
				mvp.area_id,
				case 
					when ftm.kpi_month = v_yearmonth and coalesce(ftm.max_bucket) in (3, 4, 5) then ftm.outstanding_principal 
					else 0
				end as no_xau,
				case 
					when ftm.kpi_month = v_yearmonth then ftm.outstanding_principal 
					else 0
				end as tong_no,
				case 
					when ftm.kpi_month = write_off_month then ftm.write_off_balance_principal 
					else 0 
				end as wo_luy_ke
			from fact_kpi_month ftm
			left join dim_pos mvp on mvp.pos_code = ftm.pos_cde 
			where ftm.kpi_month between v_first_yearmonth and v_yearmonth
			)
		group by 1;
		
		-- STEP 3: Tính các chỉ số theo asm monthly, lưu vào bảng fact_asm_metrics_monthly
		delete from fact_asm_metrics_monthly
		where month_end = v_yearmonth;
	
		-- Tính ltn trung bình
		insert into fact_asm_metrics_monthly
		select 
			sales_id,
			33 as metric_id,
			coalesce(avg(fka.value), 0) as value,
			v_yearmonth as month_end
		from fact_kpi_asm fka 
		where year_month between v_first_yearmonth and v_yearmonth
			and metric_id = 36
		group by 1;
		
		-- Tính psdn trung bình
		insert into fact_asm_metrics_monthly
		select 
			sales_id,
			34 as metric_id,
			coalesce(avg(fka.value), 0) as value,
			v_yearmonth as month_end
		from fact_kpi_asm fka 
		where year_month between v_first_yearmonth and v_yearmonth
			and metric_id = 39
		group by 1;
	
		-- Tính ai trung bình
		insert into fact_asm_metrics_monthly
		select 
			sales_id,
			44 as metric_id,
			coalesce(avg(fka.value), 0) as value,
			v_yearmonth as month_end
		from fact_kpi_asm fka 
		where year_month between v_first_yearmonth and v_yearmonth
			and metric_id = 38
		group by 1;
	
		-- Tính aa trung bình
		insert into fact_asm_metrics_monthly
		select 
			sales_id,
			45 as metric_id,
			coalesce(avg(fka.value), 0) as value,
			v_yearmonth as month_end
		from fact_kpi_asm fka 
		where year_month between v_first_yearmonth and v_yearmonth
			and metric_id = 40
		group by 1;
		
		-- Tính ar trung bình
		insert into fact_asm_metrics_monthly
		select
			sales_id,
			35 as metric_id,
			sum(case when metric_id = 40 then value else 0 end)
			/
			nullif(sum(case when metric_id = 38 then value else 0 end), 0)
			as value,
			v_yearmonth as month_end
		from fact_kpi_asm fka 
		where year_month between v_first_yearmonth and v_yearmonth
			and metric_id in (38, 40)
		group by 1, 2
		;
	
		insert into fact_asm_metrics_monthly
		select
			sales_id,
			case 
				when metric_id = 33 then 41
				when metric_id = 34 then 42
				when metric_id = 35 then 43
				when metric_id = 44 then 46
				when metric_id = 45 then 47				
			else null end as metric_id,
			(ln(value) - ln(min(value) over (partition by metric_id)))
			/
			(ln(max(value) over (partition by metric_id)) - ln(min(value) over (partition by metric_id)))
				as value,
			month_end
		from
			fact_asm_metrics_monthly famm 
		where month_end = v_yearmonth;
	
		-- STEP 4: Ghi log sau khi kết thúc
		-- 4.1.1 Thành công
		update proc_execution_log 
		set 
			is_successful = true
		where id = v_log_id;
	
	-- 4.1.2 Nếu có lỗi xảy ra
	exception 
		when others then 
			update proc_execution_log 
			set 
				is_successful = false,
				error_message = SQLERRM
			where id = v_log_id;
	end;

	-- 4.2 Thời gian kết thúc
	update proc_execution_log 
	set end_at = now()
	where id = v_log_id;
end;
$$;