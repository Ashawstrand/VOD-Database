--PHASE 3: VOD SQL Queries & Reporting
--Purpose: Utilize SQL Concepts and Provide Value and Insight to Business
--Author: Ashley Shaw-Strand

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--REPORT 1: Movie Titles Ranked With Largest Total Rental Revenue
--Purpose: Display movies with the highest total rental revenue, including rental count, average customer rating, total revenue, and revenue rank. Identify top-performing content for business.
--SQL Concepts: Display group aggregate functions / JOINS / filter and order data

SELECT 
    m.title AS movie_title,
    COUNT(r.rental_id) AS rental_count,
    ROUND(AVG(r.customer_rating)::numeric, 2) AS avg_customer_rating,
    ROUND(SUM(r.price_paid)::numeric, 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(r.price_paid) DESC) AS revenue_rank
FROM Movie m
LEFT JOIN Rental r ON m.movie_id = r.movie_id
WHERE r.rental_date >= CURRENT_DATE - INTERVAL '6 months'
AND m.movie_id NOT IN (
    SELECT movie_id 
    FROM Movie 
    WHERE is_coming_soon = TRUE
)
GROUP BY m.movie_id, m.title
HAVING SUM(r.price_paid) > 0
ORDER BY total_revenue DESC
LIMIT 20;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--REPORT 2: Highest-Rated Customer Rentals
--Purpose: Display highest-rated movie titles (5 stars) with categories,how many times they were rated, total rental cost, and rating rank. Identify highly rated content for business marketing.
--SQL Concepts: Display use of JOINS, single-row functions, group functions

SELECT 
    m.title AS movie_title,
    STRING_AGG(DISTINCT cat.name, ', ') AS categories,
    COUNT(r.rental_id) AS high_rating_count,
    ROUND(SUM(r.price_paid)::numeric, 2) AS total_rental_cost,
    RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rating_rank
FROM Movie m
INNER JOIN Rental r ON m.movie_id = r.movie_id
INNER JOIN movie_category mc ON m.movie_id = mc.movie_id
INNER JOIN Category cat ON mc.category_id = cat.category_id
WHERE r.customer_rating = 5
AND r.rental_date >= CURRENT_DATE - INTERVAL '6 months'
AND m.movie_id NOT IN (
    SELECT movie_id 
    FROM Movie 
    WHERE is_coming_soon = TRUE
)
GROUP BY m.movie_id, m.title
HAVING COUNT(r.rental_id) > 1
ORDER BY high_rating_count DESC, m.title
;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--REPORT 3: Top Customers by Total Rental Count and Amount Spent
--Purpose: Display most active customers with the highest number of rentals, including their email, rental count, rental dates for recency,total spending, and ranking. Identify key customers for the business.
--SQL Concepts: OLAP / Single-Row Functions


SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    UPPER(c.email) AS customer_email,
    COUNT(r.rental_id) AS total_rental_count,
    STRING_AGG(TO_CHAR(r.rental_date, 'YYYY-MM-DD'), ', ') AS rental_dates,
    ROUND(SUM(r.price_paid)::numeric, 2) AS total_spent,
    RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rental_rank
FROM Customer c
INNER JOIN Rental r ON c.customer_id = r.customer_id
INNER JOIN Movie m ON r.movie_id = m.movie_id
WHERE r.rental_date >= CURRENT_DATE - INTERVAL '6 months'
AND m.movie_id NOT IN (
    SELECT movie_id 
    FROM Movie 
    WHERE is_coming_soon = TRUE
)
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING COUNT(r.rental_id) > (
    SELECT AVG(rental_count)::numeric
    FROM (
        SELECT COUNT(rental_id) AS rental_count
        FROM Rental
        WHERE rental_date >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY customer_id
    ) sub
)
ORDER BY total_rental_count DESC
;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Report 4: Top Movies with Both Above-Average Rentals and High Ratings
--Purpose: Identify movies with above-average rental counts and average customer rating >= 4. Includes categories, rental count, and total revenue. Help business promote popular high-quality content.
--SQL Concepts: JOINS / Subqueries / Group Aggregate Functions

SELECT 
    m.title AS movie_title,
    STRING_AGG(DISTINCT cat.name, ', ') AS categories,
    COUNT(r.rental_id) AS rental_count,
    ROUND(AVG(r.customer_rating)::numeric, 2) AS avg_customer_rating,
    ROUND(SUM(r.price_paid)::numeric, 2) AS total_revenue,
    RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rental_rank
FROM Movie m
INNER JOIN Rental r ON m.movie_id = r.movie_id
INNER JOIN movie_category mc ON m.movie_id = mc.movie_id
INNER JOIN Category cat ON mc.category_id = cat.category_id
WHERE r.rental_date >= CURRENT_DATE - INTERVAL '6 months'
AND m.movie_id NOT IN (
    SELECT movie_id 
    FROM Movie 
    WHERE is_coming_soon = TRUE
)
AND m.movie_id IN (
    SELECT r2.movie_id
    FROM Rental r2
    WHERE r2.rental_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY r2.movie_id
    HAVING COUNT(r2.rental_id) > (
        SELECT AVG(rental_count)::numeric
        FROM (
            SELECT COUNT(rental_id) AS rental_count
            FROM Rental
            WHERE rental_date >= CURRENT_DATE - INTERVAL '6 months'
            GROUP BY movie_id
        ) sub
    )
)
GROUP BY m.movie_id, m.title
HAVING AVG(r.customer_rating) >= 4
ORDER BY rental_count DESC
LIMIT 50;


-------------------------------------------------------------------------------------------------------------------------------------------


--Report 5: Most Wished-For Movies
--Purpose: Display movies with the highest wishlist counts, ranking, and includes categories to identify content for the business to prioritize.
--SQL Concepts: JOINS / Subqueries / Group Functions

SELECT 
    m.title AS movie_title,
    STRING_AGG(DISTINCT cat.name, ', ') AS categories,
    COUNT(w.movie_id) AS wishlist_count,
    RANK() OVER (ORDER BY COUNT(w.movie_id) DESC) AS wishlist_rank
FROM Movie m
INNER JOIN Wishlist w ON m.movie_id = w.movie_id
INNER JOIN movie_category mc ON m.movie_id = mc.movie_id
INNER JOIN Category cat ON mc.category_id = cat.category_id
WHERE m.movie_id NOT IN (
    SELECT movie_id 
    FROM Movie 
    WHERE is_coming_soon = TRUE
)
GROUP BY m.movie_id, m.title
HAVING COUNT(w.movie_id) > (
    SELECT AVG(wishlist_count)::numeric
    FROM (
        SELECT COUNT(movie_id) AS wishlist_count
        FROM Wishlist
        GROUP BY movie_id
    ) sub
)
ORDER BY wishlist_count DESC, m.title
LIMIT 50;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Report 6: Most Watched Actors
--Purpose: Display actors with the highest ranked rental counts for their movies. Includes the movie titles and categories, to identify popular actors for business promotions.
--SQL Concepts: JOINS/ Group Functions / Filter and Order Data / Subqueries

SELECT 
    CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT cat.name, ', ') AS categories,
    COUNT(r.rental_id) AS rental_count,
    RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS actor_rank
FROM Actor a
INNER JOIN movie_actor ma ON a.actor_id = ma.actor_id
INNER JOIN Movie m ON ma.movie_id = m.movie_id
INNER JOIN Rental r ON m.movie_id = r.movie_id
INNER JOIN movie_category mc ON m.movie_id = mc.movie_id
INNER JOIN Category cat ON mc.category_id = cat.category_id
WHERE r.rental_date >= CURRENT_DATE - INTERVAL '6 months'
AND m.movie_id NOT IN (
    SELECT movie_id 
    FROM Movie 
    WHERE is_coming_soon = TRUE
)
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING COUNT(r.rental_id) > (
    SELECT AVG(rental_count)::numeric
    FROM (
        SELECT COUNT(rental_id) AS rental_count
        FROM Rental
        WHERE rental_date >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY movie_id
    ) sub
)
ORDER BY rental_count DESC, actor_name
LIMIT 50;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Report 7: Directors with Highest Ratings and Revenue
--Purpose: Display directors whose movies have the highest ratings and revenue. Includes movie titles, categories, director ranking, and total revenue to identify the top directors for business promotions.
--SQL Concepts: JOINS / Group Functions / Filter and Order Data / Subqueries

SELECT 
    CONCAT(d.first_name, ' ', d.last_name) AS director_name,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT cat.name, ', ') AS categories,
    COUNT(r.rental_id) AS high_rating_count,
    ROUND(SUM(r.price_paid)::numeric, 2) AS total_revenue,
    RANK() OVER (ORDER BY COUNT(r.rental_id) DESC, SUM(r.price_paid) DESC) AS director_rank
FROM Director d
INNER JOIN movie_director md ON d.director_id = md.director_id
INNER JOIN Movie m ON md.movie_id = m.movie_id
INNER JOIN Rental r ON m.movie_id = r.movie_id
INNER JOIN movie_category mc ON m.movie_id = mc.movie_id
INNER JOIN Category cat ON mc.category_id = cat.category_id
WHERE r.customer_rating = 5
AND r.rental_date >= CURRENT_DATE - INTERVAL '6 months'
AND m.movie_id NOT IN (
    SELECT movie_id 
    FROM Movie 
    WHERE is_coming_soon = TRUE
)
GROUP BY d.director_id, d.first_name, d.last_name
HAVING COUNT(r.rental_id) > (
    SELECT AVG(rental_count)::numeric
    FROM (
        SELECT COUNT(rental_id) AS rental_count
        FROM Rental
        WHERE customer_rating = 5
        AND rental_date >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY movie_id
    ) sub
)
AND SUM(r.price_paid) > (
    SELECT AVG(revenue)::numeric
    FROM (
        SELECT SUM(price_paid) AS revenue
        FROM Rental
        WHERE customer_rating = 5
        AND rental_date >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY movie_id
    ) sub
)
ORDER BY high_rating_count DESC, total_revenue DESC, director_name
LIMIT 100;