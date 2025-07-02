USE [hkapa];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18900';
DECLARE @Comments nvarchar(Max) = 
	'Update Sections of OL to query in the CSD report';
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
    AND mtt.IsPresentationView = 1	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (14)		--comment back in if just doing some of the mtt's

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
('NULL', 'CourseOutcome', 'OutcomeText','1'),
('NULL', 'CourseObjective', 'Text','2')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 2;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed
DECLARE @MAX2 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
SELECT 0 AS Value,
CONCAT('<ol style=""list-style-type: none;""><li>', dbo.ConcatWithSepOrdered_Agg('<li>', co.SortOrder, co.OutcomeText), '</ol>') AS Text
FROM Course AS c
INNER JOIN CourseOutcome AS co on co.CourseId = c.Id
WHERE c.Id = @EntityId
"

DECLARE @SQL2 NVARCHAR(MAX) = "
SELECT 0 AS Value,
CONCAT('<ol style=""list-style-type: none;""><li>', dbo.ConcatWithSepOrdered_Agg('<li>', co.SortOrder, co.Text), '</ol>') AS Text
FROM Course AS c
INNER JOIN CourseObjective AS co on co.CourseId = c.Id
WHERE c.Id = @EntityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseOutcome', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Query for report so it doesn''t number them', 2),
(@MAX2, 'CourseObjective', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'Query for report so it doesn''t number them', 2)

UPDATE MetaSelectedSection
SET MetaBaseSchemaId = NULL
, MetaSectionTypeId = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, DefaultDisplayType = 'QueryText'
, LabelVisible = 0
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = 
CASE 
	WHEN f.Action = '1' THEN @MAX
	WHEN f.Action = '2' THEN @MAX2
ELSE NULL
END
, MetaAvailableFieldId = 
CASE
	WHEN f.Action = '1' THEN 8905
	WHEN f.Action = '2' THEN 8906
ELSE NULL
END
FROM MetaSelectedField AS msf
INNER JOIN @Fields AS f on msf.MetaSelectedFieldId = f.FieldId
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback