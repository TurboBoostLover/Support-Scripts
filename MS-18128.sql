DROP TABLE FINALResults

-- Declare the user ID and cursor for looping through users
DECLARE @userId INT;

DECLARE user_cursor CURSOR FOR
SELECT Id
FROM [user]
WHERE Active = 1 AND ClientId = 2;

DECLARE @entityTypeId INT = 6;
DECLARE @ClientId INT = 2, @includeInactive BIT;
DECLARE @now DATETIME = GETDATE();
DECLARE @bubbleUp BIT = (SELECT dbo.fnGetClientSetting('AllowOriginationBubbleUp', 'Workflows', @ClientId));

-- Declare @userPermissions table variable
DECLARE @userPermissions TABLE (Id INT);

-- Create the final results table to store all output
CREATE TABLE FinalResults (
    Id INT,
    ClientId INT,
    OrganizationTierId INT,
    Title NVARCHAR(255),
    Parent_OrganizationEntityId INT,
    UserId INT
);

OPEN user_cursor;

-- Fetch the first user
FETCH NEXT FROM user_cursor INTO @userId;

-- Loop through all users
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Clear the table variable for each user
    DELETE FROM @userPermissions;

    -- Insert into @userPermissions
    INSERT INTO @userPermissions (Id)
    SELECT oe.Id
    FROM OrganizationEntity oe
    LEFT JOIN UserRole ur ON oe.ClientId = ur.ClientId
    WHERE (oe.Active = 1 OR @includeInactive = 1)
    AND ur.UserId = @userId
    AND ur.RoleId = 1
    UNION
    SELECT os.OrganizationEntityId
    FROM [User] u
    INNER JOIN UserOriginationSubjectPermission AS uosp
        ON u.Id = uosp.UserId
        AND uosp.Active = 1
    INNER JOIN OrganizationSubject AS OS
        ON uosp.SubjectId = OS.SubjectId
        AND os.Active = 1
    INNER JOIN Subject s ON s.Id = os.SubjectId
    WHERE u.Id = @userId
    AND uosp.Active = 1
    AND @bubbleUp = 1
    UNION
    SELECT uooep.OrganizationEntityId
    FROM [User] u
    INNER JOIN UserOriginationOrganizationEntityPermission uooep
        ON u.Id = uooep.UserId
        AND uooep.Active = 1
    WHERE u.Id = @userId;

    WITH Link AS (
        SELECT OE.Id, OE.ClientId, OT.Id AS OrganizationTierId, OE.Title, OL.Parent_OrganizationEntityId, oe.Active AS OrgEntityActive
        FROM OrganizationEntity AS OE
        INNER JOIN OrganizationTier AS OT ON (OE.OrganizationTierId = OT.Id AND OT.Active = 1)
        LEFT JOIN OrganizationLink AS OL ON (OE.Id = OL.Child_OrganizationEntityId AND (OL.Active = 1 OR @includeInactive = 1))
        WHERE (OE.Active = 1 OR @includeInactive = 1)
    ),
    OrgData AS (
        -- Anchor member definition
        SELECT OE.Id, OE.ClientId, OT.Id AS OrganizationTierId, OE.Title, OL.Parent_OrganizationEntityId, oe.Active AS OrgEntityActive
        FROM OrganizationEntity AS OE
        INNER JOIN OrganizationTier AS OT ON (OE.OrganizationTierId = OT.Id AND OT.Active = 1)
        LEFT JOIN OrganizationLink AS OL ON (OE.Id = OL.Child_OrganizationEntityId AND (OL.Active = 1 OR @includeInactive = 1))
        WHERE EXISTS (SELECT 1 FROM @userPermissions usp WHERE usp.Id = oe.Id)
        AND (OE.Active = 1 OR @includeInactive = 1)
        UNION ALL
        -- Recursive member definition
        SELECT l.Id, l.ClientId, l.OrganizationTierId, l.Title, l.Parent_OrganizationEntityId, l.OrgEntityActive
        FROM Link l
        INNER JOIN OrgData AS O ON O.Parent_OrganizationEntityId = l.Id
    )
    -- Insert the result into the FinalResults table
    INSERT INTO FinalResults (Id, ClientId, OrganizationTierId, Title, Parent_OrganizationEntityId, UserId)
    SELECT 
        Id, ClientId, OrganizationTierId, 
        Title + CASE WHEN OrgEntityActive = 0 THEN ' (Inactive)' ELSE '' END AS Title,
        Parent_OrganizationEntityId, @userId
    FROM OrgData
    WHERE OrganizationTierId IN (1, 2)
    ORDER BY OrganizationTierId, OrgEntityActive DESC, Title;

    -- Fetch the next user
    FETCH NEXT FROM user_cursor INTO @userId;
END

-- Close and deallocate the cursor
CLOSE user_cursor;
DEALLOCATE user_cursor;

-- Now you can select from the FinalResults table
--SELECT * FROM FinalResults;

-- Optionally, drop the FinalResults table if no longer needed
-- DROP TABLE FinalResults;



DECLARE @1 TABLE (Title NVARCHAR(MAX), UserId int);
WITH DistinctTitles AS (
    SELECT DISTINCT Title, UserId
    FROM FinalResults
    WHERE OrganizationTierId = 1
)
INSERT INTO @1
SELECT 
    dbo.ConcatWithSep_Agg('; ', Title) AS Titles,
		    UserId
FROM 
    DistinctTitles
GROUP BY 
    UserId
ORDER BY 
    UserId


DECLARE @2 TABLE (Title NVARCHAR(MAX), UserId int);
WITH DistinctTitles AS (
    SELECT DISTINCT Title, UserId
    FROM FinalResults
    WHERE OrganizationTierId = 2
)
INSERT INTO @2
SELECT 
    dbo.ConcatWithSep_Agg('; ', Title) AS Titles,
		    UserId
FROM 
    DistinctTitles
GROUP BY 
    UserId
ORDER BY 
    UserId


SELECT 
    one.Title AS [UnitName],
    two.Title AS [Division],
    CONCAT(u.FirstName, ' ', u.LastName) AS [Full Name],
    u.Email AS [Email Address]
FROM 
    [User] AS u
INNER JOIN 
    @1 AS one ON one.UserId = u.Id
INNER JOIN 
    @2 AS two ON two.UserId = u.Id
WHERE 
    u.FirstName NOT LIKE '%Curriqunet%'
ORDER BY 
    [UnitName]