# Business performance dashboard
1. Overview  
This project transforms raw data into a Power BI dashboard to provide quick insights and support business decision-making.

2. Business problem  
MH Finance Solutions’ management requires business performance monitoring to:
* Evaluate the company’s financial health
* Compare performance across regions and sales managers
* Support incentive scheme and performance-based compensation design

3. Solution  
As a Data Analyst, to address the above business problem, I applied the following approach:
* Collected and standardized business data from multiple sources
* Identified key performance indicators (KPIs) to be monitored
* Built an intuitive dashboard to deliver insights and enable fast, data-driven decision-making

4. Input  
Nguồn dữ liệu là các file excel sau:
- fact_kpi_month_raw_data: Thông tin của hồ sơ theo tháng
- fact_txn_month_raw_data: Thông tin giao dịch của các tài khoản GL
- kpi_asm_data: Thông tin về kết quả kinh doanh của từng Area Sales Manager (ASM) Files

  4.1. fact_kpi_month_raw_data
  <img width="1414" height="186" alt="image" src="https://github.com/user-attachments/assets/647faa2f-c246-4665-9563-5605f5dcd596" />
  | Column name | Description | Vietnamese description |
  |-------------|-------------|-------------|
  | kpi_month | Report month | Tháng báo cáo |
  | pos_cde | POS code | Mã POS |
  | pos_city | Province name| Tên tỉnh thành |
  | application_id | Application id | Mã hồ sơ |
  | outstanding_principal | Outstanding principal | Dư nợ |
  | write_off_month | Write off month| Tháng Write off |
  | write_off_balance_principal | Write off balance principal | Dư nợ Write off |
  | psdn | New customer count | Số lượng KH mới |
  | max_bucket | Debt group | Nhóm nợ |

  4.2. fact_txn_month_raw_data
  <img width="1306" height="184" alt="image" src="https://github.com/user-attachments/assets/c5d0eb4e-9803-425c-b54a-2878453f7342" />
  | Column name | Description | Vietnamese description |
  |-------------|-------------|------------------------|
  | transaction_date | Transaction date | Ngày giao dịch |
  | account_code | Account code | Số tài khoản GL |
  | account_description | Account description | Mô tả tài khoản GL |
  | analysis_code | Analysis code | Xác định giao dịch liên quan đến POS nào |
  | amount | Transaction amount (Unit: VND) | Số tiền giao dịch |
  | d_c | Transaction direction (D: Debit, C: Credit) | Là giao dịch ghi nợ (D) hay ghi có (C) |

  4.3. kpi_asm_data
  <img width="1890" height="197" alt="image" src="https://github.com/user-attachments/assets/74c3c726-0c9d-4096-a4ff-97a83d1f7722" />
  <img width="1889" height="200" alt="image" src="https://github.com/user-attachments/assets/efde50c7-69d4-4c86-b41d-71a173bd4674" />
  | Column name | Description | Vietnamese description |
  |-------------|-------------|------------------------|
  | month_key | Report month | Tháng báo cáo |
  | area_name | Area name | Tên khu vực |
  | sale_name | Area Sales Manager name | Tên nhân viên Area Sales Manager |
  | email | Area Sales Manager email | Email nhân viên Area Sales Manager |
  | loan_to_new | Outstanding loan balance of new customers in reporting month T | Số dư nợ cho vay khách hàng mới trong tháng T của năm báo cáo |
  | psdn | Number of new customers in reporting month T | SL KH mới trong tháng T của năm báo cáo |
  | app_approved | Number of approved applications in reporting month T | SL HS được duyệt trong tháng T của năm báo cáo |
  | app_in | Number of submitted applications in reporting month T | SL HS đăng ký trong tháng T của năm báo cáo |
  | approval_rate | Application approval rate in reporting month T | Tỷ lệ HS được duyệt trong tháng T của năm báo cáo |
  
  Note: This file is structured in a wide format, where each metric is split into 12 monthly columns within a year. 
  Due to merged cells and repeated month names, the column structure can be difficult to interpret. 
  Therefore, in the above data dictionary, fields are presented in a summarized form using the notation “reporting month T”.

5. Output  
Output: Business Performance Dashboard
* Business performance report: monitor overall company performance as well as performance by region
* Area sales managers ranking report: support bonus calculation and performance alerts
* KPI tracking across organizational and regional levels
* Individual ASM performance analysis to identify top-performing sales profiles

7. Process
- Step 1: Data Preparation  
  - Reformat the Excel files before importing into the database:
    - Remove merged cells  
    - Rename columns
  - Import the Excel files into the database.
  - Store unstandardized data in the staging table (if needed).  
  - Validate that the imported data matches the original Excel file.  
  - Transform the data and load it into fact tables.
- Step 2: Data Processing  
  Develop stored procedures with time parameters to calculate and store the required metrics in fact tables:
  - fact_area_metrics_monthly: Store monthly metric values by region  
  - fact_asm_metrics_monthly: Store monthly metric values for each sales representative
- Step 3: Visualization  
  - Define a list of key metrics to be monitored along with their corresponding charts and data sources  
  - Create views and import the required data into Power BI  
  - Build charts and format the dashboard in Power BI

8. Tools
* Excel: Data source
* DBeaver + PostgreSQL: Data processing
* Power BI: Visualization
  
9. Disclaimer
* The dataset is simulated for portfolio demonstration purposes.
* The dashboard is presented in Vietnamese to reflect a real-world business context.

9. Author  
Hanh Pham

