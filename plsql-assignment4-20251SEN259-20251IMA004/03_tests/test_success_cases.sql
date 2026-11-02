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
