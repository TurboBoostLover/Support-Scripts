USE [fresno];

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
VALUES
('helptext', '
<p>‘Significant’ changes would include adding, modifying, or deleting degrees, certificates, or courses. For courses, changes to requisites, substantial content, unit, or delivery method should be included. If no significant changes have been made, please state.</p>
<p>This prompt relates to changes that have been submitted to the Curriculum Committee during the PR data collection period (even if implementation date is outside this period). Planned changes (i.e. anything that has not been submitted to the Curriculum Committee) should be described in D. below.
Unavoidable changes in course delivery (e.g. move to 100% online instruction during COVID-19 restrictions) may be included in this section if these had a significant impact on the program.</p>
', 2850),
('helptext', '
Describe context and/or data limitations if appropriate. Plans to improve completion rates for low-performing degrees/certificates can include degree/certificate curriculum changes or deletions of degrees or certificates. Be sure to include the plans for significant degree and certificate changes in your answer to Question II.C. as well.
', 2852),
('helptext', '
This prompt relates to any planned changes, i.e. those that have not yet been submitted to the Curriculum Committee. Plans for ‘significant’ change would include adding, modifying, or deleting degrees, certificates, or courses. Additionally, changes to requisites, substantial content, unit, or delivery changes should be included.
', 2853),
('helptext', '
<p>Describe overall program enrollment and identify any trends which may have implications for the program.</p>
<p>Provide context (changes in number of faculty, new teaching rooms, categorical funding, expansion of online education etc.) to explain any significant fluctuations. If you have significant numbers of dual enrollment students, or identified trends in dual enrollment, please describe in this section (“Dual Enrollment” filter is available on IRPE dashboard – see red text at start of section for link). If significant increases in enrollment are noted, explain how the increasing numbers of students are being accommodated, and how the quality of their educational experience is being maintained.</p>
<p>If significant decreases in enrollment are noted (> 10% year-on-year drop for all 4 years of the PR period, or overall > 40% drop) defend the viability of the program, explaining how this trend may be reversed or otherwise managed. Number of sections and/or average class size data may be discussed if relevant. Any proposed links between average class size and student success data should be considered in C below.</p>
', 2857),
('helptext', '
Consider the data (in comparison to the demographics of the service area, workforce, College and/or Division): are there any under- or over-represented groups* of students within your program? Explain and/or provide necessary context. Describe any actions taken since the last IPR, or plans you have, to remediate.
* Determination of over- or under-representation is left to the discretion of the program. The PR Committee does not require a rigorous statistical analysis, but rather is looking for evidence that programs are systematically reviewing their enrollment data, and where appropriate, making efforts to address issues of over- or under-representation.
', 2858),
('helptext', '
<p>Institutional Set Standard (at time of writing) is: Success rate: 71% The ISS target may be found at the IRPE website.</p>
<p>Comparative data should include those from similar programs, the Division and/or overall College data.
Programs with persistently low success rates (defined as success rates less than 75% of ISS target either for all 4 AY of the PR period, or any 4 consecutive AY within the 8 year data trend period) should provide a full explanation, and a comprehensive remediation plan.
</p>
<p>Plans to improve retention and success should be described here.</p>
', 2859)

UPDATE MetaSelectedSection
SET SectionDescription = 'B. Examine the completion data for each of your program’s individual degrees and certificates.'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId = 1421

UPDATE MetaSelectedSection
SET SectionDescription = 'Attach all Course-level Student Learning Outcomes (CSLO) Assessment Reports since the last IPR as Appendix D.'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId = 1423

UPDATE MetaSelectedSection
SET SectionDescription = 'In this section programs will present their retention, success, degree, and certificate data and reflect on the effectiveness of their program. Strategies to optimize student success will be described.'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId = 1427