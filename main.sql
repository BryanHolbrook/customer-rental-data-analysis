-- Section B | Create Function Performing Transformation from A4 of Report

SELECT * FROM rental;

DROP FUNCTION rental_goal;

CREATE OR REPLACE FUNCTION rental_goal(customer_id INT)
 RETURNS INT
 LANGUAGE plpgsql
AS
$$
DECLARE total_rentals INT;
DECLARE rental_percent INT;
BEGIN
 SELECT customer_id, COUNT(customer_id) INTO total_rentals;
 SELECT total_rentals*50/100 INTO rental_percent;
 RETURN rental_percent;
END;
$$

SELECT rental_goal(233);

-- Section C | Create Detail Table and Summary Table to Hold Your Report Tables

DROP TABLE customer_rental_detail;

CREATE TABLE customer_rental_detail(
 customer_id SMALLINT,
 first_name VARCHAR(30),
 last_name VARCHAR(30),
 total_rentals INT,
 email VARCHAR(60),
 address_id SMALLINT,
 address VARCHAR(50),
 district VARCHAR(20),
 city_id SMALLINT,
 postal_code VARCHAR(10),
 phone VARCHAR(20),
 store_id SMALLINT,
 create_date DATE,
 last_update TIMESTAMP
);

SELECT * FROM customer_rental_detail;

DROP TABLE customer_rental_summary;

CREATE TABLE customer_rental_summary(
 customer_name VARCHAR(60),
 rental_goal INT
);

SELECT * FROM customer_rental_summary;

-- Section D | Create Query from DVD Database that Populates Detail Table

SELECT * FROM rental;
SELECT * FROM customer;
SELECT * FROM address;
DELETE FROM customer_rental_detail;

INSERT INTO customer_rental_detail
 SELECT r.customer_id, c.first_name, c.last_name, COUNT(r.customer_id) AS total_rentals, c.email, c.address_id, 
 a.address, a.district, a.city_id, a.postal_code, a.phone, c.store_id, c.create_date, c.last_update
 FROM rental r
 JOIN customer c
 ON r.customer_id = c.customer_id
 JOIN address a
 ON a.address_id = c.address_id
 WHERE rental_date >= '2005-06-01'
 AND rental_date < '2005-07-01'
 GROUP BY r.customer_id, c.first_name, c.last_name, c.email, c.address_id, a.address, a.district, a.city_id, a.postal_code, 
 a.phone, c.store_id, c.create_date, c.last_update
 ORDER BY total_rentals DESC;

SELECT * FROM customer_rental_detail;

-- Query Test

SELECT * FROM rental
WHERE rental_date >= '2005-06-01'
AND rental_date < '2005-07-01';

SELECT * FROM customer
WHERE customer_id = 31;

SELECT * FROM address
WHERE address_id = 35;

SELECT * FROM customer_rental_detail;


-- Section E | Create a Trigger on Detail Table Updating Summary Table as Data is Added to Detail Table

CREATE OR REPLACE FUNCTION detail_insert_trigger_func()
 RETURNS TRIGGER
 LANGUAGE plpgsql
AS 
$$
BEGIN
 DELETE FROM customer_rental_summary;
 INSERT INTO customer_rental_summary
 SELECT CONCAT(first_name, ' ', last_name) AS customer_name, total_rentals*50/100 AS rental_goal
 FROM customer_rental_detail
 ORDER BY rental_goal DESC;
RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS detail_insert_trigger ON customer_rental_detail;

CREATE TRIGGER detail_insert_trigger
 AFTER INSERT
 ON customer_rental_detail
 FOR EACH STATEMENT
 EXECUTE PROCEDURE detail_insert_trigger_func();

-- Trigger Test

SELECT * FROM customer_rental_summary;
SELECT COUNT(*) FROM customer_rental_detail;
INSERT INTO customer_rental_detail VALUES (905, 'Don', 'Donaldson', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null);
SELECT * FROM customer_rental_summary;
SELECT COUNT(*) FROM customer_rental_summary;
SELECT COUNT(*) FROM customer_rental_detail;

-- Section F | Stored Procedures Used to Refresh Data in Both the Detail and Summary Tables. 
-- The procedure should clear the contents of the Detail and Summary Tables and perform raw data extraction from part D. 
-- Note: Identify a relevant job scheduling tool that can be used to automate the stored procedure.

CREATE OR REPLACE PROCEDURE refresh_detail_summary_tables_procedure()
LANGUAGE plpgsql
AS
$$
BEGIN

DELETE FROM customer_rental_detail;
INSERT INTO customer_rental_detail
 SELECT r.customer_id, c.first_name, c.last_name, COUNT(r.customer_id) AS total_rentals, c.email, c.address_id, 
 a.address, a.district, a.city_id, a.postal_code, a.phone, c.store_id, c.create_date, c.last_update
 FROM rental r
 JOIN customer c
 ON r.customer_id = c.customer_id
 JOIN address a
 ON a.address_id = c.address_id
 WHERE rental_date >= '2005-06-01'
 AND rental_date < '2005-07-01'
 GROUP BY r.customer_id, c.first_name, c.last_name, c.email, c.address_id, a.address, a.district, a.city_id, a.postal_code, 
 a.phone, c.store_id, c.create_date, c.last_update
 ORDER BY total_rentals DESC;

DELETE FROM customer_rental_summary;
INSERT INTO customer_rental_summary
 SELECT CONCAT(first_name, ' ', last_name) AS customer_name, total_rentals*50/100 AS rental_goal
 FROM customer_rental_detail
 ORDER BY rental_goal DESC; 
RETURN; 
END;
$$;

CALL refresh_detail_summary_tables_procedure();

-- Procedure test

SELECT COUNT(*) FROM customer_rental_detail;
SELECT COUNT(*) FROM customer_rental_summary;
SELECT * FROM customer_rental_detail;
SELECT * FROM customer_rental_summary;
DELETE FROM customer_rental_detail WHERE last_name = 'Wright';
DELETE FROM customer_rental_summary WHERE customer_name = 'Brenda Wright';
SELECT * FROM customer_rental_detail;
SELECT * FROM customer_rental_summary;
SELECT COUNT(*) FROM customer_rental_detail;
SELECT COUNT(*) FROM customer_rental_summary;

CALL refresh_detail_summary_tables_procedure();

SELECT * FROM customer_rental_detail;
SELECT * FROM customer_rental_summary;
SELECT COUNT(*) FROM customer_rental_detail;
SELECT COUNT(*) FROM customer_rental_summary;
