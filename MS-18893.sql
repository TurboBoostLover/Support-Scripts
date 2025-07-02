USE [gavilan];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18893';
DECLARE @Comments nvarchar(Max) = 
	'Update Annual update form so all fields report doesn''t break';
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
DECLARE @Id int = 92

DECLARE @SQL NVARCHAR(MAX) = '
declare @coal varchar(max);

with
Calc(Year, FullTime, PartTime, Total)
as
(
    Select 
        yl.Id as Year		
        ,cast(SUM(Int_02) as decimal(16,2)) as FullTime		
        ,cast(SUM(Int_03) as decimal(16,2)) as PartTime		
        ,cast(SUM(Int_02) + SUM(Int_03) as decimal(16,2)) as Total
    from EntityLearningPlan elp
        left join YearLookup yl on yl.id = elp.YearLookupId
    where elp.ModuleId = @entityId
    group by yl.Id
)
select @coal = 
	CASE WHEN Total <> 0 
		THEN coalesce(@coal,'''') +''<li>Year:'' + cast(YEAR as [nvarchar](100)) + ''</li>'' +''<li>FT = '' + cast(cast(round((FullTime  / Total) * 100,1) as [decimal](16,2)) as nvarchar(100)) + ''% </li>'' +''<li>PT = '' + cast(cast(round((PartTime /Total) * 100,1) as DECIMAL(16,2)) as [nvarchar](100)) + ''% </li>'' +''</br>''
	ELSE ''''
END
from Calc
select
0 as Value    , ''<h2>Percentage Full to Part Time Faculty</h2><ul style = "list-style-type:none;">'' + @coal + ''</ul>'' as Text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id