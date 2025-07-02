USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18502';
DECLARE @Comments nvarchar(Max) = 
	'Update COR query for Total out of class hours';
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
SET CustomSql = '
select
	0 as [Value]
	,coalesce(concat(
		case
			when InClassHour > 0 then ''<span style="Width:250px; Display:inline-flex"><b>Total Out of Class Hours:</b></span>''
			+ case
				when right(format(round(InClassHour, 1, -1),''###.0''), 1) >= 5
				then cast(floor(InClassHour) + .5 as nvarchar(10))
			 else
				cast(cast(InClassHour as int) as nvarchar(10))
			end
		else
			''''
		end
		,case when COALESCE(OutClassHour, CreditTotalHour) > InClassHour then '' - '' + case
			when right(format(round(COALESCE(OutClassHour, CreditTotalHour), 1, -1),''###.0''), 1) >= 5
			then cast(floor(COALESCE(OutClassHour, CreditTotalHour)) + .5 as nvarchar(10))
		  else
			cast(cast(COALESCE(OutClassHour, CreditTotalHour) as int) as nvarchar(10))
		  end
		end
		+ '' hours per semester''
	), '''')
	as [Text]
from CourseDescription
WHERE CourseId = @EntityId
'
, ResolutionSql = '
select
	0 as [Value]
	,coalesce(concat(
		case
			when InClassHour > 0 then ''<span style="Width:250px; Display:inline-flex"><b>Total Out of Class Hours:</b></span>''
			+ case
				when right(format(round(InClassHour, 1, -1),''###.0''), 1) >= 5
				then cast(floor(InClassHour) + .5 as nvarchar(10))
			 else
				cast(cast(InClassHour as int) as nvarchar(10))
			end
		else
			''''
		end
		,case when COALESCE(OutClassHour, CreditTotalHour) > InClassHour then '' - '' + case
			when right(format(round(COALESCE(OutClassHour, CreditTotalHour), 1, -1),''###.0''), 1) >= 5
			then cast(floor(COALESCE(OutClassHour, CreditTotalHour)) + .5 as nvarchar(10))
		  else
			cast(cast(COALESCE(OutClassHour, CreditTotalHour) as int) as nvarchar(10))
		  end
		end
		+ '' hours per semester''
	), '''')
	as [Text]
from CourseDescription
WHERE CourseId = @EntityId
'
WHERE ID = 2778

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 2778