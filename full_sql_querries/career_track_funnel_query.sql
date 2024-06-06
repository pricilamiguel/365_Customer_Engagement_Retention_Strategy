USE customer_engagement;

WITH course_exams AS
(SELECT DISTINCT
    se.student_id,
    e.course_id
FROM student_exams se
JOIN exam_info e
	USING (exam_id)
WHERE
	e.exam_category = 2 -- exam_category 2 = course exams
),

course_certificates AS
(SELECT DISTINCT
    student_id,
    course_id
FROM student_certificates
WHERE certificate_type = 1 -- certificate_type 1 = course certificates
),

attempted_course_exam_certificate_issued AS
(SELECT 
    student_id,
    enrolled_in_track_id,
    MAX(attempted_course_exam) AS attempted_course_exam,
    MAX(certificate_course_id) AS certificate_course_id
FROM -- Get the successful course exams
	(SELECT 
		c.*,
		CASE
			WHEN cc.course_id IS NULL
            THEN 0
			WHEN cc.course_id IS NOT NULL
                AND c.attempted_course_exam = 0
			THEN 0
			WHEN cc.course_id IS NOT NULL
                AND c.attempted_course_exam = 1
			THEN 1
		END AS certificate_course_id
    FROM -- Get the track enrollment and the attempted_course_exam column
		(SELECT 
			a.student_id,
            a.track_id as enrolled_in_track_id,
            a.course_id,
            b.track_id,
            CASE
                WHEN a.course_id IS NULL
                THEN 0
                WHEN a.course_id IS NOT NULL
					AND b.track_id IS NULL
                THEN 0
                WHEN a.course_id IS NOT NULL
					AND b.track_id IS NOT NULL
                THEN 1
            END AS attempted_course_exam
		FROM -- Get the course ID'd of the course exams that a student has attempted
			(SELECT DISTINCT
				*
			FROM student_career_track_enrollments en
			LEFT JOIN course_exams ex
				USING (student_id)
			ORDER BY student_id , track_id , course_id) a
			LEFT JOIN career_track_info b
				ON a.track_id = b.track_id
				AND a.course_id = b.course_id) c
			LEFT JOIN course_certificates cc
				ON c.student_id = cc.student_id
				AND c.course_id = cc.course_id ) d
			GROUP BY student_id , enrolled_in_track_id
),

track_exams AS
(SELECT DISTINCT
    se.student_id,
    e.track_id
FROM student_exams se
JOIN exam_info e
	USING (exam_id)
WHERE e.exam_category = 3 -- exam_category 3 = career track exams
),

attempted_final_exam AS
(SELECT DISTINCT
    i.*,
    ex.track_id AS attempted_track_id
FROM attempted_course_exam_certificate_issued i
LEFT JOIN track_exams ex
	ON i.student_id = ex.student_id
	AND i.enrolled_in_track_id = ex.track_id
),

track_certificates AS
(SELECT 
    student_id,
    track_id,
    CAST(date_issued AS DATE) AS date_issued
FROM student_certificates
WHERE certificate_type = 2 -- certificate_type = career track certificate
),

issued_certificates AS
(SELECT DISTINCT
    e.*,
    c.track_id AS certificate_track_id,
    c.date_issued
FROM attempted_final_exam e
LEFT JOIN track_certificates c
    ON e.student_id = c.student_id
	AND e.enrolled_in_track_id = c.track_id
),

table_final AS
(SELECT 
    enrolled_in_track_id AS track_id,
    COUNT(enrolled_in_track_id) AS enrolled_in_track_id,
    SUM(attempted_course_exam) AS attempted_course_exam,
    SUM(certificate_course_id) AS certificate_course_id,
    COUNT(attempted_track_id) AS attempted_track_id,
    COUNT(certificate_track_id) AS certificate_track_id
FROM issued_certificates
GROUP BY enrolled_in_track_id
),

table_reordered AS
(SELECT 
    'Enrolled in a track' AS 'action',
    enrolled_in_track_id AS 'track',
    COUNT(enrolled_in_track_id) AS 'count'
FROM issued_certificates
GROUP BY enrolled_in_track_id

UNION

SELECT 
    'Attempted a course exam' AS 'action',
    enrolled_in_track_id AS 'track',
    SUM(attempted_course_exam) AS 'count'
FROM issued_certificates
GROUP BY enrolled_in_track_id

UNION

SELECT 
    'Completed a course exam' AS 'action',
    enrolled_in_track_id AS 'track',
    SUM(certificate_course_id) AS 'count'
FROM issued_certificates
GROUP BY enrolled_in_track_id

UNION

SELECT 
    'Attempted a final exam' AS 'action',
    enrolled_in_track_id AS 'track',
    COUNT(attempted_track_id) AS 'count'
FROM issued_certificates
GROUP BY enrolled_in_track_id

UNION

SELECT 
    'Earned a career track certificate' AS 'action',
    enrolled_in_track_id AS 'track',
    COUNT(certificate_track_id) AS 'count'
FROM issued_certificates
GROUP BY enrolled_in_track_id
)

SELECT * FROM table_reordered;