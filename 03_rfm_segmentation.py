import sqlite3
import pandas as pd

# 1. LOAD THE CLEAN DATA FROM SQL

conn = sqlite3.connect("superstore.db")
df = pd.read_sql_query(
    "SELECT order_id, order_date, customer_id, customer_name, segment, sales, profit "
    "FROM superstore",
    conn,
    parse_dates=["order_date"],
)
conn.close()
print(f"Rows: {len(df):,} | Orders: {df['order_id'].nunique():,} | Customers: {df['customer_id'].nunique():,}")
print(f"Date range: {df['order_date'].min().date()} to {df['order_date'].max().date()}")

# 2. CALCULATE R, F, M PER CUSTOMER
# Snapshot date = day after the last order. We do not use today's date because the data ends in 2014.
snapshot_date = df["order_date"].max() + pd.Timedelta(days=1)

rfm = (
    df.groupby(["customer_id", "customer_name", "segment"])
    .agg(
        recency=("order_date", lambda x: (snapshot_date - x.max()).days),
        frequency=("order_id", "nunique"),
        monetary=("sales", "sum"),
        profit=("profit", "sum"),
    )
    .reset_index()
    .rename(columns={"segment": "customer_type"})  # avoids clash with RFM segment below
)


# 3. SCORE EACH MEASURE FROM 1 TO 5
# qcut splits customers into 5 equal-sized groups.
# Recency labels are reversed because FEWER days since last order is better.
# rank(method="first") avoids errors when many customers share a value.
rfm["r_score"] = pd.qcut(rfm["recency"].rank(method="first"),   5, labels=[5, 4, 3, 2, 1]).astype(int)
rfm["f_score"] = pd.qcut(rfm["frequency"].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]).astype(int)
rfm["m_score"] = pd.qcut(rfm["monetary"].rank(method="first"),  5, labels=[1, 2, 3, 4, 5]).astype(int)
rfm["rfm_score"] = rfm["r_score"] + rfm["f_score"] + rfm["m_score"]


# 4. ASSIGN SEGMENT LABELS (first matching rule wins)
def assign_segment(row):
    r, f = row["r_score"], row["f_score"]
    if r >= 4 and f >= 4:
        return "Champions"        # bought recently and often
    elif r >= 3 and f >= 3:
        return "Loyal"            # regular, reliable buyers
    elif r >= 4:
        return "Promising"        # recent buyers, not frequent yet
    elif r <= 2 and f >= 3:
        return "At Risk"          # used to buy often, now quiet
    elif r <= 2:
        return "Lost"             # long gone and low frequency
    else:
        return "Needs Attention"  # middle of the pack

rfm["rfm_segment"] = rfm.apply(assign_segment, axis=1)

# 5. SUMMARY: use these numbers in your README and on your CV
summary = (
    rfm.groupby("rfm_segment")
    .agg(
        customers=("customer_id", "count"),
        avg_recency_days=("recency", "mean"),
        avg_orders=("frequency", "mean"),
        total_revenue=("monetary", "sum"),
        total_profit=("profit", "sum"),
    )
    .round(1)
    .sort_values("total_revenue", ascending=False)
)
summary["pct_of_customers"] = (100 * summary["customers"] / summary["customers"].sum()).round(1)
summary["pct_of_revenue"] = (100 * summary["total_revenue"] / summary["total_revenue"].sum()).round(1)

print("\nSegment summary:")
print(summary.to_string())


# 6. EXPORT FOR POWER BI
rfm.to_csv("customer_segments.csv", index=False)
summary.to_csv("segment_summary.csv")
print("\nSaved customer_segments.csv and segment_summary.csv")
