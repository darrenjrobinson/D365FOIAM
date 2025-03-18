
<#
    .SYNOPSIS
        Import dacpac file to a database
        
    .DESCRIPTION
        Import a dacpac file into a database, using the publish feature of SqlPackage.exe
        
        If the database doesn't exists, it will be created
        
        If the database exists, the publish process from the dacpac file will make sure to align the different tables inside the database
        
    .PARAMETER Path
        Path to the dacpac file that you want to import
        
    .PARAMETER ModelFile
        Path to the model file that you want the SqlPackage.exe to use instead the one being part of the dacpac file
        
        This is used to override SQL Server options, like collation and etc
        
        This is also used to support single table import / restore from a dacpac file
        
    .PARAMETER PublishFile
        Path to the publish / profile file that contains extended parameters for the SqlPackage.exe assembly
        
    .PARAMETER DiagnosticFile
        Path to where you want the import to output a diagnostics file to assist you in troubleshooting the import
        
    .PARAMETER MaxParallelism
        Sets SqlPackage.exe's degree of parallelism for concurrent operations running against a database
        
        The default value is 8
        
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
        PS C:\> Import-D365Dacpac -Path "c:\Temp\AxDB.dacpac" -ModelFile "c:\Temp\dbo.salestable.model.xml"
        
        This will import the dacpac file and use the modified model file while doing so.
        It will use the "c:\Temp\AxDB.dacpac" as the Path parameter.
        It will use the "c:\Temp\dbo.salestable.model.xml" as the ModelFile parameter.
        
        This is used to enable single table restore / publish.
        
    .EXAMPLE
        PS C:\> Import-D365Dacpac -Path "c:\Temp\AxDB.dacpac" -ModelFile "c:\Temp\dbo.salestable.model.xml" -DiagnosticFile "C:\temp\ImportLog.txt" -MaxParallelism 32
        
        This will import the dacpac file and use the modified model file while doing so.
        It will use the "c:\Temp\AxDB.dacpac" as the Path parameter.
        It will use the "c:\Temp\dbo.salestable.model.xml" as the ModelFile parameter.
        It will use the "C:\temp\ImportLog.txt" as the DiagnosticFile parameter, where the diagnostic file will be stored.
        
        It will use 32 connections against the database server while importing the bacpac file.
        
        This is used to enable single table restore / publish.
        
    .EXAMPLE
        PS C:\> Import-D365Dacpac -Path "c:\Temp\AxDB.dacpac" -PublishFile "c:\Temp\publish.xml"
        
        This will import the dacpac file and use the Publish file which contains advanced configuration instructions for SqlPackage.exe.
        It will use the "c:\Temp\AxDB.dacpac" as the Path parameter.
        It will use the "c:\Temp\publish.xml" as the PublishFile parameter, which contains advanced configuration instructions for SqlPackage.exe.
        
        This is used to enable full restore / publish, but to avoid some of the common pitfalls.
        
    .NOTES
        Tags: Database, Dacpac, Tier1, Tier2, Golden Config, Config, Configuration
        
        Author: Mötz Jensen (@Splaxi)
#>
function Import-D365Dacpac {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("Dacpac")]
        [Alias("File")]
        [string] $Path,

        [string] $ModelFile,

        [Alias("ProfileFile")]
        [string] $PublishFile,

        [string] $DiagnosticFile,

        [int] $MaxParallelism = 8,

        [string] $DatabaseServer = $Script:DatabaseServer,

        [string] $DatabaseName = $Script:DatabaseName,

        [string] $SqlUser = $Script:DatabaseUserName,

        [string] $SqlPwd = $Script:DatabaseUserPassword,

        [Alias('LogDir')]
        [string] $LogPath = $(Join-Path -Path $Script:DefaultTempPath -ChildPath "Logs\ImportDacpac"),

        [switch] $ShowOriginalProgress,

        [switch] $OutputCommandOnly,

        [switch] $EnableException
    )

    if (-not (Test-PathExists -Path $Path -Type Leaf)) {
        return
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
        Action         = "Publish"
        FilePath       = $Path
        MaxParallelism = $MaxParallelism
    }

    if ($DiagnosticFile) {
        if (-not (Test-PathExists -Path (Split-Path $DiagnosticFile -Parent) -Type Container -Create)) { return }
        
        $ImportParams.DiagnosticFile = $DiagnosticFile
    }

    if ($ModelFile) {
        if (-not (Test-PathExists -Path $ModelFile -Type Leaf)) { return }

        $ImportParams.ModelFile = $ModelFile
    }

    if ($PublishFile) {
        if (-not (Test-PathExists -Path $PublishFile -Type Leaf)) { return }

        $ImportParams.PublishFile = $PublishFile
    }

    if (Test-PSFFunctionInterrupt) { return }
    
    Write-PSFMessage -Level Verbose "Start publishing the dacpac"
    Invoke-SqlPackage @BaseParams @ImportParams -TrustedConnection $UseTrustedConnection -ShowOriginalProgress:$ShowOriginalProgress -OutputCommandOnly:$OutputCommandOnly -LogPath $LogPath

    if ($OutputCommandOnly) { return }

    if (Test-PSFFunctionInterrupt) { return }
    
    Write-PSFMessage -Level Verbose "Importing completed"

    Invoke-TimeSignal -End
}
# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCALYXNM55W76mS6
# k37602hUT0dHqNawHKXMb5d/4HVRYqCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKJKx4ft7n6C
# g9MU3QBdXW1sDzududRd0iCfc+7wzm3LMA0GCSqGSIb3DQEBAQUABIICAL3kVang
# 9xlX7CotqkIeLgPR3fOvQ4OPjQ+Agp6+2ZyOu7zITnXLuekDHMBJnYa+ySczqAGr
# u4AJ3UQ7SQ/Pp+5xRVnzpjig905MqUipQxi77jqZ9M/PE68XfU9aJv8zfLWJ7Ysx
# rvMw9C3sAd7m+HDaX9J7wH9kF0k26gVUAFIUgG9el0cznuey7eQhar+dagk/qZtU
# XAtA4ucu+jqnuSd75hFoCwevutBpSPjXdtTUrimi/fIfhKeY6ADpdLNTPdGpTdfD
# NW3X3POsvAxyt8SIt3bYtiSq2JQuaudhExkEaGJwdnHhYTQsqYgICsz/xHISuTte
# dtai7xkXqQO2taUo1AtpW1kbgbmOd9kIqTYosDTvpZ9bnzD4ZFKXTficbkuuxel7
# +/TQAqzvLz2XnBqS7564/nedJDgrOI4DswMaZRIhSiaNXSyBGun+WMl/Au3Z9cYB
# 8k71HlynqWxdH+jluseAEU7c/hr8zTyFMEUjxSyzfNrl4D8ikgtw5Lv2cq0b8hTn
# 0Cp+MPE8MAkiz8HVREFkOnQtQr3m6UiBIW9CaSbK+kppfuhECOH4B5x+JqsIJobw
# hcQwXXUxj+GCNq/G8JYgpp6x+7DV+p2fKXU4J1F7NE8esZS3MCqVmSCIkmjnCO9g
# /Yo5L9vt14d/6QpYxETe4VZaklnOKGHiwJzroYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMjY1NlowLwYJKoZIhvcNAQkEMSIEIC0pdUMKy6ORSz+6KM7DIcTcfd6U
# WkdI/xykHYeaHHUbMA0GCSqGSIb3DQEBAQUABIICADnKMTz2HE895bmTHlfDuXcu
# WLEoA48sM+3oBWr6FRI0r67X+ZccKgyjnPJt4zIvcDIubmJvbUWpZwdQPSaB/OnP
# ylwGEzwdZCU4SLtCXNx0vwK0QKIvuDGzdxo09QhvjfE6x5aGdpdHrJzWKwMtC2Xi
# fDwEqks8dOMH4Ll7gyDO/uXUe+DrAQlZ/MNPddVx+B1q737oE26nYfVw9F7ryA6n
# YxsRVxKcLcKuh50jjSUUz5BGDOsx58MWQI602jJFDky1E0WaXNSd6UFd9rGCkv2O
# H00CrPaNrrt9qt7Wadnsscm7TELAnQGcU2UhnUJ3Hab5+71qAevM7LRAIwkgoOUl
# vhOeW4sdWXTAchS6l7W1XDbkwvKBKNa4GydV7BLZn502keMwlpIOe9mhtT9J3nPe
# 3xj+mgVKEIzrzCHME4AixX10wPRTF6eTg/OZsSGuPJL5K0NW4uKOTakk6gWvGftP
# CR+Y6H9beJjzijlkScXizNa7ml8xQhTyaQ91wU/x896OhZWS6Mhv/lhSEDED1bWa
# UVwgdfz+0t0Hl/C9j/A3Z1p/CIZg/KXUW5LbPlcgmsuKH7n/bvgv2HvOlwuIfurv
# JcKvsEe9z3O5/WhWEOV/Zz+c9soCXv+IM52jcQXB8MmqjniTKZjaC2jfzOC37qm7
# qfT4AEm+b7H46dDmyxjq
# SIG # End signature block
