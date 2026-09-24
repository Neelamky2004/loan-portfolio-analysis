import os
from pathlib import Path

import pandas as pd
import requests
from sqlalchemy import create_engine, text

ROOT = Path(__file__).resolve().parents[1]
RAW_FILE = ROOT / "data" / "LoanStats3a.csv"
SOURCE_URL = "https://raw.githubusercontent.com/yhat/demo-lending-club/master/model/LoanStats3a.csv"
DB_URL = os.getenv("DATABASE_URL", "postgresql://postgres@localhost:5432/loans")

KEEP = {
    "id": "loan_id",
    "loan_amnt": "loan_amount",
    "funded_amnt": "funded_amount",
    "term": "term_months",
    "int_rate": "int_rate",
    "installment": "installment",
    "grade": "grade",
    "sub_grade": "sub_grade",
    "emp_length": "emp_length_years",
    "home_ownership": "home_ownership",
    "annual_inc": "annual_income",
    "is_inc_v": "income_verified",
    "issue_d": "issue_date",
    "loan_status": "loan_status",
    "purpose": "purpose",
    "addr_state": "state",
    "dti": "dti",
    "revol_util": "revol_util",
    "out_prncp": "outstanding_principal",
    "total_pymnt": "total_paid",
    "total_rec_prncp": "principal_received",
    "total_rec_int": "interest_received",
    "total_rec_late_fee": "late_fee_received",
    "last_pymnt_d": "last_payment_date",
}


def download():
    if RAW_FILE.exists():
        return
    RAW_FILE.parent.mkdir(exist_ok=True)
    print("downloading raw file...")
    r = requests.get(SOURCE_URL, timeout=120)
    r.raise_for_status()
    RAW_FILE.write_bytes(r.content)


def to_number(s):
    return pd.to_numeric(s.astype(str).str.replace("%", "").str.strip(), errors="coerce")


def emp_years(s):
    s = s.fillna("").str.strip()
    out = s.str.extract(r"(\d+)")[0].astype(float)
    out[s.str.startswith("<")] = 0
    out[s.isin(["", "n/a"])] = None
    return out


def clean(raw):
    df = raw[list(KEEP)].rename(columns=KEEP)
    df = df[pd.to_numeric(df["loan_id"], errors="coerce").notna()].copy()
    df["loan_id"] = df["loan_id"].astype("int64")

    df["meets_credit_policy"] = ~df["loan_status"].str.startswith("Does not meet")
    df["loan_status"] = df["loan_status"].str.replace(
        r"^Does not meet the credit policy\.\s+Status:", "", regex=True
    ).str.strip()

    df["term_months"] = df["term_months"].str.extract(r"(\d+)")[0].astype(int)
    df["int_rate"] = to_number(df["int_rate"])
    df["revol_util"] = to_number(df["revol_util"])
    df["emp_length_years"] = emp_years(df["emp_length_years"])
    df["income_verified"] = df["income_verified"].astype(str).str.lower().eq("true")
    df["issue_date"] = pd.to_datetime(df["issue_date"], errors="coerce").dt.date
    df["last_payment_date"] = pd.to_datetime(df["last_payment_date"], errors="coerce").dt.date
    df["home_ownership"] = df["home_ownership"].str.upper().str.strip()
    df["purpose"] = df["purpose"].str.strip()

    df = df.drop_duplicates(subset="loan_id")
    return df


def main():
    download()
    raw = pd.read_csv(RAW_FILE, skiprows=1, low_memory=False)
    df = clean(raw)
    print(f"raw rows: {len(raw)}  clean rows: {len(df)}")

    engine = create_engine(DB_URL)
    with engine.begin() as conn:
        conn.execute(text((ROOT / "sql" / "01_schema.sql").read_text()))
    df.to_sql("loans", engine, if_exists="append", index=False, chunksize=1000, method="multi")

    with engine.begin() as conn:
        conn.execute(text((ROOT / "sql" / "03_kpi_views.sql").read_text()))
        loaded = conn.execute(text("select count(*) from loans")).scalar()
    print(f"loaded into postgres: {loaded}")


if __name__ == "__main__":
    main()
