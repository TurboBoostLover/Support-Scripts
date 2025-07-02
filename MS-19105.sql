USE [butte];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19105';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text';
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
DECLARE @Id int = 163

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @innerText nvarchar(max)
    ,@totals nvarchar(max)
    ,@checkLect nvarchar(max)
    ,@checkAct nvarchar(max)
    ,@checkLectMax NVARCHAR(max)
    ,@checkActMax NVARCHAR(max);

Declare @isLect bit = (
			SELECT 
				IsRequired2
			FROM CourseProposal
			where CourseId = @entityId
		)

		Declare @isActivity bit = (
			SELECT 
				IsTBALAb
			FROM coursedescription
			where CourseId = @entityId
		)

SET @checkLect = (
    SELECT
        SUM(LabHours)
    FROM CourseOutline
    WHERE courseId = @EntityId
);
SET @checkAct = (
    SELECT
        SUM(LectureHours)
    FROM CourseOutline
    WHERE courseId = @EntityId
);

set @checkLectMax = (
    select sum(MaxLabHours)
    from CourseOutline
    where CourseId = @entityId
);

set @checkActMax = (
    select sum(MaxLectureHours)
    from CourseOutline
    where CourseId = @entityId
);

SET @innerText = (
SELECT
    STUFF((
        SELECT
            '' '' + CONCAT(
                ''<tr>''
                , ''<td colspan="8" style="padding-left:10%">''
                , COALESCE(LectureOutlineText, '''')
                , ''</td>''
                , CASE
		            WHEN @checkLect IS NOT NULL and @isLect = 1 THEN CONCAT(
                        ''<td colspan="2" style="text-align: left;">''
                        ,CAST(COALESCE(LabHours, 0) AS NVARCHAR(MAX))
                        ,case
                            when MaxLabHours is not null then concat('' - '',MaxLabHours)
                        end
                        ,''</td>''
                    )
		        ELSE ''''
	            END
                ,CASE
		            WHEN @checkAct IS NOT NULL and @isActivity = 1 THEN CONCAT(
                        ''<td colspan="2" style="text-align: left;">''
                        ,CAST(COALESCE(LectureHours, 0) AS NVARCHAR(MAX))
                        ,case
                            when MaxLectureHours is not null then concat('' - '',MaxLectureHours)
                        end
                        ,''</td>''
                    )
		            ELSE ''''
	            END
                ,''</tr>''
            )
        FROM CourseOutline
        WHERE CourseId = @EntityId
        ORDER BY SortOrder, Id
        FOR XML PATH(''''), TYPE).value(''.'', ''nvarchar(max)''), 1, 1, '''')
);

SET	@totals = (
    SELECT
        CONCAT(
            ''<tr>'', ''<td colspan="8" style="text-align: right; font-weight: bold;">'', ''Total Hours:'', ''</td> ''
            ,CASE
                WHEN @checkLect IS NOT NULL and @isLect = 1 THEN CONCAT(
                    ''<td colspan="2" style="text-align: left;">''
                    ,CAST(SUM(LabHours) AS NVARCHAR(MAX))
                    ,case
                        when sum(MaxLabHours) is not null then concat('' - '',cast(sum(MaxLabHours) as nvarchar(max)))
                    end
                    ,''</td>''
                )
				ELSE ''''
            END
            ,CASE
				WHEN @checkAct  IS NOT NULL and @isActivity = 1THEN CONCAT(
                    ''<td colspan="2" style="text-align: left;">''
                    ,CAST(SUM(LectureHours) AS NVARCHAR(MAX))
                    ,case
                        when sum(MaxLectureHours) is not null then concat('' - '',cast(sum(MaxLectureHours) as nvarchar(max)))
                    end
                    ,''</td>''
                )
				ELSE ''''
			END
            ,''</tr>''
        )
    FROM CourseOutline
    WHERE courseId = @entityId
);

if (@checkLect is not null or @checkAct is not null)    
begin
SELECT
	0 AS [Value]
   ,CONCAT(
       ''<table style="width:100%; table-layout: fixed;">''
        , ''<tr>''
        , ''<th colspan="8" style="padding-left: 10%"><u>Topics</u></th>''
        ,CASE
		    WHEN @checkLect IS NOT NULL and @isLect = 1 THEN ''<th colspan="2" style="text-align: left;"><u>Lec Hrs</u></th>''
		    ELSE ''''
	    END
        ,CASE
		    WHEN @checkAct IS NOT NULL and @isActivity = 1 THEN ''<th colspan="2" style="text-align: left;"><u>Act Hrs</u></th>''
		    ELSE ''''
	    END
        , ''</tr>''
        , @innerText
        , @totals
        ,''</table>''
    ) AS [Text];
END;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @SQL = '		--declare @entityId int = (5063);

		declare @innerText nvarchar(max);
		declare @totals nvarchar(max);
		declare @checkAct nvarchar(max);
		declare @checkLab nvarchar(max);
		declare @checkActMax nvarchar(max);
		declare @checkLabMax nvarchar(max);
		-------------------------------
		declare @isActivity bit = (
			select IsTBALAb
			from CourseDescription
			where CourseId = @entityId
		);

		--select @isActivity as isActivity;
		-------------------------------
		declare @isLab bit = (
			select LabSupportLecture
			from Course
			where Id = @entityId
		);

		--select @isLab as isLab;
		-------------------------------
		set @checkAct = (
			select sum(ContentPercent)
			from CourseLabContent
			where CourseId = @entityId
		);

		--select @checkAct as checkAct;
		-------------------------------
		set @checkLab = (
			select sum(ApproximatePercentage)
			from CourseLabContent
			where CourseId = @entityId
		);

		--select @checkLab as checkLab;
		-------------------------------
		set @checkActMax = (
			select sum(ContentPercentMax)
			from CourseLabContent
			where CourseId = @entityId
		);

		--select @checkActMax as checkActMax;
		-------------------------------
		set @checkLabMax = (
			select sum(ApproximatePercentageMax)
			from CourseLabContent
			where CourseId = @entityId
		);

		--select @checkLabMax as checkLabtMax;
		-------------------------------
		set @innerText = (
			select 
				dbo.ConcatWithSepOrdered_Agg('''', SortOrder
					, concat(
						coalesce(@innerText, '''')
						, ''<tr>''
							, ''<td colspan="8" style="padding-left:10%">''
								, coalesce(OutlineText, '''')
							,''</td>''
							, case
								when @checkLab is not null
								and @isLab = 1
									then
									concat(
										''<td colspan="2" style="text-align: left;">''
											, cast(coalesce(ApproximatePercentage, 0) as nvarchar(max))
											, case
												when @checkLabMax is not null
													then
													concat(
														'' - ''
														, ApproximatePercentageMax
													)
												else ''''
											end
										, ''</td>''
									)
								else ''''
							end
							, case
								when @checkAct is not null
								and @isActivity = 1
									then
									concat(
										''<td colspan="2" style="text-align: left;">''
											, cast(coalesce(ContentPercent, 0) as nvarchar(max))
											, case
												when @checkActMax is not null
													then
													concat(
														'' - ''
														, ContentPercentMax
													)
												else ''''
											end
										, ''</td>''
									)
								else ''''
							end
						,''</tr>''
					)
				)
			from CourseLabContent
			where CourseId = @entityId
		);

		set @totals = (
			select
				concat(
					''<tr>''
						, ''<td colspan="8" style="text-align: right; font-weight: bold;">''
							, ''Total Hours:''
						, ''</td>''
						, case
							when @checkLab is not null
							and @isLab = 1
								then concat(
									''<td colspan="2" style="text-align: left;">''
										, cast(sum(ApproximatePercentage) as nvarchar(max))
										, case
											when sum(ApproximatePercentageMax) is not null
												then
												concat(
													'' - ''
													, cast(sum(ApproximatePercentageMax) as nvarchar(max))
												)
											else ''''
										end
									, ''</td>''
								)
							else ''''
						end
						, case
							when @checkAct is not null
							and @isActivity = 1
								then concat(
									''<td colspan="2" style="text-align: left;">''
										, cast(sum(ContentPercent) as nvarchar(max))
										, case
											when sum(ContentPercentMax) is not null
												then
												concat(
													'' - ''
													, cast(sum(ContentPercentMax) as nvarchar(max))
												)
											else ''''
										end
									, ''</td>''
								)
							else ''''
						end
					,''</tr>''
				)
			from CourseLabContent
			where CourseId = @entityId
		);

		if (@checkLab is not null
			or @checkAct is not null
		)
		begin
			select 0 as [Value]
				, concat(
					''<table style="width:100%; table-layout: fixed;">''
						, ''<th colspan="8" style="padding-left:10%"><u>Topics</u></th>''
						, case
							when @checkLab is not null
							and @isLab = 1
								then ''<th colspan="2" style="text-align: left;"><u>Lab Hrs</u></th>''
							else ''''
						end
						, case
							when @checkAct is not null
							and @isActivity = 1
								then ''<th colspan="2" style="text-align: left;"><u>Act Hrs</u></th>''
							else ''''
						end
						, @innerText
						, @totals
					, ''</table>''
				) as [Text]
			;
		end;'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= 164

SET @SQL = 'declare @innerText nvarchar(max);
    declare @totals nvarchar(max);
    declare @checkLect nvarchar(max);
    declare @checkAct nvarchar(max);
	declare @checklectMax nvarchar(max);
    declare @checkActMax nvarchar(max);

Declare @isLect bit = (
			SELECT 
				IsRequired2
			FROM CourseProposal
			where CourseId = @entityId
		)

		Declare @isActivity bit = (
			SELECT 
				IsTBALAb
			FROM coursedescription
			where CourseId = @entityId
		)

		select @checkLect = (
			select sum(ApproximatePercentage) --Lab hours
			from CourseInstructionContent 
			where courseId = @entityId
		);

		select @checkAct = (
			select sum(ContentPercent) --Lab Activity
			from CourseInstructionContent 
			where courseId = @entityId
		);

SET @checkLect = (SELECT
			SUM(ApproximatePercentage)
		FROM CourseInstructionContent
		WHERE courseId = @entityId);
SET @checkLectMax = (SELECT
			SUM(Decimal01)
		FROM CourseInstructionContent
		WHERE courseId = @entityId);
SET @checkAct = (SELECT
			SUM(ContentPercent)
		FROM CourseInstructionContent
		WHERE courseId = @entityId);
SET @checkActMax = (SELECT
			SUM(Decimal02)
		FROM CourseInstructionContent
		WHERE courseId = @entityId);

SET @innerText = (SELECT STUFF((SELECT
			CONCAT(COALESCE(@innerText, ''''), ''<tr>'', ''<td colspan="8" style="padding-left:10%">'', COALESCE(ContentText, ''''), ''</td>'', CASE
		WHEN @checkLect IS NOT NULL and @isLect = 1 THEN CONCAT(''<td colspan="2" style="text-align: left;">'', 
						CAST(COALESCE(ApproximatePercentage, 0) AS NVARCHAR(MAX)),
                        case
                            when Decimal01 is not null then concat('' - '',convert(Decimal(10,2),Decimal01))
                        end
                        , ''</td>'')
		ELSE ''''
	END, CASE
		WHEN @checkAct IS NOT NULL and @isActivity = 1 THEN CONCAT(''<td colspan="2" style="text-align: left;">'', 
						CAST(COALESCE(ContentPercent, 0) AS NVARCHAR(MAX)),
                        case
                            when Decimal02 is not null then concat('' - '',convert(Decimal(10,2),Decimal02))
                        end
                        , ''</td>'')
		ELSE ''''
	END, ''</tr>'')
			from CourseInstructionContent
			where CourseId = @EntityId
			order by SortOrder
			FOR XML PATH (''''), TYPE)
	.value (''(./text())[1]'', ''NVARCHAR(MAX)''), 1, 0, ''''));
SET @totals = (SELECT
			CONCAT(''<tr>'', ''<td colspan="8" style="text-align: right; font-weight: bold;">'', ''Total Hours:'', ''</td>'', CASE
				WHEN @checkLect IS NOT NULL and @isLect = 1 THEN CONCAT(''<td colspan="2" style="text-align: left;">'', 
					CAST(SUM(ApproximatePercentage) AS NVARCHAR(MAX)), 
					CASE WHEN @checklectMax IS NOT NULL THEN CONCAT('' - '', Cast(SUM(convert(Decimal(10,2),Decimal01)) AS NVARCHAR(MAX))) 
					end,
					''</td>'')
				ELSE ''''
			END, CASE
				WHEN @checkAct IS NOT NULL and @isActivity = 1 THEN CONCAT(''<td colspan="2" style="text-align: left;">'', 
					CAST(SUM(ContentPercent) AS NVARCHAR(MAX)), 
					CASE WHEN @checkActMax IS NOT NULL THEN CONCAT('' - '', Cast(SUM(convert(Decimal(10,2),Decimal02,2)) AS NVARCHAR(MAX))) 
					end
					, ''</td>'')
				ELSE ''''
			END, ''</tr>'')
		FROM CourseInstructionContent
		WHERE courseId = @entityId);
      if ((@isLect = 1 and @checkLect is not null) or (@isActivity = 1 and @checkAct is not null) )    begin
SELECT
	0 AS [Value]
   ,CONCAT(''<table style="width:100%; table-layout: fixed;">'', ''<th colspan="8" style="padding-left:10%"><u>Topics</u></th>'', CASE
		WHEN @checkLect IS NOT NULL and @isLect = 1 THEN ''<th colspan="2" style="text-align: left;"><u>Ind Hrs</u></th>''
		ELSE ''''
	END, CASE
		WHEN @checkAct IS NOT NULL  and @isActivity = 1THEN ''<th colspan="2" style="text-align: left;"><u>Act Hrs</u></th>''
		ELSE ''''
	END, @innerText, @totals, ''</table>'') AS [Text];
END;'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= 225

SET @SQL = '
-- DECLARE @entityId INT = (5042);
DECLARE 
	@checkLect NVARCHAR(MAX), 
	@innerText NVARCHAR(MAX),
	@totals NVARCHAR(MAX),
	@checkMax NVARCHAR(MAX);

Declare @isLect bit = (
			SELECT 
				IsRequired2
			FROM CourseProposal
			where CourseId = @entityId
		)

SET @checkLect = 
	(
	SELECT CAST(SUM(Decimal01) AS DECIMAL)
	FROM CourseLookup13 
	WHERE CourseId = @entityId
	);

SET @checkMax = 
	(
	SELECT CAST(SUM(Decimal02) AS DECIMAL)
	FROM CourseLookup13
	WHERE CourseId = @entityId
	AND Bit01 = 1
	);

SET @innerText = 
	(
	SELECT STUFF
		(
			(
			SELECT
				CONCAT
					(
					  COALESCE(@innerText, '''')
					, ''<tr>''
					, ''<td colspan=''''8'''' style="padding-left:10%">''
					, COALESCE(MaxText01, '''')
					, ''</td>''
					, CASE WHEN @checkLect IS NOT NULL and @isLect = 1
					  THEN CONCAT
						(
						  ''<td colspan=''''2'''' style=''''text-align: left;''''>''
						, CAST(FORMAT(COALESCE(Decimal01, 0), ''###.00'') AS NVARCHAR(MAX))
						, ''</td>''
						)
					  ELSE ''''
					  END
					, CASE WHEN @checkMax > 0
					  THEN CONCAT
						(
						  ''<td colspan=''''2'''' style=''''text-align: left;''''>''
						, CAST(FORMAT(COALESCE(Decimal02, 0), ''###.00'') AS NVARCHAR(MAX))
						, ''</td>''
						)
					  ELSE ''''
					  END
					, ''</tr>''
					)
			FROM CourseLookup13
			WHERE CourseId = @entityId
			ORDER BY SortOrder
			FOR XML PATH (''''), 
			TYPE
			).value 
			(''(./text())[1]'', ''NVARCHAR(MAX)''), 
			1, 0, ''''
		)
	);

SET	@totals = 
	(
	SELECT 
		CONCAT
			(
			  ''<tr>''
			, ''<td colspan=''''8'''' style=''''text-align: right; font-weight: bold;''''>''
			, ''Total Hours:''
			, ''</td> ''
			, CASE WHEN @checkLect IS NOT NULL and @isLect = 1
			  THEN CONCAT
				(
				  ''<td colspan=''''2'''' style=''''text-align: left;''''>''
				, CAST(FORMAT(SUM(Decimal01), ''###.00'') AS NVARCHAR(MAX))
				, ''</td>''
				)
			  ELSE ''''
			  END
			, CASE WHEN @checkMax > 0
			  THEN CONCAT
				(
				  ''<td colspan=''''2'''' style=''''text-align: left;''''>''
				, CAST(FORMAT(SUM(Decimal02), ''###.00'') AS NVARCHAR(MAX))
				, ''</td>''
				)
			  ELSE ''''
			  END
			, ''</tr>''
			)
	FROM CourseLookup13
	WHERE CourseId = @entityId
	);

IF ((@isLect = 1 and @checkLect IS NOT NULL) OR @checkMax > 0)
BEGIN
	SELECT 
		  0 AS [Value]
		, CONCAT
			(
			  ''<table style=''''width:100%; table-layout: fixed;''''>''
			, ''<th colspan=''''8'''' style="padding-left:10%"><u>Topics</u></th>''
			, CASE WHEN @checkLect IS NOT NULL and @isLect = 1
			  THEN ''<th colspan=''''2'''' style=''''text-align: left;''''><u>Min Hrs</u></th>''
			  ELSE ''''
			  END
			, CASE WHEN @checkMax > 0
			  THEN ''<th colspan=''''2'''' style=''''text-align: left;''''><u>Max Hrs</u></th>''
			  ELSE ''''
			  END
			, @innerText
			, @totals
			, ''</table>''
			) AS [Text]
	;
END;'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= 231

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (@Id, 164, 225, 231)