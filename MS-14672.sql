USE [victorvalley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14672';
DECLARE @Comments nvarchar(Max) = 
	'Finish update and move to live
	MS-13757update cor to show all fields that are empty justin palmer';
DECLARE @Developer nvarchar(50) = 'Nate W';
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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
DEclare @clientId int =1,
	@Entitytypeid int =1;

declare @templateId integers

insert into @templateId
select mt.MetaTemplateId
from MetaTemplateType mtt
inner join MetaTemplate mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
where mtt.EntityTypeId = @Entitytypeid
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate is NULL
and mtt.active = 1
and mtt.IsPresentationView = 1
and mtt.ClientId = @clientId
and mtt.TemplateName = 'Course Outline'

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('23. Correspondence Education Addendum', 'GenericBit', 'Bit04','find'),
('23. Correspondence Education Addendum', 'Generic1000Text', 'Text100001','update'),
('23. Correspondence Education Addendum', 'Generic1000Text', 'Text100002','update'),
('23. Correspondence Education Addendum', 'Generic1000Text', 'Text100003','update'),
('23. Correspondence Education Addendum', 'Generic1000Text', 'Text100004','update'),
('23. Correspondence Education Addendum', 'Generic1000Text', 'Text100005','update')

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
DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId in (
SELECT FieldId from @Fields
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT Distinct SectionId fROM @Fields WHERE Action = 'update'
)

update MetaReport
set ReportAttributes = '{"isPublicReport":true,"reportTemplateId":36}'
WHERE ID = 270

update MetaSelectedField
set MetaAvailableFieldId = 2628
WHERE MetaSelectedFieldId in (SELECT fieldid FROM @Fields Where Action = 'find')
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2


--commit
--rollback