USE [whatcom];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16783';
DECLARE @Comments nvarchar(Max) = 
	'Update Requisite catalog view';
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
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @numberedReqs TABLE( CourseRequisiteId int, RequisiteTypeId int, MinimumGrade nvarchar(6), ReqType nvarchar(max), RequisiteTitle nvarchar(max), OtherReqTitle nvarchar(max), ConditionTitle nvarchar(max), Comments nvarchar(max), IterationOrder int, ReqCount int);
 IF EXISTS (SELECT
		1
	FROM CourseRequisite cr
	LEFT OUTER JOIN RequisiteType pcrt
		ON cr.PreCoReqTypesId = pcrt.Id
	LEFT OUTER JOIN EligibilityCriteria ec
		ON cr.EligibilityCriteriaId = ec.Id
	LEFT OUTER JOIN Condition con
		ON cr.ConditionId = con.Id
	LEFT OUTER JOIN MinimumGrade mg
		ON cr.MinimumGradeId = mg.Id
	LEFT OUTER JOIN Course c
	INNER JOIN [Subject] s
		ON c.SubjectId = s.Id
		ON cr.Requisite_CourseId = c.Id
	WHERE cr.CourseId = @entityId)
BEGIN
INSERT INTO @numberedReqs (CourseRequisiteId, RequisiteTypeId, MinimumGrade, ReqType, RequisiteTitle, OtherReqTitle, ConditionTitle, Comments, IterationOrder, ReqCount)
	SELECT
		cr.Id AS CourseRequisiteId
	   ,cr.RequisiteTypeId
	   ,mg.Code
	   ,pcrt.Title AS ReqType
	   ,s.SubjectCode + '' '' + c.CourseNumber + '' '' + COALESCE(RTRIM(c.Title), '''') AS RequisiteTitle
	   ,ec.Title AS OtherReqTitle
	   ,con.Title AS ConditionTitle
	   ,cr.CourseRequisiteComment AS Comments
	   ,ROW_NUMBER() OVER (ORDER BY cr.SortOrder) AS IterationOrder
	   ,COUNT(*) OVER () AS ReqCount
	FROM CourseRequisite cr
	LEFT OUTER JOIN RequisiteType pcrt
		ON cr.RequisiteTypeId = pcrt.Id
	LEFT OUTER JOIN EligibilityCriteria ec
		ON cr.EligibilityCriteriaId = ec.Id
	LEFT OUTER JOIN Condition con
		ON cr.ConditionId = con.Id
	LEFT OUTER JOIN MinimumGrade mg
		ON cr.MinimumGradeId = mg.Id
	LEFT OUTER JOIN Course c
	INNER JOIN [Subject] s
		ON c.SubjectId = s.Id
		ON cr.Requisite_CourseId = c.Id
	WHERE cr.CourseId = @entityId;
WITH ComposedRequisites
AS
(SELECT
		CONCAT(CASE
			WHEN nr.MinimumGrade <> ''-1'' THEN CONCAT(''Completion with a ('', nr.MinimumGrade, '') in: '')
			ELSE NULL
		END, COALESCE(nr.RequisiteTitle, ''''), '' '', COALESCE(nr.OtherReqTitle, ''''), '' '', COALESCE(nr.Comments, ''''), CASE
			WHEN nr.IterationOrder < nr.ReqCount THEN '', ''
			ELSE ''''
		END, COALESCE(nr.ConditionTitle, '' '')) AS ComposedText
	   ,nr.CourseRequisiteId
	   ,nr.RequisiteTypeId
	   ,nr.ReqType
	   ,nr.IterationOrder
	   ,nr.ReqCount
	FROM @numberedReqs nr),
CombinedRequisites
AS
(SELECT
		cr.CourseRequisiteId
	   ,cr.RequisiteTypeId
	   ,cr.ReqType
	   ,cr.IterationOrder
	   ,cr.ReqCount
	   ,CONCAT(''<div class="requisite-type-title">'', cr.ReqType, ''</div>'', ''<div class="requisite-text">'', '' '', cr.ComposedText, ''</div> '') AS CombinedText
	   ,CASE
			WHEN cr.IterationOrder = cr.ReqCount THEN 1
			ELSE 0
		END AS FinalRow
	FROM ComposedRequisites cr
	WHERE cr.IterationOrder = 1 UNION ALL SELECT
		cr.CourseRequisiteId
	   ,cr.RequisiteTypeId
	   ,cr.ReqType
	   ,cr.IterationOrder
	   ,cr.ReqCount
	   ,combo.CombinedText + CAST(CASE
			WHEN cr.RequisiteTypeId <> combo.RequisiteTypeId THEN COALESCE(''<div class="requisite-type-title">'' + cr.ReqType + '' '' + ''</div> '', '''')
			ELSE ''''
		END + COALESCE(''<div class="requisite-text">'' + '' '' + cr.ComposedText + ''</div> '', '''') AS NVARCHAR(MAX)) AS CombinedText
	   ,CASE
			WHEN cr.IterationOrder = cr.ReqCount THEN 1
			ELSE 0
		END AS FinalRow
	FROM ComposedRequisites cr
	INNER JOIN CombinedRequisites combo
		ON cr.IterationOrder = (combo.IterationOrder + 1))
SELECT
	CombinedText AS [Text]
   ,0 AS Value
FROM CombinedRequisites combo
WHERE combo.FinalRow = 1
END;
ELSE
BEGIN;
SELECT
	''<div style="padding: 10px;"></div>'' AS Text
   ,0 AS Value
END;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 96

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 96
)

UPDATE OutputTemplateClient 
SET TemplateQuery = '
----Testing

--declare @entityList integers
--insert into @entityList
--values
--(1389)



--declare @entityList_internal table (
--	InsertOrder int identity(1, 1) primary key,
--	Id int
--);

--insert into @entityList_internal (Id)
--select el.Id
--from @entityList el;


--declare @entityModels table ([Key] int, [Value] NVARCHAR(250))
--insert into @entityModels
--select
--	eli.Id, ''{}'' as Model
--from @entityList_internal eli
--order by eli.InsertOrder;






declare 
	  @hoursScale0 int = 0
	, @hoursScale1 int = 1
	, @hoursScale2 int = 2
	, @hoursScale3 int = 3
	, @truncateInsteadOfRound int = 0
;

declare 
	  @hoursDecimalFormat0 nvarchar(10) = concat(''F'', @hoursScale0)
	, @hoursDecimalFormat1 nvarchar(10) = concat(''F'', @hoursScale1)
	, @hoursDecimalFormat2 nvarchar(10) = concat(''F'', @hoursScale2)
	, @hoursDecimalFormat3 nvarchar(10) = concat(''F'', @hoursScale3)
	, @empty nvarchar(1) = ''''
	, @space nvarchar(5) = '' ''
	, @beginParen nvarchar(5) = ''(''
	, @endParen nvarchar(5) = '')''
	, @newLine nvarchar(5) = ''
	''
	, @classAttrib nvarchar(10) = ''class''
	, @titleAttrib nvarchar(10) = ''title''
	, @openComment nvarchar(10) = ''<!-- ''
	, @closeComment nvarchar(10) = '' -->''
	, @dash nvarchar(5) = ''-''
;

declare @elementTags table (
	Id int,
	ElementTitle nvarchar(255) unique nonclustered,
	ElementTag nvarchar(10)
);

insert into @elementTags (Id, ElementTitle, ElementTag)
values
(1, ''SummaryWrapper'', ''div''),
(2, ''Row'', ''div''),
(3, ''Column'', ''div''),
(4, ''DataElement'', ''span''),
(5, ''Block'', ''div''),
(6, ''Label'', ''b''),
(7, ''Spacer'', ''br''),
(8, ''BoldDataElement'', ''b''),
(9, ''SecondaryLabel'', ''u''),
(10, ''ItalicElement'',''i'')
;

declare
	--The tag name to use for the group wrappers
	@summaryWrapperTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''SummaryWrapper''
)
,
--The tag name to use for the row wrappers
@rowTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Row''
)
,
--The tag name to use for the column wrappers
@columnTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Column''
)
,
--The tag name to use for the wrappers of the individual data elements inside the columns
@dataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''DataElement''
)
,
--The tag name to use for generic layout blocks
@blockTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Block''
)
,
--The tag name to use for wrapping labels
@labelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Label''
)
,
--The tag name for elements to insert vertical blank lines between other elements
@spacerTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Spacer''
)
,
--The tag name to use for wrappers around invidual data elements that should be bolded by default
--This allows for bolding of elements w/o having to edit the CSS
@boldDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''BoldDataElement''
)
,
--The tag name for secondary labels; ones that need a different formatting than the primary labels
@secondaryLabelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''SecondaryLabel''
),
@italicDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''ItalicElement''
)
;

declare @elementClasses table (
	Id int primary key,
	ClassSetTitle nvarchar(255) unique nonclustered,
	Wrapper nvarchar(255),
	LeftColumn nvarchar(255),
	MiddleColumn nvarchar(255),
	RightColumn nvarchar(255),
	FullWidthColumn nvarchar(255),

	--Computed full class attributes
	WrapperAttrib as coalesce(''class="'' + Wrapper + ''"'', ''''),
	LeftColumnAttrib as coalesce(''class="'' + LeftColumn + ''"'', ''''),
	MiddleColumnAttrib as coalesce(''class="'' + MiddleColumn + ''"'', ''''),
	RightColumnAttrib as coalesce(''class="'' + RightColumn + ''"'', ''''),
	FullWidthColumnAttrib as coalesce(''class="'' + FullWidthColumn + ''"'', '''')
);

insert into @elementClasses (Id, ClassSetTitle, Wrapper, LeftColumn, MiddleColumn, RightColumn, FullWidthColumn)
values
(1, ''ThreeColumn'', ''row'', ''col-xs-3 col-sm-3 col-md-1 text-left left-column'', ''col-xs-6 col-sm-6 col-md-10 text-left middle-column'', ''col-xs-3 col-sm-3 col-md-1 text-right right-column'', null),
(2, ''TwoColumnShorterRight'', ''row'', ''col-xs-9 col-md-9 col-md-9 text-left left-column'', null, ''col-xs-3 col-sm-3 col-md-3 text-right right-column'', null),
(3, ''TwoColumnShortRight'', ''row'', ''col-xs-8 col-sm-8 col-md-8 text-left left-column'', null, ''col-xs-4 col-sm-4 col-md-4 text-left right-column'', null),
(4, ''FullWidthRow'', ''row'', null, null, null, ''col-xs-12 col-sm-12 col-md-12 text-left full-width-column'')
;

declare @transferType1 NVARCHAR(max) = ''Acceptable to CSU, UC or Private''
declare @transferType2 NVARCHAR(max) = ''Acceptable to CSU or Private College''

--#endregion

declare @modelRoot table 
(
	CourseId int,
	InsertOrder int identity(1, 1) primary key,
	RootData nvarchar(max)
);


insert into @modelRoot (CourseId)
	select em.[Key]
	from @entityModels em;




declare @modelRootData table
(
	--Transfer nvarchar(max),
	CourseId int primary key
	, SubjectCode nvarchar(max)
	, CourseNumber nvarchar(max)
	, CourseTitle nvarchar(max)
	, CourseCredits nvarchar(max)
	, CourseDescription nvarchar(max)
	, CourseRequisites nvarchar(max)
	, CourseDegreeRequirements nvarchar(max)
);

insert into @modelRootData (
    CourseId
	, SubjectCode
	, CourseNumber
	, CourseTitle
	, CourseDescription
	, CourseCredits
	, CourseRequisites
	, CourseDegreeRequirements
)
select
	C.id as CourseId
	, s.SubjectCode as SubjectCode
	, c.CourseNumber as CourseNumber
	, c.Title as CourseTitle
	, lTrim(rTrim(c.[Description])) as CourseDescription
	, case
			when cd.MinCreditHour is not null 
				and cd.MaxCreditHour is not null 
				and cd.MinCreditHour < cd.MaxCreditHour
				then dbo.FormatDecimal(cd.MinCreditHour, @hoursScale1, @truncateInsteadOfRound) + ''-''
				+ dbo.FormatDecimal(cd.MaxCreditHour, @hoursScale1, @truncateInsteadOfRound)
			when cd.MinCreditHour is not null
				then dbo.FormatDecimal(cd.MinCreditHour, @hoursScale1, @truncateInsteadOfRound)
			when cd.MaxCreditHour is not null
				then dbo.FormatDecimal(cd.MaxCreditHour, @hoursScale1, @truncateInsteadOfRound)
			else ''''
	end as CourseCredits
	, REQ.Text as CourseRequisites
	, concat(CDR1.Text,CDR2.Text) as CourseDegreeRequirements
from @modelRoot mr
	inner join course C on C.id = MR.CourseId
	inner join Subject S on C.SubjectId = S.id
	inner join CourseDescription CD on CD.CourseId = C.id
	outer apply (
		select dbo.stripHtml(fn.[Text]) as Text
		from (
			select c.Id as entityId
			, (select ResolutionSql
				from MetaForeignKeyCriteriaClient
				where Id = 96) as [query] --was 132
			, null as isAdmin
			, 1 as serializeRows
			, c.ClientId as client
			, null as userId
			, null as extraParams
		) p
		outer apply (
			select *
			from dbo.fnBulkResolveCustomSqlQuery(p.Query, p.serializeRows, p.entityId, p.client, p.userId, p.isAdmin, p.extraParams) q
		) fn
		where fn.QuerySuccess = 1 
		and fn.TextSuccess = 1
	) REQ
	outer apply (
		select dbo.ConcatWithSepOrdered_Agg('''',LP.ROWNUM,LP.Code) as Text
		from CourseLookup14 CLP
			inner join (select id,Code,ROW_NUMBER() OVER (ORDER by Sortorder) as ROWNUM from Lookup14) LP on CLP.Lookup14Id = LP.id
		where CLP.CourseId = C.id
	) CDR1
	outer apply (
		select dbo.ConcatWithSepOrdered_Agg('''',AType.ROWNUM,AType.Code) as Text
		from CourseAssignment CA
			inner join (select id,replace(Title,''"'','''') as Code,ROW_NUMBER() OVER (ORDER by Sortorder) as ROWNUM from AssignmentType) AType on CA.AssignmentTypeId = AType.id
		where CA.CourseId = C.id
	) CDR2



select mr.CourseId as [Value]
	-- custom-course-summary-context-wrapper
	, concat(
		dbo.fnHtmlOpenTag(@summaryWrapperTag,
			dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper'')
			),
			-- another nested wrapper
			dbo.fnHtmlOpenTag(@summaryWrapperTag, concat(
				dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
				dbo.fnHtmlAttribute(''data-course-id'', mrd.CourseId)
				)
				),
				-- Course Title row (Course subject code, number, title, credits)
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''Course-Title-Row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''Course-Subject-Code'')),
							UPPER(mrd.SubjectCode),
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						@Space,
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''Course-Number'')),
							UPPER(SUBSTRING(mrd.CourseNumber, PATINDEX(''%[^0]%'', mrd.CourseNumber+''.''), LEN(mrd.CourseNumber)) ),
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						@Space,
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''Course-Title'')),
							mrd.CourseTitle,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						@Space,
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''Course-Credits'')),
							@beginParen + mrd.CourseCredits + @endParen,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- Course Description Row (Description, Requisites, Degree Requirements)
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''Course-Description-Row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''Course-Description'')),
						mrd.CourseDescription,
						dbo.fnHtmlCloseTag(@DataElementTag),
						@space,
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''Course-Requisites'')),
						mrd.CourseRequisites,
						dbo.fnHtmlCloseTag(@DataElementTag),
						@space,
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''Course-Degree-Requirements'')),
						@beginParen + mrd.CourseDegreeRequirements + @endParen,
						dbo.fnHtmlCloseTag(@DataElementTag),
						@space,
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag),''</div>''
	) as [Text]
from @modelRoot mr
inner join @modelRootData mrd on mr.CourseId = mrd.CourseId
inner join @elementClasses ecfw on ecfw.Id = 4 --4 = FullWidthRow
inner join @elementClasses ec2C on ec2C.Id = 2 --3 = Two col
order by mr.InsertOrder;
'
WHERE Id = 2