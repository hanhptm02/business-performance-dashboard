create table dim_month (
	yearmonth_key int8 primary key,
	year_nbr int8,
	quarter_nbr int8,
	month_nbr int8,
	month_name varchar(255),
	month_short_name varchar(255),
	first_moy int8,
	last_moy int8,
	som_date date,
	eom_date date
);