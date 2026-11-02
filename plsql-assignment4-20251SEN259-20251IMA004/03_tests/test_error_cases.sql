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
