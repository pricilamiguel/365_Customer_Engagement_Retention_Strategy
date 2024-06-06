USE customer_engagement;

SET sql_mode = '';

SELECT
	student_id,
    date_watched,
    ROUND(SUM(minutes_watched), 2) AS minutes_watched,
    paid
FROM
	(SELECT
		student_id,
        date_watched,
        minutes_watched,
        MAX(paid) AS paid
	FROM
		(SELECT
			l.student_id,
			l.date_watched,
			l.minutes_watched,
			i.date_start,
			i.date_end,
			CASE
				WHEN l.date_watched NOT BETWEEN i.date_start AND i.date_end
				THEN 0
				WHEN i.date_start IS NULL AND i.date_end IS NULL
				THEN 0
				WHEN l.date_watched BETWEEN i.date_start AND i.date_end
				THEN 1
			END AS paid
		FROM student_learning l
		LEFT JOIN purchases_info i
			USING(student_id)) a
	GROUP BY student_id, date_watched) b
GROUP BY student_id, date_watched;
	