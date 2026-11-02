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
