USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18001';
DECLARE @Comments nvarchar(Max) = 
	'Fix Entity title on course Modify form';
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
--SELECT '(', mt.MetaTemplateId, ', ''', mt.EntityTitleTemplateString, ''')' FROM MetaTemplate AS mt
--INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--WHERE mtt.EntityTypeId <> 2

DECLARE @Table TABLE (TempId int, String NVARCHAR(MAX))
INSERT INTO @Table
VALUES
(	1	, '[0] [1] - [2]'),
(	3	, '[0] [1] - [2]'),
(	4	, '[0] [1] - [2]'),
(	5	, '[0] [1] - [2]'),
(	6	, '[0] [1] - [2]'),
(	7	, NULL),
(	8	, '[0] [1] - [2]'),
(	10	, '[0] [1] - [2]'),
(	11	, '[0] [1] - [2]'),
(	12	, '[0] [1] - [2]'),
(	13	, '[0] [1] - [2]'),
(	14	, '[0] [1] - [2]'),
(	15	, '[0] [1] - [2]'),
(	16	, '[0] [1] - [2]'),
(	17	, '[0] [1] - [2]'),
(	18	, NULL),
(	19	, '[0] [1] - [2]'),
(	20	, NULL),
(	21	, '[0] [1] - [2]'),
(	22	, '[0] [1] - [2]'),
(	23	, '[0] [1] - [2]'),
(	24	, '[0] [1] - [2]'),
(	25	, '[0] [1] - [2]'),
(	26	, '[0] [1] - [2]'),
(	27	, NULL),
(	28	, '[0] [1] - [2]'),
(	30	, '[0] [1] - [2]'),
(	31	, '[0] [1] - [2]'),
(	32	, '[0] [1] - [2]'),
(	33	, '[0] [1] - [2]'),
(	34	, '[0] [1] - [2]'),
(	35	, '[0] [1] - [2]'),
(	36	, '[0] [1] - [2]'),
(	37	, NULL),
(	38	, NULL),
(	39	, NULL),
(	41	, '[0] [1] - [2]'),
(	42	, '[0] [1] - [2]'),
(	43	, '[0] [1] - [2]'),
(	44	, '[0] [1] - [2]'),
(	45	, '[0] [1] - [2]'),
(	46	, '[0] [1] - [2]'),
(	47	, '[0] [1] - [2]'),
(	48	, '[0] [1] - [2]'),
(	49	, '[0] [1] - [2]'),
(	51	, NULL),
(	52	, '[0] [1] - [2]'),
(	54	, '[0] [1] - [2]'),
(	55	, '[0] [1] - [2]')

UPDATE mt
SET EntityTitleTemplateString = t.String
FROM MetaTemplate AS mt
INNER JOIN @Table AS t on mt.MetaTemplateId = t.TempId

DECLARE @Courses INTEGERS;

INSERT INTO @Courses
SELECT Id FROM Course
WHERE Active = 1;

DECLARE @entityId INT;

DECLARE courses Cursor FOR
SELECT Id FROM @Courses;

OPEN courses;

FETCH NEXT FROM courses INTO @entityId;

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC dbo.upCreateEntityTitle @entityTypeId = 1, @entityId = @entityId;
	FETCH NEXT FROM courses INTO @entityId;
END;

Close courses;

DEALLOCATE courses;