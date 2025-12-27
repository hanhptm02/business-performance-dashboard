CREATE TABLE fact_txn_month (
	transaction_date date,
	account_code int8,
	account_description varchar(1024),
	analysis_code varchar(1024),
	amount int8,
	d_c varchar(1),
	primary key (analysis_code, account_code, transaction_date, d_c)
);