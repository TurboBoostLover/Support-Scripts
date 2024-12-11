USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16438';
DECLARE @Comments nvarchar(Max) = 
	'Fix MC Catalog';
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
UPDATE OutputTemplateClient
SET TemplateQuery = '
--#region hide

declare 
	  @hoursScale0 int = 0
	, @hoursScale1 int = 1
	, @hoursScale2 int = 2
	, @hoursScale3 int = 3
;

declare 
	  @hoursDecimalFormat0 nvarchar(10) = concat(''F'', @hoursScale0)
	, @hoursDecimalFormat1 nvarchar(10) = concat(''F'', @hoursScale1)
	, @hoursDecimalFormat2 nvarchar(10) = concat(''F'', @hoursScale2)
	, @hoursDecimalFormat3 nvarchar(10) = ''###.###''
	, @empty nvarchar(1) = ''''
	, @space nvarchar(5) = '' ''
	, @newLine nvarchar(5) = ''
	''
	, @classAttrib nvarchar(10) = ''class''
	, @titleAttrib nvarchar(10) = ''title''
	, @openComment nvarchar(10) = ''<!-- ''
	, @closeComment nvarchar(10) = '' -->''
	, @styleAttribute nvarchar(5) = ''style''
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
	CourseId int primary key,
	InsertOrder int,
	RootData nvarchar(max)
);

declare @modelRootData table
(
	Transfer nvarchar(max),
	PeraltaArea nvarchar(max),
	CSUArea nvarchar(max),
	IGETCArea nvarchar(max),
	TopCode nvarchar(max),
	Department nvarchar(max),
	CourseId int primary key,
	SubjectCode nvarchar(max),
	CourseNumber nvarchar(max),
	CourseTitle nvarchar(max),
	Variable bit,
	MinUnit decimal(16, 3),
	MaxUnit decimal(16, 3),
	MinLec decimal(16, 3),
	MaxLec decimal(16, 3),
	MinLab decimal(16, 3),
	MaxLab decimal(16, 3),
    MinLearn decimal(16,3),
    MaxLearn decimal(16,3), 
    TransferType NVARCHAR(max),
    Requisite NVARCHAR(max),
    Limitation NVARCHAR(max),
    Preperation NVARCHAR(max),
    CatalogDescription nvarchar(max),
    CourseGrading nvarchar(max),
    IsRepeatable NVARCHAR(10),
    RepeatableCode NVARCHAR(500),
    TimesRepeated NVARCHAR(500),
	Suffix NVARCHAR(500),
    CID NVARCHAR(500),
	CIDStatus nvarchar(255),
	CIDNotes nvarchar(max),
    AdminRepeat NVARCHAR(max),
	CBE bit
);

declare @unitHourRanges table
(
	Id int not null identity primary key,
	CourseId int,
	UnitHourTypeId int,
	RenderedRange nvarchar(100)
);

--testing
 --declare @entityModels table ([Key] nvarchar(max), [Value] NVARCHAR(max))

 --insert into @entityModels
 --values
 --(''20581'',''[
 --    {
	--		"Transfer":"1",
	--		"PeraltaArea":"1",
	--		"CSUArea":"1",
	--		"IGETCArea":"1",
	--		"TopCode":"1",
	--		"Department":"1",
 --            "CourseId": 20581,
 --            "SubjectCode": "ARAB",
 --            "CourseNumber": "3",
 --            "CourseTitle": "INTERMEDIATE ARABIC",
 --            "Variable": false,
 --            "MinUnit": 5.000,
 --            "MaxUnit": 5.000,
 --            "MinLec": 5.000,
 --            "MaxLec": 6.000,
 --            "MinLab": 0.000,
 --            "MaxLab": 5.000,
 --            "MinLearn": 0.000,
 --            "MaxLearn": 5.000,
	--		 "TransferType": "1",
 --            "PreRequisite": "<b>Prerequisite: <\/b>ARAB 2ARAB 2 or three years of high school Arabic or three years of high school Arabic\n<br \/>",
 --            "CoRequisite": "<b>Corequisite: <\/b>ARAB 903<br \/>",
 --            "Limitation": "<b>Limitation on Enrollment: </b>This is a limitation",
 --            "Preperation": "<b>Preperation: </b>I have prepared",
 --            "CatalogDescription": "Intermediate level course focuses on fluency on reading, writing, speaking, and listening. Continues the study of Arabic culture.",
 --            "CourseGrading": "Letter Grade or Pass\/No Pass",
 --            "IsRepeatable": "Yes",
 --            "TransferType": "Acceptable to CSU, UC or Private",
 --            "RepeatableCode": "A",
 --            "TimesRepeated":"2",
	--		   "Suffix":"A",
 --            "CID": "Test",  
	--		 "AdminRepeat": "1"                    
 --        }
 --    }
 --]'')

--end testing

insert into @modelRoot (CourseId, InsertOrder, RootData)
	select em.[Key]
	   , m.InsertOrder
	   , m.RootData
	from @entityModels em
	cross apply openjson(em.[Value])
		with (
			InsertOrder int ''$.InsertOrder'',
			RootData nvarchar(max) ''$.RootData'' as json
		) m
;

insert into @modelRootData (
	[Transfer],
	PeraltaArea,
	CSUArea,
	IGETCArea,
	TopCode,
	Department,
    CourseId
    , SubjectCode
    , CourseNumber
    , CourseTitle
    , Variable
    , MinUnit
    , MaxUnit
    , MinLec
    , MaxLec
    , MinLab
    , MaxLab
    , MinLearn
    , MaxLearn
    , TransferType
    , Requisite
    , Limitation
    , Preperation
    , CatalogDescription
    , CourseGrading
    , IsRepeatable
    , RepeatableCode
    , TimesRepeated
	, Suffix
    , CID
	, CIDStatus
	, CIDNotes
    , AdminRepeat
	, CBE
)
select
	m.Transfer,
	m.PeraltaArea,
	m.CSUArea,
	m.IGETCArea,
	m.TopCode,
	m.Department,
	m.CourseId
	, case
		when m.SubjectCode is not null
			and len(m.SubjectCode) > 0
				then m.SubjectCode
		else @empty
	end as SubjectCode
	, case
		when m.CourseNumber is not null
			and len(m.CourseNumber) > 0
				then m.CourseNumber
		else @empty
	end as CourseNumber
	, case
		when m.CourseTitle is not null
			and len(m.CourseTitle) > 0
				then m.CourseTitle
		else @empty
	end as CourseTitle
	, m.Variable
	, m.MinUnit
	, m.MaxUnit
	, m.MinLec
	, m.MaxLec
	, m.MinLab
	, m.MaxLab
	, m.MinLearn
    , m.MaxLearn
    , case
        when m.TransferType is not null and len(m.TransferType) > 0
            then m.TransferType
            else @empty 
        end as TransferType
    , case
        when m.Requisite is not null and len(m.Requisite) > 0
            then m.Requisite
            else @empty
        end as Requisite
    , case
        when m.Limitation is not null and len(m.Limitation) > 0
            then m.Limitation
            else @empty
        end as Limitation
     , case
        when m.Preperation is not null and len(m.Preperation) > 0
            then m.Preperation
            else @empty
        end as Preperation
	, case
		when m.CatalogDescription is not null and len(m.CatalogDescription) > 0
            then m.CatalogDescription
		    else @empty
	end as CatalogDescription
	, case
		when m.CourseGrading is not null and len(m.CourseGrading) > 0
            then m.CourseGrading
		    else @empty
	end as CourseGrading
	, case
		when m.IsRepeatable is not null and len(m.IsRepeatable) > 0
            then m.IsRepeatable
		    else @empty
	end as IsRepeatable
	, case
		when m.RepeatableCode is not null and len(m.RepeatableCode) > 0
            then m.RepeatableCode
		    else @empty
	end as RepeatableCode
    ,case
        when m.TimesRepeated is not null and len(m.TimesRepeated) > 0
            then m.TimesRepeated
            else @empty
    end as TimesRepeated
	,case
		when m.Suffix is not null and len(m.Suffix) > 0
			then m.Suffix
			else @empty
    end
    , case
        when m.CID is not null and len(m.CID) > 0
            then m.CID
        else @empty
    end
	, case
        when m.CIDStatus is not null and len(m.CIDStatus) > 0
            then m.CIDStatus
        else @empty
    end
	, case
        when m.CIDNotes is not null and len(m.CIDNotes) > 0
            then m.CIDNotes
        else @empty
    end
   ,  case
        when m.AdminRepeat is not null and len(m.AdminRepeat) > 0
            then m.AdminRepeat
        else @empty
    end
	,CP.HasExam as  CBE
from @modelRoot mr
cross apply openjson(mr.RootData)
	with (
		Transfer nvarchar(max) ''$.Transfer'',
		PeraltaArea nvarchar(max) ''$.PeraltaArea'',
		CSUArea nvarchar(max) ''$.CSUArea'',
		IGETCArea nvarchar(max) ''$.IGETCArea'',
		TopCode nvarchar(max) ''$.TopCode'',
		Department nvarchar(max) ''$.Department'',
		CourseId int ''$.CourseId'',
		SubjectCode nvarchar(max) ''$.SubjectCode'',
		CourseNumber nvarchar(max) ''$.CourseNumber'',
		CourseTitle nvarchar(max) ''$.CourseTitle'',
		Variable bit ''$.Variable'',
		MinUnit decimal(16, 3) ''$.MinUnit'',
		MaxUnit decimal(16, 3) ''$.MaxUnit'',
		MinLec decimal(16, 3) ''$.MinLec'',
		MaxLec decimal(16, 3) ''$.MaxLec'',
		MinLab decimal(16, 3) ''$.MinLab'',
		MaxLab decimal(16, 3) ''$.MaxLab'',
        MinLearn decimal(16,3) ''$.MinLearn'',
        MaxLearn decimal(16,3) ''$.MaxLearn'',
        TransferType NVARCHAR(max) ''$.TransferType'',
        Requisite NVARCHAR(max) ''$.Requisite'',
        Limitation NVARCHAR(max) ''$.Limitation'',
        Preperation NVARCHAR(max) ''$.Preperation'',
        CatalogDescription NVARCHAR(max) ''$.CatalogDescription'',
        CourseGrading NVARCHAR(max) ''$.CourseGrading'',
        IsRepeatable NVARCHAR(10) ''$.IsRepeatable'',
        RepeatableCode NVARCHAR(10) ''$.RepeatableCode'',
        TimesRepeated NVARCHAR(10) ''$.TimesRepeated'',
		Suffix nvarchar(500) ''$.Suffix'',
        CID NVARCHAR(500) ''$.CID'',
		CIDStatus NVARCHAR(500) ''$.CIDStatus'',
		CIDNotes NVARCHAR(500) ''$.CIDNotes'',
        AdminRepeat NVARCHAR(500) ''$.AdminRepeat''
	) m
inner join CourseProposal CP on MR.CourseId = CP.CourseId


insert into @unitHourRanges (CourseId, UnitHourTypeId, RenderedRange)
select mrd.CourseId, uht.UnitHourTypeId, uhr.RenderedRange
from @modelRootData mrd
cross apply (
	select 1 as UnitHourTypeId -- units
		, mrd.MinUnit as MinVal
		, case when isnull(mrd.MaxUnit,0) = 0 then mrd.MinUnit else mrd.MaxUnit end as MaxVal
		, 1 as RenderIfZero
		, 0 as ForceRange
		, mrd.Variable
		, 3 as FormatType
		, 1 as Render
	union all
	select 2 as UnitHourTypeId -- lec
		, mrd.MinLec as MinVal
		, case when isnull(mrd.MaxLec,0) = 0 then mrd.MinLec else mrd.MaxLec end as MaxVal
		, 0 as RenderIfZero
		, 0 as ForceRange
		, mrd.Variable
		, 3 as FormatType
		, 1 as Render
	union all
	select 3 as UnitHourTypeId -- lab
		, mrd.MinLab as MinVal
		, case when isnull(mrd.MaxLab,0) = 0 then mrd.MinLab else mrd.MaxLab end as MaxVal
		, 0 as RenderIfZero
		, 0 as ForceRange
		, mrd.Variable
		, 3 as FormatType
        , 1 as Render
    union all
    select 4 as UnitHourTypeId --learn
        ,mrd.MinLearn as MinVal
        , case when isnull(mrd.MaxLearn,0) = 0 then mrd.MinLearn else mrd.MaxLearn end as MaxVal
        , 0 as RenderIfZero
        , 0 as ForceRange
        , mrd.Variable
        , 3 as FormatType
        , 1 as Render

) uht
cross apply (
	select
		case
			when uht.Render = 1
				and (
						(
							uht.Variable = 1
							and uht.MinVal is not null
							and uht.MaxVal is not null
							and uht.MinVal != uht.MaxVal
						)
						or (
							uht.ForceRange = 1
						)
					) then concat(
						case when uht.MinVal <> 0 then format(uht.MinVal,
							case
								when uht.FormatType = 0 
									then @hoursDecimalFormat0
								when uht.FormatType = 1
									then @hoursDecimalFormat1
								when uht.FormatType = 3
									then @hoursDecimalFormat3
								else @hoursDecimalFormat2
							end
						) else ''0'' end,
						'' - '',
						format(
							uht.MaxVal,
							case
								when uht.FormatType = 0
									then @hoursDecimalFormat0
								when uht.FormatType = 1
									then @hoursDecimalFormat1
								when uht.FormatType = 3
									then @hoursDecimalFormat3
								else @hoursDecimalFormat2
							end
						)
					) 
			when (uht.Render = 1
					and uht.MaxVal is not null
					and (uht.MaxVal > 0
						or uht.RenderIfZero = 1
					)
				) then case when uht.MaxVal <> 0 then format(
					uht.MaxVal,
					case
						when uht.FormatType = 0
							then @hoursDecimalFormat0
						when uht.FormatType = 1
							then @hoursDecimalFormat1
						when uht.FormatType = 3
							then @hoursDecimalFormat3
						else @hoursDecimalFormat2
					end
				)else ''0'' end
			else null
		end as RenderedRange
) uhr;

select mr.CourseId as [Value]
	-- custom-course-summary-context-wrapper
   , concat(''<div style="font-family: Calibri;font-size:12px;padding-left:10px;padding-right:10px;margin-top: 10px;page-break-inside: avoid;">'',
		dbo.fnHtmlOpenTag(@summaryWrapperTag,
			dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper'')
			),
			-- another nested wrapper
			dbo.fnHtmlOpenTag(@summaryWrapperTag, concat(
				dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
				dbo.fnHtmlAttribute(''data-course-id'', mrd.CourseId)
				)
				),
				-- Department row (Department)
				--dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-Department-header''))),
				--	dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
				--		dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-Department'')),
				--			UPPER(mrd.Department),
				--		dbo.fnHtmlCloseTag(@boldDataElementTag),
				--	dbo.fnHtmlCloseTag(@columnTag),
				--dbo.fnHtmlCloseTag(@rowTag),
				-- Course Title row (Course subject code, number, and title)
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-title-header''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-subject'')),
							UPPER(mrd.SubjectCode),@space,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-number'')),
							UPPER(SUBSTRING(mrd.CourseNumber, PATINDEX(''%[^0]%'', mrd.CourseNumber+''.''), LEN(mrd.CourseNumber)) ), case when mrd.Suffix is not null and len(mrd.Suffix) > 0 then concat(mrd.Suffix,@space) else @space end,''</br>'',
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-title'')),
							mrd.CourseTitle,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- units and hours
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-units-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-unit-range'')),
							isNull(unithr.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@DataElementTag),
                        dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-unit-label'')),
							case
								when len(unithr.RenderedRange) > 0 then 
								concat(
								case 
									when unithr.RenderedRange <> ''1'' then  '' Units''
									else ''Unit'' 
								end,  
								case
									when len(lecthr.RenderedRange) > 0 or len(labhr.RenderedRange) > 0 or len(learnhr.RenderedRange) > 0
									then '', ''
									else @empty
								end )
								else @empty 
							end,
						dbo.fnHtmlCloseTag(@DataElementTag),
                        --lecture
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-range'')),
							isNull(lecthr.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-label'')),
							case 
								when len(lecthr.RenderedRange) > 0 then 
								case 
									when lecthr.RenderedRange <> ''1'' then  '' hours lecture'' 
									else ''hour lecture'' 
								end
								else @empty 
							end,
							case
								when len(lecthr.RenderedRange) is not null and len(labhr.RenderedRange) is not null then '', ''
								else ''''
							end,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        --lab
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-range'')),
														isNull(labhr.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-label'')),
							case 
								when len(labhr.RenderedRange) > 0 then 
									case 
										when labhr.RenderedRange <> ''1'' then  '' hours lab'' 
										else ''hour lab'' 
									end
								else @empty 
							end,
							case
								when len(learnhr.RenderedRange) is not null then '',''
							end,
							@space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        --learn
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-range'')),
							isNull(learnhr.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-label'')),
							case 
								when len(learnhr.RenderedRange) > 0 then 
									case 
										when learnhr.RenderedRange <> ''1'' then  '' hours Learning Center'' 
										else ''hour Learning Center'' 
									end
								else @empty 
							end, @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
						-- grading policy
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-label'')),
							''('', 
						dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-value'')),
							case
								when mrd.CourseGrading = ''GC'' then ''GR or P/NP''
								when mrd.CourseGrading = ''P/NP/SP'' then ''SP or P/NP''
								else isNull(mrd.CourseGrading, @empty)
							end, '')'',
						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- Requisite
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-Requisite-row''))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-Requisite-value'')),
						isNull(mrd.Requisite, @empty),
						@space,
					dbo.fnHtmlCloseTag(@dataElementTag),
				dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- Credit By Exam
                dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-Credit-By-Exam-row''))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-Credit-By-Exam-value'')),
						case when MRD.CBE = 1 then ''Eligible for credit by examination'' else '''' end,
					dbo.fnHtmlCloseTag(@dataElementTag),
				dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- Acceptable for Credit: ((UC, CSU))
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-Transfer-row''))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-Transfer-value'')),
						Case
							when isnull(mrd.Transfer,'''') <> '''' then ''Acceptable for Credit ''
							else @empty
						end,
						isNull(mrd.Transfer, @empty),@space,
					dbo.fnHtmlCloseTag(@dataElementTag),
				dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- Course description
                dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-description-row''))),
                dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
                    dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-description-value'')),
                        case
                            when mrd.CatalogDescription is not null and len(mrd.CatalogDescription) > 0
                                then mrd.CatalogDescription
                                else @empty
                        end,@space,
                    dbo.fnHtmlCloseTag(@dataElementTag),
               		-- topcode
					dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-topcode-value'')),
						@space,UPPER(mrd.TopCode),
					dbo.fnHtmlCloseTag(@DataElementTag),
				dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- Peralta GE Areas it fulfils
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-PeraltaArea-row''))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					Case 
						WHEN mrd.PeraltaArea is not null and mrd.PeraltaArea <> ''''
						THEN Concat(	
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-PeraltaArea-value'')),
								Case
									when isnull(mrd.PeraltaArea,'''') <> '''' then ''Peralta GE Areas ''
									else @empty
								end,
								isNull(mrd.PeraltaArea + ''; '',@empty),
								@space,
							dbo.fnHtmlCloseTag(@dataElementTag)
						)
					END,
				-- CSU area it fulfills
					Case 
						WHEN mrd.CSUArea is not null and mrd.CSUArea <> ''''
						THEN Concat(	
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CSUArea-value'')),
								Case
									when isnull(mrd.CSUArea ,'''') <> '''' then ''CSU area ''
									else @empty
								end,
								isNull(mrd.CSUArea+ ''; '' ,@empty),
								@space,
							dbo.fnHtmlCloseTag(@dataElementTag)
						)
					END,
				-- IGETC area it fulfills
					Case 
						WHEN mrd.IGETCArea is not null and mrd.IGETCArea <> ''''
						THEN Concat(
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-IGETCArea-value'')),
								Case
									when isnull(mrd.IGETCArea + ''; '','''') <> '''' then ''IGETC area ''
									else @empty
								end,
								isNull(mrd.IGETCArea + ''; '',@empty),
								@space,
							dbo.fnHtmlCloseTag(@dataElementTag)
						)
					END,
				dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- C-ID number, if applicable.
                dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-CID-row''))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					case
						when lower(mrd.CIDStatus) = ''approved'' and mrd.CID is not null and len(mrd.CID) > 0
							then concat(
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value-prefix'')),
									''('',
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value'')),
									''C-ID: '', mrd.CID, 
								dbo.fnHtmlCloseTag(@dataElementTag),
								case 
									when mrd.CIDNotes is not null and len(mrd.CIDNotes) > 0 then concat(
										dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value-notes'')),
											'' '', mrd.CIDNotes,
										dbo.fnHtmlCloseTag(@dataElementTag)
									) -- Removed comma for MS-13571
									else @empty
								end,
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value-suffix'')),
									'')'',
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						else @empty
					end,
				dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag),''</div>''
	) as [Text]
from @modelRoot mr
inner join @modelRootData mrd on mr.CourseId = mrd.CourseId
left join @unitHourRanges unithr on (mr.CourseId = unithr.CourseId 
	and unithr.UnitHourTypeId = 1)
left join @unitHourRanges lecthr on (mr.CourseId = lecthr.CourseId 
	and lecthr.UnitHourTypeId = 2)
left join @unitHourRanges labhr on (mr.CourseId = labhr.CourseId 
	and labhr.UnitHourTypeId = 3)
left join @unitHourRanges learnhr on (mr.CourseId = learnhr.CourseId 
	and learnhr.UnitHourTypeId = 4)
inner join @elementClasses ecfw on ecfw.Id = 4 --4 = FullWidthRow
order by mr.InsertOrder;
'
WHERE Id = 12


UPDATE CatalogSection
SET ParentId = 21973
WHERE Id in (
21976,
21978,
21980,
21982,
21984,
21988,
21995,
22506,
22509
)

UPDATE CatalogSection
SET SortOrder = 2
WHERE Id = 21976

UPDATE CatalogSection
SET SortOrder = 3
WHERE Id = 21978

UPDATE CatalogSection
SET SortOrder = 4
WHERE Id = 21980

UPDATE CatalogSection
SET SortOrder = 5
WHERE Id = 21984

UPDATE CatalogSection
SET SortOrder = 6
WHERE Id = 21988

UPDATE CatalogSection
SET SortOrder = 7
WHERE Id = 21995

UPDATE CatalogSection
SET SortOrder = 8
WHERE Id = 22506

UPDATE CatalogSection
SET SortOrder = 9
WHERE Id = 22509

UPDATE CatalogSection
SET SortOrder = 10
WHERE Id = 21982

DELETE FROM CatalogSection
WHERE Id in (
21975,
21977,
21979,
21981,
21983,
21987,
21994,
22505,
22508
)

--commit