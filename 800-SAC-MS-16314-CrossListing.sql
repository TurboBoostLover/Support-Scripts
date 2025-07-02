USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16314';
DECLARE @Comments nvarchar(Max) = 
	'Set up Crosslisting';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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
DECLARE @ClientId int = 1

exec upGetUpdateClientSetting @setting = 'EnableCrossListing', @newValue = 1, @clientId = 1, @valuedatatype = 'bit', @section = 'Curriqunet'

UPDATE MetaTemplateType
SET IsReducedView = 0
WHERE MetaTemplateTypeId in (
6
)

DECLARE @SupportAdminUserId INT = (SELECT Id FROM [User] WHERE LastName = 'SupportAdmin')

Insert into CrossListingFieldSyncBlackList
(MetaAvailableFieldId,ClientId)
Values
(873,@ClientId), 
(888,@ClientId), 
(2697,@ClientId),   
(2558,@ClientId),    
(600,@ClientId),
(1731,@ClientId), 
(607,@ClientId), 
(1392,@ClientId), 
(586,@ClientId);

/********************************************************************
 * Add cross listings
 ********************************************************************/
DECLARE @cl Table (Text NVARCHAR(MAX), base INT, related INT, non int)

INSERT INTO @cl (text, base, related, non)
select  c1.Title, c1.Id, c2.Id, c1.ProposalTypeId
FROM CourseRelatedCourse crc
	INNER JOIN Course c1 on c1.Id = crc.CourseId
	Inner JOIN StatusAlias sa1 on sa1.Id = c1.StatusAliasId
	Inner JOIN Course c2 ON c2.Id = crc.RelatedCourseId
	INNER JOIN StatusAlias sa2 ON sa2.Id = c2.StatusAliasId
WHERE courseId != crc.RelatedCourseId
	AND courseId != c1.PreviousId
	AND sa1.StatusBaseId IN (1)
	AND sa2.StatusBaseId IN (1) 
UNION
select  c1.Title, c1.Id, c2.Id,c1.ProposalTypeId
FROM CourseRelatedCourse crc
	INNER JOIN Course c1 on c1.Id = crc.CourseId
	Inner JOIN StatusAlias sa1 on sa1.Id = c1.StatusAliasId
	Inner JOIN Course c2 ON c2.Id = crc.RelatedCourseId
	INNER JOIN StatusAlias sa2 ON sa2.Id = c2.StatusAliasId
WHERE courseId != crc.RelatedCourseId
	AND courseId != c1.PreviousId
	AND sa1.StatusBaseId IN (6)
	AND sa2.StatusBaseId IN (1) 

INSERT INTO CrossListing (Title, AddedBy_UserId, AddedOn, ClientId)
select Distinct Text, @SupportAdminUserId, GETDATE(), @clientId
FROM @cl

DELETE FROM @cl WHERE base in (
	SELECT DISTINCT related FROM @cl
)
/********************************************************************
 *  INsert the Courses that are cross-listed
 ********************************************************************/
INSERT INTO CrossListingCourse (CrosslistingId,CourseId,AddedBy_UserId,AddedOn,IsSource, IsSynced)
SELECT DISTINCT cl.Id, cll.base, @SupportAdminUserId, GETDATE(), 1, 0
FROM @cl cll
	INNER JOIN CrossListing cl ON cl.Title = cll.text AND cll.Base IS Not NULL
Union
SELECT DISTINCT cl.Id, cll.related , @SupportAdminUserId, GETDATE(), 0, 0
FROM @cl cll
	INNER JOIN CrossListing cl ON cl.Title = cll.text

/********************************************************************
 * Insert the ProposalTypes
 ********************************************************************/
DECLARE @CreditProposalTypeId INT= 28
Merge into CrossListingProposalType as Target
Using (
    Select Id as CrosslistingId,
        @CreditProposalTypeId as ProposalTypeId,
        @SupportAdminUserId as AddedBy_UserId,
        GetDate() as AddedOn,
        @ClientId as ClientId
    From Crosslisting
) as s on 1=0
When not matched then
Insert (CrossListingId,ProposalTypeId,AddedBy_UserId,AddedOn,ClientId)
VALUES (s.CrossListingId,s.ProposalTypeId,s.AddedBy_UserId,s.AddedOn,s.ClientId);


/********************************************************************
 * Sync the cross listings
 ********************************************************************/
DECLARE @cls Table (Id INT IDENTITY Primary KEY, clId INT)
DECLARE @count INT = 1;
DECLARE @crosslistingId INT;
--DECLARE @SupportAdminUserId INT = (SELECT Id FROM [User] WHERE LastName = 'SupportAdmin')

INSERT INTO @cls (clId)
SELECT DISTINCT crosslistingId FROM CrossListingCourse

WHILE @count <= (Select max(Id) FROM @cls)
BEGIN


SET @crosslistingId = (SELECT clId FROM @cls where Id = @count)

Exec upSyncCrossListing @crossListingId = @crosslistingId, @userId = @SupportAdminUserId;
SET @count += 1

END;

DECLARE @BAD INTEGERS
INSERT INTO @BAD
SELECT Id FROM CrossListing
WHERE Id not in (
SELECT CrossListingId FROM CrossListingCourse
)

DELETE FROM CrossListingProposalType
WHERE CrossListingId in (
	SELECT Id FROM @BAD
)

DELETE FROM CrossListing
WHERE Id in (
	SELECT Id FROM @BAD
)

;WITH DistinctSubjects AS (
    SELECT
        cl.Id,
        c.Title,
        c.CourseNumber,
        s.SubjectCode
    FROM CrossListing AS cl
    INNER JOIN CrossListingCourse AS clc ON clc.CrossListingId = cl.Id
    INNER JOIN Course AS c ON clc.CourseId = c.Id
    INNER JOIN Subject AS s ON c.SubjectId = s.Id
    GROUP BY cl.Id, c.Title, c.CourseNumber, s.SubjectCode
),
ConcatenatedResults AS (
    SELECT 
        ds.Id, 
        CONCAT(ds.Title, ' ', ds.CourseNumber, ' ', 
               dbo.ConcatWithSep_Agg(' - ', ds.SubjectCode)) AS ConcatenatedResult
    FROM DistinctSubjects AS ds
    GROUP BY ds.Id, ds.Title, ds.CourseNumber
)
UPDATE cl
SET cl.Title = cr.ConcatenatedResult
FROM CrossListing AS cl
INNER JOIN ConcatenatedResults AS cr ON cl.Id = cr.Id;

COMMIT