USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15748';
DECLARE @Comments nvarchar(Max) = 
	'Update ProgramCode since there where some wrong inputs';
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
UPDATE ProgramCode
SET Code = 
    CASE 
        WHEN ID in (497, 526, 516, 83, 133, 84, 89, 90, 91, 92, 105, 134, 106, 107, 108, 300, 527, 109, 110, 111, 488, 112, 503, 113, 114, 495, 115, 116, 539, 541, 117, 67, 440, 118, 420, 119, 506, 120, 446, 121, 122, 504, 123, 452, 538, 502, 126, 135, 127, 451, 566, 490, 128, 442, 340, 563, 517, 130, 131) THEN 1
        WHEN ID in (498, 4, 574, 5, 6, 7, 43, 42, 8, 9, 10, 11, 12, 564, 13, 14, 520, 44, 45, 15, 449, 220, 16, 546, 17, 575, 18, 540, 20, 565, 140, 484, 545, 23, 493, 450, 525, 25, 512, 260, 48, 26, 27, 28, 29, 30, 124, 570, 543, 31, 32, 33, 34, 567, 35, 562, 36, 46, 532, 569, 47, 38, 39, 513, 280, 572, 515, 491) THEN 2
        WHEN ID in (499, 542, 51, 555, 548, 56, 533, 534, 57, 553, 554, 58, 482, 61, 571, 524, 62, 63, 64, 547, 561, 65, 560, 568, 530, 59, 66, 550, 556, 519, 536, 573, 76, 514, 500, 492, 29, 320, 509, 537, 551, 78, 557, 558, 567, 559, 342, 82, 510, 552) THEN 3
        ELSE 4
    END

UPDATE ProgramCode
SET EndDate = GETDATE()
WHERE Id = 131

UPDATE ProgramCode
SET Title = 'Education'
WHERE Id = 575

UPDATE ProgramCode
SET Title = 'Humanities'
WHERE Id = 525

UPDATE ProgramCode
SET Title = 'Visual and Performing Arts'
WHERE Id = 526

UPDATE ProgramCode
SET Title = 'Radio Frequency Technology'
WHERE Id = 490

UPDATE ProgramCode
SET Title = 'Sustainability'
WHERE Id = 528

UPDATE pc
SET Title = CONCAT(pc.Title, ' (', c.Title, ')')
FROM ProgramCode AS pc
INNER JOIN Campus AS c on pc.Code = c.Id