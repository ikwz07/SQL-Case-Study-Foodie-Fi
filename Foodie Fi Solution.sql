
/* Custome Journey */
# Based off the sample customers provided in the sample from the subscriptions table, 
# write a brief description about each customer’s onboarding journey.

SELECT p.plan_name, s.customer_id, s.start_date
FROM subscriptions AS s 
JOIN plans AS p on s.plan_id = p.plan_id;

# Case Study Questions

/* 1. How many customers has Foodie-Fi ever had? */

SELECT COUNT(DISTINCT(customer_id)) AS number_of_customers
FROM subscriptions;

/* 2. What is the monthly distribution of trial plan start_date values for our dataset - 
use the start of the month as the group by value */

# 1. Solution

SELECT 
    DATE_FORMAT(start_date, '%Y-%m-01') AS Starting_Month,
    COUNT(plan_id) AS trial_count
FROM
    subscriptions
WHERE
    plan_id = 0
GROUP BY DATE_FORMAT(start_date, '%Y-%m-01')
ORDER BY Starting_Month;

# 2. Solution 

SELECT MONTH(start_date) AS starting_months, COUNT(customer_id) AS customer_num
FROM subscriptions
WHERE plan_id = 0
GROUP BY starting_months
ORDER BY starting_months ASC;

/* 3. What plan 'start_date' values occur after the year 2020 for our dataset? Show the 
breakdown by count of events for each 'plan_name' */

SET sql_mode = '';

SELECT p.plan_id, p.plan_name, COUNT(*) AS event_count 
FROM subscriptions AS s
JOIN plans AS p ON p.plan_id = s.plan_id
WHERE
	EXTRACT(YEAR FROM start_date) > 2020
GROUP BY p.plan_name
ORDER BY p.plan_name ASC;

/* 4. What is the customer count and percentage of customers who have churned the 
rounded to 1 decimal place?*/

SELECT
    COUNT(DISTINCT customer_id) AS Total_Customers,
    COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) AS Churned,
	CONCAT(ROUND(100.0 * SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) / 
		   COUNT(DISTINCT customer_id), 1), '%') AS Churn_Rate_Percentages
FROM subscriptions;

/* 5. How many customers have churned straight after their initial free trial - 
what percentage is this rounded to the nearest whole number? */

WITH cte_churn AS (
SELECT *, LAG(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) AS prev_plan 
FROM subscriptions) 

SELECT COUNT(prev_plan) AS churn_count, 
ROUND(COUNT(*) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) AS chrun_percentage
FROM cte_churn
WHERE plan_id = 4 AND prev_plan = 0;

/* 6. What is the number and percentage of customer plans after their initial free trial? */

WITH cte_next_plan AS (
SELECT *, LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) AS next_plan 
FROM subscriptions)

SELECT next_plan, COUNT(*) AS num_customer,
ROUND(COUNT(*) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS percentage_next_plan
FROM cte_next_plan
WHERE next_plan IS NOT NULL AND plan_id = 0
GROUP BY next_plan
ORDER BY next_plan;

/* 7. What is the customer count and percentage breakdown of all 5 plan_name 
values at 2020–12–31?*/

WITH cte_next_date AS (
    SELECT *, 
    LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date 
    FROM subscriptions 
    WHERE start_date <= '2020-12-31'
),
plans_breakdown AS (
    SELECT plan_id, 
	COUNT(DISTINCT CASE WHEN next_date > '2020-12-31' 
    OR next_date IS NULL THEN customer_id END) AS num_customer
    FROM cte_next_date
    GROUP BY plan_id
)

SELECT plan_id, 
       num_customer,
       ROUND(num_customer * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS percentage_of_customer
FROM plans_breakdown
ORDER BY plan_id;

/* 8. How many customers have upgraded to an annual in 2020?*/

# 1. Solution

SELECT COUNT(*) AS upgraded_customers_count
FROM subscriptions AS s
JOIN plans AS p ON p.plan_id = s.plan_id
WHERE
    p.plan_name = 'pro annual' 
    AND EXTRACT(YEAR FROM s.start_date) = 2020;

# 2. Solution
    
SELECT COUNT(*) AS upgraded_customers_count
FROM subscriptions AS s
WHERE
    s.plan_id = (SELECT plan_id FROM plans WHERE plan_name = 'pro annual') 
    AND EXTRACT(YEAR FROM s.start_date) = 2020;

# 3. Solution

SELECT COUNT(customer_id) AS num_customer FROM subscriptions 
WHERE plan_id = 3 AND start_date <= DATE_FORMAT(start_date, '2020-%m-%d');

/* 9. How many days on average does it take for a customer to an annual plan from the 
day they joined Foodie-Fi?*/

# 1. Solution

WITH annual_plan AS (SELECT customer_id, start_date AS annual_date FROM subscriptions 
WHERE plan_id = 3), 

trial_plan AS (SELECT customer_id, start_date AS trial_date FROM subscriptions 
WHERE plan_id = 0) 

SELECT ROUND(AVG(DATEDIFF(annual_date, trial_date)), 0) AS avg_upgrade
FROM annual_plan ap JOIN trial_plan tp ON ap.customer_id = tp.customer_id;

# 2. Solution

SELECT ROUND(AVG(DATEDIFF(ap.start_date, tp.start_date)), 0) AS avg_upgrade
FROM subscriptions ap
JOIN subscriptions tp ON ap.customer_id = tp.customer_id
WHERE ap.plan_id = 3 -- Annual Plan
AND tp.plan_id = 0; -- Trial Plan


/* 10. Can you further breakdown this average value into 30 day 
periods (i.e. 0-30 days, 31-60 days etc) */

# 1. Solution

WITH annual_plan AS (
  SELECT customer_id, start_date AS annual_date
  FROM subscriptions
  WHERE plan_id = 3
),

trial_plan AS (
  SELECT customer_id, start_date AS trial_date
  FROM subscriptions
  WHERE plan_id = 0
),

day_period AS (
  SELECT DATEDIFF(annual_date, trial_date) AS diff
  FROM trial_plan AS tp
  LEFT JOIN annual_plan AS ap ON tp.customer_id = ap.customer_id
  WHERE annual_date IS NOT NULL
),

bins AS (
  SELECT *,
         CEIL(diff / 30) - 1 AS bins
  FROM day_period
)

SELECT CONCAT(bins * 30 + 1, ' - ', (bins + 1) * 30, ' days') AS days,
       COUNT(diff) AS total
FROM bins
GROUP BY bins
ORDER BY bins;  -- Optional: Order by bins for consistent output

# 2. Solution

SELECT 
    CONCAT(((FLOOR(DATEDIFF(ap.start_date, tp.start_date) / 30) * 30) + 1), '-', 
           ((FLOOR(DATEDIFF(ap.start_date, tp.start_date) / 30) * 30) + 30), ' days') AS period,
    COUNT(*) AS customers_count
FROM subscriptions ap
JOIN subscriptions tp ON ap.customer_id = tp.customer_id
    AND ap.plan_id = 3 -- Annual Plan
    AND tp.plan_id = 0 -- Trial Plan
GROUP BY FLOOR(DATEDIFF(ap.start_date, tp.start_date) / 30)
ORDER BY MIN(FLOOR(DATEDIFF(ap.start_date, tp.start_date) / 30));

/* 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020? */

WITH next_plan AS (
SELECT *, LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date, plan_id) AS plan 
FROM subscriptions)

SELECT COUNT(DISTINCT customer_id) AS num_downgrade
FROM next_plan AS np
LEFT JOIN plans AS p ON p.plan_id = np.plan_id
WHERE p.plan_name = 'pro monthly' AND np.plan = 1 
AND start_date <= DATE_FORMAT(start_date, '2020-%m-%d');  