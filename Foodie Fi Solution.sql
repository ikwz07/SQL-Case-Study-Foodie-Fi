/* Custome Journey */
SELECT p.plan_name, s.customer_id, s.start_date
FROM subscriptions AS s 
JOIN plans AS p on s.plan_id = p.plan_id;

/* How many customers has Foodie-Fi ever had? */

SELECT COUNT(DISTINCT(customer_Id)) AS customers_num
FROM subscriptions;

/*What is the monthly distribution of trial plan start_date values for our dataset — 
use the start of the month as the GROUP BY value */

SELECT 
    DATE_FORMAT(start_date, '%Y-%m-01') AS Starting_Month,
    COUNT(plan_id) AS trial_count
FROM
    subscriptions
WHERE
    plan_id = 0
GROUP BY DATE_FORMAT(start_date, '%Y-%m-01')
ORDER BY Starting_Month;


SELECT MONTH(start_date) AS months, COUNT(customer_id) AS num_customers 
FROM subscriptions
GROUP BY months
ORDER BY months ASC;

/* What plan ‘start_date’ values occur after the year 2020 for our dataset? Show the breakdown by 
count of events for each ‘plan_name’.*/

SELECT p.plan_name, p.plan_id, COUNT(*) AS event_count 
FROM subscriptions AS s
JOIN plans AS p ON p.plan_id = s.plan_id
WHERE
	EXTRACT(YEAR FROM start_date) > 2020
GROUP BY p.plan_name;



/*What is the customer count and percentage of customers who have churned the rounded to 1 decimal place?*/

SELECT
    COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) AS Churned,
    COUNT(DISTINCT customer_id) AS Total_Customers,
    CONCAT(ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) /
        COUNT(DISTINCT customer_id),
        1
    ), '%') AS Churn_Rate_Percentage
FROM subscriptions;

/* How many the customers have churned straight after their initial free trial — 
what the percentage is this rounded to the nearest whole number? */

/* 6. What is the number and percentage of customer plans after their initial free trial? */


/*7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020–12–31?*/


/* 8. How many customers have upgraded to an annual in 2020?*/

SELECT COUNT(*) AS upgraded_customers_count
FROM subscriptions AS s
JOIN plans AS p ON p.plan_id = s.plan_id
WHERE
    p.plan_name = 'pro annual' 
    AND EXTRACT(YEAR FROM s.start_date) = 2020;

/* 9. How many days on average does it take for a customer to an annual plan from the day they joined Foodie-Fi?*/


