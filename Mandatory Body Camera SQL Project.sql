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
	WHEN wapo_body_camera = 'Yes' THEN 'Yes'
	ELSE 'Other??'
	END AS 'Footage',
--This counts the total number of incidents with a 'Yes' or 'No' value
	COUNT(*) AS 'Amount',
--This shows the percentage of incidents counted as each value, among the rows that have a non-NULL value for the body camera column
	COUNT(*)*100/(SELECT COUNT(*) FROM fps.dbo.mappingpoliceviolence WHERE wapo_body_camera is not NULL
AND (
(state = 'SC' AND date > CAST('2015-06-10' AS datetime))
OR (state = 'CT' AND date > CAST('2022-07-01' AS datetime))
OR (state = 'CO' AND date > CAST('2023-07-01' AS datetime))
OR (state = 'DE' AND date > CAST('2021-07-21' AS datetime))
OR (state = 'NM' AND date > CAST('2020-09-20' AS datetime))
OR (state = 'NJ' AND date > CAST('2021-06-01' AS datetime))
))
AS 'Percentage'
FROM fps.dbo.mappingpoliceviolence
WHERE wapo_body_camera is not null
--This filters for incidents that took place under a mandatory body camera state law
AND (
(state = 'SC' AND date > CAST('2015-06-10' AS datetime))
OR (state = 'CT' AND date > CAST('2022-07-01' AS datetime))
OR (state = 'CO' AND date > CAST('2023-07-01' AS datetime))
OR (state = 'DE' AND date > CAST('2021-07-21' AS datetime))
OR (state = 'NM' AND date > CAST('2020-09-20' AS datetime))
OR (state = 'NJ' AND date > CAST('2021-06-01' AS datetime))
)
GROUP BY CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' AND state <> 'CO' THEN 'No'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'No'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' AND state = 'CO' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' THEN 'Yes'
	ELSE 'Other??'
	END
ORDER BY Footage DESC

----------------------------------------------------------------------------

--The following script addresses the question: Regardless of law, was there body camera footage?
--It is similar to the previous script, but looks at incidents whether or not there was an effective mandatory body camera law in place. In addition to rows 'Yes' and 'No', there is one for dashboard camera videos.
SELECT CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' THEN 'Dash'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'No'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Police Video/Other' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' THEN 'Yes'
	ELSE 'Other??'
	END AS 'Footage',
	COUNT(*) AS 'Amount',
	COUNT(*)*100/(SELECT COUNT(*) FROM fps.dbo.mappingpoliceviolence WHERE wapo_body_camera is not NULL
AND date > CAST('2021-01-01' AS datetime))
AS 'Percentage'

FROM fps.dbo.mappingpoliceviolence
WHERE wapo_body_camera is not NULL
AND date > CAST('2021-01-01' AS datetime)
GROUP BY CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'No'
	WHEN wapo_body_camera = 'Dash Cam Video' THEN 'Dash'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'No'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Police Video/Other' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' THEN 'Yes'
	ELSE 'Other??'
	END
ORDER BY Footage DESC

----------------------------------------------------------------------------

--This script generates a table with rows of possible values for body camera column, with columns showing count of incidents where person was armed, and count of incidents where person was unarmed
WITH cte AS (
SELECT wapo_body_camera, COUNT(CASE allegedly_armed WHEN 'Allegedly Armed' THEN 1 ELSE NULL END) AS Armed , COUNT(CASE allegedly_armed WHEN 'Unarmed/Did Not Have Actual Weapon' THEN 1 ELSE NULL END) AS Not_Armed
FROM fps.dbo.MappingPoliceViolence
GROUP BY wapo_body_camera, allegedly_armed
)
SELECT wapo_body_camera, SUM(Armed) AS Armed, SUM(Not_Armed) AS Not_Armed
FROM cte
GROUP BY wapo_body_camera

----------------------------------------------------------------------------

--The following script addresses the question: Does lack of camera footage have a positive correlation with person being allegedly armed?
--For rows 'Yes' and 'No' regarding whether incidents had camera footage, this table generates columns for the number of incidents involving an armed person, the number involving an unarmed person, the percentage of each of those, and the total number of incidents for the row.
SELECT CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Dash Cam Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'Yes'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Police Video/Other' THEN 'Yes'
	WHEN wapo_body_camera = 'Taser Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' THEN 'Yes'
	ELSE 'Other??'
	END AS Footage,
COUNT(CASE allegedly_armed WHEN 'Allegedly Armed' THEN 1 ELSE NULL END) AS Armed,
COUNT(CASE allegedly_armed WHEN 'Allegedly Armed' THEN 1 ELSE NULL END)*100/(COUNT(*))
AS Percent_Armed,
COUNT(CASE allegedly_armed WHEN 'Unarmed/Did Not Have Actual Weapon' THEN 1 ELSE NULL END) AS Not_Armed,
COUNT(CASE allegedly_armed WHEN 'Unarmed/Did Not Have Actual Weapon' THEN 1 ELSE NULL END)*100/(COUNT(*))
AS Percent_Not_Armed,
COUNT(*) AS Total_Number
FROM fps.dbo.MappingPoliceViolence
WHERE (allegedly_armed = 'Allegedly Armed'
OR allegedly_armed = 'Unarmed/Did Not Have Actual Weapon')
AND
(wapo_body_camera = 'Dash Cam Video' OR
wapo_body_camera = 'Surveillance Video' OR
wapo_body_camera = 'No' OR
wapo_body_camera = 'Police Video/Other' OR
wapo_body_camera = 'Taser Video' OR
wapo_body_camera = 'Yes')
GROUP BY CASE WHEN wapo_body_camera = 'Bystander Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Dash Cam Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Surveillance Video' THEN 'Yes'
	WHEN wapo_body_camera = 'No' THEN 'No'
	WHEN wapo_body_camera = 'Police Video/Other' THEN 'Yes'
	WHEN wapo_body_camera = 'Taser Video' THEN 'Yes'
	WHEN wapo_body_camera = 'Yes' THEN 'Yes'
	ELSE 'Other??'
	END
