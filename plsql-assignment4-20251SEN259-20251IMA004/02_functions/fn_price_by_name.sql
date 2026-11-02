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
