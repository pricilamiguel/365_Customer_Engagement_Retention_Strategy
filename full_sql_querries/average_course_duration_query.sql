USE customer_engagement;

SELECT
	ROUND(SUM(course_duration) / (60 * COUNT(course_id)), 2) AS average_course_duration -- in hours
FROM course_info;