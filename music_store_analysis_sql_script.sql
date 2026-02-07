-- Q1: Who is the senior most employee based on the job title?

SELECT * FROM music_store.employee
ORDER BY levels DESC
LIMIT 1;

-- Q2: Which country have the most invoices?

SELECT billing_country, count(invoice_id)
FROM music_store.invoice
group by billing_country
order by count(invoice_id) desc;

-- Q3: What are the top 3 values of total invoice?

select total from music_store.invoice
order by total desc
limit 3;

-- Q4: Which city has the best customers? We woild like to throw a promotional Music Festival in the city 
-- we made the most money. Write a query that returns one city that has the highest sum of invoice totals.
-- Return both the city name & sum of all invoice totals.

select billing_city, sum(total) 
from music_store.invoice
group by billing_city
order by sum(total) desc;

-- Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer.
-- Write a query that returns the person who has spent the most money.

select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total)
from music_store.customer
join music_store.invoice
on customer.customer_id= invoice.customer_id
group by customer.customer_id, customer.first_name, customer.last_name
order by sum(invoice.total) desc
limit 1;

-- 	MODERATE 

-- Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabatically by email starting with A

select distinct customer.first_name, customer.last_name, customer.email
from music_store.customer
join music_store.invoice 
on customer.customer_id = invoice.invoice_id
join music_store.invoice_line
on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
select track_id
from music_store.track
join music_store.genre
on track.genre_id = genre.genre_id
where genre.name like 'Rock')
order by customer.email;

-- Q2: Let's invite the artist who have written the most rock music in our dataset. Write a query that returns the Aritst name 
-- and total track count of the top 10 rock brands

select artist.name, artist.artist_id, count(artist.artist_id) as number_of_songs
from music_store.track
join music_store.album2
on track.album_id = album2.album_id
join music_store.artist
on album2.artist_id = artist.artist_id
join music_store.genre
on track.genre_id = genre.genre_id
where genre.name like 'Rock'
group by artist.artist_id, artist.name
order by number_of_songs desc
limit 10;




-- Q3: Return all the track names that have a song length longer than the average song length. Retrun the name and Milliseconds for each track.
-- Order by the song length with the longest songs listed first.

select track.name, track.milliseconds 
from music_store.track
where milliseconds > 
(select avg(track.milliseconds)
from music_store.track) 
order by track.milliseconds desc;

-- ADVANCE

-- Q1 Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent.

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album2 ON album2.album_id = track.album_id
	JOIN artist ON artist.artist_id = album2.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album2 alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- Q2: We want to find out the most popular music Genre For each country. 
-- We determine the most popular genre as the genre with the highest amount of purchase. 
-- Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared return all Genres.

select g.genre_id, g.name, inv.billing_country, (inv.total) as total
from music_store.genre as g
join music_store.track as t
on g.genre_id = t.genre_id
join music_store.invoice_line as inl
on inl.track_id = t.track_id 
join music_store.invoice as inv
on inv.invoice_id = inl.invoice_id
join music_store.customer as c
on c.customer_id = inv.customer_id;

-- Method 1:

with popular_genre as
(
select count(invoice_line.quantity) as purchases, customer.country, genre.name, genre.genre_id,
row_number() over(partition by customer.country order by count(invoice_line.quantity) desc) as RowNo
from music_store.invoice_line
join music_store.invoice on invoice.invoice_id = invoice_line.invoice_id
join music_store.customer on customer.customer_id = invoice.customer_id
join music_store.track on track.track_id = invoice_line.track_id
join music_store.genre on genre.genre_id = track.genre_id
group by 2,3,4
order by 2 asc, 1 desc
)
select * from popular_genre where RowNo <= 1;

-- Method 2: 

with recursive
sales_per_country as(
select count(*) as purchases_per_genre, customer.country, genre.name, genre.genre_id
from music_store.invoice_line
join music_store.invoice on invoice.invoice_id = invoice_line.invoice_id
join music_store.customer on customer.customer_id = invoice.customer_id
join music_store.track on track.track_id = invoice_line.track_id
join music_store.genre on genre.genre_id = track.genre_id
group by 2,3,4
order by 2
),
max_genre_per_country as (select Max(purchases_per_genre) as max_genre_number, country
from sales_per_country
group by 2
order by 2)

select sales_per_country.*
from sales_per_country
join max_genre_per_country on sales_per_country.country = max_genre_per_country.country
where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

-- Q3: Write a query that determines the customer that has spent the most on music for each country.
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared,
-- provide all customers who spent this amount

-- Method 1:

with recursive
customer_with_country as (
select customer.customer_id, first_name, last_name, billing_country, sum(total) as total_spending 
from music_store.invoice
join music_store.customer on customer.customer_id = invoice.customer_id
group by 1,2,3,4
order by 2,3 desc),

country_max_spending as(
select billing_country, max(total_spending) as max_spending
from customer_with_country
group by billing_country)
select cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
from customer_with_country cc
join country_max_spending ms
on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
order by 1;

-- Method 2:

with customer_with_country as (
select customer.customer_id, first_name, last_name, billing_country, sum(total) as total_spending,
row_number() over(partition by billing_country order by sum(total) desc) as Rowno
from music_store.invoice
join music_store.customer on customer.customer_id = invoice.customer_id
group by 1,2,3,4
order by 4 asc, 5 desc)
select * from customer_with_country where RowNo <=1