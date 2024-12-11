USE [sjcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18075';
DECLARE @Comments nvarchar(Max) = 
	'Add Attributes needed for reports to work';
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
DECLARE @Field INTEGERS

INSERT INTO MetaSelectedFieldAttribute
(Name, Value ,MetaSelectedFieldId)
output inserted.MetaSelectedFieldId INTo @Field
SELECT 'FieldSpecialization', 'UploadTextnameField', MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 930 and MetaSelectedFieldId not in (SELECT MetaSelectedFieldId FROM MetaSelectedFieldAttribute WHERE Name = 'FieldSpecialization')
UNION
SELECT 'FieldSpecialization', 'UploadFilenameField', MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 932 and MetaSelectedFieldId not in (SELECT MetaSelectedFieldId FROM MetaSelectedFieldAttribute WHERE Name = 'FieldSpecialization')
UNION
SELECT 'FieldSpecialization', 'UploadDiscnameField', MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 1373 and MetaSelectedFieldId not in (SELECT MetaSelectedFieldId FROM MetaSelectedFieldAttribute WHERE Name = 'FieldSpecialization')
UNION
SELECT 'FieldSpecialization', 'UploadMimetypeField', MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 1374 and MetaSelectedFieldId not in (SELECT MetaSelectedFieldId FROM MetaSelectedFieldAttribute WHERE Name = 'FieldSpecialization')

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Attachment Type', -- [DisplayName]
1825, -- [MetaAvailableFieldId]
MetaSelectedSectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM MetaSelectedSection
WHERE MetaSelectedSectionId in (
	SELECT MetaSelectedSectionId FROM MetaSelectedSectionAttribute WHERE Name = 'AttachmentType'
)
and MetaSelectedSectionId not in (
	SELECT MetaSelectedSectionId FROM MetaSelectedField WHERE MetaAvailableFieldId = 1825
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN @Field As f on msf.MetaSelectedFieldId = f.Id
)