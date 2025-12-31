# Business performance dashboard
**1. Overview**  
This project transforms raw data into a Power BI dashboard to provide quick insights and support business decision-making.

**2. Business problem**  
MH Finance Solutions’ management requires business performance monitoring to:
* Evaluate the company’s financial health
* Compare performance across regions and Area Sales Managers
* Support incentive scheme and performance-based compensation design

**3. Solution**  
As a Data Analyst, to address the above business problem, I applied the following approach:
* Collected and standardized business data from multiple sources
* Identified key performance indicators (KPIs) to be monitored
* Built an intuitive dashboard to deliver insights and enable fast, data-driven decision-making

**4. Input**  
The data source consists of the following three Excel files:
- fact_kpi_month_raw_data: Monthly application information
- fact_txn_month_raw_data: GL account transaction information
- kpi_asm_data: Monthly business performance by Area Sales Manager (ASM)

  **4.1. fact_kpi_month_raw_data**
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

  **4.2. fact_txn_month_raw_data**
  <img width="1306" height="184" alt="image" src="https://github.com/user-attachments/assets/c5d0eb4e-9803-425c-b54a-2878453f7342" />
  | Column name | Description | Vietnamese description |
  |-------------|-------------|------------------------|
  | transaction_date | Transaction date | Ngày giao dịch |
  | account_code | Account code | Số tài khoản GL |
  | account_description | Account description | Mô tả tài khoản GL |
  | analysis_code | Analysis code | Xác định giao dịch liên quan đến POS nào |
  | amount | Transaction amount (Unit: VND) | Số tiền giao dịch |
  | d_c | Transaction direction (D: Debit, C: Credit) | Là giao dịch ghi nợ (D) hay ghi có (C) |

  **4.3. kpi_asm_data**
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

**5. Output**  
Output: [Business Performance Dashboard](https://app.fabric.microsoft.com/view?r=eyJrIjoiZTIwODc0M2YtZDc0NS00MjU0LWEwZjgtOTU4N2JiNDBmOGNlIiwidCI6IjFhMTQ1ZTE3LTI5NzMtNDljMi1iY2U4LTFjNTA3MjRiZDdmMyIsImMiOjEwfQ%3D%3D)
* Business performance report: monitor overall company performance as well as performance by area
* Area sales managers ranking report: support bonus calculation and performance alerts
* KPI tracking across organizational and areal levels
* Individual ASM performance analysis to identify top-performing sales profiles

**6. Tools**
* Excel: Data source
* DBeaver + PostgreSQL: Data processing
* Power BI: Visualization

**7. Process**
<img width="1551" height="501" alt="Data Linage drawio" src="https://github.com/user-attachments/assets/ae4c64f1-945e-4188-b95b-dd583cbc0a09" />

- **Step 1**: Data Preparation  
  - Reformat the Excel files before importing into the database:
    - Remove merged cells  
    - Rename columns
  - Import the Excel files into the database.
  - Store unstandardized data in the staging table (if needed).
  - Transform the data and load it into fact tables.
    - [fact_kpi_asm](fact_kpi_asm.sql)
    - [fact_kpi_month](fact_kpi_month.sql)
    - [fact_txn_month](fact_txn_month.sql)
  - Validate that the imported data matches the original Excel file.
  - The following dimension tables are used to support the fact tables above:
    - [dim_area](dim_area.sql)
    - [dim_asm](dim_asm.sql)
    - [dim_general_report_structure](dim_general_report_structure.sql)
    - [dim_metric](dim_metric.sql)
    - [dim_month](dim_month.sql)
    - [dim_pos](dim_pos.sql)
    - [dim_province](dim_province.sql)
- **Step 2**: Data Processing  
  Develop stored procedure [prc_build_monthly_report](prc_build_monthly_report.sql) with time parameters to calculate and store the required metrics in fact tables:
  - [fact_area_metrics_monthly](fact_area_metrics_monthly.sql): Store monthly metric values by area  
  - [fact_asm_metrics_monthly](fact_asm_metrics_monthly.sql): Store monthly metric values for each Area Sales Managers
  <br>
  <img width="1274" height="534" alt="image" src="https://github.com/user-attachments/assets/f208b750-0c7d-4453-adfd-94bf592615dc" />

- **Step 3**: Visualization  
  - Define a list of key metrics to be monitored along with their corresponding charts and data sources  
  - Create views and import the required data into Power BI
    - [vw_rpt_general_report](vw_rpt_general_report.sql): Business performance report
    - [vw_rpt_asm_ranking](vw_rpt_asm_ranking.sql): Area sales managers ranking report
  - Build charts and format the dashboard in Power BI
  - Identify key insights through data visualization
  
**8. Disclaimer**
* The dataset is simulated for portfolio demonstration purposes.
* The dashboard is presented in Vietnamese to reflect a real-world business context.

**9. Author**  
Hanh Pham

