
<#
    .SYNOPSIS
        Invoke the AxUpdateInstaller.exe file from Software Deployable Package (SDP)
        
    .DESCRIPTION
        A cmdlet that wraps some of the cumbersome work into a streamlined process.
        The process are detailed in the Microsoft documentation here:
        https://docs.microsoft.com/en-us/dynamics365/unified-operations/dev-itpro/deployment/install-deployable-package
        
    .PARAMETER Path
        Path to the update package that you want to install into the environment
        
        The cmdlet supports a path to a zip-file or directory with the unpacked contents.
        
    .PARAMETER MetaDataDir
        The path to the meta data directory for the environment
        
        Default path is the same as the aos service PackagesLocalDirectory
        
    .PARAMETER QuickInstallAll
        Use this switch to let the runbook reside in memory. You will not get a runbook on disc which you can examine for steps
        
    .PARAMETER DevInstall
        Use this when running on developer box without administrator privileges (Run As Administrator)
        
    .PARAMETER Command
        The command you want the cmdlet to execute when it runs the AXUpdateInstaller.exe
        
        Valid options are:
        SetTopology
        Generate
        Import
        Execute
        RunAll
        ReRunStep
        SetStepComplete
        Export
        VersionCheck
        
        The default value is "SetTopology"
        
    .PARAMETER Step
        The step number that you want to work against
        
    .PARAMETER RunbookId
        The runbook id of the runbook that you want to work against
        
        Default value is "Runbook"
        
    .PARAMETER LogPath
        The path where the log file(s) will be saved
        
        When running without the ShowOriginalProgress parameter, the log files will be the standard output and the error output from the underlying tool executed
        
    .PARAMETER ShowOriginalProgress
        Instruct the cmdlet to show the standard output in the console
        
        Default is $false which will silence the standard output
        
    .PARAMETER OutputCommandOnly
        Instruct the cmdlet to only output the command that you would have to execute by hand
        
        Will include full path to the executable and the needed parameters based on your selection
        
    .EXAMPLE
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\package.zip" -QuickInstallAll
        
        This will install the package contained in the c:\temp\package.zip file using a runbook in memory while executing.
        
    .EXAMPLE
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\" -DevInstall
        
        This will install the extracted package in c:\temp\ using a runbook in memory while executing.
        
        This command is to be used on Microsoft Hosted Tier1 development environment, where you don't have access to the administrator user account on the vm.
        
    .EXAMPLE
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\" -Command SetTopology
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\" -Command Generate -RunbookId 'MyRunbook'
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\" -Command Import -RunbookId 'MyRunbook'
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\" -Command Execute -RunbookId 'MyRunbook'
        
        Manual operations that first create Topology XML from current environment, then generate runbook with id 'MyRunbook', then import it and finally execute it.
        
    .EXAMPLE
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\" -Command RunAll
        
        Create Topology XML from current environment. Using default runbook id 'Runbook' and run all the operations from generate, to import to execute.
        
    .EXAMPLE
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\" -Command RerunStep -Step 18 -RunbookId 'MyRunbook'
        
        Rerun runbook with id 'MyRunbook' from step 18.
        
    .EXAMPLE
        PS C:\> Invoke-D365SDPInstall -Path "c:\temp\" -Command SetStepComplete -Step 24 -RunbookId 'MyRunbook'
        
        Mark step 24 complete in runbook with id 'MyRunbook' and continue the runbook from the next step.
        
        
    .NOTES
        Author: Tommy Skaue (@skaue)
        Author: Mötz Jensen (@Splaxi)
        
        Inspired by blogpost http://dev.goshoom.net/en/2016/11/installing-deployable-packages-with-powershell/
        
#>
function Invoke-D365SDPInstall {
    [CmdletBinding(DefaultParameterSetName = 'QuickInstall')]
    param (
        [Parameter(Mandatory = $True, Position = 1 )]
        [Alias('Hotfix')]
        [Alias('File')]
        [string] $Path,

        [Parameter(Mandatory = $false, Position = 2 )]
        [string] $MetaDataDir = "$Script:MetaDataDir",

        [Parameter(Mandatory = $false, ParameterSetName = 'QuickInstall', Position = 3 )]
        [switch] $QuickInstallAll,

        [Parameter(Mandatory = $false, ParameterSetName = 'DevInstall', Position = 3 )]
        [switch] $DevInstall,

        [Parameter(Mandatory = $true, ParameterSetName = 'Manual', Position = 3 )]
        [ValidateSet('SetTopology', 'Generate', 'Import', 'Execute', 'RunAll', 'ReRunStep', 'SetStepComplete', 'Export', 'VersionCheck')]
        [string] $Command = 'SetTopology',

        [Parameter(Mandatory = $false, Position = 4 )]
        [int] $Step,
        
        [Parameter(Mandatory = $false, Position = 5 )]
        [string] $RunbookId = "Runbook",

        [Alias('LogDir')]
        [string] $LogPath = $(Join-Path -Path $Script:DefaultTempPath -ChildPath "Logs\SdpInstall"),

        [switch] $ShowOriginalProgress,

        [switch] $OutputCommandOnly
    )
    
    if ((Get-Process -Name "devenv" -ErrorAction SilentlyContinue).Count -gt 0) {
        Write-PSFMessage -Level Host -Message "It seems that you have a <c='em'>Visual Studio</c> running. Please ensure <c='em'>exit</c> Visual Studio and run the cmdlet again."
        Stop-PSFFunction -Message "Stopping because of running Visual Studio."
        return
    }

    Test-AssembliesLoaded

    if (Test-PSFFunctionInterrupt) {
        Write-PSFMessage -Level Host -Message "It seems that you have executed some cmdlets that required to <c='em'>load</c> some Dynamics 356 Finance & Operations <c='em'>assemblies</c> into memory. Please <c='em'>close and restart</c> you PowerShell session / console, and <c='em'>start a fresh</c>. Please note that you should execute the failed command <c='em'>immediately</c> after importing the module."
        Stop-PSFFunction -Message "Stopping because of loaded assemblies."
        return
    }

    $arrRunbookIds = Get-D365Runbook -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Get-D365RunbookId

    if (($Command -eq "RunAll") -and ($arrRunbookIds.Runbookid -contains $RunbookId)) {
        Write-PSFMessage -Level Host -Message "It seems that you have entered an <c='em'>already used RunbookId</c>. Please consider if you are <c='em'>trying to re-run some steps</c> or simply pass <c='em'>another RunbookId</c>."
        Stop-PSFFunction -Message "Stopping because of RunbookId already used on this machine."
        return
    }

    Invoke-TimeSignal -Start

    #Test if input is a zipFile that needs to be extracted first
    if ($Path.EndsWith(".zip")) {
        Unblock-File -Path $Path
        
        $extractedPath = $path.Remove($path.Length - 4)
        if (!(Test-Path $extractedPath)) {
            Expand-Archive -Path $Path -DestinationPath $extractedPath
            
            #lets work with the extracted directory from now on
            $Path = $extractedPath
        }
    }

    # Input is a relative path which needs to be converted to an absolute path.
    # see https://powershellmagazine.com/2013/01/16/pstip-check-if-the-path-is-relative-or-absolute/
    if (-not ([System.IO.Path]::IsPathRooted($Path) -or (Split-Path -Path $Path -IsAbsolute))) {
        $currentPath = Get-Location
        # https://stackoverflow.com/a/13847304/2720554
        $absolutePath = Join-Path -Path $currentPath -ChildPath $Path
        $absolutePath = [System.IO.Path]::GetFullPath($absolutePath)
        Write-PSFMessage -Level Verbose "Updating path to '$absolutePath' as relative paths are not supported"
        $Path = $absolutePath
    }

    # $Util = Join-Path $Path "AXUpdateInstaller.exe"
    $executable = Join-Path $Path "AXUpdateInstaller.exe"

    $topologyFile = Join-Path $Path 'DefaultTopologyData.xml'

    if (-not (Test-PathExists -Path $topologyFile, $executable -Type Leaf)) { return }
        
    Get-ChildItem -Path $Path -Recurse | Unblock-File

    if ($QuickInstallAll) {
        Write-PSFMessage -Level Verbose "Using QuickInstallAll mode"
        $params = "quickinstallall"

        Invoke-Process -Executable $executable -Params $params -ShowOriginalProgress:$ShowOriginalProgress -OutputCommandOnly:$OutputCommandOnly -LogPath $LogPath
    }
    elseif ($DevInstall) {
        Write-PSFMessage -Level Verbose "Using DevInstall mode"
        $params = "devinstall"

        Invoke-Process -Executable $executable -Params $params -ShowOriginalProgress:$ShowOriginalProgress -OutputCommandOnly:$OutputCommandOnly -LogPath $LogPath
    }
    else {
        $Command = $Command.ToLowerInvariant()
        $runbookFile = Join-Path $Path "$runbookId.xml"
        $serviceModelFile = Join-Path $Path 'DefaultServiceModelData.xml'
        $topologyFile = Join-Path $Path 'DefaultTopologyData.xml'
                        
        if ($Command -eq 'runall') {
            Write-PSFMessage -Level Verbose "Running all manual steps in one single operation"

            #Update topology file (first command)
            $ok = Update-TopologyFile -Path $Path

            if ($ok) {
                $params = @(
                    "generate"
                    "-runbookId=`"$runbookId`""
                    "-topologyFile=`"$topologyFile`""
                    "-serviceModelFile=`"$serviceModelFile`""
                    "-runbookFile=`"$runbookFile`""
                )
                
                #Generate (second command)
                Invoke-Process -Executable $executable -Params $params -ShowOriginalProgress:$ShowOriginalProgress -OutputCommandOnly:$OutputCommandOnly -LogPath $LogPath

                if (Test-PSFFunctionInterrupt) { return }

                $params = @(
                    "import"
                    "-runbookFile=`"$runbookFile`""
                )

                Invoke-Process -Executable $executable -Params $params -ShowOriginalProgress:$ShowOriginalProgress -OutputCommandOnly:$OutputCommandOnly -LogPath $LogPath

                if (Test-PSFFunctionInterrupt) { return }

                $params = @(
                    "execute"
                    "-runbookId=`"$runbookId`""
                )

                Invoke-Process -Executable $executable -Params $params -ShowOriginalProgress:$ShowOriginalProgress -OutputCommandOnly:$OutputCommandOnly -LogPath $LogPath

                if (Test-PSFFunctionInterrupt) { return }
            }

            Write-PSFMessage -Level Verbose "All manual steps complete."
        }
        else {
            $RunCommand = $true
            switch ($Command) {
                'settopology' {
                    Write-PSFMessage -Level Verbose "Updating topology file xml."
                   
                    $ok = Update-TopologyFile -Path $Path
                    $RunCommand = $false
                }
                'generate' {
                    Write-PSFMessage -Level Verbose "Generating runbook file."
                    
                    $params = @(
                        "generate"
                        "-runbookId=`"$runbookId`""
                        "-topologyFile=`"$topologyFile`""
                        "-serviceModelFile=`"$serviceModelFile`""
                        "-runbookFile=`"$runbookFile`""
                    )
                }
                'import' {
                    Write-PSFMessage -Level Verbose "Importing runbook file."
                    
                    $params = @(
                        "import"
                        "-runbookfile=`"$runbookFile`""
                    )
                }
                'execute' {
                    Write-PSFMessage -Level Verbose "Executing runbook file."
                   
                    $params = @(
                        "execute"
                        "-runbookId=`"$runbookId`""
                    )
                }
                'rerunstep' {
                    Write-PSFMessage -Level Verbose "Rerunning runbook step number $step."
                   
                    $params = @(
                        "execute"
                        "-runbookId=`"$runbookId`""
                        "-rerunstep=$step"
                    )
                }
                'setstepcomplete' {
                    Write-PSFMessage -Level Verbose "Marking step $step complete and continuing from next step."
                   
                    $params = @(
                        "execute"
                        "-runbookId=`"$runbookId`""
                        "-setstepcomplete=$step"
                    )
                }
                'export' {
                    Write-PSFMessage -Level Verbose "Exporting runbook for reuse."

                    $params = @(
                        "export"
                        "-runbookId=`"$runbookId`""
                        "-runbookfile=`"$runbookFile`""
                    )
                }
                'versioncheck' {
                    Write-PSFMessage -Level Verbose "Running version check on runbook."
                    
                    $params = @(
                        "execute"
                        "-runbookId=`"$runbookId`""
                        "-versioncheck=true"
                    )
                }
            }

            if ($RunCommand) {
                Invoke-Process -Executable $executable -Params $params -ShowOriginalProgress:$ShowOriginalProgress -OutputCommandOnly:$OutputCommandOnly -LogPath $LogPath

                if (Test-PSFFunctionInterrupt) { return }
            }
        }
    }

    Invoke-TimeSignal -End
    
}
# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA4zBfA7bYQHcgG
# ywHvXJER/SxZWAE5voNsrC/BQiD7sKCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGrVDefrF9Il
# MykJw5OI5FaBISP+WVNQS2DX8oKQp99UMA0GCSqGSIb3DQEBAQUABIICAGyTEReS
# NpVBewNuPMr8Z6yPTF/jZi6ArqvqwXwzpw8kI30l6NrKAucI/Nyn3JpLJosZ9AcT
# tE3o9N3kOVZZOgzAiabfmOcMvhol5oDgPU1fSCNhSyX5wQbPN2r6f/ITnrI2eohN
# 74qvUx330UJjnPYQj5NOwMXGx0Lgr7/UQ5HUxNdwEVFNb+GRQXpVlXh8TvG+ziRW
# R88vIHs5R2y7rZHK+Alv0tPtIjlUy+X6PzDK0PwGJjsC88mFPDBONkEwZmHMjNje
# shZ7+M8kJJ1ddxLU7UAU1GKXhLfK1cpckMgDAVntup8qZitN0IdZOS7RbKZx1KyK
# GaFngANmXGCgU9tjOwkv8+quibA300RYWBmI9HBr7QU67JoYNlZl200bijo3216A
# 2To0BneAzYkfvGc3bTFvNbL2qXRbRiDpPCEepTGYTIMft9+6rl95QgZ8fNf3uOUm
# 2QdHib5WDs+Tw/1BjXzk72+Fd7WBVNcJZJ0s9YPCy67rwIO76g3geYvS0JWDVCov
# 7Yy6hTQPTDaj2Vclwzu0STPgtZGzy+yhIDSp9Kv1SwBheTtnmkZFBoxY3Et1fsH3
# 7Bb3G7zwmha1fKo8El6ZXY2V2tVJjQ8mPwK9YiHrUhKakvks70dux4C39bhiVihc
# oUgzjqH1gQ0yUEBzhZZkNLWwCRbdz/rYUdy0oYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMjczOFowLwYJKoZIhvcNAQkEMSIEIEm+NBLtenmvYmZoOGO+RLIu4Ce+
# 9AJB6IjdTEM++My5MA0GCSqGSIb3DQEBAQUABIICAJBTtRROJv0JT8PswLmtD4as
# aYyyyyDkpGS/4vTFb/XAKum2HMdbGk1qGsLEterk8U9B4XaxePY4jPsRovaBUlnI
# 9nwv6kJJHpOJE02Uu4jyEdt6LQrs8s3nmVufUa2/mSdjxpOuyzGpJUetvSEiEKkn
# WMz/IfyaAo9uc5w7brIGvq5TluZjuypjyzxGqzoQStcL5nxx8fzspmuuZwh5Yniu
# FOUWF3Ip4mQmjJSIqIDN1UMgMoCzMfQ2ssI8Kvl4qarqKyVZmD5HeOOJ5iu0+5uR
# p0mZww3f4u4IMjJZ0Lz5TJXtW1rmEDaMo3YJw5+utlGg+s6W4y/VjnmF8yB4y5n0
# 0r3SzbfpPEalVbWs9un0XgMbSzEjJTmv+Dvlg6lWew0c0uNSg5TAoYkwI98jokfM
# SINAegBdG/b7kXfL/H9D8z/qkti4QmKleyAc5slyh8+xsq6NJTudiWoRyiOblRw6
# Ss3Nf+rFYOE1JdzE2sF2jEwQmRCLb+DuCxJOzNsnhMY1rk34WBrG8X7KGUd3HfJQ
# j3Hk33926S0Q475STK+y9flJIiRI8+ZNvYBtu3zMSUNFvF1woafANLdG/Ocv0dHt
# v7PCE/qif5m4EOhwIx7rja/cd18hLkFnG5mPn0w/DuPYWugX9ZhZ7IT8ZPbhRp+Z
# KuZyuVJV3ktkzTB4twzv
# SIG # End signature block
