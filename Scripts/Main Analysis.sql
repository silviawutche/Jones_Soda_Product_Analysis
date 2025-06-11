-- CLEANING THE LINE DOWNTIME TABLE

WITH clean_table AS(
SELECT Batch,
COALESCE("factor1" ,0) AS "1",
COALESCE(factor2,0) AS "2",
COALESCE(factor3,0) AS "3",
COALESCE(factor4,0) AS "4",
COALESCE(factor5,0) AS "5",
COALESCE(factor6,0) AS "6",
COALESCE(factor7,0) AS "7",
COALESCE(factor8,0) AS "8",
COALESCE(factor9,0) AS "9",
COALESCE(factor10,0) AS "10",
COALESCE(factor11,0) AS "11",
COALESCE(factor12,0) AS "12"
FROM Line_Downtime)

SELECT batch, factor,downtime_mins
FROM clean_table
UNPIVOT (downtime_mins FOR factor IN ("1","2","3","4","5","6","7","8","9","10","11","12")) AS data1



-- CURRENT STATE (BASELINE)

-- GET THE CURRENT DOWNTIME

SELECT SUM(downtime_mins) * 0.20 total_downtime
FROM Line_Downtime1

-- Analyze batch processing times across products and operators

CREATE VIEW product_op AS
WITH batch_downtime AS (
SELECT batch, SUM(downtime_mins) AS total_downtime
FROM Line_Downtime1
GROUP BY batch),
Batch_pro AS (
SELECT batch,product,SUM(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) AS production_time 
FROM Line_Productivity
GROUP BY batch,product
),
operator_prod AS (
SELECT operator, batch,SUM(DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME)))) AS production_time 
FROM Line_Productivity
GROUP BY Operator, batch)

, performance AS (
SELECT op.batch,bp.product,op.operator, COUNT(op.batch) AS total_batch,
SUM(bd.total_downtime) AS total_downtime, SUM(bp.production_time) AS total_prod_time
FROM batch_pro bp
LEFT JOIN batch_downtime bd ON bd.batch = bp.batch
LEFT JOIN operator_prod op ON op.batch = bd.batch
GROUP BY op.batch, bp.product,op.operator)

, operator_efficiency AS (
SELECT product, operator, SUM(total_batch) no_of_batches, SUM(total_downtime) AS total_downtime,SUM(total_prod_time) AS total_prod_time, 
SUM(total_prod_time) * 1.0/NULLIF(SUM(total_batch),0) avg_time_per_batch, RANK() OVER (PARTITION BY product ORDER BY SUM(total_prod_time) * 1.0/NULLIF(SUM(total_batch),0)) AS rank_per_product
FROM performance  
GROUP BY product, operator)

, rankings AS (
SELECT  product, operator, SUM(no_of_batches) AS no_of_batches, SUM(total_downtime) AS total_downtime,SUM(total_prod_time) AS total_prod_time, 
avg_time_per_batch, RANK() OVER (PARTITION BY product ORDER BY avg_time_per_batch) AS fastest_operator,
RANK() OVER (PARTITION BY product ORDER BY avg_time_per_batch DESC) AS slowest_operator
FROM operator_efficiency
GROUP BY product, operator, avg_time_per_batch)

, time_diff AS (
SELECT r1.product, r1.operator AS fastest_operator, r2.operator AS slowest_operator,
r2.no_of_batches AS no_of_batches, r1.no_of_batches AS fastest_cnt, r2.avg_time_per_batch - r1.avg_time_per_batch AS time_diff,
ROUND(CAST(r2.avg_time_per_batch - r1.avg_time_per_batch AS FLOAT) * 100.0/ NULLIF(r1.avg_time_per_batch,0),2) AS percent_slow
FROM rankings r1
LEFT JOIN rankings r2 ON r1.product = r2.product
WHERE r1.fastest_operator = 1 AND r2.slowest_operator = 1)


SELECT product, fastest_operator, slowest_operator,no_of_batches,fastest_cnt, ROUND(CAST(time_diff AS FLOAT),2) AS time_saved, ROUND(CAST(time_diff * no_of_batches AS FLOAT),2) AS total_time_saved
FROM time_diff

SELECT SUM(total_time_saved) AS overall_time_saved
FROM time_saved

SELECT * FROM product_op


WITH Mac_Charlie AS (
SELECT date,batch,start_time, p.product, operator, DATEDIFF(minute, CAST(start_time AS DATETIME),
DATEADD(DAY,CASE WHEN end_time < start_time THEN 1 ELSE 0 END,CAST(end_time AS DATETIME))) AS production_time, Min_batch_time 
FROM Line_Productivity lp LEFT JOIN Products p ON p.Product = lp.Product
WHERE Operator = 'Mac'
)
SELECT date,mc.batch,operator,start_time,product,production_time,min_batch_time,description, Downtime_Mins 
FROM Mac_Charlie mc 
JOIN Line_Downtime1 ld ON ld.Batch = mc.batch
JOIN Downtine_Factors df ON df.Factor = ld.Factor
WHERE Downtime_Mins > 0 
ORDER BY Downtime_Mins DESC


--  Downtime Analysis: Identify major downtime causes and their impact on production



CREATE VIEW downtime_op AS 
WITH operator_downtime AS (
SELECT operator, sum(downtime_mins) total_downtime
FROM Line_Productivity lp 
JOIN Line_Downtime1 ld ON ld.Batch = lp.Batch
GROUP BY Operator),

total_downtime AS (
SELECT batch, downtime_mins total FROM Line_Downtime1
WHERE downtime_mins > 0
),
num_batch AS (
SELECT batch FROM Line_Productivity)

SELECT od.operator, total_downtime AS total_downtime, 
ROUND(CAST(total_downtime AS FLOAT)* 100.0/(SELECT SUM(total_downtime) FROM operator_downtime),2) percent_of_total,
COUNT(td.batch) AS no_downtime, COUNT(DISTINCT nb.batch) num_of_batch,
total_downtime * 0.20 AS reduction_needed,ROUND(CAST(total_downtime AS FLOAT) * 1.0/ NULLIF(COUNT(td.batch),0),2) AS average_downtime
FROM operator_downtime od
JOIN Line_Productivity lp ON lp.Operator = od.Operator
JOIN total_downtime td ON td.Batch = lp.Batch
JOIN num_batch nb ON nb.batch = lp.batch
GROUP BY od.Operator, total_downtime;


SELECT * FROM downtime_op


SELECT Description, SUM(downtime_mins) TOTAL FROM (
SELECT date,Product, lp.Batch, start_time, DATEDIFF(Minute, Start_Time,End_Time) AS production_time, downtime_mins,Description,Operator_Error
FROM Line_Productivity lp 
JOIN Line_Downtime1 ld ON lp.Batch = ld.batch 
JOIN Downtine_Factors df ON df.Factor = ld.Factor
WHERE Operator = 'Dennis' AND Downtime_Mins > 0
--AND Description = 'Machine adjustment'
) t
GROUP BY Description 
ORDER BY total DESC



WITH total_shifts AS (
SELECT batch,operator, ROW_NUMBER() OVER (PARTITION BY date, operator ORDER BY start_time) rn FROM Line_Productivity 
)

SELECT COUNT(*) * 100.0/ (SELECT COUNT(*) FROM (
SELECT ld.batch,operator, ROW_NUMBER() OVER (PARTITION BY date, operator ORDER BY start_time) rn FROM Line_Productivity lp
LEFT JOIN (SELECT batch, SUM(downtime_mins) total FROM Line_Downtime1
GROUP BY batch
HAVING SUM(downtime_mins) > 0) ld
ON  ld.batch = lp.batch) t
WHERE rn = 1)
FROM total_shifts WHERE rn = 1



SELECT COUNT(*) FROM (
SELECT ld.batch,operator, ROW_NUMBER() OVER (PARTITION BY date, operator ORDER BY start_time) rn FROM Line_Productivity lp
LEFT JOIN (SELECT batch, SUM(downtime_mins) total FROM Line_Downtime1
GROUP BY batch
HAVING SUM(downtime_mins) > 0) ld
ON  ld.batch = lp.batch) t
WHERE rn = 1

CREATE VIEW time_based AS 
WITH time_date AS (
SELECT * FROM (
SELECT lp.batch, operator, start_time,end_time, Downtime_Mins, ROW_NUMBER() OVER (PARTITION BY operator ORDER BY Downtime_Mins DESC) rn
FROM Line_Productivity lp JOIN Line_Downtime1 ld ON lp.Batch = ld.Batch
WHERE Downtime_Mins > 0) t),

downtime_cause AS (
SELECT batch, factor, ROW_NUMBER() OVER (PARTITION BY batch ORDER BY downtime_mins DESC) AS rn
FROM Line_Downtime1
),

root AS (
SELECT td.batch,td.Operator,td.Start_Time, dc.Factor FROM time_date td
JOIN downtime_cause dc
ON dc.batch = td.batch
WHERE dc.rn = 1),

 time_of_day AS (
SELECT operator, df.description,
CASE WHEN DATEPART(HOUR, start_time) >= 5 AND DATEPART(HOUR, start_time) < 12 THEN 'Morning'
WHEN DATEPART(HOUR, start_time) >= 12 AND DATEPART(HOUR, start_time) < 16 THEN 'Noon'
WHEN DATEPART(HOUR, start_time) >= 16 AND DATEPART(HOUR, start_time) < 22 THEN 'Evening'
ELSE 'Night' END AS time_of_day
FROM root r JOIN Downtine_Factors df ON r.factor = df.factor
)

SELECT operator, time_of_day, COUNT(*) no_of_downtime
FROM time_of_day
GROUP BY operator, time_of_day
ORDER BY Operator,no_of_downtime DESC


SELECT date, lp.batch,product,Start_Time, Downtime_Mins,Description
FROM line_productivity lp JOIN Line_Downtime1 ld ON ld.Batch = lp.Batch JOIN Downtine_Factors df ON df.Factor = ld.Factor
WHERE Operator = 'Charlie' AND Downtime_Mins > 0 
AND  DATEPART(HOUR, start_time) BETWEEN 16 AND 22
ORDER BY Start_Time

SELECT * FROM time_based

CREATE VIEW VWdowntime_cause AS 
SELECT Description,COUNT(ld.batch) AS no_of_times,SUM(downtime_mins) AS total_downtime, 
SUM(downtime_mins) * 100.0/ (SELECT SUM(downtime_mins) FROM Line_Downtime1) AS percent_impact
FROM Line_Downtime1 ld JOIN Downtine_Factors df ON ld.Factor = df.Factor
WHERE Downtime_Mins > 0
GROUP BY Description
ORDER BY total_downtime DESC

DROP VIEW VWdowntime_cause
CREATE VIEW VWdowntime_cause AS 
SELECT product,COUNT(ld.batch) AS no_of_times,SUM(downtime_mins) AS total_downtime, 
SUM(downtime_mins) * 100.0/ (SELECT SUM(downtime_mins) FROM Line_Downtime1) AS percent_impact
FROM Line_Downtime1 ld JOIN Downtine_Factors df ON ld.Factor = df.Factor JOIN Line_Productivity lp ON lp.Batch = ld.Batch
WHERE Downtime_Mins > 0
GROUP BY product
ORDER BY total_downtime DESC

SELECT * FROM VWdowntime_cause
ORDER BY total_downtime DESC


CREATE VIEW top_three AS 
WITH top_three AS (
SELECT ld.Batch,product, Description,Start_Time, Downtime_Mins
FROM Line_Downtime1 ld JOIN Downtine_Factors df ON ld.Factor = df.Factor JOIN Line_Productivity lp ON lp.Batch = ld.Batch
WHERE Downtime_Mins > 0 
),

total_top_3_downtime AS (
SELECT SUM(Downtime_Mins) top_3_total FROM top_three)

SELECT product, SUM(CASE WHEN Description = 'Machine adjustment' THEN downtime_mins ELSE 0 END) AS machine_adjustment,
				SUM(CASE WHEN Description = 'machine failure' THEN downtime_mins ELSE 0 END) AS machine_failure,
				SUM(CASE WHEN Description = 'inventory shortage' THEN downtime_mins ELSE 0 END) AS inventory_shortage
FROM top_three
GROUP BY product

SELECT * FROM top_three
















