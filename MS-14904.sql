USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14904';
DECLARE @Comments nvarchar(Max) = 
	'Update Adhoc report';
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
UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = '
SELECT DISTINCT C.Id AS Value,
           CASE
               WHEN CYN.YesNo03Id = 1
                    OR (C.IsDistanceEd = 1
										and c.ID in (
SELECT C.Id
FROM Course AS C
INNER JOIN MetaTemplate AS mt on c.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 1744))
               THEN
						CASE
							WHEN C.Id in (SELECT CourseId from CourseDistanceEducationDeliveryMethod WHERE CourseId = @ENtityId and DeliveryMethodId in (2,11))
							THEN ''DE''
						ELSE ''Partial''
						END
						ELSE ''Not DE''
           END
        AS Text
FROM Course C
LEFT JOIN CourseYesNo CYN ON C.Id = CYN.CourseId
LEFT JOIN CourseDistanceEducationDeliveryMethod CDE on CDE.CourseId = C.Id
WHERE C.ID = @EntityId
'
WHERE Id = 454

UPDATE AdHocReport
SET Definition = '{"id":"173","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Active Course Report w/o DE","description":"This provides the active courses that do not include DE.","outputFormatId":"1","isPublic":true,"columns":[{"caption":"Course Subject Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SubjectId_Subject_Course.SubjectSubjectCode"}},{"caption":"Course Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Title"}},{"caption":"Course.Proposal Implement Date","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProposalId_Proposal_Course.ImplementDate"}},{"caption":"Course Client Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ClientId_Client_Course.ClientTitle"}},{"caption":"Course Is Distance Ed","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL_Course.Text"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"active","text":"active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Course.Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL_Course.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"       454","text":"       454"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"NotStartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL_Course.Text"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"DE","text":"DE"}]}]}}'
WHERE Id = 173