USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19769';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text on COR report for units/hours';
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
DECLARE @Id int = 117

DECLARE @SQL NVARCHAR(MAX) = '

		--declare @entityId int = (8514);

		declare @minTotal decimal (6, 2) = (
			select 
				coalesce(
					cast(MinLectureHour as decimal(6, 2))
					, 0
				) + 
				coalesce(
					cast(MinLabHour as decimal(6, 2))
					, 0
				) + 
				coalesce(
					cast(InClassHour as decimal(6, 2))
					, 0
				)
			from CourseDescription
			where CourseId = @entityId
		);

		declare @maxTotal decimal (6, 2) = (
			select 
				coalesce(
					cast(MaxLectureHour as decimal(6, 2))
					, 0
				) + 
				coalesce(
					cast(MaxLabHour as decimal(6, 2))
					, 0
				) + 
				coalesce(
					cast(OutClassHour as decimal(6, 2))
					, 0
				)
			from CourseDescription
			where CourseId = @entityId
		);

		declare @minTotalTerm decimal (6, 2) = (
			select 
				coalesce(
					cast(MinLectureHour as decimal(6, 2))
					, 0
				) + 
				coalesce(
					cast(MinLabHour as decimal(6, 2))
					, 0
				)
			from CourseDescription
			where CourseId = @entityId
		);

		declare @maxTotalTerm decimal (6, 2) = (
			select 
				coalesce(
					cast(MaxLectureHour as decimal(6, 2))
					, 0
				) + 
				coalesce(
					cast(MaxLabHour as decimal(6, 2))
					, 0
				)
			from CourseDescription
			where CourseId = @entityId
		);

		declare @minUnit decimal (6, 2) = (
			select 
				format(
					floor(
						(
							coalesce(
								MinLectureHour
								, 0
							) + 
							coalesce(
								MinLabHour
								, 0
							) + 
							coalesce(
								InClassHour
								, 0
							)
						)
						* 2 / 3
					) / 2
				, ''0.0'')
			from CourseDescription
			where CourseId = @entityId
		);

		declare @maxUnit decimal (6, 2) = (
			select 
				format(
					floor(
						(
							coalesce(
								MaxLectureHour
								, 0
							) + 
							coalesce(
								MaxLabHour
								, 0
							) + 
							coalesce(
								OutClassHour
								, 0
							)
						)
						* 2 / 3
					) / 2
				, ''0.0'')
			from CourseDescription
			where CourseId = @entityId
		);

		select ''
			<style>
				table, th, td {
				  border: 1px solid black;
				  border-collapse: collapse;
				}
			</style>
	
			<table style="text-align: center; table-layout: fixed; width: 100%; vertical-align: middle;">
				<tr>
					<td style="background-color: darkgray;"></td>
					<td style="background-color: darkgray;">
						<strong>
							Hours per Week
						</strong>
					</td>
					<td style="background-color: darkgray;">
						<strong>
							Total Hours per Term<br />
							(Based on 16-18 Weeks)
						</strong>
					</td>
					<td style="background-color: darkgray;">
						<strong>
							Total Units
						</strong>
					</td>
				</tr>
				<tr>
					<td style="background-color: darkgray;">
						<strong>
							Lecture
						</strong>
					</td>
					<td>'' + 
						case 
							when cd.MinLectureHour is not null
							and (c.BudgetId is null
								or c.BudgetId = 8--Standard
							)
							and (cd.Variable <> 1
								or cd.Variable is null
							)
								then 
									coalesce(
										format(cd.MinLectureHour, ''0.0'')
										, ''''
									)
							when cd.MaxLectureHour is not null 
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.MinLectureHour, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' - '' + 
										format(cd.MaxLectureHour, ''0.0'')
										, ''''
									)
							else ''''
						end + 
					''</td>
					<td>'' + 
						case 
							when cd.MinLectureHour is not null
							and (c.BudgetId is null 
								or c.BudgetId = 8--Standard
							)
							and (cd.Variable <> 1
								or cd.Variable is null
							)
								then 
									format(cd.MinLectureHour * 16, ''0.0'') + 
									'' - '' + 
									format(cd.MinLectureHour * 18, ''0.0'')
							when cd.MaxLectureHour is not null
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.MinLectureHour * 16, ''0.0'')
										, ''''
									) + 
									'' - '' + 
									coalesce(
										format(cd.MinLectureHour * 18, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' to <br />'' + 
										format(cd.MaxLectureHour * 16, ''0.0'') + 
										'' - '' + 
										format(cd.MaxLectureHour * 18, ''0.0'')
										, ''''
									)
							else ''''
						end + 
					''</td>
					<td>&nbsp;</td>
				</tr>
				<tr>
					<td style="background-color: darkgray;">
						<strong>
							Lab
						</strong>
					</td>
					<td>'' + 
						case 
							when cd.MinLabHour is not null 
							and (c.BudgetId is null 
								or c.BudgetId = 8--Standard
							)
							and (cd.Variable <> 1
								or cd.Variable is null
							)
								then 
									coalesce(
										format(cd.MinLabHour, ''0.0'')
										, ''''
									)
							when cd.MaxLabHour is not null 
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.MinLabHour, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' - '' + 
										format(cd.MaxLabHour, ''0.0'')
										, ''''
									)
							else ''-''
						end + 
					''</td>
					<td>'' + 
						case 
							when cd.MinLabHour is not null 
							and (c.BudgetId is null 
								or c.BudgetId = 8--Standard
							)
							and (cd.Variable <> 1
								or cd.Variable is null
							)
								then 
									format(cd.MinLabHour * 16, ''0.0'') + 
									'' - '' + 
									format(cd.MinLabHour * 18, ''0.0'')
							when cd.MaxLabHour is not null 
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.MinLabHour * 16, ''0.0'')
										, ''''
									) + 
									'' - '' + 
									coalesce(
										format(cd.MinLabHour * 18, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' to <br />'' + 
										format(cd.MaxLabHour * 16, ''0.0'') + 
										'' - '' + 
										format(cd.MaxLabHour * 18, ''0.0'')
										, ''''
									)
							else ''''
						end + 
					''</td>
					<td>&nbsp;</td>
				</tr>
				<tr>
					<td style="background-color: darkgray;">
						<strong>
							Outside-of-Class Hours
						</strong>
					</td>
					<td>'' + 
						case 
							when cd.InClassHour is not null 
							and (c.BudgetId is null 
								or c.BudgetId = 8--Standard
							)
							and (cd.Variable <> 1
								or cd.Variable is null
							)
								then 
									coalesce(
										format(cd.InClassHour, ''0.0'')
										, ''''
									)
							when cd.OutClassHour is not null 
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.InClassHour, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' - '' + 
										format(cd.OutClassHour, ''0.0'')
										, ''''
									)
							else ''''
						end + 
					''</td>
					<td>'' + 
						case 
							when cd.InClassHour is not null 
							and (c.BudgetId is null 
								or c.BudgetId = 8--Standard
							) 
							and (cd.Variable <> 1
								or cd.Variable is null
							)
								then 
									format(cd.InClassHour * 16, ''0.0'') + 
									'' - '' + 
									format(cd.InClassHour * 18, ''0.0'')
							when cd.OutClassHour is not null 
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.InClassHour * 16, ''0.0'')
										, ''''
									) + 
									'' - '' +  
									coalesce(
										format(cd.InClassHour * 18, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' to <br />'' + 
										format(cd.OutClassHour * 16, ''0.0'') + 
										'' - '' + 
										format(cd.OutClassHour * 18, ''0.0'')
										, ''''
									)
							else ''''
						end + 
					''</td>
					<td>&nbsp;</td>
				</tr>
				<tr>
					<td style="background-color: darkgray;">
						<strong>
							Total Student Learning Hours
						</strong>
					</td>
					<td>'' + 
						format(@minTotal ,''0.0'') + 
						coalesce(
							case 
								when @maxTotal > @minTotal
									then 
										'' - '' + 
										format(@maxTotal, ''0.0'') 
								else ''''
							end
							, ''''
						) + 
					''</td>
					<td>'' + 
						case 
							when c.MathIntensityId is null 
							or c.MathIntensityId = 2--Calculated
								then format(@minTotal * 16, ''0.0'') + 
								--case
									--when @maxTotal > @minTotal
										--then 
										'' - '' + 
											coalesce(
												format( 
													CASE WHEN @minTotal < @maxTotal
														THEN @maxTotal * 18
														ELSE @minTotal * 18
														END
												--coalesce(@maxTotal, @minTotal) * 18
												, ''0.0'')
												, ''''
											)
									--else ''''
								--end
							when cd.MinContactHoursOther is not null 
							and cd.MaxContactHoursOther is null 
								then 
									coalesce(
										format(cd.MinContactHoursOther, ''0.0'')
										, ''''
									)
							when cd.MinContactHoursOther is not null 
							and cd.MaxContactHoursOther is not null 
								then 
									coalesce(
										format(cd.MinContactHoursOther, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' - '' + 
										format(cd.MaxContactHoursOther, ''0.0'')
										, ''''
									)
							when cd.MinContactHoursOther is not null 
							and cd.MinStudyHour is not null 
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.MinContactHoursOther, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' - '' + 
										format(cd.MaxContactHoursOther, ''0.0'')
										, ''''
									) + 
									'' to <br />'' + 
									format(cd.MinStudyHour , ''0.0'') + 
									coalesce(
										'' - '' + 
										format(cd.MaxStudyHour, ''0.0'')
										, ''''
									)
							else ''''
						end + 
					''</td>
					<td>'' + 
						case 
							when (@minUnit is not null
								or cd.MinCreditHour is not null 
							)
							and (c.BudgetId is null 
								or c.BudgetId = 8--Standard
							) 
							and (cd.Variable <> 1
								or cd.Variable is null
							)
								then 
									coalesce(
										format(cd.MinCreditHour, ''0.0'')
										, format(@minUnit, ''0.0'')
										, ''''
									)
							when (@maxUnit is not null
								or cd.MaxCreditHour is not null 
							)
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.MinCreditHour, ''0.0'')
										, format(@minUnit, ''0.0'')
										, ''''
									) + 
									'' - '' + 
									coalesce(
										format(cd.MaxCreditHour, ''0.0'')
										, format(@maxUnit, ''0.0'')
										, ''''
									)
							else ''''
						end + 
					''</td>
				</tr>
				<tr>
					<td style="background-color: darkgray;">&nbsp;</td>
					<td style="background-color: darkgray;">&nbsp;</td>
					<td style="background-color: darkgray;">&nbsp;</td>
					<td style="background-color: darkgray;">&nbsp;</td>
				</tr>
				<tr>
					<td style="background-color: darkgray;">
						<strong>
							Total Contact Hours
						</strong>
					</td>
					<td>'' + 
						format(@minTotalTerm ,''0.0'') + 
						coalesce(
							case 
								when @minTotalTerm < @maxTotalTerm 
									then 
										'' - '' + 
										format(@maxTotalTerm, ''0.0'') 
								else ''''
							end
							, ''''
						) + 
					''</td>
					<td>'' + 
						case 
							when c.MathIntensityId is null 
							or c.MathIntensityId = 2--Calculated
								then format(@minTotalTerm * 16, ''0.0'') +  '' - '' + 
										coalesce(
											format(coalesce(@minTotalTerm ,@maxTotalTerm) * 18, ''0.0'')
											, ''''
										)
							when cd.MinContactHoursOther is not null 
							and cd.MaxContactHoursOther is null 
								then 
									coalesce(
										format(cd.MinContactHoursOther, ''0.0'')
										, ''''
									)
							when cd.MinContactHoursOther is not null 
							and cd.MaxContactHoursOther is not null 
								then 
									coalesce(
										format(cd.MinContactHoursOther, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' - '' + 
										format(cd.MaxContactHoursOther, ''0.0'')
										, ''''
									)
							when cd.MinContactHoursOther is not null 
							and cd.MinStudyHour is not null 
							and (c.BudgetId = 9--Variable
								or cd.Variable = 1
							)
								then 
									coalesce(
										format(cd.MinContactHoursOther, ''0.0'')
										, ''''
									) + 
									coalesce(
										'' - '' + 
										format(cd.MaxContactHoursOther, ''0.0'')
										, ''''
									) + 
									'' to <br />'' + 
									format(cd.MinStudyHour, ''0.0'') + 
									coalesce(
										'' - '' + 
										format(cd.MaxStudyHour, ''0.0'')
										, ''''
									)
							else ''-''
						end + 
					''</td>
					<td>&nbsp;</td>
				</tr>
			</table>'' as [Text]
		from CourseDescription cd
			inner join Course c on cd.CourseId = c.Id
		where cd.CourseId = @entityId;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id