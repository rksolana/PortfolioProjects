--This uses data created by BGG1Tool:
    --https://boardgamegeek.com/guild/3369
--Data created by BGG1Tool has columns for board games such as 'Name', 'Max Players'. In addition to a 'Max Players' column which has value of the maximum number of players, there are also columns '1Player', '2Player', '3Player', etc., with possible values like 'N' (No), 'P' (Possible), or 'B' (Best).
--This script creates several tables for a range of player configurations (by default 4-12). Each created table will only include the games that are possible to be played with that number of players.

--Define string that will be executed in WHILE loop
DECLARE @recombined_function as nvarchar(4000)
--Define string that will be split at integer variable, then recombined with variable to specify WHERE clause
DECLARE @function as nvarchar(4000)
--'MinPlayTime' and 'MaxPlayTime' are used to create range 'Playing Time'
--Columns 'Mechanic' and 'Category' have values as lists of categories/mechanics (e.g. 'Bluffing, Fantasy, Card game'). Due to personal preference, the substring 'Team-Based Game' is taken from the 'Mechanic' Column and added to 'Category' when applicable.
--In case of the table including board games across multiple collections, the final column takes the comments of each game on the BoardGameGeek list, and defaults to the price in case that game is unowned.
SET @function = 'SELECT Name as ''Game'', MaxPlayers as ''Max Players'', 
    CASE
        WHEN minplaytime = maxplaytime
        THEN CAST(PlayingTime as varchar(10))
        ELSE CONCAT(CAST(minplaytime as varchar(10)),''-'',CAST(maxplaytime as varchar(10)))
    END AS ''Playing Time (minutes)''
    , AverageWeight as ''Complexity (1-5)'',
    CASE
        WHEN CHARINDEX(''Team-Based Game'',Mechanic) > 0
        THEN CONCAT(Category,'', Team-Based Game'')
        WHEN CHARINDEX(''Cooperative Game'',Mechanic) > 0
        THEN CONCAT(Category,'', Cooperative Game'')
        ELSE Category
    END AS Categories,
    -- CASE
    --     WHEN comments_gl is null
    --     THEN CAST(Price as varchar(100))
    --     ELSE CAST(comments_gl as varchar(100))
    -- END AS Collection
FROM bgg.dbo.mygames
WHERE "Zplayer" <> ''N''
ORDER BY Name'

--Define variables that split @function in the middle of the WHERE clause, so variable in WHILE loop can be used for function.
DECLARE @first as nvarchar(4000)
--So the above function can be modified as needed without being defined in multiple parts, the below variables search for the character 'Z' in the above string.
SET @first = SUBSTRING(@function,1,CHARINDEX('Z',@function)-1)
DECLARE @third as nvarchar(4000)
SET @third = SUBSTRING(@function,CHARINDEX('Z',@function)+1,LEN(@function)-CHARINDEX('Z',@function)+2)

--WHILE loop to generate tables.
--Change below integers to change range of generated tables.
DECLARE @i int = 4
WHILE @i <= 12
BEGIN
    SET @recombined_function = @first + cast(@i as nvarchar(10)) + @third
    EXEC(@recombined_function)
    SET @i = @i + 1
END