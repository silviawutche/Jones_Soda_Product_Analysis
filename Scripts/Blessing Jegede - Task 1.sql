# 1. Retrieve the total production time for each operator

with prodd as (
    select *, 
    timestampdiff(minute, str_to_date(start_time, '%H:%i:%s'),
    CASE  WHEN STR_TO_DATE(end_time, '%H:%i:%s') < STR_TO_DATE(start_time, '%H:%i:%s') THEN DATE_ADD(STR_TO_DATE(end_time, '%H:%i:%s'), INTERVAL 1 DAY) ELSE STR_TO_DATE(end_time, '%H:%i:%s') END) AS prodd_time
    from line_productivity) 
select operator, sum(prodd_time) from prodd
group by operator;


# 2. Find the highest downtime recorded for any batch.

select batch, max(downtime_mins) from line_downtime1
group by batch;


# 3. Get the count of unique products in the productivity table.

select count(distinct(product)) from line_productivity;


# 4. Calculate the total number of downtime event

select count(downtime_mins) from line_downtime1
where downtime_mins <> 0;


# 5. ⁠Find the minimum production time recorded for each batch

with prod_time as(
    SELECT batch, 
    TIMESTAMPDIFF(MINUTE, 
    STR_TO_DATE(start_time, '%H:%i:%s'), 
    CASE  WHEN STR_TO_DATE(end_time, '%H:%i:%s') < STR_TO_DATE(start_time, '%H:%i:%s') THEN DATE_ADD(STR_TO_DATE(end_time, '%H:%i:%s'), INTERVAL 1 DAY) ELSE STR_TO_DATE(end_time, '%H:%i:%s') END) AS prodd_time
    FROM line_productivity)
select batch, min(prodd_time) as min_production_time from prod_time
group by batch;

