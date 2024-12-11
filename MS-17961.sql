USE [laspositas];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17961';
DECLARE @Comments nvarchar(Max) = 
	'Fix show hide for the Narrative Tab';
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
	@Entitytypeid int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
		AND mtt.MetaTemplateTypeId in (15, 16, 18, 23)		--comment back in if just doing some of the mtt's

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
('Cover', 'Program', 'ProgramTypeId','Trigger'),
('Narrative', 'ProgramDetail', 'SimilarPrograms','Career'),
('Narrative', 'Program', 'EmployerSurvey','Master'),
('Narrative', 'ProgramDetail', 'MasterPlanning','Enrollment'),
('Narrative', 'Program', 'ChangeRequest','Place'),
('Narrative', 'Program', 'SamplePrograms','Similar'),
('Narrative', 'ProgramYesNo', 'YesNo06Id','This'),
('Narrative', 'GenericMaxText', 'TextMax12','Explain')

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
DELETE FROM MetaDisplaySubscriber WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields
)

DECLARE @SHOWHIDE TABLE (TempId int, TrigId int, ListId int, ordinal NVARCHAR(MAX))
INSERT INTO @SHOWHIDE
SELECT f.TemplateId, f.FieldId, f2.FieldId, '"1,3,4,5,6,7"' FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
wHERE F.Action = 'Trigger'
and f2.Action = 'Career'
UNION
SELECT f.TemplateId, f.FieldId, f2.FieldId, '"1"' FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
wHERE F.Action = 'Trigger'
and f2.Action = 'Master'
UNION
SELECT f.TemplateId, f.FieldId, f2.FieldId, '"1,4,5,6,7"' FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
wHERE F.Action = 'Trigger'
and f2.Action = 'Enrollment'
UNION
SELECT f.TemplateId, f.FieldId, f2.FieldId, '"1,4,5,6,7"' FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
wHERE F.Action = 'Trigger'
and f2.Action = 'Place'
UNION
SELECT f.TemplateId, f.FieldId, f2.FieldId, '"1,2,4,5,6,7"' FROM @Fields AS f --3
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
wHERE F.Action = 'Trigger'
and f2.Action = 'Similar'
UNION
SELECT f.TemplateId, f.FieldId, f2.FieldId, '"1,3,4,5,6,7"' FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
wHERE F.Action = 'Trigger'
and f2.Action = 'This'
UNION
SELECT f.TemplateId, f.FieldId, f2.FieldId, '"1"' FROM @Fields AS f --2
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
wHERE F.Action = 'This'
and f2.Action = 'Explain'

while exists(select top 1 1 from @SHOWHIDE)
begin
    declare @TID int = (select top 1 TempId from @SHOWHIDE)
		DECLARE @Trigger int = (SELECT top 1 TrigId FROM @SHOWHIDE WHERE TempId = @TID)
		DECLARE @list int = (SELECT Top 1 listId FROM @SHOWHIDE WHERE TempId = @TID and TrigId = @Trigger)
		DECLARE @Rule NVARCHAR(MAX) = (SELECT Top 1 ordinal FROM @SHOWHIDE WHERE TempId = @TID and TrigId = @Trigger and ListId = @list)

		exec upAddShowHideRule @Trigger, null, 2, 18, 3, @Rule, null, @list, null, 'Show or Hide Based on goal', 'Show or Hide Based on goal'

    delete @SHOWHIDE
		WHERE TempId = @TID and TrigId = @Trigger and ListId = @list and @Rule = ordinal
end
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback