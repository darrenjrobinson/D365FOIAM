
<#
    .SYNOPSIS
        Get tables from the bacpac file
        
    .DESCRIPTION
        Get tables and their metadata from the bacpac file
        
        Metadata as in original size and compressed size, which are what size the bulk files are and will only indicate what you can expect of the table size
        
    .PARAMETER Path
        Path to the bacpac file that you want to work against
        
        It can also be a zip file
        
    .PARAMETER Table
        Name of the table that you want to delete the data for
        
        Supports an array of table names
        
        If a schema name isn't supplied as part of the table name, the cmdlet will prefix it with "dbo."
        
        Supports wildcard searching e.g. "Sales*" will locate all "dbo.Sales*" tables in the bacpac file
        
    .PARAMETER Top
        Instruct the cmdlet with how many tables you want returned
        
        Default is [int]::max, which translates into all tables present inside the bapcac file
        
    .PARAMETER SortSizeAsc
        Instruct the cmdlet to sort the output by size (original) ascending
        
    .PARAMETER SortSizeDesc
        Instruct the cmdlet to sort the output by size (original) descending
        
    .EXAMPLE
        PS C:\> Get-D365BacpacTable -Path "c:\Temp\AxDB.bacpac"
        
        This will return all tables from inside the bacpac file.
        
        It uses "c:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses the default value "*" as the Table parameter, to output all tables.
        It uses the default value "[int]::max" as the Top parameter, to output all tables.
        It uses the default sort, which is by name acsending.
        
        A result set example:
        
        Name                                                                   OriginalSize CompressedSize BulkFiles
        ----                                                                   ------------ -------------- ---------
        ax.DBVERSION                                                                   62 B           52 B         1
        crt.RETAILUPGRADEHISTORY                                                   13,49 MB       13,41 MB         3
        dbo.__AOSMESSAGEREGISTRATION                                                1,80 KB          540 B         2
        dbo.__AOSSTARTUPVERSION                                                         4 B            6 B         1
        dbo.ACCOUNTINGDISTRIBUTION                                                 48,60 MB        4,50 MB        95
        dbo.ACCOUNTINGEVENT                                                        11,16 MB        1,51 MB       128
        dbo.AGREEMENTPARAMETERS_RU                                                    366 B          113 B         1
        dbo.AIFSQLCDCENABLEDTABLES                                                 13,63 KB        2,19 KB         1
        dbo.AIFSQLCHANGETRACKINGENABLEDTABLES                                       9,89 KB        1,42 KB         1
        dbo.AIFSQLCTTRIGGERS                                                       44,75 KB        6,29 KB         1
        
    .EXAMPLE
        PS C:\> Get-D365BacpacTable -Path "c:\Temp\AxDB.bacpac" -SortSizeAsc
        
        This will return all tables from inside the bacpac file, sorted by the original size, ascending.
        
        It uses "c:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses the default value "*" as the Table parameter, to output all tables.
        It uses the default value "[int]::max" as the Top parameter, to output all tables.
        It uses the SortSizeAsc parameter, which is by original size acsending.
        
        A result set example:
        
        Name                                                                   OriginalSize CompressedSize BulkFiles
        ----                                                                   ------------ -------------- ---------
        dbo.__AOSSTARTUPVERSION                                                         4 B            6 B         1
        dbo.SYSSORTORDER                                                               20 B           20 B         1
        dbo.SECURITYDATABASESETTINGS                                                   20 B           12 B         1
        dbo.SYSPOLICYSEQUENCEGROUP                                                     24 B           10 B         1
        dbo.SYSFILESTOREPARAMETERS                                                     26 B           10 B         1
        dbo.SYSHELPCPSSETUP                                                            28 B           15 B         1
        dbo.DATABASELOGPARAMETERS                                                      28 B           10 B         1
        dbo.FEATUREMANAGEMENTPARAMETERS                                                28 B           10 B         1
        dbo.AIFSQLCTVERSION                                                            28 B           24 B         1
        dbo.SYSHELPSETUP                                                               28 B           15 B         1
        
    .EXAMPLE
        PS C:\> Get-D365BacpacTable -Path "c:\Temp\AxDB.bacpac" -SortSizeDesc
        
        This will return all tables from inside the bacpac file, sorted by the original size, descending.
        
        It uses "c:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses the default value "*" as the Table parameter, to output all tables.
        It uses the default value "[int]::max" as the Top parameter, to output all tables.
        It uses the SortSizeDesc parameter, which is by original size descending.
        
        A result set example:
        
        Name                                                                   OriginalSize CompressedSize BulkFiles
        ----                                                                   ------------ -------------- ---------
        dbo.TSTIMESHEETLINESTAGING                                                 35,31 GB        2,44 GB      9077
        dbo.RESROLLUP                                                              13,30 GB      367,19 MB      3450
        dbo.PROJECTSTAGING                                                         11,31 GB      508,70 MB      2929
        dbo.TSTIMESHEETTABLESTAGING                                                 5,93 GB      246,65 MB      1564
        dbo.BATCHHISTORY                                                            5,80 GB      234,99 MB      1529
        dbo.HCMPOSITIONHIERARCHYSTAGING                                             5,16 GB      222,18 MB      1358
        dbo.ERLCSFILEASSETTABLE                                                     3,15 GB      217,68 MB       302
        dbo.EVENTINBOX                                                              2,92 GB      105,63 MB       747
        dbo.HCMPOSITIONV2STAGING                                                    2,79 GB      200,27 MB       755
        dbo.HCMEMPLOYEESTAGING                                                      2,49 GB      218,69 MB       677
        
    .EXAMPLE
        PS C:\> Get-D365BacpacTable -Path "c:\Temp\AxDB.bacpac" -SortSizeDesc -Top 5
        
        This will return all tables from inside the bacpac file, sorted by the original size, descending.
        
        It uses "c:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses the default value "*" as the Table parameter, to output all tables.
        It uses the value 5 as the Top parameter, to output only 5 tables, based on the sorting selected.
        It uses the SortSizeDesc parameter, which is by original size descending.
        
        A result set example:
        
        Name                                                                   OriginalSize CompressedSize BulkFiles
        ----                                                                   ------------ -------------- ---------
        dbo.TSTIMESHEETLINESTAGING                                                 35,31 GB        2,44 GB      9077
        dbo.RESROLLUP                                                              13,30 GB      367,19 MB      3450
        dbo.PROJECTSTAGING                                                         11,31 GB      508,70 MB      2929
        dbo.TSTIMESHEETTABLESTAGING                                                 5,93 GB      246,65 MB      1564
        dbo.BATCHHISTORY                                                            5,80 GB      234,99 MB      1529
        
    .EXAMPLE
        PS C:\> Get-D365BacpacTable -Path "c:\Temp\AxDB.bacpac" -Table "Sales*"
        
        This will return all tables which matches the "Sales*" wildcard search from inside the bacpac file.
        
        It uses "c:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses the default value "Sales*" as the Table parameter, to output all tables that matches the wildcard pattern.
        It uses the default value "[int]::max" as the Top parameter, to output all tables.
        It uses the default sort, which is by name acsending.
        
        A result set example:
        
        Name                                                                   OriginalSize CompressedSize BulkFiles
        ----                                                                   ------------ -------------- ---------
        dbo.SALESPARAMETERS                                                         4,29 KB          310 B         1
        dbo.SALESPARMUPDATE                                                       273,48 KB       24,21 KB         1
        dbo.SALESQUOTATIONTOLINEPARAMETERS                                          4,18 KB          596 B         1
        dbo.SALESSUMMARYPARAMETERS                                                  2,95 KB          425 B         1
        dbo.SALESTABLE                                                              1,20 KB          313 B         1
        dbo.SALESTABLE_W                                                              224 B           60 B         1
        dbo.SALESTABLE2LINEPARAMETERS                                               4,46 KB          637 B         1
        
    .EXAMPLE
        PS C:\> Get-D365BacpacTable -Path "c:\Temp\AxDB.bacpac" -Table "Sales*","CUSTINVOICE*"
        
        This will return all tables which matches the "Sales*" and "CUSTINVOICE*" wildcard searches from inside the bacpac file.
        
        It uses "c:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses the default value "Sales*" and "CUSTINVOICE*" as the Table parameter, to output all tables that matches the wildcard pattern.
        It uses the default value "[int]::max" as the Top parameter, to output all tables.
        It uses the default sort, which is by name acsending.
        
        A result set example:
        
        Name                                                                   OriginalSize CompressedSize BulkFiles
        ----                                                                   ------------ -------------- ---------
        dbo.CUSTINVOICEJOUR                                                         2,01 MB      118,87 KB         1
        dbo.CUSTINVOICELINE                                                        14,64 MB      975,30 KB         4
        dbo.CUSTINVOICELINEINTERPROJ                                                6,58 MB      477,97 KB         2
        dbo.CUSTINVOICETABLE                                                        1,06 MB       56,56 KB         1
        dbo.CUSTINVOICETRANS                                                       32,34 MB        1,51 MB        54
        dbo.SALESPARAMETERS                                                         4,29 KB          310 B         1
        dbo.SALESPARMUPDATE                                                       273,48 KB       24,21 KB         1
        dbo.SALESQUOTATIONTOLINEPARAMETERS                                          4,18 KB          596 B         1
        dbo.SALESSUMMARYPARAMETERS                                                  2,95 KB          425 B         1
        dbo.SALESTABLE                                                              1,20 KB          313 B         1
        dbo.SALESTABLE_W                                                              224 B           60 B         1
        dbo.SALESTABLE2LINEPARAMETERS                                               4,46 KB          637 B         1
        
    .EXAMPLE
        PS C:\> Get-D365BacpacTable -Path "c:\Temp\AxDB.bacpac" -Table "SalesTable","CustTable"
        
        This will return the tables "dbo.SalesTable" and "dbo.CustTable" from inside the bacpac file.
        
        It uses "c:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses the default value "SalesTable" and "CustTable" as the Table parameter, to output the tables that matches the names.
        It uses the default value "[int]::max" as the Top parameter, to output all tables.
        It uses the default sort, which is by name acsending.
        
        A result set example:
        
        Name                                                                   OriginalSize CompressedSize BulkFiles
        ----                                                                   ------------ -------------- ---------
        dbo.CUSTTABLE                                                             154,91 KB        8,26 KB         1
        dbo.SALESTABLE                                                              1,20 KB          313 B         1
        
    .NOTES
        Tags: Bacpac, Servicing, Data, SqlPackage, Table, Size, Troubleshooting
        
        Author: Mötz Jensen (@Splaxi)
        
#>
function Get-D365BacpacTable {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('File')]
        [Alias('BacpacFile')]
        [string] $Path,

        [string[]] $Table = "*",

        [int] $Top = [int]::MaxValue,

        [Parameter(ParameterSetName = "SortSizeAsc")]
        [switch] $SortSizeAsc,

        [Parameter(ParameterSetName = "SortSizeDesc")]
        [switch] $SortSizeDesc

    )
    
    begin {
        if (-not (Test-PathExists -Path $Path -Type Leaf)) { return }

        if (Test-PSFFunctionInterrupt) { return }

        $file = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open)

        $zipArch = [System.IO.Compression.ZipArchive]::new($file)
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        $bulkFilesArray = New-Object System.Collections.Generic.List[System.Object]

        foreach ($item in $table) {

            $fullTableName = ""

            if ($item -eq "*") {
                $fullTableName = $item
            }
            elseif (-not ($item -like "*.*")) {
                $fullTableName = "dbo.$item"
            }
            else {
                $fullTableName = $item
            }
            
            Write-PSFMessage -Level Verbose -Message "Looking for $fullTableName."

            $entries = $zipArch.Entries | Where-Object Fullname -like "Data/$fullTableName/*"

            $bulkFilesArray.AddRange(@($($entries | Select-Object -Property *, @{Name = "Table"; Expression = { $_.FullName.Split("/")[1] } })))
        }

        $bulkFiles = $bulkFilesArray.ToArray() | Sort-Object -Property Fullname -Unique

        $grouped = $bulkFiles | Group-Object -Property Table

        $res = $grouped | ForEach-Object {
            [pscustomobject]@{ Name = $_.Name
                OriginalSize        = [PSFSize]$($_.Group.Length | Measure-Object -sum | Select-Object -ExpandProperty sum)
                CompressedSize      = [PSFSize]$($_.Group.CompressedLength | Measure-Object -sum | Select-Object -ExpandProperty sum)
                BulkFiles           = $_.Count
                PSTypeName          = 'D365FO.TOOLS.Bacpac.Table'
            }
        }

        if ($SortSizeAsc) {
            $res | Sort-Object OriginalSize | Select-Object -First $Top
        }
        elseif ($SortSizeDesc) {
            $res | Sort-Object OriginalSize -Descending | Select-Object -First $Top
        }
        else {
            $res | Sort-Object Name | Select-Object -First $Top
        }
    }
    
    end {
        if ($zipArch) {
            $bulkFilesArray.Clear()
            $bulkFilesArray = $null
            $zipArch.Dispose()
        }

        if ($file) {
            $file.Close()
            $file.Dispose()
        }
    }
}
# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC3G1WbJ8AJTU1/
# cpZtigk3U16nYjKm/gUxFjzGWce3gqCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGOOCmxtQLV8
# CB4g+/PTTEy9FUyjU71FZTLxYrRuBElPMA0GCSqGSIb3DQEBAQUABIICAHlCjLEP
# oajH0n6Eeew3+lWftSdPaE+ayLP4qzGnfZsE1F9+JVIg4bD2wJubhYGVhJnVLusD
# BplX69TDZL+lziA/3w3GhWgk9+gAGd7jrlkkvyUCTaXmTMCKWeDPZO39kyah0WiQ
# SgZFJZSiMY1cwJIROvsiogbf4hxJeNY1eEzJNiMwBoIx2rGtJ0kI8h50yMJBPR3x
# RD7GsXMXPRzE9R+MzaTMCntwjswZo/o8YXK8EwpfhkwINOMtRXMHeRDLXnyHCP2B
# 2ctLkEQcwc7N8ytUEfgS9L8n2TUOTC4yFv5zBFP8G/h6fCHUm/ZRIWy35T5cNk3i
# Y2QOKWvfYHH68C3vjqOPlCW6p4ehuqt3axwKLChXj9yfR5IQ8hW1U9LZZ/OWhA78
# bcSOlkmEI4GY4KqOVHG31dVpuqVtohE3WDieL35ylHemF0+qQJEL/ZviZGOKmiFr
# hJDj8sOv/r5DZlGf8Bos9lt3PuE5iHKLFAtlzqfoP/T+2U8Mym++20xivYoIdU60
# OrcsiGtdcuyk+70TPWaalc5iR7xWrFyM913s8XjZEjflua5atG9Y6ki6h/PAxs+X
# 02YVSWF48qefInMd3BbkAIF/H72QRoM5UGvPPeLf3bL9CLvMIgGawDj+nP+QyA3j
# Y4dgXF3Nalt27YVDjisn69sBxnMHKB8q3RYpoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMjYwNVowLwYJKoZIhvcNAQkEMSIEIFj81R6gmdx5PoHafn9UwhoDRwv2
# IGAp8HFPgK3YhmjqMA0GCSqGSIb3DQEBAQUABIICAAFy7XEtmD7wQlXFZOU4I1nL
# R9HC5i0z3fM/7Xyy6z8uh2xM27XL7rEPGNRmVKxRv82hJa0sHWCANF5bOiDTMFjw
# /CShk2JVyFkXhmDmGAA7DNmEO24qPMfQ6mPaZHt6YHAbd3HzY3v4SQAAJQ/4MICB
# GJ6w3V3p0wHW5uUbO8MlqQBtbNDHLqAfBQPX6m1XOpjuIMrVv8OHsUYDKij0Lrpr
# Z6ofJl3OTossC2jt9PooPeWVM56DucBNqMuhQKWlQf9ysI0D3e7RStnRGZixB9zj
# eQQcul0mOejuXXKwEnd60zUXr0CfDpbV7Uhl1OjrL+x6ZGwTiMV6ZiHpJeNIBebX
# c+rYr21iIvo99HGIQLW9lB6uYTjF03j+r/q0gX99oyJ8tNDG51/eb05XmPOCzvE3
# FhKhq0+1vglCxfwxVsqmk8DIpo9rm/EGIVFIc3Xm7SiypTkUL3iSoQMZLoimXxJ8
# Ss2OKZYaqd0MrC1DjcY4a/SOnp3aL1RAzDjaCIqwU2rAmRvpZimSMLVzWls7vAkx
# FNpDvzTLMDHhdMHW2WDrKD/DicyfhdlpQENNM4W7W/8Aayy3bSwoN1tM9G5N8gaR
# oBjj+z/hOrWdn1JKiZ5wA2ck6mjv4UF66MZelVePXEAUXW20sp/EZgMAk+ZIgFYu
# bbTtruKTWeRpG111ct2Z
# SIG # End signature block
