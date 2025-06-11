# 1. Identify the operator with the most production time

with prodd as (
    select *, 
    timestampdiff(minute, str_to_date(start_time, '%H:%i:%s'),
    case when str_to_date(end_time, '%H:%i:%s') < str_to_date(start_time, '%H:%i:%s') then date_add(str_to_date(end_time, '%H:%i:%s'), interval 1 day) else str_to_date(end_time, '%H:%i:%s') end) as prod_time
    from line_productivity)

select operator from prodd
group by operator
order by sum(prod_time) desc
limit 1;

# 2. Determine what percentage of total production time was lost due to downtime for each batch

with prodd as (
    select *, 
    timestampdiff(minute, str_to_date(start_time, '%H:%i:%s'),
    case when str_to_date(end_time, '%H:%i:%s') < str_to_date(start_time, '%H:%i:%s') then date_add(str_to_date(end_time, '%H:%i:%s'), interval 1 day) else str_to_date(end_time, '%H:%i:%s') end) as prod_time
    from line_productivity
    )
    
select ld.batch, sum(prod_time) prod_time , sum(downtime_mins) downtime_mins, round((downtime_mins/prod_time) * 100, 1) prod_time_lost from line_downtime1 ld
join prodd on prodd.batch = ld.batch
group by batch, prod_time, downtime_mins; 

# 3. Find the total number of batches produced for each product

select product, count(batch) from line_productivity
group by product;
