# Three-step walkthrough

1. **Create the schema and load the data.** Run `sql/01_create_database_and_load_data.sql`. It drops and recreates the `zales` database, creates the 10 tables, loads about 8,000 rows and ends with two checks: 1,814 `Customized` and 1,826 `Default` units.
2. **Run the analysis.** Run the queries in `sql/02_analysis_queries.sql` one at a time: VIP customers (`GROUP BY` / `HAVING`), categories above 10% of sales (subquery), purchase history (window functions) and high-value customers (CTEs).
3. **Try the programmability.** Run `sql/03_function_trigger_procedure.sql`: the state-sales function, the trigger that recalculates order totals, and the packaging procedure. The trigger test changes order 1. Then `sql/04_ai_query_optimization.sql` compares an original and a rewritten query with `EXCEPT`.

CI repeats all of this on a SQL Server 2022 container on every push (`.github/workflows/database.yml`).
