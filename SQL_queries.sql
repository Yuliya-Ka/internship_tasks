-- 1. number of films in each category, sorted in DESC order
SELECT c.name AS film_category, COUNT(fc.film_id) AS number_of_films 
FROM category c
LEFT JOIN film_category fc
ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY number_of_films DESC;

-- 2. top 10 actors whose films were rented the most, sorted in DESC order

-- 3. the movie category on which the most money was spent

-- 4. the names of films that are not in 'inventory'. A query without the IN operator

-- 5. top 3 actors who appeared the most in films in the “Children” category 
-- (If several actors have the same number of films, all should be displayed)


-- 6. Cities with the number of active and inactive customers (active — customer.active = 1). 
--Sorted by the number of inactive customers in DESC order

-- 7. 


