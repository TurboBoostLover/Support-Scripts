USE [HKAPA];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17794';
DECLARE @Comments nvarchar(Max) = 
	'Update some queries to ensure that the correct data shows';
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
UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = '
DECLARE @custom NVARCHAR(MAX) = (SELECT CustomSql FROM MetaForeignKeyCriteriaClient WHERE Id = 272);
DECLARE @user INT = (SELECT Id FROM [User] WHERE Email = ''supportadmin@curriqunet.com'');


declare @school int = (
	select Tier1_OrganizationEntityId
	from CourseDetail
	where courseId = @entityId
)

declare @type int = (
	SELECT Value
	FROM dbo.fnBulkResolveCustomSqlQuery(@custom, 1, @entityId, 1, @user, 1, NULL)
)

declare @subdivision int = (
	select SubDivisionCategoryId
	from CourseDetail
	where CourseId = @entityId
)


if @subdivision is not null
BEGIN
--Chinese opera
if (@school = 1)
BEGIN

	if(@subdivision in (58, 3, 59))
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (2)
		order by SortOrder
	else
	begin
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
		    
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		order by SortOrder
	end

end

--LA
if (@school = 48)
BEGIN
	if(@subdivision in (98))
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (7, 26)
		order by SortOrder
	else if (@subdivision in (100))
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (27,28,29,30,31)
		order by SortOrder
	else
	begin
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		order by SortOrder
	end
end

--LG
if (@school = 50)
BEGIN
	--chinese opera
	if(@subdivision = 103)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (
			--advanced
			94,95,96,97,120,121,
			--elementary
			98,100,101,102,103,104,
			--intermediate
			105,107,108,109,110,111
			)
		order by SortOrder
	--dance
	else if (@subdivision = 104)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (
			--advanced
			93,94,95,96,97,121,
			--elementary
			98,99,101,102,103,104,
			--intermediate
			105,106,108,109,110,111
		)
		order by SortOrder
	--drama
	else if (@subdivision = 105)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (
			--advanced
			93,94,95,96,97,120,
			--elementary
			98,99,100,102,103,104,
			--intermediate
			105,106,107,109,110,111
			)
		order by SortOrder
	--ftv
	else if (@subdivision = 106)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (
			--advanced
			93,95,96,97,120,121,
			--elementary
			98,99,100,101,103,104,
			--intermediate
			105,106,107,108,110,111
			)
		order by SortOrder
	--music
	else if (@subdivision = 107)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (
			--advanced
			93,94,96,97,120,121,
			--elementary
			98,99,100,101,102,104,
			--intermediate
			105,106,107,108,109,111
			)
		order by SortOrder	
	--tea
	else if (@subdivision = 108)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (
			--advanced
			93,94,95,97,120,121,
			--elementary
			98,99,100,101,102,103,
			--intermediate
			105,106,107,108,109,110
			)
		order by SortOrder
	--lang chinese or english	
	else if (@subdivision in (102,109))
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (
			--advanced
			93,94,95,96,120,121,
			--elementary
			99,100,101,102,103,104,
			--intermediate
			106,107,108,109,110,111
		)
		order by SortOrder	
	else
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		order by SortOrder
end

--dance
if (@school = 2)
BEGIN
	select
		Id as Value
		,Title as Text
		,@subdivision as FilterValue
		
	from EligibilityCriteria
	where Active = 1
	and Code = @type
	and ParentEligibilityCriteriaId in (
		select Id
		from EligibilityCriteria
		where ParentEligibilityCriteriaId is null
		and Title = cast(@school as nvarchar(max))
	)
	order by SortOrder
end

--drama
if (@school = 7)
BEGIN
	if(@subdivision in (148,149,150))
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (11)
		order by SortOrder
	else
	begin
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		order by SortOrder
	end
end

--Film and TV
if (@school = 8)
BEGIN
	if(@subdivision = 84 or @subdivision is null)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		order by SortOrder
	else
	begin
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (13)
		order by SortOrder
	end
	
end

--music
if (@school = 46)
BEGIN
	select
		Id as Value
		,Title as Text
		,@subdivision as FilterValue
		
	from EligibilityCriteria
	where Active = 1
	and Code = @type
	and ParentEligibilityCriteriaId in (
		select Id
		from EligibilityCriteria
		where ParentEligibilityCriteriaId is null
		and Title = cast(@school as nvarchar(max))
	)
	order by SortOrder
end

--PAR
if (@school = 80)
BEGIN
	if(@subdivision = 117)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (42)
		order by SortOrder
	else if (@subdivision = 116)
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (114,115,116,117)
		order by SortOrder
end

--theatre
if (@school = 47)
BEGIN
	if(@subdivision not in (141))
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id not in (80)
		order by SortOrder
	else
	begin
		select
			Id as Value
			,Title as Text
			,@subdivision as FilterValue
			
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		order by SortOrder
	end
end
END
'
WHERE Id = 212

UPDATE EligibilityCriteria
SET Title = 'Master of Fine Arts & MA Performing Arts Studies'
WHERE Id = 118

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 212
)