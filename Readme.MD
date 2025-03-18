# IAM PowerShell Module for Dynamics 365 Finance & Operations

This readme provides an overview of the setup and configuration to enable orchestration of D365 F&O using PowerShell for IAM Integrations.
The following setup and configuration items then allow the D365FOIAM PowerShell Module to orchestration D365 F&O for User and Role IAM management.

## Prerequisites

API integration to Dynamics 365 Finance & Operations requires:

* registration of an Entra ID Application
* registration of a Dynamics 365 Entra ID Application association
  * creation of a Dynamics 365 F&O System User with permissions for D365 User Administration

### Entra ID

* Register an Entra ID Application through the [Application Registration Entra ID Blade](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
  * Record the following configuration items
    * from the Overview Page
      * Application (client) ID
      * Directory (tenant) ID
  * Create a Client secret from the Certificates & secrets page
    * record the Client Secret value

### Dynamics 365 F&O

* Create a Dynamics 365 System User with permissions for D365 System User administration [SysUserInfoPage](https://YOURTENANT.cloudax.dynamics.com/?cmp=USMC&mi=SysUserInfoPage)
* Create an Azure Active Directory application registration in the [SysAADClientTable](https://YOURTENANT.cloudax.dynamics.com/?cmp=USMC&mi=SysAADClientTable)
  * for Client Id use the Application (client) ID from your Entra ID Application registration
  * for User ID link to a D365 System User with permissions to perform User Management (e.g. System administrator Role)
    * **NOTE** the D365 System User MUST be a System User Account in the associated Entra ID/Azure AD Tenant. IT CANNOT BE A FEDERATED (B2B USER Account)

### Dependancies

The following PowerShell Modules are leveraged by the D365FOIAM PowerShell Module and appear in the modules subdirectory to load locally with tested and verified versionsto interact with D365 F&O.

* [d365fo.integrations](https://github.com/d365collaborative/d365fo.integrations)
* [d365fo.integrations.tools](https://github.com/d365collaborative/d365fo.tools)
  * MUST USE v0.6.79 to avoid conflict with Azure.Storage and AzureRM.Profile
* [JWTDetails](https://www.powershellgallery.com/packages/JWTDetails/1.0.2)
  * Debugging Access Tokens

## D365FOIAM PowerShell Module

### Install the Module from the PowerShell Gallery

From the module source files using an Administrative PowerShell session run the installation script.

```powershell
Install-Module D365FOIAM
```

### Import the Module

Assuming the PowerShell Module has been installed from the PowerShell Gallery ...

```powershell
Import-Module D365FOIAM 
```

If the PowerShell Module has been placed in the PowerShell Modules directory ...

Module cmdlets

```powershell
Get-Command -Module D365FOIAM | Sort-Object Name | Get-Help | Format-Table Name, Synopsis -Autosize
```

### Environment Configuration

Environment configuration sets a series of Global Variables that are used to interact with D365 F&O via the oData APIs and maintain an Access Token from Entra ID.

```powershell
$myD365FOCreds = Get-Credential -Message "Enter the ClientID of the Entra ID Application you've registered and the associated ClientSecret you created."
Set-D365FOGlobals -D365FOTenant "yourtenant.onmicrosoft.com" -D365FOURI "https://yourtenant.cloudax.dynamics.com.onmicrosoft.com" -EntraIDAppClientID $myD365FOCreds.UserName -EntraIDAppClientSecret $myD365FOCreds.Password 
```

### Enumerating D365 F&O Schemas

```powershell  
Get-D365FOSystemUserSchema

Name                 : SystemUser
EntitySetName        : SystemUsers
LabelId              : @SYS12108
IsReadOnly           : False
ConfigurationEnabled : True
Properties           : {@{Name=UserID; TypeName=Edm.String; DataType=String; LabelId=@Kernel:UserInfo_ID; IsKey=True; IsMandatory=True; ConfigurationEnabled=True; AllowEdit=False; AllowEditOnCreate=True; IsDimension=False; DimensionRelation=; IsDynamicDimension=False; DimensionLegalEntityProperty=; DimensionTypeProperty=}, @{Name=StartPage; TypeName=Edm.String;      
                       DataType=String; LabelId=; IsKey=False; IsMandatory=False; ConfigurationEnabled=True; AllowEdit=True; AllowEditOnCreate=True; IsDimension=False; DimensionRelation=; IsDynamicDimension=False; DimensionLegalEntityProperty=; DimensionTypeProperty=}, @{Name=Language; TypeName=Edm.String; DataType=String; LabelId=@SYS66040; IsKey=False;
                       IsMandatory=False; ConfigurationEnabled=True; AllowEdit=True; AllowEditOnCreate=True; IsDimension=False; DimensionRelation=; IsDynamicDimension=False; DimensionLegalEntityProperty=; DimensionTypeProperty=}, @{Name=EventPollFrequency; TypeName=Edm.Int32; DataType=Int32; LabelId=@SYS94046; IsKey=False; IsMandatory=False;
                       ConfigurationEnabled=True; AllowEdit=True; AllowEditOnCreate=True; IsDimension=False; DimensionRelation=; IsDynamicDimension=False; DimensionLegalEntityProperty=; DimensionTypeProperty=}…}
NavigationProperties : {@{Name=DefaultBudgetManager; RelatedEntity=BudgetControlConfiguration; RelatedRelationName=BudgetControlConfigurationDefaultBudgetManager; Cardinality=Multiple; Constraints=System.Object[]}, @{Name=BudgetControlRuleBudgetManager; RelatedEntity=BudgetControlRule; RelatedRelationName=BudgetManagers; Cardinality=Multiple;
                       Constraints=System.Object[]}, @{Name=UserGroupUserList; RelatedEntity=UserGroupUserList; RelatedRelationName=SystemUser; Cardinality=Multiple; Constraints=System.Object[]}, @{Name=BudgetControlGroupBudgetManager; RelatedEntity=BudgetControlGroup; RelatedRelationName=BudgetManagers; Cardinality=Multiple; Constraints=System.Object[]}…}
PropertyGroups       : {}
Actions              : {}
```

```powershell
Get-D365FOSecurityUserRolesSchema

Name                 : SecurityUserRole
EntitySetName        : SecurityUserRoles
LabelId              : @SysSecLabels:SystemSecurityUserRoleEntity
IsReadOnly           : False
ConfigurationEnabled : True
Properties           : {@{Name=UserId; TypeName=Edm.String; DataType=String; LabelId=User ID; IsKey=True; IsMandatory=True; ConfigurationEnabled=True; AllowEdit=False; AllowEditOnCreate=True; IsDimension=False; DimensionRelation=; IsDynamicDimension=False; DimensionLegalEntityProperty=; DimensionTypeProperty=}, @{Name=SecurityRoleIdentifier; TypeName=Edm.String;     
                       DataType=String; LabelId=Role AOT name; IsKey=True; IsMandatory=False; ConfigurationEnabled=True; AllowEdit=False; AllowEditOnCreate=True; IsDimension=False; DimensionRelation=; IsDynamicDimension=False; DimensionLegalEntityProperty=; DimensionTypeProperty=}, @{Name=AssignmentStatus;
                       TypeName=Microsoft.Dynamics.DataEntities.RoleAssignmentStatus; DataType=Enum; LabelId=; IsKey=False; IsMandatory=False; ConfigurationEnabled=True; AllowEdit=True; AllowEditOnCreate=True; IsDimension=False; DimensionRelation=; IsDynamicDimension=False; DimensionLegalEntityProperty=; DimensionTypeProperty=}, @{Name=AssignmentMode;
                       TypeName=Microsoft.Dynamics.DataEntities.RoleAssignmentMode; DataType=Enum; LabelId=; IsKey=False; IsMandatory=False; ConfigurationEnabled=True; AllowEdit=True; AllowEditOnCreate=True; IsDimension=False; DimensionRelation=; IsDynamicDimension=False; DimensionLegalEntityProperty=; DimensionTypeProperty=}…}
NavigationProperties : {}
PropertyGroups       : {}
Actions              : {}
```

### Enumerating D365 System Users

```powershell
Get-D365FOSystemUsers | select-object -last 1

@odata.etag                                      : W/"JzIxMzMwMjA5MjgsNjg3MjEzNzQxMDk7MSw2ODcxOTUxNzMzMyc="
UserID                                           : TimR
StartPage                                        : DefaultDashboard
Language                                         : 
EventPollFrequency                               : 15
ShowNotificationsInTheMicrosoftDynamicsAX7Client : Yes
DefaultCountryRegion                             : 
EventPopUpDisplayWhen                            : DefinedOnRule
AutomaticUrlUpdate                               : No
EventPopUpLinkDestination                        : ToAlert
UserInfo_language                                : en-us
HomePageRefreshDuration                          : 0
Density                                          : 
Company                                          : USMC
ExternalUser                                     : False
UserName                                         : TimRite
EventPopUps                                      : No
EmailProviderID                                  : 
SqmEnabled                                       : PromptMe
EventWorkflowShowPopup                           : Yes
SendNotificationsInEmail                         : No
NetworkDomain                                    : https://sts.windows.net/darrenjrobinson
DocumentHandlingActive                           : Yes
PreferredLocale                                  : 
PersonName                                       : 
Alias                                            : t.rite@darrenjrobinson.com
Email                                            : 
GlobalExcelExportFilePath                        : 
AutoLogOff                                       : 0
PreferredCalendar                                : Gregorian
SendAlertAsEmailMessage                          : DefinedOnRule
AccountType                                      : ClaimsUser
SqmGUID                                          : 00000000-0000-0000-0000-000000000000
GlobalExcelExportMode                            : 0
WorkflowLineItemNotificationFormat               : Grouped
PreferredTimeZone                                : GMT_COORDINATEDUNIVERSALTIME
Helplanguage                                     : en-us
MarkEmptyLinks                                   : No
Enabled                                          : False
Theme                                            : Theme0
EventWorkflowTasksInActionCenter                 : No
GlobalListPageLinkMode                           : 0
UserInfo_defaultPartition                        : True
ShowAttachmentStatus                             : No

```

```powershell
Get-D365FOSystemUsers | Where-Object {$_.UserId -like '*Darren*'} | Select-Object -Property UserId, Alias, Enabled

UserID            Alias                                        Enabled
------            -----                                        -------
darren            darren@darrenjrobinson.com                   True
darrenjrobinson   darren@darrenjrobinson.onmicrosoft.com       True
```

### Enumerating D365 Roles

```powershell

Get-D365FOSecurityUserRoles | Select-Object -Skip 350 | Format-Table

@odata.etag              UserId               SecurityRoleIdentifier                  AssignmentStatus AssignmentMode SecurityRoleName                                UserLicenseType
-----------              ------               ----------------------                  ---------------- -------------- ----------------                                ---------------
W/"JzEsNTYzODYyNjY2MSc=" RetailServiceAccount INVENTCOSTACCOUNTANT                    Enabled          Manual         Inventory accountant                            Enterprise
W/"JzEsNTYzODYyNjY2Myc=" RetailServiceAccount INVENTCOSTCOSTCLERK                     Enabled          Manual         Inventory accountant clerk                      Enterprise
W/"JzEsNTYzODYyNjY2NSc=" RetailServiceAccount INVENTMATERIALSMANAGER                  Enabled          Manual         Materials manager                               Enterprise
W/"JzEsNTYzODYyNjY2Nyc=" RetailServiceAccount INVENTQUALITYCONTROLMANAGER             Enabled          Manual         Quality control manager                         Enterprise
W/"JzEsNTYzODYyNjY2OSc=" RetailServiceAccount INVENTRECEIVINGCLERK                    Enabled          Manual         Receiving clerk                                 Activity
W/"JzEsNTYzODYyNjY3MSc=" RetailServiceAccount INVENTSHIPPINGCLERK                     Enabled          Manual         Shipping clerk                                  Activity
W/"JzEsNTYzODYyNjY3Myc=" RetailServiceAccount JMGADVTIMEWORKER                        Enabled          Manual         Time registration user                          Universal
W/"JzEsNTYzODYyNjY3NSc=" RetailServiceAccount TRADEPURCHASINGMANAGER                  Enabled          Manual         Purchasing manager                              Enterprise
W/"JzEsNTYzODYyNjY3Nyc=" RetailServiceAccount RETAILCATALOGMANAGER                    Enabled          Manual         Retail catalog manager                          Enterprise
W/"JzEsNTYzODYyNjY3OSc=" RetailServiceAccount RETAILMERCHANDISINGMANAGER              Enabled          Manual         Retail merchandising manager                    Enterprise
W/"JzEsNTYzODYyNjY4MSc=" RetailServiceAccount RETAILOPERATIONSMANAGER                 Enabled          Manual         Retail operations manager                       Enterprise
W/"JzEsNTYzODYyNjY4Myc=" RetailServiceAccount RETAILWAREHOUSEMANAGER                  Enabled          Manual         Retail warehouse manager                        Activity
W/"JzEsNTYzODYyNjY4NSc=" RetailServiceAccount RETAILWAREHOUSECLERK                    Enabled          Manual         Retail warehouse clerk                          Universal
W/"JzEsNTYzODYyNjY4Nyc=" RetailServiceAccount TRADESALESCLERK                         Enabled          Manual         Sales clerk                                     Activity
W/"JzEsNTYzODYyNjY4OSc=" RetailServiceAccount TRADESALESMANAGER                       Enabled          Manual         Sales manager                                   Enterprise
W/"JzEsNTYzODYyNjY5MSc=" RetailServiceAccount TRADESALESREPRESENTATIVE                Enabled          Manual         Sales representative                            Activity
W/"JzEsNTYzODYyNjY5Myc=" RetailServiceAccount SMASERVICEDELIVERYMANAGER               Enabled          Manual         Service delivery manager                        Enterprise
W/"JzEsNTYzODYyNjY5Nyc=" RetailServiceAccount FBTAXACCOUNTANT_BR                      Enabled          Manual         Tax accountant                                  Enterprise
W/"JzEsNTYzODYyNjY5OSc=" RetailServiceAccount VENDVENDORACCOUNTMANAGER                Enabled          Manual         Vendor account manager                          Activity
W/"JzEsNTYzODYyNjcwMSc=" RetailServiceAccount VENDPURCHASINGAGENT                     Enabled          Manual         Purchasing agent                                Enterprise
W/"JzEsNTYzODYyNjcwMyc=" PowerPlatformApp     CDSVIRTUALENTITYAPPLICATION             Enabled          Manual         Dataverse Virtual entity integration app        None
W/"JzEsNTYzODYyNjcwNSc=" PowerPlatformApp     CDSVIRTUALENTITYAUTHENTICATEDPORTALUSER Enabled          Manual         Dataverse Virtual entity authenticated user     None
W/"JzEsNTYzODYyNjcwNyc=" PowerPlatformApp     CDSVIRTUALENTITYANONYMOUSPORTALUSER     Enabled          Manual         Dataverse Virtual entity anonymous user         None
W/"JzEsNTYzODYyNjcwOSc=" PowerPlatformApp     BUSINESSEVENTSSECURITYROLE              Enabled          Manual         Business events security role                   Enterprise
W/"JzEsNTYzODYyNjcxNCc=" ScaleUnitPipeline    SCALEUNITDATAPIPELINEROLE               Enabled          Manual         ScaleUnitDataPipelineRole                       None
W/"JzEsNTYzODYyNjcxNic=" ScaleUnitManagement  SCALEUNITADMIN                          Enabled          Manual         Scale unit management                           None
W/"JzEsNTYzODYyNjcxOSc=" MonitoringAppUser    SYSMONSECURITYROLE                      Enabled          Manual         SysMonSecurityRole                              None
W/"JzEsNTYzODYyNjcyMic=" DataSyncFrameworkApp CDSVIRTUALENTITYDATASYNCFRAMEWORK       Enabled          Manual         Dataverse data sync framework application role. None
W/"JzEsNTYzODYyNjcyNSc=" DynamicsMaintAppUser DYNAMICSMAINTENANCEAPPUSERSECURITYROLE  Enabled          Manual         Dynamics Maintenance User Role                  None
W/"JzEsNTYzODg5Nzc1Nyc=" darren               SYSTEMUSER                              Enabled          Manual         System user                                     Universal
W/"JzEsNTYzODg5Nzc1OSc=" darren               -SYSADMIN-                              Enabled          Manual         System administrator                            Enterprise
W/"JzEsNTYzODkwMDAwOSc=" Guest                GUEST                                   Enabled          Manual         Guest                                           Universal
W/"JzEsNTYzODkwMDAxNic=" darrenjrobinson    SYSTEMUSER                              Enabled          Manual         System user                                     Universal
W/"JzEsNTYzODkwMDAyMCc=" darrenjrobinson    -SYSADMIN-                              Enabled          Manual         System administrator                            Enterprise

```

```powershell
Get-D365FOSecurityUserRoleAssociations | Select-Object -Skip 400 | Format-Table

@odata.etag              UserId            SecurityRoleIdentifier AssignmentStatus AssignmentMode SecurityRoleName
-----------              ------            ---------------------- ---------------- -------------- ----------------
W/"JzEsNTYzODg5Nzc1Nyc=" darren            SYSTEMUSER             Enabled          Manual         System user
W/"JzEsNTYzODg5Nzc1OSc=" darren            -SYSADMIN-             Enabled          Manual         System administrator
W/"JzEsNTYzODkwMDAwOSc=" Guest             GUEST                  Enabled          Manual         Guest
W/"JzEsNTYzODkwMDAxNic=" darrenjrobinson SYSTEMUSER             Enabled          Manual         System user
W/"JzEsNTYzODkwMDAyMCc=" darrenjrobinson -SYSADMIN-             Enabled          Manual         System administrator
```

### Creating D365 F&O System Users

```powershell
New-D365FOSystemUser -Company "USMC" -NetworkDomain 'https://sts.windows.net/darrenjrobinson' -UserName 'TimRite' -UserID 'TimR' -Alias 't.rite@darrenjrobinson.com'

"--batchresponse_45d1cd04-0377-4f53-b4bb-46822119f1c1\r\nContent-Type: multipart/mixed; boundary=changesetresponse_92f72077-fcc4-4055-9b2a-a40f44f11e2a\r\n\r\n--changesetresponse_92f72077-fcc4-4055-9b2a-a40f44f11e2a\r\nContent-Type: application/http\r\nContent-Transfer-Encoding: binary\r\nContent-ID: 1\r\n\r\nHTTP/1.1 201 Created\r\nETag: W/\"JzEsNjg3MjEzNzQxMDk7MSw2ODcxOTUxNzMzMyc=\"\r\nLocation: https://d365foperfpoc3ff96227df736db3devaos.cloudax.dynamics.com/data/SystemUsers('TimR')\r\nContent-Type: application/json; odata.metadata=minimal\r\nOData-Version: 4.0\r\n\r\n{\r\n  \"@odata.context\":\"https://d365foperfpoc3ff96227df736db3devaos.cloudax.dynamics.com/data/$metadata#SystemUsers/$entity\",\"@odata.etag\":\"W/\\\"JzEsNjg3MjEzNzQxMDk7MSw2ODcxOTUxNzMzMyc=\\\"\",\"UserID\":\"TimR\",\"StartPage\":\"DefaultDashboard\",\"Language\":\"\",\"EventPollFrequency\":15,\"ShowNotificationsInTheMicrosoftDynamicsAX7Client\":\"Yes\",\"DefaultCountryRegion\":\"\",\"EventPopUpDisplayWhen\":\"DefinedOnRule\",\"AutomaticUrlUpdate\":\"No\",\"EventPopUpLinkDestination\":\"ToAlert\",\"UserInfo_language\":\"en-us\",\"HomePageRefreshDuration\":0,\"Density\":null,\"Company\":\"USMC\",\"ExternalUser\":false,\"UserName\":\"TimRite\",\"EventPopUps\":\"No\",\"EmailProviderID\":\"\",\"SqmEnabled\":\"PromptMe\",\"EventWorkflowShowPopup\":\"Yes\",\"SendNotificationsInEmail\":\"No\",\"NetworkDomain\":\"https://sts.windows.net/darrenjrobinson\",\"DocumentHandlingActive\":\"Yes\",\"PreferredLocale\":\"\",\"PersonName\":\"\",\"Alias\":\"t.rite@darrenjrobinson.com\",\"Email\":\"\",\"GlobalExcelExportFilePath\":\"\",\"AutoLogOff\":0,\"PreferredCalendar\":\"Gregorian\",\"SendAlertAsEmailMessage\":\"DefinedOnRule\",\"AccountType\":\"ClaimsUser\",\"SqmGUID\":\"00000000-0000-0000-0000-000000000000\",\"GlobalExcelExportMode\":0,\"WorkflowLineItemNotificationFormat\":\"Grouped\",\"PreferredTimeZone\":\"GMT_COORDINATEDUNIVERSALTIME\",\"Helplanguage\":\"en-us\",\"MarkEmptyLinks\":\"No\",\"Enabled\":true,\"Theme\":\"Theme0\",\"EventWorkflowTasksInActionCenter\":\"No\",\"GlobalListPageLinkMode\":0,\"UserInfo_defaultPartition\":true,\"ShowAttachmentStatus\":\"No\"\r\n}\r\n--changesetresponse_92f72077-fcc4-4055-9b2a-a40f44f11e2a--\r\n--batchresponse_45d1cd04-0377-4f53-b4bb-46822119f1c1--\r\n"

Get-D365FOSystemUsers | Where-Object {$_.UserId -eq 'TimR'} | Select-Object -Property UserId, Alias, Enabled

UserID Alias                Enabled
------ -----                -------
TimR  t.rite@darrenjrobinson.com    True
```

### Updating D365 F&O System Users

```powershell
Update-D365FOSystemUser -Update @{Enabled = 'False'} -UserID 'TimR'
"--batchresponse_dd46a8bf-5041-4a81-bf33-a5fafa3c94ac\r\nContent-Type: multipart/mixed; boundary=changesetresponse_f3cb9a22-8c26-444a-993f-2a1c72b32b03\r\n\r\n--changesetresponse_f3cb9a22-8c26-444a-993f-2a1c72b32b03\r\nContent-Type: application/http\r\nContent-Transfer-Encoding: binary\r\nContent-ID: 1\r\n\r\nHTTP/1.1 204 No Content\r\n\r\n\r\n--changesetresponse_f3cb9a22-8c26-444a-993f-2a1c72b32b03--\r\n--batchresponse_dd46a8bf-5041-4a81-bf33-a5fafa3c94ac--\r\n"

Get-D365FOSystemUsers | Where-Object {$_.UserId -eq 'TimR'} | Select-Object -Property UserId, Alias, Enabled

UserID Alias                Enabled
------ -----                -------
TimR  t.rite@darrenjrobinson.com   False
```

### Adding Roles to D365 F&O System Users

```powershell
$addRole = [pscustomobject][ordered]@{
    UserId                 = 'darrenjrobinson'
    SecurityRoleIdentifier = 'HCMMANAGER'
    AssignmentStatus       = 'Enabled'
    AssignmentMode         = 'Manual'
    SecurityRoleName       = 'Manager'
}

Add-D365FORoleToSystemUser -Role $addRole

"--batchresponse_760ecb25-9b01-471d-84ed-13ef67b2c638\r\nContent-Type: multipart/mixed; boundary=changesetresponse_f73fc1da-13ec-4feb-b7a5-4bfc0eb3ce51\r\n\r\n--changesetresponse_f73fc1da-13ec-4feb-b7a5-4bfc0eb3ce51\r\nContent-Type: application/http\r\nContent-Transfer-Encoding: binary\r\nContent-ID: 1\r\n\r\nHTTP/1.1 201 Created\r\nETag: W/\"JzEsNTYzODkwMDAzMSc=\"\r\nLocation: https://d365foperfpoc3ff96227df736db3devaos.cloudax.dynamics.com/data/SecurityUserRoleAssociations(UserId='darrenjrobinson',SecurityRoleIdentifier='HCMMANAGER')\r\nContent-Type: application/json; odata.metadata=minimal\r\nOData-Version: 4.0\r\n\r\n{\r\n  \"@odata.context\":\"https://d365foperfpoc3ff96227df736db3devaos.cloudax.dynamics.com/data/$metadata#SecurityUserRoleAssociations/$entity\",\"@odata.etag\":\"W/\\\"JzEsNTYzODkwMDAzMSc=\\\"\",\"UserId\":\"darrenjrobinson\",\"SecurityRoleIdentifier\":\"HCMMANAGER\",\"AssignmentStatus\":\"Enabled\",\"AssignmentMode\":\"Manual\",\"SecurityRoleName\":\"Manager\"\r\n}\r\n--changesetresponse_f73fc1da-13ec-4feb-b7a5-4bfc0eb3ce51--\r\n--batchresponse_760ecb25-9b01-471d-84ed-13ef67b2c638--\r\n"

Get-D365FOSecurityUserRoleAssociations | Where-Object {$_.UserId -eq 'darrenjrobinson'}

@odata.etag            : W/"JzEsNTYzODkwMDAxNic="
UserId                 : darrenjrobinson
SecurityRoleIdentifier : SYSTEMUSER
AssignmentStatus       : Enabled
AssignmentMode         : Manual
SecurityRoleName       : System user

@odata.etag            : W/"JzEsNTYzODkwMDAyMCc="
UserId                 : darrenjrobinson
SecurityRoleIdentifier : -SYSADMIN-
AssignmentStatus       : Enabled
AssignmentMode         : Manual
SecurityRoleName       : System administrator

@odata.etag            : W/"JzEsNTYzODkwMDAzMSc="
UserId                 : darrenjrobinson
SecurityRoleIdentifier : HCMMANAGER
AssignmentStatus       : Enabled
AssignmentMode         : Manual
SecurityRoleName       : Manager
```

### Removing Roles from D365 F&O System Users

```powershell
Remove-D365FORoleFromSystemUser -SecurityRoleIdentifier 'HCMMANAGER' -UserId 'darrenjrobinson'

"--batchresponse_6bdf379c-d58d-48a5-bf09-257ba501d469\r\nContent-Type: multipart/mixed; boundary=changesetresponse_a5e77f5c-61a3-4a40-9b88-4795ba74c504\r\n\r\n--changesetresponse_a5e77f5c-61a3-4a40-9b88-4795ba74c504\r\nContent-Type: application/http\r\nContent-Transfer-Encoding: binary\r\nContent-ID: 1\r\n\r\nHTTP/1.1 204 No Content\r\n\r\n\r\n--changesetresponse_a5e77f5c-61a3-4a40-9b88-4795ba74c504--\r\n--batchresponse_6bdf379c-d58d-48a5-bf09-257ba501d469--\r\n"

Get-D365FOSecurityUserRoleAssociations | Where-Object {$_.UserId -eq 'darrenjrobinson'}

@odata.etag            : W/"JzEsNTYzODkwMDAxNic="
UserId                 : darrenjrobinson
SecurityRoleIdentifier : SYSTEMUSER
AssignmentStatus       : Enabled
AssignmentMode         : Manual
SecurityRoleName       : System user

@odata.etag            : W/"JzEsNTYzODkwMDAyMCc="
UserId                 : darrenjrobinson
SecurityRoleIdentifier : -SYSADMIN-
AssignmentStatus       : Enabled
AssignmentMode         : Manual
SecurityRoleName       : System administrator
```

### Disabling D365 F&O System Users

```powershell
Update-D365FOSystemUser -Update @{Enabled = 'False'} -UserID 'TimR'
"--batchresponse_dd46a8bf-5041-4a81-bf33-a5fafa3c94ac\r\nContent-Type: multipart/mixed; boundary=changesetresponse_f3cb9a22-8c26-444a-993f-2a1c72b32b03\r\n\r\n--changesetresponse_f3cb9a22-8c26-444a-993f-2a1c72b32b03\r\nContent-Type: application/http\r\nContent-Transfer-Encoding: binary\r\nContent-ID: 1\r\n\r\nHTTP/1.1 204 No Content\r\n\r\n\r\n--changesetresponse_f3cb9a22-8c26-444a-993f-2a1c72b32b03--\r\n--batchresponse_dd46a8bf-5041-4a81-bf33-a5fafa3c94ac--\r\n"

Get-D365FOSystemUsers | Where-Object {$_.UserId -eq 'TimR'} | Select-Object -Property UserId, Alias, Enabled

UserID Alias                Enabled
------ -----                -------
TimR  t.rite@darrenjrobinson.com   False
```

Author: [Darren Robinson](mailto:darren@darrenjrobinson.com)
