-- ONE-CLICK SETUP FOR A BEGINNER
-- Open THIS file in Oracle SQL Developer and press F5 (Run Script).
-- It does not use @ or @@ paths. Existing products are not deleted.
-- It is best to run this in your own student account, not SYSTEM or SYS.
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
SET SQLBLANKLINES ON;
PROMPT === STEP 1: CHECK TABLES ===

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'PRODUCTS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'~CREATE TABLE products (
    product_id   NUMBER PRIMARY KEY,
    product_name VARCHAR2(50) NOT NULL,
    price        NUMBER(10,2) NOT NULL CHECK (price > 0),
    quantity     NUMBER(3) DEFAULT 0 NOT NULL
                 CHECK (quantity BETWEEN 0 AND 100),
    min_quantity NUMBER(3) DEFAULT 5 NOT NULL
                 CHECK (min_quantity BETWEEN 0 AND 100),
    CONSTRAINT ck_product_qty_whole CHECK (quantity = TRUNC(quantity)),
    CONSTRAINT ck_product_min_whole CHECK (min_quantity = TRUNC(min_quantity))
)~';
        DBMS_OUTPUT.PUT_LINE('PRODUCTS table created.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('PRODUCTS table already exists.');
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'SALES';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'~CREATE TABLE sales (
    sale_id     NUMBER PRIMARY KEY,
    product_id  NUMBER NOT NULL,
    quantity    NUMBER(3) NOT NULL CHECK (quantity > 0 AND quantity = TRUNC(quantity)),
    sale_date   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id)
        REFERENCES products(product_id)
)~';
        DBMS_OUTPUT.PUT_LINE('SALES table created.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('SALES table already exists.');
    END IF;
END;
/

PROMPT === STEP 2: SAMPLE DATA ===
-- Adds six example products and one old sale only when PRODUCTS is empty.
-- If you already have products, this file leaves them unchanged.
SET SERVEROUTPUT ON;
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM products;
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Products already exist. Sample data skipped.');
    ELSE
        INSERT INTO products VALUES (1, 'Book',     1000,  5, 10);
        INSERT INTO products VALUES (2, 'Pen',       200, 40, 20);
        INSERT INTO products VALUES (3, 'Pencil',    100,  8, 12);
        INSERT INTO products VALUES (4, 'Ruler',     500,  2,  5);
        INSERT INTO products VALUES (5, 'Eraser',    150,  0,  3);
        INSERT INTO products VALUES (6, 'A4 Paper',   50, 75, 80);
        INSERT INTO sales (sale_id, product_id, quantity) VALUES (10, 2, 2);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Six sample products and one sale saved.');
    END IF;
END;
/

PROMPT === STEP: COMPILE FUNCTIONS ===

PROMPT Compiling fn_get_stock...
-- Returns current stock for one product.
CREATE OR REPLACE FUNCTION fn_get_stock (
    p_id IN NUMBER
) RETURN NUMBER IS
    v_quantity products.quantity%TYPE;
BEGIN
    SELECT quantity INTO v_quantity
    FROM products WHERE product_id = p_id;
    RETURN v_quantity;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Product not found.');
END fn_get_stock;
/

PROMPT Compiling fn_price_by_name...
-- Searches by name. A name may match zero, one, or many products.
-- This function shows NO_DATA_FOUND and TOO_MANY_ROWS.
CREATE OR REPLACE FUNCTION fn_price_by_name (
    p_name IN VARCHAR2
) RETURN NUMBER IS
    v_price products.price%TYPE;
BEGIN
    SELECT price INTO v_price
    FROM products
    WHERE UPPER(product_name) = UPPER(p_name);
    RETURN v_price;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Product name not found.');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20007, 'More than one product has this name. Use its ID.');
END fn_price_by_name;
/

PROMPT Compiling fn_total_value...
-- Returns the value of all remaining stock in RWF.
CREATE OR REPLACE FUNCTION fn_total_value
RETURN NUMBER IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(price * quantity), 0)
    INTO v_total
    FROM products;
    RETURN v_total;
EXCEPTION
    WHEN OTHERS THEN
        RAISE; -- Report unexpected database errors.
END fn_total_value;
/

PROMPT === STEP: COMPILE PROCEDURES ===

PROMPT Compiling pr_add_product...
-- Adds one product. SQL%ROWCOUNT shows the number of inserted rows.
CREATE OR REPLACE PROCEDURE pr_add_product (
    p_id       IN NUMBER,
    p_name     IN VARCHAR2,
    p_price    IN NUMBER,
    p_quantity IN NUMBER,
    p_min_qty  IN NUMBER
) IS
    e_bad_data EXCEPTION;  -- Our own exception
BEGIN
    IF p_id IS NULL OR p_name IS NULL OR TRIM(p_name) IS NULL
       OR p_price IS NULL OR p_price <= 0
       OR p_quantity IS NULL OR p_quantity < 0 OR p_quantity > 100
       OR p_quantity <> TRUNC(p_quantity)
       OR p_min_qty IS NULL OR p_min_qty < 0 OR p_min_qty > 100
       OR p_min_qty <> TRUNC(p_min_qty) THEN
        RAISE e_bad_data;
    END IF;

    INSERT INTO products (product_id, product_name, price, quantity, min_quantity)
    VALUES (p_id, p_name, p_price, p_quantity, p_min_qty);

    DBMS_OUTPUT.PUT_LINE('Product added. Rows inserted: ' || SQL%ROWCOUNT);
EXCEPTION
    WHEN e_bad_data THEN
        RAISE_APPLICATION_ERROR(-20001, 'Enter valid product details (stock from 0 to 100).');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20001, 'This product ID already exists.');
END pr_add_product;
/

PROMPT Compiling pr_delete_product...
-- Deletes a product only if it has no sales.
-- SQL%NOTFOUND is TRUE when DELETE removed no rows.
CREATE OR REPLACE PROCEDURE pr_delete_product (
    p_id IN NUMBER
) IS
    e_has_sales EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_has_sales, -2292); -- Child rows exist
BEGIN
    DELETE FROM products WHERE product_id = p_id;

    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Product not found. Nothing was deleted.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Product deleted. Rows: ' || SQL%ROWCOUNT);
EXCEPTION
    WHEN e_has_sales THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot delete: this product has a sale.');
END pr_delete_product;
/

PROMPT Compiling pr_restock_low_stock...
-- BULK COLLECT gets several product IDs at once.
-- The nested table stores those IDs.
-- FORALL updates several rows with less PL/SQL-to-SQL overhead.
CREATE OR REPLACE PROCEDURE pr_restock_low_stock (
    p_add_qty IN NUMBER,
    p_changed OUT NUMBER -- tells us how many products were restocked
) IS
    TYPE t_id_list IS TABLE OF products.product_id%TYPE;
    v_ids t_id_list; -- A collection (nested table)

    e_bulk_error EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_error, -24381);
BEGIN
    p_changed := 0;
    IF p_add_qty IS NULL OR p_add_qty <= 0
       OR p_add_qty <> TRUNC(p_add_qty) THEN
        RAISE_APPLICATION_ERROR(-20009, 'Restock amount must be a positive whole number.');
    END IF;

    SELECT product_id BULK COLLECT INTO v_ids
    FROM products
    WHERE quantity < min_quantity
    ORDER BY product_id;

    IF v_ids.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No low-stock products.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Low-stock products found: ' || v_ids.COUNT);
    SAVEPOINT before_restock;

    BEGIN
        FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
            UPDATE products
            SET quantity = quantity + p_add_qty
            WHERE product_id = v_ids(i);

        p_changed := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('Restocked products: ' || p_changed);
    EXCEPTION
        WHEN e_bulk_error THEN
            -- Example: one product goes above the limit of 100.
            DBMS_OUTPUT.PUT_LINE('Bulk errors found: ' || SQL%BULK_EXCEPTIONS.COUNT);
            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                DBMS_OUTPUT.PUT_LINE('Failed item number: '
                    || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
            END LOOP;
            ROLLBACK TO before_restock;
            RAISE_APPLICATION_ERROR(-20010, 'Restock cancelled. Stock cannot exceed 100.');
        WHEN OTHERS THEN
            ROLLBACK TO before_restock;
            RAISE;
    END;
END pr_restock_low_stock;
/

PROMPT Compiling pr_sell_product...
-- Sells a product. %ROWTYPE keeps all fields from one product row.
-- A SAVEPOINT protects stock if saving the sale fails.
CREATE OR REPLACE PROCEDURE pr_sell_product (
    p_sale_id    IN NUMBER,
    p_product_id IN NUMBER,
    p_quantity   IN NUMBER
) IS
    v_product products%ROWTYPE; -- Table-based record
    e_bad_quantity EXCEPTION;
    e_not_enough   EXCEPTION;
BEGIN
    SAVEPOINT before_sale;

    IF p_sale_id IS NULL OR p_product_id IS NULL OR p_quantity IS NULL
       OR p_quantity <= 0 OR p_quantity <> TRUNC(p_quantity) THEN
        RAISE e_bad_quantity;
    END IF;

    SELECT * INTO v_product
    FROM products
    WHERE product_id = p_product_id
    FOR UPDATE;

    IF v_product.quantity < p_quantity THEN
        RAISE e_not_enough;
    END IF;

    UPDATE products
    SET quantity = quantity - p_quantity
    WHERE product_id = p_product_id;

    IF SQL%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Stock updated. Rows: ' || SQL%ROWCOUNT);
    END IF;

    INSERT INTO sales (sale_id, product_id, quantity)
    VALUES (p_sale_id, p_product_id, p_quantity);

    DBMS_OUTPUT.PUT_LINE('Sale saved for ' || v_product.product_name);
EXCEPTION
    WHEN e_bad_quantity THEN
        ROLLBACK TO before_sale;
        RAISE_APPLICATION_ERROR(-20002, 'Sale quantity must be a positive whole number.');
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO before_sale;
        RAISE_APPLICATION_ERROR(-20003, 'Product does not exist.');
    WHEN e_not_enough THEN
        ROLLBACK TO before_sale;
        RAISE_APPLICATION_ERROR(-20002, 'Not enough stock for this sale.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK TO before_sale;
        RAISE_APPLICATION_ERROR(-20002, 'Sale ID already exists.');
    WHEN OTHERS THEN
        ROLLBACK TO before_sale;
        RAISE;  -- Do not hide unexpected errors.
END pr_sell_product;
/

PROMPT Compiling pr_show_products...
-- Explicit cursor: OPEN, FETCH, CLOSE.
-- User-defined record holds one row at a time.
CREATE OR REPLACE PROCEDURE pr_show_products IS
    CURSOR c_products IS
        SELECT product_id, product_name, quantity
        FROM products ORDER BY product_id;

    TYPE t_product_record IS RECORD (
        id   products.product_id%TYPE,
        name products.product_name%TYPE,
        qty  products.quantity%TYPE
    );
    v_item t_product_record;
BEGIN
    DBMS_OUTPUT.PUT_LINE('ID | NAME | STOCK');
    OPEN c_products;
    LOOP
        FETCH c_products INTO v_item;
        EXIT WHEN c_products%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_item.id || ' | ' || v_item.name
                             || ' | ' || v_item.qty);
    END LOOP;
    CLOSE c_products;
EXCEPTION
    WHEN OTHERS THEN
        IF c_products%ISOPEN THEN
            CLOSE c_products;
        END IF;
        RAISE;
END pr_show_products;
/

PROMPT === CHECK PROGRAM STATUS: ALL EIGHT MUST BE VALID ===
-- Shows if any of our saved procedures/functions failed to compile.
PROMPT === CHECK PROGRAMS ===
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN (
    'PR_ADD_PRODUCT', 'PR_SELL_PRODUCT', 'PR_DELETE_PRODUCT',
    'PR_SHOW_PRODUCTS', 'PR_RESTOCK_LOW_STOCK',
    'FN_GET_STOCK', 'FN_TOTAL_VALUE', 'FN_PRICE_BY_NAME'
)
ORDER BY object_type, object_name;

SELECT name, type, line, position, text
FROM user_errors
WHERE name IN (
    'PR_ADD_PRODUCT', 'PR_SELL_PRODUCT', 'PR_DELETE_PRODUCT',
    'PR_SHOW_PRODUCTS', 'PR_RESTOCK_LOW_STOCK',
    'FN_GET_STOCK', 'FN_TOTAL_VALUE', 'FN_PRICE_BY_NAME'
)
ORDER BY name, sequence;


PROMPT === RUN SUCCESS TESTS ===
-- SUCCESS TESTS: Work even if no sample products were inserted.
-- They create their own products and undo them at the end.
SET SERVEROUTPUT ON SIZE UNLIMITED;
PROMPT === SUCCESS TESTS ===
SAVEPOINT success_test_start;

DECLARE
    v_id       NUMBER;
    v_other_id NUMBER;
    v_delete_id NUMBER;
    v_sale_id  NUMBER;
    v_changed  NUMBER;
    v_before   NUMBER;
    v_name     VARCHAR2(50);
    v_found    NUMBER;
BEGIN
    v_before := fn_total_value();

    -- Hide old low-stock products from this test (only temporarily).
    UPDATE products SET min_quantity = 0;

    -- Choose free IDs, instead of assuming IDs 1, 2, or 99 exist.
    SELECT NVL(MAX(product_id), 0) + 1 INTO v_id FROM products;
    v_other_id := v_id + 1;
    v_delete_id := v_id + 2;
    SELECT NVL(MAX(sale_id), 0) + 1 INTO v_sale_id FROM sales;
    v_name := 'Test Marker ' || v_id;

    -- 1. INSERT with a procedure, then read it with a function.
    pr_add_product(v_id, v_name, 600, 10, 12);
    IF fn_get_stock(v_id) <> 10 THEN
        RAISE_APPLICATION_ERROR(-20901, 'Cannot add a product.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 1: Add product.');

    -- 2. UPDATE and INSERT when selling.
    pr_sell_product(v_sale_id, v_id, 3);
    IF fn_get_stock(v_id) <> 7 THEN
        RAISE_APPLICATION_ERROR(-20902, 'Wrong stock after sale.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 2: Sell three items.');

    -- 3. A function returns a product price.
    IF fn_price_by_name(v_name) <> 600 THEN
        RAISE_APPLICATION_ERROR(-20903, 'Wrong product price.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 3: Get a product price.');

    -- 4. Delete an item that has no sales.
    pr_add_product(v_delete_id, 'Test Delete', 100, 1, 0);
    pr_delete_product(v_delete_id);
    SELECT COUNT(*) INTO v_found FROM products WHERE product_id = v_delete_id;
    IF v_found <> 0 THEN
        RAISE_APPLICATION_ERROR(-20904, 'Product was not deleted.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 4: Delete a product.');

    -- 5. BULK COLLECT and FORALL update two low-stock items.
    pr_add_product(v_other_id, 'Test Notebook', 100, 2, 5);
    pr_restock_low_stock(5, v_changed);
    IF v_changed <> 2 OR fn_get_stock(v_id) <> 12
       OR fn_get_stock(v_other_id) <> 7 THEN
        RAISE_APPLICATION_ERROR(-20905, 'Restock result is incorrect.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 5: Restock two products using FORALL.');

    -- 6. Check stock value, without assuming the shop started empty.
    -- Marker = 12 * 600 = 7200; notebook = 7 * 100 = 700.
    IF fn_total_value() <> v_before + 7900 THEN
        RAISE_APPLICATION_ERROR(-20906, 'Wrong total stock value.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 6: Total stock value is correct.');

    -- 7. An explicit cursor shows our products.
    pr_show_products;
    DBMS_OUTPUT.PUT_LINE('PASS 7: Show products with cursor.');
    DBMS_OUTPUT.PUT_LINE('=== ALL SEVEN SUCCESS TESTS PASSED ===');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST FAILED: ' || SQLERRM);
        RAISE;
END;
/
ROLLBACK TO success_test_start;
PROMPT Success test changes undone.

PROMPT === RUN ERROR TESTS ===
-- ERROR TESTS: Use temporary products, not fixed IDs.
-- An expected error gives PASS. An unexpected error gives FAIL.
SET SERVEROUTPUT ON SIZE UNLIMITED;
PROMPT === ERROR TESTS ===
SAVEPOINT error_test_start;

DECLARE
    v_id         NUMBER;
    v_sale_id    NUMBER;
    v_good_id    NUMBER;
    v_bad_id     NUMBER;
    v_same_id    NUMBER;
    v_same_id2   NUMBER;
    v_missing_id NUMBER;
    v_changed    NUMBER;
    v_number     NUMBER;
    v_good_before NUMBER;
    v_bad_before  NUMBER;
    v_same_name  VARCHAR2(50);
BEGIN
    -- Do not let existing stock affect the bulk-error example.
    UPDATE products SET min_quantity = 0;
    SELECT NVL(MAX(product_id), 0) + 1 INTO v_id FROM products;
    SELECT NVL(MAX(sale_id), 0) + 1 INTO v_sale_id FROM sales;
    v_good_id := v_id + 1;
    v_bad_id := v_id + 2;
    v_same_id := v_id + 3;
    v_same_id2 := v_id + 4;
    v_missing_id := v_id + 100;
    v_same_name := 'Same Test Name ' || v_id;

    pr_add_product(v_id, 'Test Book', 1000, 3, 0);
    pr_add_product(v_good_id, 'Test Good', 100, 2, 10);
    pr_add_product(v_bad_id, 'Test Too Full', 100, 75, 80);
    pr_add_product(v_same_id, v_same_name, 100, 1, 0);
    pr_add_product(v_same_id2, v_same_name, 200, 1, 0);

    -- 1. Do not sell more than we have.
    BEGIN
        pr_sell_product(v_sale_id, v_id, 999);
        RAISE_APPLICATION_ERROR(-20911, 'The sale should have failed.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            DBMS_OUTPUT.PUT_LINE('PASS 1: Not enough stock.');
        ELSE RAISE; END IF;
    END;

    -- 2. NO_DATA_FOUND when a product does not exist.
    BEGIN
        v_number := fn_get_stock(v_missing_id);
        RAISE_APPLICATION_ERROR(-20912, 'Missing product was not rejected.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20005 THEN
            DBMS_OUTPUT.PUT_LINE('PASS 2: Product not found.');
        ELSE RAISE; END IF;
    END;

    -- 3. A repeated primary key is not allowed.
    BEGIN
        pr_add_product(v_id, 'Duplicate ID', 100, 1, 0);
        RAISE_APPLICATION_ERROR(-20913, 'Duplicate ID was not rejected.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('PASS 3: Duplicate product ID.');
        ELSE RAISE; END IF;
    END;

    -- 4. A product with a saved sale cannot be deleted.
    pr_sell_product(v_sale_id, v_id, 1);
    BEGIN
        pr_delete_product(v_id);
        RAISE_APPLICATION_ERROR(-20914, 'Deletion should have failed.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20004 THEN
            DBMS_OUTPUT.PUT_LINE('PASS 4: Cannot delete a product with sales.');
        ELSE RAISE; END IF;
    END;

    -- 5. TOO_MANY_ROWS when two products have the same name.
    BEGIN
        v_number := fn_price_by_name(v_same_name);
        RAISE_APPLICATION_ERROR(-20915, 'Same-name lookup should have failed.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20007 THEN
            DBMS_OUTPUT.PUT_LINE('PASS 5: Duplicate product names.');
        ELSE RAISE; END IF;
    END;

    -- 6. FORALL errors: one product can accept +30, one cannot.
    -- 75 + 30 = 105, but max stock is 100.
    v_good_before := fn_get_stock(v_good_id);
    v_bad_before := fn_get_stock(v_bad_id);
    BEGIN
        pr_restock_low_stock(30, v_changed);
        RAISE_APPLICATION_ERROR(-20916, 'Restock should have failed.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20010 THEN
            DBMS_OUTPUT.PUT_LINE('PASS 6: Bulk error was reported.');
        ELSE RAISE; END IF;
    END;

    -- 7. Even the good product must stay unchanged after that error.
    IF fn_get_stock(v_good_id) <> v_good_before
       OR fn_get_stock(v_bad_id) <> v_bad_before THEN
        RAISE_APPLICATION_ERROR(-20917, 'Bulk rollback failed.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 7: Bulk updates were cancelled safely.');

    -- 8. SQL%NOTFOUND when deleting an unknown ID.
    BEGIN
        pr_delete_product(v_missing_id);
        RAISE_APPLICATION_ERROR(-20918, 'Missing delete was not rejected.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20004 THEN
            DBMS_OUTPUT.PUT_LINE('PASS 8: Delete unknown product.');
        ELSE RAISE; END IF;
    END;
    DBMS_OUTPUT.PUT_LINE('=== ALL EIGHT ERROR TESTS PASSED ===');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST FAILED: ' || SQLERRM);
        RAISE;
END;
/
ROLLBACK TO error_test_start;
PROMPT Error test changes undone.

PROMPT === SETUP AND TESTS FINISHED. CHECK THE PASS AND VALID LINES ABOVE. ===
