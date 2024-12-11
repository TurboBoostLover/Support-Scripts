USE [delta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15754';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text that just displays static text';
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
		select Id as [Value]
			, concat(
				case
					when AwardTypeId in (
						3--Certificate of Achievement
						, 4--Associate in Arts Degree
						, 5--Associate in Science Degree
						, 10--Certificate of Competency 
						, 11--Certificate of Completion
					)
						then concat(
							''<div>''
								, ''<b>Supporting Documentation:</b>''
							, ''</div>''
						)
					when AwardTypeId in (
						7--Associate in Arts for Transfer (AA-T)
						, 8--Associate in Science for Transfer (AS-T)
					)
						then concat(
							''<div>''
								, ''<b>Transfer Model Curriculum:</b>''
							, ''</div>''
						)
					else ''''
				end
				, case
					when AwardTypeId in (
						3--Certificate of Achievement
						, 4--Associate in Arts Degree
						, 5--Associate in Science Degree
						, 10--Certificate of Competency 
						, 11--Certificate of Completion
					)
						then concat(
							''<div>''
								, ''If the selected program goal is “Career Technical Education (CTE)” or “Career Technical Education (CTE) and Transfer,” then the following are required as additional supporting documentation*:''
								, ''<ul>''
									, ''<li>Labor Market Information and Analysis – Current LMI and analysis, or other comparable information, must show that jobs are available for program completers within the local service area of the individual college and/or that job enhancement or promotion justifies the proposed curriculum. <span style="color: red;">The LMI report cannot be older than 2 years.</span></li>''
									, case
										when AwardTypeId in (
											3--Certificate of Achievement
											, 4--Associate in Arts Degree
											, 5--Associate in Science Degree
										)
											then ''<li>Advisory Committee Recommendation – includes advisory committee membership and meeting minutes that clearly detail the recommendation for the specific program being offered by the college.</li>''
										else ''''
									end
								, ''</ul>''
							, ''</div>''
						)
					when AwardTypeId in (
						7--Associate in Arts for Transfer (AA-T)
						, 8--Associate in Science for Transfer (AS-T)
					)
						then concat(
							''<div>''
								, ''An inter-segmentally developed <a href="https://www.cccco.edu/About-Us/Chancellors-Office/Divisions/Educational-Services-and-Support/What-we-do/Curriculum-and-Instruction-Unit/Templates-For-Approved-Transfer-Model-Curriculum" target="_blank">Transfer Model Curriculum</a> (TMC) defines the major or area of emphasis for all ADT degrees. The Academic Senate of the California State University has developed a Transfer Model Curriculum (TMC) for certain majors that have been identified for students who transfer from a California community college to CSU. A TMC is considered to have final approval when the template is posted by the Chancellor’s Office. The approved templates are located on the Chancellor’s Office Educational Services and Support Division webpage under Templates for Transfer Model Curriculum.''
								, ''<div>&nbsp;</div>''
								, ''<ol>''
									, ''<li>Visit the Chancellor''''s Office TMC template website by clicking on the provided link <a href="https://www.cccco.edu/About-Us/Chancellors-Office/Divisions/Educational-Services-and-Support/What-we-do/Curriculum-and-Instruction-Unit/Templates-For-Approved-Transfer-Model-Curriculum" target="_blank">here</a>.</li>''
									, ''<li>Download the relevant template corresponding to your program.</li>''
									, ''<li>Complete the downloaded document with the required information.</li>''
									, ''<li>Upload the filled-out document.</li>''
									, ''<li>Attach the document to your program proposal submission.</li>''
								, ''</ol>''
								, ''<div>''
									, ''<b>Transfer Documentation:</b>''
								, ''</div>''
								, ''<div>''
									, ''Please refer to the TMC Template for the specific type of transfer documentation required for the ADT discipline. Articulation and transfer reports may be downloaded from the <a href="https://assist.org/" target="_blank">ASSIST</a> website (www.assist.org). ASSIST is the official online repository of articulation for California’s public colleges and universities.''
								, ''</div>''
							, ''</div>''
							, ''<div>&nbsp;</div>''
						)
					else ''''
				end
				, case
					when AwardTypeId in (
						3--Certificate of Achievement
						, 4--Associate in Arts Degree
						, 5--Associate in Science Degree
						, 10--Certificate of Competency 
						, 11--Certificate of Completion
					)
						then concat(
							''<div>''
								, ''*An asterisk (*) appears next to TOP codes that are recognized to be Career Technical Education by the CCC Chancellor''''s Office.''
							, ''</div>''
							, ''<div>&nbsp;</div>''
						)
					else ''''
				end
				, case
					when AwardTypeId in (
						3--Certificate of Achievement
						, 4--Associate in Arts Degree
						, 5--Associate in Science Degree
						, 10--Certificate of Competency 
						, 11--Certificate of Completion
						, 7--Associate in Arts for Transfer (AA-T)
						, 8--Associate in Science for Transfer (AS-T)
					)
						then concat(
							''<div>''
								, ''<b>Program Pathway Map:</b>''
							, ''</div>''
							, ''<div>''
								, ''The program pathway map outlines the sequential order for this program. It serves as a visual guide for students, indicating both the order and expected duration for completing the program. Click <a href="https://sanjoaquindeltacollege.box.com/s/su298oj2ek90j5p9vcqjabhetd1aeu5d " target="_blank">here</a> to download the template. Make sure to include all courses in the program and attach the document to this program proposal.''
							, ''</div>''
						)
					else ''''
				end
			) as [Text]
		from Program
		where Id = @entityId;
'

DECLARE @SQL2 NVARCHAR(MAX) = '

		select Id as [Value]
			, concat(
				case
					when AwardTypeId in (
						3--Certificate of Achievement
						, 4--Associate in Arts Degree
						, 5--Associate in Science Degree
						, 10--Certificate of Competency 
						, 11--Certificate of Completion
					)
						then concat(
							''<div>''
								, ''<b>Supporting Documentation:</b>''
							, ''</div>''
						)
					when AwardTypeId in (
						7--Associate in Arts for Transfer (AA-T)
						, 8--Associate in Science for Transfer (AS-T)
					)
						then concat(
							''<div>''
								, ''<b>Transfer Model Curriculum:</b>''
							, ''</div>''
						)
					else ''''
				end
				, case
					when AwardTypeId in (
						3--Certificate of Achievement
						, 4--Associate in Arts Degree
						, 5--Associate in Science Degree
						, 10--Certificate of Competency 
						, 11--Certificate of Completion
					)
						then concat(
							''<div>''
								, ''If the selected program goal is “Career Technical Education (CTE)” or “Career Technical Education (CTE) and Transfer,” then the following are required as additional supporting documentation*:''
								, ''<ul>''
									, ''<li>Labor Market Information and Analysis – Current LMI and analysis, or other comparable information, must show that jobs are available for program completers within the local service area of the individual college and/or that job enhancement or promotion justifies the proposed curriculum. <span style="color: red;">The LMI report cannot be older than 2 years.</span></li>''
									, case
										when AwardTypeId in (
											3--Certificate of Achievement
											, 4--Associate in Arts Degree
											, 5--Associate in Science Degree
										)
											then ''<li>Advisory Committee Recommendation – includes advisory committee membership and meeting minutes that clearly detail the recommendation for the specific program being offered by the college.</li>''
										else ''''
									end
								, ''</ul>''
							, ''</div>''
						)
					when AwardTypeId in (
						7--Associate in Arts for Transfer (AA-T)
						, 8--Associate in Science for Transfer (AS-T)
					)
						then concat(
							''<div>''
								, ''An inter-segmentally developed <a href="https://www.cccco.edu/About-Us/Chancellors-Office/Divisions/Educational-Services-and-Support/What-we-do/Curriculum-and-Instruction-Unit/Templates-For-Approved-Transfer-Model-Curriculum" target="_blank">Transfer Model Curriculum</a> (TMC) defines the major or area of emphasis for all ADT degrees. The Academic Senate of the California State University has developed a Transfer Model Curriculum (TMC) for certain majors that have been identified for students who transfer from a California community college to CSU. A TMC is considered to have final approval when the template is posted by the Chancellor’s Office. The approved templates are located on the Chancellor’s Office Educational Services and Support Division webpage under Templates for Transfer Model Curriculum.''
								, ''<div>&nbsp;</div>''
								, ''<ol>''
									, ''<li>Visit the Chancellor''''s Office TMC template website by clicking on the provided link <a href="https://www.cccco.edu/About-Us/Chancellors-Office/Divisions/Educational-Services-and-Support/What-we-do/Curriculum-and-Instruction-Unit/Templates-For-Approved-Transfer-Model-Curriculum" target="_blank">here</a>.</li>''
									, ''<li>Download the relevant template corresponding to your program.</li>''
									, ''<li>Complete the downloaded document with the required information.</li>''
									, ''<li>Upload the filled-out document.</li>''
									, ''<li>Attach the document to your program proposal submission.</li>''
								, ''</ol>''
								, ''<div>''
									, ''<b>Transfer Documentation:</b>''
								, ''</div>''
								, ''<div>''
									, ''Please refer to the TMC Template for the specific type of transfer documentation required for the ADT discipline. Articulation and transfer reports may be downloaded from the <a href="https://assist.org/" target="_blank">ASSIST</a> website (www.assist.org). ASSIST is the official online repository of articulation for California’s public colleges and universities.''
								, ''</div>''
							, ''</div>''
							, ''<div>&nbsp;</div>''
						)
					else ''''
				end
				, case
					when AwardTypeId in (
						3--Certificate of Achievement
						, 4--Associate in Arts Degree
						, 5--Associate in Science Degree
						, 10--Certificate of Competency 
						, 11--Certificate of Completion
					)
						then concat(
							''<div>''
								, ''*An asterisk (*) appears next to TOP codes that are recognized to be Career Technical Education by the CCC Chancellor''''s Office.''
							, ''</div>''
							, ''<div>&nbsp;</div>''
						)
					else ''''
				end
				, case
					when AwardTypeId in (
						3--Certificate of Achievement
						, 4--Associate in Arts Degree
						, 5--Associate in Science Degree
						, 10--Certificate of Competency 
						, 11--Certificate of Completion
						, 7--Associate in Arts for Transfer (AA-T)
						, 8--Associate in Science for Transfer (AS-T)
					)
						then concat(
							''<div>''
								, ''<b>Program Pathway Map:</b>''
							, ''</div>''
							, ''<div>''
								, ''The program pathway map outlines the sequential order for this program. It serves as a visual guide for students, indicating both the order and expected duration for completing the program. Click <a href="https://sanjoaquindeltacollege.box.com/s/su298oj2ek90j5p9vcqjabhetd1aeu5d " target="_blank">here</a> to download the template. Make sure to include all courses in the program and attach the document to this program proposal.''
							, ''</div>''
						)
					else ''''
				end
			) as [Text]
		from Program
		where Id = @entityId;
	
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 8699

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 8700

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection As mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (8699, 8700)
)