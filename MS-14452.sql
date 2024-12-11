USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14452';
DECLARE @Comments nvarchar(Max) = 
	'Update COR';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (17)		--comment back in if just doing some of the mtt's

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Course Content', 'Course', 'LectureOutline','Update'),
('Course Content', 'Course', 'LabOutline','Update2')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
DECLARE @TABLE TABLE (LEC NVARCHAR(MAX))
INSERT INTO @TABLE
SELECT 
LectureOutline
FROM Course
WHERE Id = @EntityId

UPDATE @TABLE SET LEC = replace(LEC, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&#39;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&quot;' collate Latin1_General_CS_AS, '""'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)

SELECT 0 AS Value, LEC AS Text FROM @TABLE
"

DECLARE @RSQL NVARCHAR(MAX) = "
DECLARE @TABLE TABLE (LEC NVARCHAR(MAX))
INSERT INTO @TABLE
SELECT 
LectureOutline
FROM Course
WHERE Id = @EntityId

UPDATE @TABLE SET LEC = replace(LEC, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&#39;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&quot;' collate Latin1_General_CS_AS, '""'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)

SELECT 0 AS Value, LEC AS Text FROM @TABLE
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
DECLARE @TABLE TABLE (LEC NVARCHAR(MAX))
INSERT INTO @TABLE
SELECT 
LabOutline
FROM Course
WHERE Id = @EntityId

UPDATE @TABLE SET LEC = replace(LEC, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&#39;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&quot;' collate Latin1_General_CS_AS, '""'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)

SELECT 0 AS Value, LEC AS Text FROM @TABLE
"

DECLARE @RSQL2 NVARCHAR(MAX) = "
DECLARE @TABLE TABLE (LEC NVARCHAR(MAX))
INSERT INTO @TABLE
SELECT
LabOutline
FROM Course
WHERE Id = @EntityId

UPDATE @TABLE SET LEC = replace(LEC, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&#39;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&quot;' collate Latin1_General_CS_AS, '""'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET LEC = replace(LEC, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)

SELECT 0 AS Value, LEC AS Text FROM @TABLE
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'COR CUSTOM SQL TO STRIP UNICODE', 2),
(@MAX2, 'Course', 'Id', 'Title', @CSQL2, @RSQL2, 'Order By SortOrder', 'COR CUSTOM SQL TO STRIP UNICODE', 2)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
, MetaPresentationTypeId = 103
, FieldTypeId = 5
, DefaultDisplayType = 'QueryText'
, MetaAvailableFieldId = 8898
, LabelStyleId = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX2
, MetaPresentationTypeId = 103
, FieldTypeId = 5
, DefaultDisplayType = 'QueryText'
, MetaAvailableFieldId = 8899
, LabelStyleId = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback