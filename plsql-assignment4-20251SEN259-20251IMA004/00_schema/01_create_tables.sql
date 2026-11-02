-- STEP 1: Make two simple tables for our small shop.
-- Run in a new Oracle schema. Do not run twice in the same schema.

CREATE TABLE products (
    product_id   NUMBER PRIMARY KEY,
    product_name VARCHAR2(50) NOT NULL,
    price        NUMBER(10,2) NOT NULL CHECK (price > 0),
    quantity     NUMBER(3) DEFAULT 0 NOT NULL
                 CHECK (quantity BETWEEN 0 AND 100),
    min_quantity NUMBER(3) DEFAULT 5 NOT NULL
                 CHECK (min_quantity BETWEEN 0 AND 100),
    CONSTRAINT ck_product_qty_whole CHECK (quantity = TRUNC(quantity)),
    CONSTRAINT ck_product_min_whole CHECK (min_quantity = TRUNC(min_quantity))
);

CREATE TABLE sales (
    sale_id     NUMBER PRIMARY KEY,
    product_id  NUMBER NOT NULL,
    quantity    NUMBER(3) NOT NULL CHECK (quantity > 0 AND quantity = TRUNC(quantity)),
    sale_date   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

PROMPT Tables created: PRODUCTS and SALES.
