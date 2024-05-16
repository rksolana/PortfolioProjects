--This uses two CDC Datasets with Behavioral Risk Factor Surveillance System (BRFSS) Prevalence Data:
	--https://data.cdc.gov/Behavioral-Risk-Factors/Behavioral-Risk-Factor-Surveillance-System-BRFSS-P/dttw-5yxu/about_data
	--https://data.cdc.gov/Behavioral-Risk-Factors/Behavioral-Risk-Factors-Selected-Metropolitan-Area/j32a-sa6u/about_data
--BRFSS Datasets has columns for the question asked (Question), the response given (Response), the number of people who gave that response (Sample_Size), and the percent (Data_Value) of people who gave that response in the same year (Year), location (Location_desc), and demographic group (Break_Out). The Data_Value of rows with the same Question, Year, Location_desc, and Break_Out thus all add up to 100.
--Limiting to Question value 'How is your general health?' shows five possible Response values: 'Poor', 'Fair', 'Good', 'Very Good', and 'Excellent'. This five-point Likert scale can be transformed to a quantitave measure by assigning Response values to integers 1-5. We can then find an average score in each partiton of Year, Location, and Demographic by averaging the magnitude of each Response according to the number of responses (Sample_Size) for it.

--Produces an Average General Health score from 1-5 for data partitioned by year and location
select *,avg(cast(Likert as float)*cast(Percentage as float)/20) OVER w as Average_Likert
from (select Year, locationdesc as MSA
--Assigning each possible Response an integer value
,CASE
	WHEN ResponseID = 'RESP060' THEN '1'
	WHEN ResponseID = 'RESP059' THEN '2'
	WHEN ResponseID = 'RESP058' THEN '3'
	WHEN ResponseID = 'RESP057' THEN '4'
	WHEN ResponseID = 'RESP056' THEN '5'
	END AS Likert
--Data has blank value for percent (Data_Value) when Sample_Size is too small, so it needs to be converted
,CASE
	WHEN data_value = '' THEN '0'
	ELSE data_value
	END AS Percentage
from brfss.dbo.smart
where QuestionID = 'GENHLTH'
) as SubTable
--Dataset 'SMART' (Selected Metropolitan Area Risk Trends) has only one possible Demographic (Break_Out) value ('Overall')
WINDOW w AS (PARTITION BY year, MSA)

-------------------------------------------------------------

--This does the same as above using a CTE. It also produces an average score for each year and location
WITH
cte (Year, MSA, Likert, Percentage, Average_Likert)
AS
(
select Year, locationdesc as MSA
,CASE
	WHEN ResponseID = 'RESP060' THEN '1'
	WHEN ResponseID = 'RESP059' THEN '2'
	WHEN ResponseID = 'RESP058' THEN '3'
	WHEN ResponseID = 'RESP057' THEN '4'
	WHEN ResponseID = 'RESP056' THEN '5'
	END AS Likert	
,CASE
	WHEN data_value = '' THEN '0'
	ELSE data_value
	END AS Percentage
,avg(cast(
CASE
	WHEN ResponseID = 'RESP060' THEN '1'
	WHEN ResponseID = 'RESP059' THEN '2'
	WHEN ResponseID = 'RESP058' THEN '3'
	WHEN ResponseID = 'RESP057' THEN '4'
	WHEN ResponseID = 'RESP056' THEN '5'
	END
as float)*cast(
CASE
	WHEN data_value = '' THEN '0'
	ELSE data_value
	END
as float)/20) OVER w as Average_Likert
from brfss.dbo.smart
where QuestionID = 'GENHLTH'
WINDOW w AS (PARTITION BY year, locationdesc)
)
select Year, MSA
--Make average score NULL in the case that the percentage being 0 drive the score below an actual possible value of 1
, CASE
	WHEN Average_Likert < 1 THEN NULL
	ELSE Average_Likert
	END as Average_Likert
, AVG(Average_Likert) OVER (PARTITION BY year) as Average_Likert_in_Year, AVG(Average_Likert) OVER (PARTITION BY MSA) as Average_Likert_in_MSA
from cte

-------------------------------------------------------------

--This Dataset is similar to the previous, but Location_desc only has values for states, and Break_Out has many possible values for different demographics
--Produces an Average General Health score from 1-5 for data partitioned by year, location, and demographic (Break_Out)
select *,avg(cast(Likert as float)*cast(Percentage as float)/20) OVER w as Average_Likert
from (select Year, locationdesc as State, Break_Out
,CASE
	WHEN ResponseID = 'RESP060' THEN '1'
	WHEN ResponseID = 'RESP059' THEN '2'
	WHEN ResponseID = 'RESP058' THEN '3'
	WHEN ResponseID = 'RESP057' THEN '4'
	WHEN ResponseID = 'RESP056' THEN '5'
	END AS Likert	
,CASE
	WHEN data_value = '' THEN '0'
	ELSE data_value
	END AS Percentage
from brfss.dbo.brfss
where QuestionID = 'GENHLTH'
) as SubTable
WINDOW w AS (PARTITION BY year, State, Break_Out)

-------------------------------------------------------------

--This does the same as above using a CTE. It also produces an average score for each year, location, and Break_Out value
WITH
cte (Year, State, Break_Out, Break_Out_Category, Likert, Percentage, Average_Likert)
AS
(
select Year, locationdesc as MSA, Break_Out, Break_Out_Category
,CASE
	WHEN ResponseID = 'RESP060' THEN '1'
	WHEN ResponseID = 'RESP059' THEN '2'
	WHEN ResponseID = 'RESP058' THEN '3'
	WHEN ResponseID = 'RESP057' THEN '4'
	WHEN ResponseID = 'RESP056' THEN '5'
	END AS Likert	
,CASE
	WHEN data_value = '' THEN '0'
	ELSE data_value
	END AS Percentage
,avg(cast(
CASE
	WHEN ResponseID = 'RESP060' THEN '1'
	WHEN ResponseID = 'RESP059' THEN '2'
	WHEN ResponseID = 'RESP058' THEN '3'
	WHEN ResponseID = 'RESP057' THEN '4'
	WHEN ResponseID = 'RESP056' THEN '5'
	END
as float)*cast(
CASE
	WHEN data_value = '' THEN '0'
	ELSE data_value
	END
as float)/20) OVER w as Average_Likert
from brfss.dbo.brfss
where QuestionID = 'GENHLTH'
WINDOW w AS (PARTITION BY year, locationdesc, Break_Out)
)
select Year, MSA, Break_Out_Category
, CASE
	WHEN Break_Out_Category = 'Age Group' THEN 'Age: '+Break_Out
	WHEN Break_Out_Category = 'Education Attained' THEN 'Education: '+Break_Out
	WHEN Break_Out_Category = 'Gender' THEN 'Gender: '+Break_Out
	WHEN Break_Out_Category = 'Household Income' THEN 'Income: '+Break_Out
	WHEN Break_Out_Category = 'Overall' THEN Break_Out
	WHEN Break_Out_Category = 'Race/Ethnicity' THEN 'Race: '+Break_Out
	END as Break_Out
--Make average score NULL in the case that the percentage being 0 drive the score below an actual possible value of 1
, CASE
	WHEN Average_Likert < 1 THEN NULL
	ELSE Average_Likert
	END as Average_Likert
, AVG(Average_Likert) OVER (PARTITION BY year) as Average_Likert_in_Year, AVG(Average_Likert) OVER (PARTITION BY MSA) as Average_Likert_in_MSA, AVG(Average_Likert) OVER (PARTITION BY Break_Out) as Average_Likert_Break_Out
from cte

-------------------------------------------------------------

--Dataset 'BRFSS' has a Location_desc column that has State in the form of e.g. 'Georgia'. Dataset 'SMART' has a Location_desc column of Metropolitan Statistical Areas in the form of e.g. 'Chattanooga, TN-GA'
--In order to compare the two Datasets on the same State value, This separates the Location_desc values of Dataset 'Smart' and separates them into multiple columns for city and each state
with state_cte (Year,States,City,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High)
AS
(
SELECT Year
--Separate second half of location as abbreviated states
,SUBSTRING(Locationdesc, CHARINDEX(',',Locationdesc,1)+2, CHARINDEX(' ', Locationdesc, CHARINDEX(',',Locationdesc,1)+2) - CHARINDEX(',',Locationdesc,1)-2) as States
--Separate first half of location as Metropolitan Statistical Area/City
,SUBSTRING(Locationdesc, 1, CHARINDEX(',',Locationdesc,1)-1) as City
,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High
FROM BRFSS.dbo.SMART
)
select States
,SUBSTRING(States,1,2) as First_State
--Add abbreviated states into multiple columns if state portion has hyphens
,CASE
	WHEN States like '%-%' THEN SUBSTRING(States,4,2)
	END AS Second_State
,CASE
	WHEN SUBSTRING(States,4,3) like '%-%' THEN SUBSTRING(States,7,2)
	END AS Third_State
,CASE
	WHEN SUBSTRING(States,9,3) <> '' THEN SUBSTRING(States,10,2)
	END AS Fourth_State
from state_cte
where states like '%-%'

-------------------------------------------------------------

--This duplicates rows with multiple states, adding different states into a unified 'State' column, e.g. one row with Location_desc value 'Chattanooga, TN-GA' becomes two duplicate rows with one value for 'State' column as 'TN' and other as 'GA'
with state_cte (Year,States,City,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High,GeoLocation)
AS
(
SELECT Year
,SUBSTRING(Locationdesc, CHARINDEX(',',Locationdesc,1)+2, CHARINDEX(' ', Locationdesc, CHARINDEX(',',Locationdesc,1)+2) - CHARINDEX(',',Locationdesc,1)-2) as States
,SUBSTRING(Locationdesc, 1, CHARINDEX(',',Locationdesc,1)-1) as City
,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High,GeoLocation
FROM BRFSS.dbo.SMART
)
--First_State
select Year
,SUBSTRING(States,1,2) as State
,City,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High,GeoLocation
from state_cte
UNION ALL
--Second_State
select Year
,CASE
	WHEN States like '%-%' THEN SUBSTRING(States,4,2)
	END AS State
,City,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High,GeoLocation
from state_cte
WHERE SUBSTRING(States,4,2) <> ''
UNION ALL
--Third_State
SELECT Year
,CASE
	WHEN SUBSTRING(States,4,3) like '%-%' THEN SUBSTRING(States,7,2)
	END AS State
,City,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High,GeoLocation
FROM state_cte
WHERE SUBSTRING(States,7,2) <> ''
UNION ALL
--Fourth_State
SELECT Year
,CASE
	WHEN SUBSTRING(States,9,3) <> '' THEN SUBSTRING(States,10,2)
	END AS Fourth_State
,City,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High,GeoLocation
FROM state_cte
WHERE SUBSTRING(States,10,2) <> ''

-------------------------------------------------------------

--This does the same as above, but generalized to divide based on location of hyphens, rather than the specific index of the two-character state abbreviations
with state_cte (Year,States,City,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High)
AS
(
SELECT Year
,SUBSTRING(Locationdesc, CHARINDEX(',',Locationdesc,1)+2, CHARINDEX(' ', Locationdesc, CHARINDEX(',',Locationdesc,1)+2) - CHARINDEX(',',Locationdesc,1)-2) as States
,SUBSTRING(Locationdesc, 1, CHARINDEX(',',Locationdesc,1)-1) as City
,Class,Topic,Question,Response,Break_Out,Break_Out_Category,Sample_Size,Data_value,Confidence_limit_Low,Confidence_limit_High
FROM BRFSS.dbo.SMART
)
select States
,SUBSTRING(States,1,2) as First_State
,CASE
	WHEN States like '%-%' THEN SUBSTRING(States,CHARINDEX('-',States,1)+1,2)
	END AS Second_State
,CASE
	WHEN SUBSTRING(States,CHARINDEX('-',States,1)+1,LEN(States)) like '%-%' THEN SUBSTRING(States,CHARINDEX('-',States,CHARINDEX('-',States,1)+1)+1,2)
	END AS Third_State
,CASE
	WHEN SUBSTRING(States,CHARINDEX('-',States,CHARINDEX('-',States,CHARINDEX('-',States,1)+1)+1),LEN(States)) is not NULL 
	AND CHARINDEX('-',States,CHARINDEX('-',States,1)+1) <> 0
	AND CHARINDEX('-',States,CHARINDEX('-',States,CHARINDEX('-',States,1)+1)+1) <> 0
	THEN SUBSTRING(States,CHARINDEX('-',States,CHARINDEX('-',States,CHARINDEX('-',States,1)+1)+1)+1,2)
	END AS Fourth_State
	,SUBSTRING(States,9,3)
from state_cte

-------------------------------------------------------------

--This combines previous queries, and creates an Average General Health Score where rows with multiple states are separated into multiple rows for each state
;WITH
--Create average general health score
cte1 
AS
(
select Year, locationdesc
,CASE
	WHEN ResponseID = 'RESP060' THEN '1'
	WHEN ResponseID = 'RESP059' THEN '2'
	WHEN ResponseID = 'RESP058' THEN '3'
	WHEN ResponseID = 'RESP057' THEN '4'
	WHEN ResponseID = 'RESP056' THEN '5'
	END AS Likert	
,CASE
	WHEN data_value = '' THEN '0'
	ELSE data_value
	END AS Percentage
,avg(cast(
CASE
	WHEN ResponseID = 'RESP060' THEN '1'
	WHEN ResponseID = 'RESP059' THEN '2'
	WHEN ResponseID = 'RESP058' THEN '3'
	WHEN ResponseID = 'RESP057' THEN '4'
	WHEN ResponseID = 'RESP056' THEN '5'
	END
as float)*cast(
CASE
	WHEN data_value = '' THEN '0'
	ELSE data_value
	END
as float)/20) OVER w as Average_Likert,GeoLocation
from brfss.dbo.smart
where QuestionID = 'GENHLTH'
WINDOW w AS (PARTITION BY year, locationdesc)
),
--Separate Location column into separate MSA/City and State columns
cte2 
AS
(
SELECT Year
,SUBSTRING(Locationdesc, CHARINDEX(',',Locationdesc,1)+2, CHARINDEX(' ', Locationdesc, CHARINDEX(',',Locationdesc,1)+2) - CHARINDEX(',',Locationdesc,1)-2) as States
,SUBSTRING(Locationdesc, 1, CHARINDEX(',',Locationdesc,1)-1) as Demographic
, CASE
	WHEN Average_Likert < 1 THEN NULL
	ELSE Average_Likert
	END as Average_Likert
,GeoLocation
FROM cte1
)
--Separate rows with multiple states into multiple rows with each state
--First_State
select Year
,SUBSTRING(States,1,2) as State
,'MSA' as 'Demographic Category'
,Demographic,Average_Likert
,GeoLocation
from cte2
UNION ALL
--Second_State
select Year
,CASE
	WHEN States like '%-%' THEN SUBSTRING(States,4,2)
	END AS State
,'MSA' as 'Demographic Category'
,Demographic,Average_Likert
,GeoLocation
from cte2
WHERE SUBSTRING(States,4,2) <> ''
UNION ALL
--Third_State
SELECT Year
,CASE
	WHEN SUBSTRING(States,4,3) like '%-%' THEN SUBSTRING(States,7,2)
	END AS State
,'MSA' as 'Demographic Category'
,Demographic,Average_Likert
,GeoLocation
FROM cte2
WHERE SUBSTRING(States,7,2) <> ''
UNION ALL
--Fourth_State
SELECT Year
,CASE
	WHEN SUBSTRING(States,9,3) <> '' THEN SUBSTRING(States,10,2)
	END AS Fourth_State
,'MSA' as 'Demographic Category'
,Demographic,Average_Likert
,GeoLocation
FROM cte2
WHERE SUBSTRING(States,10,2) <> ''
--Create similar table using 'BRFSS' Dataset with the same columns
Select Year, Locationdesc as State
--This allows for 'Break_Out' values (e.g. 'Female') to be placed in same dimension as Metropolitan Statistical area from previous Dataset
, Break_Out_Category as 'Demographic Category', CASE
	WHEN Break_Out_Category = 'Age Group' THEN 'Age: '+Break_Out
	WHEN Break_Out_Category = 'Education Attained' THEN 'Education: '+Break_Out
	WHEN Break_Out_Category = 'Gender' THEN 'Gender: '+Break_Out
	WHEN Break_Out_Category = 'Household Income' THEN 'Income: '+Break_Out
	WHEN Break_Out_Category = 'Overall' THEN Break_Out
	WHEN Break_Out_Category = 'Race/Ethnicity' THEN 'Race: '+Break_Out
	END as Demographic, Sample_Size
from brfss.dbo.brfss
where QuestionID = 'GENHLTH'