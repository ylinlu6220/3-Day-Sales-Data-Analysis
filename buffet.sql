SELECT 
    *
FROM
    orders;

CREATE TABLE items (
    item_id INT NOT NULL AUTO_INCREMENT,
    item_name VARCHAR(50),
    item_price FLOAT,
    PRIMARY KEY (item_id)
);
INSERT INTO items (item_name, item_price)
VALUES('Dinner Buffet', 16.99), ('Dinner KID (3-5)', 6.75), ('Dinner KID (6-8)', 9.50), ('Dinner KID (9-11)', 13.45),
('Lunch Buffet', 12.99), ('Lunch KID (3-5)', 5.50), ('Lunch KID (6-8)', 7.50), ('Lunch KID (9-11)', 9.50), ('Soda', 2.49);
SELECT 
    *
FROM
    items;

CREATE TABLE order_cpy (
    row_id INT,
    date TEXT,
    order_id TEXT,
    waitress_id INT,
    item_name TEXT,
    item_price DOUBLE,
    item_quantity INT,
    item_total DOUBLE,
    items_total DOUBLE,
    order_tip INT,
    order_discount INT,
    order_total DOUBLE,
    item_id INT,
    item_name1 VARCHAR(50),
    item_price1 FLOAT,
    PRIMARY KEY (row_id),
    FOREIGN KEY (item_id)
        REFERENCES items (item_id)
);
INSERT INTO order_cpy 
SELECT * FROM orders
CROSS JOIN items ON orders.item_name = items.item_name;
ALTER TABLE order_cpy DROP COLUMN item_price;
ALTER TABLE order_cpy DROP COLUMN item_total;
ALTER TABLE order_cpy DROP COLUMN item_name1;
ALTER TABLE order_cpy DROP COLUMN item_name;
ALTER TABLE order_cpy DROP COLUMN item_price1;
SELECT * FROM order_cpy;

#For the Dashboard
SELECT 
	date, 
    COUNT( DISTINCT order_id),
    AVG(order_total) OVER(PARTITION BY date)
FROM order_cpy Group By 
	date;

#Simplify and find the MAD averages + other metrics needed for dashboard
SELECT 
	date,
    order_id,
    order_total,
	Overall_Avg_Total,
	Difference_from_Avg_Total,
	AVG(Difference_from_Avg_Total) OVER () AS MAD_Overall,
	AVG_Total_BY_ITEM,
	Difference_from_AVG_by_ITEM,
	AVG(Difference_from_AVG_by_ITEM) OVER () AS MAD_by_item
FROM (
	SELECT row_id, date, order_id, waitress_id, item_id, items_total, order_tip, order_discount, order_total, 
		AVG(order_total) OVER() AS Overall_Avg_Total,
		order_total - AVG(order_total) OVER() AS Difference_from_Avg_Total,
		AVG(order_total) OVER(PARTITION BY item_id) AS AVG_Total_BY_ITEM,
		order_total - AVG(order_total) OVER(PARTITION BY item_id) AS Difference_from_AVG_by_ITEM
	FROM order_cpy) AS S1
GROUP BY 
	date,
	order_id,
    order_total,
	Overall_Avg_Total ,
	Difference_from_Avg_Total,
	AVG_Total_BY_ITEM,
	Difference_from_AVG_by_ITEM
;

#Find the average order total per item
SELECT DISTINCT date, items.item_name,
		AVG(order_total) OVER(PARTITION BY items.item_id) AS AVG_ORDER_Total_BY_ITEM        
	FROM order_cpy LEFT JOIN items ON items.item_id = order_cpy.item_id;

#Find the frequency of each item
SELECT date, order_cpy.item_id, item_name, COUNT(order_cpy.item_id) 
FROM order_cpy LEFT JOIN items ON items.item_id = order_cpy.item_id GROUP BY item_id, date;

#Next, we want to know which waitress gets the best tips and who has the largest order averages
SELECT DISTINCT date, waitress_id, AVG(order_tip) OVER(PARTITION BY waitress_id) AS "Avg tip by waitress",
AVG(order_total) OVER(PARTITION BY waitress_id) AS "AVG total by waitress",
AVG(order_tip) OVER() AS "AVG tip", 
AVG(order_total) OVER() AS "AVG total"
FROM order_cpy;
#Export this table


