-- Adds six example products and one old sale only when PRODUCTS is empty.
-- If you already have products, this file leaves them unchanged.
SET SERVEROUTPUT ON;
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM products;
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Products already exist. Sample data skipped.');
    ELSE
        INSERT INTO products VALUES (1, 'Book',     1000,  5, 10);
        INSERT INTO products VALUES (2, 'Pen',       200, 40, 20);
        INSERT INTO products VALUES (3, 'Pencil',    100,  8, 12);
        INSERT INTO products VALUES (4, 'Ruler',     500,  2,  5);
        INSERT INTO products VALUES (5, 'Eraser',    150,  0,  3);
        INSERT INTO products VALUES (6, 'A4 Paper',   50, 75, 80);
        INSERT INTO sales (sale_id, product_id, quantity) VALUES (10, 2, 2);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Six sample products and one sale saved.');
    END IF;
END;
/
