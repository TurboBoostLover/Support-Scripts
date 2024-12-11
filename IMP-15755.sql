use clovis

INSERT INTO LookupTypeGroup
(GroupName, GroupKey)
VALUES
('SUO', 'SUO')

DECLARE @ID INT = SCOPE_IDENTITY()

INSERT INTO LookupType
(Title, TableName, SortOrder, LookupTypeGroupId)
VALUES
('SUO''s', 'Lookup01', 3, @ID)

DECLARE @ID2 INT = SCOPE_IDENTITY()

INSERT INTO ClientLookupType
(ClientId, LookupTypeId, CustomTitle, DontManage)
VALUES
(1, @ID2, 'SUO''s', 1)