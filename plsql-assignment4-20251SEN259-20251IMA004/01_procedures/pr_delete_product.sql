-- Deletes a product only if it has no sales.
-- SQL%NOTFOUND is TRUE when DELETE removed no rows.
CREATE OR REPLACE PROCEDURE pr_delete_product (
    p_id IN NUMBER
) IS
    e_has_sales EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_has_sales, -2292); -- Child rows exist
BEGIN
    DELETE FROM products WHERE product_id = p_id;

    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Product not found. Nothing was deleted.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Product deleted. Rows: ' || SQL%ROWCOUNT);
EXCEPTION
    WHEN e_has_sales THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot delete: this product has a sale.');
END pr_delete_product;
/
