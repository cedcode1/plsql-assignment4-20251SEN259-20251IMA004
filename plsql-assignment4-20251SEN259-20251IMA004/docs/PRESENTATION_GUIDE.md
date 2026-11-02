# Easy Presentation Guide (Both Students)

## A short opening (about 30 seconds)

> Good morning. Our names are IRAKOZE PEACE CEDRICK and MUGISHA Elyse.
> We made a simple shop stock system using Oracle PL/SQL.
> It saves products and sales. It can also show stock and add more items
> when stock is low. We used records, collections, cursors, functions,
> procedures, bulk processing, and error handling.

## A good live demonstration

1. Open `00_schema/01_create_tables.sql`. Point to `PRODUCTS` and `SALES`.
   Explain that one product can have many sales.
2. Run `SELECT * FROM products;` to show products. If the shop was empty, `run_all.sql` adds six examples.
3. Open `pr_sell_product.sql`. Say that `%ROWTYPE` stores one product row.
   Explain that the sale checks stock before updating it.
4. Open `pr_show_products.sql`. Point to `RECORD`, `OPEN`, `FETCH` and `CLOSE`.
5. Open `pr_restock_low_stock.sql`. Point to the nested table, `BULK COLLECT`
   and `FORALL`, and the `OUT` count. Say that the code updates several products efficiently when the
   number of products is large.
6. Run `run_all.sql` once using **F5** to set up or repair the project. It has no file paths.
   Then run `03_tests/manual_demo.sql` using **F5**. Show the two temporary
   products, the sale, and the restock. Its changes are rolled back.
7. Run `03_tests/test_error_cases.sql`. Explain that it rejects a sale with
   too little stock and cancels a failed bulk restock.

You can rerun `run_all.sql` if needed. It does not delete old products and
only adds sample products when the PRODUCTS table is empty. The tests use
temporary products and do not need fixed product IDs. Use a student schema,
not the SYS or SYSTEM database account.

## Questions the lecturer may ask

| Question | Simple answer |
|---|---|
| What is your project? | It helps a small shop record sales and control stock. |
| How many tables? | Two: PRODUCTS and SALES. |
| What is a primary key? | A unique ID for one row. |
| What is a foreign key? | It connects a sale to an existing product. |
| What is a procedure? | Saved PL/SQL code that does an action. |
| What is a function? | Saved code that gives back one answer. |
| What are IN and OUT parameters? | IN sends a value to the procedure. OUT returns a value to the caller. |
| What is a record? | One variable with several related fields. |
| What is `%ROWTYPE`? | It uses the columns of one table row as the record fields. |
| What is a collection? | It is a variable that stores many items. |
| What is an implicit cursor? | Oracle makes it automatically when we use SQL. |
| What is an explicit cursor? | We create it ourselves to read rows step by step. |
| Why use `BULK COLLECT`? | To bring many rows into a collection in one query. |
| Why use `FORALL`? | To send many updates efficiently to SQL. |
| What does an exception do? | It handles an error and shows a useful message. |
| Why use a savepoint? | We can undo one operation if it fails. |
| How do you stop negative stock? | We check stock before selling and use a CHECK constraint. |
| What is `TOO_MANY_ROWS`? | A SELECT INTO found more than one row. |
| Does FORALL make every operation safe? | No. We still check errors and can roll back all changes. |
| Is the project ready for a real shop? | No. It is a classroom example showing PL/SQL concepts. |

## Work as a team

Both students should explain **both** the code and the tests. Divide the live
presentation only after both of you have practised. Each student should make
real improvements and genuine commits in GitHub. Do not claim work you did
not do.

**Practice tip:** Be able to explain each file in your own simple words rather
than memorizing every line. If the lecturer changes a number, you should know
what the result should be.
