USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18860';
DECLARE @Comments nvarchar(Max) = 
	'Update Units and Hours to round to nearest .5';
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
DEclare @clientId int = 1,
	@Entitytypeid int = 1;

declare @templateId integers

insert into @templateId
select mt.MetaTemplateId
from MetaTemplateType mtt
inner join MetaTemplate mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
where mtt.EntityTypeId = @Entitytypeid
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate is NULL
and mtt.active = 1
and mtt.IsPresentationView = 0
and mtt.ClientId = @clientId


Declare @newformula table (avaiablefield int, formula nvarchar(max))
Insert into @newformula (avaiablefield, formula)
Values
(189,'if ([2] == 7 || [2] == 11) {
  if ([3] == 4) {
    Math.round([4] * 32 * 2) / 2;
  } else {
    Math.round([1] * 32 * 2) / 2;
  }
} else if ([2] == 19) {
  if ([3] == 4) {
    Math.round([4] * 24 * 2) / 2;
  } else {
    Math.round([1] * 24 * 2) / 2;
  }
} else {
  Math.round(0 * 2) / 2;}'),
(166,'if ([2] == 7 || [2] == 11) {
  if ([3] == 4) {
    Math.round([4] * 32 * 2) / 2;
  } else {
    Math.round([1] * 32 * 2) / 2;
  }
} else if ([2] == 19) {
  if ([3] == 4) {
    Math.round([4] * 24 * 2) / 2;
  } else {
    Math.round([1] * 24 * 2) / 2;
  }
} else {
  Math.round(0 * 2) / 2;}
'),
(1866,'if ([4] == 4) {
  Math.round([5] * 54 * 2) / 2;
} else if (~[8, 9, 10, 11].indexOf([2])) {
  Math.round([6] * 54 * 2) / 2;
} else {
  Math.round(0 * 2) / 2;}'),
(207,'if ([3] == 4) {
  Math.round([4] * 18 * 2) / 2;
} else {
  Math.round([1] * 18 * 2) / 2;}
'),
(206,'if ([2] == 4) {
  Math.round([3] * 54 * 2) / 2;
} else {
  Math.round([1] * 54 * 2) / 2;}
'),
(183,'if ([2] == 4) {
  Math.round([3] * 48 * 2) / 2;
} else {
  Math.round([1] * 48 * 2) / 2;}
'),
(187,'if ([2] == 4) {
  Math.round([3] * 60 * 2) / 2;
} else {
  Math.round(([1] + [4]) * 60 * 2) / 2;}
'),
(177,'if ([2] == 4) {
  Math.round([3] * 75 * 2) / 2;
} else {
  Math.round([1] * 75 * 2) / 2;}
'),
(165,'if ([2] == 7 || [2] == 11) {
  if ([3] == 4) {
    Math.round([4] * 36 * 2) / 2;
  } else {
    Math.round([1] * 36 * 2) / 2;
  }
} else if ([2] == 19) {
  if ([3] == 4) {
    Math.round([4] * 27 * 2) / 2;
  } else {
    Math.round([1] * 27 * 2) / 2;
  }
} else {
  Math.round(0 * 2) / 2;}
'),
(1855,'let zero = ([3] == 4) ? [5] * 18 : [2] * 18;
let two = ([3] == 4) ? [5] * 54 : [0] * 54;
let three = ([4] == 7 || [4] == 11) 
    ? ([3] == 4 ? [5] * 36 : [2] * 36)
    : ([4] == 19 
        ? ([3] == 4 ? [5] * 27 : [2] * 27)
        : 0);

if ([4] == 7 || [4] == 15) {
  Math.round((zero + three) * 2) / 2;
} else if ([4] == 8 || [4] == 9 || [4] == 10 || [4] == 16 || [4] == 17 || [4] == 18) {
  Math.round([1] + three * 2) / 2;
} else if ([4] == 11) {
  Math.round((zero + [1] + three) * 2) / 2;
} else if ([4] == 19) {
  Math.round((two + three) * 2) / 2;
} else if ([4] == 12 || [4] == 13) {
  Math.round(three * 2) / 2;
} else if ([4] == 14) {
  Math.round((zero + two + three) * 2) / 2;
} else {
  Math.round(0 * 2) / 2;}
'),
(179,'let zero = ([4] == 4) ? [2] * 16 : [3] * 16;
let one = ([4] == 4) ? [1] * 48 : (~[8, 9, 10, 11].indexOf([5])) ? [6] * 48 : 0;
let two = ([4] == 4) ? [2] * 48 : [0] * 48;
let three = ([4] == 4) ? [2] * 60 : [3] * 60;
let four = ([5] == 7 || [5] == 11) ? ([4] == 4 ? [2] * 32 : [3] * 32) : ([5] == 19 ? ([4] == 4 ? [2] * 24 : [3] * 24) : 0);

if ([5] == 7 || [5] == 15) {
  Math.round((zero + four) * 2) / 2;
} else if ([5] == 8 || [5] == 9 || [5] == 10 || [5] == 16 || [5] == 17 || [5] == 18) {
  Math.round((one + four) * 2) / 2;
} else if ([5] == 11) {
  Math.round((zero + one + four) * 2) / 2;
} else if ([5] == 19) {
  Math.round((two + four) * 2) / 2;
} else if ([5] == 12) {
  Math.round((three + four) * 2) / 2;
} else if ([5] == 13) {
  Math.round(four * 2) / 2;
} else if ([5] == 14) {
  Math.round((zero + two) * 2) / 2;
} else {
  Math.round(0 * 2) / 2;}
'),
(174,'if ([2] == 4) {Math.round([3] * 48 * 2) / 2;} else {Math.round([1] * 48 * 2) / 2;}'),
(170, 'if ([5] == 7 || [5] == 15) {Math.round(([0] + [4]) * 2) / 2} else if ([5] == 8 || [5] == 9 || [5] == 10 || [5] == 16 || [5] == 17 || [5] == 18) {Math.round(([1] + [4]) * 2) / 2} else if ([5] == 11) {Math.round(([0] + [1] + [4]) * 2) / 2} else if ([5] == 19) {Math.round(([2] + [4]) * 2) / 2} else if ([5] == 12) {Math.round(([3] + [4]) * 2) / 2} else if ([5] == 13) {Math.round([4] * 2) / 2} else if ([5] == 14) {Math.round(([0] + [2]) * 2) / 2} else { 0 }'),
(175, 'if([3] == 4) {Math.round([4] * 16 * 2) / 2} else {Math.round([1] * 16 * 2) / 2}'),
(173, 'if([4] == 4) {Math.round([5] * 54 * 2) / 2} else if (~[8, 9, 10, 11].indexOf([2])) {Math.round([6] * 54 * 2) / 2} else {0}'),
(184, 'if([3] == 4) {Math.round([4] * 16 * 2) / 2} else {Math.round([1] * 16 * 2) / 2}'),
(182, 'if([4] == 4) {Math.round([5] * 48 * 2) / 2} else if (~[8, 9, 10, 11].indexOf([2])) {Math.round([6] * 48 * 2) / 2} else {0}')



Update MetaFieldFormula
set Formula = nf.formula
From MetaFieldFormula mff
	inner join MetaSelectedField msf on mff.MetaSelectedFieldId = msf.MetaSelectedFieldId
	inner join @newformula nf on msf.MetaAvailableFieldId = nf.avaiablefield
	inner join MetaSelectedsection mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mss.MetaTemplateId in (select Id from @templateId)

Update MetaTemplate
set LastUpdatedDate = GETDATE()
From MetaTemplate mt
	inner join MetaSelectedSection mss on mt.MetaTemplateId = mss.MetaTemplateId
	inner join MetaSelectedField msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	inner join @newformula nf on msf.MetaAvailableFieldId = nf.avaiablefield
WHERE mt.MetaTemplateId in (select Id from @templateId)