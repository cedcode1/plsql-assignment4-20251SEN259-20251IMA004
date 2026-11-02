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
