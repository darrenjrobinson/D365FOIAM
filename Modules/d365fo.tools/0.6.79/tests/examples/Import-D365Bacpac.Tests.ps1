$commandName = "Import-D365Bacpac"
################################### New Example test ###################################

$exampleRaw = "Import-D365Bacpac -ImportModeTier1 -BacpacFile `"C:\temp\uat.bacpac`" -NewDatabaseName `"ImportedDatabase`""
#Remember to escape any variables names in the line above.
#Remember to you need to output $true to the pester test, otherwise is fails.
#; `$var -eq `$true

#Here you declare any variable(s) you need to complete the test.

$example = $exampleRaw -replace "`n.*" -replace "PS C:\\>"

Describe "Specific example testing for $commandName" {

It "Example - $example" {
# mock the tested command so we don't actually do anything
# because it can be unsafe and we don't have the environment setup
# (so the only thing we are testing is that the code is semantically
# correct and provides all the needed params)
Mock $commandName {
# I am returning true here,
# but some of the examples drill down to the returned object
# so in strict mode we would fail
$true
}
# here simply invoke the example
$result = Invoke-Expression $example
# and check that we got result from the mock
$result | Should -BeTrue
}
}
################################### New Example test ###################################

$exampleRaw = "Import-D365Bacpac -ImportModeTier2 -SqlUser `"sqladmin`" -SqlPwd `"XyzXyz`" -BacpacFile `"C:\temp\uat.bacpac`" -AxDeployExtUserPwd `"XxXx`" -AxDbAdminPwd `"XxXx`" -AxRuntimeUserPwd `"XxXx`" -AxMrRuntimeUserPwd `"XxXx`" -AxRetailRuntimeUserPwd `"XxXx`" -AxRetailDataSyncUserPwd `"XxXx`" -AxDbReadonlyUserPwd `"XxXx`" -NewDatabaseName `"ImportedDatabase`""
#Remember to escape any variables names in the line above.
#Remember to you need to output $true to the pester test, otherwise is fails.
#; `$var -eq `$true

#Here you declare any variable(s) you need to complete the test.

$example = $exampleRaw -replace "`n.*" -replace "PS C:\\>"

Describe "Specific example testing for $commandName" {

It "Example - $example" {
# mock the tested command so we don't actually do anything
# because it can be unsafe and we don't have the environment setup
# (so the only thing we are testing is that the code is semantically
# correct and provides all the needed params)
Mock $commandName {
# I am returning true here,
# but some of the examples drill down to the returned object
# so in strict mode we would fail
$true
}
# here simply invoke the example
$result = Invoke-Expression $example
# and check that we got result from the mock
$result | Should -BeTrue
}
}
################################### New Example test ###################################

$exampleRaw = "Import-D365Bacpac -ImportModeTier1 -BacpacFile `"C:\temp\uat.bacpac`" -NewDatabaseName `"ImportedDatabase`" -DiagnosticFile `"C:\temp\ImportLog.txt`""
#Remember to escape any variables names in the line above.
#Remember to you need to output $true to the pester test, otherwise is fails.
#; `$var -eq `$true

#Here you declare any variable(s) you need to complete the test.

$example = $exampleRaw -replace "`n.*" -replace "PS C:\\>"

Describe "Specific example testing for $commandName" {

It "Example - $example" {
# mock the tested command so we don't actually do anything
# because it can be unsafe and we don't have the environment setup
# (so the only thing we are testing is that the code is semantically
# correct and provides all the needed params)
Mock $commandName {
# I am returning true here,
# but some of the examples drill down to the returned object
# so in strict mode we would fail
$true
}
# here simply invoke the example
$result = Invoke-Expression $example
# and check that we got result from the mock
$result | Should -BeTrue
}
}
################################### Entire help loaded ###################################

<#


NAME
    Import-D365Bacpac
    
SYNOPSIS
    Import a bacpac file
    
    
SYNTAX
    Import-D365Bacpac [-ImportModeTier1] [[-DatabaseServer] <String>] [[-DatabaseName] <String>] [[-SqlUser] <String>] 
    [[-SqlPwd] <String>] [-BacpacFile] <String> [-NewDatabaseName] <String> [[-CustomSqlFile] <String>] [-DiagnosticFil
    e <String>] [-ImportOnly] [-EnableException] [<CommonParameters>]
    
    Import-D365Bacpac [-ImportModeTier2] [[-DatabaseServer] <String>] [[-DatabaseName] <String>] [-SqlUser] <String> [-
    SqlPwd] <String> [-BacpacFile] <String> [-NewDatabaseName] <String> [[-AxDeployExtUserPwd] <String>] [[-AxDbAdminPw
    d] <String>] [[-AxRuntimeUserPwd] <String>] [[-AxMrRuntimeUserPwd] <String>] [[-AxRetailRuntimeUserPwd] <String>] [
    [-AxRetailDataSyncUserPwd] <String>] [[-AxDbReadonlyUserPwd] <String>] [[-CustomSqlFile] <String>] [-DiagnosticFile
     <String>] -ImportOnly [-EnableException] [<CommonParameters>]
    
    Import-D365Bacpac [-ImportModeTier2] [[-DatabaseServer] <String>] [[-DatabaseName] <String>] [-SqlUser] <String> [-
    SqlPwd] <String> [-BacpacFile] <String> [-NewDatabaseName] <String> [-AxDeployExtUserPwd] <String> [-AxDbAdminPwd] 
    <String> [-AxRuntimeUserPwd] <String> [-AxMrRuntimeUserPwd] <String> [-AxRetailRuntimeUserPwd] <String> [-AxRetailD
    ataSyncUserPwd] <String> [-AxDbReadonlyUserPwd] <String> [[-CustomSqlFile] <String>] [-DiagnosticFile <String>] [-E
    nableException] [<CommonParameters>]
    
    
DESCRIPTION
    Import a bacpac file to either a Tier1 or Tier2 environment
    

PARAMETERS
    -ImportModeTier1 [<SwitchParameter>]
        Switch to instruct the cmdlet that it will import into a Tier1 environment
        
        The cmdlet will expect to work against a SQL Server instance
        
        Required?                    true
        Position?                    1
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ImportModeTier2 [<SwitchParameter>]
        Switch to instruct the cmdlet that it will import into a Tier2 environment
        
        The cmdlet will expect to work against an Azure DB instance
        
        Required?                    true
        Position?                    1
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -DatabaseServer <String>
        The name of the database server
        
        If on-premises or classic SQL Server, use either short name og Fully Qualified Domain Name (FQDN).
        
        If Azure use the full address to the database server, e.g. server.database.windows.net
        
        Required?                    false
        Position?                    2
        Default value                $Script:DatabaseServer
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -DatabaseName <String>
        The name of the database
        
        Required?                    false
        Position?                    3
        Default value                $Script:DatabaseName
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -SqlUser <String>
        The login name for the SQL Server instance
        
        Required?                    false
        Position?                    4
        Default value                $Script:DatabaseUserName
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -SqlPwd <String>
        The password for the SQL Server user
        
        Required?                    false
        Position?                    5
        Default value                $Script:DatabaseUserPassword
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -BacpacFile <String>
        Path to the bacpac file you want to import into the database server
        
        Required?                    true
        Position?                    6
        Default value                
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    -NewDatabaseName <String>
        Name of the new database that will be created while importing the bacpac file
        
        This will create a new database on the database server and import the content of the bacpac into
        
        Required?                    true
        Position?                    7
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -AxDeployExtUserPwd <String>
        Password that is obtained from LCS
        
        Required?                    false
        Position?                    8
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -AxDbAdminPwd <String>
        Password that is obtained from LCS
        
        Required?                    false
        Position?                    9
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -AxRuntimeUserPwd <String>
        Password that is obtained from LCS
        
        Required?                    false
        Position?                    10
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -AxMrRuntimeUserPwd <String>
        Password that is obtained from LCS
        
        Required?                    false
        Position?                    11
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -AxRetailRuntimeUserPwd <String>
        Password that is obtained from LCS
        
        Required?                    false
        Position?                    12
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -AxRetailDataSyncUserPwd <String>
        Password that is obtained from LCS
        
        Required?                    false
        Position?                    13
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -AxDbReadonlyUserPwd <String>
        Password that is obtained from LCS
        
        Required?                    false
        Position?                    14
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -CustomSqlFile <String>
        Path to the sql script file that you want the cmdlet to execute against your data after it has been imported
        
        Required?                    false
        Position?                    15
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -DiagnosticFile <String>
        Path to where you want the import to output a diagnostics file to assist you in troubleshooting the import
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ImportOnly [<SwitchParameter>]
        Switch to instruct the cmdlet to only import the bacpac into the new database
        
        The cmdlet will create a new database and import the content of the bacpac file into this
        
        Nothing else will be executed
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -EnableException [<SwitchParameter>]
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    
OUTPUTS
    
NOTES
    
    
        Tags: Database, Bacpac, Tier1, Tier2, Golden Config, Config, Configuration
        
        Author: Rasmus Andersen (@ITRasmus)
        Author: Mötz Jensen (@Splaxi)
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Import-D365Bacpac -ImportModeTier1 -BacpacFile "C:\temp\uat.bacpac" -NewDatabaseName "ImportedDatabase"
    
    PS C:\> Switch-D365ActiveDatabase -NewDatabaseName "ImportedDatabase"
    
    This will instruct the cmdlet that the import will be working against a SQL Server instance.
    It will import the "C:\temp\uat.bacpac" file into a new database named "ImportedDatabase".
    The next thing to do is to switch the active database out with the new one you just imported.
    "ImportedDatabase" will be switched in as the active database, while the old one will be named "AXDB_original".
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Import-D365Bacpac -ImportModeTier2 -SqlUser "sqladmin" -SqlPwd "XyzXyz" -BacpacFile "C:\temp\uat.bacpac" -Ax
    DeployExtUserPwd "XxXx" -AxDbAdminPwd "XxXx" -AxRuntimeUserPwd "XxXx" -AxMrRuntimeUserPwd "XxXx" -AxRetailRuntimeUs
    erPwd "XxXx" -AxRetailDataSyncUserPwd "XxXx" -AxDbReadonlyUserPwd "XxXx" -NewDatabaseName "ImportedDatabase"
    
    PS C:\> Switch-D365ActiveDatabase -NewDatabaseName "ImportedDatabase" -SqlUser "sqladmin" -SqlPwd "XyzXyz"
    
    This will instruct the cmdlet that the import will be working against an Azure DB instance.
    It requires all relevant passwords from LCS for all the builtin user accounts used in a Tier 2 environment.
    It will import the "C:\temp\uat.bacpac" file into a new database named "ImportedDatabase".
    The next thing to do is to switch the active database out with the new one you just imported.
    "ImportedDatabase" will be switched in as the active database, while the old one will be named "AXDB_original".
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>Import-D365Bacpac -ImportModeTier1 -BacpacFile "C:\temp\uat.bacpac" -NewDatabaseName "ImportedDatabase" -Dia
    gnosticFile "C:\temp\ImportLog.txt"
    
    This will instruct the cmdlet that the import will be working against a SQL Server instance.
    It will import the "C:\temp\uat.bacpac" file into a new database named "ImportedDatabase".
    It will output a diagnostic file to "C:\temp\ImportLog.txt".
    
    
    
    
    
RELATED LINKS



#>

# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAEKgdG8g9nLkIh
# HKQ4eNAuh/XsYl8vwMys6bMcXS/RUqCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO/bO0seOkcQ
# U7I9R/i57ULtYzg2vJldId5hdYwWmeI+MA0GCSqGSIb3DQEBAQUABIICAEPYEXn0
# myWx9jDksXbuaes3GHCruP1lJOfsN723CLDIwm5gTSU813Ym9KVBUMvYJLmDUBXM
# v3hQsTg/YKrFLeKv5OmRfN9cgjvjUQSFUAldGtYbIqkMTPf08w1ksqjTbeO1+1Ua
# WSFxyrlQb28QleXmaLpmqJA0FuU3Y9IDHA5zd83xq8Wf/bUKNGp6zGJqP42rq+0b
# m4CSs39R49B7SyXmJlfcSlVbqFSjOOQR4Mf/ixP/QidC3Oq/AsXCfeTrgDS/rRHh
# biEM8sZFxGZ4h2b1EHj3maJ1zd3cLt6yCTfzhiYtT+mSiS08BQS5yr31d1Op08OY
# CEN82Viwl8gx46lAuHZNbjT+dDcGd1QLaf+gT3OpetMG7N0+ZkdN8VYIXLLRsWdB
# fLOWm5aqUeICieDA8lehjGv66+u3ihGuz9TiljKzY+qDXjeBnXukpghw9YY2tBFF
# t7OwXbM2KoId/+pP5QliPUFWQOeD//CI9T+O6Vg0jNzQryaQst14M8D5vdNt38qq
# fhtHSeaSPAK8cFcUebyrsNhzN0GlyPEK2mPMoyBfXd1XBv6HGt3Sm1O7HbNCKvDT
# 03L+dtM/5QdTquHl1Ykc3mAWwEN/xk8Ty1wVB2OmwCQzlj9N6mxbajOdQ/lXoPfs
# kU6KOD++CiI4gnd6t1RaYi4OEbYUslWWx5VKoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMjk1MFowLwYJKoZIhvcNAQkEMSIEIHoZ+K8ZkgRHhcsnPb8tJLTyzIGh
# vFCH3KrcKzw9RWmAMA0GCSqGSIb3DQEBAQUABIICAAbYKcWsYVw8rPassXHP8UYc
# wbRk8Em9bzGzA2X6RwAtPAUu0kDq0FxQCVkcMrEe58uoZJ8EgOOvTzk9XsCc8aXf
# gFPkLiqRl4Z2fdZwZlcfxzLu041XMF/LFdbX/aY4hJ8GjwfKyMQkpOWkfJ0Z9Sl/
# +nbKl3uLFN2nbrNjABtN6FMh9QTomBU/yFY4tpg3abmr6JQaMn9wcf0cGVx0FBLX
# 7GtIB8MnULDGrGt6Pch79uJpNXEm8w5YrwFBdCoxu4alk+OiQ5eRu2RSsH9G0VOx
# yfxdOlP1mVAkwbNqpVvHJaWyx4BZPlXmi4ullyszBHlNQ9h13ri17Fnt34KT2Y/N
# jm7IM8BYxGKFVvqVUqQYkir9BsmnTLIcHvXcSQhBOi/VMdDfAk9GupgUpZu1bz4b
# BK3xgAMzablADBgFzpmwHQi9Z/UNBcxhYu9mnPFaDRwUhP275mx9BKkA3jZzyJuc
# LLxQliYME3yOyFJLgfOI6oVaVhQgu5hQaN51RU5+RRFAKB1LQd/4cDbIrPCwIoey
# QPpAGUjBgEhp70DRvmE83lgMO3NNMsHliWzRRQl59M+UPQflArlLVLdn3ULloKvL
# dImneteyLHyvNHKXqTI2KK/z3LfVmd9rVpzaAZvlNku6SdDv+6V4fXIIpqHNFkkx
# KlcRXO2yXZ/DD0QihKb+
# SIG # End signature block
