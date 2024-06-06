USE customer_engagement;

SELECT
	certificate_id,
    student_id,
    certificate_type,
    date_issued,
    MAX(paid) AS paid
FROM
(SELECT
	c.certificate_id,
    c.student_id,
    c.certificate_type,
    c.date_issued,
    i.date_start,
    i.date_end,
    CASE
		WHEN c.date_issued NOT BETWEEN i.date_start AND i.date_end
        THEN 0
        WHEN i.date_start IS NULL AND i.date_end IS NULL
        THEN 0
        WHEN c.date_issued BETWEEN i.date_start AND i.date_end
        THEN 1
	END AS paid
FROM student_certificates c
LEFT JOIN purchases_info i
	USING(student_id)) AS certificate_paid
GROUP BY certificate_id;