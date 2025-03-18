@{
	# Script module or binary module file associated with this manifest
	RootModule        = 'd365fo.tools.psm1'

	# Version number of this module.
	ModuleVersion     = '0.6.79'

	# ID used to uniquely identify this module
	GUID              = '7c7b26d4-f764-4cb0-a692-459a0a689dbb'

	# Author of this module
	Author            = 'Mötz Jensen & Rasmus Andersen'

	# Company or vendor of this module
	CompanyName       = 'Essence Solutions'

	# Copyright statement for this module
	Copyright         = '(c) 2018 Mötz Jensen & Rasmus Andersen. All rights reserved.'

	# Description of the functionality provided by this module
	Description       = 'A set of tools that will assist you when working with Dynamics 365 Finance & Operations development / demo machines.'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'
	
	# Modules that must be imported into the global environment prior to importing
	# this module.
	# To enable the GitHub dependency graph, changes should be synchronized with
	# https://github.com/d365collaborative/d365fo.tools/blob/master/.github/workflows/dependencies.yml
	RequiredModules   = @(
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.0.12' }
		, @{ ModuleName = 'Azure.Storage'; ModuleVersion = '4.4.0' }
		, @{ ModuleName = 'AzureAd'; ModuleVersion = '2.0.1.16' }
		, @{ ModuleName = 'PSNotification'; ModuleVersion = '0.5.3' }
		, @{ ModuleName = 'PSOAuthHelper'; ModuleVersion = '0.3.0' }
		, @{ ModuleName = 'ImportExcel'; ModuleVersion = '7.1.0' }
	)
	

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\d365fo.tools.dll')

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\d365fo.tools.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess  = @('xml\d365fo.tools.Format.ps1xml')

	# Functions to export from this module
	FunctionsToExport = @(
		'Add-D365AzureStorageConfig',
		'Add-D365BroadcastMessageConfig',
		'Add-D365ModuleToRemove',
		'Add-D365RsatWifConfigAuthorityThumbprint',
		'Add-D365WindowsDefenderRules',

		'Backup-D365DevConfig',
		'Backup-D365MetaDataDir',
		'Backup-D365Runbook',
		'Backup-D365WebConfig',

		'Clear-D365ActiveBroadcastMessageConfig',
		'Clear-D365BacpacObject',
		'Clear-D365BacpacTableData',
		'Clear-D365MonitorData',
		'Clear-D365TempDbTables',
		'ConvertTo-D365Dacpac',

		'Publish-D365SsrsReport',

		'Disable-D365MaintenanceMode'
		'Disable-D365SqlChangeTracking',
		'Disable-D365User',
		'Disable-D365Flight',
		'Disable-D365Exception',

		'Enable-D365Exception',
		'Enable-D365MaintenanceMode',
		'Enable-D365SqlChangeTracking',
		'Enable-D365User',
		'Enable-D365Flight',

		'Export-D365BacpacModelFile',
		'Export-D365Model',
		'Export-D365SecurityDetails',

		'Find-D365Command',

		'Get-D365ActiveAzureStorageConfig',
		'Get-D365ActiveBroadcastMessageConfig',

		'Get-D365AOTObject',

		'Get-D365AzureDevOpsNuget',

		'Get-D365AzureStorageConfig',
		'Get-D365AzureStorageFile',
		'Get-D365AzureStorageUrl',
		'Get-D365BacpacSqlOptions',
		'Get-D365BacpacTable',
		'Get-D365BroadcastMessage',
		'Get-D365BroadcastMessageConfig',

		'Get-D365ClickOnceTrustPrompt',
		'Get-D365CompilerResult',

		'Get-D365Database',
		'Get-D365DatabaseAccess',
		'Get-D365DecryptedWebConfig',
		'Get-D365DefaultModelForNewProjects',
		'Get-D365DotNetClass',
		'Get-D365DotNetMethod',

		'Get-D365Environment',
		'Get-D365EnvironmentSettings',
		'Get-D365EventTraceProvider',
		'Get-D365ExternalIP',

		'Get-D365JsonService',

		'Get-D365InstalledHotfix',
		'Get-D365InstalledPackage',
		'Get-D365InstalledService',
		'Get-D365InstanceName',

		'Get-D365Label',
		'Get-D365Language',
		'Get-D365LabelFile',
						
		'Get-D365LcsApiConfig',
		'Get-D365LcsApiToken',
		'Get-D365LcsAssetFile',
		'Get-D365LcsSharedAssetFile',
		'Get-D365LcsAssetValidationStatus',
		'Get-D365LcsDatabaseBackups',
		'Get-D365LcsDatabaseOperationStatus',
		'Get-D365LcsDeploymentStatus',
		'Get-D365LcsEnvironmentHistory',
		'Get-D365LcsEnvironmentMetadata',

		'Get-D365MaintenanceMode',
		'Get-D365Model',
		'Get-D365Module',
		'Get-D365OfflineAuthenticationAdminEmail',

		'Get-D365PackageBundleDetail',
		'Get-D365PackageLabelResourceFile',
		'Get-D365PackageLabelResources',
		'Get-D365ProductInformation',

		'Get-D365RsatCertificateThumbprint',
		'Get-D365RsatPlaybackFile',
		'Get-D365RsatSoapHostname',

		'Get-D365Runbook',
		'Get-D365RunbookId',
		'Get-D365RunbookLogFile',

		'Get-D365SDPCleanUp',

		'Get-D365Table',
		'Get-D365TableField',
		'Get-D365TableSequence',
		'Get-D365TablesInChangedTracking',
		'Get-D365TfsUri',
		'Get-D365TfsWorkspace',

		'Get-D365Url',
		'Get-D365User',
		'Get-D365UserAuthenticationDetail',

		'Get-D365VisualStudioCompilerResult',
		'Get-D365WebServerType',
		'Get-D365WindowsActivationStatus',

		'Import-D365AadUser',
		'Import-D365AadApplication',
		'Import-D365Bacpac',
		'Import-D365Dacpac',
		'Import-D365Model',
		'Import-D365ExternalUser',
		'Import-D365RsatSelfServiceCertificates',
						
		'Initialize-D365RsatCertificate',
		
		'Install-D365SupportingSoftware',

		'Invoke-D365AzCopyTransfer',
						
		'Invoke-D365AzureDevOpsNugetPush',
						
		'Invoke-D365AzureStorageDownload',
		'Invoke-D365AzureStorageUpload',

		'Invoke-D365CompilerResultAnalyzer',
						
		'Invoke-D365DataFlush',
		'Invoke-D365DbSync',
		'Invoke-D365DbSyncPartial',
		'Invoke-D365DbSyncModule',
						
		'Invoke-D365GenerateReportAggregateDataEntity',
		'Invoke-D365GenerateReportAggregateMeasure',
		'Invoke-D365GenerateReportConfigKey',
		'Invoke-D365GenerateReportConfigKeyGroup',
		'Invoke-D365GenerateReportDataEntity',
		'Invoke-D365GenerateReportDataEntityField',
		'Invoke-D365GenerateReportKpi',
		'Invoke-D365GenerateReportLicenseCode',
		'Invoke-D365GenerateReportMenuItem',
		'Invoke-D365GenerateReports',
		'Invoke-D365GenerateReportSsrs',
		'Invoke-D365GenerateReportTable',
		'Invoke-D365GenerateReportWorkflowType'
						
		'Invoke-D365InstallAzCopy',
		'Invoke-D365InstallLicense',
		'Invoke-D365InstallNuget',
		'Invoke-D365InstallSqlPackage',
						
		'Invoke-D365LcsApiRefreshToken',
		'Invoke-D365LcsDatabaseExport',
		'Invoke-D365LcsDatabaseRefresh',
		'Invoke-D365LcsDeployment',
		'Invoke-D365LcsEnvironmentStart',
		'Invoke-D365LcsEnvironmentStop',
		'Invoke-D365LcsUpload',

		'Invoke-D365ModuleCompile',
		'Invoke-D365ModuleLabelGeneration',
		'Invoke-D365ModuleReportsCompile',
		'Invoke-D365ModuleFullCompile',

		'Invoke-D365ProcessModule'

		'Invoke-D365ReArmWindows',
		'Invoke-D365RunbookAnalyzer',

		'Invoke-D365SDPInstall',
		'Invoke-D365SCDPBundleInstall',
		'Invoke-D365SeleniumDownload',
		'Invoke-D365SysFlushAodCache',
		'Invoke-D365SysRunnerClass',
		'Invoke-D365SqlScript',

		'Invoke-D365VisualStudioCompilerResultAnalyzer',
		'Invoke-D365WinRmCertificateRotation',
						
		'Invoke-D365TableBrowser',

		'Invoke-D365BestPractice',

		'New-D365Bacpac',
		'New-D365CAReport',
		'New-D365ISVLicense',
		'New-D365ModuleToRemove',
		'New-D365TopologyFile',

		'Register-D365AzureStorageConfig',
		
		'Remove-D365LcsAssetFile',
		'Remove-D365BroadcastMessageConfig',
		'Remove-D365Database',
		'Remove-D365Model',
		'Remove-D365User',

		'Rename-D365Instance',
		'Rename-D365ComputerName',

		'Restart-D365Environment',

		'Restore-D365DevConfig',
		'Restore-D365WebConfig',

		'Send-D365BroadcastMessage',

		'Set-D365ActiveAzureStorageConfig',
		'Set-D365ActiveBroadcastMessageConfig',

		'Set-D365Admin',

		'Set-D365AzCopyPath',

		'Set-D365ClickOnceTrustPrompt',

		'Set-D365DefaultModelForNewProjects',

		'Set-D365FavoriteBookmark',
		'Set-D365LcsApiConfig',
						
		'Set-D365NugetPath',

		'Set-D365OfflineAuthenticationAdminEmail',
						
		'Set-D365RsatTier2Crypto',
		'Set-D365RsatConfiguration',
						
		'Set-D365SDPCleanUp',
		'Set-D365StartPage',
		'Set-D365SqlPackagePath',
		'Set-D365SysAdmin',

		'Set-D365WebConfigDatabase',
		'Set-D365WebServerType',

		'Set-D365TraceParserFileSize',

		'Set-D365WorkstationMode',

		'Set-D365FlightServiceCatalogId',

		'Start-D365Environment',
		'Start-D365EnvironmentV2',
		'Start-D365EventTrace',

		'Stop-D365Environment',
		'Stop-D365EventTrace',

		'Switch-D365ActiveDatabase',

		'Test-D365Command',
		'Test-D365FlightServiceCatalogId',
		'Test-D365LabelIdIsValid',
						
		'Update-D365BacpacModelFileSingleTable',
		'Update-D365User'
	)

	# Cmdlets to export from this module
	CmdletsToExport   = ''

	# Variables to export from this module
	VariablesToExport = ''

	# Aliases to export from this module
	AliasesToExport   = @(
		'Initialize-D365TestAutomationCertificate'
		, 'Add-D365WIFConfigAuthorityThumbprint'
		, 'Invoke-D365SqlCmd'
		, 'Get-D365ModelFileFromBacpac'
		, 'Get-D365SqlOptionsFromBacpacModelFile'
		, 'Clear-D365TableDataFromBacpac'
	)

	# List of all modules packaged with this module
	ModuleList        = @()

	# List of all files packaged with this module
	FileList          = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData       = @{

		#Support for PowerShellGet galleries.
		PSData = @{
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags                       = @('d365fo', 'Dynamics365', 'D365', 'Finance&Operations', 'FinanceOperations', 'FinanceAndOperations', 'Dynamics365FO')

			# A URL to the license for this module.
			LicenseUri                 = "https://opensource.org/licenses/MIT"

			# A URL to the main website for this project.
			ProjectUri                 = 'https://github.com/d365collaborative/d365fo.tools'

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

			# Indicates this is a pre-release/testing version of the module.
			IsPrerelease               = 'True'

			ExternalModuleDependencies = @('PSDiagnostics')

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}

# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCMT9IWvFG2JO+H
# ETvFNMJ2xzNAxOQcZHuH+YNdysLZEqCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILMkGpdHm+/B
# f+DRIj+B4JxkN+WFh4dUS7bmOHs1zikNMA0GCSqGSIb3DQEBAQUABIICAFS4wOGV
# Vt2WkCWq69UzcwkPn/1Zw8oIpWPuNJ64bNaGhWJZFmxz9IU4t2DwQENmEzgZWtlC
# THsoAPAtled/CT6RLpFms9U5AyPLnpuKt3bR5S43/PfsTJbjYEDd7kI8/S0x/38Y
# 7bYPIB49ItwbVfZuRLxmfQHuZHddofUEMFldOT1eKyEN+U/BvtbYwJO9tmumD77/
# AyRoisv6DR2PcmqU5hYC4s6aIZle/mNz9Vx2myCIxt0vSsCuu5zw5r8duZObAFff
# RZ53mJwbDZ37id1j/fdJe395lkZsyy2ap9Jo1ZOv06CmG4vNyA8dIVyQ5bPtOJYr
# x0PleWlCfA1NVo692GtS/ZzRmdaDf5JZ6sDhq4aegtHt2FtW0WHq6lrgbi0e3Kid
# pn4QbH30uk8X+LO/sOXeLG/ftU2OX0qDNfCDs6ObqjfhlS9nJi68k3zjkNwvjK84
# FvifFJ7H5uv/Quv2Bqx0coTnruPA1zksr9k28sfBpH+C3prTyc+HQDhn7LsQNt6E
# HaItqztTmzg/gybSjYtrArK+Z9Bz9LbobjXXvU9wt92i3m7JlKQugmTKJS8gXZbE
# yg9t8JOr4EBK5uhg4Oosj01/rrp5jUSyDASjPBTnxwETRvnmKc6kpHLQtFurwUdY
# bc1B+ETe2LdbcamRwq4m3jWTKQW0znt0TOf8oYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMzIyMFowLwYJKoZIhvcNAQkEMSIEIAeM+j7NwO1x9JsNf3cLwgQz5QMN
# a9RvtmYcbJejvh2NMA0GCSqGSIb3DQEBAQUABIICABSOdtZNYIWVY0tjj7yXo6If
# wmhg2ip/Ff9QaYPVA2Tb1iOrbKgD/hT+a5qwtUi7HfhyV05lUItAXOCRC/socdYp
# I13NtJcljdNAcZzhi7jvoitE45IEeA0kmAVZf9UbfgixV+HW4oHlfxsd4pEwcHsx
# iNRk5K1r6O9HKeQRuEfAIn7b7vy59uqn6D89pL55iqXQzHKM14fL6hMjvb/j1f0e
# KY+BOzHaAoQWjrHsLgY2I4FW8sjxVvX398XsIhXzdhx0cIa/+0Nn7HreXVxminMT
# IZ6gD1cmb7q5XkA1CFzeAomdR0SC99r9crsT9LI22B3wqlBewdr0eQRNlmbXH8ed
# 7L9Svgn530I8r/FINYcYL7ZS0frOkOAEjhLqZX18rjjK6vvczYJ+i00ZUWky5ly4
# QGnUqR80SHSIhGIpgSGNYn0B08iIWyowYgF2bs9vC427Tl7zneBp5GN+S8pkYw/7
# 12lHLypdjh6914Qsz/h3tW08ZOeNBTCjZeFi0pQOtg1Xuz6Bfe0sZUH/VQRDlDFe
# 4HYGraTLpidul00uKfaRhKrDcWbR/zfmP68Xdqpkkg0lEIvXrwrI73UQ1e17BEas
# VSgdnZBUDTUtaVcEjZDpTpv4T8N7or1pBsyKroeGGsYjNIxf/ykUWJo8DS5PwzoT
# W5XORId0JlV4jgono5H/
# SIG # End signature block
