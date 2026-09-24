select 'missing issue date' as check_name, count(*) as failed_rows from loans where issue_date is null
union all
select 'loan amount zero or negative', count(*) from loans where loan_amount <= 0 or loan_amount is null
union all
select 'funded more than requested', count(*) from loans where funded_amount > loan_amount
union all
select 'interest rate outside 0-40%', count(*) from loans where int_rate not between 0 and 40 or int_rate is null
union all
select 'invalid grade', count(*) from loans where grade not in ('A','B','C','D','E','F','G') or grade is null
union all
select 'annual income missing or zero', count(*) from loans where annual_income is null or annual_income <= 0
union all
select 'negative dti', count(*) from loans where dti < 0
union all
select 'principal received more than funded', count(*) from loans where principal_received > funded_amount + 1
union all
select 'fully paid but principal outstanding', count(*) from loans where loan_status = 'Fully Paid' and outstanding_principal > 0
union all
select 'employment length missing', count(*) from loans where emp_length_years is null
union all
select 'duplicate loan ids', count(*) - count(distinct loan_id) from loans;
