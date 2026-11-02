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
