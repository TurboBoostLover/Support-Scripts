USE [cscc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16613';
DECLARE @Comments nvarchar(Max) = 
	'update Catalog Query to look a little better and pull in all requisites';
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
--Course summary
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL2 NVARCHAR(MAX) = "
DECLARE @item_id int;
DECLARE @open_paren nvarchar(100);
DECLARE @is_concurrent bit;
DECLARE @min_grade nvarchar(12);
DECLARE @course_id int;
DECLARE @subject_code nvarchar(20);
DECLARE @course_number nvarchar(20);
DECLARE @condition_id int;
DECLARE @close_paren nvarchar(100);
DECLARE @output nvarchar(max) = '';
DECLARE @inClause int = 0;
DECLARE @curPhrase nvarchar(max) = '';
DECLARE @comment nvarchar(max);

DECLARE @consent nvarchar(200) = (SELECT RequisiteProgramText FROM CourseRequisiteJustification WHERE CourseId = @EntityId);
DECLARE @recommended nvarchar(max) = (SELECT RequisiteStandardText FROM CourseRequisiteJustification WHERE CourseId = @EntityId);

DECLARE item_cursor CURSOR FOR
SELECT
    cr.Id,
    cr.Parenthesis,
    cr.IsConcurrent,
    cr.MinimumGrade,
    cr.Requisite_CourseId,
    s.SubjectCode,
    c.CourseNumber,
    cr.ConditionId,
    cr.HealthText,
    cr.CourseRequisiteComment
FROM
    CourseRequisite cr
    LEFT JOIN Course c ON cr.Requisite_CourseId = c.Id
    LEFT JOIN Subject s ON c.SubjectId = s.Id
WHERE
    cr.CourseId = @EntityId
ORDER BY cr.SortOrder;

OPEN item_cursor;

FETCH NEXT FROM item_cursor INTO @item_id, @open_paren, @is_concurrent, @min_grade, @course_id, @subject_code, @course_number, @condition_id, @close_paren, @comment;

WHILE @@FETCH_STATUS = 0  
BEGIN;
    SET @curPhrase = '';
    
    IF (@open_paren = '(' OR @open_paren = '((')
    BEGIN;
        SET @inClause = @inClause + 1;
        SET @curPhrase = (SELECT @curPhrase + @open_paren);
    END;

    -- Add course information or comment
    IF (@subject_code IS NOT NULL AND @course_number IS NOT NULL)
    BEGIN;
        SET @curPhrase = (SELECT @curPhrase + @subject_code + ' ' + @course_number);
    END;
    ELSE IF (@comment IS NOT NULL)
    BEGIN;
        SET @curPhrase = (SELECT @curPhrase + @comment);
    END;

    IF (LEN(@min_grade) > 0)
    BEGIN;
        IF(@min_grade != 'D-')
        BEGIN;
            IF (@min_grade != 'A')
            BEGIN;
                SET @curPhrase = (SELECT @curPhrase + ' ' + UPPER(@min_grade) + ' or better');
            END;
            ELSE
            BEGIN;
                SET @curPhrase = (SELECT @curPhrase + ' ' + UPPER(@min_grade) + ' is required');
            END;
        END;
    END;

    IF (@is_concurrent = 1)
    BEGIN;
        SET @curPhrase = (SELECT @curPhrase + ' (can be concurrent)');
    END;

    IF (@close_paren = ')' OR @close_paren = '))')
    BEGIN;
        SET @inClause = CASE WHEN @inClause > 0 THEN @inClause - 1 ELSE 0 END;
        SET @curPhrase = (SELECT @curPhrase + @close_paren);
    END;

    DECLARE @condition int = @condition_id;

    FETCH NEXT FROM item_cursor INTO @item_id, @open_paren, @is_concurrent, @min_grade, @course_id, @subject_code, @course_number, @condition_id, @close_paren, @comment;

    IF (@@fetch_status = 0)
    BEGIN;
        IF (@condition = 2)
        BEGIN;
            SET @curPhrase = (SELECT @curPhrase + ' or');
        END;
				IF (@condition = 1)
        BEGIN;
            SET @curPhrase = (SELECT @curPhrase + ' and');
        END;
        ELSE
        BEGIN;
            IF (@inClause > 0)
            BEGIN;
                SET @curPhrase = (SELECT @curPhrase + ', ');
            END;
            ELSE
            BEGIN;
                SET @curPhrase = (SELECT @curPhrase + '; ');
            END;
        END;
    END;
    ELSE
    BEGIN;
        IF (@consent IS NOT NULL AND @consent != '-1' OR @recommended IS NOT NULL)
        BEGIN;
            SET @curPhrase = (SELECT @curPhrase + '; ');
        END;
    END;

    SET @output = (SELECT @output + ' ' + @curPhrase);
END;

CLOSE item_cursor;
DEALLOCATE item_cursor;

IF (@consent IS NOT NULL AND @consent != '-1')
BEGIN;
    SET @output = (SELECT @output + ' ' + @consent + '. ');
END;

IF (@recommended IS NOT NULL)
BEGIN;
    SET @output = (SELECT @output + ' ' + @recommended);
END;

SELECT @output AS [Text], @EntityId AS Value;

RETURN;
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseRequisite', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'CourseRequisite', 2)


declare @CurriculumPresentationOutputFormat integers
insert into @CurriculumPresentationOutputFormat
select id from CurriculumPresentationOutputFormat where CurriculumPresentationid = 1  -- Choose Course Summary

-- select*from CurriculumPresentation

declare @TemplateQuery nvarchar(MAX) =CONCAT(
'declare @RequisiteQueryTextMetaForeignKeyCriteriaClientid int = ',@MAX, '
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
	, @dash nvarchar(5) = ''—''
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

	@summaryWrapperTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''SummaryWrapper''
)
,

@rowTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Row''
)
,

@columnTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Column''
)
,

@dataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''DataElement''
)
,

@blockTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Block''
)
,

@labelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Label''
)
,

@spacerTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Spacer''
)
,

@boldDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''BoldDataElement''
)
,

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
	CourseId int primary key
	, SubjectCode nvarchar(max)
	, CourseNumber nvarchar(max)
	, CourseTitle nvarchar(max)
	, CourseCredits nvarchar(max)
	, CourseDescription nvarchar(max)
	, HourTypes nvarchar(max)
	, CourseRequisites nvarchar(max)
	, EffectiveSemester nvarchar(max)
	, fee nvarchar(max)
);

insert into @modelRootData (
    CourseId
	, SubjectCode
	, CourseNumber
	, CourseTitle
	, CourseDescription
	, CourseCredits
	, HourTypes
	, CourseRequisites
	, EffectiveSemester
	, fee
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
	end as CourseCredits,
	    isnull((
        select STRING_AGG(
            case 
                when cht.MinCreditHours is not null and cht.MaxCreditHours is not null and cht.MinCreditHours < cht.MaxCreditHours
                    then CONCAT(ht.Title, '': '', dbo.FormatDecimal(cht.MinCreditHours, @hoursScale1, @truncateInsteadOfRound), '' - '', dbo.FormatDecimal(cht.MaxCreditHours, @hoursScale1, @truncateInsteadOfRound))
                when cht.MinCreditHours is not null
                    then CONCAT(ht.Title, '': '', dbo.FormatDecimal(cht.MinCreditHours, @hoursScale1, @truncateInsteadOfRound))
                when cht.MaxCreditHours is not null
                    then CONCAT(ht.Title, '': '', dbo.FormatDecimal(cht.MaxCreditHours, @hoursScale1, @truncateInsteadOfRound))
                else ''''
            end, '', ''
        )
        from CourseHourType cht
        LEFT join HourType ht on ht.Id = cht.HourTypeId
        where cht.CourseId = c.Id
    ), '''') as HourTypes
	, CONCAT(''Prerequisite(s): '', REQ.Text, ''.'') as CourseRequisites
	, concat(''Effective: '',S2.Title) as EffectiveSemester
	, ISNULL(dbo.FormatDecimal(cf.CurrentFee, @hoursScale1, @truncateInsteadOfRound), '''')
from @modelRoot mr
	inner join course C on C.id = MR.CourseId
	inner join CourseProposal CP on CP.CourseId = C.id
	inner join Subject S on C.SubjectId = S.id
	inner join CourseDescription CD on CD.CourseId = C.id
	inner join Semester S2 on s2.Id = CP.SemesterId
	left join CourseFee AS cf on cf.CourseId = c.Id
	outer apply (
		select dbo.stripHtml(fn.[Text]) as Text
		from (
			select c.Id as entityId
			, (select ResolutionSql
				from MetaForeignKeyCriteriaClient
				where Id = @RequisiteQueryTextMetaForeignKeyCriteriaClientid) as [query]
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
order by dbo.fnCourseNumberToNumeric(c.CourseNumber),C.EntityTitle

select mr.CourseId as [Value]
	, concat(
		dbo.fnHtmlOpenTag(@summaryWrapperTag,
			dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper'')
			),
			dbo.fnHtmlOpenTag(@summaryWrapperTag, concat(
				dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
				dbo.fnHtmlAttribute(''data-course-id'', mrd.CourseId)
				)
				),
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-title-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-subject-code'')),
							UPPER(mrd.SubjectCode),
						dbo.fnHtmlCloseTag(@DataElementTag),
						@Space,
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-number'')),
							UPPER(SUBSTRING(mrd.CourseNumber, PATINDEX(''%[^0]%'', mrd.CourseNumber+''.''), LEN(mrd.CourseNumber)) ),
						dbo.fnHtmlCloseTag(@DataElementTag),
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-number-title-separator'')),
							@dash,
						dbo.fnHtmlCloseTag(@DataElementTag),
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-title'')),
							mrd.CourseTitle,
						dbo.fnHtmlCloseTag(@DataElementTag),
						@Space,
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-credits'')),
							@beginParen + mrd.CourseCredits + @endParen,
						dbo.fnHtmlCloseTag(@DataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-description-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-requisites'')),
						CONCAT(mrd.HourTypes, ''<br />''),
						dbo.fnHtmlCloseTag(@DataElementTag),
						@space,
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-requisites'')),
						CASE WHEN LEN(mrd.CourseRequisites) > 18
						THEN CONCAT(mrd.CourseRequisites, ''<br />'')
						ELSE ''''
						END,
						dbo.fnHtmlCloseTag(@DataElementTag),
						@space,
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-description'')),
						mrd.CourseDescription,
							CASE WHEN LEN(mrd.fee) > 0
						THEN CONCAT('' Lab Fee: $'',mrd.fee)
						ELSE ''''
						END,
						dbo.fnHtmlCloseTag(@DataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag),''</div>''
	) as [Text]
from @modelRoot mr
inner join @modelRootData mrd on mr.CourseId = mrd.CourseId
inner join @elementClasses ecfw on ecfw.Id = 4
inner join @elementClasses ec2C on ec2C.Id = 2
order by mr.InsertOrder;
')

declare @ModelQuery nvarchar(MAX) =
'declare @entityList_internal table (
	InsertOrder int identity(1, 1) primary key,
	Id int
);

insert into @entityList_internal (Id)
select el.Id
from @entityList el;


--declare @entityModels table ([Key] int, [Value] NVARCHAR(250))
--insert into @entityModels
select
	eli.Id, ''{}'' as Model
from @entityList_internal eli
order by eli.InsertOrder;'


insert into OutputModelClient
(EntityTypeId,ModelQuery,Title,Description,StartDate)
values
(1,@ModelQuery,'Course Summary','Custom course model summary',GETDATE())

declare @OutputModelClientid int = scope_identity()

insert into OutputTemplateClient
(TemplateQuery,Title,Description,StartDate)
values
(@TemplateQuery,'Course Summary','This is a custom course summary',GETDATE())

declare @OutputTemplateClientid int = scope_identity()


insert into OutputTemplateModelMappingClient
(OutputTemplateBaseId,OutputTemplateClientId,OutputModelBaseId,OutputModelClientId,Title,Description,Config)
values
(NULL,@OutputTemplateClientid,NULL,@OutputModelClientid,'Custom Course Summary','This is a Custom Course Summary',NULL)

declare @OutputTemplateModelMappingClientid int = scope_identity()

update CPOF
set OutputTemplateModelMappingClientId = @OutputTemplateModelMappingClientid,
OutputTemplateModelMappingBaseId = null
from CurriculumPresentationOutputFormat CPOF
	inner join @CurriculumPresentationOutputFormat TCPOF on CPOF.Id = TCPOF.Id