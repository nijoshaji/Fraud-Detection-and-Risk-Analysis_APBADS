# 1. Customer Risk Analysis: Identify customers with low credit scores and high-risk loans to 
#predict potential defaults and prioritize risk mitigation strategies.

select *
from customer c join loan l 
on c.customer_id = l.customer_id
where c.credit_score < (select avg(c2.credit_score) from customer c2)
and l.default_risk = 'High'
order by c.credit_score , l.loan_amount desc;

#2. Loan Purpose Insights: Determine the most popular loan purposes and their associated revenues to 
#align financial products with customer demands

select loan_purpose, count(*) as loan_number,
sum(loan_amount) as total_loan
from loan
group by loan_purpose
order by loan_number desc;

#3.High-Value Transactions: Detect transactions that exceed 30% of their respective loan amounts to
# flag potential fraudulent activities

select t.transaction_id, t.loan_id,
t.transaction_amount, l.loan_amount
from transaction t left join loan l
on t.loan_id = l.loan_id
where t.transaction_amount > 0.3 * l.loan_amount;

#4. Missed EMI Count: Analyze the number of missed EMIs per loan to identify loans at risk of 
#default and suggest intervention strategies

select loan_id, count(transaction_type) as transactions_number
from transaction
where transaction_type = 'Missed EMI'
group by loan_id
order by transactions_number desc;

#5. Regional Loan Distribution: Examine the geographical distribution of loan disbursements to assess 
#regional trends and business opportunities.

select left(right(address,8),2) as state, count(*) as number_of_loans,
sum(l.loan_amount) as total_amount
from customer c join loan l
on c.customer_id = l.customer_id
group by state
order by number_of_loans desc;

# 6. Loyal Customers: List customers who have been associated with Cross River Bank for over five years 
#and evaluate their loan activity to design loyalty programs.

select customer_id, name, age, active_loans, customer_since
from customer
where STR_TO_DATE(customer_since, '%m/%d/%Y') < date_sub(curdate(), interval 5 year)
order by customer_since;

# 7. High-Performing Loans: Identify loans with excellent repayment histories to refine lending 
#policies and highlight successful products.

select * 
from loan
where repayment_history > 8
order by repayment_history desc;

# 8. Age-Based Loan Analysis: Analyze loan amounts disbursed to customers of different age groups 
#to design targeted financial products.

select 
	case
		when c.age between 18 and 24 then '18-24'
        when c.age between 25 and 35 then '25-35'
        when c.age between 36 and 50 then '36-50'
        when c.age between 51 and 65 then '51-65'
        when c.age > 65 then '65+'
	end as age_group,  
l.loan_purpose,
sum(l.loan_amount) as total_loan_amount
from customer c join loan l
on c.customer_id = l.customer_id
group by age_group, l.loan_purpose
order by age_group, total_loan_amount desc;

# 9. Seasonal Transaction Trends: Examine transaction patterns over years and months to identify 
#seasonal trends in loan repayments.

select year(str_to_date(transaction_date, '%m/%d/%Y')) as transaction_year,
month(str_to_date(transaction_date, '%m/%d/%Y')) as transaction_month,
count(*) as total_transactions,
sum(transaction_amount) as total_amount,
sum(case when payment_method = 'Credit Card' then 1 else 0 end) as credit_card_transactions,
sum(case when payment_method = 'Cash' then 1 else 0 end) as cash_transactions,
sum(case when payment_method = 'Online Transfer' then 1 else 0 end) as online_transfer_transactions,
sum(case when payment_method = 'UPI' then 1 else 0 end) as UPI_transactions
from transaction
group by transaction_year, transaction_month 
order by transaction_year, transaction_month;


# 10. Fraud Detection: Highlight potential fraud by identifying mismatches between customer address
# locations and transaction IP locations.

select b.customer_id, c.name, left(right(c.address,8),2) as state_code,
s.full_name as state, b.location as ip_locations
from behaviour b
left join customer c on c.customer_id = b.customer_id
join states s on left(right(c.address,8),2) = s.state
where  b.location not like concat('%', s.full_name, '%');


#11. Repayment History Analysis: Rank loans by repayment performance using window functions.

select loan_id, customer_id, loan_amount, repayment_history,
rank() over (partition by repayment_history order by repayment_history desc, loan_amount desc) as loan_rank
from loan;

# 12. Credit Score vs. Loan Amount: Compare average loan amounts for different credit score ranges.

select 
	case
		when c.credit_score between 300 and 399 then '300 - 400'
        when c.credit_score between 400 and 499 then '400 - 500'
        when c.credit_score between 500 and 599 then '500 - 600'
        when c.credit_score between 600 and 699 then '600 - 700'
        when c.credit_score between 700 and 799 then '700 - 800'
        when c.credit_score >= 800 then '800+'
	end as credit_score_ranges,
sum(l.loan_amount) as total_loan_amount
from customer c join loan l
on c.customer_id = l.customer_id
group by credit_score_ranges
order by credit_score_ranges ;

# 13. Top Borrowing Regions: Identify regions with the highest total loan disbursements.

select left(right(c.address,8),2) as region_code, 
s.full_name as region,
count(*) as number_of_loans,
sum(l.loan_amount) as total_amount
from customer c 
join loan l on c.customer_id = l.customer_id
join states s on s.state = left(right(c.address,8),2)
group by left(right(c.address,8),2), s.full_name
having region <> 'Armed Forces'
order by number_of_loans desc;

# 14. Early Repayment Patterns: Detect loans with frequent early repayments and their impact on revenue.

select loan_id, customer_id, loan_amount, loan_date, loan_status, repayment_history
from loan
where loan_status = 'Closed'  
and repayment_history > (select avg(repayment_history) from loan) 
order by repayment_history desc;

# 15. Feedback Correlation: Correlate customer feedback sentiment scores with loan statuses.

select l.loan_status, avg(f.sentiment_score) as avg_sentiment
from loan l join feedback f
on l.loan_id = f.loan_id
group by l.loan_status;