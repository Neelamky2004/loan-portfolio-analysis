# Loan Portfolio Analysis

Analysis of 42,535 personal loans (LendingClub, issued 2007–2011) using Python, PostgreSQL and Excel.
The goal was to track the main lending KPIs — disbursal, interest rate, delinquency and default — and
build a simple dashboard and collections list from them.

## Tools

- **Python (Pandas)** – cleaning the raw file and loading it into PostgreSQL
- **PostgreSQL** – data quality checks and KPI views
- **Excel** – dashboard, VLOOKUP, COUNTIFS/SUMIFS summary, conditional formatting
- **Tableau Public** – interactive dashboard

## Steps

1. **Cleaning (`src/load_data.py`)**
   - removed the header note and footer rows in the raw file
   - converted text fields to numbers (`11.89%` → 11.89, `36 months` → 36, `10+ years` → 10)
   - split the "Does not meet the credit policy" rows into a separate flag
   - removed duplicate loan ids and loaded the clean table into PostgreSQL
2. **Data quality checks (`sql/02_quality_checks.sql`)** – 11 checks such as missing dates, invalid grades,
   interest rate out of range, principal received more than funded, duplicate ids
3. **KPI views (`sql/03_kpi_views.sql`)** – portfolio summary, monthly disbursal, delinquency buckets,
   grade performance, vintage (issue quarter) analysis, purpose and state summary, collections list
4. **Excel report (`src/build_report.py`)** – writes `output/loan_portfolio_report.xlsx` and `output/loans_clean.csv` (used for Tableau)

## Excel report

| Sheet | What it shows |
|---|---|
| Dashboard | KPI tiles and 4 charts |
| Grade_Summary | loans, funded amount and default rate by grade using COUNTIFS / SUMIFS / AVERAGEIFS, risk band with VLOOKUP |
| Monthly_Trend | loans and funded amount per month |
| Status_Buckets | Current, Grace, 16-30 days late, 31-120 days late, Default, Fully Paid |
| Vintage | default rate by the quarter the loan was issued |
| Purpose / States | performance by loan purpose and by state |
| Collections_List | 1,043 late accounts ranked by priority and outstanding amount |
| Data_Checks | result of each quality check |
| Loan_Data | clean loan-level data with a VLOOKUP risk band column |

## Key findings

- Total funded **$460M** across 42,535 loans, average loan size **$10,822**
- Default rate on closed loans is **18.9%**
- Default rate rises with grade: **7.7% for grade A** vs **42% for grade G**
- **60-month loans default 2.4x more** than 36-month loans (37.6% vs 15.4%)
- **Small business** loans have the highest default rate (35.6%)
- **1,043 accounts** are late or in grace period, holding **7%** of the outstanding principal

## How to run

```bash
pip install -r requirements.txt
createdb loans
python src/load_data.py
python src/build_report.py
```

The raw file is downloaded automatically into `data/` on the first run.
If your PostgreSQL login is different, set it first:

```bash
set DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/loans      (Windows)
export DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/loans   (Mac/Linux)
```

## Project structure

```
loan-portfolio-analysis/
├── sql/
│   ├── 01_schema.sql
│   ├── 02_quality_checks.sql
│   └── 03_kpi_views.sql
├── src/
│   ├── load_data.py
│   └── build_report.py
├── output/
│   └── loan_portfolio_report.xlsx
└── requirements.txt
```

## Data source

LendingClub loan data 2007–2011 (public dataset, file `LoanStats3a.csv`).
