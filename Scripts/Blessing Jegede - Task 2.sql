-- Find the top three downtime reasons that caused the most delays across all batches

select description from ( 
    select description, sum(downtime_mins) as dm
    from downtine_factors df
    join line_downtime1 ld on df.factor = ld.factor
    group by description) as alll
order by dm desc
limit 3;

-- Great Job Blessing! can you think of anaother approach to this?

WITH NumberSeries AS (
    SELECT 1 AS num
    UNION ALL
    SELECT num + 1 FROM NumberSeries WHERE num < 20
)
SELECT * FROM NumberSeries OPTION (MAXRECURSION 100);


WITH RECURSIVE DateSeries AS (
    SELECT DATE('2024-01-01') AS dt
    UNION ALL
    SELECT dt + INTERVAL 1 DAY FROM DateSeries WHERE dt < '2024-01-10'
)
SELECT * FROM DateSeries


WITH DateSeries AS (
    SELECT CAST('2024-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt) FROM DateSeries WHERE dt < '2024-01-10'
)
SELECT * FROM DateSeries  
OPTION (MAXRECURSION 100)
