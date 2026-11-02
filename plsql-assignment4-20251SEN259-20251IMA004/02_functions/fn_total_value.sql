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
