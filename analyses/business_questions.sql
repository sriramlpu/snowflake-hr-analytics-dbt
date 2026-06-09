-- HR Analytics Business Questions SQL

-- Q1. Attrition rate by department
SELECT department,
    COUNT(*) AS employees,
    SUM(CASE WHEN attrition='Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0*SUM(CASE WHEN attrition='Yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS attrition_pct,
    ROUND(AVG(monthly_income),0) AS avg_income
FROM HR_DB.MARTS.fct_attrition
GROUP BY 1 ORDER BY attrition_pct DESC;

-- Q2. Job roles with highest attrition
SELECT job_role, department,
    COUNT(*) AS total,
    ROUND(100.0*SUM(CASE WHEN attrition='Yes' THEN 1 ELSE 0 END)/COUNT(*),1) AS attrition_pct
FROM HR_DB.MARTS.fct_attrition GROUP BY 1,2 ORDER BY attrition_pct DESC;

-- Q3. Overtime vs attrition correlation
SELECT over_time,
    COUNT(*) AS employees,
    ROUND(100.0*SUM(CASE WHEN attrition='Yes' THEN 1 ELSE 0 END)/COUNT(*),1) AS attrition_pct,
    ROUND(AVG(work_life_balance),2) AS avg_wlb
FROM HR_DB.MARTS.fct_attrition GROUP BY 1 ORDER BY attrition_pct DESC;

-- Q4. Salary quartile vs attrition (NTILE)
WITH banded AS (
      SELECT employee_number, attrition, monthly_income,
          NTILE(4) OVER (ORDER BY monthly_income) AS quartile
      FROM HR_DB.MARTS.fct_attrition
  )
SELECT
    CASE quartile WHEN 1 THEN 'Q1-Low' WHEN 2 THEN 'Q2-Mid-Low'
                  WHEN 3 THEN 'Q3-Mid-High' ELSE 'Q4-High' END AS income_band,
    COUNT(*) AS employees,
    ROUND(100.0*SUM(CASE WHEN attrition='Yes' THEN 1 ELSE 0 END)/COUNT(*),1) AS attrition_pct
FROM banded GROUP BY quartile, income_band ORDER BY quartile;

-- Q5. Average tenure by department
SELECT department, job_level,
    ROUND(AVG(years_at_company),1) AS avg_tenure,
    ROUND(AVG(years_since_last_promotion),1) AS avg_yrs_since_promo,
    ROUND(AVG(monthly_income),0) AS avg_income
FROM HR_DB.MARTS.fct_attrition WHERE attrition='No'
GROUP BY 1,2 ORDER BY 1,2;

-- Q7. Promotion gap attrition analysis
SELECT
    CASE WHEN years_since_last_promotion=0 THEN '0 (recent)'
         WHEN years_since_last_promotion<=2 THEN '1-2 yrs'
         WHEN years_since_last_promotion<=5 THEN '3-5 yrs'
         ELSE '5+ yrs (high risk)' END AS promo_gap,
    COUNT(*) AS employees,
    ROUND(100.0*SUM(CASE WHEN attrition='Yes' THEN 1 ELSE 0 END)/COUNT(*),1) AS attrition_pct
FROM HR_DB.MARTS.fct_attrition GROUP BY 1 ORDER BY attrition_pct DESC;

-- Q8. Cumulative attrition by department + hire year (window function)
SELECT department, hire_year,
    COUNT(*) AS headcount,
    SUM(CASE WHEN attrition='Yes' THEN 1 ELSE 0 END) AS annual_attrition,
    SUM(SUM(CASE WHEN attrition='Yes' THEN 1 ELSE 0 END)) OVER (
          PARTITION BY department ORDER BY hire_year
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_attrition
FROM HR_DB.MARTS.fct_attrition
GROUP BY 1,2 ORDER BY 1,2;
