
\* Retrieve all records from the Line productivity table
Select only the Batch and Product columns from the Line productivity table
Get all unique products from the productivity table
Count the total number of batches produced
Retrieve all downtime records from the Line downtime table
Find all batches produced on 2024-09-29
Get all downtime events where downtime was greater than 10 minutes.
Find all batches handled by operator Mac
Retrieve all flavors that have a Min batch time greater than 70 minutes.
Select all products that have a size of 600ml
List all batches in order of production start time (earliest first).
Find the total downtime minutes recorded across all batches.
Calculate the average production time per batch.
Identify the highest batch production time recorded.
Count the number of times each operator handled a batch.
Join Line productivity and Products tables to display the Batch, Product, and Flavor.
Join Line downtime and Downtime factors to display downtime reasons alongside their descriptions.
Identify the total downtime per operator by joining Line productivity and Line downtime.
Find the number of batches affected by each downtime factor.
Retrieve all batches where downtime was caused by an operator error.
Use a CTE to calculate the average production time per product and filter only those above 40 minutes.
Find operators who have handled more than 10 batches.
Identify the top 3 downtime reasons affecting production.
Retrieve all products that have a downtime greater than the average downtime
Find operators whose average batch time is higher than the overall average batch time
Get the list of batches that took longer than the longest batch time of ‘Cola Soda’
Rank operators based on total downtime minutes
Assign a row number to each batch based on production time 
Calculate the running total of downtime minutes across all batches 
Find the average batch production time per operator
Compare each batch’s production time to the previous batch
*/

SELECT * FROM downtine_factors
SELECT * FROM line_downtime1
SELECT * FROM line_productivity
SELECT * FROM products

--  Retrieve all records from the Line productivity table
SELECT * FROM line_productivity

-- Select only the Batch and Product columns from the Line productivity table
SELECT batch, product FROM line_productivity

-- Get all unique products from the productivity table
SELECT DISTINCT product FROM line_productivity

-- Count the total number of batches produced
SELECT COUNT(batch) AS 'total batches' FROM line_productivity

-- Retrieve all downtime records from the Line downtime table
SELECT * FROM line_downtime1

-- Find all batches produced on 2024-08-29
SELECT batch FROM line_productivity WHERE date = '2024-08-29'

-- Get all downtime events where downtime was greater than 10 minutes
SELECT * FROM line_downtime1 WHERE downtime_mins > 10

-- Find all batches handled by operator Mac
SELECT batch FROM line_productivity WHERE operator = 'Mac'

-- Retrieve all flavors that have a Min batch time greater than 70 minutes
SELECT flavor FROM products WHERE min_batch_time > 70 

-- List all batches in order of production start time (earliest first)
SELECT batch FROM line_productivity 
ORDER BY start_time 

-- Find the total downtime minutes recorded across all batches
SELECT batch, SUM(downtime_mins) total 
FROM line_downtime1
GROUP BY batch


-- Calculate the average production time per batch
SELECT batch, AVG(DATEDIFF(minute, start_time,end_time)) Avg_production_time FROM line_productivity
GROUP BY batch

-- Identify the highest batch production time recorded
SELECT TOP 1 WITH TIES batch, DATEDIFF(minute, start_time,end_time)production_time 
FROM line_productivity
ORDER BY production_time DESC
--GROUP BY batch

-- Count the number of times each operator handled a batch
SELECT operator, COUNT(batch) no_of_times
FROM line_productivity
GROUP BY operator
ORDER BY no_of_times DESC


-- Join Line productivity and Products tables to display the Batch, Product, and Flavor
SELECT *
--batch, lp.product,flavor
FROM line_productivity lp RIGHT JOIN products p ON lp.product = p.product

-- Join Line downtime and Downtime factors to display downtime reasons alongside their descriptions
SELECT batch, df.factor,description
FROM line_downtime1 ld JOIN downtine_factors df ON ld.factor = df.factor

SELECT * FROM line_downtime1
SELECT * FROM downtine_factors

-- Find the number of batches affected by each downtime factor
SELECT COUNT(batch) AS total_batches FROM
(
SELECT batch, description, SUM(downtime_mins) AS total_mins
FROM line_downtime1 ld JOIN downtine_factors df ON ld.factor = df.factor
GROUP BY  batch, description
HAVING SUM(downtime_mins) <> 0) batches_affected


-- Retrieve all batches where downtime was caused by an operator error
SELECT DISTINCT lp.batch FROM line_downtime1 ld JOIN downtine_factors df ON ld.factor = df.factor
LEFT JOIN line_productivity lp ON lp.batch = ld.batch
WHERE operator_error = 1

-- Use a CTE to calculate the average production time per product and filter only those above 100 minutes
SET SHOWPLAN_ALL ON;
GO
WITH avg_prod AS 
(
SELECT product, AVG(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) AS avg_prod_time
FROM line_productivity
GROUP BY product) 
SELECT * FROM avg_prod
WHERE avg_prod_time > 100
GO
SET SHOWPLAN_ALL OFF

SET SHOWPLAN_ALL ON;
GO
SELECT * FROM 
(
SELECT product, AVG(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) AS avg_prod_time
FROM line_productivity
GROUP BY product) avg_prod_time
WHERE avg_prod_time > 100 
GO
SET SHOWPLAN_ALL OFF;



-- Find operators who have handled more than 10 batches
SELECT operator
FROM line_productivity
GROUP BY operator
HAVING COUNT(batch) > 10

-- Identify the top 3 downtime reasons affecting production
SELECT TOP 3 WITH TIES description, SUM(downtime_mins) AS total_mins
FROM line_downtime1 ld JOIN downtine_factors df ON ld.factor = df.factor
GROUP BY description
ORDER BY total_mins DESC

-- Retrieve all products that have a downtime greater than the average downtime

WITH avg_time AS (
SELECT product, SUM(downtime_mins) AS total_mins
FROM Line_Productivity lp JOIN Line_Downtime1 ld ON lp.batch = ld.batch
GROUP BY product
HAVING SUM(downtime_mins) > (SELECT AVG(downtime_mins) AS avg_time
FROM line_downtime1))

SELECT AVG(total_mins) FROM avg_time


--Find operators whose average batch time is higher than the overall average batch time
SELECT operator,AVG(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) AS avg_prod_time
FROM line_productivity
GROUP BY operator
HAVING AVG(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) > (SELECT AVG(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) AS avg_prod_time
FROM line_productivity)




-- Get the list of batches that took longer than the longest batch time of ‘Cola Soda’
WITH list_batch AS (
SELECT batch,DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME))) AS production_time
FROM Line_Productivity),
cola AS (
SELECT TOP 1 batch, 
CAST(DATEDIFF(minute, CAST(lp.start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(lp.end_time AS DATETIME))) AS INT) AS cola_prod_time
FROM line_productivity lp JOIN Products p ON lp.Product = p.Product
WHERE p.Flavor = 'cola'
ORDER BY cola_prod_time DESC)

SELECT  list_batch.batch, production_time, COALESCE(cola.cola_prod_time,0) cola_prod_time  FROM list_batch 
CROSS JOIN cola
WHERE CAST(list_batch.production_time AS INT) < CAST(cola.cola_prod_time AS INT)








COALESCE(cola.cola_prod_time,0)

LEFT JOIN cola ON prod.Batch = cola.Batch
WHERE prod.production_time < cola.cola_prod_time





SELECT batch,DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME))) AS production_time
FROM Line_Productivity
WHERE DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME))) >
(
SELECT TOP 1 
DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME))) AS cola_prod_time
FROM line_productivity lp JOIN Products p ON lp.Product = p.Product
WHERE Flavor = 'cola'
ORDER BY cola_prod_time DESC)


-- Rank operators based on total downtime minutes
SELECT operator, SUM(downtime_mins) total_downtime, RANK() OVER (ORDER BY SUM(downtime_mins)) AS rnk
FROM Line_Productivity lp JOIN Line_Downtime1 ld ON lp.Batch = ld.Batch
GROUP BY Operator


--Assign a row number to each batch based on production time 
SELECT batch, ROW_NUMBER() OVER (ORDER BY start_time) rn
FROM Line_Productivity


-- Calculate the running total of downtime minutes across all batches 
SELECT lp.batch, SUM(downtime_mins) OVER (ORDER BY start_time) AS running_total, start_time,
downtime_mins AS total_downtime, factor
FROM Line_Productivity lp JOIN Line_Downtime1 ld ON lp.Batch = ld.Batch



-- Find the average batch production time per operator
SELECT operator,AVG(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) AS avg_prod_time
FROM line_productivity
GROUP BY operator


--Compare each batch’s production time to the previous batch
SELECT batch, DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME))) prod_time,
LAG(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) OVER (order BY start_time) prev_batch_time
FROM Line_Productivity