-- 1. Scalar Functions -------------------------------------------------------------------------------
-- Convert all film titles in the film table to uppercase:
SELECT
	UPPER(title)
FROM public.film

-- Calculate the length in hours (rounded to 2 decimal places) for each film in the film table:
SELECT
	film_id,
	title,
	ROUND(CAST(length AS NUMERIC)/60 , 2) AS length_in_hrs
FROM public.film
ORDER BY title

-- Extract the year from the last_update column in the actor table:
SELECT DISTINCT
	EXTRACT(YEAR FROM last_update) AS last_update_year
FROM public.actor

-- 2. Aggregate Functions -------------------------------------------------------------------------------
-- Count the total number of films in the film table:
SELECT
	COUNT(film_id) AS total_films
FROM public.film

-- Calculate the average rental rate of films in the film table:
SELECT
	ROUND(AVG(rental_rate),2) AS avg_rental_rate
FROM public.film

-- Determine the highest and lowest film lengths:
SELECT
	MIN(length) AS lowest_film_length,
	MAX(length) AS highest_film_length
FROM public.film

-- Find the total number of films in each film category:
SELECT 
	se_category.category_id,
	se_category.name AS category,
	COUNT(se_film_cat.film_id) AS total_films
FROM public.category AS se_category
LEFT JOIN public.film_category AS se_film_cat
	ON se_category.category_id = se_film_cat.category_id
GROUP BY
	se_category.category_id,
	se_category.name

-- 3. Window Functions -------------------------------------------------------------------------------
-- Rank films in the film table by length using the RANK() function:
SELECT
	film_id,
	title,
	RANK() OVER (ORDER BY length) as ranked_by_length
FROM public.film

-- Calculate the cumulative sum of film lengths in the film table using the SUM() window function:
SELECT
	film_id,
	title,
	length,
	SUM(length) OVER (ORDER BY title) AS cumulative_length
FROM public.film

-- For each film in the film table, retrieve the title of the next film in terms of alphabetical order using the LEAD() function:
SELECT
	film_id,
	title AS film_title,
	LEAD(title) OVER (ORDER BY title) AS next_film_title
FROM public.film

-- 4. Conditional Functions -------------------------------------------------------------------------------
-- Classify films in the film table based on their lengths:
--   - Short (< 60 minutes)
--   - Medium (60 - 120 minutes)
--   - Long (> 120 minutes)
SELECT
	film_id,
	title,
	length,
	CASE
		WHEN length < 60 THEN 'Short'
		WHEN length >= 60 AND length <= 120 THEN 'Medium'
		WHEN length > 120 THEN 'Long'
	END AS length_class
FROM public.film

-- For each payment in the payment table, use the COALESCE function to replace null values in the amount column with the average payment amount:
SELECT
	COALESCE(amount, (SELECT ROUND(AVG(amount),2) FROM public.payment)) AS new_amount
FROM public.payment


-- 5. User-Defined Functions (UDFs) -------------------------------------------------------------------------------
-- Create a UDF named film_category that accepts a film title as input and returns the category of the film:
CREATE OR REPLACE FUNCTION film_category(film_title TEXT)
RETURNS TEXT AS
$$
DECLARE
	category_name TEXT;
BEGIN
	SELECT
		se_category.name
	INTO category_name
	FROM public.film se_film
	INNER JOIN public.film_category se_film_category
		ON se_film_category.film_id = se_film.film_id
	INNER JOIN public.category se_category
		ON se_category.category_id = se_film_category.category_id
	WHERE se_film.title = film_title;
	RETURN category_name;
END;
$$ LANGUAGE PLPGSQL;
-- SELECT * FROM film_category('Arizona Bang')

-- Develop a UDF named total_rentals that takes a film title as an argument and returns the total number of times the film has been rented.
CREATE OR REPLACE FUNCTION total_rentals(film_title TEXT)
RETURNS NUMERIC AS
$$
DECLARE
	total_rented INT;
BEGIN
	SELECT
		COUNT(se_rental.rental_id)
	INTO total_rented
	FROM public.inventory se_inventory
	INNER JOIN public.rental se_rental
		ON se_rental.inventory_id = se_inventory.inventory_id
	INNER JOIN public.film se_film
		ON se_film.film_id = se_inventory.film_id
	WHERE se_film.title = film_title;
	RETURN total_rented;
END;
$$ LANGUAGE PLPGSQL;
-- SELECT * FROM total_rentals('Arizona Bang')

-- Design a UDF named customer_stats which takes a customer ID as input and returns a JSON containing the customer's name,
-- total rentals, and total amount spent.
CREATE OR REPLACE FUNCTION customer_stats(input_cust_id INT)
RETURNS JSONB AS
$$
DECLARE jsonb_customer JSONB;
BEGIN
	SELECT
		row_to_json (customer_data.*)
	INTO jsonb_customer
	FROM
	(
		SELECT
			CONCAT(se_customer.first_name,' ',se_customer.last_name) AS full_name,
			SUM(se_payment.amount) AS total_payment,
			COUNT(se_rental.rental_id) AS total_rentals
		FROM public.customer se_customer
		INNER JOIN public.rental se_rental
			ON se_rental.customer_id = se_customer.customer_id
		INNER JOIN public.payment se_payment
			ON se_payment.rental_id = se_rental.rental_id
		WHERE se_customer.customer_id = input_cust_id
		GROUP BY
			se_customer.customer_id,
			CONCAT(se_customer.first_name,' ',se_customer.last_name)
	) customer_data;
	RETURN jsonb_customer;
END;
$$ LANGUAGE PLPGSQL;
-- SELECT * FROM customer_stats(123)










