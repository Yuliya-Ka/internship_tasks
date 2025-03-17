-- 1. number of films in each category, sorted in DESC order
SELECT c.name AS film_category, COUNT(fc.film_id) AS number_of_films 
FROM category c
LEFT JOIN film_category fc
ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY number_of_films DESC;

-- 2. top 10 actors whose films were rented the most, sorted in DESC order
WITH ranked_actors_by_rental_count AS
	(SELECT 
		a.actor_id,
		a.first_name ||' '|| a.last_name AS actor_full_name,
		COUNT(r.rental_id) AS rental_count,
		dense_rank() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rank_by_rental_count -- ranked to prevent losing actors with the same rental_count 
	FROM actor a
	INNER JOIN film_actor fa 
	ON a.actor_id = fa.actor_id
	INNER JOIN inventory i 
	ON fa.film_id = i.film_id
	INNER JOIN rental r
	ON i.inventory_id = r.inventory_id
	GROUP BY a.actor_id)
SELECT *
FROM ranked_actors_by_rental_count
WHERE rank_by_rental_count <=10 
ORDER BY rental_count DESC;


-- 3. the movie category on which the most money was spent

WITH revenue_by_category AS
	(SELECT c.name AS category, 
		SUM(p.amount) AS total_rental_amount
	FROM category c
	INNER JOIN film_category fc 
	ON c.category_id = fc.category_id
	INNER JOIN inventory i
	ON fc.film_id = i.film_id
	INNER JOIN rental r
	ON i.inventory_id = r.inventory_id
	INNER JOIN payment p 
	ON r.rental_id = p.rental_id
	GROUP BY c.name) 
SELECT *
FROM revenue_by_category 
WHERE total_rental_amount =
	(SELECT MAX(total_rental_amount) FROM revenue_by_category);


-- 4. the names of films that are not in 'inventory'. A query without the IN operator
-- 4.1 A solution with 'except'

SELECT f.film_id, f.title AS film_name
FROM film f

EXCEPT

SELECT i.film_id, f.title AS film_name
FROM film f 
INNER JOIN inventory i 
ON f.film_id = i.film_id;

-- 4.2 another solution by checking for null values
SELECT f.film_id, f.title AS film_name
FROM film f 
LEFT JOIN inventory i 
ON f.film_id = i.film_id
WHERE i.film_id IS NULL;

-- 4.3 third solution using NOT EXIST as a type of ANTI SEMI JOIN

SELECT f.film_id, f.title AS film_name
FROM film f 
WHERE NOT EXISTS (
	SELECT i.film_id
	FROM inventory i 
	WHERE i.film_id = f.film_id 
);


/* 5. top 3 actors who appeared the most in films in the “Children” category 
(If several actors have the same number of films, all should be displayed) */

WITH ranked_actors_by_number_of_films AS 
	(SELECT a.first_name ||' '|| a.last_name AS actor_full_name, 
		COUNT(*) AS number_of_films_children_category,
		DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_by_number_of_films
	FROM actor a 
	INNER JOIN film_actor fa 
	ON a.actor_id = fa.actor_id
	INNER JOIN film_category fc 
	ON fa.film_id = fc.film_id
	INNER JOIN category c 
	ON fc.category_id = c.category_id
	WHERE c.name = 'Children'
	GROUP BY a.actor_id
	ORDER BY number_of_films_children_category DESC
	)
SELECT *
FROM ranked_actors_by_number_of_films -- in the “Children” category
WHERE rank_by_number_of_films <=3;


/* 6. Cities with the number of active and inactive customers (active — customer.active = 1). 
Sorted by the number of inactive customers in DESC order */

SELECT 
	c.city_id, 
	c.city, 
	COUNT(CASE WHEN cust.active = 1 THEN 1 END) AS active_customers,
	COUNT(CASE WHEN cust.active = 0 THEN 1 END) AS inactive_customers
FROM city c 
INNER JOIN address a 
ON c.city_id = a.city_id
INNER JOIN customer cust 
ON a.address_id = cust.address_id
GROUP BY c.city_id
ORDER BY inactive_customers DESC;


/* 7. The category of films that has the largest number of hours of total rental in cities 
 (customer.address_id in this city), and which begin with the letter “a”.
 The same for cities that have the “-” symbol. One query. */

WITH category_rental AS (
    SELECT 
        CASE 
            WHEN UPPER(c.city) LIKE 'A%' THEN 'cities starting with A'
            WHEN c.city LIKE '%-%' THEN 'cities with a hyphen in their name'
        END AS city_group,
        cat.name AS category,
        SUM(f.rental_duration) AS total_rental_hours
    FROM city c
    INNER JOIN address a ON c.city_id = a.city_id
    INNER JOIN customer cust ON a.address_id = cust.address_id
    INNER JOIN rental r ON cust.customer_id = r.customer_id 
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
    INNER JOIN film_category fc ON f.film_id = fc.film_id
    INNER JOIN category cat ON fc.category_id = cat.category_id
    WHERE UPPER(c.city) LIKE 'A%' OR c.city LIKE '%-%'
    GROUP BY city_group, cat.name
),
ranked_categories AS (
	SELECT *,
    	DENSE_RANK() OVER (PARTITION BY city_group ORDER BY total_rental_hours DESC) AS rank_by_rental_hours
    FROM category_rental
)

SELECT 'cities starting with A' AS city_group, category, total_rental_hours
FROM ranked_categories
WHERE city_group = 'cities starting with A'
AND rank_by_rental_hours = 1

UNION ALL

SELECT 'cities with a hyphen in their name' AS city_group, category, total_rental_hours
FROM ranked_categories
WHERE city_group = 'cities with a hyphen in their name'
AND rank_by_rental_hours = 1;
