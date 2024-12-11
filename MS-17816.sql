--INSERT INTO MetaSelectedFieldRolePermission
--(MetaSelectedFieldId, RoleId, AccessRestrictionType)
--VALUES



----Admin 1
----User 4

----Visable 1
----Edit 2


INSERT INTO ItemType
(Title, StartDate, SortOrder, ClientId, ItemTableName)
VALUES
('Approved', GETDATE(), 0, 1, 'CourseGeneralEducation'),
('Denied', GETDATE(), 1, 1, 'CourseGeneralEducation')

INSERT INTO GeneralEducation
(Title, StartDate, SortOrder, ClientId)
VALUES
('Reedley College General Education', GETDATE(), 1, 1)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, StartDate, ClientId, SortOrder)
VALUES
(@Id, 'Area 1A: English Composition', GETDATE(), 1, 0),
(@Id, 'Area 1B: Oral Communication/Critical Thinking', GETDATE(), 1, 1),
(@Id, 'Area 2: Mathematical Concepts and Quantitative Reasoning', GETDATE(), 1, 2),
(@Id, 'Area 3: Arts and Humanities', GETDATE(), 1, 3),
(@Id, 'Area 4: Social and Behavioral Sciences', GETDATE(), 1, 4),
(@Id, 'Area 5: Natural Sciences', GETDATE(), 1, 5),
(@Id, 'Area 6: Ethnic Studies', GETDATE(), 1, 6),
(@Id, 'Area 7A: Lifetime Skills', GETDATE(), 1, 7),
(@Id, 'Area 7B: Physical Education', GETDATE(), 1, 8)

INSERT INTO GeneralEducation
(Title, StartDate, SortOrder, ClientId)
VALUES
('California General Education Transfer Curriculum', GETDATE(), 2, 1)

DECLARE @Id2 int = SCOPE_IDENTITY()

INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, StartDate, ClientId, SortOrder)
VALUES
(@Id2, 'Area 1A: English Composition', GETDATE(), 1, 0),
(@Id2, 'Area 1B: Critical Thinking-English Composition', GETDATE(), 1, 1),
(@Id2, 'Area 1C: Oral Communication', GETDATE(), 1, 2),
(@Id2, 'Area 2: Mathematical Concepts and Quantitative Reasonings', GETDATE(), 1, 3),
(@Id2, 'Area 3A: Arts', GETDATE(), 1, 4),
(@Id2, 'Area 3B: Humanities', GETDATE(), 1, 5),
(@Id2, 'Area 4: Social and Behavioral Sciences', GETDATE(), 1, 6),
(@Id2, 'Area 5A: Physical Sciences', GETDATE(), 1, 7),
(@Id2, 'Area 5B: Biological Sciences', GETDATE(), 1, 8),
(@Id2, 'Area 5C: Laboratory Activity', GETDATE(), 1, 9),
(@Id2, 'Area 6: Ethnic Studies', GETDATE(), 1, 10)

INSERT INTO PreCoRequisiteType
(Title, Description, SortOrder, ClientId, StartDate)
VALUES
('Non-course prerequisite/text entry', 'Non-course prerequisite/text entry', 9, 1, GETDATE())

exec spActivateWorkflow 17, 47
exec spActivateWorkflow 16, 48

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()