USE [rccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14271';
DECLARE @Comments nvarchar(Max) = 
	'Fixed hard coded course id in the catalog presentation that grabs the grade options';
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
UPDATE OutputModelClient
SET ModelQuery = '
declare @entityList_internal table (
	InsertOrder int Identity(1, 1) primary key
	, CourseId int
);

insert into @entityList_internal (CourseId)
select el.Id
from @entityList el;

declare @entityRootData table (	
	[Transfer] nvarchar(max),
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
	Requisite nvarchar(max),
	CatalogDescription nvarchar(max),
	CourseGrading nvarchar(max),
	CID nvarchar(500),
	FormerlyLanguage nvarchar(max),
	Prerequisite bit,
	IsTBALab bit,
	Crosslisting nvarchar(max)
);

declare @clientId int = (
	select top 1 c.ClientId 
	from Course c
		inner join @entityList_internal eli on c.Id = eli.CourseId
)




declare @requisite_mfkccId int = 4012;
declare @requisite_mfkccQuery nvarchar(max) = 
''select 0 as [Value]
, dbo.ConcatWithSepOrdered_Agg(
	''''<br>'''',
	A.RequisiteTypeId,
	A.[Text]
) as [Text]
from (
	select  
		B.RequisiteTypeId
	, concat(
		B.RequisiteType, '''': '''',
		dbo.ConcatWithSepOrdered_Agg(
			'''''''',
			SortOrder,
			concat(
				case
					when B.CourseId is not null then concat(
						B.SubjectCode, '''' '''', UPPER(SUBSTRING(B.CourseNumber, PATINDEX(''''%[^0]%'''', B.CourseNumber+''''.''''), LEN(B.CourseNumber)) ),
						case 
							when B.Comment is not null then concat('''' '''', B.Comment)
							else ''''''''
						end,B.CourseRequisiteComment
					)
					else B.CourseRequisiteComment
				end,
				case
					when B.Condition is not null then 
						case
							when B.CountPerRequisiteType = B.SortOrder then concat('''' '''', B.Condition)
							else concat('''' '''', B.Condition, '''' '''')
						end
					else 
						case
							when B.CountPerRequisiteType = B.SortOrder then ''''''''
							else '''', ''''
						end
				end
			)
		)
	) as [Text]	
	from (
		select con.title as Condition
		-- this is done on purpose as a fallback if the fitler subject id is wrong or empty
		, S.SubjectCode
		, C1.CourseNumber
		, CR.CourseRequisiteComment
		-- reset sort order
		, row_number() over (partition by rt.Id order by CR.SortOrder, CR.id) as SortOrder
		, count(*) over (partition by rt.Id) as CountPerRequisiteType
		, RT.Title as RequisiteType
		, RT.id as RequisiteTypeId
		, CR.CommText as Comment
		, c1.Id as CourseId
		from CourseRequisite CR
			left join course C1 on C1.id = CR.Requisite_CourseId
			left join [Subject] S on S.id = C1.subjectid
			inner join RequisiteType RT on CR.RequisiteTypeid = RT.id
			left join Condition con on CR.ConditionId = con.id
		where CR.courseid = @entityId
	) B
	group by RequisiteTypeId, RequisiteType
) A'';

-- ============================
-- return
-- ============================
insert into @entityRootData (
	[Transfer]
	, CourseId
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
	, Requisite
	, CatalogDescription
	, CourseGrading
	, CID
	, FormerlyLanguage
	, Prerequisite
	, IsTBALab
	, Crosslisting
)
select distinct
	tr.Transfer
	, c.Id
	, s.SubjectCode
	, c.CourseNumber
	, c.Title
	, CD.Variable
	, cd.MinCreditHour --Min unit
	, cd.MaxCreditHour
	, cd.MinLectureHour
	, cd.MaxLectureHour
	, cd.MinLabHour
	, cd.MaxLabHour
	, REQ.[Text] as Requisite
	, lTrim(rTrim(c.[Description]))
	, gon.Title -- course grading
	, g255.Text25501 --CID
	, gMAX.TextMax15 --Formerly Language
	, Prereq.bit --Prerequisite
	, CD.IsTBALab
	, CL.Crosslisting
from Course c
	inner join @entityList_internal eli on c.Id = eli.CourseId
	inner join CourseDescription cd on c.Id = cd.CourseId
	inner join CourseCampus CC on CC.courseid = C.id
		and CC.campusid = 1
	left join [Subject] s on c.SubjectId = s.Id
	left join Generic255Text g255 on g255.courseid = c.id
	left join GenericMaxText gMAX on gMAX.courseid = c.id
	left join CourseAttribute CA on c.Id = cA.CourseId
	outer apply (
		select fn.[Text]
		from (
			select c.Id as entityId
			, @requisite_mfkccQuery as [query]
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
		select case 
			when Code = ''A'' then ''UC, CSU''
			when Code = ''B'' then ''CSU''
			else null
		end as Transfer
		from Designation
		where CA.DesignationId = id
	) Tr
	outer apply (
		select
		case
			when A.counter = 2 and a.miner = 1 and a.maxer = 3 then ''(Letter grade or Pass/No Pass option)''
			when A.counter = 1 and a.miner = 1 then ''(Letter grade only)''
			when A.counter = 1 and a.miner = 2 then ''(No grade)''
			when A.counter = 1 and a.miner = 3 then ''(Pass/No Pass only)''
			else null
		end as Title
		from
			(select count(GradeOptionId) as counter, min(GradeOptionId) as miner, max(GradeOptionId) as maxer
			from CourseGradeOption CGO 
			where CGO.CourseId = c.Id) A
	) gon
	outer apply (
		select isnull( (select top 1 1 
		from CourseRequisite CR
		where RequisiteTypeId = 1
			and Courseid = C.id),0) as [bit]
	) Prereq
	outer apply (
	select ''(Same as '' + dbo.ConcatWithSepOrdered_Agg('', '',RowNum,A.Text) + '') '' as Crosslisting
		from (select distinct concat(s2.SubjectCode,''-'', c2.CourseNumber) as Text,ROW_NUMBER() OVER (Order by concat(s2.SubjectCode,''-'', c2.CourseNumber)) as RowNum
			from CourseRelatedCourse CRC
				inner join course C2 on CRC.RelatedCourseId = C2.id
				inner join subject S2 on C2.subjectid = S2.id
		where CRC.courseid = C.id and C.AddCrossListed = 1) A
	) CL
;

select eli.CourseId as Id
	, m.Model
from @entityList_internal eli
	cross apply (
		select (
			select *
			from @entityRootData erd
			where eli.CourseId = erd.CourseId
			for json path, without_array_wrapper
		) RootData
	) erd
	cross apply (
		select (
			select eli.InsertOrder
				, json_query(erd.RootData) as RootData
			for json path
		) Model
	) m
;
'
WHERE Id = 1

UPDATE OutputModelClient
SET ModelQuery = '
declare @entityList_internal table (
	InsertOrder int Identity(1, 1) primary key
	, CourseId int
);

insert into @entityList_internal (CourseId)
select el.Id
from @entityList el;

declare @entityRootData table (	
	[Transfer] nvarchar(max),
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
	Requisite nvarchar(max),
	CatalogDescription nvarchar(max),
	CourseGrading nvarchar(max),
	CID nvarchar(500),
	FormerlyLanguage nvarchar(max),
	Prerequisite bit,
	IsTBALab bit,
	Crosslisting nvarchar(max)
);

declare @clientId int = (
	select top 1 c.ClientId 
	from Course c
		inner join @entityList_internal eli on c.Id = eli.CourseId
)




declare @requisite_mfkccId int = 4012;
declare @requisite_mfkccQuery nvarchar(max) = 
''select 0 as [Value]
, dbo.ConcatWithSepOrdered_Agg(
	''''<br>'''',
	A.RequisiteTypeId,
	A.[Text]
) as [Text]
from (
	select  
		B.RequisiteTypeId
	, concat(
		B.RequisiteType, '''': '''',
		dbo.ConcatWithSepOrdered_Agg(
			'''''''',
			SortOrder,
			concat(
				case
					when B.CourseId is not null then concat(
						B.SubjectCode, '''' '''', UPPER(SUBSTRING(B.CourseNumber, PATINDEX(''''%[^0]%'''', B.CourseNumber+''''.''''), LEN(B.CourseNumber)) ),
						case 
							when B.Comment is not null then concat('''' '''', B.Comment)
							else ''''''''
						end,B.CourseRequisiteComment
					)
					else B.CourseRequisiteComment
				end,
				case
					when B.Condition is not null then 
						case
							when B.CountPerRequisiteType = B.SortOrder then concat('''' '''', B.Condition)
							else concat('''' '''', B.Condition, '''' '''')
						end
					else 
						case
							when B.CountPerRequisiteType = B.SortOrder then ''''''''
							else '''', ''''
						end
				end
			)
		)
	) as [Text]	
	from (
		select con.title as Condition
		-- this is done on purpose as a fallback if the fitler subject id is wrong or empty
		, S.SubjectCode
		, C1.CourseNumber
		, CR.CourseRequisiteComment
		-- reset sort order
		, row_number() over (partition by rt.Id order by CR.SortOrder, CR.id) as SortOrder
		, count(*) over (partition by rt.Id) as CountPerRequisiteType
		, RT.Title as RequisiteType
		, RT.id as RequisiteTypeId
		, CR.CommText as Comment
		, c1.Id as CourseId
		from CourseRequisite CR
			left join course C1 on C1.id = CR.Requisite_CourseId
			left join [Subject] S on S.id = C1.subjectid
			inner join RequisiteType RT on CR.RequisiteTypeid = RT.id
			left join Condition con on CR.ConditionId = con.id
		where CR.courseid = @entityId
	) B
	group by RequisiteTypeId, RequisiteType
) A'';

-- ============================
-- return
-- ============================
insert into @entityRootData (
	[Transfer]
	, CourseId
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
	, Requisite
	, CatalogDescription
	, CourseGrading
	, CID
	, FormerlyLanguage
	, Prerequisite
	, IsTBALab
	, Crosslisting
)
select distinct
	tr.Transfer
	, c.Id
	, s.SubjectCode
	, c.CourseNumber
	, c.Title
	, CD.Variable
	, cd.MinCreditHour --Min unit
	, cd.MaxCreditHour
	, cd.MinLectureHour
	, cd.MaxLectureHour
	, cd.MinLabHour
	, cd.MaxLabHour
	, REQ.[Text] as Requisite
	, lTrim(rTrim(c.[Description]))
	, gon.Title -- course grading
	, g255.Text25501 --CID
	, gMAX.TextMax15 --Formerly Language
	, Prereq.bit --Prerequisite
	, CD.IsTBALab
	, CL.Crosslisting
from Course c
	inner join @entityList_internal eli on c.Id = eli.CourseId
	inner join CourseDescription cd on c.Id = cd.CourseId
	inner join CourseCampus CC on CC.courseid = C.id
		and CC.campusid = 2
	left join [Subject] s on c.SubjectId = s.Id
	left join Generic255Text g255 on g255.courseid = c.id
	left join GenericMaxText gMAX on gMAX.courseid = c.id
	left join CourseAttribute CA on c.Id = cA.CourseId
	outer apply (
		select fn.[Text]
		from (
			select c.Id as entityId
			, @requisite_mfkccQuery as [query]
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
		select case 
			when Code = ''A'' then ''UC, CSU''
			when Code = ''B'' then ''CSU''
			else null
		end as Transfer
		from ConsentOption
		where C.ConsentOptionId = id
	) Tr
	outer apply (
		select
		case
			when A.counter = 2 and a.miner = 1 and a.maxer = 3 then ''(Letter grade or Pass/No Pass option)''
			when A.counter = 1 and a.miner = 1 then ''(Letter grade only)''
			when A.counter = 1 and a.miner = 2 then ''(No grade)''
			when A.counter = 1 and a.miner = 3 then ''(Pass/No Pass only)''
			else null
		end as Title
		from
			(select count(GradeOptionId) as counter, min(GradeOptionId) as miner, max(GradeOptionId) as maxer
			from CourseGradeOption CGO 
			where CGO.CourseId = c.Id) A
	) gon
	outer apply (
		select isnull( (select top 1 1 
		from CourseRequisite CR
		where RequisiteTypeId = 1
			and Courseid = C.id),0) as [bit]
	) Prereq
	outer apply (
	select ''(Same as '' + dbo.ConcatWithSepOrdered_Agg('', '',RowNum,A.Text) + '') '' as Crosslisting
		from (select distinct concat(s2.SubjectCode,''-'', c2.CourseNumber) as Text,ROW_NUMBER() OVER (Order by concat(s2.SubjectCode,''-'', c2.CourseNumber)) as RowNum
			from CourseRelatedCourse CRC
				inner join course C2 on CRC.RelatedCourseId = C2.id
				inner join subject S2 on C2.subjectid = S2.id
		where CRC.courseid = C.id and C.AddCrossListed = 1) A
	) CL
;

select eli.CourseId as Id
	, m.Model
from @entityList_internal eli
	cross apply (
		select (
			select *
			from @entityRootData erd
			where eli.CourseId = erd.CourseId
			for json path, without_array_wrapper
		) RootData
	) erd
	cross apply (
		select (
			select eli.InsertOrder
				, json_query(erd.RootData) as RootData
			for json path
		) Model
	) m
;
'
WHERE Id = 2

UPDATE OutputModelClient
SET ModelQuery = '
declare @entityList_internal table (
	InsertOrder int Identity(1, 1) primary key
	, CourseId int
);

insert into @entityList_internal (CourseId)
select el.Id
from @entityList el;

declare @entityRootData table (	
	[Transfer] nvarchar(max),
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
	Requisite nvarchar(max),
	CatalogDescription nvarchar(max),
	CourseGrading nvarchar(max),
	CID nvarchar(500),
	FormerlyLanguage nvarchar(max),
	Prerequisite bit,
	IsTBALab bit,
	Crosslisting nvarchar(max)
);

declare @clientId int = (
	select top 1 c.ClientId 
	from Course c
		inner join @entityList_internal eli on c.Id = eli.CourseId
)




declare @requisite_mfkccId int = 4012;
declare @requisite_mfkccQuery nvarchar(max) = 
''select 0 as [Value]
, dbo.ConcatWithSepOrdered_Agg(
	''''<br>'''',
	A.RequisiteTypeId,
	A.[Text]
) as [Text]
from (
	select  
		B.RequisiteTypeId
	, concat(
		B.RequisiteType, '''': '''',
		dbo.ConcatWithSepOrdered_Agg(
			'''''''',
			SortOrder,
			concat(
				case
					when B.CourseId is not null then concat(
						B.SubjectCode, '''' '''', UPPER(SUBSTRING(B.CourseNumber, PATINDEX(''''%[^0]%'''', B.CourseNumber+''''.''''), LEN(B.CourseNumber)) ),
						case 
							when B.Comment is not null then concat('''' '''', B.Comment)
							else ''''''''
						end,B.CourseRequisiteComment
					)
					else B.CourseRequisiteComment
				end,
				case
					when B.Condition is not null then 
						case
							when B.CountPerRequisiteType = B.SortOrder then concat('''' '''', B.Condition)
							else concat('''' '''', B.Condition, '''' '''')
						end
					else 
						case
							when B.CountPerRequisiteType = B.SortOrder then ''''''''
							else '''', ''''
						end
				end
			)
		)
	) as [Text]	
	from (
		select con.title as Condition
		-- this is done on purpose as a fallback if the fitler subject id is wrong or empty
		, S.SubjectCode
		, C1.CourseNumber
		, CR.CourseRequisiteComment
		-- reset sort order
		, row_number() over (partition by rt.Id order by CR.SortOrder, CR.id) as SortOrder
		, count(*) over (partition by rt.Id) as CountPerRequisiteType
		, RT.Title as RequisiteType
		, RT.id as RequisiteTypeId
		, CR.CommText as Comment
		, c1.Id as CourseId
		from CourseRequisite CR
			left join course C1 on C1.id = CR.Requisite_CourseId
			left join [Subject] S on S.id = C1.subjectid
			inner join RequisiteType RT on CR.RequisiteTypeid = RT.id
			left join Condition con on CR.ConditionId = con.id
		where CR.courseid = @entityId
	) B
	group by RequisiteTypeId, RequisiteType
) A'';

-- ============================
-- return
-- ============================
insert into @entityRootData (
	[Transfer]
	, CourseId
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
	, Requisite
	, CatalogDescription
	, CourseGrading
	, CID
	, FormerlyLanguage
	, Prerequisite
	, IsTBALab
	, Crosslisting
)
select distinct
	tr.Transfer
	, c.Id
	, s.SubjectCode
	, c.CourseNumber
	, c.Title
	, CD.Variable
	, cd.MinCreditHour --Min unit
	, cd.MaxCreditHour
	, cd.MinLectureHour
	, cd.MaxLectureHour
	, cd.MinLabHour
	, cd.MaxLabHour
	, REQ.[Text] as Requisite
	, lTrim(rTrim(c.[Description]))
	, gon.Title -- course grading
	, g255.Text25501 --CID
	, gMAX.TextMax15 --Formerly Language
	, Prereq.bit --Prerequisite
	, CD.IsTBALab
	, CL.Crosslisting
from Course c
	inner join @entityList_internal eli on c.Id = eli.CourseId
	inner join CourseDescription cd on c.Id = cd.CourseId
	inner join CourseCampus CC on CC.courseid = C.id
		and CC.campusid = 3
	left join [Subject] s on c.SubjectId = s.Id
	left join Generic255Text g255 on g255.courseid = c.id
	left join GenericMaxText gMAX on gMAX.courseid = c.id
	left join CourseAttribute CA on c.Id = cA.CourseId
	outer apply (
		select fn.[Text]
		from (
			select c.Id as entityId
			, @requisite_mfkccQuery as [query]
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
		select case 
			when Title = ''A'' then ''UC, CSU''
			when Title = ''B'' then ''CSU''
			else null
		end as Transfer
		from TransferApplication
		where CD.TransferAppsId = id
	) Tr
	outer apply (
		select
		case
			when A.counter = 2 and a.miner = 1 and a.maxer = 3 then ''(Letter grade or Pass/No Pass option)''
			when A.counter = 1 and a.miner = 1 then ''(Letter grade only)''
			when A.counter = 1 and a.miner = 2 then ''(No grade)''
			when A.counter = 1 and a.miner = 3 then ''(Pass/No Pass only)''
			else null
		end as Title
		from
			(select count(GradeOptionId) as counter, min(GradeOptionId) as miner, max(GradeOptionId) as maxer
			from CourseGradeOption CGO 
			where CGO.CourseId = c.Id) A
	) gon
	outer apply (
		select isnull( (select top 1 1 
		from CourseRequisite CR
		where RequisiteTypeId = 1
			and Courseid = C.id),0) as [bit]
	) Prereq
	outer apply (
	select ''(Same as '' + dbo.ConcatWithSepOrdered_Agg('', '',RowNum,A.Text) + '') '' as Crosslisting
		from (select distinct concat(s2.SubjectCode,''-'', c2.CourseNumber) as Text,ROW_NUMBER() OVER (Order by concat(s2.SubjectCode,''-'', c2.CourseNumber)) as RowNum
			from CourseRelatedCourse CRC
				inner join course C2 on CRC.RelatedCourseId = C2.id
				inner join subject S2 on C2.subjectid = S2.id
		where CRC.courseid = C.id and C.AddCrossListed = 1) A
	) CL
;

select eli.CourseId as Id
	, m.Model
from @entityList_internal eli
	cross apply (
		select (
			select *
			from @entityRootData erd
			where eli.CourseId = erd.CourseId
			for json path, without_array_wrapper
		) RootData
	) erd
	cross apply (
		select (
			select eli.InsertOrder
				, json_query(erd.RootData) as RootData
			for json path
		) Model
	) m
;
'
WHERE Id = 3