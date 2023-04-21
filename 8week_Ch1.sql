use dannys_diner;


CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', 10),
  ('2', 'curry', 15),
  ('3', 'ramen', 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  
  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?


select s.customer_id,   sum(m.price) as total_amount
from sales s join menu m
on  s.product_id=m.product_id
group by 1;





-- 2. How many days has each customer visited the restaurant?

select customer_id,   count(1) as no_of_days
from sales group by 1;




-- 3. What was the first item from the menu purchased by each customer?

select	s.customer_id,	 m.product_name as first_prod_ordered
from menu m join (
select  customer_id,
 first_value(product_id) over (partition by customer_id order by order_date) as first_prod
from  sales group by 1) s
on s.first_prod=m.product_id;




-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name , s.times_purchased from menu m join
(select  product_id,count( product_id) as times_purchased
from sales group by  product_id
order by 2 desc limit 1) s 
on m.product_id= s.product_id;



-- 5. Which item was the most popular for each customer?

select s.customer_id, s.popularity as no_of_times_purchased, m.product_name       from(
select customer_id, product_id,count( product_id) as popularity ,
dense_rank() over (partition by customer_id order by count( product_id) desc) as ranking
 from sales 
group by customer_id, product_id )s join menu m
on s.product_id=m.product_id
where s.ranking=1 
order by 1;


-- 6. Which item was purchased first by the customer after they became a member?

select  sub.customer_id, first_value(sub.product_id) over( partition by sub.customer_id order by sub.order_date)
 as first_ordered_prod, m1.product_name
from(
select s.customer_id, s.order_date, s.product_id
,  m.join_date
 from sales s join members m 
 on s.customer_id=m.customer_id
 and s.order_date > m.join_date 
   ) sub  join menu m1
   on m1.product_id= sub.product_id
   group by sub.customer_id;
   
-- alternate solution

select sub.customer_id,  sub.product_id  ,  m1.product_name     
from(	select s.customer_id, s.order_date, s.product_id,
		m.join_date, dense_rank() over( partition by s.customer_id order by s.order_date) as rn
		 from sales s join members m 
		 on s.customer_id=m.customer_id
		 and s.order_date > m.join_date order by 2) sub
		join menu m1 on m1.product_id =sub.product_id
        where sub.rn=1 
        order by sub.customer_id;


-- 7. Which item was purchased just before the customer became a member?


select  sub.customer_id, sub.last_bought_prod_id, m1.product_name
from menu m1 join 
	(select distinct customer_id, 
	last_value( product_id) over (partition by customer_id order by order_date 
	range between unbounded preceding and unbounded following) as last_bought_prod_id
      from(
			select s.customer_id, s.order_date, s.product_id, m.join_date
			from sales s join members m on 
			s.customer_id = m.customer_id and
			s.order_date < m.join_date
            
           ) x 
) sub
       on m1.product_id=sub.last_bought_prod_id order by 1;


 
-- 8. What is the total items and amount spent for each member before they became a member?
select customer_id, count(product_id) as total_items,
sum(price) as amount_spent_before_membrshp
from(
	select s.customer_id, s.order_date, s.product_id,
	m1.product_name,m1.price, m.join_date
	from sales s join members m
	on s.customer_id= m.customer_id
	and s.order_date < m.join_date
	join menu m1 
	on s.product_id=m1.product_id
	) sub
group by 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?

with data as (select s.customer_id,  s.product_id,m.product_name, m.price ,
			case when m.product_name="sushi" then 2 * m.price else 1 * m.price end as points
			from sales s join menu m
			on s.product_id=m.product_id)
select customer_id, sum(points) as total_points from data group by 1;


-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at
-- the end of January?


with data as (
select s.customer_id,  s.product_id,m.product_name, m.price , s.order_date, m1.join_date,
case when s.order_date <= m1.join_date + interval 6 Day then 2 * m.price
else 1 * m.price end as points
			from sales s join menu m
			on s.product_id=m.product_id
            join members m1 
            on s.customer_id=m1.customer_id
			and  s.order_date>=m1.join_date 
            where s.order_date <= "2021-01-31")
		
        select customer_id,  sum(points) as total_pts_before_jan from data group by 1 order by 1;

-- BONUS 
-- Re-create new table to show members as Y /N
    
    select s.customer_id, s.order_date, m.product_name, m.price ,
    case when s.order_date>= m1.join_date then "Y" else "N" end as member
			from sales s join menu m
			on s.product_id=m.product_id
            left join members m1 
            on s.customer_id=m1.customer_id
            order by 1,2;
 
-- BONUS
-- Danny also requires further information about the ranking of customer products, but he purposely
-- does not need the ranking for non-member purchases so he expects null ranking values for the records 
-- when customers are not yet part of the loyalty program.

   with cte as (
               select s.customer_id, s.order_date, m.product_name, m.price ,
    case when s.order_date>= m1.join_date then "Y" else "N" end as member
			from sales s join menu m
			on s.product_id=m.product_id
            left join members m1 
            on s.customer_id=m1.customer_id
            order by 1,2)
select * ,
case when member ='Y' then dense_rank() over (partition by customer_id,member order by  order_date) 
else null end as ranking
 from cte;