USE [clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16459';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Summary report';
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
DECLARE @SQL NVARCHAR(MAX) = '
		select p.Id as [Value]
			, concat(
				''<div class="h3" style="font-size: 24px;">''
					, case
						--22 Associate in Arts (AA)
						--24 Associate in Science (AS)
						when p.AwardTypeId in (22, 24)
							then 
								concat(
									p.Title
									, '' - ''
									, awt.Title
									, '' Degree''
								)
						--23 Associate in Arts for Transfer (AA-T)
						--25 Associate in Science for Transfer (AS-T)
						when p.AwardTypeId in (23, 25)
							then
								concat(
									''Associate in ''
									, case
										--23 Associate in Arts for Transfer (AA-T)
										when p.AwardTypeId = 23
											then ''Arts''
										--25 Associate in Science for Transfer (AS-T)
										when p.AwardTypeid = 25
											then ''Science''
										else ''''
									end
									, '' in ''
									, p.Title
									, case
										--23 Associate in Arts for Transfer (AA-T)
										when p.AwardTypeId = 23
											then '' for Transfer Degree''
										else ''''
									end
								)
						--26 Certificate in
						when p.AwardTypeId in (26)
							then
								concat(
									p.Title
									, case
										when p.Title like ''%Certificate%''
											then
												''''
										else
											concat(
												'' - ''
												, awt.Title
											)
									end
								)
						--30 Certificate of Achievement requiring 8 to less than 16 semester units.
						--31 Certificate of Achievement requiring 16 to less than 30 semester units.
						--32 Certificate of Achievement requiring 30 to less than 60 semester units.
						--33 Certificate of Achievement requiring 60 or more semester units.
						when p.AwardTypeId in (30, 31, 32, 33)
							then
								concat(
									p.Title
									, '' - ''
									, '' Certificate of Achievement''
								)
						--29 University of California Transfer Pathway
						when p.AwardTypeId in (29)
							then
								concat(
									case
										--1 Associate of Arts (A.A.) degree
										--3 Baccalaureate of Arts (B.A.) degree
										when p.PrimaryAreaOfInterestId in (1, 3)
											then
												''Associate in Arts in ''
										--2 Associate of Science (A.S.) degree
										--4 Baccalaureate of Science (B.S.) degree
										when p.PrimaryAreaOfInterestId in (2, 4)
											then ''Associate in Science in ''
										else ''''
									end
									, p.Title
									, '' for UC Transfer Degree''
								)
					else 
						concat(
							p.Title
							, '' - ''
							, awt.Title
						)
					end
				, ''</div>''
				, ''<br />''
				, ''<table>''
					, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Major #: ''
						, ''</td>''
						, ''<td>''
							, pdet.AcademicCareer
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Effective Term: ''
						, ''</td>''
						, ''<td>''
							, sem.Title
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Effective Date: ''
						, ''</td>''
						, ''<td>''
							, format(sem.TermStartDate, ''MM/dd/yyy'')
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Curriculum Committee Approval: ''
						, ''</td>''
						, ''<td>''
							, format(pd.ProgramDate, ''MM/dd/yyyy'')
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Board of Trustee Approval: ''
						, ''</td>''
						, ''<td>''
							, format(pd2.ProgramDate, ''MM/dd/yyyy'')
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Program Control Number: ''
						, ''</td>''
						, ''<td>''
							, p.UniqueCode2
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Top Code: ''
						, ''</td>''
						, ''<td>''
							, CONCAT(
        SUBSTRING(cb03.Code, 1, LEN(cb03.Code) - 2), 
        ''.'', 
        SUBSTRING(cb03.Code, LEN(cb03.Code) - 1, 2), 
        '' - '', 
        cb03.Description
    )
						, ''</td>''
					, ''</tr>''
										, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Cip Code: ''
						, ''</td>''
						, ''<td>''
							, CONCAT(cc.Code, '' - '', cc.Title)
						, ''</td>''
					, ''</tr>''
				, ''</table>''
				, ''<br />''
			) as [Text]
		from Program p
			inner join AwardType awt on p.AwardTypeId = awt.Id
			left join ProgramProposal pp on p.Id = pp.ProgramId
			left join ProgramCBCode AS pcb on pcb.ProgramId = p.Id
			LEFT JOIN Cb03 AS cb03 on pcb.CB03Id = cb03.ID
			LEFT JOIN ProgramSeededLookup AS psl on psl.ProgramId = p.Id
			LEFT JOIN CipCode_Seeded AS cc on psl.CipCode_SeededId = cc.ID
			left join Semester sem on pp.SemesterId = sem.Id
			left join ProgramQueryText pqt on p.Id = pqt.ProgramId
			left join ProgramDate pd on p.Id = pd.ProgramId
				and pd.ProgramDateTypeId = 1--Curriculum Committee Approval
			left join ProgramDate pd2 on p.Id = pd2.ProgramId
				and pd2.ProgramDateTypeId = 2--Board of Trustees Approval
			left join ProgramDetail pdet on p.Id = pdet.ProgramId
		where p.Id = @entityId;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 1384

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 1384
)