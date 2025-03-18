<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'd365fo.tools' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'd365fo.tools' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'd365fo.tools' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

Set-PSFConfig -FullName "d365fo.tools.workstation.mode" -Value $false -Initialize -Description "Setting to assist the module to grab the URL from configuration rather from the non existing dll files."

Set-PSFConfig -FullName "d365fo.tools.azure.storage.accounts" -Value @{} -Initialize -Description "Object that stores different Azure Storage Account and their details."
Set-PSFConfig -FullName "d365fo.tools.active.azure.storage.account" -Value @{} -Initialize -Description "Object that stores the Azure Storage Account details that should be used during the module."
Set-PSFConfig -FullName "d365fo.tools.active.logic.app" -Value @{} -Initialize -Description "Object that stores the Azure Logic App details that should be used during the module."

Set-PSFConfig -FullName "d365fo.tools.lcs.projectid" -Value "" -Initialize -Description "Project number for the specific LCS project that you want to upload to."
Set-PSFConfig -FullName "d365fo.tools.lcs.clientid" -Value "" -Initialize -Description "Client Id of the Azure Registered App that you configured to be able to use the API of LCS."
Set-PSFConfig -FullName "d365fo.tools.lcs.lcsapiuri" -Value "" -Initialize -Description "URI / URL for the LCS API."
Set-PSFConfig -FullName "d365fo.tools.lcs.activetokenexpireson" -Value "" -Initialize -Description "The time when the currently stored bearer token will expire. Measured in seconds from 1970-01-01 (UnixTime)."
Set-PSFConfig -FullName "d365fo.tools.lcs.bearertoken" -Value "" -Initialize -Description "The bearer token used to authenticate / authorize against LCS when you want to upload files."
Set-PSFConfig -FullName "d365fo.tools.lcs.refreshtoken" -Value "" -Initialize -Description "The refresh token, that can be used to obtain a new bearer token from Azure Active Directory."

Set-PSFConfig -FullName "d365fo.tools.active.broadcast.message.config.name" -Value "" -Initialize -Description "Name of the broadcast message configuration that should be the default / active configuration for the module."

Set-PSFConfig -FullName "d365fo.tools.path.sqlpackage" -Value "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\SqlPackage.exe" -Initialize -Description "Path to the default location where SqlPackage.exe is located."

Set-PSFConfig -FullName "d365fo.tools.azure.common.oauth.token" -Value "https://login.microsoftonline.com/common/oauth2/token" -Initialize -Description "URI / URL for the Azure Active Directory OAuth 2.0 endpoint for tokens"

Set-PSFConfig -FullName "d365fo.tools.path.rsat" -Value "C:\Program Files (x86)\Regression Suite Automation Tool" -Initialize -Description "Path to the default location where RSAT is located."

Set-PSFConfig -FullName "d365fo.tools.path.rsatplayback" -Value "C:\Users\$($env:UserName)\AppData\Roaming\regressionTool\playback" -Initialize -Description "Path to the playback output location where RSAT is writing all the output values."

Set-PSFConfig -FullName "d365fo.tools.path.azcopy" -Value "C:\temp\d365fo.tools\AzCopy\AzCopy.exe" -Initialize -Description "Path to the default location where AzCopy.exe is located."

Set-PSFConfig -FullName "d365fo.tools.path.nuget" -Value "C:\temp\d365fo.tools\nuget\nuget.exe" -Initialize -Description "Path to the default location where nuget.exe is located."


$scriptBlock = { (Get-NetEventProvider -ShowInstalled | Where-Object name -like "Microsoft-Dynamics*" | Sort-Object Name).Name }

Register-PSFTeppScriptblock -Name "d365fo.tools.event.trace.providers" -ScriptBlock $scriptBlock -Mode Simple

Register-PSFTeppScriptblock -Name "d365fo.tools.event.trace.format.options" -ScriptBlock { 'bin', 'bincirc', 'csv', 'sql', 'tsv' }



<#
# Example:
Register-PSFTeppScriptblock -Name "d365fo.tools.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

<#
"options": {
    "1": "Model",
    "4": "Process Data Package",
    "10": "Software Deployable Package",
    "12": "GER Configuration",
    "15": "Data Package",
    "19": "PowerBI Report Model"
}
#>
Register-PSFTeppScriptblock -Name "d365fo.tools.lcs.options" -ScriptBlock { [LcsAssetFileType]::Model, [LcsAssetFileType]::ProcessDataPackage, [LcsAssetFileType]::SoftwareDeployablePackage, [LcsAssetFileType]::GERConfiguration, [LcsAssetFileType]::DataPackage, [LcsAssetFileType]::PowerBIReportModel, [LcsAssetFileType]::ECommercePackage, [LcsAssetFileType]::NuGetPackage, [LcsAssetFileType]::RetailSelfServicePackage, [LcsAssetFileType]::CommerceCloudScaleUnitExtension }


<#
[ValidateSet("https://lcsapi.lcs.dynamics.com", "https://lcsapi.eu.lcs.dynamics.com")]
#>
Register-PSFTeppScriptblock -Name "d365fo.tools.lcs.api.urls" -ScriptBlock { 'https://lcsapi.lcs.dynamics.com', 'https://lcsapi.eu.lcs.dynamics.com', 'https://lcsapi.fr.lcs.dynamics.com', 'https://lcsapi.sa.lcs.dynamics.com', 'https://lcsapi.uae.lcs.dynamics.com', 'https://lcsapi.ch.lcs.dynamics.com', 'https://lcsapi.no.lcs.dynamics.com', 'https://lcsapi.lcs.dynamics.cn', 'https://lcsapi.gov.lcs.microsoftdynamics.us' }



<#
# Example:
Register-PSFTeppScriptblock -Name "d365fo.tools.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

# Register-PSFTeppScriptblock -Name "d365fo.tools.timezones" -ScriptBlock { [System.TimeZoneInfo]::GetSystemTimeZones().Id }


Register-PSFTeppScriptblock -Name "d365fo.tools.timezones" -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
	
    [System.TimeZoneInfo]::GetSystemTimeZones() | Where-Object {$PSItem.DisplayName -match $wordToComplete} | ForEach-Object {
        $CompletionText = '"{0} - [{1}]"' -f $PSItem.DisplayName, $PSItem.StandardName
	
        New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @($CompletionText)
    }
}

<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name d365fo.tools.alcohol
#>

#File Options
Register-PSFTeppArgumentCompleter -Command Invoke-D365LcsUpload -Parameter FileType -Name d365fo.tools.lcs.options
Register-PSFTeppArgumentCompleter -Command Get-D365LcsAssetFile -Parameter FileType -Name d365fo.tools.lcs.options

#LCS API URLS
Register-PSFTeppArgumentCompleter -Command Get-D365LcsApiToken -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Get-D365LcsAssetFile -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Get-D365LcsAssetValidationStatus -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Get-D365LcsDatabaseBackups -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Get-D365LcsDatabaseOperationStatus -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Get-D365LcsDeploymentStatus -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls


Register-PSFTeppArgumentCompleter -Command Invoke-D365LcsDatabaseExport -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Invoke-D365LcsDatabaseRefresh -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Invoke-D365LcsDeployment -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Invoke-D365LcsEnvironmentStart -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Invoke-D365LcsEnvironmentStop -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls
Register-PSFTeppArgumentCompleter -Command Invoke-D365LcsUpload -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls

Register-PSFTeppArgumentCompleter -Command Set-D365LcsApiConfig -Parameter LcsApiUri -Name d365fo.tools.lcs.api.urls

#TimeZones
Register-PSFTeppArgumentCompleter -Command Send-D365BroadcastMessage -Parameter TimeZone -Name d365fo.tools.timezones
Register-PSFTeppArgumentCompleter -Command Add-D365BroadcastMessageConfig -Parameter TimeZone -Name d365fo.tools.timezones

#Event Trace
Register-PSFTeppArgumentCompleter -Command Start-D365EventTrace -Parameter ProviderName -Name d365fo.tools.event.trace.providers
Register-PSFTeppArgumentCompleter -Command Start-D365EventTrace -Parameter OutputFormat -Name d365fo.tools.event.trace.format.options


New-PSFLicense -Product 'd365fo.tools' -Manufacturer 'Motz' -ProductVersion $script:ModuleVersion -ProductType Module -Name MIT -Version "1.0.0.0" -Date (Get-Date "2018-09-20") -Text @"
Copyright (c) 2018 Motz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@

$Script:TimeSignals = @{ }

Write-PSFMessage -Level Verbose -Message "Gathering all variables to assist the different cmdlets to function"

$serviceDrive = ($env:ServiceDrive) -replace " ", ""

# When a local Tier1 machine is domain joined, the domain users will not have the %ServiceDrive% environment variable
if ([system.string]::IsNullOrEmpty($serviceDrive)) {
    $serviceDrive = "c:"

    Write-PSFMessage -Level Host -Message "Unable to locate the %ServiceDrive% environment variable. It could indicate that the machine is either not configured with D365FO or that you have domain joined a local Tier1. We have defaulted to <c='em'>c:\</c>"
    Write-PSFMessage -Level Host -Message "This message will show every time you load the module. If you want to silence this message, please add the ServiceDrive environment variable by executing this command (remember to restart the console afterwards):"
    Write-PSFHostColor -String '<c="em">[Environment]::SetEnvironmentVariable("ServiceDrive", "C:", "Machine")</c>'
}

$script:ServiceDrive = $serviceDrive

$Script:IsAdminRuntime = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$Script:WebConfig = "web.config"

$Script:DevConfig = "DynamicsDevConfig.xml"

$Script:WifServicesConfig = "wif.services.config"

$Script:Hosts = 'C:\Windows\System32\drivers\etc\hosts'

$Script:DefaultAOSName = 'usnconeboxax1aos'

$Script:IISHostFile = 'C:\Windows\System32\inetsrv\Config\applicationHost.config'

$Script:MRConfigFile = 'C:\FinancialReporting\Server\ApplicationService\bin\MRServiceHost.settings.config'

#Update all module variables
Update-ModuleVariables

$environment = Get-ApplicationEnvironment

$Script:AOSPath = $environment.Aos.AppRoot

$dataAccess = $environment.DataAccess

$Script:DatabaseServer = $dataAccess.DbServer

$Script:DatabaseName = $dataAccess.Database

$Script:BinDir = $environment.Common.BinDir

$Script:PackageDirectory = $environment.Aos.PackageDirectory

$Script:MetaDataDir = $environment.Aos.MetadataDirectory

$Script:BinDirTools = $environment.Common.DevToolsBinDir

$Script:ServerRole = [ServerRole]::Unknown
$RoleVaule = $(If ($environment.Monitoring.MARole -eq "" -or $environment.Monitoring.MARole -eq "dev") { "Development" } Else { $environment.Monitoring.MARole })

if ($null -ne $RoleVaule) {
    $Script:ServerRole = [ServerRole][Enum]::Parse([type]"ServerRole", $RoleVaule, $true);
}

$Script:EnvironmentType = [EnvironmentType]::Unknown
$Script:CanUseTrustedConnection = $false
if ($environment.Infrastructure.HostName -like "*cloud.onebox.dynamics.com*") {
    $Script:EnvironmentType = [EnvironmentType]::LocalHostedTier1
    $Script:CanUseTrustedConnection = $true
}
elseif ($environment.Infrastructure.HostName -like "*cloudax.dynamics.com*") {
    $Script:EnvironmentType = [EnvironmentType]::AzureHostedTier1
    $Script:CanUseTrustedConnection = $true
}
elseif ($environment.Infrastructure.HostName -like "*sandbox.ax.dynamics.com*") {
    $Script:EnvironmentType = [EnvironmentType]::MSHostedTier1
    $Script:CanUseTrustedConnection = $true
}
elseif ($environment.Infrastructure.HostName -like "*sandbox.operations.dynamics.com*") {
    $Script:EnvironmentType = [EnvironmentType]::MSHostedTier2
}

$Script:Url = $environment.Infrastructure.HostUrl
$Script:DatabaseUserName = $dataAccess.SqlUser
$Script:DatabaseUserPassword = $dataAccess.SqlPwd
$Script:Company = "DAT"

$Script:IsOnebox = $environment.Common.IsOneboxEnvironment

$RegSplat = @{
    Path = "HKLM:\SOFTWARE\Microsoft\Dynamics\Deployment\"
    Name = "InstallationInfoDirectory"
}

$RegValue = $( if (Test-RegistryValue @RegSplat) { Join-Path (Get-ItemPropertyValue @RegSplat) "InstallationRecords" } else { "" } )
$Script:InstallationRecordsDir = $RegValue

$Script:UserIsAdmin = $env:UserName -like "*admin*"

$Script:TfDir = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\"

$Script:SQLTools = "C:\Program Files (x86)\Microsoft SQL Server\130\Tools\Binn"

$Script:SSRSTools = "C:\Program Files\Microsoft SQL Server Reporting Services\Shared Tools"

$Script:DefaultTempPath = "c:\temp\d365fo.tools"

foreach ($item in (Get-PSFConfig -FullName d365fo.tools.active*)) {
    $nameTemp = $item.FullName -replace "^d365fo.tools.", ""
    $name = ($nameTemp -Split "\." | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) } ) -Join ""
    
    New-Variable -Name $name -Value $item.Value -Scope Script
}

#Active LCS Upload config extraction
Update-LcsApiVariables

$maskOutput = @(
    "AccessToken",
    "AzureStorageAccessToken",
    "Token",
    "BearerToken",
    "Password",
    "RefreshToken",
    "SAS"
    "AzureStorageSAS"
)

#Active broadcast message config extraction
Update-BroadcastVariables

#Update different PSF Configuration variables values
Update-PsfConfigVariables

#Active Azure Storage Configuration variables values
Update-AzureStorageVariables

(Get-Variable -Scope Script) | ForEach-Object {
    $val = $null

    if ($maskOutput -contains $($_.Name)) {
        $val = "The variable was found - [...REDACTED...]"
    }
    else {
        $val = $($_.Value)
    }
   
    Write-PSFMessage -Level Verbose -Message "$($_.Name) - $val" -Target $val -FunctionName "Variables.ps1"
}

Write-PSFMessage -Level Verbose -Message "Finished outputting all the variable content."

# Add the System.Web type
Add-Type -AssemblyName System.Web

# Add the System.Net.Http type
Add-Type -AssemblyName System.Net.Http

# Add the System.IO.Compression type
Add-Type -AssemblyName System.IO.Compression

# Add the System.IO.Compression.FileSystem type
Add-Type -AssemblyName System.IO.Compression.FileSystem
