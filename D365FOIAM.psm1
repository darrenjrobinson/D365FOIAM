<#
Install Module Dependancies
- [d365fo.integrations](https://github.com/d365collaborative/d365fo.integrations)
- [d365fo.integrations.tools](https://github.com/d365collaborative/d365fo.tools)
    - MUST USE v0.6.79 to avoid conflict with Azure.Storage and AzureRM.Profile
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# if (-not(get-module -ListAvailable -name d365fo.integrations).Version -ge [System.Version]"0.4.38") {
#     Install-Module -Name d365fo.integrations -AllowClobber -Force 
# }

# if (-not(get-module -ListAvailable -Name d365fo.tools).Version -ge [System.Version]"0.6.79") {
#     Install-Module -Name d365fo.tools -RequiredVersion 0.6.79 -AllowClobber -Force
# }

# if (-not(get-module -ListAvailable -Name JWTDetails)) {
#     Install-Module -Name JWTDetails -AllowClobber -Force
# }


# Import D365 PSModules

# Import-Module d365fo.tools -RequiredVersion 0.6.79
# Import-Module d365fo.integrations
# Set-ExecutionPolicy RemoteSigned
Import-Module -Name $PSScriptRoot\Modules\d365fo.tools\0.6.79\d365fo.tools.psm1 
Import-Module -Name $PSScriptRoot\Modules\d365fo.integrations\0.4.38\d365fo.integrations.psm1  

# Enable Exceptions
Enable-D365ExceptionIntegrations

# JWT Token Module

# Import-Module JWTDetails

Import-Module -Name $PSScriptRoot\Modules\JWTDetails\1.0.3\JWTDetails.psm1

function Set-D365FOGlobals {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$D365FOTenant,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$D365FOURI,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$EntraIDAppClientID,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [securestring]$EntraIDAppClientSecret
    )

    <#
.SYNOPSIS

Set Global variables used in D365 oData API functions

.DESCRIPTION

Set Global variables used in D365 oData API functions

.PARAMETER D365FOTenant

D365 AAD/Entra ID TenantId. Can be either the AAD/Entra ID TenantId GUID or TenantName
e.g. yourtenant.onmicrosoft.com or ff43e024-31ef-babe-73372-e31c3b31949e

.PARAMETER D365FOURI

D365 URL.
e.g. https://yourtenant.cloudax.dynamics.com.onmicrosoft.com 


.PARAMETER EntraIDAppClientID

EntraID Application Registration Client (Application) ID.
e.g. d55a2c66-727a-460d-ba91-56bd167ccdad 

.PARAMETER EntraIDAppClientSecret

[SecureString]
EntraID Application Registration Client Secret.
e.g. System.Security.SecureString

.INPUTS

Token from Pipeline 

.OUTPUTS

PowerShell Object

.SYNTAX

Set-D365FOGlobals

.EXAMPLE

PS> Set-D365FOGlobals -D365FOTenant "yourtenant.onmicrosoft.com" -D365FOURI "https://yourtenant.cloudax.dynamics.com.onmicrosoft.com" -EntraIDAppClientID d55a2c66-727a-460d-ba91-56bd167ccdad -EntraIDAppClientSecret System.Security.SecureString

.LINK

https://blog.darrenjrobinson.com


#>
    $Global:D365FOTenant = $D365FOTenant 
    $Global:D365FOURI = $D365FOURI
    $Global:D365FOCredential = New-Object System.Management.Automation.PSCredential ($EntraIDAppClientID, $EntraIDAppClientSecret)

    if ($D365FOCredential -and ($null -ne $D365FOTenant) -and ($null -ne $D365FOURI)) {
        Try {
            Add-D365ODataConfig -Name "D365Integration" -Tenant $Global:D365FOTenant -url $Global:D365FOURI -ClientId $D365FOCredential.UserName -ClientSecret (ConvertFrom-SecureString $D365FOCredential.Password -AsPlainText) -Force
            Set-D365ActiveODataConfig -Name D365FOIntegration -Temporary
            
            $Global:D365FOToken = Get-D365ODataToken -Tenant $Global:D365FOTenant -Url $Global:D365FOURI -ClientId $D365FOCredential.UserName -ClientSecret (ConvertFrom-SecureString $D365FOCredential.Password -AsPlainText) -Debug -Verbose -EnableException
            if (get-module -name JWTDetails) {
                Get-JWTDetails -token ($Global:D365FOToken -split " ")[1]
            }
        }
        catch {
            try {
                $Global:D365FOToken = Get-D365ODataTokenInteractive -Tenant $Global:D365FOTenant -Url $Global:D365FOURI 
            }
            catch {
                Write-Error $_
            }
            Write-Error $_ -ErrorAction Continue
        }
    }
}


function Get-D365FOPersonUserSchema {
    <#

.Synopsis
Retrieves the metadata schema for the Dynamics 365 Front Office (FO) PersonUser entity.

.Description
The Get-D365FOPersonUserSchema function retrieves the metadata schema for the Dynamics 365 Front Office (FO) PersonUser entity using the OData REST API. It requires the Global:D365FOToken variable to be set, which contains the access token for Dynamics 365 FO. The function returns the entity schema data as a PowerShell object.

.Parameter
None.

.Inputs
None.

.Outputs
value: A PowerShell object containing the entity schema data.

.Example
$personUserSchema = Get-D365FOPersonUserSchema
Write-Output $personUserSchema

#>

    [cmdletbinding()]
    param()
    Try {
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken
        $response = Get-D365ODataPublicEntity -EntityName "PersonUser" -Token $Global:D365FOToken 
        return $response
    }
    catch {
        Write-Error "Unable to refresh/get Access Token. Ensure you have successfully configured your system and run Set-Globals."
        Write-Error $_
    }
}

function Get-D365FOSystemUserSchema {

    <#

.Synopsis
Retrieves the metadata schema for the Dynamics 365 Front Office (FO) SystemUser entity.

.Description
The Get-D365FOSystemUserSchema function retrieves the metadata schema for the Dynamics 365 Front Office (FO) SystemUser entity using the OData REST API. It requires the Global:D365FOToken variable to be set, which contains the access token for Dynamics 365 FO. The function returns the entity schema data as a PowerShell object.

.Parameter
None.

.Inputs
None.

.Outputs
value: A PowerShell object containing the entity schema data.

.Example
$systemUserSchema = Get-D365FOSystemUserSchema
Write-Output $systemUserSchema


#>

    [cmdletbinding()]
    param()
    Try {
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken
        $response = Get-D365ODataPublicEntity -EntityName "SystemUser" -Token $Global:D365FOToken 
        return $response
    }
    catch {
        Write-Error "Unable to refresh/get Access Token. Ensure you have successfully configured your system and run Set-Globals."
        Write-Error $_
    }
}

function Get-D365FOPersonUsers {

    <#
    
.Synopsis
Retrieves all Dynamics 365 Front Office (FO) PersonUser entities.

.Description
The Get-D365FOPersonUsers function retrieves all Dynamics 365 Front Office (FO) PersonUser entities using the OData REST API. It requires the Global:D365FOToken variable to be set, which contains the access token for Dynamics 365 FO. The function returns the PersonUser entity data as a PowerShell object.

.Parameter
None.

.Inputs
None.

.Outputs
value: A PowerShell object containing the PersonUser entity data.

.Example
$personUsers = Get-D365FOPersonUsers
Write-Output $personUsers
    #>


    [cmdletbinding()]
    param()
    Try {
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken
        $response = Get-D365ODataEntityData -EntitySetName "PersonUsers" -Token $Global:D365FOToken -TraverseNextLink
        return $response
    }
    catch {
        Write-Error "Unable to refresh/get Access Token. Ensure you have successfully configured your system and run Set-Globals."
        Write-Error $_
    }
}

function Get-D365FOSystemUsers {

    <#

.Synopsis
Retrieves all Dynamics 365 Front Office (FO) SystemUser entities. If $userId parameter is provided - return one user.

.Description
The Get-D365FOSystemUser function retrieves all Dynamics 365 Front Office (FO) SystemUser entities using the OData REST API. 
It requires the Global:D365FOToken variable to be set, which contains the access token for Dynamics 365 FO. 
The function returns the SystemUser entity data as a PowerShell object.
If userId parameter is supplied - return only one user.

.Parameter
None.

.Inputs
$userId. If no parameter supplied - returns all system users

.Outputs
value: A PowerShell object containing the SystemUser entity data.

.Example
$systemUsers = Get-D365FOSystemUsers
Write-Output $systemUsers
#>

    [cmdletbinding()]
    param(
        [string] $userId
    )
    Try {
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken

        if ($userId) {
            $response = Get-D365ODataEntityData -EntitySetName "SystemUsers" -ODataQuery $('$filter=UserID eq ''' + $userId + '''')  -Token $Global:D365FOToken 
        }
        else {
            $response = Get-D365ODataEntityData -EntitySetName "SystemUsers" -Token $Global:D365FOToken -TraverseNextLink
        }
        return $response
    }
    catch {
        Write-Error "Unable to refresh/get Access Token. Ensure you have successfully configured your system and run Set-Globals."
        Write-Error $_
    }
}

function Get-D365FOSecurityRoles {
    <#
    
    .Synopsis
    Retrieves the metadata schema for the Dynamics 365 Front Office (FO) SecurityRoles entity.
    
    .Description
    The Get-D365FOSecurityRoles function retrieves the metadata schema for the Dynamics 365 Front Office (FO) SecurityRoles entity using the OData REST API. It requires the Global:D365FOToken variable to be set, which contains the access token for Dynamics 365 FO. The function returns the entity schema data as a PowerShell object.
    
    .Parameters
    None.
    
    .Inputs
    None.
    
    .Outputs
    value: A PowerShell object containing the entity schema data.
    
    .Example
    $securityRoles = Get-D365FOSecurityRoles
    Write-Output $securityRoles
    
    #>
    
    [cmdletbinding()]
    param(
        [string] $secRoleId
    )
    Try {
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken
            
        if ($secRoleId) {
            $response = Get-D365ODataEntityData -EntitySetName "SecurityRoles" -ODataQuery $('$filter=SecurityRoleIdentifier eq ''' + $secRoleId + '''')  -Token $Global:D365FOToken 
        }
        else {
            $response = Get-D365ODataEntityData -EntitySetName "SecurityRoles" -Token $Global:D365FOToken -TraverseNextLink
        }
        return $response
    }
    catch {
        Write-Error "Unable to refresh/get Access Token. Ensure you have successfully configured your system and run Set-Globals."
        Write-Error $_
    }
}
        
function Get-D365FOSecurityUserRolesSchema {
    [cmdletbinding()]
    param()
    Try {
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken
        $response = Get-D365ODataPublicEntity -EntityName "SecurityUserRoles" -Token $Global:D365FOToken 
        return $response
    }
    catch {
        Write-Error "Unable to refresh/get Access Token. Ensure you have successfully configured your system and run Set-Globals."
        Write-Error $_
    }
}

function Get-D365FOSecurityUserRoles {

    <#

.Synopsis
Retrieves the metadata schema for the Dynamics 365 Front Office (FO) SecurityUserRoles entity.

.Description
The Get-D365FOSecurityUserRolesSchema function retrieves the metadata schema for the Dynamics 365 Front Office (FO) SecurityUserRoles entity using the OData REST API. It requires the Global:D365FOToken variable to be set, which contains the access token for Dynamics 365 FO. The function returns the entity schema data as a PowerShell object.

.Parameters
None.

.Inputs
None.

.Outputs
value: A PowerShell object containing the entity schema data.

.Example
$securityUserRolesSchema = Get-D365FOSecurityUserRolesSchema
Write-Output $securityUserRolesSchema

#>

    [cmdletbinding()]
    param(
        [string] $secRoleId = $null,
        [string] $userId = $null
    )
    Try {
        
        if ($secRoleId -and $userId) {
            $query = $('$filter=SecurityRoleIdentifier eq ''' + $secRoleId + ''' and  UserId eq ''' + $userId + '''')
        }
        elseif ($secRoleId) {
            $query = $('$filter=SecurityRoleIdentifier eq ''' + $secRoleId + '''')
        }
        elseif ($userId) {
            $query = $('$filter=UserId eq ''' + $userId + '''') 
        }
        
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken
     
        if ($query) {
            $response = Get-D365ODataEntityData -EntitySetName "SecurityUserRoles" -ODataQuery $query -Token $Global:D365FOToken -TraverseNextLink
        }
        else {
            $response = Get-D365ODataEntityData -EntitySetName "SecurityUserRoles" -Token $Global:D365FOToken -TraverseNextLink
        }
        
        return $response
    }
    catch {
        Write-Error "Unable to refresh/get Access Token. Ensure you have successfully configured your system and run Set-Globals."
        Write-Error $_
    }
}

function Get-D365FOSecurityUserRoleAssociations {

    <#
    
.Synopsis
Retrieves all Dynamics 365 Front Office (FO) SecurityUserRoleAssociation entities.

.Description
The Get-D365FOSecurityUserRoleAssociations function retrieves all Dynamics 365 Front Office (FO) SecurityUserRoleAssociation entities using the OData REST API. It requires the Global:D365FOToken variable to be set, which contains the access token for Dynamics 365 FO. The function returns the SecurityUserRoleAssociation entity data as a PowerShell object.

.Parameter
None.

.Inputs
None.

.Outputs
value: A PowerShell object containing the SecurityUserRoleAssociation entity data.

.Example
$securityUserRoleAssociations = Get-D365FOSecurityUserRoleAssociations
Write-Output $securityUserRoleAssociations

    
    #>
    [cmdletbinding()]
    param(
        [string] $secRoleId = $null,
        [string] $userId = $null
    )

    if ($secRoleId -and $userId) {
        $query = $('$filter=SecurityRoleIdentifier eq ''' + $secRoleId + ''' and  UserId eq ''' + $userId + '''')
    }
    elseif ($secRoleId) {
        $query = $('$filter=SecurityRoleIdentifier eq ''' + $secRoleId + '''')
    }
    elseif ($userId) {
        $query = $('$filter=UserId eq ''' + $userId + '''') 
    }

    Try {
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken

        if ($query) {
            $response = Get-D365ODataEntityData -EntitySetName "SecurityUserRoleAssociations" -ODataQuery $query -Token $Global:D365FOToken -TraverseNextLink
        }
        else {
            $response = Get-D365ODataEntityData -EntitySetName "SecurityUserRoleAssociations" -Token $Global:D365FOToken -TraverseNextLink
        }
        
        return $response
    }
    catch {
        Write-Error "Unable to refresh/get Access Token. Ensure you have successfully configured your system and run Set-Globals."
        Write-Error $_
    }
}

Function New-D365FOSystemUser {

    <#
    
.Synopsis
Creates a new Dynamics 365 Front Office (FO) system user.

.Description
The New-D365FOSystemUser function creates a new Dynamics 365 Front Office (FO) system user using the OData REST API. It requires the following mandatory parameters: Company, NetworkDomain, UserName, UserID, and Alias. The function returns the response from the OData API.

.Parameter Company
(Mandatory) The company for the system user.

.Parameter NetworkDomain
(Mandatory) The network domain for the system user.

.Parameter UserName
(Mandatory) The user name for the system user.

.Parameter UserID
(Mandatory) The user ID for the system user.

.Parameter Alias
(Mandatory) The alias for the system user.

.Parameter Enabled
(Optional) The enabled status for the system user. The default value is 'True'.

.Inputs
None.

.Outputs
The response from the OData API as a PowerShell object.

.Example
$newUserDetails = New-D365FOSystemUser -Company "Contoso" -NetworkDomain "contoso.com" -UserName "johndoe" -UserID "johndoe@contoso.com" -Alias "jdoe"
Write-Output $newUserDetails

    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$Company,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$NetworkDomain,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$UserName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$UserID,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$Alias,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Enabled = 'True'
    )

    # Refresh Token
    $Global:D365FOToken = Get-D365ODataToken

    $newUserDetails = [pscustomobject][ordered]@{ 
        StartPage                 = 'DefaultDashboard' 
        UserInfo_language         = 'en-us'
        Company                   = $Company 
        ExternalUser              = 'False'
        UserName                  = $UserName
        NetworkDomain             = $NetworkDomain 
        Alias                     = $Alias 
        UserInfo_defaultPartition = 'True'
        AccountType               = 'ClaimsUser'
        Helplanguage              = 'en-us'
        UserID                    = $UserID 
        Enabled                   = $Enabled
    }

    try {
        $newUserResponse = Import-D365ODataEntityBatchMode -EntityName "SystemUsers" -Payload ($newUserDetails | ConvertTo-json) -RawOutput -token $Global:D365FOToken
        return $newUserResponse
    }
    catch {
        return $_ 
    }
}

Function New-D365FOSecurityRole {

    <#
    
.Synopsis
Creates a new Dynamics 365 Front Office (FO) system user.

.Description
The New-D365FOSystemUser function creates a new Dynamics 365 Front Office (FO) system user using the OData REST API. It requires the following mandatory parameters: Company, NetworkDomain, UserName, UserID, and Alias. The function returns the response from the OData API.

.Parameter SecurityRoleIdentifier   
The company for the system user.

.Parameter AccessToSensitiveData  
The company for the system user.

.Parameter Description            
The network domain for the system user.

.Parameter SecurityRoleName       
(Mandatory) The user name for the system user.

.Inputs
None.

.Outputs
The response from the OData API as a PowerShell object.

.Example
$newUserDetails = New-D365FOSystemUser -SecurityRoleName "new role" -AccessToSensitiveData $false -Description "new role description" 
Write-Output $newUserDetails

    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$SecurityRoleIdentifier,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$SecurityRoleName,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [boolean]$AccessToSensitiveData = $false,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Description
    )

    # Refresh Token
    $Global:D365FOToken = Get-D365ODataToken

    $newSecRoleDetails = [pscustomobject][ordered]@{ 
        SecurityRoleIdentifier = $SecurityRoleIdentifier 
        SecurityRoleName       = $SecurityRoleName
        AccessToSensitiveData  = $AccessToSensitiveData 
        Description            = $Description
    }

    try {
        $newSecRoleResponse = Import-D365ODataEntityBatchMode -EntityName "SecurityRoles" -Payload ($newSecRoleDetails | ConvertTo-json) -RawOutput -token $Global:D365FOToken
        return $newSecRoleResponse
    }
    catch {
        return $_ 
    }
}

<#
.SYNOPSIS
    .EXAMPLE

    PS> $updatePersonUser = [pscustomobject][ordered]@{ 
        Enabled = 'True'
    }
    PS> Update-SystemUser -UserID D365Tenant "yourtenant.onmicrosoft.com" -D365URI "https://yourtenant.cloudax.dynamics.com.onmicrosoft.com" -EntraIDAppClientID d55a2c66-727a-460d-ba91-56bd167ccdad -EntraIDAppClientSecret System.Security.SecureString
    
#>

function Update-D365FOSystemUser {

    <#
    
.Synopsis
Updates an existing Dynamics 365 Front Office (FO) system user.

.Description
The Update-D365FOSystemUser function updates an existing Dynamics 365 Front Office (FO) system user using the OData REST API. It requires a PSCustomObject containing the updated system user details as a mandatory parameter, along with the UserID to identify the user to be updated. The function returns the response from the OData API.

.Parameter Update
(Mandatory) A PSCustomObject containing the updated system user details. The PSCustomObject should have properties corresponding to the updated fields, such as Company, NetworkDomain, UserName, Alias, and Enabled.

.Parameter UserID
(Mandatory) The UserID of the system user to update.

.Inputs
None.

.Outputs
The response from the OData API as a PowerShell object.

.Example
$updateDetails = New-Object PSCustomObject -Property @{
    Company = "Contoso Consulting"
    Alias = "jdoe123"
}
$UserID = "johndoe@contoso.com"
$updateResponse = Update-D365FOSystemUser -Update $updateDetails -UserID $UserID
Write-Output $updateResponse
    
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [pscustomobject]$Update,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$UserID
    )

    # Refresh Token
    $Global:D365FOToken = Get-D365ODataToken

    $payload = $Update | ConvertTo-json
    $updates = @([PSCustomObject]@{Key = "UserID='$($UserID)'"; Payload = $payload })
    $updateResponse = Update-D365ODataEntityBatchMode -EntityName "SystemUsers" -Payload $updates -RawOutput -token $Global:D365FOToken
    return $updateResponse
}

function Update-D365FOSecurityRole {

    <#
    
.Synopsis
Updates an existing Dynamics 365 Front Office (FO) system user.

.Description
The Update-D365FOSystemUser function updates an existing Dynamics 365 Front Office (FO) system user using the OData REST API. It requires a PSCustomObject containing the updated system user details as a mandatory parameter, along with the UserID to identify the user to be updated. The function returns the response from the OData API.

.Parameter Update
(Mandatory) A PSCustomObject containing the updated system user details. The PSCustomObject should have properties corresponding to the updated fields, such as Company, NetworkDomain, UserName, Alias, and Enabled.

.Parameter UserID
(Mandatory) The UserID of the system user to update.

.Inputs
None.

.Outputs
The response from the OData API as a PowerShell object.

.Example
$updateDetails = New-Object PSCustomObject -Property @{
    Company = "Contoso Consulting"
    Alias = "jdoe123"
}
$UserID = "johndoe@contoso.com"
$updateResponse = Update-D365FOSystemUser -Update $updateDetails -UserID $UserID
Write-Output $updateResponse
    
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$SecurityRoleIdentifier,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$SecurityRoleName,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [boolean]$AccessToSensitiveData = $false,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Description
    )

    # Refresh Token
    $Global:D365FOToken = Get-D365ODataToken

    $newSecRoleDetails = @{}    

    if ($AccessToSensitiveData) {
        $newSecRoleDetails.AccessToSensitiveData = $AccessToSensitiveData
    }

    if ($Description) {
        $newSecRoleDetails.Description = $Description
    }        
    
    $updateResponse = Update-D365ODataEntity -EntityName "SecurityRoles" -Key "SecurityRoleIdentifier='$($SecurityRoleIdentifier)'" -Payload ($newSecRoleDetails | ConvertTo-json) -token $Global:D365FOToken
    return $updateResponse
}


Function Add-D365FORoleToSystemUser {

    <#
    
.Synopsis
Adds a security role to a Dynamics 365 Front Office (FO) system user.

.Description
The Add-D365FORoleToSystemUser function adds a security role to a Dynamics 365 Front Office (FO) system user using the OData REST API. It requires a PSCustomObject containing the role details as a mandatory parameter. The PSCustomObject should have the following properties:

.Parameter Role
(mandatory) PowerShell Object with all the Role details and the UserId of the account to be given the role. 

.Inputs
None.

.Outputs
The response from the OData API as a PowerShell object.

.Example
$addRole = [pscustomobject][ordered]@{ 
    UserId                 = 'darrenjrobinson'
    SecurityRoleIdentifier = 'HCMMANAGER'
    AssignmentStatus       = 'Enabled'
    AssignmentMode         = 'Manual'
    SecurityRoleName       = 'Manager'
}

Add-RoleToSystemUser -Role $addRole

    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [pscustomobject]$Role
    )

    if ($null -ne $Role.UserId -and $null -ne $Role.SecurityRoleIdentifier -and $null -ne $Role.AssignmentStatus -and $null -ne $Role.AssignmentMode -and $null -ne $Role.SecurityRoleName) {
        # Refresh Token
        $Global:D365FOToken = Get-D365ODataToken

        try {
            $addRoleResponse = Import-D365ODataEntityBatchMode -EntityName "SecurityUserRoleAssociations" -Payload ($Role | ConvertTo-json) -RawOutput -token $Global:D365FOToken
            return $addRoleResponse
        }
        catch {
            return Write-Error $_
        }
    }
    else {
        Write-Error "Role Object missing one or more of 'UserId', 'SecurityRoleIdentifier', 'AssignmentStatus', 'AssignmentMode','SecurityRoleName'. Update your Role object to include those attributes."
    }
}

Function Remove-D365FORoleFromSystemUser {

    <#
    
.Synopsis
Removes a security role from a Dynamics 365 Front Office (FO) system user.

.Description
The Remove-D365FORoleFromSystemUser function removes a security role from a Dynamics 365 Front Office (FO) system user using the OData REST API. It requires the SecurityRoleIdentifier of the role to remove and the UserId of the system user as mandatory parameters. The function returns the response from the OData API.

.Parameter SecurityRoleIdentifier
(Mandatory) The ID of the security role to remove.

.Parameter UserId
(Mandatory) The ID of the system user to remove the role from.

.Inputs
None.

.Outputs
The response from the OData API as a PowerShell object.

.Example
$SecurityRoleIdentifier = "12345678-90ab-cdef-1234-567890abcdef"
$UserId = "johndoe@contoso.com"
$removeRoleResponse = Remove-D365FORoleFromSystemUser -SecurityRoleIdentifier $SecurityRoleIdentifier -UserId $UserId
Write-Output $removeRoleResponse
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [pscustomobject]$SecurityRoleIdentifier,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [pscustomobject]$UserId
    )

    # Refresh Token
    $Global:D365FOToken = Get-D365ODataToken
    
    try {
        $removeRoleResponse = Remove-D365ODataEntityBatchMode -EntityName SecurityUserRoles -Key "UserId='$($UserId)',SecurityRoleIdentifier='$($SecurityRoleIdentifier)'" -RawOutput -Token $Global:D365FOToken
        return $removeRoleResponse
    }
    catch {
        return Write-Error $_
    }
}


# SIG # Begin signature block
# MIIoJQYJKoZIhvcNAQcCoIIoFjCCKBICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBidIxoDRIMrpKZ
# mlEgWPTP8N4eIiz5QmL5OsE6ettUvKCCISgwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXH
# JQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMf
# UBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w
# 1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRk
# tFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYb
# qMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUm
# cJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP6
# 5x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzK
# QtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo
# 80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjB
# Jgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXche
# MBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU
# 7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZI
# hvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd
# 4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiC
# qBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl
# /Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeC
# RK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYT
# gAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/
# a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37
# xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmL
# NriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0
# YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJ
# RyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIG
# sDCCBJigAwIBAgIQCK1AsmDSnEyfXs2pvZOu2TANBgkqhkiG9w0BAQwFADBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# HhcNMjEwNDI5MDAwMDAwWhcNMzYwNDI4MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1bQvQtAorXi3XdU5WRuxiEL1M4zr
# PYGXcMW7xIUmMJ+kjmjYXPXrNCQH4UtP03hD9BfXHtr50tVnGlJPDqFX/IiZwZHM
# gQM+TXAkZLON4gh9NH1MgFcSa0OamfLFOx/y78tHWhOmTLMBICXzENOLsvsI8Irg
# nQnAZaf6mIBJNYc9URnokCF4RS6hnyzhGMIazMXuk0lwQjKP+8bqHPNlaJGiTUyC
# EUhSaN4QvRRXXegYE2XFf7JPhSxIpFaENdb5LpyqABXRN/4aBpTCfMjqGzLmysL0
# p6MDDnSlrzm2q2AS4+jWufcx4dyt5Big2MEjR0ezoQ9uo6ttmAaDG7dqZy3SvUQa
# khCBj7A7CdfHmzJawv9qYFSLScGT7eG0XOBv6yb5jNWy+TgQ5urOkfW+0/tvk2E0
# XLyTRSiDNipmKF+wc86LJiUGsoPUXPYVGUztYuBeM/Lo6OwKp7ADK5GyNnm+960I
# HnWmZcy740hQ83eRGv7bUKJGyGFYmPV8AhY8gyitOYbs1LcNU9D4R+Z1MI3sMJN2
# FKZbS110YU0/EpF23r9Yy3IQKUHw1cVtJnZoEUETWJrcJisB9IlNWdt4z4FKPkBH
# X8mBUHOFECMhWWCKZFTBzCEa6DgZfGYczXg4RTCZT/9jT0y7qg0IU0F8WD1Hs/q2
# 7IwyCQLMbDwMVhECAwEAAaOCAVkwggFVMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYD
# VR0OBBYEFGg34Ou2O/hfEYb7/mF7CIhl9E5CMB8GA1UdIwQYMBaAFOzX44LScV1k
# TN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcD
# AzB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
# ZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0
# cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmww
# HAYDVR0gBBUwEzAHBgVngQwBAzAIBgZngQwBBAEwDQYJKoZIhvcNAQEMBQADggIB
# ADojRD2NCHbuj7w6mdNW4AIapfhINPMstuZ0ZveUcrEAyq9sMCcTEp6QRJ9L/Z6j
# fCbVN7w6XUhtldU/SfQnuxaBRVD9nL22heB2fjdxyyL3WqqQz/WTauPrINHVUHmI
# moqKwba9oUgYftzYgBoRGRjNYZmBVvbJ43bnxOQbX0P4PpT/djk9ntSZz0rdKOtf
# JqGVWEjVGv7XJz/9kNF2ht0csGBc8w2o7uCJob054ThO2m67Np375SFTWsPK6Wrx
# oj7bQ7gzyE84FJKZ9d3OVG3ZXQIUH0AzfAPilbLCIXVzUstG2MQ0HKKlS43Nb3Y3
# LIU/Gs4m6Ri+kAewQ3+ViCCCcPDMyu/9KTVcH4k4Vfc3iosJocsL6TEa/y4ZXDlx
# 4b6cpwoG1iZnt5LmTl/eeqxJzy6kdJKt2zyknIYf48FWGysj/4+16oh7cGvmoLr9
# Oj9FpsToFpFSi0HASIRLlk2rREDjjfAVKM7t8RhWByovEMQMCGQ8M4+uKIw8y4+I
# Cw2/O/TOHnuO77Xry7fwdxPm5yg/rBKupS8ibEH5glwVZsxsDsrFhsP2JjMMB0ug
# 0wcCampAMEhLNKhRILutG4UI4lkNbcoFUCvqShyepf2gpx8GdOfy1lKQ/a+FSCH5
# Vzu0nAPthkX0tGFuv2jiJmCG6sivqf6UHedjGzqGVnhOMIIGvDCCBKSgAwIBAgIQ
# C65mvFq6f5WHxvnpBOMzBDANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0
# ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTI0MDkyNjAw
# MDAwMFoXDTM1MTEyNTIzNTk1OVowQjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERp
# Z2lDZXJ0MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyNDCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAL5qc5/2lSGrljC6W23mWaO16P2RHxjE
# iDtqmeOlwf0KMCBDEr4IxHRGd7+L660x5XltSVhhK64zi9CeC9B6lUdXM0s71EOc
# Re8+CEJp+3R2O8oo76EO7o5tLuslxdr9Qq82aKcpA9O//X6QE+AcaU/byaCagLD/
# GLoUb35SfWHh43rOH3bpLEx7pZ7avVnpUVmPvkxT8c2a2yC0WMp8hMu60tZR0Cha
# V76Nhnj37DEYTX9ReNZ8hIOYe4jl7/r419CvEYVIrH6sN00yx49boUuumF9i2T8U
# uKGn9966fR5X6kgXj3o5WHhHVO+NBikDO0mlUh902wS/Eeh8F/UFaRp1z5SnROHw
# SJ+QQRZ1fisD8UTVDSupWJNstVkiqLq+ISTdEjJKGjVfIcsgA4l9cbk8Smlzddh4
# EfvFrpVNnes4c16Jidj5XiPVdsn5n10jxmGpxoMc6iPkoaDhi6JjHd5ibfdp5uzI
# Xp4P0wXkgNs+CO/CacBqU0R4k+8h6gYldp4FCMgrXdKWfM4N0u25OEAuEa3Jyidx
# W48jwBqIJqImd93NRxvd1aepSeNeREXAu2xUDEW8aqzFQDYmr9ZONuc2MhTMizch
# NULpUEoA6Vva7b1XCB+1rxvbKmLqfY/M/SdV6mwWTyeVy5Z/JkvMFpnQy5wR14GJ
# cv6dQ4aEKOX5AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/
# BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEE
# AjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8w
# HQYDVR0OBBYEFJ9XLAN3DigVkGalY17uT5IfdqBbMFoGA1UdHwRTMFEwT6BNoEuG
# SWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQw
# OTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKG
# TGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJT
# QTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIB
# AD2tHh92mVvjOIQSR9lDkfYR25tOCB3RKE/P09x7gUsmXqt40ouRl3lj+8QioVYq
# 3igpwrPvBmZdrlWBb0HvqT00nFSXgmUrDKNSQqGTdpjHsPy+LaalTW0qVjvUBhcH
# zBMutB6HzeledbDCzFzUy34VarPnvIWrqVogK0qM8gJhh/+qDEAIdO/KkYesLyTV
# OoJ4eTq7gj9UFAL1UruJKlTnCVaM2UeUUW/8z3fvjxhN6hdT98Vr2FYlCS7Mbb4H
# v5swO+aAXxWUm3WpByXtgVQxiBlTVYzqfLDbe9PpBKDBfk+rabTFDZXoUke7zPgt
# d7/fvWTlCs30VAGEsshJmLbJ6ZbQ/xll/HjO9JbNVekBv2Tgem+mLptR7yIrpaid
# RJXrI+UzB6vAlk/8a1u7cIqV0yef4uaZFORNekUgQHTqddmsPCEIYQP7xGxZBIhd
# mm4bhYsVA6G2WgNFYagLDBzpmk9104WQzYuVNsxyoVLObhx3RugaEGru+SojW4dH
# PoWrUhftNpFC5H7QEY7MhKRyrBe7ucykW7eaCuWBsBb4HOKRFVDcrZgdwaSIqMDi
# CLg4D+TPVgKx2EgEdeoHNHT9l3ZDBD+XgbF+23/zBjeCtxz+dL/9NWR6P2eZRi7z
# cEO1xwcdcqJsyz/JceENc2Sg8h3KeFUCS7tpFk7CrDqkMIIHbTCCBVWgAwIBAgIQ
# CcjsXDR9ByBZzKg16Kdv+DANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExMB4XDTIz
# MDMyOTAwMDAwMFoXDTI2MDYyMjIzNTk1OVowdTELMAkGA1UEBhMCQVUxGDAWBgNV
# BAgTD05ldyBTb3V0aCBXYWxlczEUMBIGA1UEBxMLQ2hlcnJ5YnJvb2sxGjAYBgNV
# BAoTEURhcnJlbiBKIFJvYmluc29uMRowGAYDVQQDExFEYXJyZW4gSiBSb2JpbnNv
# bjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMesp+e1UZ5doOnpL+ep
# m6Iq6GYiqK8ZNcz1XBe7M7eBXwVy4tYP5ByIa6NORYEselVWI9XmO1M+cPS6jRMr
# pZb9xtUH+NpKZO+eSthgTAtnEO1dWaAK6Y7AH/ZVjmgOTWZXBVibjAE/JQKIfZyx
# 4Hm5FOH6hq3bslA+RUQpo3NQxNv2AuzckKQwbW7AoXINudj0duYCiDYshn/9mHzz
# gL0VpNYRpmgEa7WWgc1JH17V+SYlaf6qMWpYoWuODwuDltSH2p57qAI2/4J6rUYE
# vns7QZ9sgIUdGlUr596fp0Y4juypyVGE7Rr0a8PtByLWUupyV7Z5kKPr/MRjerXA
# mBnf6AdhI3kY6Gjz356fZkPA49UuCIXFgyTZT84Ao6Klw+0RqJ70JDt449Uky7hd
# a+h8h2PiUdf7rXQamV57mY65+lHAmc4+UgTuWsnpwnTuNlkbZxRnCw2D+W3qto2a
# BhDebciKZzivfiAWlWfTcHtCpy96gM5L+OB45ezDpU6KAH1hwRSjORUlW5yoFTXU
# bPUBRflU3O2bZ0wdAJeyUYaHWAayNoyFfuKdrmCLtIx726O06dz9Kg+cJf+1ZdJ7
# KcUvZgR2d8F19FV5G1CVMnOzhMZR2dnIeJ5h0EgcOKNHl3hMKFdVRx4lhW8tcrQQ
# N4ZT2EgGfI9fBc0i3GXTFA0xAgMBAAGjggIDMIIB/zAfBgNVHSMEGDAWgBRoN+Dr
# tjv4XxGG+/5hewiIZfROQjAdBgNVHQ4EFgQUBTFWqXTuYnNp+d03es2KM9JdGUgw
# DgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMIG1BgNVHR8Ega0w
# gaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMFOgUaBPhk1o
# dHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2ln
# bmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDA+BgNVHSAENzA1MDMGBmeBDAEE
# ATApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgZQG
# CCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEu
# Y3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQADggIBAFhACWjPMrcafwDfZ5me
# /nUrkv4yYgIi535cddPAm/2swGDTuzSVBVHIMBp8LWLmzXPA1GbxBOmA4L8vvDgj
# EpQF9I9Ph5MNYgYhg0xSpAIp9/KAoc4OQnwlyRGPN+CjayY40xxTz4/hHohWg4rn
# JMIuVEjkMtKnMdTbpnqU85w78AQlfD79v/gWQ2dL1T3n18HOEjTt8VSurxkEhQ5I
# 3SH8Cr9YhUv94ObWIUbOKUt5SG7m/d+y2mfkKRSOmRluLSoYLPWbx35pArsYkaPp
# jf5Yl5jiJPY3GQzEU/SRVW0rrwDAbtKSN0gKWtZxijPDbs8aQUYCijFfje6OWGF4
# RnmPSQh0Ff8AyzPQcx9LjQ/8W7gUELsE6IFuXP5bj2i6geLy65LRe46QZlYDq/bM
# azUoZQTlje/hs6pkOL4f1Kv7tbJZmMENVVURJNmeDRejvNliHaaGEAv/iF0Zo7pq
# vj4wCCCGG3j/sNR5WSRYnxf5xQ4r9i9gZqk4yjwk/DJCW2rmKNCUoxNIZWh2EIlM
# SDzw3DMKk2ylZdiY/LAi5GmbCyGLt6sTz/IE1w1NYwrp/z6v4I91lDgdXg+fTkhh
# xt47hWmjMOD3ZYVSFzQmg8al1iQ/+6RYKgfsww64tIky8JOOZX/3ss/uhxKUjPJx
# YJkOwQwUyoAYzjcu/AE7By0rMYIGUzCCBk8CAQEwfTBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExAhAJyOxc
# NH0HIFnMqDXop2/4MA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPTI0cxE2DCCGve4MGWj
# hXSwa+L18yLHbqkSoqk6PQsdMA0GCSqGSIb3DQEBAQUABIICAL+xMqlK6AAsO5Rq
# 3bn+SeFI3BS9qC1x3s/UjfQUFzvfLtiNPP4IuQf1tYBeK6fXEiQ590lmMaRdrB5P
# ehAH6Lpdq252cDW2Q708juD9Rxr4lGskbvIlmg77ei9HfuLXrTGWPO8iJ7ZT44oe
# ng8zjURYmbhadazupE/zKVlaTjTFFc5I/DK4FNAXNL2QUy/GyiW+4C6o26qbYP2I
# kvAitj+6LwEwWRqyI8WhTlu3vnyNsv24FnAy770RLX6OXVTClkQizlYHDGxA7Dsh
# 8fanohncymSd80pjOwK1Bbpml+biFQkYn5YlQAqibd1bYhY88SRSOpCfSA4IcSP0
# kPwgqJzv1iqE+nT1hEMvE0oxEP/1JiYy7pvisz+pBRzjWLDENHpdJ8ZCOoHr03Ur
# 0u8DfG3Tg/qgAyYCdSlyH2Yu/iRlk3EmfgaXYNozH7PaRiUXmbQEo1GhEcKlGVWH
# K5S0exMzLp7WJYvtcjIslGkKhbJ1AzD7yWbWEK8DDBtIjo48ZIieHAn0vjHsR0qu
# Hhu7gKkEpWMPip/s8l3wKJy/2/Vl9TVBZG2d7CdQ0SsGyBTAPZkwpf5fZTPKa1A6
# SQcZbG3dv5pHI4D5B39LdEu3ZUs4Y4hJP4iWql6J9omHE2OqhNXDPH4M1BWWgi7n
# 3IzU9jBzjjyOtVV34rvxG/tWlnLAoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJ
# AgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTsw
# OQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVT
# dGFtcGluZyBDQQIQC65mvFq6f5WHxvnpBOMzBDANBglghkgBZQMEAgEFAKBpMBgG
# CSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI1MDMxODA3
# MTMxNlowLwYJKoZIhvcNAQkEMSIEIGynIRMI8Xu80nAkUQFArwzr+Xb4nJ6cW7lx
# t13Fqg76MA0GCSqGSIb3DQEBAQUABIICAG1JEob74qSyq/85Mu1vBbjLiZwC1MZQ
# erSCqvZzIOfvOIi8tv3QAyoa/Iw1Bne034Hrm6S0sTUYiBVMPb22NkeE6gHnCDn7
# +kwXy+h3G6wRZmzEZ9SSIfwU1QHSd9nDaeDBMoVVT3kELVZ9exK99mUgE52jc1lU
# mRN64oAM1R91LGrq/vZl4BI3+ljDgBeoUS0wwxpEKrWsw+AuFWbpkOtUIvqm0CQr
# ZeZ4rg584oOb6D4X6oRZvR9Kyb2PpCa6BZff8iqQUi4YA2/cTOOcjcLzRnxtN3LL
# f5VsZ/Et34u45OUNmXKmnX99CbsKQaoqPSwKeFyVOuakcI5rIpWlglSZNI8ieHKb
# nJ8upYeUapULS3vDhvkNwGOZE5xXqE1Tf909pw3ii3nWFM1M3hVTvaSEEIROEhhT
# KT4IyisRtYVuLBtm6gmRfFRZklD1+rUuL79Zr1c1T01obdwoQOLIW3iuDgqmZBt0
# fsM0pzJbFqVcSXqEalLZ9CnEoG4q3usi7T49PVDIzwWMteBbaVSKxbckj0qWY3Uu
# lS6QlTTCir+eiZezLiQ2bGJ0Vl6XC4z0ddOWyxkc5xlDVulZc+6PQX5WnkCNPsLK
# LWeqgWRjwq/djWHLSLYpOaBQ4GFs+qaIoOMNKX1FcW0aoF2RnGz5aFWeagr+uK9g
# 5h2hvxc2leAv
# SIG # End signature block
