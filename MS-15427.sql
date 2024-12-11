USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15427';
DECLARE @Comments nvarchar(Max) = 
	'Update Query for Program Pathway';
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
DECLARE @SQL NVARCHAR(MAX) = '
declare @inlineTag nvarchar(10) = ''span'';
declare @blockTag nvarchar(10) = ''div'';
declare @footnoteIdentifierTag nvarchar(10) = ''sup'';
declare @classAttrib nvarchar(10) = ''class'';
declare @empty nvarchar(1) = '''';
declare @space nvarchar(5) = '' '';

drop table if exists #renderedInjections;

create table #renderedInjections (
	TableName sysname,
	Id int,
	InjectionType nvarchar(255),
	RenderedText nvarchar(max),
	primary key (TableName, Id, InjectionType)
);

--#region ProgramCourse rendered injections - course entries
insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	''ProgramCourse'' as TableName, pc.Id, ''CourseEntryRightColumn'',
	concat(
				/*case when len(ed.ExtraDetailsIcons) > 0 then concat(
					@space,
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''course-entry-icons'')),
						ed.ExtraDetailsIcons,
					dbo.fnHtmlCloseTag(@inlineTag)
				) else @empty end,*/
            case when pc.Parent_Id is not null 
            then
			    dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'') + dbo.fnHtmlAttribute(''style'',''padding:0px;padding-right:4px;padding-top:5px;width:40%;''))
            else 
                dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'') + dbo.fnHtmlAttribute(''style'',''padding:0px;padding-top:5px;width:40%;''))
            end,
                ExtraDetailsIcons,
			dbo.fnHtmlCloseTag(@blockTag),			
            dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1 text-right'') + dbo.fnHtmlAttribute(''style'',''float:right;padding:0px;width:60%;'')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''units-display block-entry-units-display'')),
                    case 
                    when 
                        (pc.Calculate = 0 AND pc.DoNotCalculate = 0)
                        OR
                        (pc.Calculate = 1 AND pc.DoNotCalculate = 0)
                        OR
                        (pc.Calculate = 1 AND pc.DoNotCalculate = 1)
                    then
                        case
                            when pc.CalcMin is not null and pc.CalcMax is not null
                                and pc.CalcMin <> pc.CalcMax
                                then format(pc.CalcMin, ''F1'')
                                + ''-'' + format(pc.CalcMax, ''F1'')
                            when pc.CalcMin is not null
                                then format(pc.CalcMin, ''F1'')
                            when pc.CalcMax is not null
                                then format(pc.CalcMax, ''F1'')
                            else ''''
                        end
                    else 
                        ''''
                    end,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag)        
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on pc.CourseOptionId = co.Id
inner join Course c on pc.CourseId = c.Id
cross apply (
	select
		concat(
			case
				when c.IsDistanceEd =1 then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:#0075df!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''color:white!important;top:-6px;font-size:8px;'')),
                            ''O'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when CourseTypeProgramId IN (5,4,2) then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:rebeccapurple!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''color:white!important;top:-6px;font-size:8px;'')),
                            ''GE'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when pc.CourseTypeProgramId IN (1,2,3,4) then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:mediumvioletred!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''color:white!important;top:-5px;font-size:8px;'')),
                            ''M'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end
		) as ExtraDetailsIcons
) ed
where (
	co.ProgramId = @entityId
	or exists (
		select top 1 1
		from ProgramCourse pc2
		inner join CourseOption co2 on pc2.CourseOptionId = co2.Id
		where co2.ProgramId = @entityId
		and pc.Id = pc2.ReferenceId
	)
);
--#endregion ProgramCourse rendered injections - course entries

--#region ProgramCourse rendered injections - non-course entries
insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	''ProgramCourse'' as TableName, pc.Id, ''NonCourseEntryRightColumn'',
	concat(
				/*case when len(ed.ExtraDetailsIcons) > 0 then concat(
					@space,
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''course-entry-icons'')),
						ed.ExtraDetailsIcons,
					dbo.fnHtmlCloseTag(@inlineTag)
				) else @empty end,*/
            case when pc.Parent_Id is not null 
            then
			    dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'') + dbo.fnHtmlAttribute(''style'',''padding:0px;padding-right:4px;padding-top:5px;width:40%;''))
            else 
                dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'') + dbo.fnHtmlAttribute(''style'',''padding:0px;padding-top:5px;width:40%;''))
            end,
                ExtraDetailsIcons,
			dbo.fnHtmlCloseTag(@blockTag),			
            dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1 text-right'') + dbo.fnHtmlAttribute(''style'',''float:right;padding:0px;width:60%;'')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''units-display block-entry-units-display'')),
                    case 
                    when 
                        (pc.Calculate = 0 AND pc.DoNotCalculate = 0)
                        OR
                        (pc.Calculate = 1 AND pc.DoNotCalculate = 0)
                        OR
                        (pc.Calculate = 1 AND pc.DoNotCalculate = 1)
                    then
                        case
                            when pc.CalcMin is not null and pc.CalcMax is not null
                                and pc.CalcMin <> pc.CalcMax
                                then format(pc.CalcMin, ''F1'')
                                + ''-'' + format(pc.CalcMax, ''F1'')
                            when pc.CalcMin is not null
                                then format(pc.CalcMin, ''F1'')
                            when pc.CalcMax is not null
                                then format(pc.CalcMax, ''F1'')
                            else ''''
                        end
                    else 
                        ''''
                    end,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag)        
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on pc.CourseOptionId = co.Id
cross apply (
	select
		concat(
			case
				when CourseTypeProgramId IN (5,4,2) then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:rebeccapurple!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''color:white!important;top:-6px;font-size:8px;'')),
                            ''GE'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when pc.CourseTypeProgramId IN (1,2,3,4) then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:mediumvioletred!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''color:white!important;top:-5px;font-size:8px;'')),
                            ''M'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end
		) as ExtraDetailsIcons
) ed
where (
	co.ProgramId = @entityId
	or exists (
		select top 1 1
		from ProgramCourse pc2
		inner join CourseOption co2 on pc2.CourseOptionId = co2.Id
		where co2.ProgramId = @entityId
		and pc.Id = pc2.ReferenceId
	)
);
--#endregion ProgramCourse rendered injections - non-course entries

--#region ProgramCourse rendered injections - non-course entries
insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	''ProgramCourse'' as TableName, pc.Id, ''NonCourseEntryLeftColumn'',
	concat(
		dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''row'')),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-9 col-sm-9 col-md-9'')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''non-course-entry-title'')),
					t.ListItemTitle,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1 text-right'')),
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''non-course-spacer'')),
					''&nbsp;'',
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag),
		dbo.fnHtmlCloseTag(@blockTag)
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on (pc.CourseOptionId = co.Id and pc.CourseId is null)
left outer join ListItemType lit on pc.ListItemTypeId = lit.Id
cross apply (
	--Quick HACK
	--I am NOT calling fnResolveOrderedListEntryTitles from this query for exactly the reasons given
	--in the comment at the top of that function (tl;dr too fragile!)
	--Do not have time to engineer a better general solution given I was given this task today and told to have it done by tomorrow
	--So that is why I''m hard-coding the backing stores this way
	--Going off of the ordinal instead of the ListItemTypeId directly as the Non-Course requirement list item type
	--only exists on Sandbox, and I''m not sure how stable that Id (Currently 6) is, while the ordinals are much more
	--fixed in place so are more reliable for this logic
	select
		--pc.Header as ListItemTitle
		case lit.ListItemTypeOrdinal
			when 2 then pc.Header --2 = Group
			when 3 then pc.ProgramCourseRule --3 Non-Course Requirement
		end as ListItemTitle
) t
where (
	co.ProgramId = @entityId
	or exists (
		select top 1 1
		from ProgramCourse pc2
		inner join CourseOption co2 on pc2.CourseOptionId = co2.Id
		where co2.ProgramId = @entityId
		and pc.Id = pc2.ReferenceId
	)
);
--#endregion ProgramCourse rendered injections - non-course entries

--#region extra details queries
declare @programCourseExtraDetails nvarchar(max) =
''select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramCourse'''' and ri.Id = @id and ri.InjectionType = ''''CourseEntryRightColumn'''';'';

declare @programCourseNonCourseExtraDetails nvarchar(max) =
''select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramCourse'''' and ri.Id = @id and ri.InjectionType = ''''NonCourseEntryLeftColumn'''';'';

declare @programCourseNonCourseExtraDetailsRight nvarchar(max) =
''select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramCourse'''' and ri.Id = @id and ri.InjectionType = ''''NonCourseEntryRightColumn'''';'';

--#endregion extra details queries

declare @extraDetailsDisplay StringPair;

insert into @extraDetailsDisplay (String1, String2)
values
(''CourseEntryRightColumnReplacement'', @programCourseExtraDetails),
(''NonCourseEntryLeftColumnReplacement'', @programCourseNonCourseExtraDetails),
(''NonCourseEntryRightColumnReplacement'',@programCourseNonCourseExtraDetailsRight);


exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @creditHoursLabel = ''Semester Units:'', @outputTotal = 0;

drop table if exists #renderedInjections;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 5943

UPDATE MetaSelectedField
SET DisplayName = '
<div style="font-weight:normal;"> 
	<p>
		<span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:#0075df!important;color:white;border:1px solid black;"><span style="color:white!important;top:-6px;font-size:8px;">O</span></span> 
		Available Online
		<span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:rebeccapurple!important;color:white;border:1px solid black;"><span style="color:white!important;top:-6px;font-size:8px;">GE</span></span> 
		General Education
		<span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:mediumvioletred!important;color:white;border:1px solid black;"><span style="color:white!important;top:-5px;font-size:8px;">M</span></span> 
		Major Requirement
		
	</p>
</div>
'
WHERE MetaSelectedFieldId in (
	SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 110
	and msf.RowPosition = 4
	and msf.DefaultDisplayType = 'StaticText'
)


UPDATE MetaSelectedField
SET DisplayName = '
<div style="font-weight:normal;"><p>The pathway below represents an efficient and effective course taking sequence for this program.
Individual circumstances might require some changes to this pathway.
It is <em><strong>always</strong></em> recommended that you <strong>meet with an academic counselor</strong> to develop a personalized educational plan.</p>
<p>The courses have been intentionally placed and should be prioritized in the order in which they appear.
If you are unable to take all the courses in a semester, you should prioritize enrolling in the courses in the order below.
Some courses have been noted as “Appropriate for Intersession” <span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:#084968!important;border:1px solid black;">
<span style="color:white!important;top:-6px;font-size:8px;">IN</span></span>.
Should you need (or want) to take classes in the summer and/or winter intersessions, the program recommends these courses as appropriate for the condensed schedule of the intersessions.</p><p>Some pathways combine a “Certificate of Achievement” and an “Associate Degree”.
If you are pursuing only the Certificate of Achievement, you are only required to take the courses marked “Program Requirement” <span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:mediumvioletred!important;color:white;border:1px solid black;">
<span style="position:relative;color:white!important;top:-5px;font-size:12px;">?</span></span>.</p>
<p>All pathways include at least one “Gateway Course”<span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:green!important;color:white;border:1px solid black;">
<span style="position:relative;color:white!important;top:-5px;font-size:12px;">!</span></span>which introduces you to the program and/or field of study and helps you decide if you want to continue with this Academic and Career Path. </p>
<p>Most Associate degrees (though not Associate Degrees for Transfer) require satisfying the SMC Global Citizenship requirement.
If the Program Requirements do not include a “Global Citizenship course”, be sure to select a General Education course that also satisfies Global Citizenship.</p></div>
'
WHERE MetaSelectedFieldId in (
	SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 110
	and msf.RowPosition = 3
	and msf.DefaultDisplayType = 'StaticText'
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 5943
)