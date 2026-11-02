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
