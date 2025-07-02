USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18849';
DECLARE @Comments nvarchar(Max) = 
	'Fix Catalog bit for Credit Type filter';
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
UPDATE Config.ClientSetting
SET EnableCBManagement = 1		--They have it turned off in configurations since they are no longer using it in the forms, however they are using the filters in the catalog and it looks at the bit so enabling the bit will let the catalog work and wont affect the forms
WHERE 1 = 1

UPDATE CourseCBCode
SET CB04Id = 2 --Went through and checked all these are correct
WHERE CourseId in (
11184,
11155,
11156,
12194,
12279,
10502,
10503,
10504,
10505,
10506,
10510,
10511,
10512,
10515,
11988,
11871,
12003,
10195,
10196,
10551,
10457,
10101,
12315,
12569,
2109,
10015,
10018,
10094,
10197,
10309,
10355,
10357,
10359,
10360,
10364,
10369,
10381,
10384,
10389,
10391,
10399,
10400,
10402,
10403,
10405,
10408,
10411,
10412,
10433,
10434,
10435,
10436,
10488,
10491,
10496,
10497,
10498,
10508,
10513,
10526,
10527,
10528,
10773,
11158,
11159,
11160,
11161,
11162,
11267,
11270,
11276,
11277,
11855,
11931,
11963,
11964,
11966,
11967,
11968,
11969,
11970,
11971,
12105,
12192,
12196,
12601,
12701,
12705,
12706,
12707,
12783,
12788,
12789,
12914,
13670,
12316
)

--SELECT cp.SemesterId, cb.CB04Id, c.Id, c.Title, CB05Id, CB22Id, CB08Id FROM Course AS c
--INNER JOIN CourseProposal AS cp on cp.CourseId = c.Id
--INNER JOIN CourseCBCode AS cb on cb.CourseId = c.Id
--WHERE (cp.SemesterId IS NULL
--or cb.CB04Id IS NULL)
--and c.StatusAliasId = 1
--and c.Active = 1