use fasoos;
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2020-01-08 21:30:45','25km','25mins',null),
(8,2,'2020-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2020-01-11 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01  18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

 1. how many rolls were ordered?
 
 select count(roll_id) from customer_orders;
 
 2. how many unique customers were made?
 
 select count( distinct customer_id) from customer_orders;
 
 3. how many successful orders were delivered by each driver?
 select * from driver_order;
 select driver_id, count( distinct order_id) successfull_order from driver_order where cancellation not in ('Cancellation','Customer Cancellation')
 group by driver_id;
 
 4. how many of each type of roll were delivered?
 -- here comes data cleaning part, as we will also deal with null cells
 -- select * from driver_order where cancellation not in ('Cancellation','Customer Cancellation');
select roll_id, count(roll_id) from customer_orders where order_id in
(select order_id from
(select *, case when cancellation in ('Cancellation','Customer Cancellation') then 'yes' else 'no' end as order_cancel
 from driver_order)a
where order_cancel='no')
group by roll_id;
 
 5. how many veg and non veg rolls were ordered by each customer?
 
 select * from customer_orders;
select a.*, b.roll_name from
( select customer_id, roll_id, count(roll_id) cnt from customer_orders 
 group by customer_id, roll_id)a inner join rolls b on a.roll_id=b.roll_id;
 
 6. what was the maximum number of rolls delivered in a single order?
-- here answer would be orderid 4 was delivered 3 rolls
select * from
(select *, rank() over (order by cnt desc) rnk from
(select order_id,count(roll_id) cnt from
 (select * from customer_orders where order_id in
 (select order_id from
(select *, case when cancellation in ('Cancellation','Customer Cancellation') then 'yes' else 'no' end as order_cancel
 from driver_order)a
where order_cancel='no'))b
group by order_id)c)d where rnk=1;

7.for each customer, how many delivered rolls had at least 1 change and how many had no change in ingredients?

with temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
( select order_id,customer_id,roll_id, 
case when not_include_items is null or not_include_items=''
then '0' else not_include_items end as new_not_include_items,
case when extra_items_included is null or extra_items_included = '' or extra_items_included = 'NaN'
then '0' else extra_items_included end as new_extra_items_included,
order_date from customer_orders)
select * from temp_customer_orders;
 
 
with temp_driver_order(order_id,driver_id,pickup_time,distance,duration,new_cancellation) as
(
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation in('Cancellation','Customer Cancellation' ) then 0 else 1 end as new_cancellation
from driver_order)
select * from temp_driver_order;

select * from temp_customer_orders where order_id in (
select order_id from temp_driver_order where new_cancellation!=0);      