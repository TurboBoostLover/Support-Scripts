USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16300';
DECLARE @Comments nvarchar(Max) = 
	'Remove all Historical courses from catalog';
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
	declare @serializedStatusBaseMapping nvarchar(max);
 
	select @serializedStatusBaseMapping = (
		select
			vals.Catalog_StatusBaseId as [catalogStatusBaseId],
			vals.Entity_StatusBaseId as [entityStatusBaseId]
		from (
			values
			-- Active catalog
			(1, 1),
			(1, 2),
			-- Approved catalog
			(2, 1),
			(2, 2),
			-- Draft catalog
			(4, 1),
			(4, 2),
			-- Historical catalog
			(5, 1),
			(5, 2),
			(5, 5),
			-- In Review catalog
			(6, 1),
			(6, 2),
			-- Rejected catalog
			(7, 1),
			(7, 2),
			(7, 5)
		) vals (Catalog_StatusBaseId, Entity_StatusBaseId)
		for json path
	);
 
	update cp
	set cp.Config = json_modify(isnull(cp.Config, '{}'), '$.statusBaseMapping', json_query(@serializedStatusBaseMapping))
	from CurriculumPresentation cp
	where cp.Id = 13;