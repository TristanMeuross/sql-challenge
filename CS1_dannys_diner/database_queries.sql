
-- Question 1: How much did each customer spend?

SELECT customer_id, SUM(price)
FROM sales
INNER JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY customer_id

-- Question 2: How many days has each customer visited the restaurant

SELECT customer_id, COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id

-- Question 3: What was the first item from the menu purchased by each customer?

WITH product_rn AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as row_num
FROM sales)

SELECT customer_id, product_name as first_product
FROM product_rn
INNER JOIN menu
	ON product_rn.product_id = menu.product_id
WHERE row_num = 1

-- Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(*) AS purchases
FROM sales
INNER JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY purchases DESC
LIMIT 1

-- Question 5: Which item was the most popular for each customer?

WITH most_ordered AS(
	SELECT customer_id,
		   product_id,
		   COUNT(*) AS purchases,
		   RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS rank
	FROM sales
	GROUP BY customer_id, product_id)

SELECT customer_id,
	   product_name,
	   purchases
FROM most_ordered
INNER JOIN menu
	ON most_ordered.product_id = menu.product_id
WHERE rank = 1
ORDER BY customer_id

-- Question 6: Which item was purchased first by the customer after they became a member?

WITH after_join 
    AS (SELECT *,
        	RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) AS ranking
        FROM members
        LEFT JOIN sales
            ON sales.customer_id = members.customer_id
        LEFT JOIN menu
            ON sales.product_id = menu.product_id
        WHERE order_date >= (SELECT join_date FROM members)
        )

SELECT customer_id,
	   product_name
FROM after_join
WHERE ranking = 1

-- Question 7: Which item was purchased just before the customer became a member?

WITH after_join 
		AS (SELECT *,
				RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) AS ranking
			FROM members
			LEFT JOIN sales
				ON sales.customer_id = members.customer_id
			LEFT JOIN menu
				ON sales.product_id = menu.product_id
			WHERE order_date < (SELECT join_date FROM members)
			)

SELECT customer_id,
	   product_name
FROM after_join
WHERE ranking = 1

-- Question 8: What is the total items and amount spent for each member before they became a member?

WITH after_join 
		AS (SELECT sales.customer_id, product_name, price
			FROM members
			LEFT JOIN sales
				ON sales.customer_id = members.customer_id
			LEFT JOIN menu
				ON sales.product_id = menu.product_id
			WHERE order_date < (SELECT join_date FROM members)
			)

SELECT customer_id,
	   SUM(price) AS total_spend
FROM after_join
GROUP BY customer_id

-- Question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH after_join 
		AS (SELECT sales.customer_id,
				   price,
				   sales.product_id
			FROM members
			LEFT JOIN sales
				ON sales.customer_id = members.customer_id
			LEFT JOIN menu
				ON sales.product_id = menu.product_id
			WHERE order_date >= (SELECT join_date FROM members)
			)

SELECT customer_id,
	   SUM(CASE
			WHEN product_id = 1 THEN price * 20
			ELSE price * 10
		   END) AS points
FROM after_join
GROUP BY customer_id

-- Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

WITH after_join 
		AS (SELECT sales.customer_id,
				   order_date,
				   join_date,
				   price,
				   sales.product_id
			FROM members
			LEFT JOIN sales
				ON sales.customer_id = members.customer_id
			LEFT JOIN menu
				ON sales.product_id = menu.product_id
			WHERE order_date >= (SELECT join_date FROM members)
			)

SELECT customer_id,
	   SUM(CASE
			WHEN order_date <= DATE(join_date, '+6 day') THEN price * 20
			WHEN product_id = 1 THEN price * 20
			ELSE price * 10
		   END) AS points
FROM after_join
WHERE order_date <= '2021-01-31'
GROUP BY customer_id

-- Bonus Question 1: Join all the things

SELECT sales.customer_id,
	   order_date,
	   product_name,
	   price,
	   CASE 
		 WHEN order_date >= join_date THEN 'Y'
		 ELSE 'N'
	   END AS member
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
LEFT JOIN members
	ON sales.customer_id = members.customer_id

-- Bonus Question 2: Rank all the things

WITH pre_rank AS
	(SELECT sales.customer_id,
		   order_date,
		   product_name,
		   price,
		   CASE 
			 WHEN order_date >= join_date THEN 'Y'
			 ELSE 'N'
		   END AS member
	FROM sales
	LEFT JOIN menu
		ON sales.product_id = menu.product_id
	LEFT JOIN members
		ON sales.customer_id = members.customer_id
	)

SELECT customer_id,
	   order_date,
	   product_name,
	   price,
	   member,
	   CASE
		 WHEN member = 'N' THEN NULL
		 ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
	   END AS ranking
FROM pre_rank

