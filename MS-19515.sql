USE [butte];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19515';
DECLARE @Comments nvarchar(Max) = 
	'Fix Catalog Query to not break when bad sort orders are in DaArea';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
UPDATE OutputModelClient
SET ModelQuery = '
		--#region model query

		--#region model tables
		declare @entityList_internal table (
			InsertOrder int identity (1, 1)
			, Id int primary key
		);
		--#endregion model tables

		insert into @entityList_internal (Id)
		select Id
		from @entityList;

		select eli.Id
		   , m.Model
		from @entityList_internal eli
			inner join Program p on eli.Id = p.Id
			cross apply (
				select
					(
						select eli.InsertOrder
							, p.[Description]
							, (
								select po.Outcome
								from ProgramOutcome po
								where po.ProgramId = eli.Id
								and po.Active = 1
								order by po.SortOrder, po.Id
								for json path
							)
							as Outcomes
							,(
								select STRING_AGG(da.[Description], '', '') WITHIN GROUP (ORDER BY Da.SortOrder, Da.Id)
								from ProgramArea pa
									left join DaArea da on da.Id = pa.DaAreaId
								where pa.ProgramId = eli.Id
							) as GEArea
							, (
								select pc.Title
								from ProgramCode pc
								where pc.Id = p.ProgramCodeId 
							) as ProgramCode
							, (
								select pt.Title
								from ProgramType pt
								where pt.Id = p.ProgramTypeId
							) as ProgramGoal
						for json path, without_array_wrapper
					)
					Model
			) m
		;
		--#endregion model query'
WHERE Id = 1

UPDATE DaArea
SET EndDate = GETDATE()
WHERE Id = 7