-------------------------------------------------------------------------------------------------------------------------------------------------------
Create DataBase Human_Resourse;
Use Human_Resourse;

					-- To Inport The CSV file to MySQL 
-- Right Click on Database and select "Table Data Inport Wizard"
-- Browse the CSV file
-- Click on Next >>>> until Finished

select * from hr;
-------------------------------------------------------------------------------------------------------------------------------------------------------
					
                    -- EDA (exploratory data analysis)
set sql_safe_updates = 0;

		-- Rename the column

Alter table hr
change column ï»¿id id varchar(15);

		-- Correct the data types

Update hr 
set birthdate = Case 
	When birthdate like "%/%/%" then str_to_date(birthdate, '%m/%d/%Y')
    when birthdate like "%-%-%" then str_to_date(birthdate, '%m-%d-%Y')
    else null
End;

Alter table hr 
modify column birthdate date;

Update hr 
set hire_date = Case 
	When hire_date like "%/%/%" then str_to_date(hire_date, '%m/%d/%Y')
    when hire_date like "%-%-%" then str_to_date(hire_date, '%m-%d-%Y')
    else null
End;

Alter table hr 
modify column hire_date date;

UPDATE hr
SET termdate = IF(termdate IS NOT NULL AND termdate != '', date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC')), '0000-00-00')
WHERE true;

SET sql_mode = 'ALLOW_INVALID_DATES';

ALTER TABLE hr
MODIFY COLUMN termdate DATE;

		-- Adding more columns

Alter table hr 
ADD column age int ;

UPDATE hr 
set age = timestampdiff(Year, birthdate, date(now()));

Alter table hr 
Add column AgeGroup varchar(10) ;

UPDATE hr 
set AgeGroup = case
	when age between 21 and 30 then "21-30"
    when age between 31 and 40 then '31-40'
    when age between 41 and 50 then '41-50'
    when age between 51 and 60 then '51-60'
    else age
end;

		-- Checking for null and Duplicate vlaues in data

select id, count(*) from hr 
group by id 		-- no duplicates values
having count(*)>1;

select id from hr 
where id is null or id like ''; 		-- no null values

set sql_safe_updates = 1;
-------------------------------------------------------------------------------------------------------------------------------------------------------
								-- Exploring the data

select * from hr;

select age
from hr 		-- 967 rows are having negetive age (need to ignore that)
where age <= 0;

select * 
from hr 		-- 17482 employees are currently working
where termdate like '0000-00-00' and age >= 0;

select * 
from hr 		-- 2431 employees are terminated till date
where termdate not like '0000-00-00' and age >= 0 and termdate < curdate();

-------------------------------------------------------------------------------------------------------------------------------------------------------
/*		
					Questions
                    
What is the gender breakdown of employees in the company?
What is the race/ethnicity breakdown of employees in the company?
What is the age distribution of employees in the company?
How many employees work at headquarters versus remote locations?
What is the average length of employment for employees who have been terminated?
How does the gender distribution vary across departments and job titles?
What is the distribution of job titles across the company?
Which department has the highest termination rate?
What is the distribution of employees across locations by state?
How has the company's employee count changed over time based on hire and term dates?
What is the tenure distribution for each department?
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. What is the gender breakdown of employees in the company?

select gender, count(*) as Gender_count
from hr
where termdate like '0000-00-00' and age >= 0
group by gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?

select race, count(*) as race_count
from hr
where termdate like '0000-00-00' and age >= 0
group by race order by race_count desc;

-- 3. What is the age/gender distribution of employees in the company?

select AgeGroup, count(*) as emp_count
from hr
where termdate like '0000-00-00' and age >= 0
group by AgeGroup;  

select AgeGroup, gender, count(*) as emp_count
from hr
where termdate like '0000-00-00' and age >= 0
group by AgeGroup, gender;

-- 4. How many employees work at headquarters versus remote locations?

select location, count(*) as emp_count
from hr
where termdate like '0000-00-00' and age >= 0
group by location;

-- 5. What is the average length of employment for employees who have been terminated?

select 
		FLOOR(AVG(timestampdiff(year,hire_date, termdate))) as avg_employeement
from hr 
where termdate not like '0000-00-00' and age >= 0 and termdate <= current_date();

-- 6. How does the gender distribution vary across departments and job titles?

select Department, Gender, count(*) as emp_count
from hr
where termdate like '0000-00-00' and age >= 0
group by Department, Gender
order by department;

select JobTitle, Gender, count(*) as emp_count
from hr
where termdate like '0000-00-00' and age >= 0
group by Gender, JobTitle
order by jobtitle;

-- 7. What is the distribution of job titles across the company?

select JobTitle, count(*) as emp_count
from hr
where termdate like '0000-00-00' and age >= 0
group by JobTitle
order by JobTitle;

-- 8. Which department has the highest termdate rate?

WITH table_cte as 
	(
select department, count(*) as emp_count,
sum(case when termdate not like '0000-00-00' and termdate <= curdate() then 1 else 0 end) as terminated_emp_count
from hr
where age > 0 
group by department
	)
select department, round(emp_count / terminated_emp_count, 2) as termination_rate
from table_cte
order by termination_rate desc;

-- 9. What is the distribution of employees across locations by state?

select location_state, count(*) as emp_count
from hr
where age > 0 and termdate like '0000-00-00'
group by location_state;

-- 10. How has the company's employee count changed over time based on hire and term dates?

with table_cte as 
	(
select YEAR(hire_date) as year, count(*) as hired_emp, 
sum(case when termdate not like '0000-00-00' and termdate <= curdate() then 1 else 0 end) as terminated_emp
from hr
group by year order by year asc
	)
select *, 
round((terminated_emp / hired_emp) * 100, 2) as termination_percentage
from table_cte;

-- 11. What is the tenure distribution for each department?

select department, 
floor(avg(timestampdiff(year, hire_date, termdate))) as avg_tenure
from hr
where age > 0 and termdate not like '0000-00-00' and termdate <= date(now())
group by department;

select  floor(avg(timestampdiff(year, hire_date, termdate))) as avg_tenure
from hr;
-------------------------------------------------------------------------------------------------------------------------------------------------------
