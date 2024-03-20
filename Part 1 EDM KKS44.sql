---Individual Project
---Name:Khushali Sheth kks44@njit.edu

---Submission 1 � Problems
---You are trying to decide where in the US to reside. The most important factor to you is temperature,
---you hate cold weather. Answer the following questions to help you make your decision. For all
---problems show all columns included in the examples. Note that the term temperature applies to the
---average daily temperature unless otherwise stated

---Q1 Find the minimum, maximum and average of the average temperature column for each state sorted by
---state name.
SELECT a.State_Name, MIN(CAST([average_temp] AS Decimal(9,6))) AS Minimum_Temp, 
max(CAST([average_temp] AS Decimal(9,6))) AS Maximum_Temp,
avg(CAST([average_temp] AS Decimal(9,6))) AS Average_Temp 
FROM [dbo].[AQS_Sites] AS a, [dbo].[Temperature] AS t
WHERE a.state_code = t.state_code
GROUP BY state_name
ORDER BY state_name

--Q2 The results from question #2 show issues with the database. Obviously, a temperature of -99 degrees
---Fahrenheit in Arizona is not an accurate reading as most likely is 135.5 degrees for Delaware. Write a
---query to count all the suspect temperatures (below -39o and above 105o). Sort your output by
---State_Name, state_code, County_Code, and Site_Number
SELECT state_name, a.state_code, t.county_code, a.site_number, COUNT(*) as num_bad_entries
FROM [dbo].[AQS_Sites] AS a, [dbo].[Temperature] AS t
WHERE average_temp < -39 OR average_temp > 105 AND a.state_code = t.state_code
GROUP BY state_name, a.state_code, t.county_code, site_number
ORDER BY state_name, state_code, county_code, site_number



--Q3 You noticed that the average temperatures become questionable below -39 o and above 125 o and that
---it is unreasonable to have temperatures over 105 o for state codes 30, 29, 37, 26, 18, 38. You also
---decide that you are only interested in living in the United States, not Canada or the US territories.
---Create a view that combines the data in the AQS_Sites and Temperature tables. The view should have
---the appropriate SQL to exclude the data above. You should use this view for all subsequent queries.
---My view returned 5,616,127 rows. The view includes the State_code, State_Name, County_Code,
---Site_Number.
CREATE VIEW temp_view WITH SCHEMABINDING AS 
SELECT a.state_code, a.state_name, a.county_code, a.site_number
FROM AQS_Sites a
JOIN Temperature t
ON a.state_code = t.state_code AND a.county_code = t.county_code AND a.site_number = t.site_number
WHERE a.county_code = 'US' AND t.average_temp >= -39 AND t.average_temp <= 105 AND a.state_code NOT IN ('30', '29', '37', '26', '18', '38')

--Q4 Using the SQL RANK statement, rank the states by Average Temperature
SELECT state_name, MIN(CAST([average_temp] AS Decimal(9,6))) AS Minimum_Temp, 
MAX(CAST([average_temp] AS Decimal(9,6))) AS Maximum_Temp,
AVG(CAST([average_temp] AS Decimal(9,6))) AS Average_Temp, 
RANK() OVER(ORDER BY (AVG(CONVERT(FLOAT, Average_temp))) DESC) AS State_Rank 
FROM [dbo].[AQS_Sites] AS a, [dbo].[Temperature] AS t
GROUP BY state_name
 
---Q5 At this point, you’ve started to become annoyed at the amount of time each query is taking to run.
---You’ve heard that creating indexes can speed up queries. Create an index for your view (not the
---underlying tables). You are required to create a single index with the unique and clustered
---parameters and the index will be on the State_Code, County_Code, Site_Number, average_temp, and
---Date_Local columns. DO NOT create the index on the tables, the index must be created on the VIEW

CREATE UNIQUE CLUSTERED INDEX idx_temp_view ON temp_view (state_code, county_code, site_number, avg_temp, date_local);

--Q6 There are 270,511 duplicate rows that you must delete before you can create a unique index. Use the
---Rownumber parameter in a partition statement and deleted any row where the row number was greater
---than 1.
WITH cte AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY state_code, county_code, site_number, average_temp, date_local ORDER BY state_code, county_code, site_number, average_temp, date_local) as rn
  FROM temp_view)
DELETE FROM cte
WHERE rn > 1;

CREATE UNIQUE INDEX idx_temp_view ON temp_view (state_code, county_code, site_number, average_temp, date_local);

--Q7 You’ve decided that you want to see the ranking of each high temperatures for each city in each state
---to see if that helps you decide where to live. Write a query that ranks (using the rank function) the
---states by averages temperature and then ranks the cities in each state. The ranking of the cities should
---restart at 1 when the query returns a new state. You also want to only show results for the 15 states
---with the highest average temperatures.
SELECT s.state_rank, s.state_name, c.city_rank, c.city_name, c.average_temp
FROM (
  SELECT state_name, city_name, average_temp,
         RANK() OVER (PARTITION BY state_name ORDER BY average_temp DESC) as city_rank
  FROM temp_view) 
JOIN (SELECT state_name, RANK() OVER (ORDER BY average_temp DESC) as state_rank
  FROM (SELECT state_name, AVG(average_temp) as avg_temp
    FROM temp_view GROUP BY state_name) ) 
ON c.state_name = s.state_name WHERE s.state_rank <= 15 ORDER BY s.state_rank, c.city_rank;

--Q8 You notice in the results that sites with Not in a City as the City Name are include but do not provide
---you useful information. Exclude these sites from all future answers. You can do this by either adding it
---to the where clause in the remaining queries or updating the view you created in #4. Include the SQL
---for #7 with the revised answer
SELECT s.state_rank, s.state_name, c.city_rank, c.city_name, c.average_temp
FROM (SELECT state_name, city_name, average_temp,
         RANK() OVER (PARTITION BY state_name ORDER BY average_temp DESC) as city_rank
  FROM temp_view
  WHERE city_name != 'Not in a City') 
JOIN (SELECT state_name, RANK() OVER (ORDER BY avg_temp DESC) as state_rank
  FROM ( SELECT state_name, AVG(average_temp) as average_temp FROM temp_view
    WHERE city_name != 'Not in a City' GROUP BY state_name ) ) 
ON c.state_name = s.state_name WHERE s.state_rank <= 15 ORDER BY s.state_rank, c.city_rank;

--Q9 You’ve decided that the results in #8 provided too much information and you only want to 2 cities with
---the highest temperatures and group the results by state rank then city rank
SELECT s.state_rank, s.state_name, c.city_rank, c.city_name, c.average_temp
FROM ( SELECT state_name, city_name, average_temp, RANK() OVER (PARTITION BY state_name ORDER BY average_temp DESC) as city_rank FROM temp_view
  WHERE city_name != 'Not in a City') 
JOIN (SELECT state_name, RANK() OVER (ORDER BY average_temp DESC) as state_rank
  FROM (SELECT state_name, AVG(average_temp) as average_temp FROM temp_view
    WHERE city_name != 'Not in a City' GROUP BY state_name ) ) 
ON c.state_name = s.state_name WHERE s.state_rank <= 15 AND c.city_rank <= 2
ORDER BY s.state_rank, c.city_rank;

--Q10 You decide you like the monthly average temperature to be at least 70 degrees. Write a query that
---returns the states and cities that meets this condition, the number of months where the average is
---above 70, the number of days in the database where the days are about 70 and calculate the average
---monthly temperature by month
SELECT state_name, city_name, COUNT(*) as num_months, SUM(num_days) as num_days, AVG(average_temp) as avg_temp
FROM (  SELECT state_name, city_name, DATEPART(MONTH, date_local) as month, COUNT(*) as num_days, AVG(average_temp) as avg_temp
  FROM temp_view WHERE avg_temp >= 70
  GROUP BY state_name, city_name, DATEPART(MONTH, date_local)) 
GROUP BY state_name, city_name HAVING COUNT(*) >= 12;

--Q11 You assume that the temperatures follow a normal distribution and that the majority of the temperatures
---will fall within the 40% to 60% range of the cumulative distribution. Using the CUME_DIST function,
---show the temperatures for the cities having an average temperature of at least 70 degrees that fall
---within the range
SELECT state_name, city_name, avg_temp, CUME_DIST() OVER (PARTITION BY state_name, city_name ORDER BY average_temp) as temp_cume_dist
FROM temp_view WHERE average_temp >= 70 AND temp_cume_dist BETWEEN 0.4 AND 0.6
ORDER BY state_name, city_name, average_temp;

--Q12 You decide this is helpful, but too much information. You decide to write a query that shows the first
---temperature and the last temperature that fall within the 40% and 60% range for cities you are focusing
---on in question #11.
SELECT state_name, city_name,
       MIN(average_temp) as "40 Percentile Temp", MAX(average_temp) as "60 Percentile Temp"
FROM ( SELECT state_name, city_name, average_temp,
         CUME_DIST() OVER (PARTITION BY state_name, city_name ORDER BY average_temp) as temp_cume_dist FROM temp_view
  WHERE average_temp >= 70) 
WHERE temp_cume_dist BETWEEN 0.4 AND 0.6 GROUP BY state_name, city_name
ORDER BY state_name, city_name;

--Q13 You remember from your statistics classes that to get a smoother distribution of the temperatures and
---eliminate the small daily changes that you should use a moving average instead of the actual
---temperatures. Using the windowing within a ranking function to create a 4 day moving average,
---calculate the moving average for each day of the year
SELECT city_name, DATEPART(DAYOFYEAR, date_local) as day_of_year,
       AVG(average_temp) OVER (PARTITION BY city_name ORDER BY date_local ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING) as rolling_avg_temp
FROM temp_view WHERE city_name = 'Mission' ORDER BY date_local;

