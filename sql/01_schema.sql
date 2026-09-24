drop view if exists v_collections_list, v_state_summary, v_purpose_performance, v_vintage,
    v_grade_performance, v_status_buckets, v_monthly_disbursal, v_portfolio_summary cascade;
drop table if exists loans;

create table loans (
    loan_id               bigint primary key,
    loan_amount           numeric(12,2),
    funded_amount         numeric(12,2),
    term_months           int,
    int_rate              numeric(5,2),
    installment           numeric(10,2),
    grade                 char(1),
    sub_grade             varchar(3),
    emp_length_years      int,
    home_ownership        varchar(10),
    annual_income         numeric(14,2),
    income_verified       boolean,
    issue_date            date,
    loan_status           varchar(30),
    purpose               varchar(40),
    state                 char(2),
    dti                   numeric(6,2),
    revol_util            numeric(6,2),
    outstanding_principal numeric(12,2),
    total_paid            numeric(14,2),
    principal_received    numeric(14,2),
    interest_received     numeric(14,2),
    late_fee_received     numeric(10,2),
    last_payment_date     date,
    meets_credit_policy   boolean
);
