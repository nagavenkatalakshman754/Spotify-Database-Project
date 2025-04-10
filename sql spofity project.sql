use sqlproject;

-- Employee Table
ALTER TABLE employee
ADD CONSTRAINT PK_employee PRIMARY KEY (employee_id);

-- Customer Table
ALTER TABLE customer
ADD CONSTRAINT PK_customer PRIMARY KEY (customer_id);

-- Invoice Table
ALTER TABLE invoice
ADD CONSTRAINT PK_invoice PRIMARY KEY (invoice_id);

ALTER TABLE invoice
ADD CONSTRAINT FK_invoice_customer 
FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

-- Invoice_Line Table
ALTER TABLE invoice_line
ADD CONSTRAINT PK_invoice_line 
PRIMARY KEY (invoice_line_id);

ALTER TABLE invoice_line
ADD CONSTRAINT FK_invoice_line_invoice 
FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id);

ALTER TABLE invoice_line
ADD CONSTRAINT FK_invoice_line_track 
FOREIGN KEY (track_id) REFERENCES track(track_id);

-- Playlist Table
ALTER TABLE playlist
ADD CONSTRAINT PK_playlist PRIMARY KEY (playlist_id);

-- Playlist_Track Table
ALTER TABLE playlist_track
ADD CONSTRAINT PK_playlist_track 
PRIMARY KEY (playlist_id, track_id); -- Composite Key

ALTER TABLE playlist_track
ADD CONSTRAINT FK_playlist_track_playlist 
FOREIGN KEY (playlist_id) REFERENCES playlist(playlist_id);

ALTER TABLE playlist_track
ADD CONSTRAINT FK_playlist_track_track 
FOREIGN KEY (track_id) REFERENCES track(track_id);

-- Track Table
ALTER TABLE track
ADD CONSTRAINT PK_track PRIMARY KEY (track_id);

ALTER TABLE track
ADD CONSTRAINT FK_track_album 
FOREIGN KEY (album2_id) REFERENCES album(album2_id);

ALTER TABLE track
ADD CONSTRAINT FK_track_media_type 
FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id);

ALTER TABLE track
ADD CONSTRAINT FK_track_genre 
FOREIGN KEY (genre_id) REFERENCES genre(genre_id);

-- Media_Type Table
ALTER TABLE media_type
ADD CONSTRAINT PK_media_type PRIMARY KEY (media_type_id);

-- Artist Table
ALTER TABLE artist
ADD CONSTRAINT PK_artist PRIMARY KEY (artist_id);

-- Album Table
ALTER TABLE album2
ADD CONSTRAINT PK_album PRIMARY KEY (album2_id);

ALTER TABLE album2
ADD CONSTRAINT FK_album_artist 
FOREIGN KEY (artist_id) REFERENCES artist(artist_id);

-- Genre Table
ALTER TABLE genre
ADD CONSTRAINT PK_genre PRIMARY KEY (genre_id);

-- Self-Referencing Foreign Key for Employee (reports_to)
ALTER TABLE employee
ADD CONSTRAINT FK_employee_reports_to 
FOREIGN KEY (reports_to) REFERENCES employee(employee_id);

-- Adding foreign key to customer table from employee table
ALTER TABLE customer
ADD CONSTRAINT FK_customer_support_rep 
FOREIGN KEY (support_rep_id) REFERENCES employee(employee_id);

desc artist;
desc album2;
desc customer;
desc employee;
desc invoice;
desc invoice_line;
desc playlist;
desc playlist_track;
desc track;
desc media_type;
desc genre;

-- Easy Level Questions:

-- 1. Who is the senior most employee based on job title?

SELECT * FROM employee
ORDER BY levels DESC LIMIT 1;

-- 2. Which countries have the most Invoices?

SELECT billing_country, COUNT(*) AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;

-- 3. What are top 3 values of total invoice?

SELECT total FROM invoice
ORDER BY total DESC LIMIT 3;

-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city that has made the most money.

SELECT billing_city, SUM(total) AS total_invoice_value
FROM invoice
GROUP BY billing_city
ORDER BY total_invoice_value DESC
LIMIT 1;

-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer.

SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;

-- Moderate Level Questions:

-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners.

SELECT c.email, c.first_name, c.last_name, g.name AS genre_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;

-- 2. Let's invite the artists who have written the most rock music in our dataset.

SELECT ar.name AS artist_name, COUNT(t.track_id) AS track_count
FROM artist ar
JOIN album2 al ON ar.artist_id = al.artist_id
JOIN track t ON al.album_id = t.album_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.name
ORDER BY track_count DESC
LIMIT 10;

-- 3. Return all the track names that have a song length longer than the average song length.

SELECT name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;

-- Advanced Level Questions:

-- 1. Find how much amount spent by each customer on artists?

WITH customer_artist_spending AS (
    SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name, ar.name AS artist_name, SUM(il.unit_price * il.quantity) AS amount_spent
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN album2 al ON t.album_id = al.album_id
    JOIN artist ar ON al.artist_id = ar.artist_id
    GROUP BY c.customer_id, customer_name, ar.name
)
SELECT customer_name, artist_name, amount_spent
FROM customer_artist_spending
ORDER BY customer_name, amount_spent DESC;

-- 2. We want to find out the most popular music Genre for each country.

WITH popular_genre_by_country AS (
    SELECT i.billing_country, g.name AS genre_name, COUNT(il.quantity) AS purchase_count,
           ROW_NUMBER() OVER (PARTITION BY i.billing_country ORDER BY COUNT(il.quantity) DESC) AS rn
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY i.billing_country, g.name
)
SELECT billing_country, genre_name
FROM popular_genre_by_country
WHERE rn = 1;

-- 3. Write a query that determines the customer that has spent the most on music for each country.

WITH customer_total_spending AS (
    SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name, i.billing_country, SUM(i.total) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS rn
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, customer_name, i.billing_country
)
SELECT billing_country, customer_name, total_spent
FROM customer_total_spending
WHERE rn = 1;