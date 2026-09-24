create or replace view v_portfolio_summary as
select
    count(*)                                                        as total_loans,
    sum(funded_amount)                                              as total_funded,
    round(avg(funded_amount), 0)                                    as avg_loan_size,
    round(sum(int_rate * funded_amount) / sum(funded_amount), 2)    as weighted_avg_rate,
    sum(outstanding_principal)                                      as outstanding_principal,
    round(100.0 * count(*) filter (where loan_status in ('Charged Off','Default'))
        / count(*) filter (where loan_status in ('Fully Paid','Charged Off','Default')), 2) as default_rate_pct,
    round(100.0 * count(*) filter (where loan_status in ('In Grace Period','Late (16-30 days)','Late (31-120 days)'))
        / nullif(count(*) filter (where outstanding_principal > 0), 0), 2) as delinquency_rate_pct,
    sum(funded_amount - principal_received) filter (where loan_status in ('Charged Off','Default')) as principal_lost
from loans;

create or replace view v_monthly_disbursal as
select
    date_trunc('month', issue_date)::date          as issue_month,
    count(*)                                       as loans,
    sum(funded_amount)                             as funded_amount,
    round(avg(funded_amount), 0)                   as avg_loan_size,
    round(avg(int_rate), 2)                        as avg_int_rate
from loans
group by 1
order by 1;

create or replace view v_status_buckets as
with b as (
    select *,
        case
            when loan_status = 'Current' then '1. Current'
            when loan_status = 'In Grace Period' then '2. Grace (1-15 days)'
            when loan_status = 'Late (16-30 days)' then '3. Late 16-30 days'
            when loan_status = 'Late (31-120 days)' then '4. Late 31-120 days'
            when loan_status in ('Default','Charged Off') then '5. Default / Charged Off'
            when loan_status = 'Fully Paid' then '6. Fully Paid'
            else '7. Other'
        end as bucket
    from loans
)
select
    bucket,
    count(*)                                                  as loans,
    round(100.0 * count(*) / sum(count(*)) over (), 2)        as pct_of_loans,
    sum(funded_amount)                                        as funded_amount,
    sum(outstanding_principal)                                as outstanding_principal
from b
group by bucket
order by bucket;

create or replace view v_grade_performance as
select
    grade,
    count(*)                                                                      as loans,
    sum(funded_amount)                                                            as funded_amount,
    round(avg(int_rate), 2)                                                       as avg_int_rate,
    count(*) filter (where loan_status in ('Fully Paid','Charged Off','Default'))  as closed_loans,
    count(*) filter (where loan_status in ('Charged Off','Default'))              as defaulted_loans,
    round(100.0 * count(*) filter (where loan_status in ('Charged Off','Default'))
        / nullif(count(*) filter (where loan_status in ('Fully Paid','Charged Off','Default')), 0), 2) as default_rate_pct,
    coalesce(sum(funded_amount - principal_received) filter (where loan_status in ('Charged Off','Default')), 0) as principal_lost
from loans
group by grade
order by grade;

create or replace view v_vintage as
select
    extract(year from issue_date)::int                                            as issue_year,
    'Q' || extract(quarter from issue_date)::int                                  as issue_quarter,
    count(*)                                                                      as loans,
    sum(funded_amount)                                                            as funded_amount,
    round(avg(int_rate), 2)                                                       as avg_int_rate,
    round(100.0 * count(*) filter (where loan_status in ('Charged Off','Default')) / count(*), 2) as default_rate_pct,
    round(100.0 * count(*) filter (where loan_status = 'Fully Paid') / count(*), 2)             as fully_paid_pct,
    round(100.0 * count(*) filter (where outstanding_principal > 0) / count(*), 2)              as still_active_pct
from loans
group by 1, 2
order by 1, 2;

create or replace view v_purpose_performance as
select
    purpose,
    count(*)                                                  as loans,
    sum(funded_amount)                                        as funded_amount,
    round(avg(funded_amount), 0)                              as avg_loan_size,
    round(100.0 * count(*) filter (where loan_status in ('Charged Off','Default'))
        / nullif(count(*) filter (where loan_status in ('Fully Paid','Charged Off','Default')), 0), 2) as default_rate_pct
from loans
group by purpose
order by loans desc;

create or replace view v_state_summary as
select
    state,
    count(*)                                                  as loans,
    sum(funded_amount)                                        as funded_amount,
    round(100.0 * count(*) filter (where loan_status in ('Charged Off','Default'))
        / nullif(count(*) filter (where loan_status in ('Fully Paid','Charged Off','Default')), 0), 2) as default_rate_pct,
    rank() over (order by count(*) desc)                      as volume_rank
from loans
group by state
order by loans desc;

create or replace view v_collections_list as
select
    loan_id,
    grade,
    state,
    loan_status,
    case
        when loan_status = 'Late (31-120 days)' then 'High'
        when loan_status = 'Late (16-30 days)' then 'Medium'
        else 'Low'
    end                                  as priority,
    outstanding_principal,
    installment,
    last_payment_date,
    int_rate
from loans
where loan_status in ('In Grace Period','Late (16-30 days)','Late (31-120 days)')
order by
    case loan_status when 'Late (31-120 days)' then 1 when 'Late (16-30 days)' then 2 else 3 end,
    outstanding_principal desc;
