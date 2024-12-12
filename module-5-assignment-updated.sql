-- 5.1
-- return total spend across all owners
SELECT sum(spend) as total_spend
FROM owner_spend_date;

-- 5.2
-- from owner_spend_date, from owners who spent >10,000 in 2017 return max(spend) 
-- order by spend DESC; exclude card_no 3

WITH spend_2017 AS(
	SELECT sum(spend), card_no
	FROM owner_spend_date
	WHERE strftime("%Y", date) = "2017"
	GROUP BY card_no
	HAVING sum(spend) > 10000
	)
SELECT max(spend) as max_spend, card_no--, strftime("%Y", date) as year
FROM owner_spend_date
WHERE card_no != 3 --AND card_no in (select card_no from spend_2017)
GROUP BY card_no
HAVING card_no in (select card_no from spend_2017)
ORDER BY max_spend DESC;

-- 5.3 
-- from department_date, return all cols WHERE dept != 1 or 2, spend for day between 5k and 7k, 
-- month is june, july, aug. Order the results by spend DESC
SELECT * 
FROM department_date
WHERE department NOT IN (1,2)
AND spend BETWEEN 5000 and 7000
AND strftime("%m", date) IN ("05", "06", "07", "08")
ORDER BY spend DESC;

-- 5.4 
-- Use date_hour and department_date to return department spend in busiest months. 
-- from date_hour, find months with 4 highest spends
-- use department_date to return department spend in these months. 
-- Return year, month, total store spend from date_hour, department, and department spend
-- Limit to departments that have spent over $200,000 in the month
WITH store_spend AS (
    SELECT 
        sum(spend) as total_spend, 
        strftime("%Y", date) as year, 
        strftime("%m", date) as month 
    FROM date_hour
    GROUP BY month, year
)
SELECT 
    strftime("%Y", dd.date) as year,
    strftime("%m", dd.date) as month,
    ss.total_spend as total_spend,
    dd.department,
    sum(dd.spend) as department_spend
FROM department_date dd
INNER JOIN store_spend ss 
    ON strftime("%Y", dd.date) = ss.year 
    AND strftime("%m", dd.date) = ss.month
GROUP BY year, month, dd.department
HAVING sum(spend) > 200000
ORDER BY year ASC, month ASC, department_spend DESC;

-- 5.5
-- For zip codes with 100+ owners, which are top 5 in terms of spend per TRANSACTION
-- return zip code, num_owners in zip code, avg_spend per owner, avg_spend per TRANSACTION
WITH OwnerSummary AS (
  SELECT
    o.zip AS zip_code,
    COUNT(o.card_no) AS owner_count,
    AVG(os.spend) AS avg_spend_per_owner,
    SUM(os.spend) / SUM(os.trans) AS avg_spend_per_transaction
  FROM
    owners o
    JOIN owner_spend_date os ON o.card_no = os.card_no
  GROUP BY
    o.zip
  HAVING
    COUNT(o.card_no) >= 100
)
SELECT
  zip_code,
  owner_count,
  avg_spend_per_owner,
  avg_spend_per_transaction
FROM
  OwnerSummary
ORDER BY
  avg_spend_per_transaction DESC
LIMIT 5;

-- 5.6 
-- do the same but for lowest spend
WITH OwnerSummary AS (
  SELECT
    o.zip AS zip_code,
    COUNT(o.card_no) AS owner_count,
    AVG(os.spend) AS avg_spend_per_owner,
    SUM(os.spend) / SUM(os.trans) AS avg_spend_per_transaction
  FROM
    owners o
    JOIN owner_spend_date os ON o.card_no = os.card_no
  GROUP BY
    o.zip
  HAVING
    COUNT(o.card_no) >= 100
)

SELECT
  zip_code,
  owner_count,
  avg_spend_per_owner,
  avg_spend_per_transaction
FROM
  OwnerSummary
ORDER BY
  avg_spend_per_transaction ASC
LIMIT 5;

-- 5.7
-- from owners return zip, num_active_owners, num_inactive_owners, fraction active_owners
-- include zips with >= 50 owners
-- order by num_owners DESC
SELECT
    zip,
    SUM(CASE WHEN status LIKE "active" THEN 1 ELSE 0 END) AS active_owners,
    SUM(CASE WHEN status LIKE "inactive" THEN 1 ELSE 0 END) AS inactive_owners,
    CAST(SUM(CASE WHEN status LIKE "active" THEN 1 ELSE 0 END) AS REAL) / CAST(COUNT(*) AS REAL) AS fraction_active
FROM owners
GROUP BY zip
HAVING COUNT(*) >= 50
ORDER BY COUNT(*) DESC;