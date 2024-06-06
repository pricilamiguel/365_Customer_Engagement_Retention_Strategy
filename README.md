# **365 Data Science Customer Engagement Retention Strategy**

## Table of Contents
- [About the Company](#about-the-company)
- [Project Overview](#project-overview)
- [Things to Know Before We Start](#things-to-know-before-we-start)
- [Data Acquisition Using SQL](#data-acquisition-using-sql)
- [Data Analysis and Insights](#data-analysis-and-insights)
- [Applying Insights: Recommendations](#applying-insights-recommendations)
- [Contact Information](#contact-information)

## About the Company

365 Data Science is a free online education platform that covers a wide array of topics related to data science, data analytics, business analytics, machine learning, and more. Alongside its free educational resources, the platform also offers a premium subscription option, granting users full access to its comprehensive learning content. Each course on the platform is supplemented with quizzes, practice exams, and course exams. Upon successfully passing a course exam, students receive a course certificate, showcasing their proficiency in a given subject.

Learn more on the [365 Data Science](https://365datascience.com/) website.

## Project Overview

We used MySQL to extract relevant data in the form of CSV files and Tableau to create a story-based [dashboard](https://public.tableau.com/app/profile/pricila.miguel/viz/365CustomerEngagement/Overview) for our analysis.

As data analysts, our objective is to identify potential improvements and recommendations to help elevate the platform based off of data that was collected from the 365 Data Science website between January 1, 2022 – October 31, 2022, which include career track, course, and student engagement data.

> [!NOTE]
> To find a detailed breakdown of the database used for this analysis, refer to the [365 Customer Engagement Database Breakdown](365_Customer_Engagement_Database_Breakdown.pdf) document.

We will achieve this by addressing the following key questions through cohort analysis:
- How engaged are the students inside the platform, and how can this metric be improved?
-	How long do students stay engaged on the platform, and how can this period be extended?
-	What’s the difference in behavior between free and paid students?
-	Which are the most popular courses on the platform?
-	How many students sit for an exam?

Cohort Analysis examines the behavior and evolution of specific groups (or cohorts), serving as a valuable tool for tracking student engagement levels, monitoring retention rates, assessing the effectiveness of marketing campaigns, and measuring the success of new platform features. Understanding these metrics is crucial for subscription-based businesses, as they rely on recurring revenue from subscribers, ultimately driving increased overall business revenue over time.

## Things to Know Before We Start

Free users have access to about 30 minutes of content per course, while paid users enjoy unlimited access to all course content throughout their subscription period. In addition to individual courses, the platform offers career tracks, which represent a collection of seven carefully curated courses, forming a complete program on either of three job titles: Data Analyst, Business Analyst, or Data Scientist.

To successfully complete a career track, students must first finish ten exams in total: the course exams for the seven compulsory courses, the course exams for the two elective courses, and the final exam covering topics from all mandatory courses in the track with a passing score of 60% or higher. Practice exams are not factored into a student’s grade; their purpose is to help prepare for the final exams. Upon completing a career track, students receive a corresponding career track certificate, validating their proficiency across various topics and opening new doors to their desired job position.

In August 2022, the platform hosted a 3-day marketing event where all content is free within those three days. On September 16th, 2022, we released a new gamified platform feature. The expected outcome is to see an increase in student engagement and the onboarding rate during these times.

### Key Terms:
- **Students:** Those who have created an account by completing the registration form.
    - Can be a free-plan student or paying student.
- **Subscription Types:** Monthly, quarterly, or annual.
- **Engagement:** Students who have attempted or completed a lecture from a course, a quiz, or an exam.
- **Onboarding:** A students' first-time engagement.
- **Cohort:** Students onboarded in the same month.
    - 10 cohorts (January - October)

## Data Acquisition Using SQL

The first page of our story-based [dashboard](https://public.tableau.com/app/profile/pricila.miguel/viz/365CustomerEngagement/Overview), the ‘Overview’ page, provides a comprehensive view of student engagement, which includes three key performance indicators (KPIs): the number of engaged students on the platform, the average number of minutes watched per student, and the total number of certificates issued. The bar chart displays either the top or bottom five courses based on total overall minutes watched, average minutes watched per student, or its completion rate. The second chart, a donut chart, displays the average platform rating at its center, surrounded by fractions representing the distribution of one though five-star course ratings.

<img width="1344" alt="365_Customer_Engagement_Overview_Page" src="https://github.com/pricilamiguel/365_Customer_Engagement_Retention_Strategy/assets/131540339/d7975147-1214-4a99-b07b-7a615ee0c240">

To create the first KPI, number of engaged students, we need to identify those students who have engaged on the platform.
```sql
SELECT
  student_id,
  date_engaged
FROM student_engagement
GROUP BY student_id, date_engaged
ORDER BY student_id, date_engaged
```

To create the second KPI, the average minutes watched, we must determine the total number of minutes watched by each student.
```sql
SELECT ROUND(SUM(minutes_watched), 2) AS minutes_watched
FROM student_learning
GROUP BY student_id, date_watched
```

To create the third KPI, total number of certificates issued, we’ll identify the students who have successfully earned certificates.
```sql
SELECT
  certificate_id,
  student_id
FROM student_certificates
GROUP BY certificate_id
```

To apply date filtering to all three KPIs, we’ll extract dates from the student engagement table...
``sql
SELECT date_engaged
FROM student_engagement
GROUP BY student_id, date_engaged
ORDER BY student_id, date_engaged
``

…the student learning table...
```sql
SELECT date_watched
FROM student_learning
GROUP BY student_id, date_watched
```

…and the student certificates table. This will enable us to create parameters in Tableau, defining both the start and the end of the date range.
```sql
SELECT date_issued
FROM student_certificates
GROUP BY certificate_id
```

To filter all three KPIs by the student type (free, paid, or both), we’ll need to distinguish between engaged students that are free students and those who are paying. For the number of engaged students KPI, we’ll create a CTE to retrieve the relevant records.
```sql
WITH student_engagement AS
(
SELECT
  student_id,
  date_engaged,
  MAX(paid) AS paid
FROM
  (SELECT
    e.student_id,
    e.date_engaged,
    p.date_start,
    p.date_end,
    CASE
      WHEN p.date_start IS NULL AND p.date_end IS NULL
      THEN 0
      WHEN e.date_engaged BETWEEN p.date_start AND p.date_end
      THEN 1
      WHEN e.date_engaged NOT BETWEEN p.date_start AND p.date_end
      THEN 0
    END AS paid
  FROM student_engagement e
  LEFT JOIN purchases_info p
    USING(student_id)) AS student_paid
GROUP BY student_id, date_engaged
ORDER BY student_id, date_engaged)
```

For the average minutes watched KPI, we’ll utilize a subquery (or a nested query), to retrieve the relevant records.
```sql
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
GROUP BY student_id, date_watched)
```

Similarly, for the total number of certificates issued KPI, we’ll also employ a subquery to retrieve the relevant records.

For all three ‘Course Metrics’ bar charts, we will utilize the common table expressions (CTEs) created in the ‘courses engagement’ query to retrieve the course titles.
```sql
SELECT
  c.course_id,
  c.course_title
FROM total_minutes_watched_course c
JOIN total_minutes_watched_per_student s
  ON c.course_id = s.course_id
GROUP BY course_id
```

For the ‘Overall Minutes Watched’ graph, we will retrieve the total minutes watched from the ‘total_minutes_watched_course’ CTE created in the same query.
```sql
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
```

To obtain the total minutes watched per student for the ‘Minutes per Student’ graph, we’ll generate a CTE named ‘total_minutes_watched_per_student’ in the ‘courses engagement’ query to calculate the average minutes watched per student per course.
```sql
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
```

For the ‘Completion Rate’ graph, we will utilize both CTEs from the ‘courses engagement’ query to retrieve the completion rate for each course.
```sql
SELECT
  ROUND(((c.total_minutes_watched / c.student_watched_count) /  c.course_duration), 2) AS completion_rate
FROM total_minutes_watched_course c
JOIN total_minutes_watched_per_student s
  ON c.course_id = s.course_id
GROUP BY course_id;
```

For the ‘Course Ratings’ donut chart, we’ll simply retrieve the ratings for every course to display the number of course ratings per rating.
```sql
SELECT course_rating
FROM course_ratings;
```

> [!NOTE]
> These snippets of code do not represent the complete queries used to create the dashboards. They serve as examples of specific sections used for certain measures or dimensions. Please refer to links below for the full queries used.

> [!NOTE]
> Full Student Engagement SQL query [here](full_sql_querries/student_engagement_query.sql)

> [!NOTE]
> Full Student Learning SQL query [here](full_sql_querries/student_learning_query.sql)

> [!NOTE]
> Full Student Certificates SQL query [here](full_sql_querries/student_certificates_query.sql)

> [!NOTE]
> Full Courses Engagement SQL query [here](full_sql_querries/courses_engagement_query.sql)

> [!NOTE]
> Full Course Ratings SQL query [here](full_sql_querries/course_ratings_query.sql)

The ‘Engagement and Onboarding’ page focuses on tracking activity and onboarding trends over time. The first line chart displays the number of engaged users over time, while the bottom chart shows the percentage of onboarded students relative to their registration date. This page will give the option to select between daily, monthly, or yearly views to analyze data at different levels of granularity.

- **Onboarded-to-Registered:** (number of students onboarded / number of students) * 100

<img width="1344" alt="365_Customer_Engagement_Engagement_Page" src="https://github.com/pricilamiguel/365_Customer_Engagement_Retention_Strategy/assets/131540339/eba304ed-b605-4aff-9edb-07b80800f1ff">

For all three views of the engagement date chart, we’ll extract the engagement dates and student IDs from the ‘student engagement’ query. These engagement dates will serve as the basis for our date filter.
```sql
SELECT
  student_id,
  date_engaged
FROM student_engagement
GROUP BY student_id, date_engaged
ORDER BY student_id, date_engaged
```

To filter this chart by the student type (free, paid, or both), we’ll need to distinguish between engaged students that are free students and those who are paying. We’ll achieve this by employing the same subquery (or a nested query) from the ‘student engagement’ query to retrieve the relevant records.

For all three views of the registration date chart, we’ll retrieve student registration dates from the ‘student onboarding’ query. This column will also be used to respond to the date filter for all charts.
```sql
SELECT date_registered
FROM student_info;
```

To calculate the fraction of onboarded students in Tableau, we’ll distinguish whether a student has been onboarded on not.
```sql
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
```

> [!NOTE]
> These snippets of code do not represent the complete queries used to create the dashboards. They serve as examples of specific sections used for certain measures or dimensions. Please refer to links below for the full queries used.

> [!NOTE]
> Full Student Engagement SQL query [here](full_sql_querries/student_engagement_query.sql)

> [!NOTE]
> Full Student Onboarding SQL query [here](full_sql_querries/student_onboarding_query.sql)

On the ‘Cohort Engagement’ page, the bottom chart features a cohort analysis table, where each row represents a cohort of students onboarded in the same month. The columns represent the months since onboarding, offering insight into the retention of newcomers over time. The chart above illustrates the fluctuation in cohort size over successive periods, corresponding to the months selected in the cohort analysis table. It plots retention rates on the y-axis against periods on the x-axis, with the curve starting at 100% to signify the initial cohort size.

- **Retention Rate:** (number of engaged students within a given period / total number of engaged students within the given month) * 100

<img width="1344" alt="365_Customer_Engagement_Cohorts_Page" src="https://github.com/pricilamiguel/365_Customer_Engagement_Retention_Strategy/assets/131540339/59916807-1366-4b00-a42a-e582de8eb7ad">

For the cohort table, we’ll extract the months from the cohort dates using the CTE from the ‘student engagement’ query. The cohort column stores each student’s onboarding date, by student type. The student IDs from this query will be used to determine the number of students for each cohort and period.
```sql
cohorts AS
(
SELECT 
  *,
  MIN(date_engaged) AS cohort
FROM student_engagement
GROUP BY student_id , paid
),
```

Next, we’ll create a CTE that calculates the periods by determining the difference in months between the engagement date and the cohort columns.
```sql
engagement_and_cohort_difference AS
(
SELECT 
  e.*,
  c.cohort,
  TIMESTAMPDIFF(MONTH, c.cohort, e.date_engaged) AS period
FROM student_engagement e
JOIN cohorts c
  ON e.student_id = c.student_id
    AND e.paid = c.paid
)
```

To filter all charts on this page by student type, we’ll need to distinguish between engaged students that are free students and those who are paying. We’ll achieve this by employing the same subquery (or a nested query) from the ‘student engagement’ query to retrieve the relevant records.

To create the retention curve chart, we’ll utilize the ‘student_id’ and ‘period’ columns from the ‘student engagement’ query. A table calculation will be created in Tableau to determine the percentage of engaged students relative to their number in period zero.

> [!NOTE]
> These snippets of code do not represent the complete queries used to create the dashboards. They serve as examples of specific sections used for certain measures or dimensions. Please refer to links below for the full queries used.

> [!NOTE]
> Full Student Engagement SQL query [here](full_sql_querries/student_engagement_query.sql)

On the ‘Exams and Certificates’ page, the first chart is a horizontal bar chart showing the number of exams taken that month. Within each bar, the left section indicates the percentage of exams not passed, while the right section would show the opposite. The second half of the page offers toggling between two charts. The first is a vertical bar chart displaying the number of certificates issued by month. The second is a funnel visualization presented as a horizonal bar chart, with a filter option to select the career track.

- **Percent of Exams Taken for the Month:** (number of exam attempts by exam status / total number of exam attempts) * 100

<img width="1344" alt="365_Customer_Engagement_Exams_Page" src="https://github.com/pricilamiguel/365_Customer_Engagement_Retention_Strategy/assets/131540339/2dc64b5a-1827-4ce5-9a7b-43f5e5c02e75">

For the left bar chart, we’ll extract the exam attempt IDs to count the number of exam attempts, distinguish between pass and fail statuses, and completion dates from the ‘student exam attempts’ query.
```sql
SELECT
  s.exam_attempt_id,
  s.exam_passed,
  s.date_exam_completed
FROM student_exams s
JOIN exam_info i
  USING(exam_id)
```

To filter the chart by the exam category (practice exam, course exam, career track exam, or all), we’ll include the exam category column from the same query.
```sql
SELECT
  i.exam_category,
FROM student_exams s
JOIN exam_info i
  USING(exam_id);
```

For the ‘Certificates Issued’ chart, we’ll gather the certificate IDs to count the number of certificates issued and issuance dates from the ‘student certificates’ query.
```sql
SELECT
  certificate_id,
  date_issued
FROM student_certificates
GROUP BY certificate_id
```

To filter the chart by the certificate type (course certificate, career track certificate, or both), we’ll extract the certificate type column from the same query.
```sql
SELECT certificate_type
FROM student_certificates
GROUP BY certificate_id
```

For the ‘Career Track Funnel’ chart, we’ll discern the different student actions (enrolled in a track, attempted a course exam, etc.) and the count of each action from the ‘career track funnel’ query. We’ll achieve this by creating a CTE for each action to reference later.
```sql
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
      (SELECT DISTINCT *
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

attempted_final_exam AS
(SELECT DISTINCT
  i.*,
  ex.track_id AS attempted_track_id
FROM attempted_course_exam_certificate_issued i
LEFT JOIN track_exams ex
  ON i.student_id = ex.student_id
    AND i.enrolled_in_track_id = ex.track_id
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
```

To filter this chart by the career track type, we’ll obtain the track IDs for each action from the same query.

> [!NOTE]
> These snippets of code do not represent the complete queries used to create the dashboards. They serve as examples of specific sections used for certain measures or dimensions. Please refer to links below for the full queries used.

> [!NOTE]
> Full Student Exam Attempts SQL query [here](full_sql_querries/student_exam_attempts_query.sql)

> [!NOTE]
> Full Student Certificates SQL query [here](full_sql_querries/student_certificates_query.sql)

> [!NOTE]
> Full Career Track Funnel SQL query [here](full_sql_querries/career_track_funnel_query.sql)

The final page on the dashboard is the ‘Student Learning’ page. The left bar chart displays the minutes watched by students each month, along with a line graph showing the average minutes watched each month. The right side of the page will feature two combo charts. One will display the number of students segmented into buckets and their conversion rate. The other will show the number of students segmented into buckets and their average subscription duration counted in days.

- **Free-to-Paid Conversion Rate:** (number of paying students / total number of students) * 100

<img width="1344" alt="365_Customer_Engagement_Learning_Page" src="https://github.com/pricilamiguel/365_Customer_Engagement_Retention_Strategy/assets/131540339/f0c34b4d-36a1-40d8-8a2e-af513a279cb3">

For the left combo chart, we’ll gather dates indicating when students viewed any content, along with the total minutes watched for each date to create the bar chart.
```sql
SELECT
  date_watched,
  ROUND(SUM(minutes_watched), 2) AS minutes_watched
FROM student_learning
GROUP BY student_id, date_watched
```

Additionally, we’ll calculate the average minutes watched per student for the line chart. This calculation involves subtracting the total minutes watched from the count of students in Tableau, using the ‘student_id’ and ‘minutes_watched’ columns.
```sql
SELECT student_id
FROM student_learning
GROUP BY student_id, date_watched
```

To filter this chart by the student type (free, paid, or both), we’ll need to distinguish between engaged students that are free students and those who are paying. We’ll achieve this by employing the same subquery (or a nested query) from the ‘student engagement’ query to retrieve the relevant records.

For the ‘Conversion Rate’ combo chart, we’ll create buckets based on the minutes watched, accomplished by creating a CTE for later reference.
```sql
buckets_distribution AS
(SELECT 
  *,
  CASE
    WHEN total_minutes_watched = 0
      OR total_minutes_watched IS NULL
    THEN '[0]'
    WHEN total_minutes_watched > 0
      AND total_minutes_watched <= 5
    THEN '(0, 5]'
    WHEN total_minutes_watched > 5
      AND total_minutes_watched <= 10
    THEN '(5, 10]'
    WHEN total_minutes_watched > 10
      AND total_minutes_watched <= 15
    THEN '(10, 15]'
    WHEN total_minutes_watched > 15
      AND total_minutes_watched <= 20
    THEN '(15, 20]'
    WHEN total_minutes_watched > 20
      AND total_minutes_watched <= 25
    THEN '(20, 25]'
    WHEN total_minutes_watched > 25
      AND total_minutes_watched <= 30
    THEN '(25, 30]'
    WHEN total_minutes_watched > 30
      AND total_minutes_watched <= 40
    THEN '(30, 40]'
    WHEN total_minutes_watched > 40
      AND total_minutes_watched <= 50
    THEN '(40, 50]'
    WHEN total_minutes_watched > 50
      AND total_minutes_watched <= 60
    THEN '(50, 60]'
    WHEN total_minutes_watched > 60
      AND total_minutes_watched <= 70
    THEN '(60, 70]'
    WHEN total_minutes_watched > 70
      AND total_minutes_watched <= 80
    THEN '(70, 80]'
    WHEN total_minutes_watched > 80
      AND total_minutes_watched <= 90
    THEN '(80, 90]'
    WHEN total_minutes_watched > 90
      AND total_minutes_watched <= 100
    THEN '(90, 100]'
    WHEN total_minutes_watched > 100
      AND total_minutes_watched <= 110
    THEN '(100, 110]'
    WHEN total_minutes_watched > 110
      AND total_minutes_watched <= 120
    THEN '(110, 120]'
    WHEN total_minutes_watched > 120
      AND total_minutes_watched <= 240
    THEN '(120, 240]'
    WHEN total_minutes_watched > 240
      AND total_minutes_watched <= 480
    THEN '(240, 480]'
    WHEN total_minutes_watched > 480
      AND total_minutes_watched <= 1000
    THEN '(480, 1000]'
    WHEN total_minutes_watched > 1000
      AND total_minutes_watched <= 2000
    THEN '(1000, 2000]'
    WHEN total_minutes_watched > 2000
      AND total_minutes_watched <= 3000
    THEN '(2000, 3000]'
    WHEN total_minutes_watched > 3000
      AND total_minutes_watched <= 4000
    THEN '(3000, 4000]'
    WHEN total_minutes_watched > 4000
      AND total_minutes_watched <= 6000
    THEN '(4000, 6000]'
    ELSE '6000+'
  END AS buckets
FROM minutes_summed_2
)
```

Then we’ll obtain student IDs from the same query to get the count of students within each bucket.
```sql
SELECT student_id
FROM buckets_distribution;
```

To calculate the conversion rate for the line chart, we’ll determine the number of students who have converted from free to paid, dividing it by the count of students in Tableau using the ‘paid’ and ‘student_id’ columns.
```sql
WITH period_to_consider AS
(SELECT 
  0 AS paid,
  -- Those who don't have a paid subscription
FROM student_info i
LEFT JOIN student_purchases p
  ON i.student_id = p.student_id
WHERE p.student_id IS NULL

UNION

SELECT 
  1 AS paid,
  -- Those who have a paid subscription
FROM student_info i
JOIN student_purchases p
  ON i.student_id = p.student_id
GROUP BY p.student_id
),
```

For the ‘Subscription Duration’ combo chart, we’ll create the same bar chart using the ‘buckets distribution’ and ‘student_id’ columns from the ‘student buckets subscription duration’ query.
```sql
buckets_distribution AS
(SELECT 
  d.*,
  i.date_registered,
  CASE
    WHEN total_minutes_watched = 0
      OR total_minutes_watched IS NULL
    THEN '[0]'
    WHEN total_minutes_watched > 0
      AND total_minutes_watched <= 30
    THEN '(0, 30]'
    WHEN total_minutes_watched > 30
      AND total_minutes_watched <= 60
    THEN '(30, 60]'
    WHEN total_minutes_watched > 60
      AND total_minutes_watched <= 120
    THEN '(60, 120]'
    WHEN total_minutes_watched > 120
      AND total_minutes_watched <= 240
    THEN '(120, 240]'
    WHEN total_minutes_watched > 240
      AND total_minutes_watched <= 480
    THEN '(240, 480]'
    WHEN total_minutes_watched > 480
      AND total_minutes_watched <= 1000
    THEN '(480, 1000]'
    WHEN total_minutes_watched > 1000
      AND total_minutes_watched <= 2000
    THEN '(1000, 2000]'
    WHEN total_minutes_watched > 2000
      AND total_minutes_watched <= 3000
    THEN '(2000, 3000]'
    WHEN total_minutes_watched > 3000
      AND total_minutes_watched <= 4000
    THEN '(3000, 4000]'
    WHEN total_minutes_watched > 4000
      AND total_minutes_watched <= 6000
    THEN '(4000, 6000]'
  ELSE '6000+'
  END AS user_buckets
FROM duration_in_days d
JOIN student_info i
  USING(student_id)
)
```

To calculate the average subscription duration for the line chart, we’ll find the difference of the total number of paid days and the number of students per bucket in Tableau using the ‘num_paid_days’ and ‘student_id’ columns.
```sql
SELECT 
  student_id,
  difference_in_days AS num_paid_days,
  user_buckets AS 'buckets'
FROM buckets_distribution;
```

> [!NOTE]
> These snippets of code do not represent the complete queries used to create the dashboards. They serve as examples of specific sections used for certain measures or dimensions. Please refer to links below for the full queries used.

> [!NOTE]
> Full Student Learning SQL query [here](full_sql_querries/student_learning_query.sql)

> [!NOTE]
> Full Student Buckets F2P SQL query [here](full_sql_querries/student_buckets_f2p_query.sql)

> [!NOTE]
> Full Student Buckets Subscription Duration SQL query [here](full_sql_querries/student_buckets_sub_duration_query.sql)

## Data Analysis and Insights

Reflecting on the key questions we aim to address:
- **How engaged are the students inside the platform, and how can this metric be improved?**
  - **Number of Engaged Students:** From June 1, 2022 – October 31, 2022, there were 19,332 engaged students. Among them, 18,032 were free-plan students and 2,178 were paying students. Some students converted from free to paid plans, which explains why the combined total exceeds the number of engaged students.
  - **Changes Over Time:** Engagement increased by approximately 40% in the last three months compared to the beginning of the year. The August promotion significantly boosted free student engagement with 805 students engaged on the 15th, 806 students on the 16th, and 743 on the 17th. Excluding August, the engagement of free students follows a fairly linear pattern at the beginning of the year, with an average of about 70 engaged students daily in January, rising to about 80 in July, and then increasing to about 100 in August. By October, the number of engaged students rose up to approximately 150 per day. This indicates about a 33% increase in the number of engaged free students following the August promotion. There was no discernible effect of the engagement trends for paying students following the August promotion, likely due to the fact that they already had paid access to all content. Nonetheless, engagement among paying students shows an upwards trend over time, with an average of about 45 students daily in January, increasing to about 190 in October.
  - **Marketing Campaigns and Events:** The August promotion and the gamified feature added in med-September positively impacted engagement. The gamification feature increased the average number of engaged paying students by about 37%.
  - **Onboarding Rate:** The onboarding rate varies between about 40-60% throughout most of the months. This indicates that our company is performing well overall, as the industry benchmark is 30-50% according to various resources. It is also apparent that the changes made to the platform in mid-September have increased the onboarding rate to about 70%. We observe this positive change in the onboarding rate immediately after the launch and can confidently conclude that the gamification caused the increase.

- **How long do students stay engaged on the platform, and how can this period be extended?**
  - **Free vs. Paying Students:** Free-plan students generally stay engaged for about a week, while paying students remain engaged throughout their subscription period, which can be a month, three months, or a year. For instance, in January’s cohort, only 3% of free-plan students remained engaged the following month. Paying students show higher retention, with about 50% retained after the first month and 35% after the second month.

- **What’s the difference in behavior between free and paid students?**
  - **Content Consumption:** Free-plan students watched an average of 21.06 minutes, equivalent to the unlocked content for each course. Paying students watched and average of 543.7 minutes, which is equivalent to about 2-3 courses, based on the average course length. The average course duration is 3.49 hours (refer to the ‘average_course_duration_query’ SQL query). August saw the highest content consumption due to the three unlocked days, significantly increasing the average minutes watched per free student by about 50%.
  - **Free-to-Paid Conversion Rate:** About 3% of free students who did not watch any content converted to paid plans and about 12% of free students who watched 20-30 minutes of content converted to paid plans. Higher conversions rates were observed with more content watched, reaching up to 45.7%.
  - **Subscription Duration:** There is a positive correlation between the amount of content watched and the subscription duration. Students consuming more content tend to stay subscribed longer.

- **Which are the most popular courses on the platform?**
  - **Total Minutes Watched:** The top 5 courses based on the total minutes watched are:
 1.	‘Introduction to Data and Data Science’ – 297,198 minutes
 2.	‘SQL’ – 215,894 minutes
 3.	‘Statistics’ – 199,006 minutes
 4.	‘Introduction to Excel’ – 194,196 minutes
 5.	‘Python Programmer Bootcamp’ – 150,892 minutes
- **Average Minutes Watched Per Student:** The top 5 courses in this category are:
1.	‘Data Literacy’ – 117.68 minutes per student
2.	‘SQL’ – 114.72 minutes per student
3.	‘Python Programmer Bootcamp’ – 107.55 minutes per student
4.	‘Data Processing with NumPy’ – 99.35 minutes per student
5.	‘Negotiation’ – 84.45 minutes per student
   - **Completion Rate:** The top 5 courses based on completion rate are:
1.	‘Negotiation’ – 95%
2.	‘Marketing Strategy’ – 64%
3.	‘Git and GitHub’ – 49%
4.	‘Mathematics’ – 48%
5.	‘Data Literacy’ – 47%
    - **Course Ratings:** 83.8% of all reviews are 5 stars, 13% are 4 stars, 2.3% are 3 stars, 0.7% are 2 stars, and only 0.2% are 1 star, making the average rating 4.79 stars. This analysis helps identify well-performing courses and pinpoint potential issues with those that have low ratings or engagement, indicating possibly quality problems.

- **How many students sit for an exam?**
  - **Number of Exams Taken:** August had the highest number of exam attempts with 7,234, 64% resulted in a pass and 35.1% resulted in a failure. Among the three exam types (practice, course, and career track), the career track exams had the lowest pass rate with 38.9%.
  - **General Exam Success Rate:** Excluding the August outlier, the general trend of exam attempts increases over the year, with an average of 3,125 exam attempts and an average pass rate of 71.6%. Career track exams had the fewest attempts and the lowest pass rate with only 7 total attempts, 3 of which are passes (42.9% pass rate).
  - **Course and Career Track Certificates Issued:** A total of 3,683 certificates were issued. The number of course certificates were fewer due to the higher difficulty and requirements.
  - **Fraction of Students Completing Career Tracks:** Out of 7,900 enrolled, less than 12% attempted a course exam, and 0.55% earned a career track certificate. Analyzing the statistics for each career track, we can see that about 1.3% of those who enrolled in the Business Analyst career track pass and earn the certificate. For the Data Science career track, 0.5% pass and earn the certificate, and only 0.4% earn the Data Analyst certificate. This analysis concluded that most enrolled students give up at the first step, which requires attempting an exam from the track.

By breaking down each question, we can pinpoint any existing issues and limitations, thereby enabling us to formulate recommendations aimed at improving engagement and retention rates on the platform.

> [!NOTE]
> To find the corresponding data findings, refer to the 'Interpreting the Data' section in the [365 Customer Engagement Analysis Report](365_Customer_Engagement_Analysis_Report.pdf)

## Applying Insights: Recommendations

After analyzing 19,332 engaged students on the platform, we found that 18,032 were free-plan students and 2,178 were paying students, indicating that only about 11% are paying. To increase the number of paying students, which in turn will increase overall engagement, we propose several strategies: 

**Increasing New Students and Engagement:**
- Our registered-to-onboarding rate meets the industry benchmark of 30-50%, varying between 40-60%. This success suggests that our initial engagement is strong. To capitalize on this, we should focus on increasing the number of new students.
- The last three months show approximately a 40% increase in engaged students compared to the beginning months, with about a 33% increase in engaged free students following the August promotion. This indicates that promotions are particularly effective.

**Marketing Campaigns:**
- The August peak for free-plan students, where minutes watched tripled and average minutes watched per student increased by 50%, suggests that targeted campaigns during low engagement periods can boost numbers.

**Gamification and Engagement:**
- Introducing gamification on September 16th increased the onboarding rate to about 70%. By notifying free-plan students of the points they’ve earned by completing the free portions of courses and explaining the benefits of these points, we can use this to pique their interest in purchasing a subscription to continue their learning, thereby enhancing the free-to-paid conversion rate.
- Post-gamification, the average engagement increased by 37% for paying students. We recommend monitoring this trend to ensure it’s not a temporary novelty effect.

**Subscription Duration:**
- Data shows that 17% of students who watched 30-60 minutes of content converted to paying students, and about 42% who watched 2 hours converted, with the highest conversion rates at 45.7% and 41.2% This suggests that increasing content consumption can lead to higher conversions.

**Retention of Paying Students:**
- Approximately half of the paying students are trained after the first month, with 35% remaining active in the second month. However, this drops to about 25% in subsequent periods. Enhancing the value proposition in early months could improve retention.

**Exam Statistics and Career Tracks:**
- Career track exams have low attempt and pass rates, indicating potential barriers. We suggest investigating potential drawbacks, such as exam difficulty or time constraints, and possibly running A/B tests to identify areas of improvements.
- Despite low exam engagement, our course ratings are excellent, averaging 4.79 stars, suggesting that the course content is not the issue.

**Recommendations:**
1.	Increase marketing campaigns during low engagement periods.
2.	Advertise gamification features to boost free-to-paid conversion rates.
3.	Monitor the impact of gamification on engagement to avoid novelty effects.
4.	Investigate and improve the career track exam process to increase pass rates and engagement.
5.	Maintain high course quality while addressing any identified issues from low ratings.

## Contact Information

**Email:** [miguel.pricila98@gmail.com](miguel.pricila98@gmail.com)

**LinkedIn:** [linkedin.com/pricila-miguel](http://www.linkedin.com/in/pricila-miguel-686ab2250)

**Tableau:** [public.tableau.com/pricila.miguel](https://public.tableau.com/app/profile/pricila.miguel/vizzes)
