-- - Use opencsvserde to parse university ranking data 
-- and map columns to correct data type ---
CREATE EXTERNAL TABLE IF NOT EXISTS `learn_by_doing.university_ranking_csv`(
  `university` string, 
  `year` int, 
  `rank_display` string, 
  `score` float, 
  `link` string, 
  `country` string, 
  `city` string, 
  `region` string, 
  `logo` string, 
  `type` string, 
  `research_output` string, 
  `student_faculty_ratio` float, 
  `international_students` string, 
  `size` string, 
  `faculty_count` string)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' 
WITH SERDEPROPERTIES ("separatorChar" = ",", "escapeChar" = "\\", "quoteChar"='\"') 
LOCATION
  's3://aws-glue-chandra-us-east-1/university_ranking/csv/'
TBLPROPERTIES ("skip.header.line.count"="1")

--- Option- Create a View to simplify querying --- 
--- View with correct data types ---
-- handles n_rank and excludes rank_display that are empty
-- next example shows how to handle all columns

--- Reference:
--- https://aws.amazon.com/premiumsupport/knowledge-center/athena-hive-bad-data-error-csv/
--- More generic handling of missing values 
---  COALESCE(TRY(CAST(col as type)),0)
---    cast will attempt to convert the column to specified type
---    try will catch condition when cast is unable to convert to desired type
---    try will replace error condition with a null
---    coalesce will handle scenario when you don't want null
---    in the above example, coalsece will repalce with 0 whenever column value is null or 
---    when there is a type conversion error
---  international_students and faculty_count contain comma and dot separated numbers
---   like 
---   301 Rutgers University–New Brunswick 7,965  5,009
---   305 Politecnico di Torino 5.369 1.050
CREATE OR REPLACE VIEW `learn_by_doing.university_ranking_view` AS
SELECT university,
       COALESCE(TRY(CAST(year AS int)),9999) AS year, 
       rank_display, 
       COALESCE(TRY(CAST(split_part(rank_display,'-',1) AS int)),9999) AS n_rank,
       COALESCE(TRY(CAST(score AS double)),-1) AS score, 
       country, city, region, type,
       research_output, 
       COALESCE(TRY(CAST(student_faculty_ratio AS double)),-1) AS student_faculty_ratio,
       international_students,
       size, 
       faculty_count
FROM "learn_by_doing"."university_ranking_csv"
order by year, n_rank;





-- cleanup the data 

select regexp_replace("international_students",'[.,]', '') as "faculty_count", 
regexp_replace("faculty_count",'[.,]', '') as "faculty_count"
FROM "university_ranking_csv" ;


---    Convert to appropriate type using a view
---   Simplify querying with a view
---   This time we will create an athena view ---
CREATE OR REPLACE VIEW university_ranking_view AS
SELECT university,
       COALESCE(TRY(CAST(year AS int)),9999) AS year, 
       rank_display, 
       COALESCE(TRY(CAST(split_part(rank_display,'-',1) AS int)),9999) AS n_rank,
       COALESCE(TRY(CAST(score AS double)),-1) AS score, 
       country, city, region, type,
       research_output, 
       COALESCE(TRY(CAST(student_faculty_ratio AS double)),-1) AS student_faculty_ratio,
       COALESCE(TRY(CAST(regexp_replace(international_students,'[.,]','') AS int)),-1) as international_students,
       size, 
       COALESCE(TRY(CAST(regexp_replace(faculty_count,'[.,]','') AS int)),-1) as faculty_count
FROM "learn_by_doing"."university_ranking_csv"
order by year, n_rank;