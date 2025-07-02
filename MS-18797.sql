USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18797';
DECLARE @Comments nvarchar(Max) = 
	'Update Courses from Normal Proposal Types and Forms to General Education Proposal Types and their forms';
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
UPDATE Course
SET ProposalTypeId = 557
, MetaTemplateId = 816
WHERE Id in (
150878,
150877,
150902,
150876,
150875,
144685,
144684,
146351,
147257,
147256,
150439,
150373,
149093,
150372,
150371,
144351,
147392,
147391,
147390,
142578,
150880,
145128,
145732,
147658,
142872,
149144,
147254,
147253,
146563,
143857,
143831,
143830,
142770,
142769,
150381,
147111,
148780,
145272,
146315,
146301,
146300,
146299,
146298,
143296,
143084,
143083,
143082,
143081,
144559,
149145,
143913,
143911,
146002,
150252,
150257,
143742,
143741,
150835,
143829,
144313,
145010,
143578
)