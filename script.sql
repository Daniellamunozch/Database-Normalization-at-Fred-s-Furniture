--Here I'm looking at the existing table with 14 columns that I probably need to normalize. There's even columns for repeated items such as item_1_id, item_2_id, item_3_id and the same for item names and prices, which can be optimized!
SELECT *
FROM store
LIMIT 10;

--Now I'm querying the number or distinct orders and customers and I can see there's a discrepancy in the number of orders and customers, there are more orders (100) than customers(80).
SELECT COUNT(DISTINCT(order_id)) 
FROM store;

SELECT COUNT(DISTINCT(customer_id)) 
FROM store;

--This query demonstrates some of the issues with repeated data in this database, the result of this query gives us 2 results with repeated data for this customer.
SELECT customer_id, customer_email, customer_phone 
FROM store
WHERE customer_id = 1;

--Another query demonstrating more repeated data issues, this time there's 3 identical results for this item. 
SELECT item_1_id, item_1_name, item_1_price 
FROM store
WHERE item_1_id = 4;

--We're finally normalizing the database by dividing the original 'store' table into 4 tables. First we create the table 'customers'.
CREATE TABLE customers AS 
SELECT DISTINCT customer_id, customer_phone, customer_email
FROM store;

--Since I created the table 'customers' based on an existing table 'store', I couldn't add the constraint PRIMARY KEY right away in the CREATE TABLE statement. I'm doing it now:
ALTER TABLE customers
ADD PRIMARY KEY (customer_id);

--Now, let's create the table 'items' from 'store', I'll need to join several columns with repreated data and add the PRIMARY KEY later.
CREATE TABLE items AS
SELECT DISTINCT item_1_id as item_id, item_1_name as name, item_1_price as price 
FROM store
UNION
SELECT DISTINCT item_2_id as item_id, item_2_name as name, item_2_price as price
FROM store
WHERE item_2_id IS NOT NULL
UNION
SELECT DISTINCT item_3_id as item_id, item_3_name as name, item_3_price as price
FROM store
WHERE item_3_id IS NOT NULL;

ALTER TABLE items
ADD PRIMARY KEY (item_id);

--Another table I need to create is 'orders_items' which will connect the orders table to the items table, as multiple orders can contain multiple items and multiple items can be in multiple orders, making it a many-to-many relationship, thus the need to create this table with the columns 'order_id' and 'item_id' for further analysis.
CREATE TABLE orders_items AS
SELECT order_id, item_1_id as item_id 
FROM store
UNION ALL
SELECT order_id, item_2_id as item_id
FROM store
WHERE item_1_id IS NOT NULL
UNION ALL
SELECT order_id, item_3_id as item_id
FROM store
WHERE order_id IS NOT NULL;

--I'm checking how it came about here to see if I did what I wanted
SELECT *
FROM orders_items
LIMIT 10
;

--Finally, the last table needs to be created
CREATE TABLE orders AS
SELECT order_id, order_date, customer_id
FROM store;

ALTER TABLE orders
ADD PRIMARY KEY (order_id);

--Now I'm designating FOREING KEYS to relate the database schema accordingly.
ALTER TABLE orders
ADD FOREIGN KEY (customer_id) 
REFERENCES customers(customer_id);

ALTER TABLE orders_items
ADD FOREIGN KEY (item_id) 
REFERENCES items(item_id);

ALTER TABLE orders_items
ADD FOREIGN KEY (order_id) 
REFERENCES orders(order_id);

--As the new database schema is done, now we can test it and make some queries and compare it to the old schema. First let's query the old database with just the 'store' table to return the emails of all customers who made an order after July 25, 2019:
SELECT customer_email
FROM store
WHERE order_date > '2019-08-25';

--Now I'll do the same with the new updated schema
SELECT customer_email
FROM customers, orders
WHERE customers.customer_id = orders.customer_id
AND
orders.order_date > '2019-08-25';

--Now we're testing the original database to return all number of orders containing each unique item 
WITH all_items AS (
SELECT item_1_id as item_id 
FROM store
UNION ALL
SELECT item_2_id as item_id
FROM store
WHERE item_2_id IS NOT NULL
UNION ALL
SELECT item_3_id as item_id
FROM store
WHERE item_3_id IS NOT NULL
)
SELECT item_id, COUNT(*)
FROM all_items
GROUP BY item_id;

--Lastly, I'm doing the same with the normalized schema, we can see it's easier to query this particular data from a normalized schema than in the original
SELECT item_id, COUNT(*)
FROM orders_items
GROUP BY item_id;