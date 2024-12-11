USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16434';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report';
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
UPDATE AdminReport
SET ReportSQL = '
		select c.Id as [Course Id]
			, s.SubjectCode as [Prefix]
			, c.CourseNumber as [Course Number]
			, c.Title as [Course Title]
			, c.StateId as [Course Control Number]
			, rt.Title as [Requisite Type]
			, cr.CourseRequisiteComment as [Non Course Requirement]
			, sreq.SubjectCode as [Requsisite Prefix]
			, creq.CourseNumber as [Requisite Course Number]
			, creq.Title as [Requisite Course Title]
			, creq.StateId as [Requisite Course Control Number]
			, cht.RenderedText as [Level of Scrutiny]
			, CONVERT(VARCHAR, p.ImplementDate, 101) AS [Implementation Date]
		from Course c
			inner join [Subject] s on c.SubjectId = s.Id
			INNER JOIN Proposal AS p on c.ProposalId = p.Id
			inner join CourseRequisite cr on c.Id = cr.CourseId
			left join RequisiteType rt on cr.RequisiteTypeId = rt.Id
			left join Course creq on cr.Requisite_CourseId = creq.Id
			left join [Subject] sreq on creq.SubjectId = sreq.Id
			outer apply (
				select dbo.ConcatWithSepOrdered_Agg(char(10), cht.SortOrder, cht.Title) as RenderedText
				from (
					select ht.Title
						, row_number() over (partition by cht.CourseId order by cht.SortOrder, cht.Id) as SortOrder
					from CourseHourType cht
						inner join HourType ht on cht.HourTypeId = ht.Id
					where creq.Id = cht.CourseId
				) cht
			) cht
		where c.StatusAliasId = 1--Active
		order by s.SubjectCode, c.CourseNumber, cr.SortOrder;
	
'
WHERE Id = 11