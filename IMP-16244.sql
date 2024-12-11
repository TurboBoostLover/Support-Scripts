USE [sbcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-';
DECLARE @Comments nvarchar(Max) = 
	'';
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
DECLARE @clientId INT = (SELECT Id FROM Client)

Update config.ClientSetting
set EnableCrossListing = 1
, Configurations = '
[
    {
        "label": "Profile",
        "description": "This is your information.",
        "name": "Profile",
        "iconClass": "fa-duotone fa-user-edit me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [],
        "sortorder": 1,
        "curriqunetOnly": false
    },
    {
        "label": "Form Builder",
        "description": "This is the form builder",
        "name": "Builder",
        "iconClass": "fa-duotone fa-screwdriver-wrench me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [],
        "sortorder": 2,
        "curriqunetOnly": true
    },
    {
        "label": "Curriqunet",
        "description": "These settings are controlled by us",
        "name": "Curriqunet",
        "iconClass": "fa-fw fa-duotone fa-trophy-star me-2",
        "smallIconClass": "",
        "active": true,
        "type": "setting",
        "settings": [
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "This will show the return to Classic Meta button on the new UI",
                    "Default": true,
                    "Label": "Enable return to Classic Meta button",
                    "Name": "ReturnToClassicMetaEnabled",
                    "Value": true,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": "none",
                    "Label": "Client Id",
                    "Name": "ClientId",
                    "Value": 1,
                    "Active": false
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "string",
                    "Description": "",
                    "Default": "none",
                    "Label": "Support Email Address",
                    "Name": "SupportEmail",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": "none",
                    "Label": "Authentication Type",
                    "Name": "AuthenticationTypeId",
                    "Value": 2,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": "None",
                    "Label": "Default Entity Type",
                    "Name": "DefaultEntityTypeId",
                    "Value": 1,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable Public Search",
                    "Name": "PublicSearch",
                    "Value": true,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": "none",
                    "Label": "Country",
                    "Name": "CountryId",
                    "Value": 252,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "string",
                    "Description": "",
                    "Default": "none",
                    "Label": "SQL Catalog",
                    "Name": "SQLCatalog",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": "",
                    "Label": "Use Mapping",
                    "Name": "UseMapping",
                    "Value": false,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": 1,
                    "Label": "Use Reporting Services",
                    "Name": "UseReportingServices",
                    "Value": true,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Allow State Required Fields",
                    "Name": "AllowStateControlledFields",
                    "Value": false,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Client has Assist",
                    "Name": "AssistClient",
                    "Value": true,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": "",
                    "Label": "New Feature Setting",
                    "Name": "NewFeatureSetting",
                    "Value": 3,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": "",
                    "Label": "Default Client Entity Type Id",
                    "Name": "DefaultClientEntityTypeId",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Allow Catalog (old)",
                    "Name": "AllowCatalog",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Restrict AdHoc by Client",
                    "Name": "RestrictAdHocByClient",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": 2,
                    "Label": "Default Landing Type Id",
                    "Name": "DefaultLandingTypeId",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable SSO Redirect",
                    "Name": "EnableAutomaticSSORedirect",
                    "Value": false,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable Create Proposal New Search",
                    "Name": "EnableCreateProposalNewSearch",
                    "Value": false,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "string",
                    "Description": "",
                    "Default": "none",
                    "Label": "Default Search Filter Scope Client Id",
                    "Name": "DefaultSearchFilterScopeClientId",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable Authentication Tracking",
                    "Name": "EnableAuthenticationTracking",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": 4,
                    "Label": "Numeric Rounding Method",
                    "Name": "NumericRoundingMethod",
                    "Value": 4,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable CB Management",
                    "Name": "EnableCBManagement",
                    "Value": false,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "string",
                    "Description": "",
                    "Default": "none",
                    "Label": "Subject Alias",
                    "Name": "SubjectAlias",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable Peer Review",
                    "Name": "EnablePeerReview",
                    "Value": false,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable Originator Launch Notification",
                    "Name": "AllowOriginatorLaunchNotification",
                    "Value": true,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "string",
                    "Description": "",
                    "Default": "",
                    "Label": "UTC offset",
                    "Name": "UTCOffset",
                    "Value": null,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "int",
                    "Description": "",
                    "Default": "",
                    "Label": "Approval Level Completion Strategy Type",
                    "Name": "ApprovalLevelCompletionStrategyType",
                    "Value": 2,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable Splashboard",
                    "Name": "EnableSplashboard",
                    "Value": true,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable Catalog",
                    "Name": "EnableNewCatalog",
                    "Value": false,
                    "Active": true
                },
                {
                    "AccessLevel": "curriqunet",
                    "DataType": "bool",
                    "Description": "",
                    "Default": false,
                    "Label": "Enable Multiple Catalogs",
                    "Name": "AllowMultipleCampus",
                    "Value": null,
                    "Active": true
                },
                {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Reactivation",
                "Name": "AllowReactivation",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Range Lockout",
                "Name": "AllowRangeLockout",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Subtype Lockout",
                "Name": "AllowSubtypeLockout",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Cloning",
                "Name": "AllowCloning",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Non Admin Reactivation",
                "Name": "AllowNonAdminReactivation",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Multiple Approved",
                "Name": "AllowMultipleApproved",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Cross Listing",
                "Name": "EnableCrossListing",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Crosslisting Add All approval",
                "Name": "CrossListAddAllApproval",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Crosslisting require all approval",
                "Name": "CrossListRequireAllApproval",
                "Value": false,
                "Active": true
            }
        ],
        "sortorder": 3,
        "curriqunetOnly": true
    },
    {
        "label": "Notifications",
        "description": "Configure notifications and messages for workflows and system notifications.",
        "name": "Notifications",
        "iconClass": "fa-fw fa-duotone fa-bell-on me-2",
        "smallIconClass": "",
        "active": true,
        "type": "setting",
        "settings": [
            {
                "AccessLevel": "curriqunet",
                "DataType": "int",
                "Description": "",
                "Default": "",
                "Label": "Notification Interval in seconds",
                "Name": "NotificationIntervalInSeconds",
                "Value": 86400,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "datetime",
                "Description": "",
                "Default": "",
                "Label": "Last Notification Time",
                "Name": "LastNotificationTime",
                "Value": "2023-10-19T00:00:00",
                "Active": true
            }
        ],
        "sortorder": 4,
        "curriqunetOnly": true
    },
    {
        "label": "Search",
        "description": "Configure curriculum inventory, approval and catalog search.",
        "name": "Search",
        "iconClass": "fa-fw fa-duotone fa-magnifying-glass me-2",
        "smallIconClass": "",
        "active": true,
        "type": "setting",
        "settings": [
            {
                "AccessLevel": "curriqunet",
                "DataType": "string",
                "Description": "",
                "Default": "",
                "Label": "Course Sort String",
                "Name": "CourseSortStrategy",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow Search Filter Saving",
                "Name": "AllowSearchFilterSaving",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Course Title Search",
                "Name": "EnableCourseTitleSearch",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "string",
                "Description": "",
                "Default": "",
                "Label": "Proposal Type Sort",
                "Name": "ProposalTypeSortStrategy",
                "Value": "ORDER BY pt.Active desc, pt.Title",
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "string",
                "Description": "",
                "Default": "",
                "Label": "Award Type Sort",
                "Name": "AwardTypeSortStrategy",
                "Value": null,
                "Active": true
            }
        ],
        "sortorder": 5,
        "curriqunetOnly": true
    },
    {
        "label": "Position",
        "description": "Configure positions.",
        "name": "Position",
        "iconClass": "fa-fw fa-duotone fa-circle-p me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [],
        "sortorder": 6,
        "curriqunetOnly": false
    },
    {
        "label": "Position Groups",
        "description": "Configure position groups",
        "name": "PositionGroups",
        "iconClass": "fa-fw fa-duotone fa-people-group me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [],
        "sortorder": 7,
        "curriqunetOnly": false
    },
    {
        "label": "Users",
        "description": "Configure users, positions and permissions.",
        "name": "Users",
        "iconClass": "fa-fw fa-duotone fa-users me-2",
        "smallIconClass": "fa-duotone fa-user-shield text-danger",
        "active": true,
        "type": "view",
        "settings":[],
        "sortorder": 8,
        "curriqunetOnly": false
    },
    {
        "label": "Workflows",
        "description": "Create and modify approval workflows.",
        "name": "Workflows",
        "iconClass": "fa-fw fa-duotone fa-diagram-next me-2",
        "smallIconClass": "fa-duotone fa-user-shield text-danger",
        "active": true,
        "type": "view",
        "settings": [
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Comment Censor",
                "Name": "AllowCommentCensoring",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Origination Rights Bubble Up",
                "Name": "AllowOriginationBubbleUp",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Origination Rights Bubble Down",
                "Name": "AllowOriginationBubbleDown",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Set workflow comment as RTE",
                "Name": "EnableApprovalCommentRTE",
                "Value": null,
                "Active": true
            }
              
        ],
        "sortorder": 9,
        "curriqunetOnly": false
    },
    {
        "label": "Reports",
        "description": "TBD",
        "name": "Reports",
        "iconClass": "fa-fw fa-duotone fa-file-invoice me-2",
        "smallIconClass": "",
        "active": true,
        "type": "settings",
        "settings": [
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable reports to work for public search",
                "Name": "AllowAnonymousAllFieldsReport",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow Course Not Attached Program",
                "Name": "AllowCourseNotAttachedProgram",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow NOI Form Report",
                "Name": "AllowNoiFormReport",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow LMI Report",
                "Name": "AllowLMIReport",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow ICC Phase Report",
                "Name": "AllowIccPhseReport",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType":"bool",
                "Description": "",
                "Default": false,
                "Label": "Allow Active Program Review Dates Report",
                "Name": "AllowActiveProgramReviewDatesReport",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow Educational Programs Report",
                "Name": "AllowEducationalProgramsReport",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType":"bool",
                "Description": "",
                "Default": false,
                "Label": "Allow Transfer Comparison Report",
                "Name": "AllowTransferComparisonReport",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow Gainful Employment Report",
                "Name": "AllowGainfulEmploymentReport",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow Iowa Program Compliance",
                "Name": "AllowIowaAllProgramCompliance",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Allow Iowa New Program Report",
                "Name": "AllowIowaNewProgramReport",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Agenda Report Table Format",
                "Name": "EnableAgendaTableFormat",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType":"bool",
                "Description": "",
                "Default": "",
                "Label": "Use Standard Program Block Output",
                "Name": "UseStandardProgramBlockOutput",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType":"bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Middle Reports Menu",
                "Name": "AllowUseReportsForUsers",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable ProposalTimeline Report",
                "Name": "AllowProposalTimelineReport",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Agenda Report",
                "Name": "AllowNewAgendaReport",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Curricular Changes Report",
                "Name": "AllowCurricularChangesReport",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Course Outcomes Canvas Report",
                "Name": "AllowCourseOutcomesCanvasReport",
                "Value": false,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Course Fee Report",
                "Name": "AllowCourseFeeReport",
                "Value": false,
                "Active": true
            }
        ],
        "sortorder": 10,
        "curriqunetOnly": true
    },
    {
        "label": "Proposal Types",
        "description": "TBD",
        "name": "ProposalType",
        "iconClass": "fa-fw fa-duotone fa-file-circle-question me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [
            
        ],
        "sortorder": 11,
        "curriqunetOnly": false
    },
    {
        "label": "Lookup Manager",
        "description": "Manage lookups",
        "name": "LookupManager",
        "iconClass": "fa-fw fa-duotone fa-list-check me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [],
        "sortorder": 12,
        "curriqunetOnly": false
    },
    {
        "label": "Data Services",
        "description": "TBD",
        "name": "DataServices",
        "iconClass": "fa-fw fa-duotone fa-database me-2",
        "smallIconClass": "",
        "active": false,
        "type": "view",
        "settings": [],
        "sortorder": 13,
        "curriqunetOnly": true
    },
    {
        "label": "Organization",
        "description": "TBD",
        "name": "Organization",
        "iconClass": "fa-fw fa-duotone fa-sitemap me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Org Management",
                "Name": "EnableOrgManagementTool",
                "Value": true,
                "Active": true
            }
        ],
        "sortorder": 14,
        "curriqunetOnly": false
    },
    {
        "label": "Cross Listings",
        "description": "TBD",
        "name": "CrossListings",
        "iconClass": "fa-fw fa-duotone fa-merge me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [
           
        ],
        "sortorder": 15,
        "curriqunetOnly": false
    },
    {
        "label": "Action",
        "description": "TBD",
        "name": "Action",
        "iconClass": "fa-fw fa-duotone fa-circle-a me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [
           
        ],
        "sortorder": 16,
        "curriqunetOnly": false
    },
    {
        "label": "Holiday",
        "description": "TBD",
        "name": "Holiday",
        "iconClass": "fa-fw fa-duotone fa-calendar me-2",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [
           
        ],
        "sortorder": 17,
        "curriqunetOnly": false
    },
    {
        "label": "Dashboard",
        "description": "TBD",
        "name": "Dashboard",
        "iconClass": "fa-fw fa-duotone fa-objects-column me-2",
        "smallIconClass": "",
        "active": false,
        "type": "view",
        "settings": [],
        "sortorder": 18,
        "curriqunetOnly": true
    },
    {
        "label": "Premium Features",
        "description": "TBD",
        "name": "PremiumFeatures",
        "iconClass": "fa-fw fa-duotone fa-circle-dollar me-2",
        "smallIconClass": "fa-duotone fa-key text-orange",
        "active": false,
        "type": "setting",
        "settings": [],
        "sortorder": 19,
        "curriqunetOnly": true
    },
    {
        "label": "Other",
        "description": "TBD",
        "name": "Other",
        "iconClass": "",
        "smallIconClass": "",
        "active": true,
        "type": "setting",
        "settings": [
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Notes",
                "Name": "AllowNotes",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Notes Delete",
                "Name": "AllowNotesDelete",
                "Value": true,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Block Libraries",
                "Name": "AllowLibraries",
                "Value": null,
                "Active": true
            },
            {
                "AccessLevel": "curriqunet",
                "DataType": "bool",
                "Description": "",
                "Default": false,
                "Label": "Enable Group Vote",
                "Name": "AllowGroupVote",
                "Value": false,
                "Active": true
            }
        ,
    {
        "AccessLevel": "curriqunet",
        "DataType": "bool",
        "Description": "",
        "Default": false,
        "Label": "Hide Skipped Users on workflow approval history",
        "Name": "WorkflowHideSkipped",
        "Value": false,
        "Active": true
    }],
        "sortorder": 20,
        "curriqunetOnly": true
    },
    {
        "label": "Web Services",
        "description": "TBD",
        "name": "WebService",
        "iconClass": "",
        "smallIconClass": "",
        "active": true,
        "type": "view",
        "settings": [],
        "sortorder": 21,
        "curriqunetOnly": false
    },
    {
        "label": "Theme",
        "description": "TBD",
        "name": "Theme",
        "iconClass": "fa-fw fa-duotone fa-brush me-2",
        "smallIconClass": "",
        "active": false,
        "type": "setting",
        "settings": [],
        "sortorder": 22,
        "curriqunetOnly": true
    }
]
'
Where ClientId = @ClientId


UPDATE MetaTemplateType
SET IsReducedView = 0
WHERE MetaTemplateTypeId in (
3, 16
)

DECLARE @SupportAdminUserId INT = (SELECT Id FROM [User] WHERE LastName = 'SupportAdmin')

/********************************************************************
 * Add cross listings
 ********************************************************************/
DECLARE @cl Table (Text NVARCHAR(MAX), base INT, related INT, non int)

INSERT INTO @cl (text, base, related, non)
select  c1.Title, c1.Id, c2.Id, c1.ProposalTypeId
FROM CourseRelatedCourse crc
	INNER JOIN Course c1 on c1.Id = crc.CourseId
	Inner JOIN StatusAlias sa1 on sa1.Id = c1.StatusAliasId
	Inner JOIN Course c2 ON c2.Id = crc.RelatedCourseId
	INNER JOIN StatusAlias sa2 ON sa2.Id = c2.StatusAliasId
WHERE courseId != crc.RelatedCourseId
	AND courseId != c1.PreviousId
	AND sa1.StatusBaseId IN (1)
	AND sa2.StatusBaseId IN (1) 
UNION
select  c1.Title, c1.Id, c2.Id,c1.ProposalTypeId
FROM CourseRelatedCourse crc
	INNER JOIN Course c1 on c1.Id = crc.CourseId
	Inner JOIN StatusAlias sa1 on sa1.Id = c1.StatusAliasId
	Inner JOIN Course c2 ON c2.Id = crc.RelatedCourseId
	INNER JOIN StatusAlias sa2 ON sa2.Id = c2.StatusAliasId
WHERE courseId != crc.RelatedCourseId
	AND courseId != c1.PreviousId
	AND sa1.StatusBaseId IN (6)
	AND sa2.StatusBaseId IN (1) 
INSERT INTO CrossListing (Title, AddedBy_UserId, AddedOn, ClientId)
select Distinct text, @SupportAdminUserId, GETDATE(), @clientId
FROM @cl

DELETE FROM @cl WHERE base in (
	SELECT DISTINCT related FROM @cl
) or related = 1615 or related = 1262
/********************************************************************
 *  INsert the Courses that are cross-listed
 ********************************************************************/
INSERT INTO CrossListingCourse (CrosslistingId,CourseId,AddedBy_UserId,AddedOn,IsSource, IsSynced)
SELECT DISTINCT cl.Id, cll.base, @SupportAdminUserId, GETDATE(), 1, 0
FROM @cl cll
	INNER JOIN CrossListing cl ON cl.Title = cll.text AND cll.Base IS Not NULL
Union
SELECT DISTINCT cl.Id, cll.related , @SupportAdminUserId, GETDATE(), 0, 0
FROM @cl cll
	INNER JOIN CrossListing cl ON cl.Title = cll.text

/********************************************************************
 * Insert the ProposalTypes
 ********************************************************************/
DECLARE @CreditProposalTypeId INT= 3
Merge into CrossListingProposalType as Target
Using (
    Select Id as CrosslistingId,
        @CreditProposalTypeId as ProposalTypeId,
        @SupportAdminUserId as AddedBy_UserId,
        GetDate() as AddedOn,
        @ClientId as ClientId
    From Crosslisting
) as s on 1=0
When not matched then
Insert (CrossListingId,ProposalTypeId,AddedBy_UserId,AddedOn,ClientId)
VALUES (s.CrossListingId,s.ProposalTypeId,s.AddedBy_UserId,s.AddedOn,s.ClientId);


/********************************************************************
 * Sync the cross listings
 ********************************************************************/
DECLARE @cls Table (Id INT IDENTITY Primary KEY, clId INT)
DECLARE @count INT = 1;
DECLARE @crosslistingId INT;
--DECLARE @SupportAdminUserId INT = (SELECT Id FROM [User] WHERE LastName = 'SupportAdmin')

INSERT INTO @cls (clId)
SELECT DISTINCT crosslistingId FROM CrossListingCourse

WHILE @count <= (Select max(Id) FROM @cls)
BEGIN


SET @crosslistingId = (SELECT clId FROM @cls where Id = @count)

Exec upSyncCrossListing @crossListingId = @crosslistingId, @userId = @SupportAdminUserId;
SET @count += 1

END;