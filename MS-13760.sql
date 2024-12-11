USE [ucdavis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13760';
DECLARE @Comments nvarchar(Max) = 
	'Update backing store';
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
   -- AND mt.EndDate IS NULL
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
('Grading', 'CourseYearTerm', 'ActualStartSemesterId','Update'),
('Grading', 'CourseYearTerm', 'ActualEndSemesterId','Update2')

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
INSERT INTO Term
(Title, SortOrder, ClientId, StartDate)
VALUES
('Summer', 1, 1, GETDATE()),
('Fall', 2, 1, GETDATE()),
('Winter', 3, 1, GETDATE()),
('Spring', 4, 1, GETDATE())

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 12544
, MetaForeignKeyLookupSourceId = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 12548
, MetaForeignKeyLookupSourceId = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

Update cp
SET TermId01 = (
    CASE 
        WHEN cyt.ActualStartSemesterId = 643
        THEN (SELECT Id FROM Term WHERE Title = 'Summer')
        WHEN cyt.ActualStartSemesterId = 644
        THEN (SELECT Id FROM Term WHERE Title = 'Fall')
        WHEN cyt.ActualStartSemesterId = 645
        THEN (SELECT Id FROM Term WHERE Title = 'Winter')
        WHEN cyt.ActualStartSemesterId = 646
        THEN (SELECT Id FROM Term WHERE Title = 'Spring')
        ELSE NULL
    END
)
, TermId02 = (
    CASE 
        WHEN cyt.ActualEndSemesterId = 643
        THEN (SELECT Id FROM Term WHERE Title = 'Summer')
        WHEN cyt.ActualEndSemesterId = 644
        THEN (SELECT Id FROM Term WHERE Title = 'Fall')
        WHEN cyt.ActualEndSemesterId = 645
        THEN (SELECT Id FROM Term WHERE Title = 'Winter')
        WHEN cyt.ActualEndSemesterId = 646
        THEN (SELECT Id FROM Term WHERE Title = 'Spring')
        ELSE NULL
    END
)
FROM CourseProposal AS cp
INNER JOIN Course AS c on cp.CourseId = c.Id
INNER JOIN CourseYearTerm AS cyt on cyt.CourseId = c.Id

UPDATE CourseYearTerm
SET ActualStartSemesterId = NULL
, ActualEndSemesterId = NULL
WHERE (ActualStartSemesterId IS NOT NULL OR ActualEndSemesterId IS NOT NULL)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback