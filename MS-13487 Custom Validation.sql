USE [chabot];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13487';
DECLARE @Comments nvarchar(Max) = 
	'Open Course Number to be edited and fix validation of course number';
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
DEclare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

insert into @templateId
select mt.MetaTemplateId
from MetaTemplateType mtt
inner join MetaTemplate mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
where mtt.EntityTypeId = @Entitytypeid
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate is NULL
and mtt.active = 1
and mtt.IsPresentationView = 0
and mtt.ClientId = @clientId
and mtt.MetaTemplateTypeId = 7 --noncredit course proposal

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
('Cover', 'Course', 'CourseNumber','CNumber')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/

UPDATE MetaSelectedField
SET ReadOnly = 0
WHERE MetaSelectedFieldId IN (SELECT FieldId FROM @Fields)

SET QUOTED_IDENTIFIER OFF

Update MetaCommandProcessor
SET CommandSQL =
"
declare @entityId int;
declare @courseNumber nvarchar(max);

select @entityId = entityId 
, @courseNumber = [value] 
from @parameters
where [target] = 'Course.CourseNumber'

declare @message nvarchar(max),
	--@courseNumber varchar(50) = (select [string2] from @parameters where string1 = 'EntityNumber'),
	@unitLow int = 200, 
	@unitHigh  int = 299,
	@isLowOk bit = 0, 
	@isHighOk bit = 1;
declare @parsedCourseNumber int = try_cast(@courseNumber as int)
	if (@parsedCourseNumber >= @unitLow)
		set @isLowOk = 1; 
	else 
		set @isLowOk = 0;
	if (@unitHigh > 0)
		if (@parsedCourseNumber <= @unitHigh)
			set @isHighOk = 1;
		else 
			set @isHighOk = 0;
	--select @isLowOk as '@isLowOk', @isHighOk as '@isHighOk'
	--, @unitLow as '@unitLow', @unitHigh as '@unitHigh' 
	--, @numberCourseNumber as '@numberCourseNumber'
	if (@isLowOk != 1 or @isHighOk != 1)
	begin;
		if (@unitHigh > 0)
		begin;
				set @message = concat('This is a Noncredit level course proposal. The course number must be between ', @unitLow, ' and ', @unitHigh, '.');
			end;
			else 
			begin;
				set @message = concat('This is a Noncredit level course proposal. The course number must be greater than ', @unitLow, '.');
				end;
			end;
			else 
			begin;
				set @message = null; 
			end;
		select @message as [Message], case when @message is null then 1 else 0 end as Success
"
WHERE Id = 2;
SET QUOTED_IDENTIFIER ON
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2


--commit
--rollback