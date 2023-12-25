/*Data cleaning for table hrdata*/

select* from hrdata;
/*Check data type of all fields in table */
DESCRIBE hrdata;

/*Rename the Field/Column Employees ID */
ALTER TABLE hrdata
CHANGE COLUMN ï»¿id emp_id VARCHAR(20);

/*Re-format date in yyyy-mm-dd */
UPDATE hrdata
SET birthdate = CASE
	WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    ELSE null
END;
/*Change data type of field birthdate to DATE */
ALTER TABLE hrdata
MODIFY COLUMN birthdate DATE;

/*Check the format of of field hire_date and clean data this field yyyy-mm-dd */
/* */
UPDATE hrdata
SET hire_date = CASE
	WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    ELSE null
END;
/*Change data type of field hire_date to DATE */
ALTER TABLE hrdata
MODIFY COLUMN hire_date DATE;

/*Check the format of of field termate and clean data this field yyyy-mm-dd */
/* */
UPDATE hrdata
SET termdate = date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != '';
/*Replace '' to null of field termdate*/
UPDATE hrdata
SET termdate = null
WHERE termdate = '';
/*Change data type of field termdate to DATE */
ALTER TABLE hrdata
MODIFY COLUMN termdate DATE;

/*Create new column name age & Calculate the age of all employee*/
ALTER TABLE hrdata
ADD COLUMN age Int;
/*Calculate the age of all employee*/
UPDATE hrdata
SET age = timestampdiff(YEAR, birthdate, CURDATE());

#########################################################################################################
/*Questions for HR analysis*/
##1. What is the gender breakdown of employees in the company?
##Solution
SELECT gender, count(*) AS total FROM hrdata
WHERE termdate IS NULL OR termdate>= CURDATE()
GROUP BY gender;

##2. What is the race/ethnicity breakdown of employees in the company?
##Solution
SELECT race, COUNT(*) AS total FROM hrdata
WHERE termdate IS NULL OR termdate>= CURDATE()
GROUP BY race;

##3. What is the age distribution of employees in the company?
##Solution
SELECT
	CASE
		WHEN age>=18 AND age<=24 THEN '18-24'
        WHEN age>=25 AND age<=34 THEN '25-34'
        WHEN age>=35 AND age<=44 THEN '35-44'
        WHEN age>=45 AND age<=54 THEN '45-54'
        WHEN age>=55 AND age<=36 THEN '55-64'
        ELSE '65+'
	END AS agegroup,
    gender,
    COUNT(*) AS total
FROM hrdata
WHERE termdate IS NULL OR termdate>= CURDATE()
GROUP BY agegroup, gender
ORDER BY agegroup, gender ASC;
        
##4. How many employees work at headquarters versus remote locations?
##Solution
SELECT location, COUNT(*) AS total FROM hrdata
WHERE termdate IS NULL OR termdate>= CURDATE()
GROUP BY location;

##5. What is the average length of employment for employees who have been terminated?
##Solution 1
SELECT ROUND(AVG(DATEDIFF(termdate,hire_date)/365)) AS avg_length_employment
FROM hrdata
WHERE termdate IS NOT NULL AND termdate <= CURDATE();
##Solution 2
SELECT ROUND(AVG(year(termdate) - year(hire_date))) AS avg_length_employment
FROM hrdata
WHERE termdate IS NOT NULL AND termdate <= CURDATE();

##6. How does the gender distribution vary across departments and job titles?
##Solution
SELECT department, jobtitle, gender, COUNT(*) AS total
FROM hrdata
WHERE termdate IS NULL OR termdate>= CURDATE()
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender;

##7. What is the distribution of job titles across the company?
##Solution
SELECT jobtitle, COUNT(*) AS total
FROM hrdata
WHERE termdate IS NULL OR termdate >= CURDATE()
GROUP BY jobtitle
ORDER BY jobtitle;

##8. Which department has the highest turnover rate?
##Solution
SELECT 	department,
		COUNT(*) AS total,
		COUNT(		CASE
					WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1
					END) AS terminated_total,
		ROUND((COUNT(CASE
					WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1
					END)/COUNT(*))*100,2) AS terminated_percentage
FROM hrdata
GROUP BY department
ORDER BY terminated_percentage DESC;

##9. What is the distribution of employees across locations by state?
##Solution
SELECT location_state, COUNT(*) as total
FROM hrdata
WHERE termdate IS NULL OR termdate >= CURDATE()
GROUP BY location_state
ORDER BY location_state ASC;

##10. How has the company's employee count changed over time based on hire and term dates?
##Solution
SELECT 	year,
		hired_hc,
        terminated_hc,
        hired_hc - terminated_hc AS changed_hc,
        ROUND((terminated_hc/hired_hc)*100,2) AS percent_hc
FROM(
		SELECT	YEAR(hire_date) AS year,
				COUNT(*) AS hired_hc,
                COUNT(	CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1
						END) AS terminated_hc
		FROM hrdata
        GROUP BY year) AS subquery
GROUP BY year
ORDER BY year;

##11. What is the tenure distribution for each department?
##Solution
SELECT department, ROUND(AVG(DATEDIFF(termdate, hire_date)/365),0) AS tenure_distribution
FROM hrdata
WHERE termdate IS NOT NULL AND termdate <= CURDATE()
GROUP BY department;

##12. What is the terminated rate by gender?
SELECT gender,
		COUNT(CASE
				WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1
				END) AS terminated_hc,
		ROUND((COUNT(CASE
				WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1
				END)/COUNT(*)*100),2) AS terminated_percent
FROM hrdata
GROUP BY gender;

##13. Terminated rate by Age group
SELECT
	CASE
		WHEN age>=18 AND age<=24 THEN '18-24'
        WHEN age>=25 AND age<=34 THEN '25-34'
        WHEN age>=35 AND age<=44 THEN '35-44'
        WHEN age>=45 AND age<=54 THEN '45-54'
        WHEN age>=55 AND age<=36 THEN '55-64'
        ELSE '65+'
	END AS agegroup,
    gender,
    ROUND((COUNT(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 END)/COUNT(*))*100,2) AS terminated_rate
FROM hrdata
GROUP BY agegroup, gender
ORDER BY agegroup, gender ASC;

SELECT
	CASE
		WHEN age>=18 AND age<=24 THEN '18-24'
        WHEN age>=25 AND age<=34 THEN '25-34'
        WHEN age>=35 AND age<=44 THEN '35-44'
        WHEN age>=45 AND age<=54 THEN '45-54'
        WHEN age>=55 AND age<=36 THEN '55-64'
        ELSE '65+'
	END AS agegroup,
    ROUND((COUNT(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 END)/COUNT(*))*100,2) AS terminated_rate
FROM hrdata
GROUP BY agegroup
ORDER BY agegroup ASC;

#########################################################################################################
/*
## Summary of Findings
 - There are more male employees
 - White race is the most dominant while Native Hawaiian and American Indian are the least dominant.
 - The youngest employee is 20 years old and the oldest is 57 years old
 - 5 age groups were created (18-24, 25-34, 35-44, 45-54, 55-64). A large number of employees were between 25-34 followed by 35-44 while the smallest group was 55-64.
 - A large number of employees work at the headquarters versus remotely.
 - The average length of employment for terminated employees is around 7 years.
 - The gender distribution across departments is fairly balanced but there are generally more male than female employees.
 - The Marketing department has the highest turnover rate followed by Training. The least turn over rate are in the Research and development, Support and Legal departments.
 - A large number of employees come from the state of Ohio.
 - The net change in employees has increased over the years.
- The average tenure for each department is about 8 years with Legal and Auditing having the highest and Services, Sales and Marketing having the lowest.

## Limitations
- Some records had negative ages and these were excluded during querying(967 records). Ages used were 18 years and above.
- Some termdates were far into the future and were not included in the analysis(1599 records). The only term dates used were those less than or equal to the current date.
*/