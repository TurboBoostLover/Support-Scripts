USE [compton];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17340';
DECLARE @Comments nvarchar(Max) = 
	'Update Query';
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
SET CustomSql = '		declare @nonCredit int = (
			select isNull(CB04Id, 0)
			from CourseCBCode
			where CourseId = @entityId
		);

		if (@nonCredit = 3) --3 = N - Noncredit
			begin
				select gr.Id as [Value]
					, concat(gr.Title, '' - '', gr.[Description]) as [Text]
					, gr.SortOrder
				from GradeOption gr
				where (gr.Active = 1
					and gr.Id in (1, 9, 10)
					/*
						1 = L - Letter Grade Only
						9 = P/SP/NP - Pass/Satisfactory Progress/No Pass
						10 = U - Ungraded
					*/
				)
				order by gr.SortOrder;
			end
		else
			begin
				select gr.Id as [Value]
					, concat(gr.Title, '' - '', gr.[Description]) as [Text]
				from GradeOption gr
				where (gr.Active = 1
					and gr.Id in (1, 3)
					/*
						1 = L - Letter grade only
						3 = B - Both - Letter with Pass/No Pass Option
					*/
				);
			end
		;
	'
WHERE Id = 71

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 71
)