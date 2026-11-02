-- SIMPLE LIVE DEMO: No fixed product IDs and no external file paths.
-- Run with F5 in Oracle SQL Developer, after running run_all.sql.
-- The demo creates temporary products and later removes them with ROLLBACK.
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- Recreate the show-products procedure in case this one was missing.
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

PROMPT Checking PR_SHOW_PRODUCTS (status should be VALID):
SELECT object_name, status
FROM user_objects
WHERE object_name = 'PR_SHOW_PRODUCTS';

SAVEPOINT demo_start;

DECLARE
    v_book_id products.product_id%TYPE;
    v_pen_id  products.product_id%TYPE;
    v_sale_id sales.sale_id%TYPE;
    v_changed NUMBER;
BEGIN
    -- Temporarily tell Oracle to ignore old low-stock products.
    -- This makes the demo show only our two test products being restocked.
    -- ROLLBACK will restore the original minimum quantities.
    UPDATE products SET min_quantity = 0;

    -- Choose IDs that are not already in the tables.
    SELECT NVL(MAX(product_id), 0) + 1 INTO v_book_id FROM products;
    v_pen_id := v_book_id + 1;
    SELECT NVL(MAX(sale_id), 0) + 1 INTO v_sale_id FROM sales;

    INSERT INTO products (product_id, product_name, price, quantity, min_quantity)
    VALUES (v_book_id, 'Demo Book', 1000, 5, 10);
    INSERT INTO products (product_id, product_name, price, quantity, min_quantity)
    VALUES (v_pen_id, 'Demo Pen', 200, 2, 5);

    DBMS_OUTPUT.PUT_LINE('=== 1. SHOW PRODUCTS ===');
    pr_show_products;

    DBMS_OUTPUT.PUT_LINE('=== 2. CHECK STOCK ===');
    DBMS_OUTPUT.PUT_LINE('Books before sale: ' || fn_get_stock(v_book_id));
    DBMS_OUTPUT.PUT_LINE('Total shop stock value: ' || fn_total_value() || ' RWF');

    DBMS_OUTPUT.PUT_LINE('=== 3. SELL TWO BOOKS ===');
    pr_sell_product(v_sale_id, v_book_id, 2);
    IF fn_get_stock(v_book_id) <> 3 THEN
        RAISE_APPLICATION_ERROR(-20941, 'Demo sale failed.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Books after sale: ' || fn_get_stock(v_book_id));

    DBMS_OUTPUT.PUT_LINE('=== 4. RESTOCK LOW-STOCK PRODUCTS ===');
    pr_restock_low_stock(1, v_changed);
    IF v_changed <> 2 OR fn_get_stock(v_book_id) <> 4 THEN
        RAISE_APPLICATION_ERROR(-20942, 'Demo restock failed.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Products restocked: ' || v_changed);
    DBMS_OUTPUT.PUT_LINE('Books after restock: ' || fn_get_stock(v_book_id));
    DBMS_OUTPUT.PUT_LINE('=== DEMO PASSED ===');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('DEMO FAILED: ' || SQLERRM);
        RAISE;
END;
/

-- Undo the temporary products, sale, and temporary MIN_QUANTITY changes.
ROLLBACK TO demo_start;
PROMPT Demo changes undone. Original data is unchanged.
