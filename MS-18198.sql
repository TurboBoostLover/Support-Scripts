USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18198';
DECLARE @Comments nvarchar(Max) = 
	'Update Comprehensive PR';
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
Please do not alter the script above this comment� except to set
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
	@Entitytypeid int =6; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (40)		--comment back in if just doing some of the mtt's

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
('Equity and Success Metrics - Summary of Key Takeaways and Conclusions', 'GenericMaxText', 'TextMax01','1'),
('Equity and Success Metrics - Summary of Key Takeaways and Conclusions', 'GenericMaxText', 'TextMax05','2')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE ProposalType
SET Title = 'Comprehensive PSR - Student Support/Services'
WHERE Id = 48

UPDATE ProposalType
SET Title = 'Comprehensive PSR - Student Support/Services Modification'
WHERE Id = 49

UPDATE MetaSelectedSection
SET SectionDescription = '
<h6><b>The objectives of this section of Program and Services Review are:</b></h6> 
<ol>
	<li>To serve as evidence for Accreditation STANDARD 2.7: The institution designs and delivers equitable and effective services and programs that support students in their unique educational journeys, address academic and non-academic needs, and maximize their potential for success. Such services include library and learning resources, academic counseling and support, and other services the institution identifies as appropriate for its mission and student needs. (ER 15, ER 17)]</li>
    <li>To serve as evidence for Accreditation STANDARD 2.8: The institution conducts systematic review and assessment to ensure the quality of its academic, learning support, and student services programs and implement improvements and innovations in support of equitable student achievement. (ER 11, ER 14)]</li>
    <li>To serve as evidence for Accreditation STANDARD 2.9: The institution fosters a sense of belonging and community with its students by providing multiple opportunities for engagement with the institution, programs, and peers. Such opportunities reflect the varied needs of the student population and effectively support students� unique educational journeys. (ER 15)]</li>
    <li>To evaluate the effectiveness of the student support services available to Chaffey students</li>
    <li>To use the analysis of success metrics and equity data to inform strategic planning</li>
</ol>
<div class="fs-4">Summary of Key Takeaways and Conclusions</div>
<p>This section is intended for programs to briefly summarize key points from data-coaching sessions and any follow-up conversations. PSR Coaches are responsible for providing a detailed record of data-coaching sessions and data analysis, as well as any supporting
documents, in the Equity and Success Metrics - Data Analysis tab.
'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedSection
SET SectionDescription = 'If you cannot address a question because your program does not have the data, please write in "Data unavailable in the text box."'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '1'
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback