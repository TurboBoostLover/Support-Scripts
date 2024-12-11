use sbccd

UPDATE report.AgendaReportLayout
SET AttributesJson = '{
  "ListNumberStrategy": [
    { "Id": 1, "Level": 0, "NumberStyle": "roman", "UpperCase": 1 },
    { "Id": 2, "Level": 1, "NumberStyle": "alpha", "UpperCase": 0 },
    { "Id": 3, "Level": 2, "NumberStyle": "NONE", "UpperCase": 0 }
  ]
}
'
WHERE Id = 2

UPDATE report.AgendaReportSection
SET AttributesJson = '[{"Key":"valign","Value":"top"},{"Key":"colspan","Value":"2"}]'
WHERE Id = 18

UPDATE report.AgendaReportQuery
SET QueryText = '
SET @_entityData =( 
SELECT c.Id AS [Id],
(
	CASE 
		WHEN C.[IsDistanceEd] IS NULL or C.[IsDistanceEd] = 0 
			THEN dbo.fnHtmlStandardSimplefield(''Distance Ed'',''No'', NULL, NULL, '': '', 0 )
			ELSE dbo.fnHtmlStandardSimplefield(''Distance Ed'',''<span class="text-danger">Yes</span>'', NULL, NULL, '': '', 0 ) 
		END ) AS [DistanceEd],
( 
	CASE 
		WHEN (C.[IsDistanceEd] IS NULL or C.[IsDistanceEd] = 0) and ( (C.[IsSharedSCC] IS NULL or C.[IsSharedSCC] = 0) or (C.[IsShowFieldTrip] IS NULL or C.[IsShowFieldTrip] = 0) or (GB.[Bit04] IS NULL or GB.[Bit04] = 0 ) )
			THEN '''' 
			ELSE dbo.fnHtmlStandardSimplefield(''Delivery Method'',
				concat(
					case
						when C.[IsSharedSCC] = 1 
							then ''Fully Online'' 
							else '''' 
						end,
							case 
								when C.[IsSharedSCC] = 1 and (C.[IsShowFieldTrip] = 1 or GB.[Bit04] = 1) 
									then '', '' 
									else '''' 
								end,
									case 
										when C.[IsShowFieldTrip] = 1
										then ''Partially Online''
										else '''' 
										end,
									case 
									when C.[IsShowFieldTrip] = 1 and GB.[Bit04] = 1
									then '', '' 
									else '''' 
									end,
								case 
									when GB.[Bit04] = 1 
									then ''Online with In-Person Proctored Assessments'' 
									else ''''
									end)
, NULL, NULL, '': '', 0 ) END ) AS [DeliveryMethod]
FROM [course] c 
INNER JOIN [GenericBit] GB ON c.Id = GB.courseId
INNER JOIN @entity e ON c.Id = e.[EntityId] AND c.Id = @entityId
FOR JSON AUTO ); 

SET @_entitySummary = ( 
	SELECT CONCAT( dbo.fnHtmlOpenTag( ''div'', [dbo].[fnHtmlConcatTagAttributes](''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Course Basics"}]'', 0 ) ), 
	[DistanceEd],[DeliveryMethod], dbo.fnHtmlCloseTag(''div'') ) 
	FROM OPENJSON(@_entityData)
	WITH ( [DistanceEd] nvarchar(max) ''$.DistanceEd'', [DeliveryMethod]  nvarchar(max) ''$.DeliveryMethod'') ); 
	
	SELECT ( CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END ) AS [Text], @entityId AS [Value];
'
WHERE Id = 12

UPDATE report.AgendaReportQuery
SET QueryText = '

SET @_entityData =
	(
	SELECT 
		  t.Id AS [Id]
		, t.ReqTypeId AS [ReqTypeId]
		, CONCAT
			( 
			  dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'',''reqtype-title''))
			, ''<span class="text-danger">'',
			t.ReqTypeTitle,
			''</span>''
			, dbo.fnHtmlCloseTag(''div'')
			, dbo.ConcatOrdered_Agg(t.cr_Id, t.ReqText, 1)
			) AS [ReqText] 
	FROM 
		(
		SELECT 
			  c1.Id AS [Id]
			, rt.Id AS [ReqTypeId]
			, cr.Id AS [cr_Id]
			, COALESCE(rt.Title, ''No Requisite Type'') AS [ReqTypeTitle]
			, CONCAT
				(
				  dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''req-text''))
				, CONCAT
					( 
					  -- Requisite Type list items -- 
					  (
					  CASE	
					  /* 
					  When Subject and Requisite Course are chosen from dropdowns, 
					  and Requisite Comment textarea is filled out:
					  Show requisite course entity title and comment text
					  */
					  WHEN cr.Requisite_CourseId IS NOT NULL AND cr.EntrySkill IS NOT NULL 
					  THEN dbo.fnHtmlElement(''span'', CONCAT(c2.EntityTitle, '' - '', cr.EntrySkill), NULL)					  
					  /* 
					  When Subject and Requisite Course are chosen from dropdowns, 
					  but Requisite Comment textarea is blank: 
					  Show requisite course entity title 
					  */
					  WHEN cr.Requisite_CourseId IS NOT NULL AND cr.EntrySkill IS NULL
					  THEN dbo.fnHtmlElement(''span'', c2.EntityTitle, NULL) 					  				  
					  /* 
					  When Subject and Requisite Course dropdowns are blank, 
					  but Requisite Comment textarea is filled out:
					  Show comment text
					  */
					  WHEN cr.Requisite_CourseId IS NULL AND cr.EntrySkill IS NOT NULL 
					  THEN dbo.fnHtmlElement(''span'', cr.EntrySkill, NULL)					  
					  END
					  )
					  -- Non-Course Requirement list items -- 
					, (
					  CASE				  
					  /* 
					  When Non-Course Requirement textarea is filled out:
					  Show NCR text
					  */
					  WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN dbo.fnHtmlElement(''span'', cr.CourseRequisiteComment, NULL) 					  
					  END
					  )
					)
				, dbo.fnHtmlCloseTag(''div'') 
				) AS [ReqText] 
		FROM Course c1 
			INNER JOIN CourseRequisite cr ON c1.Id = cr.CourseId
			LEFT JOIN Course c2 ON cr.Requisite_CourseId = c2.Id
			LEFT JOIN Subject s ON s.Id = c2.SubjectId 
			LEFT JOIN StatusAlias sa ON sa.Id = c2.StatusAliasId
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
			INNER JOIN @entity e ON c1.Id = e.EntityId AND c1.Id = @entityId 
		) AS t 
	GROUP BY Id, ReqTypeId, ReqTypeTitle
	FOR JSON AUTO 
	) 
SET @_entitySummary = 
	(
	SELECT 
		CONCAT
			(
			  dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlConcatTagAttributes(''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Course Requisites"}]'', 0))
			, CASE 
			  WHEN dbo.Concat_Agg([ReqText]) IS NULL 
			  THEN '''' 
			  ELSE dbo.fnHtmlStandardSimplefield(''<span class="text-danger"><b>Requisites</b></span>'', dbo.Concat_Agg([ReqText]), NULL, NULL, '': '', 0) 
			  END
			, dbo.fnHtmlCloseTag(''div'') 
			) 
	FROM OPENJSON(@_entityData) 
	WITH ([ReqText] NVARCHAR(MAX) ''$.ReqText'') 
	);
SELECT 
	  (
	  CASE 
	  WHEN @_entitySummary IS NULL 
	  THEN '' '' 
	  ELSE @_entitySummary 
	  END
	  ) AS [Text]
	, @entityId AS [Value];

'
WHERE Id = 5


UPDATE report.AgendaReportSection
SET Title = 'Call to Order/Committee Members'
WHERE Id = 14

UPDATE report.AgendaReportSection
SET Title = 'Action Items'
, SortOrder = 3
WHERE Id = 18

UPDATE report.AgendaReportSection
SET Title = 'Operational Issues'
, SortOrder = 4
WHERE Id = 22

UPDATE report.AgendaReportSection
SET SortOrder = 3
WHERE Id = 23

delete from report.AgendaReportLayoutMapping
WHERE AgendaReportSectionId in (16, 17, 19, 20, 21, 24)

delete from report.AgendaReportQueryMapping
WHERE AgendaReportSectionId in (16, 17, 19, 20, 21, 24)

delete FROM report.AgendaReportSection
WHERE Id in (16, 17, 19, 20, 21, 24)