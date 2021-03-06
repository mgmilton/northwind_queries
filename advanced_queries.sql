-- Return customers who have made at least one order with a toal of $10,000 in the year of 1997.

SELECT customers.customerid, customers.companyname, orders.orderid, ROUND(sum(order_details.unitprice * order_details.quantity)::numeric, 2) as totalorder
FROM customers
JOIN orders ON orders.customerid = customers.customerid
JOIN order_details ON order_details.orderid = orders.orderid
WHERE orders.orderdate BETWEEN '1/1/1997' and '01/01/1998'
GROUP BY customers.customerid, customers.companyname, orders.orderid
HAVING sum(order_details.unitprice * order_details.quantity) > 10000;


-- Return customers who have made orders whose total is greater $15,000
SELECT customers.customerid, customers.companyname, orders.orderid, ROUND(sum(order_details.unitprice * order_details.quantity)::numeric, 2) as totalorder
FROM customers
JOIN orders ON orders.customerid = customers.customerid
JOIN order_details ON order_details.orderid = orders.orderid
GROUP BY customers.customerid, customers.companyname, orders.orderid
HAVING sum(order_details.unitprice * order_details.quantity) > 15000;

--Return high value customers with discount


--Month end orders
-- Show all orders made on the last day fo the month, ordered by employeeid and orderid


--Orders with many line items
--Show the 10 orders with the most line items, in order of total line items
SELECT orders.orderid, count(order_details.productid) as totalorderdetails
FROM orders
JOIN order_details ON order_details.orderid = orders.orderid
GROUP BY orders.orderid
ORDER BY totalorderdetails DESC
LIMIT 10;

--Orders - random assortment
--Show a random set of 2% of the orders
SELECT orders.orderid
FROM orders
ORDER BY RANDOM()
LIMIT 17;

--Orders - accidental double entry
--Show all the OrderIds with line items that have a quantity of 60 or more, order by order id
SELECT order_details.orderid
FROM order_details
WHERE order_details.quantity >= 60
GROUP BY order_details.orderid, order_details.quantity
HAVING count(order_details.orderid) >1;


-- Orders - accidental double-entry, derived table
SELECT order_details.orderid, order_details.productid, order_details.unitprice, order_details.quantity, order_details.discount
FROM order_details
JOIN
  (SELECT order_details.orderid
  FROM order_details
  WHERE order_details.quantity >= 60
  GROUP BY order_details.orderid, order_details.quantity
  HAVING Count(*) > 1) PotentialProblemOrders
  ON PotentialProblemOrders.orderid = order_details.orderid
ORDER BY order_details.orderid, order_details.productid;


--Late Orders
--Return orders that are late
SELECT orders.orderid, orders.orderdate, orders.requireddate, orders.shippeddate
FROM orders
WHERE orders.shippeddate >= orders.requireddate;

--Late Orders
--Return the sales people that have the most orders arriving late
SELECT orders.employeeid, employees.lastname, sum(case when orders.shippeddate >= orders.requireddate then 1 else 0 end) as lateorders
FROM orders
JOIN employees ON employees.employeeid = orders.employeeid
GROUP BY orders.employeeid, employees.lastname
ORDER BY lateorders DESC;

--Late orders vs total orders
-- compare the number of orders arriving late for each sales person agains the total number of orders per sales person

SELECT orders.employeeid, employees.lastname, count(*) as allorders, sum(case when orders.shippeddate >= orders.requireddate then 1 else 0 end) as lateorders
FROM orders
JOIN employees ON employees.employeeid = orders.employeeid
GROUP BY orders.employeeid, employees.lastname
ORDER BY employeeid;

--Late orders vs total orders as a percentlateorders
SELECT orders.employeeid, employees.lastname, count(*) as allorders, sum(case when orders.shippeddate >= orders.requireddate then 1 else 0 end) as lateorders, sum(case when orders.shippeddate >= orders.requireddate then 1 else 0 end) / count(*)::numeric as percentlateorders
FROM orders
JOIN employees ON employees.employeeid = orders.employeeid
GROUP BY orders.employeeid, employees.lastname
ORDER BY employeeid;


--Late orders vs total orders as a percentlateorders rounded to 2 places
SELECT orders.employeeid, employees.lastname, count(*) as allorders, sum(case when orders.shippeddate >= orders.requireddate then 1 else 0 end) as lateorders, ROUND(sum(case when orders.shippeddate >= orders.requireddate then 1 else 0 end) / count(*)::numeric,2) as percentlateorders
FROM orders
JOIN employees ON employees.employeeid = orders.employeeid
GROUP BY orders.employeeid, employees.lastname
ORDER BY employeeid;


--Customer grouping
--Group customers
WITH customer_sales AS (
  SELECT customers.customerid, customers.companyname, sum(order_details.quantity * order_details.unitprice) as totalorderamount
  FROM customers
  JOIN orders ON orders.customerid = customers.customerid
  JOIN order_details ON orders.orderid = order_details.orderid
  GROUP BY customers.customerid, customers.companyname
  ORDER BY totalorderamount DESC)

SELECT *,
  CASE
  WHEN totalorderamount BETWEEN 0 and 1000 THEN 'Low'
  WHEN totalorderamount BETWEEN 1000 and 5000 THEN 'Medium'
  WHEN totalorderamount BETWEEN 5000 and 10000 THEN 'High'
  WHEN totalorderamount > 10000 THEN 'Very High'
  END AS group
FROM customer_sales
ORDER BY customerid;

--Customer grouping
--Group customers without null value
WITH customer_sales AS (
  SELECT customers.customerid, customers.companyname, sum(order_details.quantity * order_details.unitprice) as totalorderamount
  FROM customers
  JOIN orders ON orders.customerid = customers.customerid
  JOIN order_details ON orders.orderid = order_details.orderid
  GROUP BY customers.customerid, customers.companyname
  ORDER BY totalorderamount DESC)

SELECT *,
  CASE
  WHEN totalorderamount > 0 AND totalorderamount < 1000 THEN 'Low'
  WHEN totalorderamount > 1000 AND totalorderamount < 5000 THEN 'Medium'
  WHEN totalorderamount > 5000 AND totalorderamount < 10000 THEN 'High'
  WHEN totalorderamount > 10000 THEN 'Very High'
  END AS group
FROM customer_sales
ORDER BY customerid;

--Group customers
--show the percentage of groups in each customer grouping

WITH customergroups AS (
  WITH customer_sales AS (
    SELECT sum(order_details.quantity * order_details.unitprice) as totalorderamount
    FROM customers
    JOIN orders ON orders.customerid = customers.customerid
    JOIN order_details ON orders.orderid = order_details.orderid
    GROUP BY customers.customerid, customers.companyname
    ORDER BY totalorderamount DESC)

  SELECT *,
    CASE
    WHEN totalorderamount > 0 AND totalorderamount < 1000 THEN 'Low'
    WHEN totalorderamount > 1000 AND totalorderamount < 5000 THEN 'Medium'
    WHEN totalorderamount > 5000 AND totalorderamount < 10000 THEN 'High'
    WHEN totalorderamount > 10000 THEN 'Very High'
    END AS group
  FROM customer_sales)

SELECT customergroups.group, count(customergroups.group) as totalingroup, count(customergroups.group)/(89)::numeric as percentageingroup
FROM customergroups
GROUP BY customergroups.group
ORDER BY totalingroup DESC;

--Countries with suppliers or customers
-- list all the countries where suppliers or customers are based
SELECT country FROM suppliers
UNION
SELECT country FROM customers
ORDER BY country;

--Countries with suppliers or customers, where null is inputed if no customer or supplier exists
SELECT DISTINCT suppliers.country as suppliercountry, customers.country as customercountry
FROM suppliers
FULL OUTER JOIN customers ON customers.country = suppliers.country;


--Countries with supploers or customers and a count of total suppliers and total customers
WITH countries AS (
  SELECT country FROM suppliers
  UNION
  SELECT country FROM customers
  ORDER BY country
)

SELECT countries.country, count(suppliers.supplierid) as totalsuppliers, count(customers.customerid) as totalcustomers
FROM suppliers
FULL JOIN countries ON suppliers.country = countries.country
FULL JOIN customers ON customers.country = countries.country
GROUP BY countries.country
ORDER BY countries.country;

--First order in each country
--Show deatils for eahc order that was the first in that particular country, ordered by order id
WITH ordersbycountry AS (
  SELECT orders.shipcountry, orders.customerid, orders.orderid, orders.orderdate, ROW_NUMBER() over (PARTITION BY orders.shipcountry ORDER BY orders.shipcountry, orders.orderid) as rownumberpercountry
  FROM orders)

SELECT shipcountry, customerid, orderid, orderdate
FROM ordersbycountry
WHERE rownumberpercountry = 1
ORDER BY shipcountry;
