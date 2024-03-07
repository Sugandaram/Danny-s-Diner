CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;
use dannys_diner;
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

select * from sales;

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  # Case Study Questions
#--------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_spend
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id, count(DISTINCT order_date) as days_visited 
FROM dannys_diner.sales as s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?

select distinct foo.customer_id,m.product_name
from
(select s.*,
	rank () over (partition by s.customer_id order by s.order_date) as r
from dannys_diner.sales as s
) as foo
left join dannys_diner.menu as m
on(foo.product_id=m.product_id)
where foo.r = 1;


-- 4. What is the most purchased item on the menu and how many
-- times was it purchased by all customers?
select m.product_name, count(s.product_id) as total_purchased
from dannys_diner.sales as s
inner join dannys_diner.menu as m
on (s.product_id=m.product_id)
group by m.product_name;

-- 5. Which item was the most popular for each customer?

SELECT foo.customer_id, m.product_name
FROM (
    SELECT s.customer_id, s.product_id, COUNT(s.product_id) AS total_purchased,
           RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS r
    FROM 
    GROUP BY s.customer_id, s.product_id
) AS foo
LEFT JOIN dannys_diner.menu AS m ON foo.product_id = m.product_id
WHERE foo.r = 1;

-- 6. Which item was purchased first by the customer after they became a member?
select foo.customer_id, foo.product_name
from
(select s.customer_id,mm.join_date, s.order_date, s.product_id, m.product_name,
	RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS r
from dannys_diner.sales as s
left join dannys_diner.members as mm
on(s.customer_id=mm.customer_id)
left join dannys_diner.menu as m
on(s.product_id=m.product_id)
where mm.join_date<s.order_date) as foo
where foo.r = 1;


-- 7. Which item was purchased just before the customer became a member?


SELECT foo.customer_id, foo.product_id
FROM (
    SELECT s.customer_id, 
		   m.product_id, 
           s.order_date,
           RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS r
    FROM dannys_diner.sales AS s
    JOIN dannys_diner.members AS mm 
    ON s.customer_id = mm.customer_id
    JOIN dannys_diner.menu AS m 
    ON s.product_id = m.product_id
    WHERE s.order_date < mm.join_date) AS foo
WHERE foo.r = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id,
	count(s.product_id) as total_items,
    sum(m.price) as total_spent
from dannys_diner.sales as s
left join dannys_diner.members as mm
on s.customer_id=mm.customer_id
left join dannys_diner.menu as m
on s.product_id=m.product_id
where s.order_date < mm.join_date
group by s.customer_id;
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
select s.customer_id,
sum(
	case when m.product_name = 'sushi' then 2 * 10 * m.price
    else 10*m.price end
)as total_points
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id=m.product_id
group by s.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 
-- 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select foo.customer_id, sum(foo.points) as total_points
from
(selects.*, mm.join_date, m.price,
	case when(s.order_date-mm.join_date) <= 7 then 2 * 10 * m.price
    when (s.order_date-mm.join_date) >7 and m.product_name = 'sushi' then 2 * 10 * m.price
    when (s.order_date-mm.join_date) >0 and m.product_name = 'sushi' then 2 * 10 * m.price
    else 10 * m.price end as points
from dannys_diner.sales as s
left join dannys_diner.members as mm
on s.customer_id = mm.customer_id
left join dannys_diner.menu as m
on s.product-id = m.product_id
where s.customer_id in ('A', 'B') and s.order_date <= '2021-10-31') as foo
group by foo.customer_id;
    


  
