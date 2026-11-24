# Business questions and answers

All figures come from the synthetic data (see the Power BI report in the README and the checks in `tests/check_database.sql`). They demonstrate the analysis; they say nothing about the real company.

| # | Question | Answer from the data | Where |
|---|---|---|---|
| 1 | Do customers buy more customized or default jewelry? | Almost equally: 1,814 customized units against 1,826 default, out of 3,640. | Power BI page 1; `V_ORDER_ANALYSIS` |
| 2 | Does it differ by category? | Yes. Rings lean customized (244 against 163 units); watches lean default (308 against 236). | Power BI page 3 |
| 3 | Which category sells the most, and which the least? | Necklaces lead (705 units, 307 orders); rings trail (407 units, 192 orders). | Power BI page 3 |
| 4 | Which categories matter to the business? | `sql/02` Query 2a lists categories above 10% of all units sold. | `sql/02` |
| 5 | Who are the high-value customers? | `sql/02` Query 4 (CTE): average order value above the store average and lifetime value over $5,000. | `sql/02` |

## What a marketing team could do with it

- Promote customization for rings, where buyers already choose it.
- Test customization offers for watches, where most buyers take the default.
- Treat the customized/default split as a store-wide balance, not a category rule: it hides opposite trends by category.

## Limits

The data is randomly generated, so category differences reflect how the generator and the team's loading script assigned variants, not customer behavior. The value of this analysis is the method (joins, window functions, CTEs, a report a manager can read), not the numbers.
## What I would add next

- **Test it on real data.** The generator decides the category differences, so the first step is to rerun the same queries and report on real order data and see whether the ring and watch pattern holds.
- **Add revenue and margin.** The schema already stores a price addition per component. A measure for revenue per variant would show whether customized pieces earn more, not only sell more units.
- **Add time and repeat purchases.** Query 3 already tracks days between a customer's orders. A monthly trend and a repeat-purchase view would turn it into a retention page in the report.
- **Move the logic into the report.** The report is built on the database view. Rebuilding the key figures as Power BI measures (DAX) would make the dashboard reusable on new data without changing the SQL.
