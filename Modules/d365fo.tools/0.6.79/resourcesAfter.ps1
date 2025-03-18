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

# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBIZFoK0wGZVcQ4
# KtY4Sh/FzudwyNSfHczKkpmgmdcDr6CCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# Vzu0nAPthkX0tGFuv2jiJmCG6sivqf6UHedjGzqGVnhOMIIGwjCCBKqgAwIBAgIQ
# BUSv85SdCDmmv9s/X+VhFjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0
# ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIzMDcxNDAw
# MDAwMFoXDTM0MTAxMzIzNTk1OVowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRp
# Z2lDZXJ0LCBJbmMuMSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMzCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKNTRYcdg45brD5UsyPgz5/X
# 5dLnXaEOCdwvSKOXejsqnGfcYhVYwamTEafNqrJq3RApih5iY2nTWJw1cb86l+uU
# UI8cIOrHmjsvlmbjaedp/lvD1isgHMGXlLSlUIHyz8sHpjBoyoNC2vx/CSSUpIIa
# 2mq62DvKXd4ZGIX7ReoNYWyd/nFexAaaPPDFLnkPG2ZS48jWPl/aQ9OE9dDH9kgt
# XkV1lnX+3RChG4PBuOZSlbVH13gpOWvgeFmX40QrStWVzu8IF+qCZE3/I+PKhu60
# pCFkcOvV5aDaY7Mu6QXuqvYk9R28mxyyt1/f8O52fTGZZUdVnUokL6wrl76f5P17
# cz4y7lI0+9S769SgLDSb495uZBkHNwGRDxy1Uc2qTGaDiGhiu7xBG3gZbeTZD+BY
# QfvYsSzhUa+0rRUGFOpiCBPTaR58ZE2dD9/O0V6MqqtQFcmzyrzXxDtoRKOlO0L9
# c33u3Qr/eTQQfqZcClhMAD6FaXXHg2TWdc2PEnZWpST618RrIbroHzSYLzrqawGw
# 9/sqhux7UjipmAmhcbJsca8+uG+W1eEQE/5hRwqM/vC2x9XH3mwk8L9CgsqgcT2c
# kpMEtGlwJw1Pt7U20clfCKRwo+wK8REuZODLIivK8SgTIUlRfgZm0zu++uuRONhR
# B8qUt+JQofM604qDy0B7AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYD
# VR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgG
# BmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxq
# II+eyG8wHQYDVR0OBBYEFKW27xPn783QZKHVVqllMaPe1eNJMFoGA1UdHwRTMFEw
# T6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRH
# NFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGD
# MIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYB
# BQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQEL
# BQADggIBAIEa1t6gqbWYF7xwjU+KPGic2CX/yyzkzepdIpLsjCICqbjPgKjZ5+PF
# 7SaCinEvGN1Ott5s1+FgnCvt7T1IjrhrunxdvcJhN2hJd6PrkKoS1yeF844ektrC
# QDifXcigLiV4JZ0qBXqEKZi2V3mP2yZWK7Dzp703DNiYdk9WuVLCtp04qYHnbUFc
# jGnRuSvExnvPnPp44pMadqJpddNQ5EQSviANnqlE0PjlSXcIWiHFtM+YlRpUurm8
# wWkZus8W8oM3NG6wQSbd3lqXTzON1I13fXVFoaVYJmoDRd7ZULVQjK9WvUzF4UbF
# KNOt50MAcN7MmJ4ZiQPq1JE3701S88lgIcRWR+3aEUuMMsOI5ljitts++V+wQtaP
# 4xeR0arAVeOGv6wnLEHQmjNKqDbUuXKWfpd5OEhfysLcPTLfddY2Z1qJ+Panx+VP
# NTwAvb6cKmx5AdzaROY63jg7B145WPR8czFVoIARyxQMfq68/qTreWWqaNYiyjvr
# moI1VygWy2nyMpqy0tg6uLFGhmu6F/3Ed2wVbK6rr3M66ElGt9V/zLY4wNjsHPW2
# obhDLN9OTH0eaHDAdwrUAuBcYLso/zjlUlrWrBciI0707NMX+1Br/wd3H3GXREHJ
# uEbTbDJ8WC9nR2XlG3O2mflrLAZG70Ee8PBf4NvZrZCARK+AEEGKMIIHbTCCBVWg
# AwIBAgIQCcjsXDR9ByBZzKg16Kdv+DANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0
# IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0Ex
# MB4XDTIzMDMyOTAwMDAwMFoXDTI2MDYyMjIzNTk1OVowdTELMAkGA1UEBhMCQVUx
# GDAWBgNVBAgTD05ldyBTb3V0aCBXYWxlczEUMBIGA1UEBxMLQ2hlcnJ5YnJvb2sx
# GjAYBgNVBAoTEURhcnJlbiBKIFJvYmluc29uMRowGAYDVQQDExFEYXJyZW4gSiBS
# b2JpbnNvbjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMesp+e1UZ5d
# oOnpL+epm6Iq6GYiqK8ZNcz1XBe7M7eBXwVy4tYP5ByIa6NORYEselVWI9XmO1M+
# cPS6jRMrpZb9xtUH+NpKZO+eSthgTAtnEO1dWaAK6Y7AH/ZVjmgOTWZXBVibjAE/
# JQKIfZyx4Hm5FOH6hq3bslA+RUQpo3NQxNv2AuzckKQwbW7AoXINudj0duYCiDYs
# hn/9mHzzgL0VpNYRpmgEa7WWgc1JH17V+SYlaf6qMWpYoWuODwuDltSH2p57qAI2
# /4J6rUYEvns7QZ9sgIUdGlUr596fp0Y4juypyVGE7Rr0a8PtByLWUupyV7Z5kKPr
# /MRjerXAmBnf6AdhI3kY6Gjz356fZkPA49UuCIXFgyTZT84Ao6Klw+0RqJ70JDt4
# 49Uky7hda+h8h2PiUdf7rXQamV57mY65+lHAmc4+UgTuWsnpwnTuNlkbZxRnCw2D
# +W3qto2aBhDebciKZzivfiAWlWfTcHtCpy96gM5L+OB45ezDpU6KAH1hwRSjORUl
# W5yoFTXUbPUBRflU3O2bZ0wdAJeyUYaHWAayNoyFfuKdrmCLtIx726O06dz9Kg+c
# Jf+1ZdJ7KcUvZgR2d8F19FV5G1CVMnOzhMZR2dnIeJ5h0EgcOKNHl3hMKFdVRx4l
# hW8tcrQQN4ZT2EgGfI9fBc0i3GXTFA0xAgMBAAGjggIDMIIB/zAfBgNVHSMEGDAW
# gBRoN+Drtjv4XxGG+/5hewiIZfROQjAdBgNVHQ4EFgQUBTFWqXTuYnNp+d03es2K
# M9JdGUgwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMIG1BgNV
# HR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMFOg
# UaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRD
# b2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDA+BgNVHSAENzA1MDMG
# BmeBDAEEATApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9D
# UFMwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIw
# MjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQADggIBAFhACWjPMrca
# fwDfZ5me/nUrkv4yYgIi535cddPAm/2swGDTuzSVBVHIMBp8LWLmzXPA1GbxBOmA
# 4L8vvDgjEpQF9I9Ph5MNYgYhg0xSpAIp9/KAoc4OQnwlyRGPN+CjayY40xxTz4/h
# HohWg4rnJMIuVEjkMtKnMdTbpnqU85w78AQlfD79v/gWQ2dL1T3n18HOEjTt8VSu
# rxkEhQ5I3SH8Cr9YhUv94ObWIUbOKUt5SG7m/d+y2mfkKRSOmRluLSoYLPWbx35p
# ArsYkaPpjf5Yl5jiJPY3GQzEU/SRVW0rrwDAbtKSN0gKWtZxijPDbs8aQUYCijFf
# je6OWGF4RnmPSQh0Ff8AyzPQcx9LjQ/8W7gUELsE6IFuXP5bj2i6geLy65LRe46Q
# ZlYDq/bMazUoZQTlje/hs6pkOL4f1Kv7tbJZmMENVVURJNmeDRejvNliHaaGEAv/
# iF0Zo7pqvj4wCCCGG3j/sNR5WSRYnxf5xQ4r9i9gZqk4yjwk/DJCW2rmKNCUoxNI
# ZWh2EIlMSDzw3DMKk2ylZdiY/LAi5GmbCyGLt6sTz/IE1w1NYwrp/z6v4I91lDgd
# Xg+fTkhhxt47hWmjMOD3ZYVSFzQmg8al1iQ/+6RYKgfsww64tIky8JOOZX/3ss/u
# hxKUjPJxYJkOwQwUyoAYzjcu/AE7By0rMYIGUzCCBk8CAQEwfTBpMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0
# IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0Ex
# AhAJyOxcNH0HIFnMqDXop2/4MA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcC
# AQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYB
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOwKeeLJppkD
# Y99GnF8IM+acO/cxmiWqy70Ub/OCb6qZMA0GCSqGSIb3DQEBAQUABIICAC+xlIqB
# tUjYxk7Ae51Hqs+Mp7D9kqIsKVkpRKvZ1SgH5ICCZiV4Vq1CJXwb4LugUU9j23gu
# teG4afxrcUjRxgtelLgP69tP8gfzPj3xGZMnu/SBKLWOyCsq3yyFIXL26VWJUd72
# O4bWjxPxoSIsH6w1IbvL1cnj4Wca7V0nKaEW8pKjzBWPku93PTFEaOPdLWGmZkHt
# o71BjWhtUNJxkGY7GgUmz0XkXqwFs0pBUYmwW43/aG4HgndmIOU1BqXK6HELKSzc
# /BnhAxUyDMhqsk2Q5+bGkn2gDOj3I3Ny2NdrJFyE798PcdJxkkmU/EO9z5Zz5JUY
# nPs5Z8VULxYr2bE80Iu/53D9B/ZG9NB6mvqLeMVJSbmwBCh7hiKQzytDja1zRvPA
# jmm+x5Rq+fCRd5j9qoGikWW+ugVzPGDMcjczymzPmtUJ+V7Ux4+N/XVVXMqGW4Qt
# lLsT4eUZ+SWD1g5O1OQRbkL+L2OEhjz7ordOffwRf3bRWtnllOEKJ/OzCOFLtWST
# CdgVURNEByPnMj4YCzVqZz2Wq7p7bhpJxZQI8wwnniWwON3VdsUxjtr0CsqW7xwz
# qlXcwn0rhOnLB3UxJffgbT+zYKMO/dR8GjmXJLzAHuTX3uvFCGsvNnldRO+rzVwV
# d9b0framMEM9gfY5JN68PLi6p14J7tLoLrdpoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMzIxOFowLwYJKoZIhvcNAQkEMSIEIAqjtPniF9JjUhBshSGIB5+j0C65
# N834gSIf3pNbzW2yMA0GCSqGSIb3DQEBAQUABIICAFO3Drs0OjzPlm7eMcQcUr3H
# Kiil6fAKjBiqCbEcWA6oLau3YWbmGjg6fqq2Db8jbkzAym3XeRnhZJ3YaVzQ3LZt
# DJvcZLfVEsb/gPV8OnUapjDC6nzH5knEH2TPdyorxWP8tGQXSx8Ez6ePG7Eiflty
# H09yQF+LYWyKYQuVvDCmeaJeW37Xj3E9lX4cD4nmZ/4uqYDW3Qk1rhQ/P2Z69vrp
# m9r1WuDwNGwcoJ9tNSRJBJaOCQMq13h6mgwlUQZvxSQ76dXR/mTHwUfIiTboTdRo
# iR3w/hpHLRpygmeKLLLYBaYCqrOy/i5zFi8dsaI/VLowrUfoEj7ykxHLqv9n9pk5
# phufe4JsupQP1l0jLjKNEcJYvhq6rMwJMaed2Vjz/y3mOW6AM3snwphHWI8++udl
# sWh4gZGvLuOuYeWPW2MM2U2vZ+1cxFFM7L9u8CbxtOh2shO2wuVrr9MaL6SUTu9g
# Ouab2lxEPS6Nh70Mgnx0adaZzNR9Q4f3Fm6Hg074tLb07EKoU98of9Agla2k6nQi
# G/nJrEcrmm11Cflbpj5Xy1UD/WoneDRJpwcRhpZOHR3a8KskkP+sygEFDLIIlgdY
# 9h562ii3+LhYY8iqZk2nDQD3BtX1p8OOT7nuboo2YLpGXj2MUr69j8ERPJ7Afqh5
# iEtVogzd6X8LLZ4vIDUL
# SIG # End signature block
