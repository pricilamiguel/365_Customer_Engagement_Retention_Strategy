USE customer_engagement;

CREATE VIEW purchases_info AS 
SELECT
	purchase_id,
    student_id,
    purchase_type,
    date_start,
    IF(date_refunded IS NULL, date_end, date_refunded) AS date_end
FROM
	(SELECT
		purchase_id,
		student_id,
		purchase_type,
		date_purchased as date_start,
		CASE
			WHEN purchase_type = 0
			THEN DATE_ADD(MAKEDATE(YEAR(date_purchased), DAY(date_purchased)), INTERVAL MONTH(date_purchased) MONTH)
			WHEN purchase_type = 1
			THEN DATE_ADD(MAKEDATE(YEAR(date_purchased), DAY(date_purchased)), INTERVAL MONTH(date_purchased)+2 MONTH)
			-- We're adding two because there are 3 months per quarter. So we will add two months to the current 1 month
			WHEN purchase_type = 2
			THEN DATE_ADD(MAKEDATE(YEAR(date_purchased), DAY(date_purchased)), INTERVAL MONTH(date_purchased)+11 MONTH)
			-- We're adding 11 months to the current 1 month to get a full years' date
		END AS date_end,
		date_refunded
	FROM student_purchases) AS sp_end_dates;
-- You can check the CASE statement by adding the following WHERE clause to filter throught each purchase_type
-- WHERE purchase_type = 0;

SELECT * FROM purchases_info;