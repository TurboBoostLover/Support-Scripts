USE [riohondo];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-11341';
DECLARE @Comments nvarchar(Max) = 
	'Adding New Program Summary Report';
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
DECLARE @reportId int = 376
DECLARE @reportTitle nvarchar(max) = 'Program Summary'
DECLARE @newMT int = 838
DECLARE @EntityTypeId int = 2
DECLARE @ReportType int = 13

DECLARE @reportattribute nvarchar(max) = concat('{"reportTemplateId":',@newMT,'}')

INSERT INTO MetaReport
	(Id, Title, MetaReportTypeId, OutputFormatId, ReportAttributes)
VALUES
	(@reportId, @reportTitle, @ReportType, 5, @reportattribute)

INSERT INTO MetaReportTemplateType
	(MetaReportId, MetaTemplateTypeId, StartDate)
SELECT
	@reportId,
	mtt.MetaTemplateTypeId,
	GETDATE()
FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = @EntityTypeId
AND mt.Active = 1
AND mt.IsDraft = 0
AND mtt.Active = 1
AND mtt.IsPresentationView = 0

DECLARE @newId int = (SELECT max(id) + 1 from MetaReportActionType)

INSERT INTO MetaReportActionType
	(Id, MetaReportId, ProcessActionTypeId)
VALUES
	(@newId, @reportId, 1),
	(@newId + 1, @reportId, 2),
	(@newId + 2, @reportId, 3)

--------------------------------------------------------------------

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
('Program Sequencing', 'ProgramYesNo', 'YesNo02Id','Remove'),
('Program Sequencing', 'ProgramYesNo', 'YesNo01Id','Update')

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
where mt.MetaTemplateId  = @newMT
/***************************************************************************************************************/
----------------------------------------------------------------------------------------------------------------
DELETE FROM MetaReportTemplateType
WHERE MetaReportId = 86 --OLD Report

DECLARE @maxId int = (SELECT max(Id) from MetaForeignKeyCriteriaClient)
DECLARE @csmSql nvarchar(max) = 'exec upGenerateCourseBlockDisplay @entityId = @entityId'

DELETE FROM MetaSelectedField
	WHERE MetaSelectedFieldId IN (SELECT FieldId FROM @Fields WHERE Action = 'Remove')

Insert INTO MetaForeignKeyCriteriaClient
	(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, Title, LookupLoadTimingType)
VALUES
	(@maxId + 1, 'Program', 'Id', 'Title', @csmSql, @csmSql, 'Program Course Blocks', 2)

UPDATE MetaSelectedField
SET DefaultDisplayType = 'QueryText', 
FieldTypeId = 5, 
MetaPresentationTypeId = 103, 
MetaForeignKeyLookupSourceId = @maxId + 1, 
DisplayName = 'Course Blocks', 
LabelVisible = 0,
MetaAvailableFieldId = 9102
	WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Update')

/****************************************************************************************************************/
UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = @newMT