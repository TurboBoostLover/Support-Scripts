USE [ccsf];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15234';
DECLARE @Comments nvarchar(Max) = 
	'Update GE Order';
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
UPDATE GeneralEducation
SET SortOrder = SortOrder + 1 
WHERE Id in (
802, 803, 804
)

UPDATE GeneralEducation
SET SortOrder = 2
WHERE Id = 805

UPDATE GeneralEducation
SET SortOrder = 6
WHERE Id = 806

UPDATE GeneralEducationElement 
SET SortOrder = 1
WHERE Id = 1537

UPDATE GeneralEducationElement 
SET SortOrder = 2
WHERE Id = 1538

UPDATE GeneralEducationElement 
SET SortOrder = 3
WHERE Id = 1598

UPDATE GeneralEducationElement 
SET SortOrder = 4
WHERE Id = 1597

UPDATE GeneralEducationElement 
SET SortOrder = 5
WHERE Id = 1540

UPDATE GeneralEducationElement 
SET SortOrder = 6
WHERE Id = 1541

UPDATE GeneralEducationElement 
SET SortOrder = 7
WHERE Id = 1542

UPDATE GeneralEducationElement 
SET SortOrder = 8
WHERE Id = 1543

UPDATE GeneralEducationElement 
SET SortOrder = 9
WHERE Id = 1544

UPDATE GeneralEducationElement 
SET SortOrder = 10
WHERE Id = 1545

UPDATE GeneralEducationElement 
SET SortOrder = 11
WHERE Id = 1546

UPDATE GeneralEducationElement 
SET SortOrder = 12
WHERE Id = 1547

UPDATE GeneralEducationElement 
SET SortOrder = 13
WHERE Id = 1596

UPDATE GeneralEducationElement 
SET SortOrder = 14
WHERE Id = 1603

UPDATE GeneralEducationElement 
SET SortOrder = 15
WHERE Id = 1604

UPDATE GeneralEducationElement 
SET SortOrder = 16
WHERE Id = 1605

UPDATE GeneralEducationElement 
SET SortOrder = 17
WHERE Id = 1606

UPDATE GeneralEducationElement 
SET SortOrder = 18
WHERE Id = 1607

UPDATE GeneralEducationElement 
SET SortOrder = 19
WHERE Id = 1608

UPDATE GeneralEducationElement 
SET SortOrder = 20
WHERE Id = 1609

UPDATE GeneralEducationElement 
SET SortOrder = 21
WHERE Id = 1610

UPDATE GeneralEducationElement 
SET SortOrder = 22
WHERE Id = 1611

UPDATE GeneralEducationElement 
SET SortOrder = 23
WHERE Id = 1612

UPDATE GeneralEducationElement 
SET SortOrder = 24
WHERE Id = 1613

UPDATE GeneralEducationElement 
SET SortOrder = 25
WHERE Id = 1548

UPDATE GeneralEducationElement 
SET SortOrder = 26
WHERE Id = 1549

UPDATE GeneralEducationElement 
SET SortOrder = 27
WHERE Id = 1550

UPDATE GeneralEducationElement 
SET SortOrder = 28
WHERE Id = 1551

UPDATE GeneralEducationElement 
SET SortOrder = 29
WHERE Id = 1552

UPDATE GeneralEducationElement 
SET SortOrder = 30
WHERE Id = 1553

UPDATE GeneralEducationElement 
SET SortOrder = 31
WHERE Id = 1554

UPDATE GeneralEducationElement 
SET SortOrder = 32
WHERE Id = 1555

UPDATE GeneralEducationElement 
SET SortOrder = 33
WHERE Id = 1556

UPDATE GeneralEducationElement 
SET SortOrder = 34
WHERE Id = 1591

UPDATE GeneralEducationElement 
SET SortOrder = 35
WHERE Id = 1567

UPDATE GeneralEducationElement 
SET SortOrder = 36
WHERE Id = 1599

UPDATE GeneralEducationElement 
SET SortOrder = 37
WHERE Id = 1602

UPDATE GeneralEducationElement 
SET SortOrder = 38
WHERE Id = 1568

UPDATE GeneralEducationElement 
SET SortOrder = 39
WHERE Id = 1569

UPDATE GeneralEducationElement 
SET SortOrder = 40
WHERE Id = 1570

UPDATE GeneralEducationElement 
SET SortOrder = 41
WHERE Id = 1571

UPDATE GeneralEducationElement 
SET SortOrder = 42
WHERE Id = 1572

UPDATE GeneralEducationElement 
SET SortOrder = 43
WHERE Id = 1573

UPDATE GeneralEducationElement 
SET SortOrder = 44
WHERE Id = 1595

UPDATE GeneralEducationElement 
SET SortOrder = 45
WHERE Id = 1584

UPDATE GeneralEducationElement 
SET SortOrder = 46
WHERE Id = 1585

UPDATE GeneralEducationElement 
SET SortOrder = 47
WHERE Id = 1586

UPDATE GeneralEducationElement 
SET SortOrder = 48
WHERE Id = 1587

UPDATE GeneralEducationElement 
SET SortOrder = 49
WHERE Id = 1600

UPDATE GeneralEducationElement 
SET SortOrder = 50
WHERE Id = 1592

UPDATE GeneralEducationElement 
SET SortOrder = 51
WHERE Id = 1593

UPDATE GeneralEducationElement 
SET SortOrder = 52
WHERE Id = 1594

UPDATE GeneralEducationElement 
SET SortOrder = 53
WHERE Id = 1614

UPDATE GeneralEducationElement 
SET SortOrder = 54
WHERE Id = 1615

UPDATE GeneralEducationElement 
SET SortOrder = 55
WHERE Id = 1616

UPDATE GeneralEducationElement 
SET SortOrder = 56
WHERE Id = 1617

UPDATE GeneralEducationElement 
SET SortOrder = 57
WHERE Id = 1618

UPDATE GeneralEducationElement 
SET SortOrder = 58
WHERE Id = 1619

UPDATE GeneralEducationElement 
SET SortOrder = 59
WHERE Id = 1620

UPDATE GeneralEducationElement 
SET SortOrder = 60
WHERE Id = 1621

UPDATE GeneralEducationElement 
SET SortOrder = 61
WHERE Id = 1622

UPDATE GeneralEducationElement 
SET SortOrder = 62
WHERE Id = 1623

UPDATE GeneralEducationElement 
SET SortOrder = 63
WHERE Id = 1624

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '			declare @now datetime = getdate();

			select gee.Id as [Value]
				, gee.Title as [Text]
				, ge.Id as filterValue
				, IsNull(gee.SortOrder, gee.Id) as SortOrder
				, IsNull(ge.SortOrder, ge.Id) as FilterSortOrder
			from GeneralEducation ge
				inner join GeneralEducationElement gee on ge.Id = gee.GeneralEducationId
			where (
				@now between gee.StartDate
				and IsNull(gee.EndDate, @now)
			)
			or exists (
				select 1
				from CourseGeneralEducation cge
				where gee.Id = cge.GeneralEducationElementId
				and cge.CourseId = @entityId
			)
			order by SortOrder, filterValue;'
WHERE Id = 67

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MEtaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 67
)