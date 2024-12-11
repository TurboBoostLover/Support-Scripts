DECLARE @EntityId int = 863

declare @inlineTag nvarchar(10) = 'span';
declare @blockTag nvarchar(10) = 'div';
declare @footnoteIdentifierTag nvarchar(10) = 'sup';
declare @classAttrib nvarchar(10) = 'class';
declare @empty nvarchar(1) = '';
declare @space nvarchar(5) = ' ';

drop table if exists #renderedInjections;

create table #renderedInjections (
	TableName sysname,
	Id int,
	InjectionType nvarchar(255),
	RenderedText nvarchar(max),
	primary key (TableName, Id, InjectionType)
);

--#region ProgramCourse rendered injections
insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	'ProgramCourse' as TableName, pc.Id, 'CourseEntryMiddleColumn',
	concat(
		dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'row')),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-6 col-sm-6 col-md-6')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'course-entry-title')),
					c.Title,
				dbo.fnHtmlCloseTag(@inlineTag),
				case
					when pc.ExceptionIdentifier is not null then concat(
						dbo.fnHtmlOpenTag(@footnoteIdentifierTag, dbo.fnHtmlAttribute(@classAttrib, 'footnote-identifier')),
							pc.ExceptionIdentifier,
						dbo.fnHtmlCloseTag(@footnoteIdentifierTag)
					)
					else @empty
				end,
				case when len(ed.ExtraDetailsIcons) > 0 then concat(
					@space,
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'course-entry-icons')),
						ed.ExtraDetailsIcons,
					dbo.fnHtmlCloseTag(@inlineTag)
				) else @empty end,
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-3 col-sm-3 col-md-3')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'course-Units')),
					format(PC.CalcMin,'0.0#'),
					case when PC.CalcMin <> PC.CalcMax then ' - ' + format(PC.CalcMax,'0.0#') end,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-3 col-sm-3 col-md-3')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'course-Semester')),
					PCT.title,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag),
		dbo.fnHtmlCloseTag(@blockTag)
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on pc.CourseOptionId = co.Id
inner join Course c on pc.CourseId = c.Id
left join ProgramCourseType PCT on PCT.id = PC.ProgramCourseTypeId
left outer join CourseGlobalCitizenship cgc on c.Id = cgc.CourseId
left outer join CourseDistanceEducation cde on c.Id = cde.CourseId
outer apply (
    select 
        rtrim(concat(
            case when ISNULL(PC.Bit01, 0) = 1 then 'Spring, ' else '' end,
            case when ISNULL(PC.Bit02, 0) = 1 then 'Summer, ' else '' end,
            case when ISNULL(PC.Bit03, 0) = 1 then 'Fall, ' else '' end,
            case when ISNULL(PC.Bit04, 0) = 1 then 'Rotating, ' else '' end
        )) as txt
) Sem
cross apply (
	select
		concat(
			case
				when pc.Bit01 = 1 then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'gateway-course-icon fa fa-sign-in-alt')),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when cgc.IsApproved = 1 then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'approved-for-global-citizenship-icon fa fa-globe')),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when cde.IsApproved = 1 then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'approved-for-distance-education-icon fa fa-laptop')),
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


insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	'ProgramCourse' as TableName, pc.Id, 'CourseEntryRightColumn',
	concat(
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'Semester')),
					case when len(Sem.txt) > 0 then left(Sem.txt,len(Sem.txt) - 1) else '&nbsp;' end,
				dbo.fnHtmlCloseTag(@inlineTag)
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on pc.CourseOptionId = co.Id
left join ProgramCourseType PCT on PCT.id = PC.ProgramCourseTypeId
outer apply (
    select 
        rtrim(concat(
            case when ISNULL(PC.Bit01, 0) = 1 then 'Spring, ' else '' end,
            case when ISNULL(PC.Bit02, 0) = 1 then 'Summer, ' else '' end,
            case when ISNULL(PC.Bit03, 0) = 1 then 'Fall, ' else '' end,
            case when ISNULL(PC.Bit04, 0) = 1 then 'Rotating, ' else '' end
        )) as txt
) Sem;
--#endregion ProgramCourse rendered injections

--#region ProgramCourse rendered injections - footer
insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	'CourseOption' as TableName, co.Id, 'BlockFooterPrefix',
	concat(
		--dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'sequence-number-explanation')),
		--	'The sequence number is the recommended order in which courses should be taken',
		--dbo.fnHtmlCloseTag(@blockTag),
		dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'icon-legend')),
			il.IconsLegend,
		dbo.fnHtmlCloseTag(@blockTag)
	) as RenderedText
from CourseOption co
cross apply (
	select
		concat(
			case when exists (
				select top 1 1
				from ProgramCourse pc
				where pc.CourseOptionId = co.Id
				and pc.Bit01 = 1
			) then concat(
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'gateway-course-icon fa fa-sign-in-alt')),
				dbo.fnHtmlCloseTag(@inlineTag), @space,
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'gateway-course-icon-label')),
					'Gateway Course', @space,
				dbo.fnHtmlCloseTag(@inlineTag)
			) else @empty end,
			case when exists (
				select top 1 1
				from ProgramCourse pc
				inner join CourseGlobalCitizenship cgc on pc.CourseId = cgc.CourseId
				where pc.CourseOptionId = co.Id
				and cgc.IsApproved = 1
			) then concat(
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'approved-for-global-citizenship-icon fa fa-globe')),
				dbo.fnHtmlCloseTag(@inlineTag), @space,
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'approved-for-global-citizenship-icon-label')),
					'Approved for Global Citizenship', @space,
				dbo.fnHtmlCloseTag(@inlineTag)
			) else @empty end,
			case when exists (
				select top 1 1
				from ProgramCourse pc
				inner join CourseDistanceEducation cde on pc.CourseId = cde.CourseId
				where pc.CourseOptionId = co.Id
				and cde.IsApproved = 1
			) then concat(
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'approved-for-distance-education-icon fa fa-laptop')),
				dbo.fnHtmlCloseTag(@inlineTag), @space,
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'approved-for-distance-education-icon-label')),
					'Approved for Distance Education',
				dbo.fnHtmlCloseTag(@inlineTag)
			) else @empty end
		) as IconsLegend
) il
where co.ProgramId = @entityId;
--#endregion ProgramCourse rendered injections - footer

insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	'ProgramCourse' as TableName, pc.Id, 'NonCourseEntryRightColumnReplacement',
	concat(
				case when len(ed.ExtraDetailsIcons) > 0 then concat(
					@space,
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'course-entry-icons')),
						ed.ExtraDetailsIcons,
					dbo.fnHtmlCloseTag(@inlineTag)
				) else @empty end,
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-2 col-sm-2 col-md-2')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'course-Units')),
					format(PC.CalcMin,'0.0#'),
					case when PC.CalcMin <> PC.CalcMax then ' - ' + format(PC.CalcMax,'0.0#') end,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-2 col-sm-2 col-md-2')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'GEN')),
					PCT.title,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-2 col-sm-2 col-md-2 text-end')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'course-Semester')),
					case when len(Sem.txt) > 0 then left(Sem.txt,len(Sem.txt) - 1) else '&nbsp;' end,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag)
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on pc.CourseOptionId = co.Id
left join ProgramCourseType PCT on PCT.id = PC.ProgramCourseTypeId
outer apply (
    select 
        rtrim(concat(
            case when ISNULL(PC.Bit01, 0) = 1 then 'Spring, ' else '' end,
            case when ISNULL(PC.Bit02, 0) = 1 then 'Summer, ' else '' end,
            case when ISNULL(PC.Bit03, 0) = 1 then 'Fall, ' else '' end,
            case when ISNULL(PC.Bit04, 0) = 1 then 'Rotating, ' else '' end
        )) as txt
) Sem
cross apply (
	select
			case
				when pc.Bit01 = 1 then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'gateway-course-icon fa fa-sign-in-alt')),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end as ExtraDetailsIcons
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

insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	'ProgramCourse' as TableName, pc.Id, 'NonCourseEntryLeftColumnReplacement',
	concat(
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-6 col-sm-6 col-md-6')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, 'Title')),
					pc.Header,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag)
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on pc.CourseOptionId = co.Id
WHERE co.ProgramId = @EntityId

insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	'CourseOption' as TableName, co.Id, 'BlockHeaderSuffix',
	concat(
		dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'row column-heading-row bg-primary text-white')),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-2 col-sm-2 col-md-2 left-column text-left')),
				'Course',
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-4 col-sm-4 col-md-4 left-middle-column text-left')),
				'&nbsp;',
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-2 col-sm-2 col-md-2 middle-column text-left')),
				'Units',
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-2 col-sm-2 col-md-2 right-column text-left')),
					'MAJ/GEN/ELEC',
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, 'col-xs-2 col-sm-2 col-md-2 right-middle-column text-right text-end')),
				'Semester(s) Offered',
			dbo.fnHtmlCloseTag(@blockTag),
		dbo.fnHtmlCloseTag(@blockTag)
	) as RenderedText
from CourseOption co
where co.ProgramId = @entityId;

declare @programCourseExtraDetails nvarchar(max) =
'select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''ProgramCourse'' and ri.Id = @id and ri.InjectionType = ''CourseEntryMiddleColumn'';';

declare @programCourseExtraDetailsRight nvarchar(max) =
'select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''ProgramCourse'' and ri.Id = @id and ri.InjectionType = ''CourseEntryRightColumn'';';

declare @blockFooterExtraDetails nvarchar(max) = 
'select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''CourseOption'' and ri.Id = @id and ri.InjectionType = ''BlockFooterPrefix'';';

declare @blockHeaderExtraDetails nvarchar(max) =
'select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''CourseOption'' and ri.Id = @id and ri.InjectionType = ''BlockHeaderSuffix'';';

declare @non nvarchar(max) =
'select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''ProgramCourse'' and ri.Id = @id and ri.InjectionType = ''NonCourseEntryRightColumnReplacement'';';

declare @non2 nvarchar(max) =
'select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''ProgramCourse'' and ri.Id = @id and ri.InjectionType = ''NonCourseEntryLeftColumnReplacement'';';

declare @extraDetailsDisplay StringPair;

declare @classOverrides StringTriple;

INSERT INTO @classOverrides
(String1, String2, String3)
VALUES
('NonCourseRow', 'LeftColumn', 'col-xs-4 col-sm-4 col-md-4 two-column left-column text-left text-start')

insert into @extraDetailsDisplay (String1, String2)
values
('CourseEntryMiddleColumnReplacement', @programCourseExtraDetails),
('CourseEntryRightColumnReplacement', @programCourseExtraDetailsRight),
('BlockFooterPrefix', @blockFooterExtraDetails),
('BlockHeaderSuffix', @blockHeaderExtraDetails),
('NonCourseEntryRightColumnReplacement', @non),
('NonCourseEntryLeftColumnReplacement', @non2);

exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @elementClassOverrides = @classOverrides;

drop table if exists #renderedInjections;