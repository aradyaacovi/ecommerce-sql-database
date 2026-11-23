# E-commerce SQL Database (Jewelry Store)

[![database](https://github.com/aradyaacovi/ecommerce-sql-database/actions/workflows/database.yml/badge.svg)](https://github.com/aradyaacovi/ecommerce-sql-database/actions/workflows/database.yml)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2016%2B-CC2927)](https://www.microsoft.com/sql-server)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A relational database for an online jewelry store, built in SQL Server as the semester project for a Database Systems course (B.Sc. Industrial Engineering & Management). It was a team project: three students worked on it together.

The scenario is based on the purchase flow of Zales.com, a US jewelry retailer. We studied how the site works (browsing, searching, customizing a piece, checkout) and designed a database that could support that process. The company is only the case study. This is not affiliated with Zales, and all data in the database is synthetic: the names, emails, card numbers and addresses are made up. For this public version, emails use the reserved `example.com` domain, phone numbers use the fictional 555-01xx range, and card numbers start with `0000` and are not valid card numbers.

## At a glance

| | |
|---|---|
| **Question** | Do customers buy more customized or off-the-shelf jewelry, and does it differ by category? |
| **Stack** | SQL Server (T-SQL), Python (pandas, Faker), Power BI, GitHub Actions |
| **My part** | Built the database (tables, keys, constraints), generated the synthetic data, wrote and ran the analysis queries. Three-person team project. |
| **Data** | Fully synthetic: 10 tables, 1,500 orders, about 8,000 rows |
| **Checked by CI** | A SQL Server 2022 container builds the database and re-checks the figures published below |

## Findings

From the synthetic data, as shown in the Power BI report. The numbers demonstrate the analysis; they say nothing about the real company.

- **Customized and default sell almost equally:** 1,814 customized units against 1,826 default, out of 3,640.
- **Categories split the other way:** rings lean customized (244 against 163 units, about 1.5 to 1), while watches lean default (308 against 236).
- **Necklaces lead on volume** (705 units across 307 orders) and **rings trail** (407 units across 192 orders).
- **Where a marketing team could act on it:** promote customization for rings, where buyers already choose it, and test it for watches, where most buyers take the default.

More: [business questions and answers](docs/INSIGHTS.md) · [three-step walkthrough](docs/WALKTHROUGH.md)

## What the database models

- **Customers** who place **orders** and pay with **credit cards**
- A **jewelry** catalog, where each item is sold as one or more **variants** (size and color, marked `Default` or `Customized`)
- **Components** (materials such as 14K gold or platinum) that a variant is built from. Each component carries a price addition, and order value is calculated from these.
- **Searches** on the site and the **search results** returned for each search (rank, clicked or not)

## Schema

10 tables, 1,500 orders and about 8,000 rows of synthetic data in total.

| Table | Rows | Primary key | Notes |
|---|---|---|---|
| `CUSTOMERS` | 350 | `Email` | |
| `CREDIT_CARDS` | 450 | `CCNumber` | FK to `CUSTOMERS` |
| `JEWELRY` | 300 | `Jewelry` | catalog item and category |
| `JEWELRY_VARIANTS` | 400 | `Jewelry_Variant` | FK to `JEWELRY`, CHECK on `Variant_Type` |
| `COMPONENTS` | 250 | `Component` | CHECK `Price_Addition >= 0` |
| `ORDERS_TABLE` | 1,500 | `Order_ID` | FKs to `CUSTOMERS` and `CREDIT_CARDS` |
| `INCLUDES` | 1,800 | (`Order_ID`, `Jewelry_Variant`) | order lines, CHECK `Quantity > 0` |
| `BUILDS_FROM` | 1,200 | (`Jewelry_Variant`, `Component`) | many-to-many between variants and components |
| `SEARCHES` | 400 | (`Search_IP`, `Search_DT`) | composite key, FK to `CUSTOMERS` |
| `SEARCH_RETURNS` | 1,500 | (`Search_IP`, `Search_DT`, `Jewelry`) | composite FK to `SEARCHES`, CHECK `Result_Rank BETWEEN 1 AND 20` |

The diagram below was generated from the `CREATE TABLE` statements in `sql/01_create_database_and_load_data.sql`. It only shows the keys and foreign keys defined there.

```mermaid
erDiagram
    CUSTOMERS ||--o{ CREDIT_CARDS : "owns"
    CUSTOMERS ||--o{ ORDERS_TABLE : "places"
    CREDIT_CARDS ||--o{ ORDERS_TABLE : "pays for"
    ORDERS_TABLE ||--o{ INCLUDES : "has lines"
    JEWELRY_VARIANTS ||--o{ INCLUDES : "ordered as"
    JEWELRY ||--o{ JEWELRY_VARIANTS : "offered as"
    JEWELRY_VARIANTS ||--o{ BUILDS_FROM : "built from"
    COMPONENTS ||--o{ BUILDS_FROM : "used in"
    CUSTOMERS ||--o{ SEARCHES : "performs"
    SEARCHES ||--o{ SEARCH_RETURNS : "returns"
    JEWELRY ||--o{ SEARCH_RETURNS : "appears in"

    CUSTOMERS {
        varchar Email PK
        varchar Password
        varchar Name_Last
        varchar Name_First
        varchar Phone
    }
    CREDIT_CARDS {
        char CCNumber PK
        varchar Owner_ID FK
        char Expiry_Date
        char CVV
    }
    ORDERS_TABLE {
        int Order_ID PK
        date Date
        varchar Address_State
        varchar Address_City
        varchar Delivery_Method
        varchar Email FK
        char CCNumber FK
        decimal Total_Order_Value
        varchar Packaging_Type
    }
    JEWELRY {
        int Jewelry PK
        varchar Product_Name
        varchar Category
    }
    JEWELRY_VARIANTS {
        int Jewelry_Variant PK
        int Jewelry FK
        varchar Variant_Type
        varchar Size
        varchar Color
    }
    COMPONENTS {
        int Component PK
        varchar Material
        decimal Price_Addition
    }
    INCLUDES {
        int Order_ID PK, FK
        int Jewelry_Variant PK, FK
        int Quantity
    }
    BUILDS_FROM {
        int Jewelry_Variant PK, FK
        int Component PK, FK
    }
    SEARCHES {
        varchar Search_IP PK
        datetime2 Search_DT PK
        varchar Search_Text
        varchar Search_Filter
        varchar Sort_Method
        varchar Email FK
    }
    SEARCH_RETURNS {
        varchar Search_IP PK, FK
        datetime2 Search_DT PK, FK
        int Jewelry PK, FK
        int Result_Rank
        bit Clicked
    }
```

We also drew our own ERD for the course (`docs/erd_course_submission.png`). The final SQL differs slightly from that drawing: in the SQL, `SEARCH_RETURNS` stores `Result_Rank` and `Clicked`.

## Synthetic data generation

`data-generation/generate_fake_data.py` uses Python, pandas and Faker to create the data. It builds the tables in dependency order: parent tables first, then the tables that reference them. That way every foreign key points to a row that already exists, and the pairs in the link tables are unique. Each table is exported to a CSV file. The row counts (350 customers, 1,500 orders, and so on) are set at the top of the script. Product names are put together from lists of Zales-style collections, stones and styles.

```bash
pip install pandas faker
python data-generation/generate_fake_data.py
```

The script produced the first version of the data, where `SEARCHES` had a simple `Search_ID` key. In the final schema the key is (`Search_IP`, `Search_DT`), and the data was adjusted to match. That conversion step is not part of this script. Running the script again produces a new random dataset, not the exact rows in `sql/01`.

## SQL concepts used

| Concept | Where |
|---|---|
| Primary keys, composite keys, foreign keys, CHECK constraints | `01` – table definitions |
| Multi-table joins, `GROUP BY` / `HAVING` | `02` – Query 1 |
| Nested queries (subquery in `HAVING`, subquery in `FROM`) | `02` – Queries 2a, 2b |
| Window functions (`ROW_NUMBER`, `LAG`, running `SUM ... OVER`) | `02` – Query 3 |
| CTEs (`WITH`, three chained blocks) | `02` – Query 4 |
| View | `01` – `V_ORDER_ANALYSIS` |
| Table-valued function | `03` – `GetStateSalesSummary(@State)` |
| Trigger | `03` – `trg_UpdateOrderValue` on `INCLUDES` |
| Stored procedure | `03` – `sp_SetOrderPackaging(@OrderID)` |
| Query rewrite and output equivalence check (`EXCEPT`) | `04` |

A few examples of what the queries answer:

- **Customer purchase history (window functions):** for every order, the customer's order number, the days since their previous order, and their running lifetime value.
- **High-value customers (CTE):** customers whose average order value is above the store-wide average and whose lifetime value is over $5,000.
- **Keeping order totals current (trigger):** when an order line is inserted, updated or deleted, the trigger recalculates `Total_Order_Value` for the affected orders.
- **Packaging rule (stored procedure):** takes an order ID and sets `Premium Velvet Box` for orders worth $2,000 or more, otherwise `Standard Box`.

## Power BI report

A three-page report comparing units sold for customized and default (off-the-shelf) jewelry, with filters for state and date range. The target audience is a sales and marketing manager. The data is synthetic.

| Overall comparison | Monthly trends | Category details |
|---|---|---|
| ![Overall comparison](docs/powerbi/01_overall_comparison.png) | ![Monthly trends](docs/powerbi/02_monthly_trends.png) | ![Category details](docs/powerbi/03_category_details.png) |

## Team

This was a three-person team project. My part:

- Built the database in SQL Server: the tables, keys and constraints
- Generated the synthetic data. We had no access to the company's real data, so I wrote a Python script with Cursor (an AI-assisted code editor) to fill the tables with made-up records (`data-generation/generate_fake_data.py`).
- Wrote and ran the analysis queries

The other parts of the project were done by my teammates or together.

## Use of AI tools

The synthetic data generator was written in Cursor (see Team above). The table design and the SQL in this repository were written without AI help, except for two course assignments that required a generative AI tool (a course-provided ChatGPT assistant):

1. Comparing our conceptual ERD with one the tool suggested.
2. Asking the tool to optimize existing queries. We applied one suggestion: replacing `YEAR(Date) = 2024` with a date range, which can be faster, especially when the date column has an index. We then used `EXCEPT` to check that both versions return the same rows. See `sql/04_ai_query_optimization.sql`.

## Repository structure

```
data-generation/
  generate_fake_data.py                  Python script that generated the synthetic data (CSV per table)
sql/
  01_create_database_and_load_data.sql   creates the database, 10 tables, synthetic data, view, function, trigger, procedure
  02_analysis_queries.sql                analysis queries (joins, nested queries, window functions, CTE)
  03_function_trigger_procedure.sql      the function, trigger and procedure as written for the assignment, plus test calls
  04_ai_query_optimization.sql           original vs. rewritten query and the EXCEPT check
tests/
  check_database.sql                     post-install checks run by CI
docs/
  erd_course_submission.png              ERD drawn for the course
  INSIGHTS.md                            business questions and the answers from the data
  WALKTHROUGH.md                         three-step guide to running the project
  powerbi/                               screenshots of the Power BI report
```

The SQL comments are mostly in Hebrew (the course language). Lines starting with `-- EN:` are English translations added for this repository.

## How to run

You need SQL Server 2016 SP1 or later (Developer or Express edition) and SQL Server Management Studio or Azure Data Studio.

1. Run `sql/01_create_database_and_load_data.sql`. It drops any existing `zales` database, recreates it, loads the data, and ends with two validation queries. Expected result: 1,814 `Customized` units and 1,826 `Default` units.
2. Run the queries in `sql/02_analysis_queries.sql` one at a time.
3. Optionally run `sql/03_function_trigger_procedure.sql` and `sql/04_ai_query_optimization.sql`. The trigger test in `03` changes order 1.

## Continuous integration

Every push and pull request starts a SQL Server 2022 container, runs all four scripts
against it in order, and then runs [`tests/check_database.sql`](tests/check_database.sql).
That script re-checks the numbers this README publishes: 10 tables, 1,814 `Customized`
and 1,826 `Default` units, the two-column primary key on `SEARCHES`, and the presence of
the view, function, trigger and procedure. If the data or the schema ever stops matching
the documentation, the build fails.

See [`.github/workflows/database.yml`](.github/workflows/database.yml).

## Changes made for this repository

The SQL is the team's final submitted script. The only changes were:

- Split the single file into four files, and converted it from UTF-16 to UTF-8 so GitHub can display it
- Masked the synthetic personal data: emails moved to `example.com`, phones to 555-01xx, and card numbers replaced with invalid `0000…` numbers. Keys and relationships are unchanged, and the report totals are the same.
- Added English translation comments (`-- EN:`)
- Fixed one comment line that started with a single `-` (a syntax error)
- In `03`, used `CREATE OR ALTER` and added `GO` separators, because `01` already creates the same objects
