import sqlite3

conn = sqlite3.connect("superstore.db")
with open("02_sql_analysis.sql", encoding="utf-8") as f:
    conn.executescript(f.read())
conn.commit()

tables = [r[0] for r in conn.execute(
    "SELECT name FROM sqlite_master WHERE type IN ('table','view') ORDER BY name")]
rows = conn.execute("SELECT COUNT(*) FROM superstore").fetchone()[0]
conn.close()

print("Tables/views in superstore.db:", tables)
print(f"Clean table 'superstore' has {rows:,} rows. You can now run 03_rfm_segmentation.py")