USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16881';
DECLARE @Comments nvarchar(Max) = 
	'Add text to COR when course is non-credit';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
	declare 
			@tshOverride int,
			@tshVariable int,
			@tshMinLecUnits decimal(16, 3),
			@tshMaxLecUnits decimal(16, 3),
			@tshMinLecHrOverride decimal(16, 3),
			@tshMaxLecHrOverride decimal(16, 3),
			@tshMinLabUnits decimal(16, 3),
			@tshMaxLabUnits decimal(16, 3),
			@tshMinLabHrOverride decimal(16, 3),
			@tshMaxLabHrOverride decimal(16, 3),
			@tshMinOtherUnits decimal(16, 3),
			@tshMaxOtherUnits decimal(16, 3),
			@tshMinOtherHrOverride decimal(16, 3),
			@tshMaxOtherHrOverride decimal(16, 3)
		;

		-- Get saved Values
		select 
			@tshOverride = cyn.YesNo05Id,
			@tshVariable = cyn.YesNo14Id,
			@tshMinLecUnits = cd.ShortTermLabHour,
			@tshMaxLecUnits = cd.SemesterHour,
			@tshMinLecHrOverride = cd.MinContactHoursClinical,
			@tshMaxLecHrOverride = cd.MaxContactHoursClinical,
			@tshMinLabUnits = cd.MinLabHour,
			@tshMaxLabUnits = cd.MaxLabHour,
			@tshMinLabHrOverride = cd.MinContactHoursLecture,
			@tshMaxLabHrOverride = cd.MaxContactHoursLecture,
			@tshMinOtherUnits = cd.MinOtherHour,
			@tshMaxOtherUnits = cd.MaxOtherHour,
			@tshMinOtherHrOverride = cd.MinUnitHour,
			@tshMaxOtherHrOverride = cd.MaxUnitHour
		from Course c
			inner join CourseYesNo cyn on c.Id = cyn.CourseId
			inner join CourseDescription cd on c.id = cd.CourseId
		where c.Id = @entityId;

		-- Calculations
		declare 
			@tshMinLecHr decimal(16, 3) = 
				case
					when @tshOverride = 1
						then @tshMinLecHrOverride
					else format((isNull(@tshMinLecUnits, 0) * 16), ''0.###'')
				end,
			@tshMaxLecHr decimal(16, 3) = 
				case
					when @tshOverride = 1
						then format(@tshMaxLecHrOverride, ''0.###'')
					when @tshVariable = 1
						then format((isNull(@tshMaxLecUnits, 0) * 18), ''0.###'')
					else format((isNull(@tshMinLecUnits, 0) * 18), ''0.###'')
				end,
			@tshMinLabHr decimal(16, 3) = 
				case
					when @tshOverride = 1
						then format(@tshMinLabHrOverride, ''0.###'')
					else format((isNull(@tshMinLabUnits, 0) * 48), ''0.###'')
				end,
			@tshMaxLabHr decimal(16, 3) = 
				case
					when @tshOverride = 1
						then format(@tshMaxLabHrOverride, ''0.###'')
					when @tshVariable = 1
						then format((isNull(@tshMaxLabUnits, 0) * 54), ''0.###'')
					else format((isNull(@tshMinLabUnits, 0) * 54), ''0.###'')
				end,
			@tshMinOtherHr decimal(16,3) = 
				case
					when @tshOverride = 1
						then format(@tshMinOtherHrOverride, ''0.###'')
					else format((isNull(@tshMinOtherUnits, 0) * 48), ''0.###'')--54), ''0.###'')
				end,
			@tshMaxOtherHr decimal(16,3) = 
				case
					when @tshOverride = 1
						then format(@tshMaxOtherHrOverride, ''0.###'')
					when @tshVariable = 1
						then format((isNull(@tshMaxOtherUnits, 0) * 54), ''0.###'')
					else format((isNull(@tshMinOtherUnits, 0) * 48), ''0.###'')--54), ''0.###'')
				end,
			@tshHoursdecimalFormat nvarchar(10) = concat(''F'', 3);

		declare
			@tshMinContactHr decimal(16, 3) 
				= format((isNull(@tshMinLecHr, 0) + isNull(@tshMinLabHr, 0) + isNull(@tshMinOtherHr, 0)), ''0.###''), 
			@tshMaxContactHr decimal(16, 3) 
				= format((isNull(@tshMaxLecHr, 0) + isNull(@tshMaxLabHr, 0) + isNull(@tshMaxOtherHr, 0)), ''0.###''), 
			@tshMinOutHr decimal(16, 3) = format((isNull(@tshMinLecHr, 0) * 2), ''0.###''),
			@tshMaxOutHr decimal(16, 3) = format((isNull(@tshMaxLecHr, 0) * 2), ''0.###'');
		declare
			@tshMintotalHr decimal(16, 3) = format((isNull(@tshMinContactHr, 0) + isNull(@tshMinOutHr, 0)), ''0.###''),
			@tshMaxTotalHr decimal(16, 3) = format((isNull(@tshMaxContactHr, 0) + isNull(@tshMaxOutHr, 0)), ''0.###'')

		-- Formatting
		select concat(format(@tshMintotalHr, ''0.###''), '' - '', format(@tshMaxTotalHr, ''0.###''),
		CASE WHEN cb.CB04Id = 3
		THEN 
		''<div>
    <label class="iq-data-field-label field-label">Institutional Student Learning Outcomes</label>
    <ol>
        <li>Social Responsibility
            <p>SDCCE students demonstrate interpersonal skills by learning and working cooperatively in a diverse environment.</p>
        </li>
        <li>Effective Communication
            <p>SDCCE students demonstrate effective communication skills.</p>
        </li>
        <li>Critical Thinking
            <p>SDCCE students critically process information, make decisions, and solve problems independently or cooperatively.</p>
        </li>
        <li>Personal and Professional Development
            <p>SDCCE students pursue short term and life-long learning goals, mastering necessary skills and using resource management and self-advocacy skills to cope with changing situations in their lives.</p>
        </li>
        <li>Diversity, Equity, Inclusion, Anti-racism and Access
            <p>SDCCE students critically and ethically engage with local and global issues using principles of equity, civility, and compassion as they apply their knowledge and skills: exhibiting awareness, appreciation, respect, and advocacy for diverse individuals, groups, and cultures.</p>
        </li>
    </ol>
</div>''
ELSE ''''
END) as [Text] FROM Course AS c LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id where c.Id = @EntityId;
'
WHERE Id = 128

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 128
)