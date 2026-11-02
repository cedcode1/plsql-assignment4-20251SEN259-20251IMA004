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
