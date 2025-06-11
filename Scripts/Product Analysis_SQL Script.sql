
WITH cleaned_data AS (
    SELECT 
        Batch,
        COALESCE("Factor1", 0) AS "1",
        COALESCE("Factor2", 0) AS "2",
        COALESCE("Factor3", 0) AS "3",
        COALESCE("Factor4", 0) AS "4",
        COALESCE("Factor5", 0) AS "5",
        COALESCE("Factor6", 0) AS "6",
        COALESCE("Factor7", 0) AS "7",
        COALESCE("Factor8", 0) AS "8",
        COALESCE("Factor9", 0) AS "9",
        COALESCE("Factor10", 0) AS "10",
        COALESCE("Factor11", 0) AS "11",
        COALESCE("Factor12", 0) AS "12"
    FROM line_downtime
)

SELECT 
    Batch,
    Factor_ID,
    Downtime_Minutes
FROM cleaned_data
UNPIVOT (Downtime_Minutes FOR Factor_ID IN ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12")
) AS unpivoted_data;




WITH production_min AS (
    -- Calculate total production time for each product
    SELECT 
        product, 
        SUM(DATEDIFF(MINUTE, CAST(Start_Time AS DATETIME), 
            DATEADD(DAY, CASE WHEN End_Time < Start_Time THEN 1 ELSE 0 END, CAST(End_Time AS DATETIME))
        )) AS total_production_min
    FROM line_productivity
    GROUP BY product
),

avg_time AS (
    -- Calculate average production time for each product
    SELECT 
        product,
        AVG(DATEDIFF(MINUTE, CAST(Start_Time AS DATETIME), 
            DATEADD(DAY, CASE WHEN End_Time < Start_Time THEN 1 ELSE 0 END, CAST(End_Time AS DATETIME))
        )) AS avg_production_min
    FROM line_productivity
    GROUP BY product
),

total_downtime AS (
    -- Calculate total downtime for each batch
    SELECT 
        ld.batch,
        SUM(Downtime_Mins) AS total_downtime 
    FROM line_downtime1 ld
    GROUP BY ld.batch
),

total AS (
    -- Calculate overall downtime
    SELECT 
        SUM(Downtime_Mins) AS overall 
    FROM line_downtime1
),

product_downtime AS (
    -- Calculate total downtime per product
    SELECT 
        lp.Product,
        SUM(Downtime_Mins) AS total_downtime_min 
    FROM Line_Productivity lp
    JOIN line_downtime1 ld ON lp.Batch = ld.batch
    GROUP BY lp.Product
),

downtime_cnt AS (
    -- Count the number of downtime occurrences per product
    SELECT 
        lp.product,
        COUNT(ld.batch) AS cnt_batchdowntime 
    FROM line_downtime1 ld
    JOIN Line_Productivity lp ON ld.batch = lp.Batch
    WHERE Downtime_Mins > 0
    GROUP BY lp.product
),

total_batch AS (
    -- Count the total number of batches per product
    SELECT 
        product,
        COUNT(batch) AS total_batch 
    FROM Line_Productivity
    GROUP BY Product
),

major_factor AS (
    -- Identify the major cause of downtime per product
    SELECT 
        lp.Product,
        df.description,
        SUM(Downtime_Mins) AS total_downtime,
        RANK() OVER (PARTITION BY lp.product ORDER BY SUM(Downtime_Mins) DESC) AS downtime_cause
    FROM line_downtime1 ld
    INNER JOIN Line_Productivity lp ON ld.batch = lp.Batch
    LEFT JOIN Downtine_Factors df ON ld.factor = df.Factor
    GROUP BY lp.Product, df.description
),

downtime_cause AS (
    -- Select the top downtime cause per product
    SELECT 
        product,
        description,
        total_downtime 
    FROM major_factor
    WHERE downtime_cause = 1
),

affected_batches AS (
    -- Count the number of affected batches per product
    SELECT 
        lp.product, 
        COUNT(DISTINCT lp.Batch) AS affected_batches 
    FROM line_downtime1 ld
    LEFT JOIN line_productivity lp ON ld.batch = lp.batch
    WHERE Downtime_Mins > 0
    GROUP BY lp.Product
),

main_insight AS (
    -- Final aggregation of all key insights
    SELECT 
        pd.product AS product,
        pd.total_downtime_min AS total_downtime_min,
        (pd.total_downtime_min * 100.0) / NULLIF(t.overall, 0) AS percentage_of_totaldowntime,
        pm.total_production_min,
        at.avg_production_min,
        dc.cnt_batchdowntime,
        tb.total_batch,
        ROUND(CAST(ab.affected_batches AS FLOAT) * 100.0 / NULLIF(tb.total_batch, 0), 2) AS batch_failure_rate,
        de.description,
        ab.affected_batches,
        ROUND(CAST(ab.affected_batches AS FLOAT) * 100.0 / NULLIF(tb.total_batch, 0), 2) AS percentage_affected_batches, 
        (pd.total_downtime_min) / NULLIF(p.Min_batch_time, 1) AS total_batchloss, 
        p.Min_batch_time AS expected_batch_time, 
        pd.total_downtime_min * 0.5 AS expected_downtime,
        CAST(pd.total_downtime_min AS INT) / NULLIF(CAST(p.Min_batch_time AS INT), 1) / 2 AS batches_gained
    FROM product_downtime pd
    CROSS JOIN total t 
    LEFT JOIN production_min pm ON pd.product = pm.product 
    LEFT JOIN avg_time at ON at.product = pm.product 
    LEFT JOIN downtime_cnt dc ON dc.product = pd.product
    LEFT JOIN total_batch tb ON pm.product = tb.product
    LEFT JOIN downtime_cause de ON pd.product = de.product 
    LEFT JOIN affected_batches ab ON pd.product = ab.product
    LEFT JOIN Products p ON p.product = ab.product 
)

-- Retrieve all insights
SELECT * FROM main_insight;
