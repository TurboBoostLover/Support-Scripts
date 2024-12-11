USE victorvalley;

/*
   Commit
							Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15052';
DECLARE @Comments nvarchar(Max) = 'Blacklist cloning ';
DECLARE @Developer nvarchar(50) = 'Nathan W';
DECLARE @ScriptTypeId int = 1; 
/*  
Default for @ScriptTypeId on this script 
is 1 for  Support,  
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

/*
--------------------------------------------------------------------
Please do not alter the script above this comment except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing something 
		 that is against meta best practices, but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the 
		 word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql
-----------------Script details go below this line------------------
*/

--SELECT * FROM MetaSelectedField WHERE MetaSelectedFieldId = 17996
--SELECT * FROM MetadataAttributeMap WHERE Id = 1034
--SELECT * FROM MetadataAttribute
--SELECT * FROM MEtaData

declare @Fields integers
insert into @Fields
select mss.MetaSelectedSectionId
from MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType As mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mss2.MetaSelectedSection_MetaSelectedSectionId IS NULL
AND mss2.SectionName = 'Co-Contributor(s)'	
and msf.MetadataAttributeMapId IS NULL
AND mtt.EntityTypeId = 1
AND mss.MetaBaseSchemaId = 210


declare @MetadataAttributeMap integers

while exists(select top 1 1 from @Fields)
begin

	insert into MetadataAttributeMap
	output inserted.Id into @MetadataAttributeMap
	default values

	delete @Fields
	where id in (select top 1 id from @Fields)

end

insert into @Fields
select mss.MetaSelectedSectionId
from MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType As mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mss2.MetaSelectedSection_MetaSelectedSectionId IS NULL
AND mss2.SectionName = 'Co-Contributor(s)'
and msf.MetadataAttributeMapId IS NULL
AND mtt.EntityTypeId = 1
AND mss.MetaBaseSchemaId = 210

insert into MetadataAttribute
(Description,ValueText,MetadataAttributeTypeId,MetadataAttributeMapId,DataType)
select
'BlacklistDoNotClone','BlacklistDoNotClone',20,id,'Text'
from @MetadataAttributeMap

update MSS 
set MetadataAttributeMapId = B.Id
from MetaSelectedSection MSS
inner join (
	select mss.MetaSelectedSectionId,ROW_NUMBER() OVER (ORDER BY mss.MetaSelectedSectionId) as RowN
from MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType As mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mss2.MetaSelectedSection_MetaSelectedSectionId IS NULL
AND mss2.SectionName = 'Co-Contributor(s)'
and msf.MetadataAttributeMapId IS NULL
AND mtt.EntityTypeId = 1
AND mss.MetaBaseSchemaId = 210

) A on A.MetaSelectedSectionId = MSS.MetaSelectedSectionId
inner join (
	select id, ROW_NUMBER() OVER (ORDER BY id) as RowN
	from @MetadataAttributeMap
) B on A.RowN = B.RowN

update MT
set LastUpdatedDate = GETDATE()
from MetaTemplate MT
	inner join MetaSelectedSection MSS on MT.MetaTemplateId = MSS.MetaTemplateId
	inner join MetaSelectedField MSF on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
	inner join @Fields F on MSF.MetaSelectedFieldId = F.Id