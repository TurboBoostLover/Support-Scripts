USE [chabot];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14297';
DECLARE @Comments nvarchar(Max) = 
	'Update Pathway Names';
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
DECLARE @SQL nvarchar(max)='
DECLARE @Logo nvarchar(max) =
(SELECT top 1
	CASE
		when 1= 2
			then ''pass''		--comment out these two lines also
		--when Lookup14id = 2
		--	then ''/Content/themes/base/images/clientimages/ad-banner-chabot.png''
		--when Lookup14id = 3
		--	then ''/Content/themes/base/images/clientimages/be-banner-chabot.png''
		--when Lookup14id = 4
		--	then ''/Content/themes/base/images/clientimages/hw-banner-chabot.png''		comment all these back in
		--when Lookup14id in (5,6)
		--	then ''/Content/themes/base/images/clientimages/iiat-banner-chabot.png''
		--when Lookup14id = 7
		--	then ''/Content/themes/base/images/clientimages/sci-banner-chabot.png''
		--when Lookup14id = 10
		--	then ''/Content/themes/base/images/clientimages/sm-banner-chabot.png''
		ELSE NULL --comment out to bring back in logos
	END
FROM ProgramLookup14
WHERE programid = @entityId);


SELECt
CONCAT(
''<div class="report-header-override container bottom-margin-normal text-left">
    <div class="college-logo-wrapper">
        <img class="college-logo" src="/Content/themes/base/images/clientimages/chabot-logo.png" title="Chabot College">
    </div>'',
	Case 
		WHEN @Logo is not NULL
			then CONCAT(
				''<div class="cpathway-logo-wrapper">
					<img class="pathway-logo" title="Pathway logo" src="'',@Logo,''">
				</div>''
			)
     END,
    ''<h1 class="report-title h1">Program Map</h1>
	<h3 class="report-entity-title h3">'',p.EntityTitle,''</h3>
</div>
<div class="row">
	<div class="col-md-12">
		<div class="h3"> </div>
		<div class="seperator-add hr-darker"> </div>
	</div>
</div>'') AS Text,
Id As Value
FROM Program p
WHERE p.id = @entityID
'

UPDATE Lookup14
SET Title = 'Business, Economics & Information Technology'
WHERE Id = 3

UPDATE Lookup14
SET EndDate = GETDATE()
WHERE Id = 6

UPDATE Lookup14
SET Title = 'Social Sciences, Humanities & Education'
WHERE Id = 7

UPDATE Lookup14
SET Title = 'Science, Technology, Engineering & Mathematics'
WHERE Id = 10

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 1088