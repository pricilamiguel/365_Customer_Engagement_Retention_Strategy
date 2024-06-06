USE customer_engagement;

SELECT 
    *,
    0 AS student_onboarded
FROM student_info
WHERE student_id NOT IN (SELECT DISTINCT student_id FROM student_engagement)

UNION

SELECT 
    *,
    1 AS student_onboarded
FROM student_info
WHERE student_id IN (SELECT DISTINCT student_id FROM student_engagement);