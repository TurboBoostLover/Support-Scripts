USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-17668';
DECLARE @Comments nvarchar(Max) = 
	'PLO Data Import';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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

UPDATE OrganizationEntity
SET Title = 'Automotive Technology'
WHERE Id = 119

UPDATE Program
SET AwardTypeId = 7
WHERE Id in (
570, 571
)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'Declare @Awardtype_ProgramType_Mapping table (awardtypeId int, ProgramTypeID int)
Insert into @Awardtype_ProgramType_Mapping
Values
--Associate in Arts Degree for Transfer
(2,1),--Transfer (ADTs and CalGETC certificates only)
--Associate in Science Degree for Transfer
(3,1),--Transfer (ADTs and CalGETC certificates only)
--Associate of Arts Degree
(4,2),--CTE (all non-ADT awards with CTE TOP-Codes)
(4,3),--Local (community need)
--Associate of Science Degree
(5,2),--CTE (all non-ADT awards with CTE TOP-Codes)
(5,3),--Local (community need)
--Certificate of Completion
(6,6),--Short-term Vocational
(6,7),--Workforce Preparation
--Certificate of Competency
(7,4),--Elementary or Secondary Basic Skills
(7,5),--English as a Second Language (ESL)
--Certificate of Achievement (60 or more units)
(8,2),--CTE (all non-ADT awards with CTE TOP-Codes)
(8,3),--Local (community need)
--Certificate of Achievement (30 to fewer than 60 units)
(9,1),--Transfer (ADTs and CalGETC certificates only)
(9,2),--CTE (all non-ADT awards with CTE TOP-Codes)
(9,3),--Local (community need)
--Certificate of Achievement (16 to fewer than 30 units)
(10,2),--CTE (all non-ADT awards with CTE TOP-Codes)
(10,3),--Local (community need)
--Certificate of Achievement (12 to fewer than 16 units)
(11,2),--CTE (all non-ADT awards with CTE TOP-Codes)
(11,3),--Local (community need)
--Certificate of Accomplishment (fewer than 16 units)
(12,2),--CTE (all non-ADT awards with CTE TOP-Codes)
(12,3),--Local (community need)
(7, 3)



SELECT 
	Id as Value, 
	Title as Text, 
	map.ProgramTypeID AS FilterValue
FROM AwardType At
	Inner join @Awardtype_ProgramType_Mapping map on At.Id = map.awardtypeId
WHERE map.ProgramTypeID = (
	SELECT p.ProgramTypeId FROM program p
	WHERE p.Id = @entityId
)'
WHERE Id = 71

DECLARE @Data TABLE (Division int, Department int, Program NVARCHAR(MAX), AwardType int, PLO NVARCHAR(MAX))
INSERT INTO @Data
VALUES
(20, 111, 'Administration of Justice', 4, 'Upon completion of the AA in Administration of Justice, students are academically prepared for a California Peace Officer Standards and Training Commission basic training academy and prepared for transfer to a four year degree program.  The student will be able to compare and contrast the different components and sub-components of the American criminal justice program; interpret criminal law statutes; differentiate between civil law and criminal law; investigate a scenario and create a police report utilizing proper investigative and evidentiary procedures and understand ethical leadership in a law enforcement agency.'),
(20, 111, 'Administration of Justice', 3, 'Upon completion of the AS-T in Administration of Justice, students are academically prepared for transfer to a four year degree program.  The student will be able to explain different components and sub-components of the American criminal justice program; interpret criminal law statutes and differentiate between civil law and criminal law.'),
(20, 113, 'Anthropology', 2, 'Upon completion of the AA-T in Anthropology, students are able to explain why there is no biological validity to the concept of "race".'),
(20, 113, 'Anthropology', 2, 'Upon completion of the AA-T in Anthropology, students are able to use the scientific method to test hypotheses and establish empirical facts.'),
(20, 113, 'Anthropology', 2, 'Upon completion of the AA-T in Anthropology, students are able to describe and discuss the evolution and prehistory of human beings.'),
(20, 113, 'Anthropology', 2, 'Upon completion of the AA-T in Anthropology, students are able to use the scientific method to test hypotheses and establish empirical facts.'),
(12, 116, 'Art: Emphasis in Painting', 4, 'Upon completion of the AA in Art: Emphasis in Painting, students are able to create works of art that synthesize quality technical execution with content and concept.'),
(12, 116, 'Art: Emphasis in Painting', 4, 'Upon completion of the AA in Art: Emphasis in Painting, students are able to demonstrate technical proficiency in use of art media, tools, processes and technology.'),
(12, 116, 'Art: Emphasis in Painting', 4, 'Upon completion of the AA in Art: Emphasis in Painting, students are able to apply creative thinking through the production of original artworks.'),
(12, 116, 'Art: Emphasis in Painting', 4, 'Upon completion of the AA in Art: Emphasis in Painting, students are able to apply the principles of visual design for the communication and expression of ideas.'),
(12, 116, 'Studio Arts', 2, 'Upon completion of the AA-T in Studio Arts, students are able to apply the basic principles of observational drawing and how to develop illusionary spatial constructions.'),
(12, 116, 'Studio Arts', 2, 'Upon completion of the AA-T in Studio Arts, students are able to the principles and concepts of design.'),
(12, 116, 'Studio Arts', 2, 'Upon completion of the AA-T in Studio Arts, students are able to demonstrate critical thinking as it applies to critique, evaluation and/or production of works of art.'),
(12, 116, 'Studio Arts', 2, 'Upon completion of the AA-T in Studio Arts, students are able to demonstrate knowledge of the science of color perception and how it can be utilized in the creation of works of art.'),
(12, 117, 'Art History', 2, 'Upon completion of the AA-T in Art History, students are able to communicate concepts and ideas effectively through written, oral, and digital media.'),
(12, 117, 'Art History', 2, 'Upon completion of the AA-T in Art History, students are able to evaluate the artwork from different cultures and art historical periods.'),
(12, 117, 'Art History', 2, 'Upon completion of the AA-T in Art History, students are able to identify and evaluate art historical styles, movements, and concepts.'),
(12, 117, 'Art History', 2, 'Upon completion of the AA-T in Art History, students are able to recognize art''s relationship to geography, cultural ideologies, and historical periods.'),
(12, 117, 'Art History', 2, 'Upon completion of the AA-T in Art History, students are able to research and analyze visual artwork using interdisciplinary theories and methods.'),
(20, 119, 'Automotive Alternative Fuels/Hybrid Technology', 5, 'Upon completion of the AS in Automotive Alternative Fuels/ Hybrid Technology, students are able to apply safety procedures relating to alternative fuels and high voltage.'),
(20, 119, 'Automotive Alternative Fuels/Hybrid Technology', 5, 'Upon completion of the AS in Automotive Alternative Fuels/ Hybrid Technology, students are able to diagnose alternative fuel systems.'),
(20, 119, 'Automotive Alternative Fuels/Hybrid Technology', 5, 'Upon completion of the AS in Automotive Alternative Fuels/ Hybrid Technology, students are able to perform high voltage disable procedures.'),
(20, 119, 'Automotive Alternative Fuels/Hybrid Technology', 10, 'Upon completion of the Certificate of Achievement in Automotive Alternative Fuels/ Hybrid Technology, students are able to apply safety procedures relating to alternative fuels and high voltage.'),
(20, 119, 'Automotive Alternative Fuels/Hybrid Technology', 10, 'Upon completion of the Certificate of Achievement in Automotive Alternative Fuels/ Hybrid Technology, students are able to perform high voltage disable procedures.'),
(20, 119, 'Automotive Alternative Fuels/Hybrid Technology', 10, 'Upon completion of the Certificate of Achievement in Automotive Alternative Fuels/Hybrid Technology, students are able to diagnose alternative fuel systems.'),
(20, 119, 'Automotive Chassis', 10, 'Upon completion of the Certificate of Achievement in Automotive Chassis, students are able to use automotive knowledge to diagnose various automotive concerns.'),
(20, 119, 'Automotive Chassis', 10, 'Upon completion of the Certificate of Achievement in Automotive Chassis, students are able to follow safety guidelines while employed in an automotive related job.'),
(20, 119, 'Automotive Drivability', 10, 'Upon completion of the Certificate of Achievement in Automotive Drivability, students are able to use automotive knowledge to diagnose various automotive concerns.'),
(20, 119, 'Automotive Drivability', 10, 'Upon completion of the Certificate of Achievement in Automotive Drivability, students are able to follow safety guidelines while employed in an automotive related job.'),
(20, 119, 'Automotive Electronics Technology', 5, 'Upon completion of the AS in Automotive Electronics Technology, students are able to use automotive knowledge to diagnose various automotive concerns.'),
(20, 119, 'Automotive Electronics Technology', 5, 'Upon completion of the AS in Automotive Electronics Technology, students are able to follow safety guidelines while employed in an automotive related job.'),
(20, 119, 'Automotive Light Duty Diesel', 5, 'Upon completion of the AS in Automotive Light Duty Diesel, students are able to diagnose electronic diesel systems.'),
(20, 119, 'Automotive Light Duty Diesel', 5, 'Upon completion of the AS in Automotive Light Duty Diesel, students are able to repair diesel engine mechanical systems.'),
(20, 119, 'Automotive Light Duty Diesel', 10, 'Upon completion of the Certificate of Achievement in Automotive Light Duty Diesel, students are able to diagnose and repair diesel turbo systems.'),
(20, 119, 'Automotive Light Duty Diesel', 10, 'Upon completion of the Certificate of Achievement in Automotive Light Duty Diesel, students are able to diagnose electronic diesel systems.'),
(20, 119, 'Automotive Light Duty Diesel', 10, 'Upon completion of the Certificate of Achievement in Automotive Light Duty Diesel, students are able to repair diesel engine mechanical systems.'),
(20, 119, 'Automotive Master', 5, 'Upon completion of AS in Automotive Master, students are able to diagnose electrical issues.'),
(20, 119, 'Automotive Master', 5, 'Upon completion of AS in Automotive Master, students are able to diagnose engine mechanical issues.'),
(20, 119, 'Automotive Mechanical', 10, 'Upon completion of the Certificate of Achievement in Automotive Mechanical, students are able to diagnose engine mechanical issues.'),
(20, 119, 'Automotive Mechanical', 10, 'Upon completion of the Certificate of Achievement in Automotive Mechanical, students are able to measure engine components and compare to specifications.'),
(20, 119, 'Automotive Mechanical', 10, 'Upon completion of the Certificate of Achievement in Automotive Mechanical, students are able to tear down, inspect and reassemble engines.'),
(20, 119, 'Automotive Smog Technician', 5, 'Upon completion of the AS in Automotive Smog Technician, students are able to apply for and take the California Smog test.'),
(20, 119, 'Automotive Smog Technician', 5, 'Upon completion of the AS in Automotive Smog Technician, students are able to diagnose advanced emission issues using five gas.'),
(20, 119, 'Automotive Smog Technician', 5, 'Upon completion of the AS in Automotive Smog Technician, students are able to diagnose high level engine mechanical issues using engine scanners.'),
(20, 119, 'Automotive Smog Technician', 5, 'Upon completion of the AS in Automotive Smog Technician, students should be able to diagnose high-level engine mechanical issues using engine scanners.'),
(20, 119, 'Automotive Smog Technician', 10, 'Upon completion of the Certificate of Achievement in Automotive Smog Technician, students are able to apply for and take the California Smog test.'),
(20, 119, 'Automotive Smog Technician', 10, 'Upon completion of the Certificate of Achievement in Automotive Smog Technician, students are able to diagnose engine mechanical issues.'),
(15, 121, 'Biology', 4, 'Upon completion of an AA in Biology, students are able to explain and apply basic principles and processes of biology at different levels, from the biochemical to the ecological.'),
(15, 121, 'Biology', 4, 'Upon completion of an AA in Biology, students will be able to design, conduct, analyze, and report the results of research projects and will have developed scientific literacy skills.'),
(15, 121, 'Biology', 4, 'Upon completion of an AA in Biology, students are proficient in standard biology lab techniques and lab safety procedures.'),
(15, 121, 'Biology', 3, 'Upon completion of an AS-T in Biology, students are able to explain and apply basic principles and processes of biology at different levels, from the biochemical to the ecological.'),
(15, 121, 'Biology', 3, 'Upon completion of an AS-T in Biology, students are proficient in standard biology lab techniques and lab safety procedures.'),
(15, 121, 'Biology', 3, 'Upon completion of an AS-T in Biology, students are able to design, conduct, analyze, and/or report results of investigations and experiments in the laboratory and/or field.'),
(15, 121, 'Biology: Allied Health', 4, 'Upon completion of an AA in Biology: Allied Health, students are able to explain and apply the basic processes of homeostasis in humans from the cellular to the organismal level.'),
(15, 121, 'Biology: Allied Health', 4, 'Upon completion of an AA in Biology: Allied Health, students are proficient in standard biology lab techniques and lab safety procedure.'),
(15, 121, 'Biology: Allied Health', 4, 'Upon completion of an AA in Biology: Allied Health, students are able to analyze and communicate the findings of scientific research to an academic and/or non-academic audience.'),
(15, 121, 'Biology UC Pathway', 5, 'Upon completion of an AS in Biology UC Pathway, students are able to design, conduct, analyze, and/or report results of investigations and experiments in the laboratory and/or field.'),
(15, 121, 'Biology UC Pathway', 5, 'Upon completion of an AS in Biology UC Pathway, students are able to explain and apply basic principles and processes of biology at different levels, from the biochemical to the ecological.'),
(15, 121, 'Biology UC Pathway', 5, 'Upon completion of an AS in Biology UC Pathway, students are proficient in standard biology lab techniques and lab safety procedures.'),
(15, 121, 'Biology UC Pathway', 10, 'Upon completion of an Certificate of Achievement in Biology UC Pathway, students are able to explain and apply basic principles and processes of biology at different levels, from the biochemical to the ecological.'),
(15, 121, 'Biology UC Pathway', 10, 'Upon completion of an Certificate of Achievement in Biology UC Pathway, students are proficient in standard biology lab techniques and lab safety procedures.'),
(15, 121, 'Biology UC Pathway', 10, 'Upon completion of an Certificate of Achievement in Biology UC Pathway, students will be able to design, conduct, analyze, and report the results of research projects and will have developed scientific literacy skills.'),
(15, 121, 'Computational Biology', 4, 'Upon completion of the AA in Computational Biology, students are able to demonstrate an understanding of the fundamental concepts in molecular biology, including DNA, genes, proteins and genomes.'),
(15, 121, 'Computational Biology', 4, 'Upon completion of the AA in Computational Biology, students are able to explain the use of computational techniques to solve biological problems.'),
(15, 121, 'Computational Biology', 4, 'Upon completion of the AA in Computational Biology, students are able to use online resources such as NCBI (National Center for Biotechnology Information) and bioinformatics applications to research and analyze biological data.'),
(15, 121, 'Computational Biology', 10, 'Upon completion of the Certificate of Achievement in Computational Biology, students are able to demonstrate an understanding of the fundamental concepts in molecular biology, including DNA, genes, proteins and genomes.'),
(15, 121, 'Computational Biology', 10, 'Upon completion of the Certificate of Achievement in Computational Biology, students are able to explain the use of computational techniques to solve biological problems.'),
(15, 121, 'Computational Biology', 10, 'Upon completion of the Certificate of Achievement in Computational Biology, students are able to use online resources such as NCBI (National Center for Biotechnology Information) and bioinformatics applications to research and analyze biological data.'),
(24, 122, 'Accounting Technician', 10, 'Upon completion of the Certificate of Achievement in Accounting Technician, students are able to perform variety of functions in an accounting department including: maintain and update financial records, prepare and analyze financial statements, review bookkeepers'' and clerks'' work for accuracy and completeness, prepare individual income tax returns containing schedule A, B, C, D and E, maintain cost records and prepare and analyze budgets.'),
(24, 122, 'Administrative Assistant', 4, 'Upon completion of the AA in Administrative Assistant, students are able to complete business-related documents using the various functions—basic, intermediate, and advanced—of the software programs: Word, Excel, PowerPoint.'),
(24, 122, 'Administrative Assistant', 10, 'Upon completion of the Certificate of Achievement in Administrative Assistant, students are able to demonstrate the ability to successfully use basic English language skills (grammar, punctuation, capitalization, etc.) in business documents.'),
(24, 122, 'Bookkeeping', 10, 'Upon completion of the Certificate of Accomplishment in Bookkeeping, students are able to perform a variety of functions in an accounting department, including; using accounting software to analyze and record financial transactions, analyze payroll transactions, prepare trial balance, file payroll tax returns, prepare and analyze invoices, calculate interest rates, shipping terms and prepare financial statement.'),
(24, 122, 'Business', 5, 'Upon completion of the AS in Business, students are able to compare and contrast ethical standards and best practices of social responsibility to business situations.'),
(24, 122, 'Business', 5, 'Upon completion of the AS in Business, students are able to demonstrate knowledge of business operations, the business organization, business environments, and business procedures.'),
(24, 122, 'Business', 5, 'Upon completion of the AS in Business, students are able to explain the functions of all business operations and identify the resources needed in each area.'),
(24, 122, 'Business Administration', 4, 'Upon completion of the AA in Business Administration, students are able to compare and contrast ethical standards and best practices of social responsibility to business situations.'),
(24, 122, 'Business Administration', 4, 'Upon completion of the AA in Business Administration, students are able to demonstrate knowledge of business operations, the business organization, business environments, and business procedures.'),
(24, 122, 'Business Administration', 4, 'Upon completion of the AA in Business Administration, students are able to explain the functions of all business operations and identify the resources needed in each area.'),
(24, 122, 'Business Administration', 4, 'Upon completion of the AA in Business Administration, students are able to list and explain the factors of production, the external business environments and apply their influence in specific business problems.'),
(24, 122, 'Business Administration', 3, 'Upon completion of the AS-T in Business Administration, students are able to compare and contrast ethical standards and best practices of social responsibility to business situations.'),
(24, 122, 'Business Administration', 3, 'Upon completion of the AS-T in Business Administration, students are able to demonstrate knowledge of business operations, the business organization, business environments, and business procedures.'),
(24, 122, 'Business Administration', 3, 'Upon completion of the AS-T in Business Administration, students are able to explain the functions of all business operations and identify the resources needed in each area.'),
(24, 122, 'Business Administration', 3, 'Upon completion of the AS-T in Business Administration, students are able to list and explain the factors of production, the external business environments and apply their influence in specific business problems.'),
(24, 122, 'Business Entrepreneurship', 4, 'Upon completion of the AA in Business Entrepreneurship, students are able to construct a business plan, essential marketing plan, and the basic financial documents needed for a small business.'),
(24, 122, 'Business Entrepreneurship', 4, 'Upon completion of the AA in Business Entrepreneurship, students are able to define "Competitive Advantage" and discuss actions a small business should use to achieve it.'),
(24, 122, 'Business Entrepreneurship', 4, 'Upon completion of the AA in Business Entrepreneurship, students are able to demonstrate knowledge of business operations, the business organization, business environments, and business procedures.'),
(24, 122, 'Business Entrepreneurship', 4, 'Upon completion of the AA in Business Entrepreneurship, students are able to describe the nature and characteristics of successful small businesses.'),
(24, 122, 'Business Entrepreneurship', 10, 'Upon completion of the Certificate of Achievement in Business Entrepreneurship, students are able to compare and contrast the impact of the external business environments on small businesses.'),
(24, 122, 'Business Entrepreneurship', 10, 'Upon completion of the Certificate of Achievement in Business Entrepreneurship, students are able to construct a business plan, essential marketing plan, and basic financial documents for a small business.'),
(24, 122, 'Business Entrepreneurship', 10, 'Upon completion of the Certificate of Achievement in Business Entrepreneurship, students are able to define and provide concrete examples of the "Competitive Advantage" concept that a small business must achieve in order to succeed.'),
(24, 122, 'Business Entrepreneurship', 10, 'Upon completion of the Certificate of Achievement in Business Entrepreneurship, students are able to describe the nature and characteristics of successful small business persons.'),
(24, 122, 'Business Entrepreneurship', 10, 'Upon completion of the Certificate of Achievement in Business Entrepreneurship, students are able to detail key business procedures relevant to a specific problem using appropriate technology.'),
(24, 122, 'Business Entrepreneurship', 10, 'Upon completion of the Certificate of Achievement in Business Entrepreneurship, students are able to summarize the responsibilities of small business owners in selecting, motivating, training, and supervising employees.'),
(24, 122, 'Business Workforce Proficiency', 11, 'Upon completion of the Certificate of Accomplishment in Business Workforce Proficiency, students are able to apply standard business English to oral and written communications, including grammar, punctuation, mechanics, vocabulary, style, media, and usage.'),
(24, 122, 'Business Workforce Proficiency', 11, 'Upon completion of the Certificate of Accomplishment in Business Workforce Proficiency, students are able to describe the work ethic needed for success in today’s work environment.'),
(24, 122, 'Business Workforce Proficiency', 11, 'Upon completion of the Certificate of Accomplishment in Business Workforce Proficiency, students are able to develop business communications that present information in an organized and concise manner.'),
(24, 122, 'Business Workforce Proficiency', 11, 'Upon completion of the Certificate of Accomplishment in Business Workforce Proficiency, students are able to explain group dynamics as they apply to an individual working effectively within a group and within teams.'),
(24, 122, 'Business Workforce Proficiency', 11, 'Upon completion of the Certificate of Accomplishment in Business Workforce Proficiency, students are able to identify the primary business operations, business organizational options, and business procedures.'),
(24, 122, 'Retail Management (WAFC)', 10, 'Upon completion of the Certificate of Achievement in Retail Management (WAFC), students are able to demonstrate the integration of basic management theories into supervisory and management functions.'),
(24, 122, 'Retail Management (WAFC)', 10, 'Upon completion of the Certificate of Achievement in Retail Management (WAFC), students are able to determine the demand for products and services offered by a firm and identify potential customers.'),
(24, 122, 'Retail Management (WAFC)', 10, 'Upon completion of the Certificate of Achievement in Retail Management (WAFC), students are able to differentiate threshold issues involved in legal, ethical, and social responsibilities of management.'),
(24, 122, 'Retail Management (WAFC)', 10, 'Upon completion of the Certificate of Achievement in Retail Management (WAFC), students are able to identify key business procedures relevant to a specific problem using appropriate technology.'),
(24, 122, 'Retail Management (WAFC)', 10, 'Upon completion of the Certificate of Achievement in Retail Management (WAFC), students are able to integrate basic management theories into supervisor and management functions.'),
(24, 122, 'Retail Management (WAFC)', 10, 'Upon completion of the Certificate of Achievement in Retail Management (WAFC), students are able to list current problems related to human behavior in organizations and detail management practices effective in managing those issues.'),
(24, 122, 'Retail Management (WAFC)', 10, 'Upon completion of the Certificate of Achievement in Retail Management (WAFC), students are able to list resources and strategies for monitoring trends which help identify the need for new products and services.'),
(24, 122, 'Retail Management (WAFC)', 10, 'Upon completion of the Certificate of Achievement in Retail Management (WAFC), students are able to summarize measures that can be taken by individuals and organizations to correct organizational dysfunctions'),
(24, 122, 'Supervisory Management', 10, 'Upon completion of the Certificate of Achievement in Supervisory Management, students are able to analyze basic business documents to detect problems within an area of supervision.'),
(24, 122, 'Supervisory Management', 10, 'Upon completion of the Certificate of Achievement in Supervisory Management, students are able to demonstrate effective strategies for team work, planning, organizing, leading, and controlling human resources.'),
(24, 122, 'Supervisory Management', 10, 'Upon completion of the Certificate of Achievement in Supervisory Management, students are able to identify appropriate information compilation, reporting, storage and retrieval systems for common business situations.'),
(24, 122, 'Supervisory Management', 10, 'Upon completion of the Certificate of Achievement in Supervisory Management, students are able to list the primary responsibilities of a supervisor in business today.'),
(15, 123, 'Chemistry', 5, 'Upon completion of the AS in Chemistry, students are able to demonstrate proficiency in solving complex problems in and conceptual understanding of Organic Chemistry as measured by the ACS Full-Year Organic Chemistry Exam.'),
(15, 123, 'Chemistry', 5, 'Upon completion of the AS in Chemistry, students are able to demonstrate proficiency in solving complex problems in and conceptual understanding of General Chemistry as measured by the ACS Full-Year General Chemistry Exam.'),
(15, 123, 'Chemistry', 5, 'Upon successful completion of an AS in Chemistry, students are able to design and conduct laboratory experiments, and analyze and interpret their data.'),
(15, 123, 'Chemistry', 5, 'Upon successful completion of an AS in Chemistry, students are able to effectively communicate the methods, analysis, results, and conclusions of their experiments.'),
(15, 123, 'Chemistry', 5, 'Upon successful completion of an AS in Chemistry, students are able to quantitively analyze nature at the atomic scale by applying fundamental chemical concepts, ranging from atomic theory to organic synthesis'),
(15, 123, 'Chemistry', 5, 'Upon successful completion of an AS in Chemistry, students are able to skillfully perform experimental measurements, techniques, and protocols, properly use standard laboratory instruments, and adhere to safe laboratory practices.'),
(15, 123, 'Chemistry Education', 5, 'Upon completion of the AA in Chemistry Education, students are able to demonstrate proficiency in solving complex problems in and conceptual understanding of Organic Chemistry as measured by the ACS Full-Year Organic Chemistry Exam.'),
(15, 123, 'Chemistry Education', 5, 'Upon successful completion of an AS in Chemistry Education, students are able to design and conduct laboratory experiments, and analyze and interpret their data.'),
(15, 123, 'Chemistry Education', 5, 'Upon successful completion of an AS in Chemistry Education, students are able to effectively communicate the methods, analysis, results, and conclusions of their experiments.'),
(15, 123, 'Chemistry Education', 5, 'Upon successful completion of an AS in Chemistry Education, students are able to quantitively analyze nature at the atomic scale by applying fundamental chemical concepts, ranging from atomic theory to organic synthesis.'),
(15, 123, 'Chemistry Education', 5, 'Upon successful completion of an AS in Chemistry Education, students are able to skillfully perform experimental measurements, techniques, and protocols, properly use standard laboratory instruments, and adhere to safe laboratory practices.'),
(12, 124, 'Communication Studies', 2, 'Upon completion of the AA-T in Communication Studies, students are able to describe the Communication discipline and its central questions.'),
(12, 124, 'Communication Studies', 2, 'Upon completion of the AA-T in Communication Studies, students are able to employ communication theories, perspectives, principles, and concepts.'),
(12, 124, 'Communication Studies', 2, 'Upon completion of the AA-T in Communication Studies, students are able to engage in communication inquiry.'),
(12, 124, 'Communication Studies', 2, 'Upon completion of the AA-T in Communication Studies, students are able to create and deliver messages appropriate to the audience, purpose, and context.'),
(12, 124, 'Communication Studies', 2, 'Upon completion of the AA-T in Communication Studies, students are able to critically analyze messages.'),
(12, 124, 'Communication Studies', 2, 'Upon completion of the AA-T in Communication Studies, students are able to apply ethical communication principles and practices.'),
(12, 124, 'Communication Studies', 2, 'Upon completion of the AA-T in Communication Studies, students are able to utilize communication to embrace difference.'),
(15, 125, 'Administrative Assistant', 4, 'Upon completion of the AA in Administrative Assistant, students are able to complete business-related documents using the various functions—basic, intermediate, and advanced—of the software programs: Word, Excel, PowerPoint.'),
(15, 125, 'Administrative Assistant', 10, 'Upon completion of the Certificate of Achievement in Administrative Assistant, students are able to demonstrate the ability to successfully use basic English language skills (grammar, punctuation, capitalization, etc.) in business documents.'),
(15, 125, 'Administrative Assistant', 10, 'Upon completion of the Certification of Achievement in Administrative Assistant, students will be able to create business-related documents using the basic, intermediate, and advanced functions of software programs such as Word, Excel, and PowerPoint.'),
(15, 125, 'Administrative Medical Assistant', 10, 'Upon completion of the Certificate of Achievement in Administrative Medical Assistant, students are able to demonstrate an understanding of basic anatomy, physiology, and disease processes of the human body as it relates to patient medical history.'),
(15, 125, 'Administrative Medical Assistant', 10, 'Upon completion of the Certificate of Achievement in Administrative Medical Assistant, students are able to describe the characteristics and personal qualities that are important for an Administrative Medical Assistant and the importance of ethics, customer service and teamwork in the workplace.'),
(15, 125, 'Cloud Computing', 10, 'Upon completion of the Certificate of Achievement in Cloud Computing, students are able to host a database and run queries using an interface from a commercial provider and run a file-server service using a provider of their choice.'),
(15, 125, 'Computer Applications Software', 10, 'Upon completion of the Certificate of Achievement in Computer Applications Software, students are able to analyze a business problem and develop a solution using appropriate application software.'),
(15, 125, 'Computer Applications Software', 10, 'Upon completion of the Certificate of Achievement in Computer Applications Software, students are able to create appropriate business documents including reports, letters, emails, project plans, messages, and websites, and apply standard business English including grammar, punctuation, and mechanics.'),
(15, 125, 'Computer Information Systems', 4, 'Upon completion of the AA in Computer Information Systems, students are able to analyze a business problem and develop a solution using appropriate applications software.'),
(15, 125, 'Computer Information Technologist', 5, 'Upon completion of the AS in Computer Information Technologist, students are able to demonstrate a strong foundation of knowledge in computer programming, database design and administration, and computer networking.'),
(15, 125, 'Computer Information Technologist', 5, 'Upon completion of the AS in Computer Information Technologist, students are able to demonstrate clear, compelling, analytical, and concise writing to professionally describe their programming, database, and networking project and skills.'),
(15, 125, 'Project Management', 10, 'Upon completion of the Certificate of Accomplishment in Project Management, students are able to analyze a business situation and prepare a response using appropriate business documents including reports letters, emails, and project plans that are clear, compelling, analytical, grammatically correct, and concise.'),
(15, 125, 'Project Management', 10, 'Upon completion of the Certificate of Accomplishment in Project Management, students are able to develop survey questions to determine client requirements, develop project plans that ensure client satisfaction, and demonstrate clear, concise, and analytical writing.'),
(15, 125, 'Web Development', 10, 'Upon completion of the Certificate of Accomplishment in Web Development, students are able to create basic web pages that contain text (utilizing different fonts and colors), hyperlinks to other web sites, graphic images and sound.'),
(15, 125, 'Web Development', 10, 'Upon completion of the Certificate of Accomplishment in Web Development, students are able to create web pages that incorporate JavaScript controls.'),
(15, 125, 'CISCO Network Associate', 10, 'Upon completion of the Certificate of Achievement in Cisco Network Associate, students are able to configure a LAN with routing, Troubleshoot LAN configuration.'),
(15, 125, 'CISCO Network Associate', 10, 'Upon completion of the Certificate of Achievement in Cisco Network Associate, students are able to configure a WAN with routing, Troubleshoot WAN configuration.'),
(15, 125, 'Computer Desktop OS Security', 10, 'Upon completion of the Certificate of Achievement in Computer Desktop OS Security, students are able to install, configure, and manage desktop operating systems.'),
(15, 125, 'Computer Desktop OS Security', 10, 'Upon completion of the Certificate of Achievement in Computer Desktop OS Security, students are able to install, configure, and manage computer and network hardware.'),
(15, 125, 'Computer Desktop OS Security', 10, 'Upon completion of the Certificate of Achievement in Computer Desktop OS Security, students are able to identify, install, configure, and manage common network cables, devices and services.'),
(15, 125, 'Computer Desktop OS Security', 10, 'Upon completion of the Certificate of Achievement in Computer Desktop OS Security, students are able to explain the basic objectives of cybersecurity and the importance of information security.'),
(15, 125, 'Computer Desktop OS Security', 10, 'Upon completion of the Certificate of Achievement in Computer Desktop OS Security, students are able to demonstrate professional behavior such as working in a team and communicating in a professional manner.'),
(15, 125, 'Computer Network Technician', 10, 'Upon completion of the Certificate of Achievement in Computer Network Technician, students are able to install, configure, and manage computer hardware.'),
(15, 125, 'Computer Network Technician', 10, 'Upon completion of the Certificate of Achievement in Computer Network Technician, students are able to install, configure, and manage client and server operating systems.'),
(15, 125, 'Computer Network Technician', 10, 'Upon completion of the Certificate of Achievement in Computer Network Technician, students are able to analyze, design and document computer network specifications to meet client needs.'),
(15, 125, 'Computer Network Technician', 10, 'Upon completion of the Certificate of Achievement in Computer Network Technician, students are able to demonstrate professional behavior such as working in a team and communicating in a professional manner.'),
(15, 125, 'Computer Network Technician', 12, 'Upon completion of the Certificate of Achievement in Computer Network Technician, students are able to install, configure, and manage computer hardware.'),
(15, 125, 'Computer Network Technician', 12, 'Upon completion of the Certificate of Achievement in Computer Network Technician, students are able to install, configure, and manage client and server operating systems.'),
(15, 125, 'Computer Network Technician', 12, 'Upon completion of the Certificate of Achievement in Computer Network Technician, students are able to analyze, design and document computer network specifications to meet client needs.'),
(15, 125, 'Computer Network Technician', 12, 'Upon completion of the Certificate of Achievement in Computer Network Technician, students are able to demonstrate professional behavior such as working in a team and communicating in a professional manner.'),
(15, 125, 'CyberSecurity', 10, 'Upon completion of the Certificate of Achievement in CyberSecurity, students are able to use analytical thinking and critical analysis skills necessary to analyze and solve computer network security issues to help protect computers and computer networks using multiple operating systems.'),
(15, 125, 'CyberSecurity', 10, 'Upon completion of the Certificate of Achievement in CyberSecurity, students are able to use group collaboration and communications skills necessary to work effectively in a team to solve computer networking security issues and to document and present information on security risks and planned responses.'),
(15, 125, 'Digital Forensics Examiner', 10, 'Upon completion of the Certificate of Achievement in Digital Forensics Examiner, students are able to image and examine evidence in a forensically sound manner.'),
(15, 125, 'Digital Forensics Examiner', 10, 'Upon completion of the Certificate of Achievement in Digital Forensics Examiner, students are able to perform evidence examination and evaluation and present in a standard forensic case report.'),
(15, 125, 'IT Support Professional', 11, 'Upon completion of the Certificate of Achievement in IT Support Professional, students are able to achieve the Google IT Support Professional certificate and will be prepared to take the CompTIA A+, Network+, and Security+ certification tests.'),
(15, 125, 'Microsoft Systems Administrator', 10, 'Upon completion of the Certificate of Achievement in Microsoft Systems Administrator, students are able to analyze, design and document computer network specifications to meet client needs.'),
(15, 125, 'Microsoft Systems Administrator', 10, 'Upon completion of the Certificate of Achievement in Microsoft Systems Administrator, students are able to manage users, computers, and groups in Active Directory.'),
(15, 125, 'Microsoft Systems Administrator', 10, 'Upon completion of the Certificate of Achievement in Microsoft Systems Administrator, students are able to demonstrate professional behavior such as working in a team and communicating in a professional manner.'),
(15, 125, 'Network Security and Administration', 5, 'Upon completion of the AS in Network Security and Administration, students are able to install, configure, and manage operating systems.'),
(15, 125, 'Network Security and Administration', 5, 'Upon completion of the AS in Network Security and Administration, students are able to install, configure, and manage computer and network hardware.'),
(15, 125, 'Network Security and Administration', 5, 'Upon completion of the AS in Network Security and Administration, students are able to explain the basic objectives of cybersecurity and the importance of information security.'),
(15, 125, 'Network Security and Administration', 5, 'Upon completion of the AS in Network Security and Administration, students are able to demonstrate professional behavior such as working in a team and communicating in a professional manner.'),
(15, 125, 'Network Security and Administration', 5, 'Upon completion of the AS in Network Security and Administration, students are able to analyze, design, and document computer and network specifications to meet client needs.'),
(15, 125, 'Computer Programming', 10, 'Upon completion of the Certificate of Achievement in Computer Programming, students are able to professionally demonstrate the application of their skills in the development and testing of their solution to solve a specific computing project.'),
(15, 125, 'Computer Programming', 10, 'Upon completion of the Certificate of Achievement in Computer Programming, students are able to professionally describe and apply their skills in the design of their solutions as well as alternative technologies or solutions to solve their specific computing project.'),
(15, 125, 'Computer Programming for the Web', 10, 'Upon completion of the Certificate of Achievement in Computer Programming for the Web, students are able to direct computer operations by writing detailed instructions in computer languages.'),
(15, 125, 'Computer Programming for the Web', 10, 'Upon completion of the Certificate of Achievement in Computer Programming for the Web, students are able to implement interactive web pages using high level programming language instructions to implement specific information internet-based solutions.'),
(15, 125, 'Computer Programming for the Web', 10, 'Upon completion of the Certificate of Achievement in Computer Programming for the Web, students are able to professionally demonstrate the application of their web development skills in the development of their solution to solve a specific internet-based computer project.'),
(15, 125, 'Computer Science', 5, 'Upon completion of the AS in Computer Science, students are able to direct computer operations by writing detailed instructions in computer languages to solve a variety of problems.'),
(15, 125, 'Computer Science', 5, 'Upon completion of the AS in Computer Science, students are able to analyze, design, and solve complex computer-based problems using both logical and mathematical methods including the implementation of control and data structures.'),
(15, 125, 'Computer Science', 5, 'Upon completion of the AS in Computer Science, students are able to professionally describe and apply their skills in the design of their complex computer system or algorithm and be able to show how their solution is the most optimal'),
(24, 129, 'Economics', 2, 'Upon completion of the AA-T in Economics, students are able to use marginal analysis to explain how individuals in the economy make their production and purchasing decisions.'),
(24, 129, 'Economics', 2, 'Upon completion of the AA-T in Economics, students are able to explain how market forces of supply and demand lead to efficient allocation of goods, services and factors of production.'),
(24, 129, 'Economics', 2, 'Upon completion of the AA-T in Economics, students are able to use key economic indicators, such as GDP, CPI and Unemployment Rate, to analyze the economy and explain how monetary and fiscal policies affect short-term fluctuations of economic activity.'),
(20, 130, 'Emergency Medical Responder', 12, 'Upon completion of the Certificate of Accomplishment in Emergency Medical Responder, students are able to competent as an entry-level Emergency Medical Responder in the cognitive (knowledge), psychomotor (skills), and affective (behavior) learning domains with exit points at the Emergency Medical Responder levels and certified to provide Basic Life Support CPR.'),
(20, 130, 'Emergency Medical Responder', 12, 'Upon completion of the Certificate of Accomplishment in Emergency Medical Responder, students are prepared to become an Emergency Medical Responder (EMR) through registration with the National Registry of EMT''s.'),
(20, 130, 'Emergency Medical Responder', 12, 'Upon completion of the Certificate of Accomplishment in Emergency Medical Responder, students are competent and prepared for employment as a Lifeguard, Police Officer, and/or Search and Rescue Squad member.'),
(20, 130, 'Emergency Medical Sciences', 5, 'The program prepares students to become a Nationally Registered Emergency Medical Technician-Paramedic (NREMTP). '),
(20, 130, 'Emergency Medical Sciences', 5, 'Upon completion of the AS in Emergency Medical Services EMT-Paramedic, students are prepared to become a Nationally Registered Paramedic (NRP).'),
(20, 130, 'Emergency Medical Sciences', 5, 'Upon completion of the AS in Emergency Medical Services EMT-Paramedic, students are prepared as a competent entry-level Paramedics in the cognitive (knowledge) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Sciences', 5, 'Upon completion of the AS in Emergency Medical Services EMT-Paramedic, students are prepared as a competent entry-level Paramedics in the psychomotor (skills) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Sciences', 5, 'Upon completion of the AS in Emergency Medical Services EMT-Paramedic, students are prepared as a competent entry-level Paramedics in the affective (behavior) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 5, 'The program prepares students to become a Nationally Registered Emergency Medical Technician-Paramedic (NREMTP). '),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 5, 'Upon completion of the AS in Emergency Medical Services EMT-Paramedic, students are prepared to become a Nationally Registered Paramedic (NRP).'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 5, 'Upon completion of the AS in Emergency Medical Services EMT-Paramedic, students are prepared as a competent entry-level Paramedics in the cognitive (knowledge) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 5, 'Upon completion of the AS in Emergency Medical Services EMT-Paramedic, students are prepared as a competent entry-level Paramedics in the psychomotor (skills) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 5, 'Upon completion of the AS in Emergency Medical Services EMT-Paramedic, students are prepared as a competent entry-level Paramedics in the affective (behavior) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 10, 'The program prepares students to become a Nationally Registered Emergency Medical Technician-Paramedic (NREMTP).'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 10, 'Upon completion of the Certificate of Achievement in Emergency Medical Services EMT-Paramedic, students are prepared to become a Nationally Registered Paramedic (NRP).'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 10, 'Upon completion of the Certificate of Achievement in Emergency Medical Services EMT-Paramedic, students are prepared as a competent entry-level Paramedics in the psychomotor (skills) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 10, 'Upon completion of the Certificate of Achievement in Emergency Medical Services EMT-Paramedic, students are prepared as a competent entry-level Paramedics in the affective (behavior) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Services EMT-Paramedic', 10, 'Upon completion of the Certificate of Achievement in Emergency Medical Services EMT-Paramedics, students are prepared as a competent entry-level Paramedics in the cognitive (knowledge) learning domain with or without exit points at the Advanced Emergency Medical Technician and/or Emergency Medical Technician, and/or Emergency Medical Responder levels.'),
(20, 130, 'Emergency Medical Technologies', 10, 'Upon completion of the Certificate of Achievement in Emergency Medical Technologies, students are prepared to become a Nationally Registered Emergency Medical Technician (NREMT).'),
(20, 130, 'Emergency Medical Technologies', 10, 'Upon completion of the Certificate of Achievement in Emergency Medical Technologies, students are able to function at the California State certified level of EMT.'),
(20, 130, 'Emergency Medical Technologies', 11, 'Upon completion of the Certificate of Achievement in Emergency Medical Technologies, students are prepared to become a Nationally Registered Emergency Medical Technician (NREMT).'),
(20, 130, 'Emergency Medical Technologies', 11, 'Upon completion of the Certificate of Achievement in Emergency Medical Technologies, students are able to function at the California State certified level of EMT.'),
(12, 132, 'English', 4, 'Upon completion of the AA in English, students are able to identify and evaluate implied arguments in college-level literary texts.'),
(12, 132, 'English', 4, 'Upon completion of the AA in English, students are able to recognize, appreciate, and compare the similarities and differences between authors, characters and self that stem from historical era and cultural tradition.'),
(12, 132, 'English', 4, 'Upon completion of the AA in English, students are able to write an academic essay synthesizing multiple texts and using logic to support a thesis.'),
(12, 132, 'English', 4, 'Upon completion of the AA in English, students are able to analyze an author''s use of literary techniques to develop a theme.'),
(12, 132, 'English', 4, 'Upon completion of the AA in English, students are able to write a research paper using credible sources and correct documentation.'),
(12, 132, 'English', 4, 'Upon completion of the AA in English, students are able to use grammar, vocabulary and style appropriate for academic essays.'),
(12, 132, 'English', 2, 'Upon completion of the AA-T in English, students are able to write an academic essay synthesizing multiple texts and using logic to support a thesis.'),
(12, 132, 'English', 2, 'Upon completion of the AA-T in English, students are able to analyze an author''s use of literary techniques to develop a theme.'),
(12, 132, 'English', 2, 'Upon completion of the AA-T in English, students are able to recognize, appreciate, and compare the similarities and differences between authors, characters and self that stem from historical era and cultural tradition.'),
(12, 132, 'English', 2, 'Upon completion of the AA-T in English, students are able to write a research paper using credible sources and correct documentation.'),
(12, 132, 'English', 2, 'Upon completion of the AA-T in English, students are able to use grammar, vocabulary, and style appropriate for academic essays.'),
(12, 132, 'English', 2, 'Upon completion of the AA-T in English, students are able to identify and evaluate implied arguments in college-level literary texts.'),
(12, 132, 'Creative Writing', 10, 'Upon completion of the Certificate of Achievement in Creative Writing, students are able to analyze and write about a diverse body of published literature.'),
(12, 132, 'Creative Writing', 10, 'Upon completion of the Certificate of Achievement in Creative Writing, students are able to evaluate and critique works of fiction and/or poetry.'),
(12, 132, 'Creative Writing', 10, 'Upon completion of the Certificate of Achievement in Creative Writing, students are able to perform entry-level editorial tasks on a magazine, journal, or newspaper.'),
(12, 132, 'Creative Writing', 10, 'Upon completion of the Certificate of Achievement in Creative Writing, students are able to write and revise fiction and/or poetry, demonstrating proficiency with the elements of fiction and/or poetry.'),
(15, 134, 'Environmental Studies', 2, 'Upon completion of the AA in Environmental Studies, students are able to conduct a literature search, identify and evaluate legitimate sources, and clearly communicate the results.'),
(15, 134, 'Environmental Studies', 2, 'Upon completion of the AA in Environmental Studies, students are able to analyze natural phenomena using fundamental scientific principles in the physical and biological sciences.'),
(15, 134, 'Environmental Studies', 2, 'Upon completion of the AA in Environmental Studies, students are able to construct arguments for environmental policy based on a sociopolitical and scientific understanding of human interactions with the environment.'),
(15, 134, 'Environmental Studies', 5, 'Upon completion of the AS in Environmental Science, students are able to conduct a literature search, identify and evaluate legitimate sources, and clearly communicate the results.'),
(15, 134, 'Environmental Studies', 5, 'Upon completion of the AS in Environmental Science, students are able to analyze natural phenomena using appropriate mathematical and computational tools employed in the physical and biological sciences.'),
(15, 134, 'Environmental Studies', 5, 'Upon completion of the AS in Environmental Science, students are able to use the scientific method to perform experiments, mathematically analyze the data, and evaluate the results.'),
(12, 142, 'Film Studies', 4, 'Upon completion of the AA in Film Studies, students are able to analyze films in terms of their formal elements: narrative structure, mise-en-scene, cinematography, editing, and sound.'),
(12, 142, 'Film Studies', 4, 'Upon completion of the AA in Film Studies, students are able to create a short film or video using basic camera, lighting, and sound equipment, as well as editing software.'),
(12, 142, 'Film Studies', 4, 'Upon completion of the AA in Film Studies, students are able to draw on a basic knowledge of film theory and film history to compare and contrast major film types and film genres.'),
(12, 142, 'Film Studies', 4, 'Upon completion of the AA in Film Studies, students are able to explain the impact of film on modern media and contemporary culture.'),
(12, 142, 'Film Studies', 10, 'Upon completion of the Certificate of Achievement in Film Studies, students are able to create a short film or video using basic camera, lighting, and sound equipment, and editing software.'),
(12, 142, 'Film Studies', 10, 'Upon completion of the Certificate of Achievement in Film Studies, students are able to draw on a basic knowledge of film theory and film history to compare and contrast major film types and film genres.'),
(12, 142, 'Film Studies', 10, 'Upon completion of the Certificate of Achievement in Film Studies, students are able to explain the impact of film on modern media and contemporary culture.'),
(12, 142, 'Film Studies', 10, 'Upon completion of the Certificate of Achievement in Film Studies, students are able to analyze films in terms of their formal elements: narrative structure, mise-en-scene, cinematography, editing, and sound.'),
(15, 136, 'Geography', 2, 'Upon completion of the AA-T in Geography, students are able to assemble and analyze spatial information (maps, data, surveys, qualitative observations, etc), using traditional and modern mapping technology methods'),
(15, 136, 'Geography', 2, 'Upon completion of the AA-T in Geography, students are able to demonstrate knowledge of global physical and environmental processes, locations and develop an appreciation of landscapes'),
(15, 136, 'Geology', 3, 'Upon completion of the AS-T in Geology, students are able to demonstrate proficiency in basic earth processes (e.g., plate tectonics).'),
(15, 136, 'Geology', 3, 'Upon completion of the AS-T in Geology, students are able to demonstrate proficiency in the evaluation and identification of basic earth materials (e.g., rocks and minerals).'),
(15, 136, 'Geology', 11, 'Upon completion of the Certificate of Achievement in Geology, students are able to demonstrate proficiency in fundamental global earth processes (e.g., plate tectonics, earthquakes, volcanoes, etc.)'),
(15, 136, 'Geology', 11, 'Upon completion of the Certificate of Achievement in Geology, students are able to demonstrate proficiency with geologic analysis and/or geologic tools (e.g., unraveling the chronology of geologic events, earth materials identification/evaluation, etc.)'),
(15, 136, 'Geology Major', 10, 'Upon completion of the Certificate of Achievement in Geology Major, students are able to demonstrate proficiency in geologic processes and concepts (e.g., plate tectonics, earthquakes, volcanoes, landslides, hydrology, geochronology, etc).'),
(15, 136, 'Geology Major', 10, 'Upon completion of the Certificate of Achievement in Geology Major, students are able to demonstrate proficiency with geologic analysis and/or geologic tools (e.g., mineralogy, petrology, topography and/or geologic maps and structures, unraveling the chronology of geologic events, earth materials identification/evaluation, etc.).'),
(24, 158, 'Global Studies', 2, 'Upon completion of an AA-T in Global Studies, students are able to assess the benefits and costs of globalization to various classes, regions, nations, and ethnic groups across the globe'),
(24, 158, 'Global Studies', 2, 'Upon completion of an AA-T in Global Studies, students are able to use social scientific and humanist modes of analysis to relate and differentiate between cultures.'),
(24, 158, 'Global Studies', 2, 'Upon completion of an AA-T in Global Studies, students are able to apply cross-cultural, transnational, and global awareness to analysis of conflicts and challenges involving race, gender, human rights, cultural differences, and economic development.'),
(24, 158, 'Global Studies', 2, 'Upon completion of an AA-T in Global Studies, students are able to demonstrate knowledge of world''s cultures, languages, art, geography, climate, social and political systems.'),
(20, 139, 'Public Health Science', 2, 'Upon completion of the AS-T in Public Health Science, students are able to describe factors that contribute to health disparities and leading causes of morbidity and mortality, including factors related to public policy, socioeconomics, and the environment'),
(20, 139, 'Public Health Science', 2, 'Upon completion of the AS-T in Public Health Science, students are able to develop strategies for initiating and/ or maintaining activities that promote health through individual behavior, civic/community engagement, and/or environmental stewardship.'),
(20, 139, 'Public Health Science', 2, 'Upon completion of the AS-T in Public Health Science, students are able to critically evaluate popular and scientific literature and other media for its significance and impact on individual and public health.'),
(24, 140, 'History', 2, 'Upon completion of the AA-T in History, students are able to analyze and interpret historical sources and to compose an argument that uses them, as appropriate, for support.'),
(24, 140, 'History', 2, 'Upon completion of the AA-T in History, students are able to explain major developments in United States and World History.'),
(24, 140, 'History', 2, 'Upon completion of the AA-T in History, students are able to explain United States and World History from multiple viewpoints, perspectives, and experiences.'),
(12, 142, 'Humanities', 4, 'Upon completion of the AA in Humanities, students are able to interpret and analyze aspects of culture and art by applying theoretical methods used in the humanities.'),
(12, 142, 'Humanities', 4, 'Upon completion of the AA in Humanities, students are able to discuss important themes expressed in material culture and belief systems as seen throughout global history.'),
(12, 142, 'Humanities', 4, 'Upon completion of the AA in Humanities, students are able to formally evaluate works of art using the elements and principles of art.'),
(12, 142, 'Humanities', 4, 'Upon completion of the AA in Humanities, students are able to express and explain their appreciation for the arts through discussion and writing.'),
(12, 142, 'Humanities', 10, 'Upon completion of the Certificate of Achievement in Humanities, students are able to express and explain their appreciation for the arts through discussion and writing.'),
(12, 142, 'Humanities', 10, 'Upon completion of the Certificate of Achievement in Humanities, students are able to discuss important themes expressed in material culture and belief systems as seen throughout global history.'),
(12, 142, 'Humanities', 10, 'Upon completion of the Certificate of Achievement in Humanities, students are able to formally evaluate works of art using the elements and principles of art.'),
(12, 142, 'Humanities', 10, 'Upon completion of the Certificate of Achievement in Humanities, students are able to critically interpret and analyze aspects of culture and art by applying theoretical methods used in the humanities.'),
(12, 143, 'Interior Design', 5, 'Upon completion of the AS in Interior Design, students are able to demonstrate the skills and knowledge learned through coursework to meet CSU transfer requirements.'),
(12, 143, 'Interior Design', 10, 'Upon completion of the Certificate of Achievement in Interior Design, students are able to work in a professional design company with both business and design education.'),
(20, 145, 'Athletic Training/Sports Medicine', 10, 'Upon completion of the Certificate of Achievement in Athletic Training/ Sports Medicine, students are able to demonstrate professional and ethical behaviors expected of the athletic trainer as a healthcare professional.'),
(20, 145, 'Athletic Training/Sports Medicine', 10, 'Upon completion of the Certificate of Achievement in Athletic Training/ Sports Medicine, students are able to develop critical thinking, problem solving, and decision-making skills as it pertains to clinical practice.'),
(20, 145, 'Athletic Training/Sports Medicine', 10, 'Upon completion of the Certificate of Achievement in Athletic Training/ Sports Medicine, students are able to gain entry-level employment in the Sports Medicine field.'),
(20, 145, 'Athletic Training/Sports Medicine', 10, 'Upon completion of the Certificate of Achievement in Athletic Training/ Sports Medicine, students are able to gain knowledge and skills in all five domains of athletic training.'),
(20, 145, 'Fitness Trainer', 10, 'Upon completion of the Certificate of Achievement in Fitness Trainer, students are able to develop and administer a safe and effective periodized exercise program designed for a client.'),
(20, 145, 'Fitness Trainer', 10, 'Upon completion of the Certificate of Achievement in Fitness Trainer, students are able to estimate heart rate, maximum heart rate and, target heart rate, and perform CPR with AED and rescue breathing.'),
(20, 145, 'Fitness Trainer', 10, 'Upon completion of the Certificate of Achievement in Fitness Trainer, students are able to identify modifiable and non-modifiable risk factors for personal health, locate health information related to behavior change processes, evaluate the credibility of those sources, and integrate and apply scientific research into individual behavior change processes for clients.'),
(20, 145, 'Fitness Trainer', 10, 'Upon completion of the Certificate of Achievement in Fitness Trainer, students are able to work in the field of personal trainers and as a group fitness instructor, and also identify a number of career options in the kinesiology field.'),
(20, 145, 'Kinesiology', 2, 'Upon completion of the AA-T in Kinesiology, students are able to disseminate the knowledge of physical activity derived from experiences, scholarly study, and professional practice.'),
(20, 145, 'Kinesiology', 2, 'Upon completion of the AA-T in Kinesiology, students are able to perform a variety of motor activities at a proficient level from at least three of the movement-based categories.'),
(20, 145, 'Kinesiology', 2, 'Upon completion of the AA-T in Kinesiology, students are able to identify programs of study as well as career pathways within the field of Kinesiology.'),
(25, 118, 'Liberal Arts & Sciences: Arts and Humanities', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Arts and Humanities, students are able to critically analyze important texts and ideas within the global intellectual tradition.'),
(25, 118, 'Liberal Arts & Sciences: Arts and Humanities', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Arts and Humanities, students are able to apply art theory to specific works of art.'),
(25, 118, 'Liberal Arts & Sciences: Business', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Business, students are able to identify and describe types of business organizations and operations, as well as the effects of legal environments, when making a selection.'),
(25, 118, 'Liberal Arts & Sciences: Business', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Business, students are able to describe the significance of marketing functions including Price, Product, Place and Promotion in a product life cycle.'),
(25, 118, 'Liberal Arts & Sciences: Business', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Business, students are able to compare, contrast, and apply ethical standards and use best practices regarding the social responsibility of a business.'),
(25, 118, 'Liberal Arts & Sciences: Computer Studies', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Computer Studies, students are able to demonstrate a strong foundation of knowledge in computer hardware, software, networking, and programming.'),
(25, 118, 'Liberal Arts & Sciences: Language Arts and Communication', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Language Arts and Communication, students are able to apply critical thinking principles to the evaluation of human symbolic interaction.'),
(25, 118, 'Liberal Arts & Sciences: Language Arts and Communication', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Language Arts and Communication, students are able to recognize and appreciate the value of a multicultural world and of diversity in its many forms.'),
(25, 118, 'Liberal Arts & Sciences: Language Arts and Communication', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Language Arts and Communication, students are able to choose and apply appropriate communication strategies based on consideration of audience and purpose.'),
(25, 118, 'Liberal Arts & Sciences: Mathematics and Science', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Mathematics and Science, students are able to apply mathematical and scientific ideas to analyze real-world situations.'),
(25, 118, 'Liberal Arts & Sciences: Mathematics and Science', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Mathematics and Science, students are able to read, write, listen to, and speak about mathematical and scientific ideas with understanding.'),
(25, 118, 'Liberal Arts & Sciences: Mathematics and Science', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Mathematics and Science, students are able to use scientific reasoning to solve problems or conduct research, and assess the reasonableness of their results.'),
(25, 118, 'Liberal Arts & Sciences: Mathematics and Science', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Mathematics and Science, students are able to use appropriate technology and/or tools to enhance their scientific thinking and understanding.'),
(25, 118, 'Liberal Arts & Sciences: Social and Behavioral Sciences', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Social and Behavioral Sciences, students are able to identify the major ideas, values, beliefs, and experiences that have shaped human history and cultures.'),
(25, 118, 'Liberal Arts & Sciences: Social and Behavioral Sciences', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Social and Behavioral Sciences, students are able to describe the major concepts, theoretical perspectives, empirical findings, and historical trends in the social science disciplines.'),
(25, 118, 'Liberal Arts & Sciences: Social and Behavioral Sciences', 4, 'Upon completion of the AA in Liberal Arts & Sciences: Social and Behavioral Sciences, students are able to apply basic social scientific methods to investigate the relationships among individuals, cultures, and societies.'),
(24, 122, 'Marketing', 4, 'Upon completion of the AA in Marketing, students are able to compare and contrast the processes used to determine the (1) demand for products and services to be offered by a firm and the (2) identification of appropriate target markets.'),
(24, 122, 'Marketing', 4, 'Upon completion of the AA in Marketing, students are able to construct a detailed marketing plan, which includes  all aspects of the marketing mix.'),
(24, 122, 'Marketing', 4, 'Upon completion of the AA in Marketing, students are able to demonstrate knowledge of business operations, the business organization, business environments, and business procedures.'),
(24, 122, 'Marketing', 4, 'Upon completion of the AA in Marketing, students are able to detail available pricing strategies and prepare comparisons of strategies to achieve a firm’s market objectives.'),
(24, 122, 'Retailing', 10, 'Upon completion of the Certificate of Achievement in Retailing, students are able to compare and contrast the various pricing strategies.'),
(24, 122, 'Retailing', 10, 'Upon completion of the Certificate of Achievement in Retailing, students are able to determine the demand for products and services offered by a firm and identify potential customers.'),
(24, 122, 'Retailing', 10, 'Upon completion of the Certificate of Achievement in Retailing, students are able to develop pricing strategies with the goal of maximizing the firm’s profits and/or market share while ensuring customer satisfaction.'),
(24, 122, 'Retailing', 10, 'Upon completion of the Certificate of Achievement in Retailing, students are able to explain promotional mixes and effective strategies for each.'),
(24, 122, 'Retailing', 10, 'Upon completion of the Certificate of Achievement in Retailing, students are able to identify distinctions between distribution channels.'),
(24, 122, 'Retailing', 10, 'Upon completion of the Certificate of Achievement in Retailing, students are able to identify the primary business operations, business organizational options, and business procedures.'),
(24, 122, 'Retailing', 10, 'Upon completion of the Certificate of Achievement in Retailing, students are able to list resources and strategies for monitoring trends which help identify the need for new products and services.'),
(24, 122, 'Retailing', 10, 'Upon completion of the Certificate of Achievement in Retailing, students are able to summarize measures that can be taken by individuals and organizations to correct organizational dysfunctions.'),
(15, 147, 'Mathematics', 3, 'Upon completion of the Mathematics AS-T, students are able to learn mathematics through modeling real-world situations.'),
(15, 147, 'Mathematics', 3, 'Upon completion of the Mathematics AS-T, students are able to read, write, listen to, and speak mathematics with understanding.'),
(15, 147, 'Mathematics', 3, 'Upon completion of the Mathematics AS-T, students are able to use appropriate technology to enhance their mathematical thinking and understanding, solve mathematical problems, and judge the reasonableness of their results.'),
(15, 147, 'Mathematics', 3, 'Upon completion of the Mathematics AS-T, students are able to use mathematical reasoning and, when appropriate, a general problem-solving process to solve problems.'),
(15, 147, 'Mathematics', 3, 'Upon completion of the Mathematics AS-T, students are able to demonstrate the ability to use symbolic, graphical, numerical, and written representations of mathematical ideas.'),
(20, 119, 'Automotive Basic', 6, 'Upon completion of the Certificate of Completion in Automotive Basic, students are able to diagnose basic engine mechanical issues.'),
(20, 119, 'Automotive Basic', 6, 'Upon completion of the Certificate of Completion in Automotive Basic, students are able to measure engine components and compare to specifications.'),
(20, 119, 'Automotive Basic', 6, 'Upon completion of the Certificate of Completion in Automotive Basic, students are able to tear down, inspect and reassemble engines.'),
(20, 119, 'Automotive Smog', 6, 'Upon completion of the Certificate of Completion in Automotive Smog, students are able to apply and take the California Smog test.'),
(20, 119, 'Automotive Smog', 6, 'Upon completion of the Certificate of Completion in Automotive Smog, students are able to diagnose emission issues.'),
(20, 119, 'Automotive Smog', 6, 'Upon completion of the Certificate of Completion in Automotive Smog, students are able to diagnose engine mechanical issues.'),
(24, 122, 'Customer Service', 6, 'Upon completion of the Certificate of Completion in Customer Service, students are able to demonstrate how to prioritize responsibilities in relation to deadlines/time demands.'),
(24, 122, 'Customer Service', 6, 'Upon completion of the Certificate of Completion in Customer Service, students are able to identify personal strengths and areas of improvement in relation to business roles and expertise.'),
(24, 122, 'Customer Service', 6, 'Upon completion of the Certificate of Completion in Customer Service, students are able to recognize multiple tools in improving customer satisfactions and loyalty.'),
(24, 122, 'Small Business Management', 6, 'Upon completion of the Certificate of Completion in Small Business Management, students are able to demonstrate the ability to comprehend, apply, and evaluate standards of ethical behavior in various business settings.'),
(24, 122, 'Small Business Management', 6, 'Upon completion of the Certificate of Completion in Small Business Management, students are able to evaluate the feasibility of success when starting a new business venture.'),
(24, 122, 'Small Business Management', 6, 'Upon completion of the Certificate of Completion in Small Business Management, students are able to recognize the advantages and disadvantages of the various forms of business ownership relative to a business opportunity.'),
(24, 122, 'Small Business Management', 6, 'Upon completion of the Certificate of Completion in Small Business Management, students are able to research and compose a business plan that can be used for planning as well as financing.'),
(12, 133, 'ESL College Reading and Writing Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Reading and Writing Pathway, students are able to matriculate into credit, transfer-level ESL courses.'),
(12, 133, 'ESL College Reading and Writing Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Reading and Writing Pathway, students are able to use foundational grammar, including all verb tenses and types of sentences.'),
(12, 133, 'ESL College Reading and Writing Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Reading and Writing Pathway, students are able to utilize a variety of study skills and strategies for language acquisition.'),
(12, 133, 'ESL College Reading and Writing Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Reading and Writing Pathway, students are able to write paragraphs and essays with control of organization, development and language at the intermediate level.'),
(12, 133, 'ESL College Reading and Writing Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Reading and Writing Pathway, students are able to comprehend a variety of authentic reading materials at the intermediate level.'),
(12, 133, 'ESL College Grammar Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Grammar Pathway, students are able to analyze grammatical content in written discourse for comprehension.'),
(12, 133, 'ESL College Grammar Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Grammar Pathway, students are able to apply grammatical concepts in writing.'),
(12, 133, 'ESL College Grammar Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Grammar Pathway, students are able to matriculate into credit, transfer-level ESL courses.'),
(12, 133, 'ESL College Grammar Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Grammar Pathway, students are able to use academic vocabulary, including parts of speech, at the intermediate level.'),
(12, 133, 'ESL College Grammar Pathway', 7, 'Upon completion of the Certificate of Competency in ESL College Grammar Pathway, students are able to use foundational grammar, including all verb tenses and types of sentences.'),
(12, 133, 'Advanced ESL Communication Studies', 6, 'Upon completion of the Certificate of Completion in Advanced ESL Communication Studies, students are able to demonstrate an awareness of cultural norms appropriate to specific public speaking situations.'),
(12, 133, 'Advanced ESL Communication Studies', 6, 'Upon completion of the Certificate of Completion in Advanced ESL Communication Studies, students are able to establish an effective and assertive presence in formal speaking situations such as academic courses, job interviews, professional meetings, and presentations.'),
(12, 133, 'Advanced ESL Communication Studies', 6, 'Upon completion of the Certificate of Completion in Advanced ESL Communication Studies, students are able to give responses using appropriate and concise rhetorical frames in common formal speaking situations, such as academic courses, job interviews, professional meetings, and presentations.'),
(15, 141, 'Horticulture', 6, 'Upon completion of the Certificate of Completion in Horticulture, students are able to demonstrate a basic understanding of the field of horticulture and possible career opportunities.'),
(15, 141, 'Horticulture', 6, 'Upon completion of the Certificate of Completion in Horticulture, students are able to demonstrate an understanding of propagation of plants by seed and vegetative cuttings.'),
(15, 141, 'Horticulture', 6, 'Upon completion of the Certificate of Completion in Horticulture, students are able to demonstrate an understanding of the maintenance requirements for trees, vines, shrubs, perennials, annuals, and turf.'),
(15, 141, 'Horticulture', 6, 'Upon completion of the Certificate of Completion in Horticulture, students are able to identify plants and be able to select their proper care and maintenance'),
(15, 147, 'College Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to use symbolic, graphical, numerical, and written representations of mathematical ideas.'),
(15, 147, 'College Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to read, write, listen to, and speak mathematics with understanding.'),
(15, 147, 'College Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to use appropriate technology to enhance their mathematical thinking and understanding, solve mathematical problems, and judge the reasonableness of their results.'),
(15, 147, 'College Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to use mathematical reasoning and, when appropriate, a general problem solving process to solve problems.'),
(15, 147, 'College Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to learn mathematics through modeling real-world situations.'),
(15, 147, 'College Mathematics Support', 7, 'Upon completion of the Certificate of Competency in College Mathematics Support, students are able to demonstrate the appropriate skills necessary to become a more productive, successful, and independent learner.'),
(15, 147, 'College Mathematics Support', 7, 'Upon completion of the Certificate of Competency in College Mathematics Support, students are able to formulate short-term and long-term learning objectives based on their academic goal(s). Students in this program have a goal to develop their knowledge, skills and abilities in preparing transfer.'),
(15, 147, 'College Mathematics Support', 7, 'Upon completion of the Certificate of Competency in College Mathematics Support, students are able to learn and apply study skills and life skills that will improve the student''s likelihood of succeeding in their academic goals (examples of topics include brain research, identifying their individual growth mindset, personal time management, test taking and conquering math anxiety strategies, etc.).'),
(15, 147, 'College Mathematics Support', 7, 'Upon completion of the Certificate of Competency in College Mathematics Support, students are able to use prerequisite topics effectively in their target mathematics course.'),
(15, 147, 'Foundational Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to use mathematical reasoning and, when appropriate, a general problem solving process to solve problems.'),
(15, 147, 'Foundational Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to learn mathematics through modeling real-world situations.'),
(15, 147, 'Foundational Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to read, write, listen to, and speak mathematics with understanding.'),
(15, 147, 'Foundational Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to use appropriate technology to enhance their mathematical thinking and understanding, solve mathematical problems, and judge the reasonableness of their results.'),
(15, 147, 'Foundational Mathematics Pathway', 7, 'Upon completion of the Certificate of Competency in College Mathematics Pathway, students are able to demonstrate the ability to use symbolic, graphical, numerical, and written representations of mathematical ideas.'),
(15, 147, 'Foundational Mathematics Support', 7, 'Upon completion of the Certificate of Competency in Foundational Mathematics Support, students are able to demonstrate the appropriate skills necessary to become a more productive, successful, and independent learner.'),
(15, 147, 'Foundational Mathematics Support', 7, 'Upon completion of the Certificate of Competency in Foundational Mathematics Support, students are able to learn and apply study skills and life skills that will improve the student''s likelihood of succeeding in their academic goals (examples of topics include brain research, identifying their individual growth mindset, personal time management, test taking and conquering math anxiety strategies, etc.).'),
(15, 147, 'Foundational Mathematics Support', 7, 'Upon completion of the Certificate of Competency in Foundational Mathematics Support, students are able to formulate short-term and long-term learning objectives based on their academic goal(s). Students in this program have a goal to develop their knowledge, skills and abilities in preparing to obtain an Associate’s degree.'),
(15, 147, 'Foundational Mathematics Support', 7, 'Upon completion of the Certificate of Competency in Foundational Mathematics Support, students are able to use prerequisite topics effectively in their target mathematics course.'),
(15, 147, 'Math Jam for College Mathematics', 7, 'Upon completion of the Certificate of Competency in Math Jam for College Mathematics, students are able to learn study skills and life skills that will improve the student''s likelihood of succeeding in their academic goals (examples of topics include brain research, identifying their individual growth mindset, personal time management, test taking and conquering math anxiety strategies, etc.).'),
(15, 147, 'Math Jam for College Mathematics', 7, 'Upon completion of the Certificate of Competency in Math Jam for College Mathematics, students are able to formulate short-term and long-term learning objectives based on their academic goal(s). Students in this program have a goal to develop their knowledge, skills and abilities in preparing to transfer.'),
(15, 147, 'Math Jam for College Mathematics', 7, 'Upon completion of the Certificate of Competency in Math Jam for College Mathematics, students are able to apply prerequisite mathematical topics at a higher level.'),
(15, 147, 'Math Jam for College Mathematics', 7, 'Upon completion of the Certificate of Competency in Math Jam for College Mathematics, students are able to demonstrate the appropriate skills necessary to become a more productive, successful, and independent learner.'),
(15, 147, 'Math Jam for Foundational Mathematics', 7, 'Upon completion of the Certificate of Competency in Math Jam for Foundational Mathematics, students are able to apply basic skills mathematical concepts at a higher level.'),
(15, 147, 'Math Jam for Foundational Mathematics', 7, 'Upon completion of the Certificate of Competency in Math Jam for Foundational Mathematics, students are able to demonstrate the appropriate skills necessary to become a more productive, successful, and independent learner.'),
(15, 147, 'Math Jam for Foundational Mathematics', 7, 'Upon completion of the Certificate of Competency in Math Jam for Foundational Mathematics, students are able to formulate short-term and long-term learning objectives based on their academic goal(s). Students in this program have a goal to develop their knowledge, skills and abilities in preparing to obtain an Associate’s degree.'),
(15, 147, 'Math Jam for Foundational Mathematics', 7, 'Upon completion of the Certificate of Competency in Math Jam for Foundational Mathematics, students are able to learn study skills and life skills that will improve the student''s likelihood of succeeding in their academic goals (examples of topics include brain research, identifying their individual growth mindset, personal time management, test taking and conquering math anxiety strategies, etc.).'),
(15, 147, 'Math Jam Tutor Pathway', 7, 'Upon completion of the Certificate of Completion in Math Jam Tutor Pathway, students are able to provide guided math workshops to students on historically difficult topics with the support of instructors and fellow tutors.'),
(15, 147, 'Math Jam Tutor Pathway', 7, 'Upon completion of the Certificate of Completion in Math Jam Tutor Pathway, students are able to coach students in how to be an effective learner, using Growth Mindset theory and intelligent practices to be successful.'),
(15, 147, 'Math Jam Tutor Pathway', 7, 'Upon completion of the Certificate of Completion in Math Jam Tutor Pathway, students are able to apply mathematical concepts at a higher level.'),
(15, 147, 'Math Jam Tutor Pathway', 7, 'Upon completion of the Certificate of Completion in Math Jam Tutor Pathway, students are able to assist students comfortably in a lab setting.'),
(15, 147, 'Math Jam Tutor Pathway', 7, 'Upon completion of the Certificate of Completion in Math Jam Tutor Pathway, students are able to communicate effectively about theory of Growth Mindset, as an individual and as a tutor.'),
(15, 147, 'Math Jam Tutor Pathway', 7, 'Upon completion of the Certificate of Completion in Math Jam Tutor Pathway, students are able to model effective problem-solving, growth mindset and study skills.'),
(15, 147, 'Math Jam Tutor Pathway', 7, 'Upon completion of the Certificate of Completion in Math Jam Tutor Pathway, students are able to navigate an online support course environment effectively.'),
(15, 147, 'Math Jam Tutor Pathway', 7, 'Upon completion of the Certificate of Completion in Math Jam Tutor Pathway, students are able to support students in math using best practices in teaching and learning pedagogy.'),
(20, 149, 'Nutrition and Dietetics', 3, 'Upon completion of the AS-T in Nutrition and Dietetics, students are able to acquire knowledge to develop health promotion and disease prevention programs that address diverse populations within a community (such as ethnicity, cultural backgrounds, socioeconomic status, and regional resources).'),
(20, 149, 'Nutrition and Dietetics', 3, 'Upon completion of the AS-T in Nutrition and Dietetics, students are able to critically evaluate factors influencing obesity, and the metabolic consequences of obesity, as it relates to chronic disease.'),
(20, 149, 'Nutrition and Dietetics', 3, 'Upon completion of the AS-T in Nutrition and Dietetics, students are able to evaluate personal energy and nutrient requirements, along with the nutrient density of various food sources, using current dietary assessment tools.'),
(15, 150, 'Occupational Safety and Health', 5, 'Upon completion of the AS in Occupational Safety and Health, students are able to apply a working knowledge of mathematics and the sciences to conduct experiments and to analyze and interpret data to solve safety and health-related issues in the workplace.'),
(15, 150, 'Occupational Safety and Health', 5, 'Upon completion of the AS in Occupational Safety and Health, students are able to prepare emergency response and fire prevention plans that meet regulatory requirements.'),
(15, 150, 'Occupational Safety and Health', 5, 'Upon completion of the AS in Occupational Safety and Health, students are able to design programs to control, eliminate, and prevent occupational disease or injury caused by chemical, physical, radiological, and biological agents or ergonomic factors.'),
(15, 150, 'Occupational Safety and Health', 10, 'Upon completion of the Certificate of Achievement in Occupational Safety and Health, students are able to prepare an emergency response plan meeting regulatory requirements'),
(15, 150, 'Occupational Safety and Health', 10, 'Upon completion of the Certificate of Accomplishment in Occupational Safety, students are able to perform basic duties of a safety specialist.'),
(15, 150, 'Occupational Safety and Health', 10, 'Upon completion of the Certificate of Achievement in Occupational Safety and Health, students are able to design programs to control, eliminate, and prevent disease or injury caused by chemical, physical, radiological, and biological agents or ergonomic factors.'),
(15, 150, 'Occupational Safety', 12, 'Upon completion of the Certificate of Accomplishment in Occupational Safety, students are able to perform basic duties of a safety specialist.'),
(12, 151, 'Philosophy', 2, 'Upon completion of the AA-T in Philosophy, students are able to develop and present formal philosophical arguments using effective logical argumentative technique and avoiding logical error and fallacies.'),
(12, 151, 'Philosophy', 2, 'Upon completion of the AA-T in Philosophy, students are able to respond to philosophical writing and ideas of historical and contemporary philosophers by describing philosophical arguments, evaluating those arguments, and applying them with accuracy and creativity to contemporary conditions.'),
(12, 152, 'Photography', 2, 'Upon completion of the AA in Photography, students are able to visualize and produce entry-level commercial and fine art photographs that demonstrate fully developed concepts of form, medium, and content.'),
(12, 152, 'Photography', 2, 'Upon completion of the AA in Photography, students are able to critique, analyze, and discuss photographic images utilizing knowledge of the history, aesthetics, and contemporary issues of the photography field.'),
(12, 152, 'Photography', 2, 'Upon completion of the AA in Photography, students are able to effectively visualize and accurately construct lighting designs utilizing artificial studio lighting and natural light in photographs.'),
(12, 152, 'Photography', 2, 'Upon completion of the AA in Photography, students are able to operate both digital and film-based photographic equipment used in the photography field.'),
(12, 152, 'Photography', 10, 'Upon completion of the Certificate of Achievement in Photography, students are able to appropriately visualize and produce entry level professional, commercial, and fine art photographs that represent fully developed concepts of form, medium and content.'),
(12, 152, 'Photography', 10, 'Upon completion of the Certificate of Achievement in Photography, students are able to critique and discuss film and digital photographic images that represent fully developed concepts of form, medium and content.'),
(12, 152, 'Photography', 10, 'Upon completion of the Certificate of Achievement in Photography, students are able to appropriately visualize and accurately construct lighting designs utilizing artificial studio lighting and natural, available light in film and digital photographs.'),
(24, 154, 'Political Science', 2, 'Upon completion of the AA-T in Political Science, students are able to analyze and assess various types of sources in the discipline.'),
(24, 154, 'Political Science', 2, 'Upon completion of the AA-T in Political Science, students are able to demonstrate an understanding of socioeconomic and/or political power disparities existing along the lines of identities such as race, class, gender, sexuality, legal status, and religion.'),
(24, 154, 'Political Science', 2, 'Upon completion of the AA-T in Political Science, students are able to demonstrate understanding and application of theories and concepts in political science to contemporary political phenomenon.'),
(24, 154, 'Political Science', 2, 'Upon completion of the AA-T in Political Science, students are able to research, synthesize, and argue a political thesis.'),
(24, 155, 'Psychology', 2, 'Upon completion of the AA-T in Psychology, students are able to apply psychological content for personal, professional, and lifelong learning goals.'),
(24, 155, 'Psychology', 2, 'Upon completion of the AA-T in Psychology, students are able to apply ethical standards to evaluate psychological science and practice in a diverse community at the local, national, and global levels.'),
(24, 155, 'Psychology', 2, 'Upon completion of the AA-T in psychology, students are able to describe key concepts, principles, and themes in psychology and apply empirical findings.'),
(24, 155, 'Psychology', 2, 'Upon completion of the AA-T in Psychology, students are able to use scientific thinking and information literacy to interpret, design, and conduct psychological research.'),
(24, 155, 'Psychology', 2, 'Upon completion of the AA-T in Psychology, students are able to demonstrate effective written and oral communication for different purposes and audiences.'),
(18, 126, 'Social Work and Human Services', 2, 'Upon completion of the AA-T in Social Work and Human Services, students are able to critically analyze societal factors that create and contribute to social service needs.'),
(18, 126, 'Social Work and Human Services', 2, 'Upon completion of the AA-T in Social Work and Human Services, students are able to demonstrate a foundational understanding of social work and human services outlining the evolution of social welfare and human services in the U.S.'),
(18, 126, 'Social Work and Human Services', 2, 'Upon completion of the AA-T in Social Work and Human Services, students are able to demonstrate knowledge and understanding of theoretical perspectives, legal and ethical principles and social issues related to social work and human services fields.'),
(18, 126, 'Social Work and Human Services', 2, 'Upon completion of the AA-T in Social Work and Human Services, students are able to demonstrate an understanding of cultural sensitivity and systems of oppression/ privilege as a foundation to success in the fields of social work and human services.'),
(24, 158, 'Sociology', 2, 'Upon completion of AA-T in Sociology, students are able to analyze and describe the major concepts, theoretical perspectives, empirical findings, and historical trends in sociology.'),
(24, 158, 'Sociology', 2, 'Upon completion of AA-T in Sociology, students are able to demonstrate critical thinking and analytic skills in the application of social theory to solve problems that arise in institutional and societal contexts.'),
(12, 164, 'Spanish', 2, 'Upon completion of the AA-T in Spanish, students are able to analyze and interpret Spanish texts according to their cultural, literary and/or linguistic content.'),
(12, 164, 'Spanish', 2, 'Upon completion of the AA-T in Spanish, students are able to demonstrate oral competence in the Spanish Language by using correct grammar, vocabulary, and appropriate register.'),
(12, 164, 'Spanish', 2, 'Upon completion of the AA-T in Spanish, students are able to demonstrate written competence in the Spanish language by using correct grammar, vocabulary, and appropriate register.'),
(12, 164, 'Spanish', 2, 'Upon completion of the AA-T in Spanish, students are able to have a clear understanding of the cultures of the Spanish speaking world.'),
(12, 164, 'Spanish', 10, 'Upon completion of the Certificate of Achievement in Spanish, students are able to analyze and interpret Spanish texts according to their cultural, literary and/or linguistic content.'),
(12, 164, 'Spanish', 10, 'Upon completion of the Certificate of Achievement in Spanish, students are able to demonstrate oral competence in the Spanish Language by using correct grammar, vocabulary, and appropriate register.'),
(12, 164, 'Spanish', 10, 'Upon completion of the Certificate of Achievement in Spanish, students are able to demonstrate written competence in the Spanish language by using correct grammar, vocabulary, and appropriate register.'),
(12, 164, 'Spanish', 10, 'Upon completion of the Certificate of Achievement in Spanish, students are able to have a clear understanding of the cultures of the Spanish-speaking world.'),
(12, 159, 'Theater Arts', 4, 'Upon completion of the AA in Theater Arts, students are able to critically analyze the artistic elements in productions, looking at design, acting, directorial choices, as well as personal performance processes.'),
(12, 159, 'Theater Arts', 4, 'Upon completion of the AA in Theater Arts, students are able to apply  the learned techniques of acting or technical theater in a public performance of various genres of theater, or other types of personal creative work.'),
(12, 159, 'Theater Arts', 4, 'Upon completion of the AA in Theater Arts, students are able to possess the skills necessary for textual interpretation for academic discourse, design, and/or performance studies.'),
(12, 159, 'Theater Arts', 4, 'Upon completion of the AA in Theater Arts, students are able to understand how to develop and maintain a positive contribution the field of theater in academics, performance, or technical theater.'),
(12, 159, 'Theater Arts', 4, 'Upon completion of the AA in Theater Arts, students are able to understand the historical and cultural significance of theater through completion of projects in the technical theater courses and theater history class.'),
(12, 159, 'Theater Arts', 2, 'Upon completion of the AA-T in Theater Arts, students are able to analyze the artistic elements in productions, looking at design, acting, and directorial choice.'),
(12, 159, 'Theater Arts', 2, 'Upon completion of the AA-T in Theater Arts, students are able to apply the learned techniques of acting or technical theater in a public performance of various genres of theater, or other types of personal creative work.'),
(12, 159, 'Theater Arts', 2, 'Upon completion of the AA-T in Theater Arts, students are able to possess the skills necessary for textual interpretation for academic discourse, design, and/or performance studies.'),
(12, 159, 'Theater Arts', 2, 'Upon completion of the AA-T in Theater Arts, students are able to understand how to develop and maintain a positive contribution the field of theater in academics, performance, or technical theater.'),
(12, 159, 'Theater Arts', 2, 'Upon completion of the AA-T in Theater Arts, students are able to understand the historical and cultural significance of theater through completion of projects in the technical theater courses and theater history class.'),
(12, 159, 'Technical Theater', 10, 'Upon completion of the Certificate of Achievement in Technical Theater, students are able to perform as a member of a show running crew in various capacities, such as stagehand, light or sound board operator, or wardrobe assistant.'),
(12, 159, 'Technical Theater', 10, 'Upon completion of the Certificate of Achievement in Technical Theater, students are able to analyze elements of a theatrical design.'),
(12, 159, 'Technical Theater', 10, 'Upon completion of the Certificate of Achievement in Technical Theater, students are able to research, plot, and design costumes for use in production.'),
(12, 159, 'Technical Theater', 10, 'Upon completion of the Certificate of Achievement in Technical Theater, students are able to read construction plans and construct common stage scenery such as flats, platform, and stairs.'),
(12, 159, 'Technical Theater', 10, 'Upon completion of the Certificate of Achievement in Technical Theater, students are able to hang, cable, and focus stage lighting and be able to read lighting plots and related documents.'),
(12, 159, 'Actors Conservatory', 10, 'Upon completion of the Actors Conservatory, students are able to apply the learned techniques of acting in a public performance of various genres of theater, or other types of personal creative work, synthesizing acting, movement, and vocal skills into a truthful theater performance.'),
(12, 159, 'Actors Conservatory', 10, 'Upon completion of the Certificate of Achievement in Actors Conservatory, students are able to integrate an understanding of the history of theater and theatrical text into performance using character construction, physicality and vocal nuance.'),
(12, 159, 'Actors Conservatory', 10, 'Upon completion of the Actors Conservatory, students are able to demonstrate a professional work ethic within a professional framework of collaboration in rehearsal and performance.'),
(12, 159, 'Actors Conservatory', 10, 'Upon completion of the Actors Conservatory, students are able to exhibit a portfolio of academic and performance work through engagement and experiences aimed at a deeper and more profound understanding of the craft of theater and the cultural importance of the art form.'),
(12, 159, 'Acting', 10, 'Upon completion of the Acting Certificate, students are able to develop an understanding of the role of a character within the context of a play and create a unique character portrayal in emotional, physical, and vocal life.'),
(12, 159, 'Acting', 10, 'Upon completion of the Acting Certificate, students are able to examine and perform within major genres of theater from world theatrical history.'),
(12, 159, 'Acting', 10, 'Upon completion of the Acting Certificate, students are able to make complex, creative, and bold acting choices during the rehearsal process as a means of creative exploration.'),
(12, 159, 'Acting', 10, 'Upon completion of the Acting Certificate, students are able to work collaboratively with fellow actors and production staff, demonstrating an understanding of the professional work ethic of an actor'),
(12, 159, 'Musical Theater', 10, 'Upon completion of the Certificate of Achievement in Musical Theater, students are able to demonstrate a professional work ethic within a professional framework of collaboration in rehearsal and performance.'),
(12, 159, 'Musical Theater', 10, 'Upon completion of the Certificate of Achievement in Musical Theater, students are able to demonstrate knowledge of the basic anatomy and physiology involved in tone production and of the respiratory system and its contribution to singing.'),
(12, 159, 'Musical Theater', 10, 'Upon completion of the Certificate of Achievement in Musical Theater, students are able to examine and perform within major genres of American Musical Theater.'),
(12, 159, 'Musical Theater', 10, 'Upon completion of the Certificate of Achievement in Musical Theater, students are able to practice, perform, and memorize scales, chords, and simple harmonic progressions.'),
(12, 159, 'Musical Theater', 10, 'Upon completion of the Certificate of Achievement in Musical Theater, students are able to synthesize acting, movement, dance, and singing skills into a truthful musical theater performance.'),
(15, 162, 'Enology', 5, 'Upon completion of the AS in Enology, students are able to apply general chemistry principles, wine microbiology fundamentals, and laboratory techniques to produce sound wines.'),
(15, 162, 'Enology', 5, 'Upon completion of the AS in Enology, students are able to safely start-up, operate, and shutdown winery equipment; and effectively utilize the equipment during the winemaking process.'),
(15, 162, 'Enology', 5, 'Upon completion of the AS in Enology, students are able to perform an accurate wine assessment utilizing acquired organoleptic skills.'),
(15, 162, 'Enology', 5, 'Upon completion of the AS in Enology, students are able to perform wine analysis methods including laboratory/quality control test during harvest, fermentations, cellaring, and prior to bottling.'),
(15, 162, 'Enology', 10, 'Upon completion of the Certificate of Achievement in Enology, students are able to safely start-up, operate and shut down winery equipment and effectively utilize the equipment during the wine making process.'),
(15, 162, 'Enology', 10, 'Upon completion of the Certificate of Achievement in Enology, students are able to perform wine analysis methods including laboratory/quality control test during harvest, fermentations, cellaring and prior to bottling.'),
(15, 162, 'Enology', 10, 'Upon completion of the Certificate of Achievement in Enology, students are able to apply general chemistry principles, wine microbiology fundamentals, and laboratory techniques to produce sound wines.'),
(15, 162, 'Enology', 10, 'Upon completion of the Certificate of Achievement in Enology, students are able to perform an accurate wine assessment utilizing acquired organoleptic skills.'),
(15, 162, 'Viticulture', 5, 'Upon completion of the AS in Viticulture, students are able to use proficient knowledge of the seasonal requirements of a working vineyard.'),
(15, 162, 'Viticulture', 5, 'Upon completion of the AS in Viticulture, students are able to describe the latest technological advances in vineyard practices and incorporate current technology into their farming plans.'),
(15, 162, 'Viticulture', 5, 'Upon completion of the AS in Viticulture, students are able to work cooperatively and effectively with winery personnel to determine optimum harvest parameters and coordinate the operations required.'),
(15, 162, 'Viticulture', 5, 'Upon completion of the AS in Viticulture, students are able to show leadership capabilities by effectively training others to perform hands-on vineyard tasks.'),
(15, 162, 'Viticulture', 5, 'Upon completion of the AS in Viticulture, students are able to contribute to the wine grape industry and participate in professional organizations at the local, state-wide, national and/or international levels.'),
(15, 162, 'Viticulture', 5, 'Upon completion of the AS in Viticulture, students are able to identify, plan, and implement sustainable farming practices that will improve fruit quality, provide efficacious pest and disease management, and protect natural resources and the environment.'),
(15, 162, 'Viticulture', 10, 'Upon completion of the Certificate of Achievement in Viticulture, students are able to describe the latest technological advances in vineyard practices and incorporate current technology into their farming plans.'),
(15, 162, 'Viticulture', 10, 'Upon completion of the Certificate of Achievement in Viticulture, students are able to identify, plan, and implement sustainable farming practices that will improve fruit quality, provide efficacious pest and disease management, and protect natural resources and the environment.'),
(15, 162, 'Viticulture', 10, 'Upon completion of the Certificate of Achievement in Viticulture, students are able to work cooperatively and effectively with wineries to determine optimum harvest parameters and coordinate the operations required.'),
(15, 162, 'Viticulture', 10, 'Upon completion of the Certificate of Achievement in Viticulture, students are able to show leadership capabilities by effectively training others to perform hands-on vineyard tasks.'),
(15, 162, 'Wine Hospitality', 11, 'Upon completion of the Certificate of Achievement in Wine Hospitality, students are able to demonstrate proper wine service.'),
(15, 162, 'Wine Hospitality', 11, 'Upon completion of the Certificate of Achievement in Wine Hospitality, students are able to describe a wine''s qualities.'),
(20, 161, 'Welding Technology', 5, 'Upon completion of the AS in Welding Technology, students are able to operate safely in a welding workplace environment.'),
(20, 161, 'Welding Technology', 5, 'Upon completion of the AS in Welding Technology, students have the skills necessary to pass an American Welding Society standard welding certification test.'),
(20, 161, 'Welding Technology', 10, 'Upon completion of the Certificate of Achievement in Welding Technology, students are able to operate safely in a welding workplace environment.'),
(20, 161, 'Welding Technology', 10, 'Upon completion of the Certificate of Achievement in Welding Technology, students have the skills necessary to pass an American Welding Society standard welding certification test.'),
(25, 118, 'CSU General Education Breadth', 9, 'Upon completion of the Certificate of Achievement in CSU General Education Breadth, students are able to critically apply ethical standards to identify problems and create solutions.'),
(25, 118, 'CSU General Education Breadth', 9, 'Upon completion of the Certificate of Achievement in CSU General Education Breadth, students are able to recognize ethical principles and behave responsibly.'),
(25, 118, 'CSU General Education Breadth', 9, 'Upon completion of the Certificate of Achievement in CSU General Education Breadth, students are able to understand and appreciate the diversity of the human experience.'),
(25, 118, 'CSU General Education Breadth', 9, 'Upon completion of the Certificate of Achievement in CSU General Education Breadth, students are able to read, write, speak, and listen to communicate effectively.'),
(25, 118, 'CSU General Education Breadth', 9, 'Upon completion of the Certificate of Achievement in CSU General Education Breadth, students are able to use and criticize quantitative arguments and understand experimental methodology, the testing of hypotheses, and the power of systematic questioning.'),
(25, 118, 'CSU General Education Breadth', 9, 'Upon completion of the Certificate of Achievement in CSU General Education Breadth, students are able to analyze and appreciate works of philosophical, historical, literary, and cultural importance.'),
(25, 118, 'CSU General Education Breadth', 9, 'Upon completion of the Certificate of Achievement in CSU General Education Breadth, students are able to identify strategies for continual sociological, psychological, and biological well-being.'),
(25, 118, 'IGETC (Intersegmental General Education Curriculum)', 9, 'Upon completion of the Certificate of Achievement in IGETC (Intersegmental General Education Curriculum), students are able to critically apply ethical standards to identify problems and create solutions.'),
(25, 118, 'IGETC (Intersegmental General Education Curriculum)', 9, 'Upon completion of the Certificate of Achievement in IGETC (Intersegmental General Education Curriculum), students are able to understand and appreciate the diversity of the human experience.'),
(25, 118, 'IGETC (Intersegmental General Education Curriculum)', 9, 'Upon completion of the Certificate of Achievement in IGETC (Intersegmental General Education Curriculum), students are able to read, write, speak, and listen to communicate effectively.'),
(25, 118, 'IGETC (Intersegmental General Education Curriculum)', 9, 'Upon completion of the Certificate of Achievement in IGETC (Intersegmental General Education Curriculum), students are able to recognize ethical principles and behave responsibly.'),
(25, 118, 'IGETC (Intersegmental General Education Curriculum)', 9, 'Upon completion of the Certificate of Achievement in IGETC (Intersegmental General Education Curriculum), students are able to use and criticize quantitative arguments.'),
(25, 118, 'IGETC (Intersegmental General Education Curriculum)', 9, 'Upon completion of the Certificate of Achievement in IGETC (Intersegmental General Education Curriculum), students are able to analyze and appreciate works of philosophical, historical, literary, and cultural importance.'),
(25, 118, 'IGETC (Intersegmental General Education Curriculum)', 9, 'Upon completion of the Certificate of Achievement in IGETC (Intersegmental General Education Curriculum), students are able to understand experimental methodology, the testing of hypotheses, and the power of systematic questioning.')

INSERT INTO ProgramOutcome
(ProgramId, SortOrder, Outcome, CreatedDate, CreatedBy_UserId, ListItemTypeId)
SELECT p.Id, 1, dat.PLO, GETDATE(), 475, 29
FROM Program AS p
INNER JOIN @Data AS dat on p.AwardTypeId = dat.AwardType
	and p.Title = dat.Program 
	and p.Tier1_OrganizationEntityId = dat.Division 
	and p.Tier2_OrganizationEntityId = dat.Department

UPDATE po
SET SortOrder = sorted.rownum
FROM ProgramOutcome po
INNER JOIN (
    SELECT 
        Id, 
        ROW_NUMBER() OVER (
            PARTITION BY ProgramId 
            ORDER BY Outcome
        ) AS rownum
    FROM ProgramOutcome
) sorted ON po.Id = sorted.Id;

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 71

COMMIT