USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19123';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text or Objectives to show grouping correctly';
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
DECLARE @Id int = 136

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @Yes bit = (SELECT CASE WHEN ISNULL(YesNo50Id, 0) = 1 THEN 1 ELSE 0 End FROM CourseYesNo WHERE CourseId = @EntityId)

select 0 as Value,
concat(''<div class="ordered-list container-list container">'',Char(13)
	,''<div><label class="field-label style" style="margin-left: -25px;">Part 1:</label></div>''
	, (select STRING_AGG(
		concat(''  <div class="bottom-margin-small row">'',Char(13),
			''    <div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small" data-available-field-id="379" data-field-id="2647" data-field-type="Textarea">'',Char(13),
			''	  <label class="field-label">'',text,''</label>'',Char(13),
			''	</div>'',Char(13),
			''  </div>'',Char(13)
		), ''''
	) WITHIN GROUP (ORDER BY Sort)
	from (select text as text,Courseid,ROW_NUMBER() over (order by sortorder) as Sort from CourseObjective where CourseId = @entityid and YesNo01Id = 1) A)
	,''<div><label class="field-label" style="margin-left: -25px;">'', CASE WHEN @yes = 0 THEN '''' ELSE ''Part 2:'' END,''</label></div>''
	,(select STRING_AGG(
		concat(''  <div class="bottom-margin-small row">'',Char(13),
			''    <div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small" data-available-field-id="379" data-field-id="2647" data-field-type="Textarea">'',Char(13),
			''	  <label class="field-label">'',text,''</label>'',Char(13),
			''	</div>'',Char(13),
			''  </div>'',Char(13)
		), ''''
	) WITHIN GROUP (ORDER BY Sort)
	from (select text as text,Courseid,ROW_NUMBER() over (order by sortorder) as Sort from CourseObjective where CourseId = @entityid and (YesNo01Id <> 1 or YesNo01Id is null)) B)
,Char(13),''</div>'') as Text
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