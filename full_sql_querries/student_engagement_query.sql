USE customer_engagement;

SET sql_mode = '';

WITH student_engagement AS
(
SELECT
	student_id,
    date_engaged,
    MAX(paid) AS paid
    -- A student can have multiple purchases, causing the engagement records to be added multiple times, storing the start and end dates of each purchase.
    -- To remove the unnecessary records, we will use the MAX() function to retrieve only the paid (or non-paid) record.
FROM 
	(SELECT
		e.student_id,
		e.date_engaged,
		p.date_start,
		p.date_end,
		CASE
			WHEN p.date_start IS NULL AND p.date_end IS NULL
			THEN 0
			-- 0 indicates those who are not paid users
			WHEN e.date_engaged BETWEEN p.date_start AND p.date_end
			THEN 1
			-- 1 indicates those who are paid users
			WHEN e.date_engaged NOT BETWEEN p.date_start AND p.date_end
			THEN 0
		END AS paid
	FROM student_engagement e
	LEFT JOIN purchases_info p
		USING(student_id)) AS student_paid
GROUP BY student_id, date_engaged
ORDER BY student_id, date_engaged),

cohorts AS
(
SELECT 
    *,
    MIN(date_engaged) AS cohort
    -- We want the first engagement date for each student upon transitioning to either a free or paid user status.
FROM student_engagement
GROUP BY student_id , paid
),

engagement_and_cohort_difference AS
(
SELECT 
    e.*,
    c.cohort,
    TIMESTAMPDIFF(MONTH, c.cohort, e.date_engaged) AS period
FROM
    student_engagement e
JOIN cohorts c
	ON e.student_id = c.student_id
		AND e.paid = c.paid
)

SELECT * FROM engagement_and_cohort_difference;