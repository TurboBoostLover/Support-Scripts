use Cuesta
--SELECT * FROM ProposalType
--SELECt * FROM MetaCommandProcessor
--SELECt * FROM MetaCommandProcessormap
--SELECt * FROM ClientEntityType

SET QUOTED_IDENTIFIER OFF
DECLARE @cmdSQL NVARCHAR(MAX) = 
"
DECLARE @Table Table (title nvarchar(max), cn nvarchar(max))
INSERT INTO @Table

SELECT c.Title, c.CourseNumber FROM Course AS c
INNER JOIN MetaTemplate AS mt on c.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.ClientEntityTypeId = 1

Declare @CourseNum nvarchar(max) = (select [string2] from @parameters where string1 = 'EntityNumber')
Declare @Title nvarchar(max) = (select [string2] from @parameters where string1 = 'Title')
select 
    'Must fill out all required fields marked with a *. Course number and title may not duplicate other existing courses with the same title and number.' as Message
     ,cast(
        case 
            when @CourseNum IS NOT NULL 
			AND @CourseNum  not in (SELECT cn FROM @Table WHERE @Title = title)  
			AND @Title IS NOT NULL 
			AND @Title  not in (SELECT title FROM @Table WHERE @CourseNum = cn)
                then 1
            else 0
        end as bit) as Success
"

SET QUOTED_IDENTIFIER ON

UPDATE MetaCommandProcessor
SET CommandSQL = @cmdSQL
WHERE Id = 2

INSERT INTO MetaCommandProcessor
(Description, CommandSQL)
VALUES 
('NOI and Course Numbers can be the same but Course Numbers can not duplicate', @cmdSQL)

INSERT INTO MetaCommandProcessorMap
(ProposalTypeId, MetaCommandProcessorId, CommandType, CommandTiming, SortOrder, StartDate)
VALUES
(2, 2, 'update', 'ProposalValidation', 1, GETDATE())