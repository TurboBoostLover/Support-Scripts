USE [reedley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18571';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text';
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
DECLARE @Id int = 1605

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @TABLE TABLE (txt NVARCHAR(MAX), val int)
declare @sqlParts table (TableName nvarchar(max), SelectStatment nvarchar(max));
declare @sql nvarchar(max);
declare @results table (TextbookName varchar(max), TextbookAuthor varchar(max),TextbookPublicationYear varchar(max));
declare @attributes table (Attribute varchar(max), SortOrder int);
declare @partstemp table (TableName varchar(max), ColumnName varchar(max),Attribute varchar(max), SortOrder int);
insert into @attributes (Attribute,SortOrder)
values (''TextbookPublicationYear'',3),(''TextbookName'',1),(''TextbookAuthor'',2);
insert into @partstemp
select distinct TableName,isnull(ColumnName,''null'') as ColumnName,Attribute,a.SortOrder
from @attributes a
left join MetadataAttribute ma
        join MetaSelectedField msf on msf.MetadataAttributeMapId = ma.MetadataAttributeMapId
        join MetaAvailableField maf on maf.MetaAvailableFieldId = msf.MetaAvailableFieldId
        join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
        join Course c on c.MetaTemplateId = mss.MetaTemplateId AND c.Id = @entityId
    on ma.ValueText = a.Attribute and MetadataAttributeTypeId = 13
order by a.SortOrder
insert into @sqlParts(TableName,SelectStatment)
select distinct TableName, dbo.concatwithsepordered_agg('','',SortOrder,concat(ColumnName,'' as '', Attribute)) as SelectStatment
from (select isnull(TableName,(select top 1 TableName from @partstemp where TableName is not null)) as TableName, ColumnName, Attribute,SortOrder from @partstemp) s
group by TableName;
if (select count(*) from @sqlParts) = 1
begin
set @sql =(select concat(''select '', SelectStatment, '' from '', TableName,'' where CourseId = @entityId'') from @sqlParts);
insert into @results exec sp_executesql @sql, N''@entityId int'', @entityId = @entityId
end 
else 
begin
    select ''<span style="color:red;">There is an error in the configuration for textbooks.  This may prevent this course from uploading to ASSIST. Please contact CurrIQunet support</span>'' as Text
end 
INSERT INTO @TABLE
select ''<div style="display:table-row;border-bottom:1px solid;"><span style="display:table-cell;width:200px;">Textbook Name</span><span style="display:table-cell;width:200px;padding-left:2px;">Textbook Author</span><span style="display:table-cell;width:200px;padding-left:2px;">Textbook Publication Year</span></div>'' as Text, 0 as Value
union all
select concat(''<div style="display:table-row;border-bottom:1px solid;"><span style="display:table-cell;width:200px;">'',TextbookName,''</span><span style="display:table-cell;width:200px;padding-left:2px;">'',TextbookAuthor,''</span><span style="display:table-cell;width:200px;padding-left:2px;">'',TextbookPublicationYear,''</span></div>'') as Text, 0 as Value
from @results
union all
select ''</div>'' as Text, 0 as Value

SELECT 0 AS Value, dbo.ConcatWithSep_Agg('''', txt) AS Text from @TABLE
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