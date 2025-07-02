USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18556';
DECLARE @Comments nvarchar(Max) = 
	'Update Instructional Program Review';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =6; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (18)		--comment back in if just doing some of the mtt's

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('I. Subjects', 'ModuleRelatedModule01', 'Reference_SubjectId','Subject'),
('II. Curriculum, Instruction and Assessment', 'ModuleCRN', 'Bit01', 'Tab')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'triggersectionrefresh', f.TabId, f2.SectionId FROM @Fields  AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
WHERE f.Action = 'Tab'
and f2.Action = 'Subject'

DECLARE @SQL NVARCHAR(MAX) = '

		--declare @entityId int = (1080);

		declare @rows table (id int, row nvarchar(max), ident int IDENTITY (1,1));

		insert into @rows
		select c.Id,
			concat(
				''<tr>'',
					''<td class="tg-73oq">'', 
						s.SubjectCode, '' '',  c.CourseNumber,
					''</td>'',
					''<td class="tg-73oq">'',
						 c.Title,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from CourseGeneralEducation 
								where CourseId = c.Id
								and GeneralEducationElementId = 1599--1599 = CSU Transfer Course
							)
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when (
								select count(GeneralEducationElementId)
								from CourseGeneralEducation 
								where CourseId = c.Id
								/* 
									1599 = CSU Transfer Course
									1559 = UC Transfer Course
								*/
								and GeneralEducationElementId in (1599,1559)
								group by CourseId
							) = 2
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from CourseGeneralEducation 
								where CourseId = c.Id
								and GeneralEducationElementId in (
									select Id
									from GeneralEducationElement
									/* 
										801 = Fresno General Education A: Natural Sciences
										822 = Fresno General Education B: Social and Behavioral Sciences
										823 = Fresno General Education C: Humanitites
										824 = Fresno General Education D: Language and Rationality
										825 = Fresno General Education E: Lifetime Wellness
										826 = Fresno General Education F: Government and American Institutions
										827 = Fresno General Education G: Communication
										828 = Fresno General Education C: Humanities
									*/
									where GeneralEducationId in (801,822,823,824,825,826,827,828)
								)
							 ) 
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from CourseGeneralEducation 
								where CourseId = c.Id
								and GeneralEducationElementId in (
									select Id
									from GeneralEducationElement
									/*
										805 = CSU GE Area A: Communication in the English Language and Critical Thinking
										815 = CSU GE Area B: Physical and its Life Forms(mark all that apply)
										816 = CSU GE Area C: Arts, Literature, Philosophy and Foreign Languages
										817 = CSU GE Area D: Social, Political, and Economic Institutions and Behavior, Historical
										818 = CSU GE Area E: Lifelong Understanding and Self-Development
										821 = CSU GE Area F: Ethnic Studies
									*/
									where GeneralEducationId in (805,815,816,817,818,821)
								)
							) 
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from CourseGeneralEducation 
								where CourseId = c.Id
								and GeneralEducationElementId in (
									select Id FROM GeneralEducationElement
									/*
										806 = IGETC Area 1: English Communication
										811 = IGETC Area 2: Mathematical Concepts and Quantitative Reasoning
										812 = IGETC Area 3: Arts and Humanities
										813 = IGETC Area 4: Social and Behavioral Sciences
										814 = IGETC Area 5: Physical and Biological Sciences (mark all that apply)
										819 = IGETC Area 6: Language other than English (101 Level only)
									*/
									where GeneralEducationId in (806,811,812,813,814,819)
								)
							) 
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from Program p
									inner join ProgramSequence ps on p.Id = ps.ProgramId
										and ps.CourseId in (
											select c2.Id
											from BaseCourse bc
												inner join Course c2 on bc.Id = c2.BaseCourseId
											where c.BaseCourseId = bc.Id
											and c2.Active = 1
										)
								where p.AwardTypeId = 1733--1733 = Associate of Arts Degree
								and p.Active = 1
								and p.StatusAliasId = 1--1 = Active
							)
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from Program p
									inner join ProgramSequence ps on p.Id = ps.ProgramId
										and ps.CourseId in (
											select c2.Id
											from BaseCourse bc
												inner join Course c2 on bc.Id = c2.BaseCourseId
											where c.BaseCourseId = bc.Id
											and c2.Active = 1
										)
								where p.AwardTypeId = 1735--1735 = Associate of Science Degree
								and p.Active = 1
								and p.StatusAliasId = 1--1 = Active
							)
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from Program p
									inner join ProgramSequence ps on p.Id = ps.ProgramId
										and ps.CourseId in (
											select c2.Id
											from BaseCourse bc
												inner join Course c2 on bc.Id = c2.BaseCourseId
											where c.BaseCourseId = bc.Id
											and c2.Active = 1
										)
								/*
									1739 = Associate in Arts (AA-T) Degree for Transfer
									1740 = Associate in Science (AS-T) Degree for Transfer
								*/
								where p.AwardTypeId in (1739,1740)
								and p.Active = 1
								and p.StatusAliasId = 1
									 ) 
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from Program p
									inner join ProgramSequence ps on p.Id = ps.ProgramId
										and ps.CourseId in (
											select c2.Id
											from BaseCourse bc
												inner join Course c2 on bc.Id = c2.BaseCourseId
											where c.BaseCourseId = bc.Id
											and c2.Active = 1
										)
								where p.AwardTypeId = 1730--1730 = Certificate of Achievement
								and p.Active = 1
								and p.StatusAliasId = 1--1 = Active
									 ) 
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from Program p
									inner join ProgramSequence ps on p.Id = ps.ProgramId
										and ps.CourseId in (
											select c2.Id
											from BaseCourse bc
												inner join Course c2 on bc.Id = c2.BaseCourseId
											where c.BaseCourseId = bc.Id
											and c2.Active = 1
										)
								where p.AwardTypeId = 1737--1737 = Certificate of Completion
								and p.Active = 1
								and p.StatusAliasId = 1--1 = Active
									 ) 
								then ''X''
							else ''''
						end,
					''</td>'',
					''<td class="tg-73oq">'',
						case
							when exists (
								select *
								from Program p
									inner join ProgramSequence ps on p.Id = ps.ProgramId
										and ps.CourseId in (
											select c2.Id
											from BaseCourse bc
												inner join Course c2 on bc.Id = c2.BaseCourseId
											where c.BaseCourseId = bc.Id
											and c2.Active = 1
										)
								where p.AwardTypeId = 1738--1738 = Certificate
								and p.Active = 1
								and p.StatusAliasId = 1--1 = Active
									 ) 
								then ''X''
							else ''''
						end,
					''</td>'',
				''</tr>''
			)
		from Course c
			inner join [Subject] s on c.SubjectId = s.Id	
		where c.Active = 1 
		and c.StatusAliasId = 1--1 = Active
		and c.SubjectId in (
			select Reference_SubjectId
			from ModuleRelatedModule01
			where ModuleId = @entityId
		)
		ORDER BY dbo.fnCourseNumberToNumeric(c.CourseNumber), c.CourseNumber;

		select 
			concat(
				''<style type="text/css">
				.tg  {border-collapse:collapse;border-spacing:0;}
				.tg td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
				  overflow:hidden;padding:10px 5px;word-break:normal;}
				.tg th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
				  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
				.tg .tg-te0j{background-color:#c0c0c0;border-color:#000000;font-weight:bold;text-align:center;vertical-align:middle}
				.tg .tg-73oq{border-color:#000000;text-align:left;vertical-align:top}
				</style>
				<table class="tg">
				<tbody>
				  <tr>
					<th class="tg-te0j" rowspan="2">Prefix &amp; Number</th>
					<th class="tg-te0j" rowspan="2">Title</th>
					<th class="tg-te0j" colspan="2">Transfer</th>
					<th class="tg-te0j" colspan="3">GE</th>
					<th class="tg-te0j" colspan="6">Course Satisfies Requirements for:</th>
				  </tr>
				  <tr>
					<th class="tg-te0j">CSU</th>
					<th class="tg-te0j">UC &amp; CSU</th>
					<th class="tg-te0j">Local</th>
					<th class="tg-te0j">CSU-GE</th>
					<th class="tg-te0j">IGETC</th>
					<th class="tg-te0j">AA</th>
					<th class="tg-te0j">AS</th>
					<th class="tg-te0j">AA-T or AS-T</th>
					<th class="tg-te0j">CA</th>
					<th class="tg-te0j">CC</th>
					<th class="tg-te0j">C</th>
				  </tr>'',
				dbo.ConcatWithSepOrdered_Agg('''',ident, row),
				''</tbody>
				</table>''
			) as [Text], 0 as [Value]
		 from @rows;
	
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 149

UPDATE ListItemType 
SET Title = 'Year'
WHERE Id = 18

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select Distinct templateId FROM @Fields
UNION
SELECT mss.MetaTemplateId fROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 149
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback