-- view data

SELECT *
FROM cl_project.cl_vehicle_postings;

-- count of postings in each state

SELECT state, count(*)
FROM cl_project.cl_vehicle_postings
GROUP BY state
ORDER BY 2 DESC;

-- create new date column
    
ALTER TABLE cl_project.cl_vehicle_postings
ADD date_posted Date;
UPDATE cl_project.cl_vehicle_postings
SET date_posted = CONVERT(SUBSTRING(posting_date,1,10), Date);

-- create new time column
    
ALTER TABLE cl_project.cl_vehicle_postings
ADD time_posted Time;
UPDATE cl_project.cl_vehicle_postings
SET time_posted = CONVERT(SUBSTRING(posting_date,12,8), Time);

-- omit '-' character, and limit to first word in string to help group vehicles by model

ALTER TABLE cl_project.cl_vehicle_postings
ADD model_clean Text;
UPDATE cl_project.cl_vehicle_postings
SET model_clean = replace(model,'-', '');
UPDATE cl_project.cl_vehicle_postings
SET model_clean = substring_index(model_clean, ' ', 1);

-- concatenate manufacturer and model_clean as new column called make_model

ALTER TABLE cl_project.cl_vehicle_postings
ADD make_model Text;
UPDATE cl_project.cl_vehicle_postings
SET make_model = CONCAT(manufacturer, " ", model_clean);

-- check for duplicates

WITH to_delete  AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY 
		price,
        year,
        model,
        odometer,
        posting_date,
        state,
        region
        ORDER BY id
        ) AS row_num
FROM cl_project.cl_vehicle_postings)
SELECT *
FROM to_delete
WHERE row_num > 1 
ORDER BY id;

-- delete duplicates (28 rows deleted)

DELETE FROM cl_project.cl_vehicle_postings
WHERE id IN(
	SELECT id
    FROM (
		SELECT id,
			ROW_NUMBER() OVER (
			PARTITION BY 
				price,
				year,
				model,
				odometer,
				posting_date,
				state,
				region
				ORDER BY id
				) AS row_num
		FROM cl_project.cl_vehicle_postings) AS sub
        WHERE row_num > 1
        );
        
-- add column as title_status boolean for value "clean"

ALTER TABLE cl_project.cl_vehicle_postings
ADD clean_title Boolean;

UPDATE cl_project.cl_vehicle_postings
SET clean_title	=
	CASE WHEN title_status = "clean" THEN TRUE ELSE FALSE END;


-- overall views

	-- total average and count
    
SELECT cast(avg(price) AS DECIMAL(10,2)) AS Average,
	count(*) AS "Total Postings"
FROM cl_project.cl_vehicle_postings
WHERE price < 500000
AND NOT (price < 500 AND year > 2016);

CREATE VIEW total_average_and_count AS
SELECT cast(avg(price) AS DECIMAL(10,2)) AS Average,
	count(*) AS "Total Postings"
FROM cl_project.cl_vehicle_postings
WHERE price < 500000
AND NOT (price < 500 AND year > 2016);

	-- data scraping start and end date
    
    SELECT max(date_posted) AS End,
		min(date_posted) AS Start
	FROM cl_project.cl_vehicle_postings;
    
    CREATE VIEW data_scraping_period AS
	SELECT max(date_posted) AS End,
		min(date_posted) AS Start
	FROM cl_project.cl_vehicle_postings;
    
    -- total count
    
    SELECT count(*)
	FROM cl_project.cl_vehicle_postings

	--  total count of each model

SELECT make_model, count(make_model)
FROM cl_project.cl_vehicle_postings
GROUP BY make_model
ORDER BY count(make_model) DESC
LIMIT 10;

CREATE VIEW cl_project.total_model_count AS
SELECT make_model, count(make_model)
FROM cl_project.cl_vehicle_postings
GROUP BY make_model
HAVING count(make_model) > 1
ORDER BY count(make_model) DESC
LIMIT 10;

	-- average price per state, filtered for extreme price alues
    
SELECT state, cast(avg(price) AS DECIMAL(10,2)) AS Average
FROM cl_project.cl_vehicle_postings
WHERE price < 500000
AND NOT (price < 500 AND year > 2016)
GROUP BY state;

CREATE VIEW cl_project.avg_price_by_state AS
SELECT state, cast(avg(price) AS DECIMAL(10,2)) AS Average
FROM cl_project.cl_vehicle_postings
WHERE price < 500000
AND NOT (price < 500 AND year > 2016)
GROUP BY state;

-- views for clean titled, make_model "Chevrolet Silverado"

	-- count, average, min, max, standard deviation
    
SELECT count(*) AS count,
	cast(avg(price) AS DECIMAL(10,2)) AS average,
	cast(min(price) AS DECIMAL(10,2)) AS min,
	cast(max(price) AS DECIMAL(10,2)) AS max,
	cast(stddev(price) AS DECIMAL(10,2)) AS std_price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Chevrolet Silverado"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
ORDER BY 3 DESC;

CREATE VIEW cl_project.silverado_totals AS
SELECT count(*) AS count,
	cast(avg(price) AS DECIMAL(10,2)) AS average,
	cast(min(price) AS DECIMAL(10,2)) AS min,
	cast(max(price) AS DECIMAL(10,2)) AS max,
	cast(stddev(price) AS DECIMAL(10,2)) AS std_price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Chevrolet Silverado"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016);
    
    -- count and average price by state
    
SELECT state,
	count(*) as count,
	cast(avg(price) AS DECIMAL(10,2)) AS average
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Chevrolet Silverado"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
GROUP BY state
ORDER BY 3 DESC;

CREATE VIEW cl_project.silverado_per_state AS
SELECT state,
	count(*) as count,
	cast(avg(price) AS DECIMAL(10,2)) AS average
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Chevrolet Silverado"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
GROUP BY state;

    -- count of make_model postings timeline
    
SELECT date_posted, count(date_posted) AS count
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Chevrolet Silverado"
AND clean_title = TRUE
GROUP BY date_posted
ORDER BY date_posted;

CREATE VIEW cl_project.silverado_timeline AS
SELECT date_posted, count(date_posted) AS count
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Chevrolet Silverado"
AND clean_title = TRUE
GROUP BY date_posted;

	-- scatterplot of make_model for year and price
    
SELECT year, price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Chevrolet Silverado"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
ORDER BY 1;

CREATE VIEW cl_project.silverado_year_price AS
SELECT year, price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Chevrolet Silverado"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016);

-- views for make_model "Jeep Wrangler"

	-- count, average, min, max, standard deviation
    
SELECT count(*) AS count,
	cast(avg(price) AS DECIMAL(10,2)) AS average,
	cast(min(price) AS DECIMAL(10,2)) AS min,
	cast(max(price) AS DECIMAL(10,2)) AS max,
	cast(stddev(price) AS DECIMAL(10,2)) AS std_price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Jeep Wrangler"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
ORDER BY 3 DESC;

CREATE VIEW cl_project.wrangler_totals AS
SELECT count(*) AS count,
	cast(avg(price) AS DECIMAL(10,2)) AS average,
	cast(min(price) AS DECIMAL(10,2)) AS min,
	cast(max(price) AS DECIMAL(10,2)) AS max,
	cast(stddev(price) AS DECIMAL(10,2)) AS std_price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Jeep Wrangler"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016);
    
    -- count and average price by state
    
SELECT state,
	count(*) as count,
	cast(avg(price) AS DECIMAL(10,2)) AS average
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Jeep Wrangler"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
GROUP BY state
ORDER BY 3 DESC;

CREATE VIEW cl_project.wrangler_per_state AS
SELECT state,
	count(*) as count,
	cast(avg(price) AS DECIMAL(10,2)) AS average
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Jeep Wrangler"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
GROUP BY state;

    -- count of make_model postings timeline
    
SELECT date_posted, count(date_posted) AS count
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Jeep Wrangler"
AND clean_title = TRUE
GROUP BY date_posted
ORDER BY date_posted;

CREATE VIEW cl_project.wrangler_timeline AS
SELECT date_posted, count(date_posted) AS count
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Jeep Wrangler"
AND clean_title = TRUE
GROUP BY date_posted;

	-- scatterplot of make_model for year and price
    
SELECT odometer, price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Jeep Wrangler"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
ORDER BY 1;

CREATE VIEW cl_project.wrangler_year_price AS
SELECT year, price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Jeep Wrangler"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016);

-- views for make_model "Ford Mustang"

	-- count, average, min, max, standard deviation

SELECT count(*) AS count,
	cast(avg(price) AS DECIMAL(10,2)) AS average,
	cast(min(price) AS DECIMAL(10,2)) AS min,
	cast(max(price) AS DECIMAL(10,2)) AS max,
	cast(stddev(price) AS DECIMAL(10,2)) AS std_price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Ford Mustang"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
ORDER BY 3 DESC;

CREATE VIEW cl_project.mustang_totals AS
SELECT count(*) AS count,
	cast(avg(price) AS DECIMAL(10,2)) AS average,
	cast(min(price) AS DECIMAL(10,2)) AS min,
	cast(max(price) AS DECIMAL(10,2)) AS max,
	cast(stddev(price) AS DECIMAL(10,2)) AS std_price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Ford Mustang"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016);
    
    -- count and average price by state
    
SELECT state,
	count(*) as count,
	cast(avg(price) AS DECIMAL(10,2)) AS average
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Ford Mustang"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
GROUP BY state
ORDER BY 3 DESC;

CREATE VIEW cl_project.mustang_per_state AS
SELECT state,
	count(*) as count,
	cast(avg(price) AS DECIMAL(10,2)) AS average
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Ford Mustang"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
GROUP BY state;

    -- count of make_model postings timeline
    
SELECT date_posted, count(date_posted) AS count
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Ford Mustang"
AND clean_title = TRUE
GROUP BY date_posted
ORDER BY date_posted;

CREATE VIEW cl_project.mustang_timeline AS
SELECT date_posted, count(date_posted) AS count
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Ford Mustang"
AND clean_title = TRUE
GROUP BY date_posted;

	-- scatterplot of make_model for year and price
    
SELECT year, price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Ford Mustang"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016)
ORDER BY 1;

CREATE VIEW cl_project.mustang_year_price AS
SELECT year, price
FROM cl_project.cl_vehicle_postings
WHERE make_model = "Ford Mustang"
AND clean_title = TRUE
AND price < 500000
AND NOT (price < 500 AND year > 2016);





