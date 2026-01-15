select *
from customers;
select *
from subscriptions;
select *
from transactions;
select *
from user_activity;

-- - Find financial churn (who stopped paying ) - LAST payment date for each customer
select customer_id,max(transaction_date) as last_payment_date
from transactions
group by customer_id;

-- -filter out these customers who haven't made a payment in the last 90 days
select customer_id,max(transaction_date) as last_payment_date
from transactions
group by customer_id
having max(transaction_date) < current_date -'90 days';

-- -Finding Engagement Churn (who stopped logging in)
select customer_id, max(event_date) as last_login_date
from user_activity
where event_type ='Login'
group by customer_id;

-- filter users who haven't logged in for 90+ days 
select customer_id, max(event_date) as last_login_date
from user_activity
where event_type ='Login'
group by customer_id
having max(event_date) < current_date - '90 days';

-- -silent churn folks (who pays but doesnt log in)
select t.customer_id,
max(t.transaction_date) as last_payment_date,
max(ua.event_date) as last_login_date
from transactions t 
left join user_activity ua
on t.customer_id = ua.customer_id
group by t.customer_id;

-- -filter these by those who still pay but dont login
select t.customer_id,
max(t.transaction_date) as last_payment_date,
max(ua.event_date) as last_login_date
from transactions t 
left join user_activity ua
on t.customer_id = ua.customer_id
group by t.customer_id
having max(t.transaction_date) >= current_date -'90 days' 
and max(ua.event_date) < current_date - '90 days';

-- -COMBINE EVERYTHING
SELECT c.customer_id,c.name,c.email,
	CASE
		WHEN fc.customer_id IS NOT NULL THEN 'financial_churn'
		WHEN ec.customer_id IS NOT NULL THEN'engagement_churn'
		WHEN sc.customer_id IS NOT NULL THEN 'silent_churn'
		ELSE 'Active'
	END AS churn_type
from customers c
LEFT JOIN (
SELECT customer_id
FROM transactions
GROUP BY customer_id
HAVING MAX(transaction_date) < CURRENT_DATE - '90 days') fc ON c.customer_id = fc.customer_id
LEFT JOIN (
	SELECT customer_id
	from  user_activity
	where event_type = 'Login'
	GROUP BY customer_id
	HAVING MAX(event_date) < CURRENT_DATE - '90 days') ec ON c.customer_id = ec.customer_id 
LEFT JOIN (
select t.customer_id
from transactions t
left join user_activity ua ON t.customer_id = ua.customer_id
GROUP BY t.customer_id
HAVING MAX(t.transaction_date) >= CURRENT_DATE - '90 days' AND MAX(ua.event_date) < CURRENT_DATE - '90 days'
) sc ON c.customer_id = sc.customer_id;
