--The following generates tables related to Mandatory Body Camera Laws and data regarding U.S. police officer-involved deaths. The database used is from:
	--https://mappingpoliceviolence.org/
--The U.S. states with effective Mandatory Body Camera Laws, with effective starting dates are:
    --South Carolina, 2015-06-10
    --Connecticut, 2022-07-01
    --Colorado, 2023-07-01
    --Delaware, 2021-07-21
    --New Mexico, 2020-09-20
    --New Jersey, 2021-06-01


--The following script addresses the question: In states with camera required, was there body camera footage?
SELECT
--This creates a column 'Footage' with values 'Yes' and 'No' depending on if relevant column indicates the presence of a body camera video (or a dashboard camera video in accordance with Colorado law)
CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' AND state <> 'CO' THEN 'No'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'No'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' AND state = 'CO' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' Then 'Yes'
	ELSE 'Other??'
	END as 'Footage',
--This counts the total number of incidents with a 'Yes' or 'No' value
	count(*) as 'Amount',
--This shows the percentage of incidents counted as each value, among the rows that have a non-NULL value for the body camera column
	count(*)*100/(select count(*) from fps.dbo.mappingpoliceviolence where wapo_body_camera is not null
AND (
(state = 'SC' AND date > cast('2015-06-10' as datetime))
OR (state = 'CT' AND date > cast('2022-07-01' as datetime))
OR (state = 'CO' AND date > cast('2023-07-01' as datetime))
OR (state = 'DE' AND date > cast('2021-07-21' as datetime))
OR (state = 'NM' AND date > cast('2020-09-20' as datetime))
OR (state = 'NJ' AND date > cast('2021-06-01' as datetime))
))
as 'Percentage'
from fps.dbo.mappingpoliceviolence
where wapo_body_camera is not null
--This filters for incidents that took place under a mandatory body camera state law
AND (
(state = 'SC' AND date > cast('2015-06-10' as datetime))
OR (state = 'CT' AND date > cast('2022-07-01' as datetime))
OR (state = 'CO' AND date > cast('2023-07-01' as datetime))
OR (state = 'DE' AND date > cast('2021-07-21' as datetime))
OR (state = 'NM' AND date > cast('2020-09-20' as datetime))
OR (state = 'NJ' AND date > cast('2021-06-01' as datetime))
)
group by CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' AND state <> 'CO' THEN 'No'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'No'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' AND state = 'CO' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' Then 'Yes'
	ELSE 'Other??'
	END
order by Footage DESC

----------------------------------------------------------------------------

--The following script addresses the question: Regardless of law, was there body camera footage?
--It is similar to the previous script, but looks at incidents whether or not there was an effective mandatory body camera law in place. In addition to rows 'Yes' and 'No', there is one for dashboard camera videos.
select CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' THEN 'Dash'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'No'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Police Video/Other' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' Then 'Yes'
	ELSE 'Other??'
	END as 'Footage',
	count(*) as 'Amount',
	count(*)*100/(select count(*) from fps.dbo.mappingpoliceviolence where wapo_body_camera is not null
AND date > cast('2021-01-01' as datetime))
as 'Percentage'

from fps.dbo.mappingpoliceviolence
where wapo_body_camera is not null
AND date > cast('2021-01-01' as datetime)
group by CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' THEN 'Dash'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'No'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Police Video/Other' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' Then 'Yes'
	ELSE 'Other??'
	END
order by Footage DESC

----------------------------------------------------------------------------

--This script generates a table with rows of possible values for body camera column, with columns showing count of incidents where person was armed, and count of incidents where person was unarmed
WITH cte as (
select wapo_body_camera, count(CASE allegedly_armed WHEN 'Allegedly Armed' THEN 1 ELSE NULL END) as Armed , count(CASE allegedly_armed WHEN 'Unarmed/Did Not Have Actual Weapon' THEN 1 ELSE NULL END) as Not_Armed
from fps.dbo.MappingPoliceViolence
group by wapo_body_camera, allegedly_armed
)
select wapo_body_camera, SUM(Armed) as Armed, SUM(Not_Armed) as Not_Armed
from cte
group by wapo_body_camera

----------------------------------------------------------------------------

--The following script addresses the question: Does lack of camera footage have a positive correlation with person being allegedly armed?
--For rows 'Yes' and 'No' regarding whether incidents had camera footage, this table generates columns for the number of incidents involving an armed person, the number involving an unarmed person, the percentage of each of those, and the total number of incidents for the row.
select CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Dash Cam Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'Yes'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Police Video/Other' THEN 'Yes'
	WHEN wapo_body_camera = 'Taser Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' Then 'Yes'
	ELSE 'Other??'
	END as Footage,
count(CASE allegedly_armed WHEN 'Allegedly Armed' THEN 1 ELSE NULL END) as Armed,
count(CASE allegedly_armed WHEN 'Allegedly Armed' THEN 1 ELSE NULL END)*100/(count(*))
as Percent_Armed,
count(CASE allegedly_armed WHEN 'Unarmed/Did Not Have Actual Weapon' THEN 1 ELSE NULL END) as Not_Armed,
count(CASE allegedly_armed WHEN 'Unarmed/Did Not Have Actual Weapon' THEN 1 ELSE NULL END)*100/(count(*))
as Percent_Not_Armed,
count(*) as Total_Number
from fps.dbo.MappingPoliceViolence
WHERE (allegedly_armed = 'Allegedly Armed'
OR allegedly_armed = 'Unarmed/Did Not Have Actual Weapon')
AND
(wapo_body_camera = 'Dash Cam Video' OR
wapo_body_camera = 'Surveillance Video' OR
wapo_body_camera = 'No' OR
wapo_body_camera = 'Police Video/Other' OR
wapo_body_camera = 'Taser Video' OR
wapo_body_camera = 'Yes')
group by CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Dash Cam Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'Yes'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Police Video/Other' THEN 'Yes'
	WHEN wapo_body_camera = 'Taser Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' Then 'Yes'
	ELSE 'Other??'
	END