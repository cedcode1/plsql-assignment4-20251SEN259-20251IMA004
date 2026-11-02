-- Shows if any of our saved procedures/functions failed to compile.
PROMPT === CHECK PROGRAMS ===
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN (
    'PR_ADD_PRODUCT', 'PR_SELL_PRODUCT', 'PR_DELETE_PRODUCT',
    'PR_SHOW_PRODUCTS', 'PR_RESTOCK_LOW_STOCK',
    'FN_GET_STOCK', 'FN_TOTAL_VALUE', 'FN_PRICE_BY_NAME'
)
ORDER BY object_type, object_name;

SELECT name, type, line, position, text
FROM user_errors
WHERE name IN (
    'PR_ADD_PRODUCT', 'PR_SELL_PRODUCT', 'PR_DELETE_PRODUCT',
    'PR_SHOW_PRODUCTS', 'PR_RESTOCK_LOW_STOCK',
    'FN_GET_STOCK', 'FN_TOTAL_VALUE', 'FN_PRICE_BY_NAME'
)
ORDER BY name, sequence;
