DECLARE @MAX int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

DECLARE @SQL NVARCHAR(MAX) = '

DROP TABLE if EXISTS #calculationResults
create table #calculationResults
(
    TableName sysname,
    Id int,
    Min decimal(16, 3),
    Max decimal(16, 3),
    IsVariable bit
);
	Exec upCalculateNestedCourseBlockEntries @entityId = 1340, @resultTable = ''#calculationResults'';

	SELECT 0 AS VALUE, 
	CONCAT(Min, 
		CASE 
			WHEN Max = MIN OR Max IS NULL 
				THEN '' 
			ELSE CONCAT('' - '', MAX)
		END
	) AS Text 
	FROM #calculationResults 
	WHERE TableName = ''CourseOption''
	'

INSERT INTO MetaForeignKeyCriteriaClient 
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Program', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Query for adhocreport', 2)

UPDATE AdHocReport 
SET Definition = CONCAT('{"id":"52","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"SC Programs (LH)","description":"Add Program Active check to conditions\n11/30/22-Add Effective Term (ProgramProposal --> Semster)\n12/12/22-Re-label column headers, remove Program.Proposal.Action Date; add Proposal Type Title","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Program ID","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Id"}},{"caption":"Program Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Title"}},{"caption":"Award Type Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"AwardTypeId_AwardType_Program.AwardTypeTitle"}},{"caption":"Tier 1 Org Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier1_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Program Active","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Active"}},{"caption":"Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"}},{"caption":"Created On","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.CreatedOn"}},{"caption":"TOP Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CB03_Program.Code"}},{"caption":"Program Control No.","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.UniqueCode2"}},{"caption":"Program Goal","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProgramTypeId_ProgramType_Program.ProgramTypeTitle"}},{"caption":"Program Require Note","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.RequireNote"}},{"caption":"Effective Term","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SemesterId_Semester_ProgramProposal.Title"}},{"caption":"Proposal Type Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProposalTypeId_ProposalType_Program.Title"}},{"caption":"Units","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Program.3"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"ClientId_Client_Program.Title"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"saddleback","text":"saddleback"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Program.Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL1_Program.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"',@MAX,'","text":"',@MAX,'"}]}]}}')
WHERE Id = 52