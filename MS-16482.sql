USE [ccsf];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16482';
DECLARE @Comments nvarchar(Max) = 
	'Update the outcomes to be numbered';
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
UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Read critically to analyze, synthesize, and evaluate primarily non-fiction, college-level texts.'
WHERE Id = 190

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Compose organized and coherent source-based essays that demonstrate critical thinking and rhetorical strategies.'
WHERE Id = 189

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Use conventions of standard English grammar and punctuation.'
WHERE Id = 192

UPDATE GeneralEducationElementOutcome
SET Outcome = 'D. Select and integrate relevant, credible, and scholarly sources to support essays, using a standardized citation format.'
WHERE Id = 191

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Employ critical thinking and logical reasoning in writing.'
WHERE Id = 194

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Analyze and synthesize complex ideas and outside texts in an argument.'
WHERE Id = 193

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Evaluate and use sources with respect to their relevance, reliability, and appropriateness in a rhetorical context.'
WHERE Id = 195

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Express ideas verbally and nonverbally with clarity and purpose.'
WHERE Id = 198

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Identify and use ethical communication practices with attention to reason, truthfulness, and accuracy.'
WHERE Id = 199

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Analyze communication theory and practice rhetorical sensitivity to diversity, equity, inclusion, belonging, and accessibility.'
WHERE Id = 196

UPDATE GeneralEducationElementOutcome
SET Outcome = 'D. Evaluate and use sources with respect to their relevance, reliability, and appropriateness in a communication context.'
WHERE Id = 197

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Use mathematical concepts to develop, present, and critique quantitative arguments.'
WHERE Id = 202

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Analyze and interpret quantitative information to solve mathematical problems.'
WHERE Id = 200

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Apply numerical, symbolic, graphical, and verbal methods to communicate mathematical results.'
WHERE Id = 201

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Explore or express the arts socially and culturally.'
WHERE Id = 205

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Analyze the historical and social contexts of works of art.'
WHERE Id = 203

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Evaluate the creative expression of self or others.'
WHERE Id = 204

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Exhibit an understanding of the ways in which people in diverse cultures and eras have produced culturally significant works.'
WHERE Id = 208

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Communicate effectively the meanings and intentions of creative expression.'
WHERE Id = 206

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Use analytical techniques to assess the value of human creations in meaningful ways.'
WHERE Id = 209

UPDATE GeneralEducationElementOutcome
SET Outcome = 'D. Demonstrate an understanding of the human condition through language, reasoning, or artistic creation.'
WHERE Id = 207

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Exhibit an understanding of the methods of inquiry used by the social and behavioral sciences.'
WHERE Id = 212

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Evaluate critically the ways people act, think, and feel in response to their societies or cultures.'
WHERE Id = 211

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Analyze how societies and/or social subgroups operate.'
WHERE Id = 210

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Apply scientific inquiry and investigation of evidence to critically evaluate physical science arguments.'
WHERE Id = 214

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Communicate scientific ideas and theories effectively.'
WHERE Id = 216

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Apply scientific principles, theories, or models to explain the behavior of natural physical phenomena.'
WHERE Id = 215

UPDATE GeneralEducationElementOutcome
SET Outcome = 'D. Apply physical science knowledge and reasoning to human interaction with the natural world and issues impacting society.'
WHERE Id = 213

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Apply scientific inquiry and investigation of evidence to critically evaluate biological science arguments.'
WHERE Id = 218

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Communicate scientific ideas and theories effectively.'
WHERE Id = 220

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Apply scientific principles, theories, or models to explain the behavior of natural biological phenomena.'
WHERE Id = 219

UPDATE GeneralEducationElementOutcome
SET Outcome = 'D. Apply biological science knowledge and reasoning to human interaction with the natural world and issues impacting society.'
WHERE Id = 217

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Investigate natural phenomena through a variety of scientific inquiry techniques.'
WHERE Id = 223

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Analyze and evaluate data from the natural world.'
WHERE Id = 221

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Apply scientific principles, theories, or models to predict and explain the behavior of natural phenomena.'
WHERE Id = 222

UPDATE GeneralEducationElementOutcome
SET Outcome = 'A. Analyze and articulate concepts of race, racism, ethnicity, and eurocentrism in the U.S. through the lens of decolonization, anti-racism, and equity as related to Native American, African American, Asian American, and/or Latina and Latino American Studies.'
WHERE Id = 224

UPDATE GeneralEducationElementOutcome
SET Outcome = 'B. Apply theory and knowledge produced by Native American, African American, Asian American, and/or Latina and Latino American communities to critically describe group affirmation through histories of social struggles and societal contributions.'
WHERE Id = 226

UPDATE GeneralEducationElementOutcome
SET Outcome = 'C. Analyze critically the intersections of race, racism, and social identities created and experienced by Native American, African American, Asian American, and/or Latina and Latino American communities.'
WHERE Id = 225

UPDATE GeneralEducationElementOutcome
SET Outcome = 'D. Review critically how struggle, resistance, racial and social justice, solidarity, and liberation experienced and enacted by Native Americans, African Americans, Asian Americans, and/or Latina and Latino Americans shape social policy and community and national politics.'
WHERE Id = 228

UPDATE GeneralEducationElementOutcome
SET Outcome = 'E. Describe and actively engage with anti-racist and anti-colonial issues and the practices and movements in Native American, African American, Asian American and/or Latina and Latino communities to build a just and equitable society.'
WHERE Id = 227