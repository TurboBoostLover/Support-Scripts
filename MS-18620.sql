use [stpetersburg]
/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18223';
DECLARE @Comments nvarchar(Max) = 
	'Maverick Conversion Clean up';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
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
If exists(select top 1 1 from [User] WHERE LastName IS NULL and Active = 1)
	THROW 51000, 'User Last Name Required in Maverick and needs fixed', 1;

DECLARE @ClientId int = (SELECT Id FROM Client WHERE Active = 1)
DECLARE @Active int = (SELECT Id FROM StatusAlias WHERE Title = 'Active')
DECLARE @ShowHideFix bit = 0;
DECLARE @RTEListItemTitle bit = 0;

Merge MetaSelectedFieldAttribute as Target 
	using 
		(
			select 'helptext' as Name, msfa1.Value, msfa1.MetaSelectedFieldId  
	from MetaSelectedFieldAttribute msfa1
	where Name = 'subtext'
	And Not Exists 
	(
	select msfa2.MetaSelectedFieldId 
	from MetaSelectedFieldAttribute msfa2
	where Name = 'HelpText'
		And msfa2.MetaSelectedFieldId
		= msfa1.MetaSelectedFieldId 
	)
) as Source (Name,Value, MetaSelectedFieldId)
	On source.Name = Target.Name
	And source.Value = Target.Value
	And source.MetaSelectedFieldId = Target.MetaSelectedFieldId
When not matched then 
INSERT  (Name,Value, MetaSelectedFieldId)
values  (source.Name,source.Value, source.MetaSelectedFieldId);

UPDATE MetaSelectedField
SET IsRequired = 0
WHERE MetaSelectedFieldId in (
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE 
(MetaPresentationTypeId = 5
or 
(MetaPresentationTypeId = 1 and FieldTypeId = 5)
or MetaPresentationTypeId = 103)
AND IsRequired = 1
)

UPDATE msf
SET DisplayName = dbo.Format_RemoveAccents(dbo.stripHtml(DisplayName))
from MetaSelectedField msf
    inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
    inner join MetaSelectedSection mss2 on mss2.MetaSelectedSectionId = mss.MetaSelectedSection_MetaSelectedSectionId
    inner join MetaTemplate mt on mt.MetaTemplateId = mss.MetaTemplateId
    inner join MetaTemplateType mtt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    inner join EntityType et on et.Id = mtt.EntityTypeId
where msf.DisplayName <> dbo.Format_RemoveAccents(dbo.stripHtml(msf.DisplayName))
	and msf.MetaAvailableFieldId is not null
	and mtt.IsPresentationView = 0
	and mt.Active = 1
	and mtt.Active = 1

UPDATE mss
SET SectionName = dbo.Format_RemoveAccents(dbo.stripHtml(mss.SectionName))
from MetaSelectedSection mss
    inner join MetaTemplate mt on mt.MetaTemplateId = mss.MetaTemplateId
    inner join MetaTemplateType mtt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    inner join EntityType et on et.Id = mtt.EntityTypeId
where mss.SectionName <> dbo.Format_RemoveAccents(dbo.stripHtml(mss.SectionName))
	and mtt.IsPresentationView = 0
	and mt.Active = 1
	and mtt.Active = 1

UPDATE MetaTemplateType
SET Active = 0
WHERE MetaTemplateTypeId not in (
	SELECT MetaTemplateTypeId FROM ProposalType
)
and IsPresentationView = 0

DELETE FROM MetaSelectedSectionSetting
WHERE IsRequired = 0

DECLARE @table nvarchar(100) = 'moduleextension02',               -- Enter the Name of the Table
		@EntityTypeId int = 6;                                    -- EntityTypeId 1 = Course, 2 = Program, 6 = Module


DECLARE @ModuleOPEN INTEGERS
INSERT INTO @ModuleOPEN
SELECT 
		maf.MetaAvailableFieldId
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
LEFT JOIN MetaAvailableField maf 
	ON o.Name = maf.TableName
	AND c.Name = maf.ColumnName
left join MetaAvailableGroup mag on mag.id = maf.MetaAvailableGroupId
WHERE o.name = @table
AND t.Name <> 'sysname'
AND t.Name = 'decimal'
and MetaAvailableFieldId is not null
AND NOT EXISTS (SELECT 1
					FROM MetaSelectedField msf
						INNER JOIN MetaSelectedSection mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					WHERE msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					AND mss.MetaTemplateId in (select mt.MetaTemplateId
												from MetaTemplate mt
												inner join MetaTemplateType mtt on mt.metaTemplateTypeId = mtt.metaTemplateTypeId
												where
												mt.startDate is not NULL
												and mt.DeletedDate is NULL
												and mt.enddate is null
												and mt.active = 1
												and Mtt.entityTypeId = @EntityTypeId
												and mtt.active = 1
												)
												 )

DECLARE @OldCalc TABLE (FieldId int, EntityTypeId int, nam NVARCHAR(MAX))
INSERT INTO @OldCalc
SELECT 
	msf.MetaSelectedFieldId,
	mtt.EntityTypeId,
	msf.DisplayName
FROM MetaSelectedField msf
	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
WHERE MetaAvailableFieldId is null
	and exists (
		SELECT 1 FROM MetaFieldFormula mff 
		where mff.MetaSelectedFieldId = msf.MetaSelectedFieldId
	)
	and (mt.MetaTemplateId in (
	SELECT MetaTemplateId FROM Course
	UNION
	SELECT MetaTemplateId FROM Program
	UNION
	SELECT MetaTemplateId FROM Module
	)
	or mt.Active = 1)

while exists(select top 1 FieldId from @OldCalc WHERE EntityTypeId = 6)
begin
		declare @Id int = (SELECT TOP 1 FieldId FROM @OldCalc WHERE EntityTypeId = 6)
    declare @TID int = (select top 1 Id from @ModuleOPEN)
		declare @nam NVARCHAR(MAX) = (SELECT nam FROM @OldCalc WHERE FieldId = @Id)

		UPDATE MetaSelectedField
		SET MetaAvailableFieldId = @TID
		, MetaPresentationTypeId = 1
		, Height = 24
		, FieldTypeId = 1
		, ReadOnly = 1
		WHERE MetaSelectedFieldId = @Id
		or
		(
		DisplayName = @nam
		and MetaSelectedFieldId in (
			SELECT FieldId FROM @OldCalc
		)
		)

    delete @OldCalc
		WHERE FieldId = @Id
				or
		(
		nam = @nam
		and EntityTypeId = 6
		)
		delete @ModuleOPEN
		WHERE Id = @TID
end

SET @Table = 'CourseDescription'
SET @EntityTypeId = 1

DECLARE @CourseOPEN INTEGERS
INSERT INTO @CourseOPEN
SELECT 
		maf.MetaAvailableFieldId
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
LEFT JOIN MetaAvailableField maf 
	ON o.Name = maf.TableName
	AND c.Name = maf.ColumnName
left join MetaAvailableGroup mag on mag.id = maf.MetaAvailableGroupId
WHERE o.name = @table
AND t.Name <> 'sysname'
AND t.Name = 'decimal'
and MetaAvailableFieldId is not null
AND NOT EXISTS (SELECT 1
					FROM MetaSelectedField msf
						INNER JOIN MetaSelectedSection mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					WHERE msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					AND mss.MetaTemplateId in (select mt.MetaTemplateId
												from MetaTemplate mt
												inner join MetaTemplateType mtt on mt.metaTemplateTypeId = mtt.metaTemplateTypeId
												where
												mt.startDate is not NULL
												and mt.DeletedDate is NULL
												and mt.enddate is null
												and mt.active = 1
												and Mtt.entityTypeId = @EntityTypeId
												and mtt.active = 1
												)
												 )

while exists(select top 1 FieldId from @OldCalc WHERE EntityTypeId = 1)
begin
		declare @Id2 int = (SELECT TOP 1 FieldId FROM @OldCalc WHERE EntityTypeId = 1)
    declare @TID2 int = (select top 1 Id from @CourseOPEN)
		declare @nam2 NVARCHAR(MAX) = (SELECT nam FROM @OldCalc WHERE FieldId = @Id2)

		UPDATE MetaSelectedField
		SET MetaAvailableFieldId = @TID2
		, MetaPresentationTypeId = 1
		, Height = 24
		, FieldTypeId = 1
		, ReadOnly = 1
		WHERE MetaSelectedFieldId = @Id2
				or
		(
		DisplayName = @nam2
		and MetaSelectedFieldId in (
			SELECT FieldId FROM @OldCalc
		)
		)

    delete @OldCalc
		WHERE FieldId = @Id2
				or
		(
		nam = @nam2
		and EntityTypeId = 1
		)
		delete @CourseOPEN
		WHERE Id = @TID2
end

SET @Table = 'GenericDecimal'
SET @EntityTypeId = 2

DECLARE @ProgramOPEN INTEGERS
INSERT INTO @ProgramOPEN
SELECT 
		maf.MetaAvailableFieldId
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
LEFT JOIN MetaAvailableField maf 
	ON o.Name = maf.TableName
	AND c.Name = maf.ColumnName
left join MetaAvailableGroup mag on mag.id = maf.MetaAvailableGroupId
WHERE o.name = @table
AND t.Name <> 'sysname'
AND t.Name = 'decimal'
and MetaAvailableFieldId is not null
AND NOT EXISTS (SELECT 1
					FROM MetaSelectedField msf
						INNER JOIN MetaSelectedSection mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					WHERE msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					AND mss.MetaTemplateId in (select mt.MetaTemplateId
												from MetaTemplate mt
												inner join MetaTemplateType mtt on mt.metaTemplateTypeId = mtt.metaTemplateTypeId
												where
												mt.startDate is not NULL
												and mt.DeletedDate is NULL
												and mt.enddate is null
												and mt.active = 1
												and Mtt.entityTypeId = @EntityTypeId
												and mtt.active = 1
												)
												 )

while exists(select top 1 FieldId from @OldCalc WHERE EntityTypeId = 2)
begin
		declare @Id3 int = (SELECT TOP 1 FieldId FROM @OldCalc WHERE EntityTypeId = 2)
    declare @TID3 int = (select top 1 Id from @ProgramOPEN)
		declare @nam3 NVARCHAR(MAX) = (SELECT nam FROM @OldCalc WHERE FieldId = @Id3)

		UPDATE MetaSelectedField
		SET MetaAvailableFieldId = @TID3
		, MetaPresentationTypeId = 1
		, Height = 24
		, FieldTypeId = 1
		, ReadOnly = 1
		WHERE MetaSelectedFieldId = @Id3
						or
		(
		DisplayName = @nam3
		and MetaSelectedFieldId in (
			SELECT FieldId FROM @OldCalc
		)
		)

    delete @OldCalc
		WHERE FieldId = @Id3
						or
		(
		nam = @nam3
		and EntityTypeId = 2
		)
		delete @ProgramOPEN
		WHERE Id = @TID3
end

DELETE FROM MetaSelectedField WHERE (LEN(DisplayName) < 1 or DisplayName IS NULL) and MetaAvailableFieldId IS NULL

CREATE TABLE #EmptySections (MetaSelectedSectionId INT);

INSERT INTO #EmptySections
SELECT MetaSelectedSectionId 
FROM MetaSelectedSection
WHERE MetaSelectedSectionId NOT IN (
    SELECT MetaSelectedSection_MetaSelectedSectionId 
    FROM MetaSelectedSection
    WHERE MetaSelectedSection_MetaSelectedSectionId IS NOT NULL
    UNION
    SELECT MetaSelectedSectionId 
    FROM MetaSelectedField
);

DELETE CSS
FROM CourseSectionSummary CSS
JOIN #EmptySections ES ON CSS.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE MSA
FROM MetaSelectedSectionAttribute MSA
JOIN #EmptySections ES ON MSA.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE MDS
FROM MetaDisplaySubscriber MDS
JOIN #EmptySections ES ON MDS.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE CCMS
FROM CourseContributorMetaSelectedSection CCMS
JOIN #EmptySections ES ON CCMS.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE MSRP
FROM MetaSelectedSectionRolePermission MSRP
JOIN #EmptySections ES ON MSRP.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE MS
FROM MetaSectionSummary MS
JOIN #EmptySections ES ON MS.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE MS
FROM ProgramSectionSummary MS
JOIN #EmptySections ES ON MS.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE MS
FROM ProgramContributorMetaSelectedSection MS
JOIN #EmptySections ES ON MS.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE MS
FROM MetaSelectedSectionPositionPermission MS
JOIN #EmptySections ES ON MS.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DELETE MS
FROM MetaSelectedSection MS
JOIN #EmptySections ES ON MS.MetaSelectedSectionId = ES.MetaSelectedSectionId;

DROP TABLE #EmptySections;

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
WHERE MetaPresentationTypeId = 29

DECLARE @Expression INTEGERS
INSERT INTO @Expression
SELECT ExpressionId FROM ExpressionPart WHERE Operand2Literal = '-1'

DELETE FROM MetaDisplaySubscriber WHERE MetaDisplayRuleId in (
	SELECT Id FROM MetaDisplayRule WHERE ExpressionId in (
		SELECT ID FROM @Expression
	)
)

DELETE FROM MetaDisplayRule WHERE ExpressionId in (
	SELECT ID FROM @Expression
)

DELETE FROM ExpressionPart WHERE ExpressionId in (
	SELECT Id FROM @Expression
)

DELETE FROM Expression WHERE Id in (
	SELECT Id FROM @Expression
)

DELETE FROM MetaDisplaySubscriber WHERE Id in (
	SELECT mds.Id FROM MetaDisplaySubscriber AS mds
	INNER JOIN MetaDisplayRule AS mdr on mds.MetaDisplayRuleId = mdr.Id
	INNER JOIN MetaSelectedField AS msf on mdr.MetaSelectedFieldId = msf.MetaSelectedFieldId
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaSelectedSection AS mss2 on mds.MetaSelectedSectionId = mss2.MetaSelectedSectionId
	WHERE mss.MetaTemplateId <> mss2.MetaTemplateId
)

IF @ShowHideFix = 1
BEGIN
		declare @template integers
		insert into @template
		select MetaTemplateid
		from MetaTemplate
		where 1 = 1


		-- Fix Showhide
		-- Fixing Null targeting Expresion part
		update EP
		set ExpressionOperatorTypeId = case 
			when ExpressionOperatorTypeId = 3 then 17 
			when ExpressionOperatorTypeId = 16 then 15 
			else ExpressionOperatorTypeId 
		end
		from ExpressionPart EP
			inner join MetaSelectedField MSF on Ep.Operand1_MetaSelectedFieldId = MSF.MetaSelectedFieldId
			inner join MetaSelectedSection MSS on MSF.MetaSelectedSectionId = MSS.MetaSelectedSectionId
			inner join @template T on MSS.MetaTemplateId = T.Id
		where ComparisonDataTypeId = 3
			and Operand2Literal = '-1'
		-- End Fixing Null targeting Expresion part


		-- Remove duplicate MetaDisplaySubscribers
		delete MDS
		from MetaDisplaySubscriber MDS
			inner join MetaDisplaySubscriber MDS2 on MDS.MetaSelectedSectionId = MDS2.MetaSelectedSectionId
				and MDS.Id <> MDS2.Id
				and MDS.MetaDisplayRuleId = MDS2.MetaDisplayRuleId
			inner join MetaSelectedSection MSS on MDS.MetaSelectedSectionId = MSS.MetaSelectedSectionId
			inner join @template T on MSS.MetaTemplateId = T.Id
		-- End Remove duplicate MetaDisplaySubscribers

		-- Create Subsections for MetaDisplaySubscribers
		declare @SectionFixShowhide integers

		insert into @SectionFixShowhide
		select distinct MSS.MetaSelectedSectionId
		from MetaSelectedSection MSS
			inner join @template T on T.id = MSS.MetaTemplateId
			cross apply (
				select count(MDS.id) as C 
				from MetaDisplaySubscriber MDS
				where MDS.MetaSelectedSectionId = MSS.MetaSelectedSectionId
			) C
			inner join (
				select count(MSF.MetaSelectedFieldid) as C,MetaSelectedSectionId
				from MetaSelectedField MSF
				group by MetaSelectedSectionId
			) C2 on C2.C = 1 and C2.MetaSelectedSectionId = MSS.MetaSelectedSectionId
			inner join MetaSelectedField MSF2 on MSF2.MetaSelectedSectionId = MSS.MetaSelectedSectionId
			left join MetaDisplaySubscriber MDS on MSF2.MetaSelectedFieldId = MDS.MetaSelectedFieldId
			left join MetaSelectedSection MSS2 on MSS.MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
		where (C.C > 1
			or (MSS.MetaSectionTypeId = 32 and C.C > 0))  -- AS of the writing of this script subscriptions does not work directly on checklists in new forms  If this changes the one below should also be removed
			and (MSS.SectionName is null or MSS.DisplaySectionName = 0)
			and (MSS.SectionDescription is null or MSS.DisplaySectionDescription = 0)
			and MDS.id is null
			and MSS2.MetaSelectedSectionId is null

		while exists(select*from @SectionFixShowhide)
		begin

			declare @MinMetaDisplayRuleIds integers
			insert into @MinMetaDisplayRuleIds
			select min(MetaDisplayRuleId) as id
			from MetaDisplaySubscriber 
			group by MetaSelectedSectionId

			update MDS
			set MetaSelectedFieldId = MSF.MetaSelectedFieldId,MetaSelectedSectionId = null
			from MetaSelectedSection MSS
				inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
				inner join MetaDisplaySubscriber MDS on MSS.MetaSelectedSectionId = MDS.MetaSelectedSectionId
				inner join @MinMetaDisplayRuleIds MMDR on MMDR.id = MDS.MetaDisplayRuleId
				inner join MetaSelectedField MSF on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId

			delete @SectionFixShowhide 
			where 1 = 1

		end

		insert into @SectionFixShowhide
		select MSS.MetaSelectedSectionId
		from MetaSelectedSection MSS
			inner join @template T on T.id = MSS.MetaTemplateId
			cross apply (
				select count(MDS.id) as C 
				from MetaDisplaySubscriber MDS
				where MDS.MetaSelectedSectionId = MSS.MetaSelectedSectionId
			) C
		where C.C > 1
			or (MSS.MetaSectionTypeId = 32 and C.C > 0)  -- AS of the writing of this script subscriptions does not work directly on checklists in new forms  If this changes the one below should also be removed

		declare @newsection3 integers

		while exists(select*from @SectionFixShowhide)
		begin

			insert MetaSelectedSection
			(ClientId,MetaSelectedSection_MetaSelectedSectionId,SectionName,DisplaySectionName,SectionDescription,DisplaySectionDescription,
			ColumnPosition,RowPosition,SortOrder,SectionDisplayId,MetaSectionTypeId,MetaTemplateId,DisplayFieldId,HeaderFieldId,FooterFieldId,
			OriginatorOnly,MetaBaseSchemaId,MetadataAttributeMapId,EntityListLibraryTypeId,EditMapId,AllowCopy,ReadOnly,Config)
			output inserted.MetaSelectedSectionid into @newsection3
			select
			MSS.ClientId,MSS.MetaSelectedSection_MetaSelectedSectionId,null,0,NULL,0,NULL,MSS.RowPosition,MSS.RowPosition,1,1,MSS.MetaTemplateId,NULL,NULL,NULL,0,MSS2.MetaBaseSchemaId,NULL,NULL,NULL,1,0,NULL
			from MetaSelectedSection MSS
				inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
				inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSectionId
	
			update MSS
			set MetaSelectedSection_MetaSelectedSectionId = NS.Id,RowPosition = 0,SortOrder = 0
			from MetaSelectedSection MSS
				inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
				inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
					and MSS.RowPosition = MSS2.RowPosition
				inner join @newsection3 NS on MSS2.MetaSelectedSectionId = NS.Id
	
			update MDS
			set MetaSelectedSectionId = MSS.MetaSelectedSection_MetaSelectedSectionId
			from MetaSelectedSection MSS
				inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
				cross apply (
					select min(MetaDisplayRuleId) as id
					from MetaDisplaySubscriber 
					where MetaSelectedSectionId = MSS.MetaSelectedSectionId
				) A
				inner join MetaDisplaySubscriber MDS on MSS.MetaSelectedSectionId = MDS.MetaSelectedSectionId
					and A.id = MDS.MetaDisplayRuleId

			delete @SectionFixShowhide 
			where 1 = 1

			delete @newsection3
			where 1 = 1

			insert into @SectionFixShowhide
			select MSS.MetaSelectedSectionId
			from MetaSelectedSection MSS
				inner join @template T on T.id = MSS.MetaTemplateId
				cross apply (
					select count(MDS.id) as C 
					from MetaDisplaySubscriber MDS
					where MDS.MetaSelectedSectionId = MSS.MetaSelectedSectionId
				) C
			where C.C > 1
				or (MSS.MetaSectionTypeId = 32 and C.C > 0)

		end

		DECLARE @EmptySections TABLE (Id int)
		INSERT INTO @EmptySections
		SELECT mss.MetaSelectedSectionId 
		FROM MetaSelectedSection mss
		WHERE NOT EXISTS (
				SELECT 1 
				FROM MetaSelectedField msf
				WHERE msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
				UNION
				SELECT 1
				FROM MetaSelectedSection mss2
				WHERE mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
		)

		DELETE FROM MetaSelectedSection
		WHERE MetaSelectedSectionId in (
			SELECT Id FROM @EmptySections
		)
END

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()

exec EntityExpand

--COMMIT