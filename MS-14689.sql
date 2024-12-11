USE butte;

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14689';
DECLARE @Comments nvarchar(Max) = 
	'Add edit map to fields ';
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
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
('Course Materials', 'CourseYesNo', 'YesNo02Id','Update'),
('Course Materials', 'GenericMaxText', 'TextMax04','Update'),
('Course Materials', 'GenericOrderedList03', 'MaxText01','Update'),
('Course Materials', 'CourseTextbook', 'Author','Update'),
('Course Materials', 'CourseTextbook', 'Title','Update'),
('Course Materials', 'CourseTextbook', 'Edition','Update'),
('Course Materials', 'CourseTextbook', 'Publisher','Update'),
('Course Materials', 'CourseTextbook', 'IsbnNum','Update'),
('Course Materials', 'CourseTextbook', 'CalendarYear','Update'),
('Course Materials', 'CourseTextbook', 'Cost','Update'),
('Course Materials', 'CourseTextbook', 'Other','Update'),
('Course Materials', 'CourseTextbook', 'IsTextbookFiveYear','Update'),
('Course Materials', 'CourseManual', 'Author','Update'),
('Course Materials', 'CourseManual', 'Title','Update'),
('Course Materials', 'CourseManual', 'Text25501','Update'),
('Course Materials', 'CourseManual', 'Description','Update'),
('Course Materials', 'CourseManual', 'Publisher','Update'),
('Course Materials', 'CourseManual', 'CalendarYear','Update'),
('Course Materials', 'CourseManual', 'Other','Update'),
('Course Materials', 'CourseManual', 'Required','Update'),
('Course Materials', 'CourseSoftware', 'Title','Update'),
('Course Materials', 'CourseSoftware', 'Edition','Update'),
('Course Materials', 'CourseSoftware', 'Publisher','Update'),
('Course Materials', 'CourseSoftware', 'Description','Update'),
('Course Materials', 'CourseSoftware', 'Required','Update'),
('Course Materials', 'CourseTextOther', 'TextOther','Update')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
INSERT INTO EditMap  
	DEFAULT VALUES 

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO EditMapStatus
(EditMapId, StatusAliasId, PositionId)
VALUES
(@ID, 1, 5),
(@ID, 2, 5),
(@ID, 3, 5),
(@ID, 6, 5),
(@ID, 4, 5)

UPDATE MetaSelectedField
SET EditMapId = @ID
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields
)

UPDATE MetaSelectedSection
SET EditMapId = @ID
WHERE MetaSelectedSectionId in (
SELECT DISTINCT SectionId FROM @Fields
)

DELETE FROM UserRole WHERE UserId = 894 and RoleId = 3
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback