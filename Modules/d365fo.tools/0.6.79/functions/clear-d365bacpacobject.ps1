
<#
    .SYNOPSIS
        Clear out sql objects from inside the bacpac/dacpac or zip file
        
    .DESCRIPTION
        Remove a set of sql objects from inside a bacpac/dacpac or zip file, before restoring it into your SQL Server / Azure SQL DB
        
        It will open the file as a zip archive, locate the desired sql object and remove it, so when importing the bacpac the object will not be created
        
        The default behavior is that you get a copy of the file, where the desired sql objects are removed
        
    .PARAMETER Path
        Path to the bacpac/dacpac or zip file that you want to work against
        
    .PARAMETER Name
        Name of the sql object that you want to remove
        
        Supports an array of names
        
        If a schema name isn't supplied as part of the table name, the cmdlet will prefix it with "dbo."
        
        Some sql objects are 3 part named, which will require that you fill them in with brackets E.g. [dbo].[SalesTable].[CustomIndexName1]
        - Index
        - Constraints
        
    .PARAMETER ObjectType
        Instruct the cmdlet, the type of object that you want to remove
        
        As we are manipulating the bacpac file, we can only handle 1 ObjectType per run
        
        If you want to remove SqlView and SqlIndex, you will have to run the cmdlet 1 time for SqlViews and 1 time for SqlIndex
        
    .PARAMETER OutputPath
        Path to where you want the updated bacpac/dacpac or zip file to be saved
        
    .PARAMETER ClearFromSource
        Instruct the cmdlet to delete sql objects directly from the source file
        
        It will save disk space and time, because it doesn't have to create a copy of the bacpac file, before deleting sql objects from it
        
    .EXAMPLE
        PS C:\> Clear-D365BacpacObject -Path "C:\Temp\AxDB.bacpac" -ObjectType SqlView -Name "View2" -OutputPath "C:\Temp\AXBD_Cleaned.bacpac"
        
        This will remove the SqlView "View2" from inside the bacpac file.
        
        It uses "C:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses "View2" as the name of the object to delete.
        It uses "C:\Temp\AXBD_Cleaned.bacpac" as the OutputPath to where it will store the updated bacpac file.
        
    .EXAMPLE
        PS C:\> Clear-D365BacpacObject -Path "C:\Temp\AxDB.bacpac" -ObjectType SqlView -Name "dbo.View1","View2" -OutputPath "C:\Temp\AXBD_Cleaned.bacpac"
        
        This will remove the SqlView(s) "dbo.View1" and "View2" from inside the bacpac file.
        
        It uses "C:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses "dbo.View1","View2" as the names of objects to delete.
        It uses "C:\Temp\AXBD_Cleaned.bacpac" as the OutputPath to where it will store the updated bacpac file.
        
    .EXAMPLE
        PS C:\> Clear-D365BacpacObject -Path "C:\Temp\AxDB.bacpac" -ObjectType SqlIndex -Name "[dbo].[SalesTable].[CustomIndexName1]" -ClearFromSource
        
        This will remove the SqlIndex "CustomIndexName1" from the dbo.SalesTable table from inside the bacpac file.
        
        It uses "C:\Temp\AxDB.bacpac" as the Path for the bacpac file.
        It uses "[dbo].[SalesTable].[CustomIndexName1]" as the name of the object to delete.
        
        Caution:
        It will remove from the source "C:\Temp\AxDB.bacpac" directly. So if the original file is important for further processing, please consider the risks carefully.
        
    .NOTES
        It will NOT fail, if it can't find any object with the specified name
        
#>
function Clear-D365BacpacObject {
    [CmdletBinding(DefaultParameterSetName = "Copy")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('File')]
        [Alias('BacpacFile')]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [Alias("ObjectName")]
        [string[]] $Name,

        [ValidateSet("SqlView", "SqlTable", "SqlIndex", "SqlCheckConstraint")]
        [string] $ObjectType,

        [Parameter(Mandatory = $true, ParameterSetName = "Copy")]
        [string] $OutputPath,

        [Parameter(Mandatory = $true, ParameterSetName = "Keep")]
        [switch] $ClearFromSource
    )
    
    if (-not (Test-PathExists -Path $Path -Type Leaf)) { return }

    $compressPath = ""

    if ($ClearFromSource) {
        $compressPath = $Path
    }
    else {
        $compressPath = $OutputPath

        if (-not (Test-PathExists -Path $compressPath -Type Leaf -ShouldNotExist)) {
            Write-PSFMessage -Level Host -Message "The <c='em'>$compressPath</c> already exists. Consider changing the <c='em'>OutputPath</c> or <c='em'>delete</c> the <c='em'>$compressPath</c> file."
            return
        }

        if (Test-PSFFunctionInterrupt) { return }

        Write-PSFMessage -Level Verbose -Message "Copying the file from '$Path' to '$compressPath'"
        Copy-Item -Path $Path -Destination $compressPath
        Write-PSFMessage -Level Verbose -Message "Copying was completed."
    }
        
    Write-PSFMessage -Level Verbose -Message "Opening the file '$compressPath'."
    $file = [System.IO.File]::Open($compressPath, [System.IO.FileMode]::Open)
    $zipArch = [System.IO.Compression.ZipArchive]::new($file, [System.IO.Compression.ZipArchiveMode]::Update)
    Write-PSFMessage -Level Verbose -Message "File '$compressPath' was read succesfully."

    if (-not $zipArch) {
        $messageString = "Unable to open the file <c='em'>$compressPath</c>."
        Write-PSFMessage -Level Host -Message $messageString
        Stop-PSFFunction -Message "Stopping because the file couldn't be opened." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', '')))
        return
    }

    $pathWorkDirectory = "$([System.IO.Path]::GetTempPath())d365fo.tools\$([System.Guid]::NewGuid().Guid)"
        
    #Make sure the work path is created and available
    New-Item -Path $pathWorkDirectory -ItemType Directory -Force -ErrorAction Ignore > $null

    if (Test-PSFFunctionInterrupt) { return }
    
    Write-PSFMessage -Level Verbose -Message "Building the regex patterns to look for in the model.xml file."
    
    # Build the array of regex patterns that we are looking for
    # Has to be the same type
    $searchCol = @(
        foreach ($item in $Name) {
            $fullObjectName = ""

            if (-not ($item -like "*.*")) {
                $fullObjectName = "[dbo].[$item]"
            }
            elseif ($item -like "*.*" -and (-not ($item -match '\[.*?\]\.\[.*?\]') )) {
                #Throw error name format isn't as expected
                Throw
            }
            else {
                $fullObjectName = $item
            }

            $regexName = $fullObjectName.Replace("[", "\[").Replace("]", "\]").Replace(".", "\.")

            '<Element Type="{0}" Name="{1}">' -f $ObjectType, $regexName
        })

    # The model files defines all objects that will be created when importing the bacpac file
    $model = $zipArch.GetEntry("model.xml")

    Write-PSFMessage -Level Verbose -Message "Extracting local model.xml file."

    # We will have a local "model.raw.xml" file to read from
    $pathModelRaw = Join-Path -Path $pathWorkDirectory -ChildPath "model.raw.xml"
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($model, $pathModelRaw)

    # We will have a local "model.xml" where we persist the changes to
    $pathModelWorking = Join-Path -Path $pathWorkDirectory -ChildPath "model.xml"

    # The Origin.xml file is a manifest file, with a checksum value for the model.xml file inside the bacpac
    # Removing a single character from the model.xml file, will invalidate the checksum stored inside the Origin.xml
    $origin = $zipArch.GetEntry("Origin.xml")
        
    Write-PSFMessage -Level Verbose -Message "Extracting local Origin.xml file."

    # We will have a local "Origin.raw.xml" file to read from
    $pathOriginRaw = Join-Path -Path $pathWorkDirectory -ChildPath "Origin.raw.xml"
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($origin, $pathOriginRaw)

    # We will have a local "Origin.xml" where we persist the changes to
    $pathOriginWorking = Join-Path -Path $pathWorkDirectory -ChildPath "Origin.xml"

    # The model file is a very large XML file, reading that into a DOM object will slow down the operation
    # We will be reading the file line-by-line
    $reader = [System.IO.StreamReader]::new($pathModelRaw)
    $writer = [System.IO.StreamWriter]::new($pathModelWorking)

    # We need to know when to skip lines and at what indent to stop skipping lines
    $skipLine = $false
    $skipIdent = -1

    Write-PSFMessage -Level Verbose -Message "Starting the analysis of the model.xml file."

    :nextLine while ( -not $reader.EndOfStream) {
        $tmp = $reader.ReadLine()

        if ($skipLine) {
            # SkipLine indicates that we found the object that we want to remove
            # We need to search for the very first NEXT instance of "</Element>"

            if ($tmp -match "</Element>") {
                # We found a "</Element>", but there are several child elements

                if ($skipIdent -eq $tmp.IndexOf("<")) {
                    Write-PSFMessage -Level Verbose -Message "Skipping lines disabled. Correct close element found."

                    # The identication signals that we found the right "</Element>"

                    # Resitting the search signal/variables
                    $skipLine = $false
                    $skipIdent = -1
                    continue nextLine
                }
            }

            # We need to move forward with reading the file
            continue nextLine
        }

        foreach ($regex in $searchCol) {
            # searchCol contains ALL regex patterns that we want to remove from the model file
            # This is done to increase performance, as we only read the file onces, but validates each line multiple times

            if (($tmp -match $regex)) {
                Write-PSFMessage -Level Verbose -Message "Regex: $regex had a match. Skipping lines until close element found."

                # A match indicates that we found the next object that we want to remove

                # Setting the signal/variables - identication helps later to match to the correct "</Element>"
                $skipIdent = $tmp.IndexOf("<")
                $skipLine = $true
                continue nextLine
            }
        }

        # If skipLine and no regex was hit, we need to line in the updated model.xml file
        $writer.WriteLine($tmp)
    }
    
    # This concludes the entire update on the model.xml file
    $reader.Close()
    $writer.Flush()
    $writer.Close()

    Write-PSFMessage -Level Verbose -Message "Calculating hash value (checksum) for the updated model.xml file."

    # The model file will be checksum validated when running an import of it
    # We need to handle that
    $hashValue = Get-FileHash -Path $pathModelWorking -Algorithm SHA256 | Select-Object -ExpandProperty Hash

    # Loading the Origin.xml into memory
    [xml]$xmlDoc = Get-Content -Path $pathOriginRaw

    Write-PSFMessage -Level Verbose -Message "Updating the hash value (checksum) inside the Origin.xml file."

    # Updating the hash vaule (checksum) and saving it
    $xmlDoc.DacOrigin.Checksums.Checksum.InnerText = $hashValue
    $xmlDoc.Save($pathOriginWorking)

    Write-PSFMessage -Level Verbose -Message "Switching out the Origin.xml and model.xml files from inside the bacpac."

    # We need to remove the model.xml and origin.xml from the bacpac (archive)
    $model.Delete()
    $origin.Delete()

    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArch, $pathModelWorking, "model.xml") > $null
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArch, $pathOriginWorking, "Origin.xml") > $null

    if ($zipArch) {
        $zipArch.Dispose()
    }

    if ($file) {
        $file.Close()
        $file.Dispose()
    }

    if (Test-PSFFunctionInterrupt) { return }
    
    $res.File = $compressPath
    $res.Filename = $(Split-Path -Path $compressPath -Leaf)

    [PSCustomObject]$res
}
# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCClgnmDtilSWHv+
# n2amh9FJSiOjrw1yRby6f+Q1DA98DKCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMVxUTFwQ/2j
# 35fVga44dw42YkWpAYr+sR1DzH7jzFaZMA0GCSqGSIb3DQEBAQUABIICAFlRGEGR
# iaJoaiCszm1E5CR8LFIFEAIb1yqnJY3tmOc/GpGHca3JeSWxqBVj8IetZC4V5CzG
# FD88jOYwqTt/og4GncJdqftmHJ7sXyPt3TNkgxf/4QArJqIuASwybz5AgPr7pFPE
# LYF+n5RSrkwFZh+jNZ9r2DheojII7to3LGa8CXpcxcXZIhwiKxPREoh16jvEuQDW
# L3pyz8bDMLm7P+Toi6nOOGG81p1BnRFheHvL8wqpI7NWRim4dZ5aV2KpvXdd1p0I
# Hch+24NeBzX4Rz5Ran2MiWLyGvdSa/VhkAB4aqBi0CtqRpRdIUxNQGAlAOQrXdI8
# 5pSQghOxQkBuDa5Fg+Rqt47eTcfHFPZsOZSI6V2rF3ezEnZMJ90QrHoyhH6hd3/C
# pEpjHuzicqJXpV5fBHPG5i2ikYwUJFX5g6bR8f/h163i0vbxfQbPoIYcRD1GBNpZ
# io93uKrTMTmKDIo2eYg0vPmtzWOvGqrbR3YO3+IY5gl/H2u+uM268N15kiZh5vyy
# iGlPwmKpP6wVY1oFxkXOnEBFDfXQQFnCEMIxjebnNUwqucaGDMGbe8fVrMS6evhC
# PCU/FWRFhFTNdDTmsrV9j4aILtqdsOFO6RXs1YM16l/8aSmPOZGq2690F2tezoXi
# rfNfTtLWBTzaFJ8fYJN23d+sVykIj+YvOO4EoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMjU0NlowLwYJKoZIhvcNAQkEMSIEIPlIUB8w3mJ/V8WLDuDhqzkNVKR+
# v0EJTSfx1XfTPmUjMA0GCSqGSIb3DQEBAQUABIICACKd5s/NBcMD2EzObYN+83/x
# 3LT3pUwY53UysQrmOZ9+8CXt039ghg5x7rm9EXSsw8oqbYRnPXRCiHkfAQhdMPK2
# /VAom5w8hvDE9xG0onXZ7f65DLBpexC5F2WvW/7v/CpT7Ku96hQNYd/JdqjYmtAV
# L1jkccfGNVDxExGW7GVJwjA2mgKizqAK9m3R3lFQeOaw7GwhVEywculsoaDvNpzZ
# jwKKU2nFvl0We3jxAlsTMXyRZcjDneaaHF50vQ8efstBP4zS7ORzKX9Gt4mUfPr9
# qTp/JJERiPG/LZM2luZejLdJnGEnBgy7fBG4oIZ8VY7DVGblEHXBtOsLFZMBQocN
# ZocM+VMx9AVL0nZx8wL7adHJMYiLB7cuoOF/0txWxDRcwWvUl0Fy8uMtRlAGYgbJ
# p18Z7okJ8lyglZe/JHfEbhu+d3H1/SCHWFvIIHUVCrKrrSgWmneuwCSyzSgnyQSp
# ODlGbbD6UL9shmDXYLokKBFuTATY+KTC0LroElnTttsFBUNDj29CxgEPucCjhPQX
# 2TL0y4iBu7QOuTAGPa+SI3ojhe/dNH42ddJkt7jf92oDbHVwtZVsM2Tm6lh8iTuR
# pT7e058fVE6sTOrfYrkB/rebpnqpFlSuWshFi9VduX+fr2PW3XMy5+jp5oyYyjMg
# jvHREteO3Y5dAxBOyiGX
# SIG # End signature block
