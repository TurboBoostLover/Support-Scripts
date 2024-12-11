USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16396';
DECLARE @Comments nvarchar(Max) = 
	'Update Ge Elements';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 1; /*  Default 1 is Support,  
For a complete list run the following query

Select * from history.ScriptType
*/

SELECT
 @@servername AS 'Server Name' 
,DB_NAME() AS 'Database Name'
,@JiraTicketNumber as 'Jira Ticket Number';

SET XACT_ABORT ON
BEGIN TRAN

If exists(select top 1 1 from History.ScriptsRunOnDatabase where TicketNumber = @JiraTicketNumber and Developer = @Developer and Comments = @Comments)
	THROW 51000, 'This Script has already been run', 1;

INSERT INTO History.ScriptsRunOnDatabase
(TicketNumber,Developer,Comments,ScriptTypeId)
VALUES
(@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId); 

/*--------------------------------------------------------------------
Please do not alter the script above this comment  except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing somehting 
		 that is against meta best practices but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql

-----------------Script details go below this line------------------*/
UPDATE GeneralEducationElement
SET Text = 'Communication and Analytical Thinking'
, EndDate = GETDATE()
WHERE Id = 165

UPDATE GeneralEducationElement
SET Text = 'Mathematics'
, EndDate = GETDATE()
WHERE Id = 166

DECLARE @TABLE TABLE (Id int, nam nvarchar(max))

INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, Text, SortOrder, StartDate, ClientId)
output inserted.Id, inserted.Title INTO @TABLE
VALUES
(1, '1B', 'Oral Communication and Critical Thinking', 2, GETDATE(), 2),
(1, '1C', 'Mathematical Concepts and Quantitative Reasoning', 3, GETDATE(), 2)

UPDATE GeneralEducationElement
SET SortOrder = 1
WHERE Id = 164
UPDATE GeneralEducationElement
SET SortOrder = 4
WHERE Id = 167
UPDATE GeneralEducationElement
SET SortOrder = 5
WHERE Id = 168
UPDATE GeneralEducationElement
SET SortOrder = 6
WHERE Id = 169
UPDATE GeneralEducationElement
SET SortOrder = 7
WHERE Id = 170
UPDATE GeneralEducationElement
SET SortOrder = 8
WHERE Id = 171
UPDATE GeneralEducationElement
SET SortOrder = 9
WHERE Id = 172
UPDATE GeneralEducationElement
SET SortOrder = 10
WHERE Id = 173
UPDATE GeneralEducationElement
SET SortOrder = 11
WHERE Id = 174
UPDATE GeneralEducationElement
SET SortOrder = 12
WHERE Id = 192
UPDATE GeneralEducationElement
SET SortOrder = 13
WHERE Id = 78
UPDATE GeneralEducationElement
SET SortOrder = 14
WHERE Id = 82
UPDATE GeneralEducationElement
SET SortOrder = 15
WHERE Id = 84
UPDATE GeneralEducationElement
SET SortOrder = 16
WHERE Id = 85
UPDATE GeneralEducationElement
SET SortOrder = 17
WHERE Id = 89
UPDATE GeneralEducationElement
SET SortOrder = 18
WHERE Id = 93
UPDATE GeneralEducationElement
SET SortOrder = 19
WHERE Id = 96
UPDATE GeneralEducationElement
SET SortOrder = 20
WHERE Id = 97
UPDATE GeneralEducationElement
SET SortOrder = 21
WHERE Id = 99
UPDATE GeneralEducationElement
SET SortOrder = 22
WHERE Id = 106
UPDATE GeneralEducationElement
SET SortOrder = 23
WHERE Id = 108
UPDATE GeneralEducationElement
SET SortOrder = 24
WHERE Id = 111
UPDATE GeneralEducationElement
SET SortOrder = 25
WHERE Id = 175

DECLARE @New1 int = (SELECT Id FROM @TABLE WHERE nam = '1B')
DECLARE @New2 int = (SELECT Id FROM @TABLE WHERE nam = '1C')

UPDATE CourseGeneralEducation 
SET GeneralEducationElementId = @New1
WHERE GeneralEducationElementId = 165 and CourseId in (
24815, 24406, 26077, 27088, 27556, 27091, 27794, 27029, 26850, 26823, 22971, 27816, 22973, 27832, 26987, 27112, 27263
)

UPDATE CourseGeneralEducation 
SET GeneralEducationElementId = @New2
WHERE GeneralEducationElementId = 166 and CourseId in (
21758, 27821, 21767, 27822, 22513, 27612, 23569, 27618, 23669, 27619, 23666, 27620, 20621, 27621, 26941, 26943, 27623, 27494, 26944, 24869, 24756, 21759, 27835, 24626, 24741, 26938, 26942, 27095
)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @now datetime = GETDATE()

declare @actualClientId int= (select ClientId from Course where Id = @entityId)

SELECT
	gee.Id AS Value
   ,gee.Title + '' - '' + coalesce(gee.Text,'''') AS Text
FROM [GeneralEducation] ge
INNER JOIN [GeneralEducationElement] gee
	ON gee.GeneralEducationId = ge.Id
WHERE (@now BETWEEN gee.StartDate AND ISNULL(gee.EndDate, @now)
AND ge.Title LIKE ''SC/IVC Code%''
and ge.ClientId = @actualClientId)
or gee.Id in (
SELECT GeneralEducationElementId FROM CourseGeneralEducation where courseId = @EntityId
)
ORDER BY gee.SortOrder'
WHERE Id = 150

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 150
)