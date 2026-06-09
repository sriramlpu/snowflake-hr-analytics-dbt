# HR Analytics with Snowflake + dbt

Workforce analytics on the IBM HR Employee Attrition dataset (Kaggle).

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=flat&logo=snowflake&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-FF694B?style=flat&logo=dbt&logoColor=white)

## Dataset
IBM HR Analytics: 1,470 employees, 35 features including job role, satisfaction, income, attrition.
Source: https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset

## Project Structure
```
snowflake-hr-analytics-dbt/
├── setup/snowflake_setup.sql
├── dbt_project/models/
│   ├── staging/stg_employees.sql
│   └── marts/
│       ├── core/fct_attrition.sql
│       └── hr/workforce_kpis.sql
└── analyses/business_questions.sql
```

## Business Questions & Answers

### Q1. Attrition rate by department
[analyses/business_questions.sql](analyses/business_questions.sql)
Sales 21%, R&D 14%, HR 19%. COUNT+CASE aggregation.

### Q2. Job roles with highest attrition
[analyses/business_questions.sql](analyses/business_questions.sql)
Sales Rep 40%, Lab Tech 24%. Ordered by attrition_rate DESC.

### Q3. Overtime vs attrition correlation
[analyses/business_questions.sql](analyses/business_questions.sql)
OT employees: 31% attrition. Non-OT: 10%. 3x difference.

### Q4. Salary band vs attrition (NTILE)
[analyses/business_questions.sql](analyses/business_questions.sql)
NTILE(4) quartiles: Q1 = 26% attrition, Q4 = 8%.

### Q5. Average tenure by department
[analyses/business_questions.sql](analyses/business_questions.sql)
AVG(years_at_company) GROUP BY department. HR: 7.2 yrs average.

### Q6. Attrition risk scoring
[dbt_project/models/marts/hr/workforce_kpis.sql](dbt_project/models/marts/hr/workforce_kpis.sql)
Composite score: overtime + low JobSatisfaction + low income + high DistanceFromHome.

### Q7. Promotion gap analysis
[analyses/business_questions.sql](analyses/business_questions.sql)
DATEDIFF on last promotion. 5+ years gap = 2x attrition rate.

### Q8. Department attrition cohort (window functions)
[analyses/business_questions.sql](analyses/business_questions.sql)
SUM(is_attrition) OVER (PARTITION BY department ORDER BY hire_year).

## Key Snowflake Features
- PIVOT for department performance comparison matrix
- - QUALIFY + ROW_NUMBER() for latest employee record
  - - ASOF JOIN for historical salary comparisons
    - - OBJECT_CONSTRUCT for employee JSON profiles
     
      - ## dbt Features
      - - Snapshot model: tracks SCD-2 changes to employee status
        - - Incremental model with hire_date watermark
          - - Custom macro: `{{ attrition_rate(numerator, denominator) }}`
            - - Singular test: no employee has negative tenure
