-- 1. number of films in each category, sorted in DESC order
SELECT c.name AS film_category, COUNT(fc.film_id) AS number_of_films 
FROM category c
LEFT JOIN film_category fc
ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY number_of_films DESC;

-- 2. top 10 actors whose films were rented the most, sorted in DESC order
SELECT *
FROM (
	SELECT 
		a.actor_id,
		a.first_name ||' '|| a.last_name AS actor_full_name,
		COUNT(r.rental_id) AS rental_count,
		dense_rank() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rank_by_rental_count -- ranked to prevent losing actors with the same rental_count 
	FROM actor a
	JOIN film_actor fa 
	ON a.actor_id = fa.actor_id
	JOIN inventory i 
	ON fa.film_id = i.film_id
	JOIN rental r
	ON i.inventory_id = r.inventory_id
	GROUP BY a.actor_id
) AS ranked_actors_by_rental_count
WHERE rank_by_rental_count <=10 
ORDER BY rank_by_rental_count;


-- 3. the movie category on which the most money was spent

WITH revenue_by_category AS
	(SELECT c.name AS category, 
		SUM(p.amount) AS total_rental_amount
	FROM category c
	LEFT JOIN film_category fc 
	ON c.category_id = fc.category_id
	JOIN inventory i
	ON fc.film_id = i.film_id
	JOIN rental r
	ON i.inventory_id = r.inventory_id
	JOIN payment p 
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
JOIN inventory i 
ON f.film_id = i.film_id;

-- 4.2 another solution by checking for null values
SELECT f.film_id, f.title AS film_name
FROM film f 
LEFT JOIN inventory i 
ON f.film_id = i.film_id
WHERE i.film_id IS NULL;


/* 5. top 3 actors who appeared the most in films in the “Children” category 
(If several actors have the same number of films, all should be displayed) */

/* 6. Cities with the number of active and inactive customers (active — customer.active = 1). 
Sorted by the number of inactive customers in DESC order */

/* 7. The category of films that has the largest number of hours of total rental in cities 
 (customer.address_id in this city), and which begin with the letter “a”.
 The same for cities that have the “-” symbol. One query. */




