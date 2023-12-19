--Q1: Who is the senior most employee based on job title?

SELECT first_name, last_name FROM employee
ORDER BY levels DESC
LIMIT 1;

--Q2: Which countries have the most Invoices?

SELECT billing_country, COUNT(*) AS C
FROM invoice
GROUP BY billing_country
ORDER BY C DESC;

--Q3: What are the top 3 values of the total invoice?

SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3;

--Q4: Which city has the best customers? 
--The company would like to throw a promotional Music Festival in the city 
--where the company made the most money. 
--Write a query that returns one city that has the highest sum of invoice totals
--Return both city names and the sum of all invoice totals.

SELECT billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC
LIMIT 1;

--Q5: Who is the best customer? 
--Write a query that returns the person who has spent the most. 
--(Hint- The customer who has spent the most will be declared as the best customer)

SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS amt
FROM customer
INNER JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY amt DESC
LIMIT 1;

--Q6: Write a query to return the email, first name, last name, & genre of all Rock Music listeners.
--Return your list with email addresses ordered alphabetically

SELECT DISTINCT email, first_name, last_name
FROM customer
INNER JOIN invoice ON customer.customer_id = invoice.customer_id
INNER JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	INNER JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name = 'Rock'
)
ORDER BY email;

--Another method:

SELECT DISTINCT email, first_name, last_name
FROM customer
INNER JOIN invoice ON invoice.customer_id = customer.customer_id
INNER JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
INNER JOIN track ON track.track_id = invoice_line.track_id
INNER JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;

--Q7: Invite the artists who have written the most Rock music album
--Write a query that returns the artist name and total track count of the top 10 Rock bands

SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM artist
INNER JOIN album ON artist.artist_id = album.artist_id
INNER JOIN track ON album.album_id = track.album_id
INNER JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

--Q8: Return all the track names that have a song length longer than the average song length
--Return the name and duration(in ms) for each track.
--Order by the song length in with the longest song listed first

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length 
	FROM track)
ORDER BY milliseconds DESC;

--Q9: Find the amount spent by each customers on artists. 
--Write a query to return the customer name, artist name, and total spent

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name,
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	INNER JOIN track ON track.track_id = invoice_line.track_id
	INNER JOIN album ON album.album_id = track.album_id
	INNER JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
INNER JOIN customer c ON c.customer_id = i.customer_id
INNER JOIN invoice_line il ON il.invoice_id = i.invoice_id
INNER JOIN track t ON t.track_id = il.track_id
INNER JOIN album alb ON alb.album_id = t.album_id
INNER JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

--Q10: Find out the most popular music genre for each country.
--Determine the most popular genre as the genre with the highest purchases
--Write a query that returns each country along with the top genre
--Return all genres for countries where the maximum number of purchases are shared.

WITH popular_genre AS
(
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id,
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
	FROM invoice_line
	INNER JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	INNER JOIN customer ON customer.customer_id = invoice.customer_id
	INNER JOIN track ON track.track_id = invoice_line.track_id
	INNER JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre
WHERE RowNo <=1

--Another method:

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		INNER JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		INNER JOIN customer ON customer.customer_id = invoice.customer_id
		INNER JOIN track ON track.track_id = invoice_line.track_id
		INNER JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.*
FROM sales_per_country
INNER JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

--Q11: Write a query that determines the customer who has spent the most on music for each country
--Write a query that returns the country along with the top customer and how much they spent.
--For countries where the top amount spent is shared, list all the customers who spent this amount.

WITH RECURSIVE
	customer_with_country AS(
		SELECT customer.customer_id, first_name, last_name, billing_country, 
		SUM(total) AS total_spending
		FROM invoice
		INNER JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),
	
	country_max_spending AS(
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY billing_country)
		
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
INNER JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;

--Another Method

WITH customer_with_country AS(
		SELECT customer.customer_id, first_name, last_name, billing_country,
		SUM(total) AS total_spending,
		ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
		FROM invoice
		INNER JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC, 5 DESC)
		
SELECT * FROM customer_with_country where RowNo <=1;