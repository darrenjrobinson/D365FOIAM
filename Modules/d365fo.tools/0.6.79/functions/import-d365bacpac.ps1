﻿
<#
    .SYNOPSIS
        Import a bacpac file
        
    .DESCRIPTION
        Import a bacpac file to either a Tier1 or Tier2 environment
        
    .PARAMETER ImportModeTier1
        Switch to instruct the cmdlet that it will import into a Tier1 environment
        
        The cmdlet will expect to work against a SQL Server instance
        
    .PARAMETER ImportModeTier2
        Switch to instruct the cmdlet that it will import into a Tier2 environment
        
        The cmdlet will expect to work against an Azure DB instance
        
    .PARAMETER DatabaseServer
        The name of the database server
        
        If on-premises or classic SQL Server, use either short name og Fully Qualified Domain Name (FQDN).
        
        If Azure use the full address to the database server, e.g. server.database.windows.net
        
    .PARAMETER DatabaseName
        The name of the database
        
    .PARAMETER SqlUser
        The login name for the SQL Server instance
        
    .PARAMETER SqlPwd
        The password for the SQL Server user
        
    .PARAMETER BacpacFile
        Path to the bacpac file you want to import into the database server
        
    .PARAMETER NewDatabaseName
        Name of the new database that will be created while importing the bacpac file
        
        This will create a new database on the database server and import the content of the bacpac into
        
    .PARAMETER AxDeployExtUserPwd
        Password that is obtained from LCS
        
    .PARAMETER AxDbAdminPwd
        Password that is obtained from LCS
        
    .PARAMETER AxRuntimeUserPwd
        Password that is obtained from LCS
        
    .PARAMETER AxMrRuntimeUserPwd
        Password that is obtained from LCS
        
    .PARAMETER AxRetailRuntimeUserPwd
        Password that is obtained from LCS
        
    .PARAMETER AxRetailDataSyncUserPwd
        Password that is obtained from LCS
        
    .PARAMETER AxDbReadonlyUserPwd
        Password that is obtained from LCS
        
    .PARAMETER CustomSqlFile
        Path to the sql script file that you want the cmdlet to execute against your data after it has been imported
        
    .PARAMETER ModelFile
        Path to the model file that you want the SqlPackage.exe to use instead the one being part of the bacpac file
        
        This is used to override SQL Server options, like collation and etc
        
    .PARAMETER DiagnosticFile
        Path to where you want the import to output a diagnostics file to assist you in troubleshooting the import
        
    .PARAMETER ImportOnly
        Switch to instruct the cmdlet to only import the bacpac into the new database
        
        The cmdlet will create a new database and import the content of the bacpac file into this
        
        Nothing else will be executed
        
    .PARAMETER MaxParallelism
        Sets SqlPackage.exe's degree of parallelism for concurrent operations running against a database
        
        The default value is 8
        
    .PARAMETER LogPath
        The path where the log file(s) will be saved
        
        When running without the ShowOriginalProgress parameter, the log files will be the standard output and the error output from the underlying tool executed
        
    .PARAMETER ShowOriginalProgress
        Instruct the cmdlet to show the standard output in the console
        
        Default is $false which will silence the standard output
        
    .PARAMETER OutputCommandOnly
        Instruct the cmdlet to only output the command that you would have to execute by hand
        
        Will include full path to the executable and the needed parameters based on your selection
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Invoke-D365InstallSqlPackage
        
        You should always install the latest version of the SqlPackage.exe, which is used by New-D365Bacpac.
        
        This will fetch the latest .Net Core Version of SqlPackage.exe and install it at "C:\temp\d365fo.tools\SqlPackage".
        
    .EXAMPLE
        PS C:\> Import-D365Bacpac -ImportModeTier1 -BacpacFile "C:\temp\uat.bacpac" -NewDatabaseName "ImportedDatabase"
        PS C:\> Switch-D365ActiveDatabase -NewDatabaseName "ImportedDatabase"
        
        This will instruct the cmdlet that the import will be working against a SQL Server instance.
        It will import the "C:\temp\uat.bacpac" file into a new database named "ImportedDatabase".
        The next thing to do is to switch the active database out with the new one you just imported.
        "ImportedDatabase" will be switched in as the active database, while the old one will be named "AXDB_original".
        
    .EXAMPLE
        PS C:\> Import-D365Bacpac -ImportModeTier2 -SqlUser "sqladmin" -SqlPwd "XyzXyz" -BacpacFile "C:\temp\uat.bacpac" -AxDeployExtUserPwd "XxXx" -AxDbAdminPwd "XxXx" -AxRuntimeUserPwd "XxXx" -AxMrRuntimeUserPwd "XxXx" -AxRetailRuntimeUserPwd "XxXx" -AxRetailDataSyncUserPwd "XxXx" -AxDbReadonlyUserPwd "XxXx" -NewDatabaseName "ImportedDatabase"
        PS C:\> Switch-D365ActiveDatabase -NewDatabaseName "ImportedDatabase" -SqlUser "sqladmin" -SqlPwd "XyzXyz"
        
        This will instruct the cmdlet that the import will be working against an Azure DB instance.
        It requires all relevant passwords from LCS for all the builtin user accounts used in a Tier 2 environment.
        It will import the "C:\temp\uat.bacpac" file into a new database named "ImportedDatabase".
        The next thing to do is to switch the active database out with the new one you just imported.
        "ImportedDatabase" will be switched in as the active database, while the old one will be named "AXDB_original".
        
    .EXAMPLE
        PS C:\> Import-D365Bacpac -ImportModeTier1 -BacpacFile "C:\temp\uat.bacpac" -NewDatabaseName "ImportedDatabase" -DiagnosticFile "C:\temp\ImportLog.txt"
        
        This will instruct the cmdlet that the import will be working against a SQL Server instance.
        It will import the "C:\temp\uat.bacpac" file into a new database named "ImportedDatabase".
        It will output a diagnostic file to "C:\temp\ImportLog.txt".
        
    .EXAMPLE
        PS C:\> Import-D365Bacpac -ImportModeTier1 -BacpacFile "C:\temp\uat.bacpac" -NewDatabaseName "ImportedDatabase" -DiagnosticFile "C:\temp\ImportLog.txt" -MaxParallelism 32
        
        This will instruct the cmdlet that the import will be working against a SQL Server instance.
        It will import the "C:\temp\uat.bacpac" file into a new database named "ImportedDatabase".
        It will output a diagnostic file to "C:\temp\ImportLog.txt".
        
        It will use 32 connections against the database server while importing the bacpac file.
        
    .EXAMPLE
        PS C:\> Import-D365Bacpac -ImportModeTier1 -BacpacFile "C:\temp\uat.bacpac" -NewDatabaseName "ImportedDatabase" -ImportOnly
        
        This will instruct the cmdlet that the import will be working against a SQL Server instance.
        It will import the "C:\temp\uat.bacpac" file into a new database named "ImportedDatabase".
        No cleanup or prepping jobs will be executed, because this is for importing only.
        
        This would be something that you can use when extract a bacpac file from a Tier1 and want to import it into a Tier1.
        You would still need to execute the Switch-D365ActiveDatabase cmdlet, to get the newly imported database to be the AXDB database.
        
    .NOTES
        Tags: Database, Bacpac, Tier1, Tier2, Golden Config, Config, Configuration
        
        Author: Rasmus Andersen (@ITRasmus)
        Author: Mötz Jensen (@Splaxi)
        
#>
function Import-D365Bacpac {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseProcessBlockForPipelineCommand", "")]
    [CmdletBinding(DefaultParameterSetName = 'ImportTier1')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier1', Position = 0)]
        [switch] $ImportModeTier1,

        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', Position = 0)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ImportOnlyTier2', Position = 0)]
        [switch] $ImportModeTier2,

        [Parameter(Position = 1 )]
        [string] $DatabaseServer = $Script:DatabaseServer,

        [Parameter(Position = 2 )]
        [string] $DatabaseName = $Script:DatabaseName,

        [Parameter(Mandatory = $false, Position = 3 )]
        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 3)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportTier1', Position = 3)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ImportOnlyTier2', ValueFromPipelineByPropertyName = $true, Position = 3)]
        [string] $SqlUser = $Script:DatabaseUserName,

        [Parameter(Mandatory = $false, Position = 4 )]
        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 4)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportTier1', Position = 4)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ImportOnlyTier2', ValueFromPipelineByPropertyName = $true, Position = 4)]
        [string] $SqlPwd = $Script:DatabaseUserPassword,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 5 )]
        [Alias('File')]
        [string] $BacpacFile,

        [Parameter(Mandatory = $true, Position = 6 )]
        [string] $NewDatabaseName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 7)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportOnlyTier2', Position = 7)]
        [string] $AxDeployExtUserPwd,

        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 8)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportOnlyTier2', Position = 8)]
        [string] $AxDbAdminPwd,

        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 9)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportOnlyTier2', Position = 9)]
        [string] $AxRuntimeUserPwd,

        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 10)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportOnlyTier2', Position = 10)]
        [string] $AxMrRuntimeUserPwd,

        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 11)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportOnlyTier2', Position = 11)]
        [string] $AxRetailRuntimeUserPwd,

        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 12)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportOnlyTier2', Position = 12)]
        [string] $AxRetailDataSyncUserPwd,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ImportTier2', ValueFromPipelineByPropertyName = $true, Position = 13)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportOnlyTier2', Position = 13)]
        [string] $AxDbReadonlyUserPwd,
        
        [string] $CustomSqlFile,

        [string] $ModelFile,

        [string] $DiagnosticFile,
 
        [Parameter(Mandatory = $false, ParameterSetName = 'ImportTier1')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ImportOnlyTier2')]
        [switch] $ImportOnly,
        
        [int] $MaxParallelism = 8,

        [Alias('LogDir')]
        [string] $LogPath = $(Join-Path -Path $Script:DefaultTempPath -ChildPath "Logs\ImportBacpac"),

        [switch] $ShowOriginalProgress,

        [switch] $OutputCommandOnly,

        [switch] $EnableException
    )

    if (-not (Test-PathExists -Path $BacpacFile -Type Leaf)) {
        return
    }

    if ($PSBoundParameters.ContainsKey("CustomSqlFile")) {
        if (-not (Test-PathExists -Path $CustomSqlFile -Type Leaf)) {
            return
        }
        else {
            $ExecuteCustomSQL = $true
        }
    }

    Invoke-TimeSignal -Start
    
    $UseTrustedConnection = Test-TrustedConnection $PSBoundParameters

    $BaseParams = @{
        DatabaseServer = $DatabaseServer
        DatabaseName   = $DatabaseName
        SqlUser        = $SqlUser
        SqlPwd         = $SqlPwd
    }

    $ImportParams = @{
        Action   = "import"
        FilePath = $BacpacFile
        MaxParallelism = $MaxParallelism
    }

    if (-not [system.string]::IsNullOrEmpty($DiagnosticFile)) {
        if (-not (Test-PathExists -Path (Split-Path $DiagnosticFile -Parent) -Type Container -Create)) { return }
        $ImportParams.DiagnosticFile = $DiagnosticFile
    }

    if (-not [system.string]::IsNullOrEmpty($ModelFile)) {
        if (-not (Test-PathExists -Path $ModelFile -Type Leaf)) { return }

        $ImportParams.ModelFile = $ModelFile
    }

    Write-PSFMessage -Level Verbose "Testing if we are working against a Tier2 / Azure DB"
    if ($ImportModeTier2) {
        Write-PSFMessage -Level Verbose "Start collecting the current Azure DB instance settings"

        $Objectives = Get-AzureServiceObjective @BaseParams

        if ($null -eq $Objectives) { return }

        [System.Collections.ArrayList] $Properties = New-Object -TypeName "System.Collections.ArrayList"
        $null = $Properties.Add("DatabaseEdition=$($Objectives.DatabaseEdition)")
        $null = $Properties.Add("DatabaseServiceObjective=$($Objectives.DatabaseServiceObjective)")

        $ImportParams.Properties = $Properties.ToArray()
    }
    
    $Params = Get-DeepClone $BaseParams
    $Params.DatabaseName = $NewDatabaseName
    
    Write-PSFMessage -Level Verbose "Start importing the bacpac with a new database name and current settings"
    Invoke-SqlPackage @Params @ImportParams -TrustedConnection $UseTrustedConnection -ShowOriginalProgress:$ShowOriginalProgress -OutputCommandOnly:$OutputCommandOnly -LogPath $LogPath

    if ($OutputCommandOnly) { return }

    if ($ImportOnly) { return }

    if (Test-PSFFunctionInterrupt) { return }
    
    Write-PSFMessage -Level Verbose "Importing completed"

    Write-PSFMessage -Level Verbose -Message "Start working on the configuring the new database"

    if ($ImportModeTier2) {
        Write-PSFMessage -Level Verbose "Building sql statement to update the imported Azure database"

        $InstanceValues = Get-InstanceValues @BaseParams -TrustedConnection $UseTrustedConnection

        if ($null -eq $InstanceValues) { return }

        $AzureParams = @{
            AxDeployExtUserPwd = $AxDeployExtUserPwd; AxDbAdminPwd = $AxDbAdminPwd;
            AxRuntimeUserPwd = $AxRuntimeUserPwd; AxMrRuntimeUserPwd = $AxMrRuntimeUserPwd;
            AxRetailRuntimeUserPwd = $AxRetailRuntimeUserPwd; AxRetailDataSyncUserPwd = $AxRetailDataSyncUserPwd;
            AxDbReadonlyUserPwd = $AxDbReadonlyUserPwd;
        }

        $res = Set-AzureBacpacValues @Params @AzureParams @InstanceValues

        if (-not ($res)) { return }
    }
    else {
        Write-PSFMessage -Level Verbose "Building sql statement to update the imported SQL database"

        $res = Set-SqlBacpacValues @Params -TrustedConnection $UseTrustedConnection
            
        if (-not ($res)) { return }
    }

    if ($ExecuteCustomSQL) {
        Write-PSFMessage -Level Verbose -Message "Invoking the Execution of custom SQL script"
        $res = Invoke-D365SqlScript @Params -FilePath $CustomSqlFile -TrustedConnection $UseTrustedConnection

        if (-not ($res)) { return }
    }

    Invoke-TimeSignal -End
}
# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA17Ufby722jU8a
# ugagdWsrtjb1s8OWsLp4jlemtepWYKCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINDHTMGz/dOo
# EgDEg3nydwALJiIecsM7c2K3UfCAW3GiMA0GCSqGSIb3DQEBAQUABIICAGE4GNbs
# g6chAcrP7UMoqscCL/VJTx7hJu5CaGdF5Yc3l+5kMSDlrnC8m3ZbkCUEjjYUHmYQ
# fFPrn1MgYnY2AA1PAm+U5uxoTc3Vsg+dAM9V7G0bZ+rYAifKsbu19ToP0XtDOi0L
# bMAfhOI/FLMcNonhds/eQPS3SYaT0TUfcfqtdyQXolR04dWLqosX+TijdwFeFaXJ
# jjpaZ3QcyTYFs82JzqM0c8x/KNwyPBU4XPlMzTNDOwgWkkRPR4CxmH334Wj3wXkt
# m0HfLHkJbq+vbiQiHo6B/PIbF8x/u0JUMTKBP5+Db0y+OHUZ1wclVX/qrNqMcRLi
# kDG2ZAdkiedv4T+xcmiyH9A6KOt3l6va7IvZW9IB+1R9EjCmGBQA2iOnpOYDC85S
# qZ0QjJlEhjiEpyVUBKGvrA7p6p5hsD5DW0LIlHv/2My7r/ZZhKDmiQVENLe+6W8g
# lmqwfhrVOPoglh5zQeKsqqEjQqmnhhG/zi7gij7Ixr5a+kDLnm4hx4KIXAbp0rOx
# RdKhbJ6hN+1E0BZ9DwyH2ucyZHkGE1pqIXk6gHkjH18BzcoHf770t+wev8BeYmzp
# 9UXj7Gj4qqEA7oz0FDtgrqRYWawMWtj7PAWSd+tfMsV/HY+st8qhDuLPH0ccVDT4
# woXvsjcw86ZhKhxgTYi1DwdQX+csPLqf0bNNoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMjY1NlowLwYJKoZIhvcNAQkEMSIEIMDhOCPy9ghVvBaeUzImiYim7hvo
# l4ggiLAZHtAU5UOPMA0GCSqGSIb3DQEBAQUABIICAJrjiS2JlJKP5ELWbzbaBlUs
# dyml3c4+Nu2VNB/1p04KpXgDdUb8Jc4KMa7ycPv4UXv8OzR3R1mIveVRLrbsHhOG
# Z4ATbJHUuBY75FwVbNGNE5zoF34VhwngYNeaBERwlA41A63XWnXn6Q42Yh+vdBGG
# 7KFooVbUNn9EX6LEVBcyNm2qNDF6pKbyneAg7PWiWHVAoB4+jHcO54f/NhKAsaPV
# kI4TWqYguIIPpaEYOIrgbA8B3m3ycjPKEGdL2rvVJERLemOZX+JZSegJOCUeVLHi
# k+Jvwx3ZqgmJIphJIeod9tZU9rrWG4b0P/zT5VpqiPVec9+R5LZaQ6W/lmerBMDr
# E6wujI0CLviUs6v+t/8FtC/ArmAVUNDtCvjzgPKyGbDdNGvnV0mWQt7r5qFsXg8Z
# By9ee9t3boU75aJeXK6d3AQkeVTrUdOkIPwBhfR8IgwjD9AUKEoTXMChICwMQzNx
# PrlbPtJzrGPTJogluYMxey/mmbig/Qj1yTjATVrYP7whGh5q2KB6gaQ2hTtZOJGm
# 8NXGXBDmXo5Ey1jsG/FI4JoY7j+weqlZjViuh8TjhlDxdFjw6GJiZOaVRuaPa+vz
# GZ/XtQdHpULR/ZC74URwPqX9JqVRgkkpOce4SEDcQVyWtn6N5GGKoR+JyDJuPNXs
# yH1ecfUsw/vKWHU4rSXM
# SIG # End signature block
