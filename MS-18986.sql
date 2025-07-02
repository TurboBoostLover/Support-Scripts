USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18986';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Presentation';
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
UPDATE OutputTemplateClient
SET TemplateQuery = '
DECLARE @modelRoot TABLE (
	ProgramId	INT PRIMARY KEY,
	InsertOrder INT,
	RootData	NVARCHAR(MAX)
	);

INSERT INTO @modelRoot (ProgramId, InsertOrder, RootData)
SELECT em.[Key], m.InsertOrder, m.RootData 
FROM @entityModels em
	CROSS APPLY OPENJSON(em.[Value])
	WITH (
		InsertOrder INT			  ''$.InsertOrder'',
		RootData	NVARCHAR(MAX) ''$.RootData'' AS JSON
	) m
;

DECLARE @blockWrapperTag NVARCHAR(10) = ''div'', 
		@listWrapperTag	 NVARCHAR(10) = ''ol'', 
		@listItemTag	 NVARCHAR(10) = ''li'',
		@italElementTag	 NVARCHAR(10) = ''i'', 
		@boldElementTag	 NVARCHAR(10) = ''b'',
		@dataElementTag  NVARCHAR(10) = ''span'', 
		@classAttrib	 NVARCHAR(10) = ''class'',
		@styleAttrib	 NVARCHAR(10) = ''style'',
		@headerTag		 NVARCHAR(10) = ''header'', 
		@h1Tag			 NVARCHAR(10) = ''h1'', 
		@h2Tag			 NVARCHAR(10) = ''h2'', 
		@h3Tag			 NVARCHAR(10) = ''h3'', 
		@h4Tag			 NVARCHAR(10) = ''h4'', 
		@h5Tag			 NVARCHAR(10) = ''h5'', 
		@h6Tag			 NVARCHAR(10) = ''h6'', 
		@space			 NVARCHAR(10) = '' '';

DECLARE @modelRootData TABLE (
	ProgramId			INT PRIMARY KEY,
	CatalogDescription	NVARCHAR(MAX),
	AwardNotes			NVARCHAR(MAX),
	ProgramOutcomes		NVARCHAR(MAX)
	);

INSERT INTO @modelRootData (ProgramId, CatalogDescription, AwardNotes, ProgramOutcomes)
SELECT emi.ProgramId, m.CatalogDescription, m.AwardNotes, m.ProgramOutcomes
FROM @modelRoot emi
	CROSS APPLY OPENJSON(emi.RootData)
	WITH (
		CatalogDescription NVARCHAR(MAX) ''$.CatalogDescription'',
		AwardNotes		   NVARCHAR(MAX) ''$.AwardNotes'',
		ProgramOutcomes    NVARCHAR(MAX) ''$.ProgramOutcomes''
	) m
;

SELECT 
	mr.ProgramId AS [Value],
	CONCAT 
		(
		-- Program Summary wrapper
		dbo.fnHtmlOpenTag(@blockWrapperTag, CONCAT
			(
			dbo.fnHtmlAttribute(@classAttrib, ''program-summary-wrapper''), 
			@space, 
			dbo.fnHtmlAttribute(''data-entity-id'', mr.ProgramId)
			)
		), 
		-- Program Description
		CASE WHEN LEN(mrd.CatalogDescription) > 0 THEN CONCAT
			(
			dbo.fnHtmlOpenTag(@blockWrapperTag, CONCAT
				(
				dbo.fnHtmlAttribute(@classAttrib, ''program-description''),
				@space,
				dbo.fnHtmlAttribute(@styleAttrib, ''margin-top: 10px;'')
				)),
				mrd.CatalogDescription,
			dbo.fnHtmlCloseTag(@blockWrapperTag)
			)
		ELSE NULL END, 
		-- Award Notes
		CASE WHEN LEN(mrd.AwardNotes) > 0 THEN CONCAT
			(
			dbo.fnHtmlOpenTag(@blockWrapperTag, CONCAT
				(
				dbo.fnHtmlAttribute(@classAttrib, ''award-notes''),
				@space,
				dbo.fnHtmlAttribute(@styleAttrib, ''margin-top: 10px;'')
				)),
				mrd.AwardNotes,
			dbo.fnHtmlCloseTag(@blockWrapperTag)
			)
		ELSE NULL END,
		-- Program Learning Outcomes
		CASE WHEN LEN(mrd.ProgramOutcomes) > 0 THEN CONCAT
			(
			dbo.fnHtmlOpenTag
				(
				@headerTag, dbo.fnHtmlAttribute
					(@classAttrib, ''program-outcome-header'')
				), 
				dbo.fnHtmlOpenTag
					(
					@boldElementTag, 
					CONCAT
						(
						dbo.fnHtmlAttribute
							(@classAttrib, ''program-outcome-header-title''),
						@space,
						dbo.fnHtmlAttribute
							(@styleAttrib, ''margin-bottom: 3px;'')
						)
					),
					''Learning Outcome(s): Students who complete the '', Award.Title, '' program will be able to:'',
				dbo.fnHtmlCloseTag(@boldElementTag),
			dbo.fnHtmlCloseTag(@headerTag), 
			dbo.fnHtmlOpenTag(@blockWrapperTag, dbo.fnHtmlAttribute(@classAttrib, ''program-outcomes'')),
				CONCAT(''<ol>'', mrd.ProgramOutcomes, ''</ol>''),
			dbo.fnHtmlCloseTag(@blockWrapperTag)
			)
		END,
		dbo.fnHtmlCloseTag(@blockWrapperTag)
		) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData mrd ON mr.ProgramId = mrd.ProgramId
	INNER JOIN Program p on mrd.ProgramId = p.Id
	LEFT JOIN AwardType Award on p.AwardTypeId = Award.Id
ORDER BY mr.InsertOrder;

--#endregion query
'
WHERE Id = 10