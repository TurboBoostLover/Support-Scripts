USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15408';
DECLARE @Comments nvarchar(Max) = 
	'Show more effecctive terms in codes and dates';
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
 Declare @Testing bit = 0;
 Declare @Deploy bit = 1; /*Set to 1 for deploying and leaving the transaction open*/
 Declare @AddMFKCCRecords int = 0

Use sdccd;

Declare @ClientId int = 1;
Declare @ClientDatabaseHasData bit = 1
Declare @StartYear int = 2000;
Declare @EndYear int = (Select year(Current_TimeStamp)+30)
Declare @YearPosition bit = 0; /* 1 puts the year after the title 0 puts the year before the title */

Select @StartYear as StartYear, @EndYear as EndYear

Drop table if exists #SeedTable
Create table #SeedTable (TermName nvarchar(50),StartMonthAndDay Nvarchar(6),EndMonthAndDay Nvarchar(6),SortOrder int,AddStartYear int,AddEndYear int);

Insert into #SeedTable (TermName,StartMonthAndDay,EndMonthAndDay ,SortOrder,AddStartYear,AddEndYear)
output 'Seed Records' as Context,inserted.*
Values
 ('Fall','08-31-','01-28-', 1,0,0)
,('Spring','01-30-','06-10-', 2,1,1)
,('Summer','06-12-','08-26-', 3,1,1)
/*
 ('Fall Semester','08-26-','12-23-', 1,0,0)
,('Spring Semester','01-09-','05-16-', 2,1,1)
,('Summer Semester','05-27-','08-08-', 3,1,1)
 ,
('Fall Quarter',  '09-01-','12-31-', 1,0,0)
,('Winter Quarter','01-01-','03-31-', 2,1,1)
,('Spring Quarter','04-01-','06-31-', 3,1,1)
,('Summer Quarter','07-01-','09-31-', 4,1,1)*/
;

/* Error Checking data that was entered in the #SeedTable */

If (select Count(*) 
from #SeedTable
Where Left(StartMonthAndDay,2) > 12 
or Left(StartMonthAndDay,2) < 01
or  Left(EndMonthAndDay,2) > 12 
or Left(EndMonthAndDay,2) < 00) >0
Begin
	select 'Error: These records have invalid month data!' as Message, * 
	from #SeedTable
	Where Left(StartMonthAndDay,2) > 12 
	or Left(StartMonthAndDay,2) < 01
	or  Left(EndMonthAndDay,2) > 12 
	or Left(EndMonthAndDay,2) < 00;
END


Update #SeedTable /*  This query is to fix potential errors where the day entered in StartMonthAndDay is greater than the number of days in the month entered*/
Set StartMonthAndDay =
Case When Left(StartMonthAndDay,2) in ('01','03','05','07','08','12') and Convert( int,(Left(Right( StartMonthAndDay,3),2))) > 31
		Then Left(StartMonthAndDay,2)+ '-31-'	
	 When Left(StartMonthAndDay,2) in ('04','06','09','11') and Convert( int,(Left(Right( StartMonthAndDay,3),2))) > 30
		Then Left(StartMonthAndDay,2)+ '-30-'
	 When Left(StartMonthAndDay,2) = '02' and Convert( int,(Left(Right( StartMonthAndDay,3),2))) > 28
		Then Left(StartMonthAndDay,2)+ '-28-'
	Else StartMonthAndDay
End

Update #SeedTable /*  This query is to fix potential errors where the day entered in EndMonthAndDay is greater than the number of days in the month entered*/
Set EndMonthAndDay =
Case When Left(EndMonthAndDay,2) in ('01','03','05','07','08','12') and Convert( int,(Left(Right( EndMonthAndDay,3),2))) > 31
		Then Left(EndMonthAndDay,2)+ '-31-'	
	 When Left(EndMonthAndDay,2) in ('04','06','09','11') and Convert( int,(Left(Right( EndMonthAndDay,3),2))) > 30
		Then Left(EndMonthAndDay,2)+ '-30-'
	 When Left(EndMonthAndDay,2) = '02' and Convert( int,(Left(Right( EndMonthAndDay,3),2))) > 28
		Then Left(EndMonthAndDay,2)+ '-28-'
	Else EndMonthAndDay
End

/* End Error Checking data entered in the #SeedTable */

If (Select Count(Id) from Client where active = 1) =1
Begin
	 set @ClientId = (Select Top 1 Id from Client Where active = 1);
End

If @ClientDatabaseHasData = 1 
Begin
	Drop table if exists #BaseYear 
	;With BaseYears as (
	Select min(year(createdOn)) as StartYear from Course 
	Union
	Select Min(year(CreatedOn)) as StartYear from Program
	)  select Min(StartYear) as Startyear into #BaseYear From BaseYears

	Set @StartYear = (Select Startyear from #BaseYear);
End


Drop table if exists #Years 
Create Table #Years (Yr int);

While @StartYear < @EndYear+1
Begin

	Insert into #Years (yr)
	Values
	(@StartYear);

	Set @StartYear = (@StartYear+1)
End

Update Semester set Active = 0, Enddate = Current_Timestamp Where ClientId = @ClientId;

drop table if exists #SemesterTemp
select Case when @YearPosition= 1 and AddStartYear = 0 then  TermName + ' ' + Cast(Yr as nvarchar(4)) 
			when @YearPosition= 1 and AddStartYear = 1 then  TermName + ' ' + Cast(Yr + 1 as nvarchar(4)) 
            When @YearPosition= 0 and AddStartYear = 0 then  Cast(Yr as nvarchar(4)) + ' ' + TermName
			When @YearPosition= 0 and AddStartYear = 1 then  Cast(Yr + 1 as nvarchar(4)) + ' ' + TermName
End as Title 
, Case when (Select Sum(AddEndYear) from #SeedTable)  > 0 Then  Cast(Yr as nvarchar(4)) + '-' + Cast((Yr + 1) as nvarchar(4))
  Else Cast(Yr as nvarchar(4)) + '-' + Cast(Yr as nvarchar(4))
  End as CatalogYear
, 1 as Active
, @ClientId as ClientId
, NUll as EndDate
, Row_Number() Over ( Order By Case when AddStartYear = 0 then  Cast(yr as nvarchar(4))  + Left(StartMonthAndDay, 2)
                                    When AddStartYear = 1 then  Cast((Yr + 1) as nvarchar(4)) + Left(StartMonthAndDay, 2) END ) As SortOrder
, Case when AddStartYear = 0 then  Cast(yr as nvarchar(4))  + Left(StartMonthAndDay, 2)
       When AddStartYear = 1 then  Cast((Yr + 1) as nvarchar(4)) + Left(StartMonthAndDay, 2)
End as Code
,Current_Timestamp as StartDate
, Case when AddStartYear = 0 then Convert(datetime, (StartMonthAndDay + Cast(Yr as nvarchar(4))))  
	   When AddStartYear = 1  then  Convert(datetime, (StartMonthAndDay + Cast((Yr + 1) as nvarchar(4))))
  End as TermStartDate
, Case when AddendYear = 0 then Convert(datetime, (EndMonthAndDay + Cast(Yr as nvarchar(4))))  
	   When AddEndYear = 1  then  Convert(datetime, (EndMonthAndDay + Cast(Yr + 1 as nvarchar(4))))
  End as TermEndDate
, Yr as AcademicYearStart
, Case when (Select Sum(AddEndYear) from #SeedTable)  > 0 Then Cast((Yr + 1) as nvarchar(4))
  Else Cast(Yr as nvarchar(4)) 
  End as AcademicYearEnd
  into #semesterTemp
from #SeedTable st cross join #Years y
Where ((Left(st.StartMonthAndDay,2) < 13 and Left(st.StartMonthAndDay,2) > 00)
And  (Left(st.EndMonthAndDay,2) < 13 and Left(st.EndMonthAndDay,2) > 00))
order by Code

merge semester as target
using (
Select Title,	CatalogYear,	Active,	ClientId,	EndDate,	SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,AcademicYearStart,	AcademicYearEnd
from #semesterTemp
)as Source (Title,	CatalogYear,	Active,	ClientId,	EndDate,	SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd)
on 1=0 WHEN not matched THEN
insert (Title,	CatalogYear,	Active,	ClientId,	EndDate,	SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd)
Values (Source.Title,	Source.CatalogYear,	Source.Active,	Source.ClientId,	Source.EndDate,	Source.SortOrder,	Source.Code,	Source.StartDate,	Source.TermStartDate,	Source.TermEndDate,	Source.AcademicYearStart,	Source.AcademicYearEnd)
output inserted.*;

Declare @NewMFKCCId int = (Select Max(Id)+1 from MetaForeignKeyCriteriaClient);
If @AddMFKCCRecords = 1
Begin
	
	Insert into MetaForeignKeyCriteriaClient
	(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,Title,LookupLoadTimingType)
	output inserted.*
	Values
	(@NewMFKCCId, 'Semester', 'Id', 'Title',
		';With AllTerms as(
		select Id,	Title,	CatalogYear,	Active,	ClientId,	EndDate,	Code as SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd	
		from semester where active = 1
		and AcademicYearStart > year(current_timestamp)-3
		and AcademicYearStart < year(current_timestamp)+7 
		union
		select Id,	Title,	CatalogYear,	Active,	ClientId,	EndDate,	Code * 10 as SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd	
		from semester where active = 1
		and AcademicYearStart < year(current_timestamp) -2
		/* or AcademicYearStart > year(current_timestamp) +6 */
		union
		select Id,	Title + '' (Inactive)'' as title,	CatalogYear,	Active,	ClientId,	EndDate,	Id * 1000000 as SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd	
		from semester where active = 0
		) 
		Select Id as Value, Title as Text
		from AllTerms
		Order by SortOrder ',
		'Select Title As Text from Semester where Id = @Id', 'Order By SortOrder', 'Rolling Semester Query with All Terms',1);

End;

If @Testing = 1
Begin
	Select @StartYear as StartYear, @EndYear as EndYear
	select * from Semester
	Select 'Testing is set to 1, transaction has been rolled back.' as Message
	Print 'Testing is set to 1, transaction has been rolled back.' 
Rollback
End
Else If (select Count(*) 
from #SeedTable
Where Left(StartMonthAndDay,2) > 12 
or Left(StartMonthAndDay,2) < 01
or  Left(EndMonthAndDay,2) > 12 
or Left(EndMonthAndDay,2) < 00) > 0
Begin
	Select 'Invalid Date in Seed table transaction has been rolled back.' as Message
	Print 'Invalid Date in Seed table transaction has been rolled back.' 
	rollback
END
ELSE if @Deploy = 1
Begin
	Select 'You have an open Transaction Terms have been added to the Semester table but not committed.' as Message
	Print 'You have an open Transaction Terms have been added to the Semester table but not committed.' 
End
Else
BEGIN
	Select 'Terms added to the Semester table and committed.' as Message
	Print 'Terms added to the Semester table and committed.' 
	commit
END

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE Active = 1

/*
Commit
*/