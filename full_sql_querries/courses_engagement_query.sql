USE customer_engagement;

-- Courses Engagement
WITH total_minutes_watched_course AS (
SELECT
	s.course_id,
    c.course_title,
    c.course_duration,
    ROUND(SUM(minutes_watched), 2) AS total_minutes_watched,
    COUNT(DISTINCT s.student_id) AS student_watched_count
FROM student_learning s
JOIN course_info c
	ON s.course_id = c.course_id
GROUP BY course_id, course_title
),

total_minutes_watched_per_student AS (
SELECT
	s.course_id,
    s.student_id,
    ROUND(SUM(s.minutes_watched), 2) AS minutes_watched
FROM student_learning s
JOIN course_info c
	ON s.course_id = c.course_id
GROUP BY student_id, course_id
)

SELECT
	c.course_id,
    c.course_title,
    ROUND(c.total_minutes_watched, 2) AS minutes_watched,
    ROUND(AVG(s.minutes_watched),2) AS minutes_per_student,
    ROUND(((c.total_minutes_watched / c.student_watched_count) /  c.course_duration), 2) AS completion_rate
FROM total_minutes_watched_course c
JOIN total_minutes_watched_per_student s
	ON c.course_id = s.course_id
GROUP BY course_id;