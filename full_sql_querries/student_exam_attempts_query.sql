USE customer_engagement;

SELECT
	s.exam_attempt_id,
    s.student_id,
    s.exam_id,
    i.exam_category,
    s.exam_passed,
    s.date_exam_completed
FROM student_exams s
JOIN exam_info i
	USING(exam_id);