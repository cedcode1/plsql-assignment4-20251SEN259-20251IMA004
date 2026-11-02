# How Our Simple Shop Project Works

## 1. Main idea

The shop needs to know what is in stock. We keep the current quantity in the
`PRODUCTS` table. Every sale is written to `SALES`. When we sell something,
we lower its quantity in `PRODUCTS`.

## 2. Tables and relationships

```text
PRODUCTS (one product)            SALES (many sales)
product_id  PK  <---------------- product_id FK
product_name                     sale_id PK
price                            quantity
quantity                         sale_date
min_quantity
```

`PRIMARY KEY` means a unique ID. `FOREIGN KEY` means a sale must belong to a
real product. `CHECK` stops bad quantities and prices. We set a simple maximum
stock of **100 units per product** so we can demonstrate a bulk-update error.
This is a classroom rule, not a real limit for all shops.

## 3. The five procedures

| Procedure | What it does |
|---|---|
| `pr_add_product` | Adds one product using INSERT. |
| `pr_sell_product` | Checks stock, reduces stock, and saves a sale. |
| `pr_delete_product` | Deletes a product only if it has no saved sales. |
| `pr_show_products` | Prints products using an explicit cursor. |
| `pr_restock_low_stock` | Adds stock to low-stock products. Its `OUT` parameter returns the number of updated products. |

A **procedure** does an action. It may take input values but does not return
one value in the same way a function does. An `IN` parameter gives data to a
procedure. An `OUT` parameter gives an answer back to the caller.

## 4. The three functions

- `fn_get_stock(1)` returns how many Books we have.
- `fn_total_value()` returns the total money value of the stock.
- `fn_price_by_name('Pen')` returns the price of Pen. When two products have
  the same name, it shows a useful error instead of guessing.

A **function** returns one answer using `RETURN`.

## 5. Simple meaning of important PL/SQL words

**Record:** A group of related values, such as ID, name and quantity.
`%ROWTYPE` copies the field layout of a whole database row.

**Collection:** A variable holding many values. Our nested table holds
product IDs that need more stock.

**Implicit cursor:** Oracle creates it automatically for SQL actions.
`SQL%ROWCOUNT` tells us how many rows were affected. `SQL%FOUND` is TRUE when
at least one row was changed. `SQL%NOTFOUND` is TRUE when no row was changed.

**Explicit cursor:** We create it ourselves to read rows one by one. Our
code uses `OPEN`, `FETCH`, then `CLOSE`.

**BULK COLLECT:** Reads many rows into a collection in one operation.

**FORALL:** Sends repeated INSERT, UPDATE or DELETE work to SQL in fewer
PL/SQL-to-SQL switches. In our project, it updates stock for many products.
It is not an ordinary loop that runs the SQL statement row by row.

**Exceptions:** Errors that the program catches and explains. For example,
we do not allow a sale when there is not enough stock.

## 6. Why bulk processing can be faster

With a normal PL/SQL loop, updating 100 products might mean 100 switches from
PL/SQL to the SQL engine. `FORALL` lowers this switching cost by sending the
operations together. `BULK COLLECT` fetches many IDs with one query. For our
six sample products, speed differences may be too small to notice. For much
larger data, bulk processing can help, but it uses memory for the collection.
We did not measure actual speed, so we do **not** claim a benchmark result.

## 7. How we protect the data

- A product cannot go below zero or above 100 units.
- A sale first checks stock before removing items.
- The foreign key protects products with saved sales from deletion.
- `NO_DATA_FOUND` means the requested row does not exist.
- `TOO_MANY_ROWS` means a name matched several products.
- `DUP_VAL_ON_INDEX` catches a repeated primary key.
- `RAISE_APPLICATION_ERROR` gives a readable error number and message.
- We use **our own exceptions** for bad input and not enough stock.
- `pr_sell_product` creates a `SAVEPOINT`; if its second step fails, it
  returns to that savepoint so the stock change is not left behind.
- `FORALL SAVE EXCEPTIONS` tries the bulk statements and records errors in
  `SQL%BULK_EXCEPTIONS`. If one product goes above 100 units, we cancel all
  updates in that restock call using `ROLLBACK TO`.

The procedures do **not** use `COMMIT`, so the person running them decides
when to save the transaction. The seed data script saves the six examples only if the PRODUCTS table is
empty. The tests choose unused IDs, create temporary products, and use
`ROLLBACK TO` to undo their changes. This avoids the "Product not found"
error caused by assuming product ID 1 exists.

## 8. What to show during presentation

Open `docs/PRESENTATION_GUIDE.md`. Both students should be able to explain the
whole project, not just their own part. Use real outputs and screenshots.
