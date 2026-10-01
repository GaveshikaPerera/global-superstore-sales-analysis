import sqlite3
import pandas as pd

CSV_FILE = "Global_Superstore2.csv"
DB_FILE = "superstore.db"

df = pd.read_csv(CSV_FILE, encoding="latin-1")

# Standardize column names: "Order Date" -> "order_date", "Sub-Category" -> "sub_category"
df.columns = (
    df.columns.str.strip().str.lower()
    .str.replace(" ", "_").str.replace("-", "_")
)

# Dates are kept as text here on purpose. We convert them in SQL (cleaning step).
conn = sqlite3.connect(DB_FILE)
df.to_sql("superstore_raw", conn, if_exists="replace", index=False)
conn.close()

print(f"Loaded {len(df):,} rows and {df.shape[1]} columns into {DB_FILE} (table: superstore_raw)")
