USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13635';
DECLARE @Comments nvarchar(Max) = 
	'Add Information to Instructional Program Review';
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
	AND mtt.MetaTemplateTypeId = 18		--hard code type


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
('III. Students and Student Success', 'ModuleExtension01', 'TextMax05','Update')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
Update MetaSelectedSection
SET SectionDescription = 'The purpose of this section is to encourage programs to reflect on their contribution to the College’s strategic goals of increasing enrollment of marginalized groups, first-year completion of both transfer level math and English, and increasing fall to fall persistence. <br>
<style>
	.demo {
		border:1px solid #C0C0C0;
		border-collapse:collapse;
		padding:5px;
	}
	.demo th {
		border:1px solid #C0C0C0;
		padding:5px;
		background:#a3a3a3;
	}
	.demo td {
		border:1px solid #C0C0C0;
		padding:5px;
	}
</style>
<table class="demo">
	<thead>
		<tr>
			<th>Student Population</th>
			<th>Student Population</th>
			<th>Metrics</th>
			<th>Metrics<br></th>
			<th>Metrics</th>
			<th>Metrics</th>
			<th>Metrics</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>Student Population</td>
			<td>Student Population</td>
			<td>Successful Enrollment</td>
			<td>Completed Transfer-Level Math & English</td>
			<td>Persistence: 1ST Primary Term to 2ND Primary Term</td>
			<td>Transfer</td>
			<td>Completion</td>
		</tr>
		<tr>
			<td>America Indian or Alaska Native</td>
			<td>All</td>
			<td>X</td>
			<td></td>
			<td></td>
			<td></td>
			<td></td>
		</tr>
		<tr>
			<td>Black or African American</td>
			<td>All</td>
			<td>X</td>
			<td>X</td>
			<td>X</td>
			<td>X</td>
			<td></td>
		</tr>
		<tr>
			<td>Hispanic or Latinx</td>
			<td>Female</td>
			<td></td>
			<td>X</td>
			<td></td>
			<td>X</td>
			<td></td>
		</tr>
		<tr>
			<td>Hispanic or Latinx</td>
			<td>Male</td>
			<td></td>
			<td></td>
			<td>X</td>
			<td></td>
			<td>X</td>
		</tr>
		<tr>
			<td>Asian</td>
			<td>Female</td>
			<td>X</td>
			<td></td>
			<td></td>
			<td></td>
			<td></td>
		</tr>
		<tr>
			<td>Asian</td>
			<td>Male</td>
			<td></td>
			<td></td>
			<td></td>
			<td></td>
			<td>X</td>
		</tr>
		<tr>
			<td>LGBT</td>
			<td>All</td>
			<td></td>
			<td>X</td>
			<td>X</td>
			<td></td>
			<td></td>
		</tr>
	</tbody>
</table>
'
WHERE MetaSelectedSectionId in (SELECT SectionId FROM @Fields)

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback