USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17288';
DECLARE @Comments nvarchar(Max) = 
	'Update Organization links';
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
DECLARE @DepHealth int = 142
DECLARE @SubHEAL int = 49
DECLARE @SubHLTH int = 332
DECLARE @DepHigh int = 143
DECLARE @SubABED int = 201
DECLARE @SubBIOL int = 17
DECLARE @SubHSEP int = 344
DECLARE @SubINTD int = 356
DECLARE @SubPHYN int = 80
DECLARE @DepHos int = 144
DECLARE @SubFDNT int = 314
DECLARE @DepInfo int = 145
DECLARE @SubComp int = 264
DECLARE @DepSkill int = 146
DECLARE @SubAGRI int = 132
DECLARE @SubCNCT int =262
DECLARE @SubELRN int =296
DECLARE @SubENGE int =38
DECLARE @SubINDT int = 348
DECLARE @SubMECT int = 379
DECLARE @SubPRTG int = 422

INSERT INTO OrganizationSubject
(OrganizationEntityId, SubjectId, StartDate)
VALUES
(@DepHealth, @SubHEAL, GETDATE()),
(@DepHealth, @SubHLTH, GETDATE()),
(@DepHigh, @SubABED ,GETDATE()),
(@DepHigh, @SubBIOL ,GETDATE()),
(@DepHigh, @SubHSEP ,GETDATE()),
(@DepHigh, @SubINTD ,GETDATE()),
(@DepHigh, @SubPHYN ,GETDATE()),
(@DepHos, @SubFDNT, GETDATE()),
(@DepInfo, @SubComp, GETDATE()),
(@DepSkill, @SubAGRI, GETDATE()),
(@DepSkill, @SubCNCT, GETDATE()),
(@DepSkill, @SubELRN, GETDATE()),
(@DepSkill, @SubENGE, GETDATE()),
(@DepSkill, @SubINDT, GETDATE()),
(@DepSkill, @SubMECT, GETDATE()),
(@DepSkill, @SubPRTG, GETDATE())