USE [ccsf];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16440';
DECLARE @Comments nvarchar(Max) = 
	'Add CALGETC outcomes';
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
DECLARE @TABLE TABLE (Title nvarchar(max), id int)
INSERT INTO @TABLE
SELECT Title, Id FROM GeneralEducationElement WHERE GeneralEducationId = 806

INSERT INTO GeneralEducationElementOutcome
(GeneralEducationElementId, Outcome, StartDate, ClientId, SortOrder)
SELECT Id, 'Read critically to analyze, synthesize, and evaluate primarily non-fiction, college-level texts.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 1A: English Composition'
UNION
SELECT Id, 'Compose organized and coherent source-based essays that demonstrate critical thinking and rhetorical strategies.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 1A: English Composition'
UNION
SELECT Id, 'Use conventions of standard English grammar and punctuation.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 1A: English Composition'
UNION
SELECT Id, 'Select and integrate relevant, credible, and scholarly sources to support essays, using a standardized citation format.', GETDATE(), 57, 4 FROM @TABLE WHERE Title = 'Cal-GETC Area 1A: English Composition'
UNION
SELECT Id, 'Employ critical thinking and logical reasoning in writing.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 1B: Critical Thinking and Composition'
UNION
SELECT Id, 'Analyze and synthesize complex ideas and outside texts in an argument.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 1B: Critical Thinking and Composition'
UNION
SELECT Id, 'Evaluate and use sources with respect to their relevance, reliability, and appropriateness in a rhetorical context.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 1B: Critical Thinking and Composition'
UNION
SELECT Id, 'Express ideas verbally and nonverbally with clarity and purpose.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 1C: Oral Communication'
UNION
SELECT Id, 'Identify and use ethical communication practices with attention to reason, truthfulness, and accuracy.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 1C: Oral Communication'
UNION
SELECT Id, 'Analyze communication theory and practice rhetorical sensitivity to diversity, equity, inclusion, belonging, and accessibility.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 1C: Oral Communication'
UNION
SELECT Id, 'Evaluate and use sources with respect to their relevance, reliability, and appropriateness in a communication context.', GETDATE(), 57, 4 FROM @TABLE WHERE Title = 'Cal-GETC Area 1C: Oral Communication'
UNION
SELECT Id, 'Use mathematical concepts to develop, present, and critique quantitative arguments.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 2: Mathematical Concepts and Quantitative Reasoning'
UNION
SELECT Id, 'Analyze and interpret quantitative information to solve mathematical problems.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 2: Mathematical Concepts and Quantitative Reasoning'
UNION
SELECT Id, 'Apply numerical, symbolic, graphical, and verbal methods to communicate mathematical results.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 2: Mathematical Concepts and Quantitative Reasoning'
UNION
SELECT Id, 'Explore or express the arts socially and culturally.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 3A: Arts and Humanities (Arts)'
UNION
SELECT Id, 'Analyze the historical and social contexts of works of art.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 3A: Arts and Humanities (Arts)'
UNION
SELECT Id, 'Evaluate the creative expression of self or others.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 3A: Arts and Humanities (Arts)'
UNION
SELECT Id, 'Exhibit an understanding of the ways in which people in diverse cultures and eras have produced culturally significant works.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 3B: Arts and Humanities (Humanities)'
UNION
SELECT Id, 'Communicate effectively the meanings and intentions of creative expression.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 3B: Arts and Humanities (Humanities)'
UNION
SELECT Id, 'Use analytical techniques to assess the value of human creations in meaningful ways.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 3B: Arts and Humanities (Humanities)'
UNION
SELECT Id, 'Demonstrate an understanding of the human condition through language, reasoning, or artistic creation.', GETDATE(), 57, 4 FROM @TABLE WHERE Title = 'Cal-GETC Area 3B: Arts and Humanities (Humanities)'
UNION
SELECT Id, 'Exhibit an understanding of the methods of inquiry used by the social and behavioral sciences.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 4: Social and Behavioral Sciences'
UNION
SELECT Id, 'Evaluate critically the ways people act, think, and feel in response to their societies or cultures.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 4: Social and Behavioral Sciences'
UNION
SELECT Id, 'Analyze how societies and/or social subgroups operate.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 4: Social and Behavioral Sciences'
UNION
SELECT Id, 'Apply scientific inquiry and investigation of evidence to critically evaluate physical science arguments.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 5A: Natural Sciences (Physical)'
UNION
SELECT Id, 'Communicate scientific ideas and theories effectively.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 5A: Natural Sciences (Physical)'
UNION
SELECT Id, 'Apply scientific principles, theories, or models to explain the behavior of natural physical phenomena.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 5A: Natural Sciences (Physical)'
UNION
SELECT Id, 'Apply physical science knowledge and reasoning to human interaction with the natural world and issues impacting society.', GETDATE(), 57, 4 FROM @TABLE WHERE Title = 'Cal-GETC Area 5A: Natural Sciences (Physical)'
UNION
SELECT Id, 'Apply scientific inquiry and investigation of evidence to critically evaluate biological science arguments.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 5B: Natural Sciences (Biological)'
UNION
SELECT Id, 'Communicate scientific ideas and theories effectively.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 5B: Natural Sciences (Biological)'
UNION
SELECT Id, 'Apply scientific principles, theories, or models to explain the behavior of natural biological phenomena.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 5B: Natural Sciences (Biological)'
UNION
SELECT Id, 'Apply biological science knowledge and reasoning to human interaction with the natural world and issues impacting society.', GETDATE(), 57, 4 FROM @TABLE WHERE Title = 'Cal-GETC Area 5B: Natural Sciences (Biological)'
UNION
SELECT Id, 'Investigate natural phenomena through a variety of scientific inquiry techniques.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 5C: Natural Sciences (Laboratory Requirement)'
UNION
SELECT Id, 'Analyze and evaluate data from the natural world.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 5C: Natural Sciences (Laboratory Requirement)'
UNION
SELECT Id, 'Apply scientific principles, theories, or models to predict and explain the behavior of natural phenomena.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 5C: Natural Sciences (Laboratory Requirement)'
UNION
SELECT Id, 'Analyze and articulate concepts of race, racism, ethnicity, and eurocentrism in the U.S. through the lens of decolonization, anti-racism, and equity as related to Native American, African American, Asian American, and/or Latina and Latino American Studies.', GETDATE(), 57, 1 FROM @TABLE WHERE Title = 'Cal-GETC Area 6: Ethnic Studies'
UNION
SELECT Id, 'Apply theory and knowledge produced by Native American, African American, Asian American, and/or Latina and Latino American communities to critically describe group affirmation through histories of social struggles and societal contributions.', GETDATE(), 57, 2 FROM @TABLE WHERE Title = 'Cal-GETC Area 6: Ethnic Studies'
UNION
SELECT Id, 'Analyze critically the intersections of race, racism, and social identities created and experienced by Native American, African American, Asian American, and/or Latina and Latino American communities.', GETDATE(), 57, 3 FROM @TABLE WHERE Title = 'Cal-GETC Area 6: Ethnic Studies'
UNION
SELECT Id, 'Review critically how struggle, resistance, racial and social justice, solidarity, and liberation experienced and enacted by Native Americans, African Americans, Asian Americans, and/or Latina and Latino Americans shape social policy and community and national politics.', GETDATE(), 57, 4 FROM @TABLE WHERE Title = 'Cal-GETC Area 6: Ethnic Studies'
UNION
SELECT Id, 'Describe and actively engage with anti-racist and anti-colonial issues and the practices and movements in Native American, African American, Asian American and/or Latina and Latino communities to build a just and equitable society.', GETDATE(), 57, 5 FROM @TABLE WHERE Title = 'Cal-GETC Area 6: Ethnic Studies'