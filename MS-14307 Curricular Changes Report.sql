USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14307';
DECLARE @Comments nvarchar(Max) = 
	'Add Curricular Changes Report';
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

--basic report setup
update Config.ClientSetting set AllowCurricularChangesReport = 1;

insert into CurricularChangesReport (ClientId,UseCombinedYearTerms)
values (1,1);


set QUOTED_IDENTIFIER off;
declare @sql nvarchar(max);


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Standard fields
--Most of the time you won't need to change these queries because they are using standard backing stores.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_c.EntityTitle as NewRawValue
		,old_c.EntityTitle as OldRawValue
		,new_c.EntityTitle  as NewTextValue
		,old_c.EntityTitle  as OldTextValue
		,(case
			when (new_c.EntityTitle = old_c.EntityTitle)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join Subject new_s on new_s.Id = new_c.SubjectId
	left join Course old_c 
		inner join Subject old_s on old_s.Id = old_c.SubjectId
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,1,1,'Course',@sql);

	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_sa.Id as NewRawValue
		,old_sa.Id as OldRawValue
		,new_sa.Title as NewTextValue
		,old_sa.Title as OldTextValue
		,(case
			when (new_sa.Id = old_sa.Id)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join StatusAlias new_sa on new_c.StatusAliasId = new_sa.Id
	left join Course old_c 
		inner join StatusAlias old_sa on old_c.StatusAliasId = old_sa.Id
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,2,0,'Status',@sql);

	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_pat.Id as NewRawValue
		,old_pat.Id as OldRawValue
		,new_pat.Title as NewTextValue
		,old_pat.Title as OldTextValue
		,(case
			when (new_pat.Id = old_pat.Id)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join ProposalType new_pt on new_pt.Id = new_c.ProposalTypeId
		inner join ProcessActionType new_pat on new_pat.Id = new_pt.ProcessActionTypeId
	left join Course old_c 
		inner join ProposalType old_pt on old_pt.Id = old_c.ProposalTypeId
		inner join ProcessActionType old_pat on old_pat.Id = old_pt.ProcessActionTypeId
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,3,0,'Workflow Action Type',@sql);

	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_pt.Id as NewRawValue
		,old_pt.Id as OldRawValue
		,new_pt.Title as NewTextValue
		,old_pt.Title as OldTextValue
		,(case
			when (new_pt.Id = old_pt.Id)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join ProposalType new_pt on new_pt.Id = new_c.ProposalTypeId
		inner join ProcessActionType new_pat on new_pat.Id = new_pt.ProcessActionTypeId
	left join Course old_c 
		inner join ProposalType old_pt on old_pt.Id = old_c.ProposalTypeId
		inner join ProcessActionType old_pat on old_pat.Id = old_pt.ProcessActionTypeId
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,4,0,'Proposal Type',@sql);
	
	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_s.Id as NewRawValue
		,old_s.Id as OldRawValue
		,new_s.SubjectCode + ' - ' + new_s.Title as NewTextValue
		,old_s.SubjectCode + ' - ' + old_s.Title as OldTextValue
		,(case
			when (new_s.Id = old_s.Id)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join Subject new_s on new_s.Id = new_c.SubjectId
	left join Course old_c 
		inner join Subject old_s on old_s.Id = old_c.SubjectId
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,5,1,'Subject',@sql);
	
	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_c.CourseNumber as NewRawValue
		,old_c.CourseNumber as OldRawValue
		,new_c.CourseNumber  as NewTextValue
		,old_c.CourseNumber  as OldTextValue
		,(case
			when (new_c.CourseNumber = old_c.CourseNumber)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join Subject new_s on new_s.Id = new_c.SubjectId
	left join Course old_c 
		inner join Subject old_s on old_s.Id = old_c.SubjectId
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,6,1,'Course Number',@sql);
	
	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_c.Title as NewRawValue
		,old_c.Title as OldRawValue
		,new_c.Title  as NewTextValue
		,old_c.Title  as OldTextValue
		,(case
			when (new_c.Title = old_c.Title)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join Subject new_s on new_s.Id = new_c.SubjectId
	left join Course old_c 
		inner join Subject old_s on old_s.Id = old_c.SubjectId
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,7,1,'Course Title',@sql);

	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_s.Id as NewRawValue
		,old_s.Id as OldRawValue
		,new_s.Title  as NewTextValue
		,old_s.Title  as OldTextValue
		,(case
			when (new_s.Id = old_s.Id)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join CourseProposal new_cp on new_cp.CourseId = new_c.Id
		left join Semester new_s on new_s.Id = new_cp.SemesterId
	left join Course old_c 
		inner join CourseProposal old_cp on old_cp.CourseId = old_c.Id
		left join Semester old_s on old_s.Id = old_cp.SemesterId
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,8,0,'Effective Term',@sql);

	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_cp.MinCreditHour as NewRawValue
		,old_cp.MinCreditHour as OldRawValue
		,new_cp.MinCreditHour  as NewTextValue
		,old_cp.MinCreditHour  as OldTextValue
		,(case
			when (new_cp.MinCreditHour = old_cp.MinCreditHour)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join CourseDescription new_cp on new_cp.CourseId = new_c.Id
	left join Course old_c 
		inner join CourseDescription old_cp on old_cp.CourseId = old_c.Id
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,9,1,'Min Units',@sql);

	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_cp.MaxCreditHour as NewRawValue
		,old_cp.MaxCreditHour as OldRawValue
		,newmaxcred  as NewTextValue
		,oldmaxcred  as OldTextValue
		,(case
			when (isnull(newmaxcred,0.0) = isnull(oldmaxcred,0.0))
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		inner join CourseDescription new_cp on new_cp.CourseId = new_c.Id
	left join Course old_c 
		inner join CourseDescription old_cp on old_cp.CourseId = old_c.Id
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	outer apply 
	(
		select coalesce(new_cp.MaxCreditHour,new_cp.MinCreditHour) as newmaxcred,
		coalesce(old_cp.MaxCreditHour,old_cp.MinCreditHour) as oldmaxcred
	) c
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,1,10,1,'Max Units',@sql);

set @sql = "
with data as
(select
		EntityId
		,PreviousEntityId
		,2 as ItemGroupId
		,ROW_NUMBER() OVER(PARTITION BY 1 ORDER BY new_c.SortOrder) as DisplayItemNum
		,new_c.Id as NewRequisiteId
		,old_c.Id as OldRequisiteId
		,new_rt.Title as NewRequisiteType
		,old_rt.Title as OldRequisiteType
		,new_c.Requisite_CourseId as NewCourseId
		,old_c.Requisite_CourseId as OldCourseId
		,new_course.EntityTitle as NewEntityTitle
		,old_course.EntityTitle as OldEntityTitle
		,new_course.BaseCourseId as NewBaseCourseId
		,old_course.BaseCourseId as OldBaseCourseId
	from  (select @entityId as EntityId, @previousEntityId as PreviousEntityId) e
	left join CourseRequisite new_c
		left join Course new_course on new_course.Id = new_c.Requisite_CourseId
		inner join RequisiteType new_rt on new_rt.Id = new_c.RequisiteTypeId
		on new_c.CourseId = e.EntityId
	left join CourseRequisite old_c
		left join Course old_course on old_course.Id = old_c.Requisite_CourseId
		inner join RequisiteType old_rt on old_rt.Id = old_c.RequisiteTypeId
		on old_c.CourseId = e.PreviousEntityId
	where new_c.SortOrder = old_c.SortOrder)
	select @entityId as EntityId, @previousEntityId as PreviousEntityId, 0 as GroupItemNum, NULL as DisplayItemNum, '' as CannonicalName, 'Course Requisites' as HeaderText,
	cast((select count(*) from data where NewRequisiteId IS NOT NULL) as varchar(max)) as NewRawValue,
	cast((select count(*) from data where OldRequisiteId IS NOT NULL) as varchar(max)) as OldRawValue,
	'[Number of Items: ' + (select cast(count(*) as varchar(10)) from data where NewRequisiteId IS NOT NULL) + ']' as NewTextValue,
	'[Number of Items: ' + (select cast(count(*) as varchar(10)) from data where OldRequisiteId IS NOT NULL) + ']' as OldTextValue,
	case when (select count(*) from data where NewRequisiteId IS NOT NULL) = (select count(*) from data where OldRequisiteId IS NOT NULL) then 0 else 1 end as IsChanged,
	1 as IsCriticalChange
	UNION
	select @entityId as EntityId, @previousEntityId as PreviousEntityId, 1 as GroupItemNum, DisplayItemNum as DisplayItemNum, '' as CannonicalName, 'Requisite Course' as HeaderText,
	cast(NewCourseId as varchar(max)) as NewRawValue,
	cast(OldCourseId as varchar(max)) as OldRawValue,
	NewEntityTitle as NewTextValue,
	OldEntityTitle as OldTextValue,
	case when NewCourseId = OldCourseId then 0 else 1 end as IsChanged,
	case when NewBaseCourseId = OldBaseCourseId then 0 else 1 end as IsCriticalChange
	from data
	UNION
	select @entityId as EntityId, @previousEntityId as PreviousEntityId, 2 as GroupItemNum, DisplayItemNum as DisplayItemNum, '' as CannonicalName, 'Requisite Type' as HeaderText,
	NewRequisiteType as NewRawValue,
	OldRequisiteType as OldRawValue,
	NewRequisiteType as NewTextValue,
	OldRequisiteType as OldTextValue,
	case when NewRequisiteType = OldRequisiteType then 0 else 1 end as IsChanged,
	1 as IsCriticalChange
	from data;"


insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,2,1,1,'Course Requisite',@sql);
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--End Standard fields
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Non-Standard fields go here
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	set @sql = 
	"select
		new_c.Id as EntityId
		,old_c.Id as PreviousEntityId
		,new_cp.Bit05 as NewRawValue
		,old_cp.Bit05 as OldRawValue
		,case new_cp.Bit05 when 1 then 'True' else 'False' end as NewTextValue
		,case old_cp.Bit05 when 1 then 'True' else 'False' end as OldTextValue
		,(case
			when (new_cp.Bit05 = old_cp.Bit05)
				then 0
			else 1
			end) as IsChanged
	from  Course new_c
		left join GenericBit new_cp on new_cp.CourseId = new_c.Id
	left join Course old_c 
		left join GenericBit old_cp on old_cp.CourseId = old_c.Id
		on new_c.BaseCourseId = old_c.BaseCourseId AND new_c.Id != old_c.Id AND old_c.Id = @previousEntityId
	where new_c.Id = @entityId
	;";

insert into CurricularChangesReportRow (CurricularChangesReportId,ItemGroupId,GroupItemNum,IsCriticalChange,HeaderText,ChangeSQL)
values (1,3,1,0,'UC/CSU Transfer Course',@sql);