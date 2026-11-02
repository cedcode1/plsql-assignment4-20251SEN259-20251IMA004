# Simple Shop Stock System (Oracle PL/SQL)

**University:** Adventist University of Central Africa (AUCA)  
**Course:** INSY 8311 - Database Development with PL/SQL  
**Work:** Group Assignment IV - Records, Collections, Cursors and More  
**Instructor:** Eric Maniraguha

## Group members

| Student | Student ID |
|---|---|
| **IRAKOZE PEACE CEDRICK** | **20251SEN259** |
| **MUGISHA Elyse** | **20251IMA004** |

**Class group:** [Write I, B, C, or D after checking your class.]  
**Project folder:** `plsql-assignment4-20251SEN259-20251IMA004`

## 1. What is our project?

Our project is a **small shop stock system**. The shop sells books, pens, and
other school items. We want to know how many items are left. We also want to
save a sale and add more stock when it is low.

Our project can:

1. Add a new product.
2. Sell a product and reduce its stock.
3. Delete a product if nobody has bought it yet.
4. Show all products.
5. Give extra stock to low-stock products.
6. Check a product's stock, product price, and total stock value.

This is a learning project, not a complete business system. It uses example
prices in **Rwandan francs (RWF)**.

## 2. Our two tables

- `PRODUCTS` stores ID, name, price, quantity, and minimum quantity.
- `SALES` stores sale ID, product ID, quantity sold, and date.

**Relationship:** One product can have many sales. `SALES.product_id` points
to `PRODUCTS.product_id` (a foreign key).

**Rules:** Product IDs and sale IDs must be unique. Price must be positive.
Product stock must be a whole number from 0 to 100. We cannot sell more stock
than we have. Products with saved sales cannot be deleted.

## 3. How the assignment topics are used

| Topic from the assignment | Our simple example |
|---|---|
| **Record (%ROWTYPE)** | `pr_sell_product` reads one complete product row. |
| **User-defined record** | `pr_show_products` stores an ID, name and stock in one record. |
| **Collection (nested table)** | `pr_restock_low_stock` stores many product IDs together. |
| **Implicit cursors** | `SQL%ROWCOUNT` after INSERT/UPDATE/DELETE; `SQL%FOUND` after UPDATE; `SQL%NOTFOUND` after DELETE. |
| **Explicit cursor** | `pr_show_products` uses OPEN, FETCH and CLOSE. |
| **BULK COLLECT** | `pr_restock_low_stock` reads many IDs in one operation. |
| **FORALL** | `pr_restock_low_stock` updates several products. |
| **Bulk error handling** | `SAVE EXCEPTIONS`, `SQL%BULK_EXCEPTIONS`, and ROLLBACK if stock goes above 100. |
| **Stored procedures** | Five procedures for shop actions, including an IN input and an OUT result. |
| **Stored functions** | Three functions return stock, total value, or price. |
| **Exceptions** | Missing product, duplicate ID/name, not enough stock, linked sales, and bad bulk update. |

## 4. Project files

```text
plsql-assignment4-20251SEN259-20251IMA004/
  README.md
  .gitignore
  run_all.sql
  00_schema/
    01_create_tables.sql
    02_insert_sample_data.sql
  01_procedures/
    pr_add_product.sql
    pr_sell_product.sql
    pr_delete_product.sql
    pr_show_products.sql
    pr_restock_low_stock.sql
  02_functions/
    fn_get_stock.sql
    fn_total_value.sql
    fn_price_by_name.sql
  03_tests/
    00_verify_compilation.sql
    manual_demo.sql
    test_error_cases.sql
    test_success_cases.sql
  screenshots/
    pictures of our project
  docs/
    IMPLEMENTATION_NOTES.md
    PRESENTATION_GUIDE.md
```

## 5. How to run the project (easy steps)

**You need:** Oracle Database and Oracle SQL Developer. The database should be OPEN.

1. Connect to your own Oracle account. **Do not use SYS or SYSTEM for class projects.**
   (If you see `SYSTEM.FN_GET_STOCK` in an error, you used the SYSTEM account.)
2. Open **`run_all.sql`**. Press **F5 (Run Script)**.
3. Look at **Script Output**: the eight programs should show `VALID`,
   seven success checks should show `PASS`, and eight error checks should
   show `PASS`. If you see `FAIL`, `ORA-`, or `PLS-`, check the error first.
4. To practice for the presentation, open **`03_tests/manual_demo.sql`**
   and press **F5**. Look for `=== DEMO PASSED ===`.
5. Save real screenshots of the output in the `screenshots/` folder.

**Why these steps work:** `run_all.sql` has no `@` or `@@` paths, so SQL
Developer does not need to find other files. It creates the two tables only
if missing. It adds sample products only if the PRODUCTS table is empty.
It compiles all three functions and all five procedures. Then it runs tests
that create **temporary** test products. Those products and changes are
cancelled with `ROLLBACK`, so your saved stock is not changed by the tests.
The setup file is safe to rerun with the same table structure; it does not
remove your existing shop records.

If you prefer to run the files one by one, do so in this order:
`00_schema/01_create_tables.sql` (**new database only**),
`00_schema/02_insert_sample_data.sql`, the three function files, the five
procedure files, then `03_tests/test_success_cases.sql` and
`03_tests/test_error_cases.sql`. Press **F5** for each file.

**Simple checks you can run:**

```sql
SELECT * FROM products ORDER BY product_id;
SELECT * FROM sales ORDER BY sale_id;
SELECT fn_total_value() AS total_rwf FROM dual;
BEGIN pr_show_products; END;
/
```

## 6. Testing and proof

`03_tests/test_success_cases.sql` runs **seven** checks for normal actions.
`03_tests/test_error_cases.sql` runs **eight** checks for expected mistakes.
`03_tests/manual_demo.sql` shows a simple example during the presentation.

All three test files make their own temporary products. They do not assume
that product ID 1 or any other fixed ID exists. They also work when the shop
already has products. The demo temporarily ignores existing low-stock items,
then uses `ROLLBACK` to restore their original settings.

If the example data was added to an empty shop, its first stock value is
**18,550 RWF**. In a shop that already has different records, the value will
be different. **We cannot claim successful Oracle execution until we run it
in Oracle and capture real output.**

## 7. AI support and student responsibility

we used AI to collect our codes from errors give structure our poject
and to organise our cintent very well so that it can be easly to explain

