USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16290';
DECLARE @Comments nvarchar(Max) = 
	'Configure look up manager';
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
declare @clientId int = 1

declare @tempLookups table (Id int identity(1,1), Name varchar(500),LookupId int)

insert into @tempLookups
(Name,LookupId)
select replace(Title,' ','')+ 'id',id
from LookupType
WHERE id NOT IN (54, 79)

declare @lookupToAdd table (Id int identity(1,1),LookupTypeId int ,CustomTitle varchar(500))

declare @start int = 1
declare @end int = (select max(id) + 1 from @tempLookups)

while @start < @end
BEGIN

    declare @displayname varchar(500) = (select Name from @tempLookups where Id = @start)
    declare @actualName varchar(500);
    declare @currentTypeId int = (select LookupId from @tempLookups where Id = @start)

    if exists (
        select top 1 msf.DisplayName
        from MetaAvailableField maf
	        inner join MetaSelectedField msf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
        where maf.ColumnName = @displayname
    )
    begin
        set @actualName =  (select top 1 msf.DisplayName
        from MetaAvailableField maf
	        inner join MetaSelectedField msf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
        where maf.ColumnName =@displayname)

        insert into @lookupToAdd
        (LookupTypeId,CustomTitle)
        VALUES
        (@currentTypeId,@actualName)

    end 

set @start = @start + 1

END

insert into ClientLookupType
(ClientId,LookupTypeId,CustomTitle)
output INSERTED.*
select 
    @clientId
    ,LookupTypeId
    ,Case   
        WHEN LookupTypeId = 18 then 'Course Date Type'
        WHEN LookupTypeId = 41 then 'Program Date Type'
    ELSE CustomTitle
    END
from @lookupToAdd