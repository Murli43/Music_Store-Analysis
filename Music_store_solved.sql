-- Q1. Who is the senior most employee based on job title?

SELECT TOP 1 * 
FROM employee
ORDER BY levels DESC;

-- Q2. Which countries have the most Invoices?

SELECT TOP 1 billing_country, COUNT(invoice_id) AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;

-- Q3. What are the top 3 values of total invoice?

SELECT TOP 3 *
FROM invoice
ORDER BY total DESC;

-- Q4. Which city has the best customers?

SELECT TOP 1 billing_city, SUM(total) AS total
FROM invoice
GROUP BY billing_city
ORDER BY total DESC;

-- Q5. Who is the best customer?

SELECT TOP 1 c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total DESC;

-- Q6. Rock Music listeners

SELECT DISTINCT email, first_name, last_name 
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN (
    SELECT track_id 
    FROM track
    JOIN genre ON genre.genre_id = track.genre_id
    WHERE genre.name = 'Rock'
)
ORDER BY email;

-- Q7. Top 10 Rock Bands

SELECT TOP 10 artist.artist_id, artist.name, COUNT(track.track_id) AS num_of_songs
FROM artist
JOIN album ON album.artist_id = artist.artist_id
JOIN track ON track.album_id = album.album_id
WHERE genre_id IN (
    SELECT genre_id FROM genre WHERE name = 'Rock'
)
GROUP BY artist.artist_id, artist.name
ORDER BY num_of_songs DESC;

-- Q8. Tracks longer than average

SELECT name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;

-- Q9. Amount spent by each customer on artists

WITH BestSellingArtist AS (
    SELECT artist.artist_id, artist.name AS artist_name, 
           SUM(invoice_line.unit_price * invoice_line.quantity) AS total_spent
    FROM invoice_line
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN album ON album.album_id = track.album_id
    JOIN artist ON artist.artist_id = album.artist_id
    GROUP BY artist.artist_id, artist.name
)
SELECT c.customer_id, c.first_name, bsa.artist_name, 
       SUM(il.unit_price * il.quantity) AS total_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN BestSellingArtist bsa ON bsa.artist_id = al.artist_id
GROUP BY c.customer_id, c.first_name, bsa.artist_name
ORDER BY total_spent DESC;

-- Q10. Most popular music Genre for each country

WITH PopularGenre AS (
    SELECT COUNT(il.quantity) AS purchases, c.country, g.name AS genre_name,
           ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS row_num
    FROM invoice_line il
    JOIN invoice i ON i.invoice_id = il.invoice_id
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY c.country, g.name
)
SELECT country, genre_name, purchases 
FROM PopularGenre 
WHERE row_num = 1;

-- Q11. Top customer in each country

WITH CustomerWithCountry AS (
    SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, SUM(i.total) AS total_spent,
           ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS row_num
    FROM invoice i
    JOIN customer c ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, i.billing_country
)
SELECT customer_id, first_name, last_name, billing_country, total_spent
FROM CustomerWithCountry
WHERE row_num = 1;

-- Q12. Most popular artists

SELECT COUNT(il.quantity) AS purchases, a.name AS artist_name
FROM invoice_line il
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN artist a ON a.artist_id = al.artist_id
GROUP BY a.name
ORDER BY purchases DESC;

-- Q13. Most popular song

SELECT TOP 1 COUNT(il.quantity) AS purchases, t.name AS song_name
FROM invoice_line il
JOIN track t ON t.track_id = il.track_id
GROUP BY t.name
ORDER BY purchases DESC;

-- Q14. Average prices of different types of music

WITH Purchases AS (
    SELECT g.name AS genre, SUM(i.total) AS total_spent
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY g.name
)
SELECT genre, FORMAT(AVG(total_spent), 'C', 'en-US') AS total_spent
FROM Purchases
GROUP BY genre;

-- Q15. Most popular countries for music purchases

SELECT COUNT(il.quantity) AS purchases, c.country
FROM invoice_line il
JOIN invoice i ON i.invoice_id = il.invoice_id
JOIN customer c ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY purchases DESC;
