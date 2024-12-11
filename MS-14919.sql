USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14919';
DECLARE @Comments nvarchar(Max) = 
	'Update Award Type and update Entity Titles';
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
UPDATE AwardType
SET Title = 'Associate of Science (AS-T) Degree for Transfer'
WHERE Id = 1740

	update MetaTemplate
	set PublicEntityTitleTemplateString = EntityTitleTemplateString;
 
	declare @entityTypeId int,
			@metaTemplateId int;
 
	declare entityTitle cursor for
	select mtt.EntityTypeId, mt.MetaTemplateId
	from MetaTemplateType mtt
		inner join MetaTemplate mt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId;
 
	open entityTitle;
 
	fetch next from entityTItle
	into @entityTypeId, @metaTemplateId;
 
	while @@fetch_status = 0
	begin;
		SELECT @entityTypeId, @metaTemplateId
		exec upCreateEntityTitle @entityTypeId = @entityTypeId, @metaTemplateId = @metaTemplateId;
		exec upCreatePublicEntityTitle @entityTypeId = @entityTypeId, @metaTemplateId = @metaTemplateId;
 
		fetch next from entityTItle
		into @entityTypeId, @metaTemplateId;
	end;
 
	close entityTitle;
	deallocate entityTitle;
--rollback
--commit