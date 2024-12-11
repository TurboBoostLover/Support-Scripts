use chaffey;

/*
	Commit
						Rollback
*/

----------------------------------------------------------------------_----------------------------------------------------------------------
declare @JiraTicketNumber nvarchar(20) = 'MS-13603';
declare @Comments nvarchar(max) = 'updated program status';
declare @Developer nvarchar(50) = 'Nathan W';
declare @ScriptTypeId int = 1;
/*  
Default for @ScriptTypeId on this script is 1 for Support, for a complete list run the following query.
@ScriptTypeId above should = 2 when for enhancement.

select * from History.ScriptType;
*/
select @@servername as 'Server Name'
	, db_name() as 'Database Name'
	, @JiraTicketNumber as 'Jira Ticket Number'
;

set xact_abort on;
begin tran;

insert into History.ScriptsRunOnDatabase (TicketNumber, Developer, Comments, ScriptTypeId)
values (@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId);
----------------------------------------------------------------------_----------------------------------------------------------------------
--Update program status.
	update Program
	set StatusAliasId = (
		select Id
		from StatusAlias
		where Title = 'Historical'
	)
	where Id = 1111;

	update Program
	set StatusAliasId = (
		select Id
		from StatusAlias
		where Title = 'Active'
	)
	where Id = 741;

	update BaseProgram
	SET ActiveProgramId = 741
	WHERE Id = 397
--commit;
--rollback;