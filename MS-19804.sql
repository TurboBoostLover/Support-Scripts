USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19804';
DECLARE @Comments nvarchar(Max) = 
	'Update Adhoc report with custom query to remove duplicates';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
DECLARE @SQL NVARCHAR(MAX) = '
SELECT 
	  0 AS Value
	, CASE
		WHEN dbo.ConcatWithSep_Agg('', '', esk.Title) IS NULL THEN ''empty''
		ELSE dbo.ConcatWithSep_Agg('', '', esk.Title) 
	  END AS Text
	, CASE
		WHEN dbo.ConcatWithSep_Agg('', '', ftreq.Title) IS NULL THEN ''empty''
		ELSE dbo.ConcatWithSep_Agg('', '', ftreq.Title) 
	  END AS [Unit Type]
	, CONCAT(''https://nu.curriqunet.com/Form/Course/Index/'', c.Id) AS [CNET Link]
	, oe.Title AS [Department]
	, oe2.Code AS [School]
FROM Course c
	LEFT JOIN CourseEntrySkill cesk ON cesk.CourseId = c.Id
	LEFT JOIN EntrySkill esk ON cesk.EntrySkillId = esk.Id
	LEFT JOIN CourseDescription cdesc ON cdesc.CourseId = c.Id
	LEFT JOIN FieldTripRequisite ftreq ON cdesc.FieldTripReqsId = ftreq.Id
	LEFT JOIN OrganizationSubject AS os on c.SubjectId = os.SubjectId and os.Active = 1
	LEFT JOIN OrganizationEntity AS oe on os.OrganizationEntityId = oe.Id and oe.Active = 1
	LEFT JOIN OrganizationLink AS ol on ol.Child_OrganizationEntityId = oe.Id
	LEFT JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id
WHERE c.Id = @EntityId
GROUP BY c.Id, oe.Title, oe2.Code;
'

UPDATE AdHocReport
SET Definition = '{"id":"94","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Active Courses Report","description":"","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Course Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"}},{"caption":"Prefix","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SubjectId_Subject_Course.SubjectSubjectCode"}},{"caption":"Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Title"}},{"caption":"School","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.6"}},{"caption":"Department","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.5"}},{"caption":"Proposal Type","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProposalType_Course.Title"}},{"caption":"Modality","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL_Course.Text"}},{"caption":"Unit Type","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.3"}},{"caption":"CNET Link","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.4"}},{"caption":"Course Description","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Description"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Active","text":"Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL_Course.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"34","text":"34"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"InList","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"DepartmentInfo_Course.Division_Code"},{"typeName":"CONST","dataType":"String","kind":"List","value":"SOHP,SOPSS,SOALS,COLPS,SOBE,SOTE,SCOE","text":"SOHP,SOPSS,SOALS,COLPS,SOBE,SOTE,SCOE"}]},{"justAdded":false,"typeName":"SMPL","enabled":false,"operatorID":"InList","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"DepartmentInfo_Course.Department_Title"},{"typeName":"CONST","dataType":"String","kind":"List","value":"Advanced Graduate Studies,Arts and Humanities,ABA School Psychology Educational Counseling,Computer Science & Cyber Security,Data Science & Analytics,Extended Learning Engineering,Finance Economics Marketing & Accounting,Global Innovation SEL & Educational Technology,Healthcare Leadership,Health Services,JFK School of Law,(Leadership,Management,& Human Capital),Mathematics & Natural Sciences,Nursing,Organizational Leadership & Educational Administration,School of Public Service,Psychology,SOPSS - Social & Behavioral Sciences,Social & Psychological Sciences,Special Education,Teacher Education,Technology Management IT/IS,University Academics,NCU - Department","text":"Advanced Graduate Studies,Arts and Humanities,ABA School Psychology Educational Counseling,Computer Science & Cyber Security,Data Science & Analytics,Extended Learning Engineering,Finance Economics Marketing & Accounting,Global Innovation SEL & Educational Technology,Healthcare Leadership,Health Services,JFK School of Law,(Leadership,Management,& Human Capital),Mathematics & Natural Sciences,Nursing,Organizational Leadership & Educational Administration,School of Public Service,Psychology,SOPSS - Social & Behavioral Sciences,Social & Psychological Sciences,Special Education,Teacher Education,Technology Management IT/IS,University Academics,NCU - Department"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"DepartmentInfo_Course.Department_Active"}]}]}}'
WHERE Id = 94

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 34