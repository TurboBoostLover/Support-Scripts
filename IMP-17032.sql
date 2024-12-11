USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-17032';
DECLARE @Comments nvarchar(Max) = 
	'Update the curriculum/Program Code dropdown on the basic course information tab so the values contain the full description title.';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
declare @organization int = (select Tier1_OrganizationEntityId from CourseDetail where CourseId = @entityId)
declare @Ids integers

--CO
if(@organization = 1)
	--A,B,C,D
	insert into @Ids
	values
	(1),(2),(3),(5) 

--DA
else if(@organization = 2)
	--2,3,A,B,C,D,P
	insert into @Ids
	values
	(11),(12),(1),(3),(5),(2),(14)

--DR
else if(@organization = 7)
	--2,3,B,C,D
	insert into @Ids
	values
	(11),(12),(2),(3),(5)

--FT
else if(@organization = 8)
	--2,3,B,C
	insert into @Ids
	values
	(11),(12),(3),(5) 

--MU
else if(@organization = 46)
	--2,3,A,C,D,G,X
	insert into @Ids
	values
	(11),(12),(1),(2),(5),(4),(13)


else if(@organization = 80)
	--2
	insert into @Ids
	values
	(11)

else if(@organization = 47)
	--2,3,B,C,D,V
	insert into @Ids
	values
	(11),(12),(3),(5),(2),(7)

--LA
else if (@organization = 48)
	--B,D,C
	insert into @Ids
	values
	(2),(3),(5)

else if (@organization = 50)
	--D,E,H,I
	insert into @Ids
	values
	(2),(8),(9),(10)

else
	begin
	insert into @Ids
	select Id
	from DisciplineType
	end

select Id as [Value]
, CONCAT(Code, '' - '', Title) as [Text]
-- hack, this is used in the create proposal screen (DO NOT REMOVE THIS)
, coalesce(left(Code, 1), '''') as CourseCodeElement
from DisciplineType
where [Active] = 1
	and ([ClientId] = 1) 
	and Id in (select * from @Ids)
order by SortOrder
'
, ResolutionSql = '
select CONCAT(Code, '' - '', Title) as [Text]
from DisciplineType
where Id = @Id

'
WHERE Id = 118

UPDATE DisciplineType
SET Title = 'MA'
WHERE Id = 12

UPDATE DisciplineType
SET Title = 'BFA/BMus (Curriculum C)'
WHERE Id = 5

UPDATE DisciplineType
SET Title = 'Diploma/DipF'
WHERE Id = 2

UPDATE DisciplineType
SET Title = 'Language courses - Elementary'
WHERE Id = 8

UPDATE DisciplineType
SET Title = 'Postgraduate Diploma'
WHERE Id = 13

UPDATE DisciplineType
SET Title = 'Language courses - Advanced'
WHERE Id = 10

UPDATE DisciplineType
SET Title = 'BFA/BMus (Curriculum B)'
WHERE Id = 4

UPDATE DisciplineType
SET Title = 'Professional Diploma'
WHERE Id = 14

UPDATE DisciplineType
SET Title = 'Language courses - Intermediate'
WHERE Id = 9

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()

COMMIT