-- workforce_kpis.sql: Attrition Risk Scoring + Dept KPIs

{{ config(materialized='table') }}

WITH base AS (
      SELECT * FROM {{ ref('stg_employees') }}
  ),

risk_scored AS (
      SELECT
          employee_number, department, job_role, job_level,
          over_time, monthly_income, job_satisfaction,
          environment_satisfaction, work_life_balance,
          distance_from_home, years_at_company,
          years_since_last_promotion, attrition,

        -- Composite risk score (0-10)
        (CASE WHEN over_time='Yes'             THEN 2 ELSE 0 END
         + CASE WHEN job_satisfaction<=2          THEN 2 ELSE 0 END
         + CASE WHEN environment_satisfaction<=2  THEN 1 ELSE 0 END
         + CASE WHEN work_life_balance<=2         THEN 1 ELSE 0 END
         + CASE WHEN monthly_income<3000          THEN 2 ELSE 0 END
         + CASE WHEN distance_from_home>20        THEN 1 ELSE 0 END
         + CASE WHEN years_since_last_promotion>5 THEN 1 ELSE 0 END
          ) AS attrition_risk_score,

        CASE
              WHEN (CASE WHEN over_time='Yes' THEN 2 ELSE 0 END
                  + CASE WHEN job_satisfaction<=2 THEN 2 ELSE 0 END
                  + CASE WHEN monthly_income<3000 THEN 2 END
                  + CASE WHEN distance_from_home>20 THEN 1 ELSE 0 END) >= 6 THEN 'High Risk'
              WHEN (CASE WHEN over_time='Yes' THEN 2 ELSE 0 END
                  + CASE WHEN job_satisfaction<=2 THEN 2 ELSE 0 END) >= 3 THEN 'Medium Risk'
              ELSE 'Low Risk'
          END AS risk_category,

        -- Dept-level window KPIs
        COUNT(*) OVER (PARTITION BY department) AS dept_headcount,
          ROUND(AVG(monthly_income) OVER (PARTITION BY department),0) AS dept_avg_income,
          ROUND(AVG(job_satisfaction) OVER (PARTITION BY department),2) AS dept_avg_satisfaction,
          ROUND(AVG(years_at_company) OVER (PARTITION BY department),1) AS dept_avg_tenure,
          PERCENT_RANK() OVER (PARTITION BY department ORDER BY monthly_income) AS income_pct_rank,
          CURRENT_TIMESTAMP() AS _loaded_at
      FROM base
  )

SELECT * FROM risk_scored
