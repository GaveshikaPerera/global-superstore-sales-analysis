# Global Superstore: Profitability & Customer Segmentation Analysis

> Where does the business lose money, and which customers are worth keeping?
> An end-to-end analysis of 51,290 retail order lines using **Power BI, SQL and Python**.

<img width="1286" height="726" alt="image" src="https://github.com/user-attachments/assets/029e6f47-08c2-435b-ad56-56fbe70cf835" />

<img width="1286" height="725" alt="image" src="https://github.com/user-attachments/assets/aa75a562-d8b1-482a-b2b3-35154198f565" />

<img width="1286" height="727" alt="image" src="https://github.com/user-attachments/assets/8d2e3b05-cf71-4241-8b59-b56d27a37778" />

## TL;DR (30-second summary)

- **Discounts above 30% lost the company about $794K.** Those lines are only 12% of revenue.
- **Tables** is the only loss-making product sub-category, and **EMEA** is the weakest market.
- **24% of customers (Champions) generate 45.5% of revenue.**
- **202 "At Risk" customers** (worth $1.86M in sales) have gone quiet and are the best win-back target.

## Project at a Glance

| | |
|---|---|
| **Dataset** | Global Superstore (Kaggle): 51,290 order lines, 24 columns |
| **Period** | January 2011 to December 2014 |
| **Scale** | $12.64M revenue, $1.47M profit, 11.6% margin, 25,035 orders, 1,590 customers |
| **Tools** | Power BI (Power Query, DAX), SQL (SQLite), Python (pandas) |
| **Deliverables** | 2-page Power BI dashboard, 15 SQL queries, RFM customer segmentation, business recommendations |

---

## Key Findings

| # | Finding | Evidence |
|---|---|---|
| 1 | **Heavy discounts destroy profit.** | No discount: **25.3%** margin. 21-30% discount: **-5.5%**. Over 50% discount: **-111%**. |
| 2 | **Discounts above 30% are the biggest source of loss.** | 20% of order lines, 12% of revenue, but a **$793,527 loss**. |
| 3 | **Tables loses money.** | **-$64K** profit (-8.5% margin). 54% of its order lines carry a discount above 20%. |
| 4 | **EMEA is the weakest market.** | **5.4%** margin vs. 10.2-12.7% in other discounted markets. It also has the highest average discount (**19.6%**). |
| 5 | **Three countries lose the most money.** | Turkey (-$98K), Nigeria (-$81K), Netherlands (-$41K). |
| 6 | **Revenue depends on a core group of customers.** | Top 20% of customers = **46.7%** of revenue. |
| 7 | **A valuable group of customers is slipping away.** | 202 "At Risk" customers (avg. 19 orders each, inactive for about 98 days) represent **$1.86M** in sales. |

## Recommendations

1. **Cap discounts at 20%**, and require manager approval above that. This targets the largest source of loss.
2. **Review Tables pricing and discounting**, since it is the only loss-making sub-category.
3. **Audit EMEA discount practices**, starting with Turkey and Nigeria.
4. **Run a win-back campaign for the 202 At Risk customers.** The dashboard includes a ready-made contact list, sorted by value.
5. **Protect and reward Champions**, who generate almost half of revenue.

## Dashboard (Power BI)
<img width="1286" height="725" alt="image" src="https://github.com/user-attachments/assets/36be395c-add6-4a51-a56a-3836783dc44d" />

KPI cards (sales, profit, orders, quantity, average order value, profit margin), sales by sub-category and market, top products, sales by city, and filters for region, category and customer type.

### Page 2: Customer Segments (RFM)
<img width="1286" height="727" alt="image" src="https://github.com/user-attachments/assets/42504135-929e-48ad-8ee5-8b797336785a" />

Customers and sales per segment, a segment filter, and a sorted **At Risk win-back list**. The segments come from the Python analysis below. The two pages are linked through a relationship on Customer ID, so sales can be split by segment.

## Customer Segmentation (RFM) in Simple Terms

RFM scores every customer on three questions:

- **Recency:** How recently did they buy?
- **Frequency:** How often do they buy?
- **Monetary:** How much do they spend?

Each is scored 1-5, and simple rules turn the scores into segments:

| Segment | Meaning | Customers | % of Customers | % of Revenue |
|---|---|---|---|---|
| Champions | Buy recently and often | 382 | 24.0% | 45.5% |
| Loyal | Regular, reliable buyers | 370 | 23.3% | 30.5% |
| At Risk | Used to buy often, now quiet | 202 | 12.7% | 14.7% |
| Lost | Long gone, low frequency | 434 | 27.3% | 6.1% |
| Promising | Recent but not frequent yet | 118 | 7.4% | 1.9% |
| Needs Attention | Middle of the pack | 84 | 5.3% | 1.2% |

## How the Tools Work Together

Global_Superstore2.csv
        |
        +--> Power Query --> Power BI dashboard (Page 1: sales overview)
        |
        +--> SQLite --> SQL cleaning + analysis (validates dashboard, finds insights)
                    |
                    +--> Python RFM --> customer_segments.csv --> Power BI (Page 2)


| Tool | Role |
|---|---|
| **Power BI** | Built the dashboard: data cleaning in Power Query, KPI measures in DAX, visuals and filters |
| **SQL** | Cleaned the data, **validated the dashboard numbers**, and answered deeper questions about discounts, losses, growth and customers |
| **Python** | Calculated RFM scores and segments, then exported them to Power BI |

**Validation check:** with the dashboard filtered to Furniture + Corporate, the SQL results match Power BI exactly: Sales $1,264,520, Profit $83,732, Margin 6.62%, Average Order Value $505.81.


## Method

**1. Data cleaning (SQL)**
- Checked for NULLs and duplicates in key columns (none found; `postal_code` is mostly empty and was dropped).
- Converted text dates (DD-MM-YYYY) into real dates.
- Verified that no order ships before it was placed and that no sales values are negative.

**2. Business analysis (SQL, 15 queries)**
- KPIs, yearly and monthly trends, and month-over-month growth (`LAG`)
- Profit by category, sub-category, market and country
- Discount bands vs. margin, and loss-making order lines
- Top and bottom products, and top 3 products per category (`RANK`)
- Customer concentration (running totals) and shipping performance
- Techniques used: joins, CTEs, window functions, `CASE`, aggregation, views

**3. Customer segmentation (Python)**
- Calculated recency, frequency and monetary value per customer with pandas.
- The snapshot date is the last order date plus one day, because the data ends in 2014.
- Scored each measure 1-5 using quintiles, then assigned segments with simple rules.

**4. Dashboard (Power BI)**
- Page 1: executive KPIs and sales breakdowns. Page 2: RFM segments, linked to the sales data.



## Skills Demonstrated

- Cleaning and validating a 51K-row dataset
- SQL: CTEs, window functions, aggregation, views
- Python: pandas, grouping, scoring, exporting results
- Power BI: Power Query, DAX measures, data model relationships, dashboard design
- Turning data into **business recommendations**, not just charts


## Repository Structure

```
├── 01_load_to_sqlite.py       # Loads the CSV into a SQLite database
├── 02_run_sql.py              # Runs the SQL script from Python
├── 02_sql_analysis.sql        # Cleaning + 15 analysis queries + Power BI view
├── 03_rfm_segmentation.py     # RFM segmentation -> customer_segments.csv
├── customer_segments.csv      # Output: one row per customer with segment
├── segment_summary.csv        # Output: segment totals
├── Global_Superstore2.csv     # Source data
└── README.md
```


**Author:** Gaveshika Perera | pereragaveshika@gmail.com
