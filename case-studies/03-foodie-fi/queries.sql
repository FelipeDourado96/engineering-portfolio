

-- A. Customer Journey

-- 1. Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

SELECT 
    s.customer_id,
    p.plan_id,
    p.plan_name,
    s.start_date
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p
  ON s.plan_id = p.plan_id
WHERE s.customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)
ORDER BY s.customer_id, s.start_date;

/*
Individual Customer Journeys:
- Customer 1: Started with a 7-day free trial on 2020-08-01, then converted directly to a Basic Monthly plan on 2020-08-08.
- Customer 2: Completed the trial and upgraded directly to Pro Annual on 2020-09-27, showing high initial commitment.
- Customer 11: Churned immediately after the 7-day trial expired on 2020-11-26 without converting to any paid plan.
- Customer 13: Subscribed to Basic Monthly after trial (2020-12-22) and upgraded to Pro Monthly ~3 months later (2021-03-29).
- Customer 15: Upgraded to Pro Monthly post-trial (2020-03-24), but churned about a month later on 2020-04-29.
- Customer 16: Gradual upgrade path; converted from trial to Basic Monthly (2020-06-07) and later upgraded to Pro Annual (2020-10-21).
- Customer 18: Converted from trial straight into a Pro Monthly subscription on 2020-07-13.
- Customer 19: Upgraded to Pro Monthly after trial (2020-06-29) and upgraded to Pro Annual two months later (2020-08-29).

Key Insights & Patterns:
1. 100% of customers begin with a 7-day free trial.
2. Trial-to-Paid Conversion: 7 out of 8 (87.5%) converted to a paid tier; only Customer 11 churned right after trial.
3. Annual Upgrades: 3 customers (37.5%) eventually committed to Pro Annual — Customer 2 directly post-trial, and Customers 16 & 19 via gradual expansion.
4. Churn Behavior: 2 customers (25%) churned — one immediately post-trial (Customer 11) and one after a month of Pro Monthly (Customer 15).



-- B. Data Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name


-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?


-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?


-- 6. What is the number and percentage of customer plans after their initial free trial?


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?


-- 8. How many customers have upgraded to an annual plan in 2020?


-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?


-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)


-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?



-- C. Challenge Payment Question

-- 1. The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
    -- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
    -- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
    -- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
    -- once a customer churns they will no longer make payments




-- D. Outside the Box Questions

-- 1. How would you calculate the rate of growth for Foodie-Fi?
    

-- 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
    

-- 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
    

-- 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
    

-- 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?




-- E