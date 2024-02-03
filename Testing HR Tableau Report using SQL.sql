
-- Employee Count:
SELECT sum(employee_count) as employee_count from hr_data;
-- WHERE education = 'High School';
-- WHERE department = 'R&D';
-- WHERE education_field = 'Medical';

-- Attrition Count:
SELECT count(attrition) as attrition_count from hr_data
WHERE attrition = 'Yes';-- and department = 'R&D' and education_field = 'Medical' and education = 'High School';

-- Attrition Rate:
select 
round(((SELECT count(attrition) from hr_data WHERE attrition = 'Yes')/sum(employee_count))*100, 2) from hr_data
-- WHERE department = 'Sales'
;

-- Active Employee:
SELECT 
sum(employee_count)-(select count(attrition) from hr_data WHERE attrition = 'Yes') -- and gender='Male') 
as active_employee 
from hr_data
-- where gender='Male'
;

-- Average Age:
select round(avg(age),0) as Avg_age from hr_data
;

select gender, count(attrition) 
from hr_data
where attrition='Yes' -- and eduction='High School'
group by gender
order by count(attrition) desc
;

-- Department wise Attrition:
SELECT department, count(attrition),
round((count(attrition)/(select count(attrition) from hr_data where attrition='Yes' -- and gender='Female', = count/total count
))*100,2) as percentage
from hr_data
where attrition='Yes' -- and gender='Female'
group by department
order by count(attrition) desc
-- if output for pecentage are 0, count(attrition) need to be converted to number
-- round((cast(count(attrition) as numeric)/(select count(attrition) from hr_data where attrition='Yes')*100,2) as percentage
;

-- Number of Employee by Age Group:
SELECT age, sum(employee_count) as employee_count 
FROM hr_data
-- where department='R&D'
Group by age
Order by age
;

-- Education Field wise Attrition:
SELECT education_field, count(attrition) as attribution_count
from hr_data
where attrition='Yes' -- and department='Sales'
group by education_field
order by count(attrition) desc
;

-- Attrition Rate by Gender for different Age Group:
SELECT age_band, gender, count(attrition) as attrition,
round(count(attrition)/(select count(attrition) from hr_data where attrition='Yes')*100,2) as percentage
from hr_data
where attrition='Yes'
group by age_band, gender
order by age_band, gender desc
-- if output for pecentage are 0, count(attrition) need to be converted to number
-- round((cast(count(attrition) as numeric)/(select count(attrition) from hr_data where attrition='Yes')*100,2) as percentage
;

-- Job Satisfaction Rating:

SELECT  job_role, job_satisfaction, sum(employee_count)
from hr_data
group by job_role, job_satisfaction
order by job_role, job_satisfaction; 

CREATE VIEW job_satisfaction_rating AS 
SELECT 
	job_role,
    SUM(CASE WHEN job_satisfaction = 1 THEN employee_count ELSE 0 END) AS One,
    SUM(CASE WHEN job_satisfaction = 2 THEN employee_count ELSE 0 END) AS Two,
    SUM(CASE WHEN job_satisfaction = 3 THEN employee_count ELSE 0 END) AS Three,
    SUM(CASE WHEN job_satisfaction = 4 THEN employee_count ELSE 0 END) AS Four
FROM hr_data
Group by job_role
Order by job_role
;
    

    














