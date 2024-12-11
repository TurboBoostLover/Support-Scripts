USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16647';
DECLARE @Comments nvarchar(Max) = 
	'Add back old data';
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
DELETE FROM ModuleModuleObjective WHERE ModuleId = 125

INSERT INTO ModuleModuleObjective
(ModuleId, MaxText01, MaxText02, SortOrder, ListItemTypeId, CreatedDate, ModuleStrategicGoalId)
VALUES
(125, 'Onboard new team member ', NULL, 0, 30, GETDATE(), 170),
(125, 'Recruit and hire position ', NULL, 1, 30, GETDATE(), 170),
(125, 'Input reorganization request into Workday, once position approved ', NULL, 2, 30, GETDATE(), 170),
(125, 'Gain approvals through appropriate channels ', NULL, 3, 30, GETDATE(), 170),
(125, 'Develop job description/responsibilities for a part-time Foundation Development Assistant focused on annual giving to Saddleback College programs, with primary dedication of time to Emeritus Institute donors', 'In progress', 4, 30, GETDATE(), 170),
(125, 'Develop annual calendar of events and activities', 'In progress', 5, 30, GETDATE(), 169),
(125, 'Identify prospects who can make an additional gift to achieve PC membership status', 'In progress', 6, 30, GETDATE(), 169),
(125, 'Monitor annual renewals', 'In progress', 7, 30, GETDATE(), 169),
(125, 'Presence on Foundation website for President’s Circle, including giving page', 'In progress', 8, 30, GETDATE(), 169),
(125, 'Create marketing materials', 'In progress', 9, 30, GETDATE(), 169),
(125, 'Encourage vice presidents, directors, and managers to enroll through payroll deduction giving', 'In progress', 10, 30, GETDATE(), 169),
(125, 'Identify prospects (individual and corporate)', 'In progress', 11, 30, GETDATE(), 169),
(125, 'Develop the “why”; identify specific areas of support. Identify giving levels and courtesies', 'In progress', 12, 30, GETDATE(), 169),
(125, 'Engage retired faculty and staff', 'In progress', 30, 30, GETDATE(), 168),
(125, 'Develop and launch Legacy Society', 'In progress', 14, 30, GETDATE(), 168),
(125, 'Host planned giving seminars', 'In progress', 15, 30, GETDATE(), 168),
(125, 'Identify contract professionals to manage planned giving efforts', 'Complete', 16, 30, GETDATE(), 168),
(125, 'Create planned giving prospect lists based on giving capacity and affinity', 'In progress', 17, 30, GETDATE(), 168),
(125, 'Procure planned giving software', 'Complete', 18, 30, GETDATE(), 167),
(125, 'Develop annual employee giving campaign:
Timeline for annual activities 1. Develop and Launch Employee Giving Campaign: Develop and launch a comprehensive, annual employee giving campaign for Saddleback College faculty and staff. 

2. Develop and Launch Planned Giving Program: Develop and launch planned giving program to secure legacy gifts to Saddleback College. 

3. Relaunch President’s Circle: rebrand and relaunch the President’s Circle for Saddleback College. 

4. Complete Foundation Reorganization #3: Complete a third reorganization that includes the addition of one part-time Foundation Development Assistant responsible for programmatic fundraising at the annual giving level.  

(annual campaign launch, celebration, wrap up, etc.) 

Identify the “why”; areas of support 

Identify annual goals 

Marketing materials 

Identify Ambassadors in each division/department 

Giving incentives/competition', 'In progress', 19, 30, GETDATE(), 167),
(125, 'Host round tables on employee giving that include faculty, classified professionals, directors, and managers to develop a plan that is inclusive and has campus-wide buy-in', 'In progress', 20, 30, GETDATE(), 167),
(125, 'Host inaugural Founders’ Giving Day in 2024', 'Complete', 21, 30, GETDATE(), 167)