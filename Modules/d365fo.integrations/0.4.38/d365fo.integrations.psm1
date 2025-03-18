$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '0.4.38'

$Script:TimeSignals = @{}

Set-PSFFeature -Name PSFramework.InheritEnableException -Value $true -ModuleName 'd365fo.integrations'

# Detect whether at some level dotsourcing was enforced
$script:doDotSource = Get-PSFConfigValue -FullName d365fo.integrations.Import.DoDotSource -Fallback $false
if ($d365fo.integrations_dotsourcemodule) { $script:doDotSource = $true }

<#
Note on Resolve-Path:
All paths are sent through Resolve-Path/Resolve-PSFPath in order to convert them to the correct path separator.
This allows ignoring path separators throughout the import sequence, which could otherwise cause trouble depending on OS.
Resolve-Path can only be used for paths that already exist, Resolve-PSFPath can accept that the last leaf my not exist.
This is important when testing for paths.
#>

# Detect whether at some level loading individual module files, rather than the compiled module was enforced
$importIndividualFiles = Get-PSFConfigValue -FullName d365fo.integrations.Import.IndividualFiles -Fallback $false
if ($d365fo.integrations_importIndividualFiles) { $importIndividualFiles = $true }
if (Test-Path (Resolve-PSFPath -Path "$($script:ModuleRoot)\..\.git" -SingleItem -NewChild)) { $importIndividualFiles = $true }
if ("<was compiled>" -eq '<was not compiled>') { $importIndividualFiles = $true }
	
function Import-ModuleFile
{
	<#
		.SYNOPSIS
			Loads files into the module on module import.
		
		.DESCRIPTION
			This helper function is used during module initialization.
			It should always be dotsourced itself, in order to proper function.
			
			This provides a central location to react to files being imported, if later desired
		
		.PARAMETER Path
			The path to the file to load
		
		.EXAMPLE
			PS C:\> . Import-ModuleFile -File $function.FullName
	
			Imports the file stored in $function according to import policy
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Path
	)
	
	if ($doDotSource) { . (Resolve-Path $Path) }
	else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText((Resolve-Path $Path)))), $null, $null) }
}

#region Load individual files
if ($importIndividualFiles)
{
	# Execute Preimport actions
	. Import-ModuleFile -Path "$ModuleRoot\internal\scripts\preimport.ps1"
	
	# Import all internal functions
	foreach ($function in (Get-ChildItem "$ModuleRoot\internal\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore))
	{
		. Import-ModuleFile -Path $function.FullName
	}
	
	# Import all public functions
	foreach ($function in (Get-ChildItem "$ModuleRoot\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore))
	{
		. Import-ModuleFile -Path $function.FullName
	}
	
	# Execute Postimport actions
	. Import-ModuleFile -Path "$ModuleRoot\internal\scripts\postimport.ps1"
	
	# End it here, do not load compiled code below
	return
}
#endregion Load individual files

#region Load compiled code
<#
This file loads the strings documents from the respective language folders.
This allows localizing messages and errors.
Load psd1 language files for each language you wish to support.
Partial translations are acceptable - when missing a current language message,
it will fallback to English or another available language.
#>
Import-PSFLocalizedString -Path "$($script:ModuleRoot)\en-us\*.psd1" -Module 'd365fo.integrations' -Language 'en-US'


<#
    .SYNOPSIS
        Add content to a Web Request
        
    .DESCRIPTION
        Add the payload as content into the Web Request object
        
    .PARAMETER WebRequest
        The Web Request object that you want to add the content to
        
    .PARAMETER Payload
        The entire string contain the json object that you want to pass to the D365FO environment
        
    .EXAMPLE
        PS C:\> $request = New-WebRequest -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/ack/123456789" -Action "POST" -AuthenticationToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....."
        PS C:\> Add-WebRequestContentFromFile -WebRequest $request -Payload '{"CorrelationId": "5acd8121-d4e1-4cf8-b31f-9713de3e3627", "PopReceipt": "AgAAAAMAAAAAAAAA3XpSEQ0b1QE=", "DownloadLocation": "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/download/%7Bb0b5401e-56ca-4dc8-b566-84389a001236%7D?correlation-id=5acd8121-d4e1-4cf8-b31f-9713de3e3627&blob=c5fbcc38-4f1e-4a81-af27-e6684d9fc217", "IsDownLoadFileExist": True, "FileDownLoadErrorMessage": ""}'
        
        This will add the payload content to the Web Request.
        It will create a new Web Request object.
        It will use the '{"CorrelationId": "5acd8121-d4e1-4cf8-b31f-9713de3e3627", "PopReceipt": "AgAAAAMAAAAAAAAA3XpSEQ0b1QE=", "DownloadLocation": "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/download/%7Bb0b5401e-56ca-4dc8-b566-84389a001236%7D?correlation-id=5acd8121-d4e1-4cf8-b31f-9713de3e3627&blob=c5fbcc38-4f1e-4a81-af27-e6684d9fc217", "IsDownLoadFileExist": True, "FileDownLoadErrorMessage": ""}' as the payload content to add to the web request.
        
    .LINK
        New-WebRequest
        
    .NOTES
        Tags: Request, DMF, Package, Packages
        
        Author: Mötz Jensen (@Splaxi)
        
#>
#
function Add-WebRequestContent {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.WebRequest] $WebRequest,
        
        [Parameter(Mandatory = $true)]
        [string] $Payload
    )

    Write-PSFMessage -Level Verbose -Message "Parsing the payload and adding it to the web request." -Target $Payload

    try {
        $WebRequest.ContentLength = [System.Text.Encoding]::UTF8.GetByteCount($Payload)

        $stream = $WebRequest.GetRequestStream()
        $streamWriter = new-object System.IO.StreamWriter($stream)
        $streamWriter.Write([string]$Payload)
        $streamWriter.Flush()
        $streamWriter.Close()
    }
    catch {
        Write-PSFMessage -Level Critical -Message "Exception while creating WebRequest $RequestUrl" -Exception $_.Exception
        Stop-PSFFunction -Message "Stopping" -StepsUpward 1
    }
}


<#
    .SYNOPSIS
        Add content from file to a Web Request
        
    .DESCRIPTION
        Read the content from a file and put it into the Web Request object
        
    .PARAMETER WebRequest
        The Web Request object that you want to add the content of the file to
        
    .PARAMETER Path
        Path to the file you want to add to the Web Request object
        
    .EXAMPLE
        PS C:\> $request = New-WebRequest -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/enqueue/123456789" -Action "POST" -AuthenticationToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....."
        PS C:\> Add-WebRequestContentFromFile -WebRequest $request -Path "c:\temp\d365fo.tools\dmfpackage.zip"
        
        This will add the file content to the Web Request.
        It will create a new Web Request object.
        It will use the "c:\temp\d365fo.tools\dmfpackage.zip" path to read the file content.
        
    .LINK
        New-WebRequest
        
    .NOTES
        Tags: Request, DMF, Package, Packages
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Add-WebRequestContentFromFile {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.WebRequest] $WebRequest,

        [Parameter(Mandatory = $true)]
        [string] $Path

    )

    if (-not (Test-PathExists -Path $Path -Type Leaf)) { return }

    try {
        Write-PSFMessage -Level Debug -Message "Working on file: $Path" -Target $Path
    
        $fileStream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open)
        
        Write-PSFMessage -Level Debug -Message "Length $($fileStream.Length)"
        
        $WebRequest.ContentLength = $fileStream.Length
        $stream = $WebRequest.GetRequestStream()
        $fileStream.CopyTo($stream)
        $fileStream.Flush()
        $fileStream.Close()
    }
    catch {
        Write-PSFMessage -Level Critical -Message "Exception while adding the file content to the WebRequest" -Exception $_.Exception
        Stop-PSFFunction -Message "Stopping" -StepsUpward 1
    }
}


<#
    .SYNOPSIS
        Get DMF Dequeue Package details
        
    .DESCRIPTION
        Get all the needed details about a DMF package, so you can download (dequeue) it from the Dynamics 365 for Finance & Operations environment
        
    .PARAMETER JobId
        The GUID from the recurring data job
        
    .PARAMETER AuthenticationToken
        The token value that should be used to authenticate against the URL / URI endpoint
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through DMF
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Get-DmfDequeuePackageDetails -JobId "db5e719a-8db3-4fe5-9c78-7be479ce85a2" -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -AuthenticationToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....."
        
        This will fetch the available DMF package details.
        It will use "db5e719a-8db3-4fe5-9c78-7be479ce85a2" as the jobid parameter passed to the DMF endpoint.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the base D365FO environment url.
        It will use the "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." as the bearer token for the endpoint.
        
    .NOTES
        Tags: Download, DMF, Package, Packages
        
        Author: Mötz Jensen (@Splaxi)
#>

function Get-DmfDequeuePackageDetails {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    [OutputType('System.String')]
    param (
        [Parameter(Mandatory = $true)]
        [String] $JobId,

        [Parameter(Mandatory = $true)]
        [string] $AuthenticationToken,

        [Parameter(Mandatory = $true)]
        [string] $Url,

        [switch] $EnableException
    )

    Write-PSFMessage -Level Verbose -Message "Building request for the DMF Package dequeue endpoint." -Target $JobId

    $requestUrl = "$Url/api/connector/dequeue/$JobId"

    $request = New-WebRequest -Url $requestUrl -Action "GET" -AuthenticationToken $AuthenticationToken

    try {
        Write-PSFMessage -Level Verbose -Message "Executing the DMF Package dequeue request against the DMF endpoint."

        $response = $request.GetResponse()
        
        Write-PSFMessage -Level Verbose -Message "Parsing the response received from the DMF Package dequeue request."

        $stream = $response.GetResponseStream()
    
        $streamReader = New-Object System.IO.StreamReader($stream)
        
        $res = $streamReader.ReadToEnd()
        $streamReader.Close()

        $res
    }
    catch {
        $messageString = "Something went wrong while dequeuing through the DMF Package endpoint for JobId: $JobId"
        Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $JobId
        Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_ -StepsUpward 1
        return
    }
}


<#
    .SYNOPSIS
        Get the DMF Package file
        
    .DESCRIPTION
        Get / Download the DMF package file from the Dynamics 365 for Finance & Operations environment
        
    .PARAMETER DownloadLocation
        The URI / URL where the DMF package file is available
        
    .PARAMETER Path
        Path where you want to store the file on your local infrastructure
        
    .PARAMETER AuthenticationToken
        The token value that should be used to authenticate against the URL / URI endpoint
        
    .PARAMETER Retries
        Number of retries the module should use to download the file
        
    .EXAMPLE
        PS C:\> Get-DmfFile -Path "c:\temp\d365fo.tools\dmfpackage.zip" -AuthenticationToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." -DownloadLocation "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/download/%7Bb0b5401e-56ca-4dc8-b566-84389a001236%7D?correlation-id=5acd8121-d4e1-4cf8-b31f-9713de3e3627&blob=c5fbcc38-4f1e-4a81-af27-e6684d9fc217"
        
        This will download the DMF Package from D365FO.
        It will use "c:\temp\d365fo.tools\dmfpackage.zip" as the location to save the file.
        It will use the "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." as the bearer token for the endpoint.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/download/%7Bb0b5401e-56ca-4dc8-b566-84389a001236%7D?correlation-id=5acd8121-d4e1-4cf8-b31f-9713de3e3627&blob=c5fbcc38-4f1e-4a81-af27-e6684d9fc217" as the request URL / URI to download the DMF Package from.
        
    .NOTES
        Tags: Download, DMF, Package, Packages
        
        Author: Mötz Jensen (@Splaxi)
#>

function Get-DmfFile {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Url')]
        [Alias('Uri')]
        [string] $DownloadLocation,

        [Parameter(Mandatory = $true)]
        [Alias('File')]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $AuthenticationToken,

        [int] $Retries = $Script:DmfDownloadRetries
    )

    process {
        if ($DownloadLocation.StartsWith("http://")) {
            $DownloadLocation = $DownloadLocation.Replace("http://", "https://").Replace(":80", "")
        }

        Write-PSFMessage -Level Verbose -Message "Download URI / URL for the DMF Package is: $DownloadLocation" -Target $DownloadLocation

        $retriesLocal = $Retries

        while ($retriesLocal -gt 0 ) {
            $attemptNo = ($Retries - $retriesLocal) + 1
            Write-PSFMessage -Level Verbose -Message "($attemptNo) - Building request for downloading the DMF Package." -Target $DownloadLocation

            $request = New-WebRequest -Url $DownloadLocation -Action "GET" -AuthenticationToken $AuthenticationToken

            Get-FileFromWebRequest -WebRequest $request -Path $Path

            if (Test-PSFFunctionInterrupt) {
                Write-PSFMessage -Level Verbose -Message "($attemptNo) - Downloading the DMF Package failed."
            
                $retriesLocal = $retriesLocal - 1;

                if ($retriesLocal -lt 0) {
                    Write-PSFMessage -Level Critical "Number of retries exhausted for JobId: $JobId"
                    Stop-PSFFunction -Message "Stopping" -StepsUpward 1
                    return
                }
            }
            else {
                $retriesLocal = 0
            }
        }
    }
}


<#
    .SYNOPSIS
        Get file from Web Request
        
    .DESCRIPTION
        Extract the file from the Web Request object
        
    .PARAMETER WebRequest
        The Web Request object that you want to add the content to
        
    .PARAMETER Path
        Path where you want to store the file on your local infrastructure
        
    .EXAMPLE
        PS C:\> $request = New-WebRequest -Action "GET" -AuthenticationToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/download/%7Bb0b5401e-56ca-4dc8-b566-84389a001236%7D?correlation-id=5acd8121-d4e1-4cf8-b31f-9713de3e3627&blob=c5fbcc38-4f1e-4a81-af27-e6684d9fc217"
        PS C:\> Get-FileFromWebRequest -WebRequest $request -Path "c:\temp\d365fo.tools\dmfpackage.zip"
        
        This will extract the file the Web Request.
        It will create a new Web Request.
        It will pass the $request variable to the function.
        It will use "c:\temp\d365fo.tools\dmfpackage.zip" as the path where the file should be stored.
        
    .NOTES
        Tags: DMF, Download
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-FileFromWebRequest {
    param(
        [Parameter(Mandatory = $true)]
        [System.Net.WebRequest] $WebRequest,

        [Parameter(Mandatory = $true)]
        [Alias('File')]
        [string] $Path
    )


    $response = $null
    
    try {
        Write-PSFMessage -Level Verbose -Message "Executing http request to download the DMF Package." -Target $($odataEndpoint.Uri.AbsoluteUri)

        $response = $WebRequest.GetResponse()
    }
    catch {
        Write-PSFMessage -Level Verbose -Message "Error getting response from $($webRequest.RequestURI.AbsoluteUri)" -Exception $_.Exception
        Stop-PSFFunction -Message "Stopping" -StepsUpward 1 -EnableException:$false
        return
    }

    if ($response.StatusCode -eq [System.Net.HttpStatusCode]::Ok) {
        Write-PSFMessage -Level Verbose -Message "Status code was 'OK' - Extracting the stream."

        $stream = $response.GetResponseStream()
    
        Write-PSFMessage -Level Debug -Message "Creating file stream for $Path." -Target $Path
        $fileStream = [System.IO.File]::Create($Path)

        $stream.CopyTo($fileStream)

        Write-PSFMessage -Level Debug -Message "Close file stream."

        # $fileStream.Flush()
        $fileStream.Close()
    }
    else {
        Write-PSFMessage -Level Verbose -Message "Status code not Ok, Description $($response.StatusDescription)"
        Stop-PSFFunction -Message "Stopping" -StepsUpward 1 -EnableException:$false
        return
    }
}


<#
    .SYNOPSIS
        Acknowledge a DMF package status
        
    .DESCRIPTION
        Send an acknowledgement to the DMF endpoint in the Dynamics 365 for Finance & Operations environment
        
    .PARAMETER JobId
        JobId of the DMF job you want to acknowledge
        
    .PARAMETER JsonMessage
        The json message that you want to pass to the DMF endpoint
        
    .PARAMETER AuthenticationToken
        The token value that should be used to authenticate against the URL / URI endpoint
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through DMF
        
    .EXAMPLE
        PS C:\> Invoke-DmfAcknowledge -JobId "db5e719a-8db3-4fe5-9c78-7be479ce85a2" -JsonMessage '{"CorrelationId": "5acd8121-d4e1-4cf8-b31f-9713de3e3627", "PopReceipt": "AgAAAAMAAAAAAAAA3XpSEQ0b1QE=", "DownloadLocation": "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/download/%7Bb0b5401e-56ca-4dc8-b566-84389a001236%7D?correlation-id=5acd8121-d4e1-4cf8-b31f-9713de3e3627&blob=c5fbcc38-4f1e-4a81-af27-e6684d9fc217", "IsDownLoadFileExist": True, "FileDownLoadErrorMessage": ""}' -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -AuthenticationToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....."
        
        This will acknowledge a DMF package through the DMF endpoint of the D365FO environment.
        It will use "db5e719a-8db3-4fe5-9c78-7be479ce85a2" as the jobid parameter passed to the DMF endpoint.
        It will use the '{"CorrelationId": "5acd8121-d4e1-4cf8-b31f-9713de3e3627", "PopReceipt": "AgAAAAMAAAAAAAAA3XpSEQ0b1QE=", "DownloadLocation": "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/download/%7Bb0b5401e-56ca-4dc8-b566-84389a001236%7D?correlation-id=5acd8121-d4e1-4cf8-b31f-9713de3e3627&blob=c5fbcc38-4f1e-4a81-af27-e6684d9fc217", "IsDownLoadFileExist": True, "FileDownLoadErrorMessage": ""}' as the json message that will be passed on to the DMF endpoint.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the base D365FO environment url.
        It will use the "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." as the bearer token for the endpoint.
        
    .NOTES
        Tags: DMF, Package, Acknowledge, Acknowledgement, Ack
        
        Author: Mötz Jensen (@Splaxi)
#>
function Invoke-DmfAcknowledge {

    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [String] $JobId,

        [Parameter(Mandatory = $true)]
        [string] $JsonMessage,

        [Parameter(Mandatory = $true)]
        [string] $AuthenticationToken,

        [Parameter(Mandatory = $true)]
        [string] $Url
    )

    Write-PSFMessage -Level Verbose -Message "Building request for the ACK interface of the DMF package." -Target $JobId

    $requestUrl = "$Url/api/connector/ack/$JobId"

    $request = New-WebRequest -Url $requestUrl -Action "POST" -AuthenticationToken $AuthenticationToken -ContentType "application/json"

    Add-WebRequestContent -WebRequest $request -Payload $JsonMessage

    try {
        Write-PSFMessage -Level Verbose -Message "Executing the request against the ACK interface of the DMF endpoint." -Target $JsonMessage

        $response = $request.GetResponse()
    }
    catch {
        $messageString = "Something went wrong while contacting the ACK interface of the DMF endpoint for JobId: $JobId."
        Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $JobId
        Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_ -StepsUpward 1
        return
    }

    Write-PSFMessage -Level Verbose -Message "Status code was: $($response.StatusCode)" -Target $response.StatusCode
    
    if ($response.StatusCode -ne [System.Net.HttpStatusCode]::Ok) {
        Write-PSFMessage -Level Verbose -Message "Status code not Ok, Description $($response.StatusDescription)"
        Stop-PSFFunction -Message "Stopping" -StepsUpward 1 -EnableException:$false
        return
    }
}


<#
    .SYNOPSIS
        Invoke enqueueing of a DMF Package
        
    .DESCRIPTION
        Enqueue a DMF package to the Dynamics 365 for Finance & Operations environment
        
    .PARAMETER Path
        Path of the file that you want to import into D365FO
        
    .PARAMETER JobId
        The GUID from the recurring data job
        
    .PARAMETER AuthenticationToken
        The token value that should be used to authenticate against the URL / URI endpoint
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through DMF
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Invoke-DmfEnqueuePackage -Path "c:\temp\d365fo.tools\dmfpackage.zip" -JobId "db5e719a-8db3-4fe5-9c78-7be479ce85a2" -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -AuthenticationToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....."
        
        This will upload the dmfpackage to the D365FO DMF endpoint.
        It will use "c:\temp\d365fo.tools\dmfpackage.zip" as the location from where to load the file.
        It will use "db5e719a-8db3-4fe5-9c78-7be479ce85a2" as the jobid parameter passed to the DMF endpoint.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the base D365FO environment url.
        It will use the "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." as the bearer token for the endpoint.
        
    .NOTES
        Tags: Download, DMF, Package, Packages
        
        Author: Mötz Jensen (@Splaxi)
#>

function Invoke-DmfEnqueuePackage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    [OutputType('System.String')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('File')]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [String] $JobId,

        [Parameter(Mandatory = $true)]
        [string] $AuthenticationToken,

        [Parameter(Mandatory = $true)]
        [string] $Url,

        [switch] $EnableException
    )

    Write-PSFMessage -Level Verbose -Message "Building request for the DMF Package enqueue endpoint." -Target $JobId

    $requestUrl = "$Url/api/connector/enqueue/$JobId"

    $request = New-WebRequest -Url $requestUrl -Action "POST" -AuthenticationToken $AuthenticationToken -ContentType "application/zip"

    Add-WebRequestContentFromFile -WebRequest $request -Path $Path

    try {
        Write-PSFMessage -Level Verbose -Message "Executing the request against the DMF Package enqueue endpoint."

        $response = $request.GetResponse()

        Write-PSFMessage -Level Verbose -Message "Response completed ($($request.ContentLength))."
    }
    catch {
        $messageString = "Something went wrong while enqueueing through the DMF Package endpoint for the JobId: $JobId"
        Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $JobId
        Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_ -StepsUpward 1
        return
    }

    Write-PSFMessage -Level Verbose -Message "Status code was: $($response.StatusCode)" -Target $response.StatusCode
    
    #Might need another status code to be correct
    if ($response.StatusCode -ne [System.Net.HttpStatusCode]::Ok) {
        Write-PSFMessage -Level Verbose -Message "Status code not Ok, Description $($response.StatusDescription)"
        Stop-PSFFunction -Message "Stopping" -StepsUpward 1 -EnableException:$false
        return
    }

    $stream = $response.GetResponseStream()
    
    $streamReader = New-Object System.IO.StreamReader($stream);
        
    $res = $streamReader.ReadToEnd()
    $streamReader.Close();
        
    $res
}


<#
    .SYNOPSIS
        Invoke the Invoke-RestMethod, wrapped in a handler that helps with the 429 issues
        
    .DESCRIPTION
        The OData endpoint will push back on clients, if it feels overwhelmed
        
        This translates into 429 in the status code of the http call and requires local logic to respect the retry timeout advice sent back
        
    .PARAMETER Method
        The http method that you want to utilize
        
    .PARAMETER Uri
        The Uri for the endpoint that you want to work against
        
    .PARAMETER ContentType
        The content type value that you want to utilize while working against the endpoint
        
    .PARAMETER Payload
        The payload, if any, that you want to pass to the endpoint
        
    .PARAMETER Headers
        Headers to be used against the endpoint
        
    .PARAMETER RetryTimeout
        The retry timeout, before the cmdlet should quit retrying based on the 429 status code
        
        Needs to be provided in the timspan notation:
        "hh:mm:ss"
        
        hh is the number of hours, numerical notation only
        mm is the number of minutes
        ss is the numbers of seconds
        
        Each section of the timeout has to valid, e.g.
        hh can maximum be 23
        mm can maximum be 59
        ss can maximum be 59
        
        Not setting this parameter will result in the cmdlet to try for ever to handle the 429 push back from the endpoint
        
    .EXAMPLE
        PS C:\> Invoke-RequestHandler -Method "Get" -Uri 'https://usnconeboxax1aos.cloud.onebox.dynamics.com/Data/SystemUsers?$top=1' -ContentType "application/json" -Headers @{Authorization = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." }
        
        This will fetch the top 1 SystemUsers from the endpoint.
        
    .NOTES
        Author: MÃ¶tz Jensen (@Splaxi)
        
#>
function Invoke-RequestHandler {
    [CmdletBinding()]
    param (
        [Alias("HttpMethod")]
        [string] $Method,

        [string] $Uri,
        
        [string] $ContentType,

        [string] $Payload,

        [Hashtable] $Headers,

        [Timespan] $RetryTimeout = "00:00:00"
    )
    
    begin {
        $parms = @{}
        $parms.Method = $Method
        $parms.Uri = $Uri
        $parms.Headers = $Headers
        $parms.ContentType = $ContentType

        if ($Payload) {
            $parms.Body = $Payload
        }

        $start = (Get-Date)
        $handleTimeout = $false

        if ($RetryTimeout.Ticks -gt 0) {
            $handleTimeout = $true
        }
    }
    
    process {
        $429Attempts = 0

        do {
            $429Retry = $false

            try {
                Invoke-RestMethod @parms
            }
            catch [System.Net.WebException] {
                if ($_.exception.response.statuscode -eq 429) {
                    $429Retry = $true
                    
                    $retryWaitSec = $_.exception.response.Headers["Retry-After"]

                    if (-not ($retryWaitSec -gt 0)) {
                        $retryWaitSec = 10
                    }

                    if ($handleTimeout) {
                        $timeSinceStart = New-TimeSpan -End $(Get-Date) -Start $start
                        $timeWithWait = $timeSinceStart.Add([timespan]::FromSeconds($retryWaitSec))
                        
                        $temp = $RetryTimeout - $timeWithWait

                        if ($temp.Ticks -lt 0) {
                            #We will be exceeding the timeout limit
                            $messageString = "The timeout value suggested from the endpoint will exceed the RetryTimeout (<c='em'>$RetryTimeout</c>) threshold."
                            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entity
                            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_ -StepsUpward 1
                            return
                        }
                    }

                    Write-PSFMessage -Level Host -Message "Hit a 429 status code. Will wait for: <c='em'>$retryWaitSec</c> seconds before trying again. Attempt (<c='em'>$429Attempts</c>)"
                    Start-Sleep -Seconds $retryWaitSec
                    $429Attempts++
                }
                else {
                    Throw
                }
            }
        } while ($429Retry)
    }
}


<#
    .SYNOPSIS
        Handle time measurement
        
    .DESCRIPTION
        Handle time measurement from when a cmdlet / function starts and ends
        
        Will write the output to the verbose stream (Write-PSFMessage -Level Verbose)
        
    .PARAMETER Start
        Switch to instruct the cmdlet that a start time registration needs to take place
        
    .PARAMETER End
        Switch to instruct the cmdlet that a time registration has come to its end and it needs to do the calculation
        
    .EXAMPLE
        PS C:\> Invoke-TimeSignal -Start
        
        This will start the time measurement for any given cmdlet / function
        
    .EXAMPLE
        PS C:\> Invoke-TimeSignal -End
        
        This will end the time measurement for any given cmdlet / function.
        The output will go into the verbose stream.
        
    .NOTES
        Author: Mötz Jensen (@Splaxi)
        
#>
function Invoke-TimeSignal {
    [CmdletBinding(DefaultParameterSetName = 'Start')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Start', Position = 1 )]
        [switch] $Start,
        
        [Parameter(Mandatory = $True, ParameterSetName = 'End', Position = 2 )]
        [switch] $End
    )

    $Time = (Get-Date)

    $Command = (Get-PSCallStack)[1].Command

    if ($Start) {
        if ($Script:TimeSignals.ContainsKey($Command)) {
            Write-PSFMessage -Level Debug -Message "The command '$Command' was already taking part in time measurement. The entry has been update with current date and time."
            $Script:TimeSignals[$Command] = $Time
        }
        else {
            $Script:TimeSignals.Add($Command, $Time)
        }
    }
    else {
        if ($Script:TimeSignals.ContainsKey($Command)) {
            $TimeSpan = New-TimeSpan -End $Time -Start (($Script:TimeSignals)[$Command])

            Write-PSFMessage -Level Verbose -Message "Total time spent inside the function was $TimeSpan" -Target $TimeSpan -FunctionName $Command -Tag "TimeSignal"
            $null = $Script:TimeSignals.Remove($Command)
        }
        else {
            Write-PSFMessage -Level Debug -Message "The command '$Command' was never started to take part in time measurement."
        }
    }
}


<#
    .SYNOPSIS
        Create batch content
        
    .DESCRIPTION
        Create a valid batch content that can be used in a HTTP batch request
        
    .PARAMETER Url
        URL / URI that the batch content should be valid for
        
        Normally the final URL / URI for the OData endpoint that the content is to be imported into
        
    .PARAMETER Payload
        The entire string contain the json object that you want to import into the D365FO environment
        
    .PARAMETER PayloadCharset
        The charset / encoding that you want the cmdlet to use while updating the odata entity
        
        The default value is: "UTF8"
        
        The charset has to be a valid http charset like: ASCII, ANSI, ISO-8859-1, UTF-8
        
    .PARAMETER Count
        The index number that the content should be stamped with, to be valid in the entire batch request content
        
    .PARAMETER Method
        Specify the HTTP method that you want the batch payload to perform
        
        Default value is: "POST"
        
    .EXAMPLE
        PS C:\> New-BatchContent -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com/data/ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' -Count 1
        
        This will create a new batch content string.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com/data/ExchangeRates" as the endpoint for the content.
        It will use the "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." as the bearer token for the endpoint.
        It will use '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' as the payload that needs to be included in the batch content.
        Iw will use 1 as the counter in the batch content number sequence.
        
    .NOTES
        Tags: OData, Data Entity, Batchmode, Batch, Batch Content, Multiple
        
        Author: Mötz Jensen (@Splaxi)
        Author: Rasmus Andersen (@ITRasmus)
        
#>

function New-BatchContent {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        
        [Parameter(Mandatory = $true)]
        [string] $Url,

        [Parameter(Mandatory = $true)]
        [string] $Payload,

        [string] $PayloadCharset = "UTF-8",

        [Parameter(Mandatory = $true)]
        [string] $Count,

        [string] $Method = "POST"
    )

    $dataBuilder = [System.Text.StringBuilder]::new()
    
    $null = $dataBuilder.AppendLine("Content-Type: application/http")
    $null = $dataBuilder.AppendLine("Content-Transfer-Encoding: binary")
    $null = $dataBuilder.AppendLine("Content-ID: $Count")
    $null = $dataBuilder.AppendLine("") #On purpose!
    $null = $dataBuilder.AppendLine("$Method $Url HTTP/1.1")
    
    $null = $dataBuilder.AppendLine("OData-Version: 4.0")
    $null = $dataBuilder.AppendLine("OData-MaxVersion: 4.0")

    $null = $dataBuilder.AppendLine("Content-Type: application/json;odata.metadata=minimal;charset=$PayloadCharset")
    
    # $null = $dataBuilder.AppendLine("Authorization: $AuthenticationToken")
    $null = $dataBuilder.AppendLine("") #On purpose!
    
    $null = $dataBuilder.AppendLine("$Payload")

    $dataBuilder.ToString()
}


<#
    .SYNOPSIS
        Create batch content
        
    .DESCRIPTION
        Create a valid batch content that can be used in a HTTP batch request
        
    .PARAMETER Url
        URL / URI that the batch content should be valid for
        
        Normally the final URL / URI for the OData endpoint that the content is to be imported into
        
    .PARAMETER AuthenticationToken
        The token value that should be used to authenticate against the URL / URI endpoint
        
    .PARAMETER Payload
        The entire string contain the json object that you want to import into the D365FO environment
        
    .PARAMETER PayloadCharset
        The charset / encoding that you want the cmdlet to use while updating the odata entity
        
        The default value is: "UTF8"
        
        The charset has to be a valid http charset like: ASCII, ANSI, ISO-8859-1, UTF-8
        
    .PARAMETER Count
        The index number that the content should be stamped with, to be valid in the entire batch request content
        
    .PARAMETER Method
        Specify the HTTP method that you want the batch payload to perform
        
        Default value is: "POST"
        
    .EXAMPLE
        PS C:\> New-BatchContent -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com/data/ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' -Count 1
        
        This will create a new batch content string.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com/data/ExchangeRates" as the endpoint for the content.
        It will use the "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." as the bearer token for the endpoint.
        It will use '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' as the payload that needs to be included in the batch content.
        Iw will use 1 as the counter in the batch content number sequence.
        
    .NOTES
        Tags: OData, Data Entity, Batchmode, Batch, Batch Content, Multiple
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function New-BatchKey {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        
        [Parameter(Mandatory = $true)]
        [string] $Url,
        
        [Parameter(Mandatory = $true)]
        [string] $Count,

        [string] $Method = "POST"
    )

    $dataBuilder = [System.Text.StringBuilder]::new()
    
    $null = $dataBuilder.AppendLine("Content-Type: application/http")
    $null = $dataBuilder.AppendLine("Content-Transfer-Encoding: binary")
    $null = $dataBuilder.AppendLine("Content-ID: $Count")

    $null = $dataBuilder.AppendLine("") #On purpose!
    $null = $dataBuilder.AppendLine("$Method $Url HTTP/1.1")
    $null = $dataBuilder.AppendLine("") #On purpose!

    $dataBuilder.ToString()
}


<#
    .SYNOPSIS
        Get a new bearer token
        
    .DESCRIPTION
        Obtain a new bearer token to be used for the different HTTP request against the Dynamics 365 for Finance & Operations environment
        
    .PARAMETER Url
        URL / URI for web endpoint that you want the token to be valid for
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to authenticate against
        
    .EXAMPLE
        PS C:\> New-BearerToken -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -ClientId "dea8d7a9-1602-4429-b138-111111111111" -ClientSecret "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522" -Tenant "e674da86-7ee5-40a7-b777-1111111111111"
        
        This will obtain a new and valid bearer token.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the resource url that you want the token to be valid for.
        It will use "dea8d7a9-1602-4429-b138-111111111111" as the ClientId.
        It will use "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522" as ClientSecret
        It will use "e674da86-7ee5-40a7-b777-1111111111111" as the Azure Active Directory guid.
        
    .NOTES
        Tags: OAuth, OAuth 2.0, Token, Bearer, JWT
        
        Author: Mötz Jensen (@Splaxi)
#>

function New-BearerToken {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Uri')]
        [string] $Url,

        [Parameter(Mandatory = $true)]
        [string] $ClientId,

        [Parameter(Mandatory = $true)]
        [string] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [string] $Tenant

    )

    Invoke-TimeSignal -Start

    Write-PSFMessage -Level Verbose -Message "Building request for fetching the bearer token." -Target $Var
    $bearerParms = @{
        Resource     = $Url
        ClientId     = $ClientId
        ClientSecret = $ClientSecret
    }

    $azureUri = $Script:AzureTenantOauthToken
    
    $bearerParms.AuthProviderUri = $azureUri -f $Tenant

    Write-PSFMessage -Level Verbose -Message "Fetching the bearer token." -Target ($bearerParms -join ", ")

    Invoke-ClientCredentialsGrant @bearerParms | Get-BearerToken

    Invoke-TimeSignal -End
}


<#
    .SYNOPSIS
        Create a webrequest
        
    .DESCRIPTION
        Create a webrequest with the needed details handled
        
    .PARAMETER Url
        URL / URI for web endpoint you want to work against
        
    .PARAMETER Action
        HTTP action instructing the cmdlet how to build the request
        
    .PARAMETER AuthenticationToken
        The token value that should be used to authenticate against the URL / URI endpoint
        
    .PARAMETER ContentType
        HTTP valid content type value that the cmdlet should use while building the request
        
    .EXAMPLE
        PS C:\> New-WebRequest -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/dequeue/123456789" -Action "GET" -AuthenticationToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....."
        
        This will create a new webrequest.
        It will use the "https://usnconeboxax1aos.cloud.onebox.dynamics.com/api/connector/dequeue/123456789" as the webrequest endpoint address.
        It will use the "Get" as HTTP Action.
        It will use the "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....." as the bearer token for the HTTP Authorization header.
        
    .NOTES
        Tags: Request, DMF, Package, Packages
        
        Author: Mötz Jensen (@Splaxi)
#>

function New-WebRequest {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType([System.Net.WebRequest])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Url,

        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [string] $AuthenticationToken,

        [Parameter(Mandatory = $false)]
        [string] $ContentType
    )

    Write-PSFMessage -Level Debug -Message "New Request $Url, $Action, $AuthenticationToken, $ContentType "
    
    $request = [System.Net.WebRequest]::Create($Url)
    $request.Headers["Authorization"] = $AuthenticationToken
    $request.Method = $Action

    if ($Action -eq 'POST') {
        $request.ContentType = $ContentType
    }

    $request
}


<#
    .SYNOPSIS
        The multiple paths
        
    .DESCRIPTION
        Easy way to test multiple paths for public functions and have the same error handling
        
    .PARAMETER Path
        Array of paths you want to test
        
        They have to be the same type, either file/leaf or folder/container
        
    .PARAMETER Type
        Type of path you want to test
        
        Either 'Leaf' or 'Container'
        
    .PARAMETER Create
        Instruct the cmdlet to create the directory if it doesn't exist
        
    .PARAMETER ShouldNotExist
        Instruct the cmdlet to return true if the file doesn't exists
        
    .PARAMETER DontBreak
        Instruct the cmdlet NOT to break execution whenever the test condition normally should
        
    .EXAMPLE
        PS C:\> Test-PathExists "c:\temp","c:\temp\dir" -Type Container
        
        This will test if the mentioned paths (folders) exists and the current context has enough permission.
        
    .NOTES
        Author: Mötz Jensen (@splaxi)
        
#>
function Test-PathExists {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory = $True, Position = 1 )]
        [string[]] $Path,

        [ValidateSet('Leaf', 'Container')]
        [Parameter(Mandatory = $True, Position = 2 )]
        [string] $Type,

        [switch] $Create,

        [switch] $ShouldNotExist,

        [switch] $DontBreak
    )
    
    $res = $false

    $arrList = New-Object -TypeName "System.Collections.ArrayList"
         
    foreach ($item in $Path) {
        Write-PSFMessage -Level Verbose -Message "Testing the path: $item" -Target $item
        $temp = Test-Path -Path $item -Type $Type

        if ((-not $temp) -and ($Create) -and ($Type -eq "Container")) {
            Write-PSFMessage -Level Verbose -Message "Creating the path: $item" -Target $item
            $null = New-Item -Path $item -ItemType Directory -Force -ErrorAction Stop
            $temp = $true
        }
        elseif ($ShouldNotExist) {
            Write-PSFMessage -Level Verbose -Message "The should NOT exists: $item" -Target $item
        }
        elseif (-not $temp ) {
            Write-PSFMessage -Level Host -Message "The <c='em'>$item</c> path wasn't found. Please ensure the path <c='em'>exists</c> and you have enough <c='em'>permission</c> to access the path."
        }
        
        $null = $arrList.Add($temp)
    }

    if ($arrList.Contains($false) -and (-not $ShouldNotExist)) {
        if (-not $DontBreak) {
            Stop-PSFFunction -Message "Stopping because of missing paths." -StepsUpward 1
        }
    }
    elseif ($arrList.Contains($true) -and $ShouldNotExist) {
        if (-not $DontBreak) {
            Stop-PSFFunction -Message "Stopping because file exists." -StepsUpward 1
        }
    }
    else {
        $res = $true
    }

    $res
}


<#
    .SYNOPSIS
        Update the OData config variables
        
    .DESCRIPTION
        Update the active OData config variables that the module will use as default values
        
    .EXAMPLE
        PS C:\> Update-ODataVariables
        
        This will update the OData variables.
        
    .NOTES
        Author: Mötz Jensen (@Splaxi)
#>

function Update-ODataVariables {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    [OutputType()]
    param ( )
    
    $configName = (Get-PSFConfig -FullName "d365fo.integrations.active.odata.config.name").Value

    if (([string]::IsNullOrEmpty($configName))) {
        return
    }

    $configName = $configName.ToString().ToLower()
    
    Remove-Variable -Name "ODataSystemUrl" -Scope "Script" -Force -ErrorAction SilentlyContinue

    if (-not ($configName -eq "")) {
        $configHash = Get-D365ActiveODataConfig -OutputAsHashtable
        foreach ($item in $configHash.Keys) {
            if ($item -eq "name") { continue }
            
            $name = "OData" + (Get-Culture).TextInfo.ToTitleCase($item)
        
            $valueMessage = $configHash[$item]

            if ($item -like "*client*" -and $valueMessage.Length -gt 20)
            {
                $valueMessage = $valueMessage.Substring(0,18) + "[...REDACTED...]"
            }

            Write-PSFMessage -Level Verbose -Message "$name - $valueMessage" -Target $valueMessage
            Set-Variable -Name $name -Value $configHash[$item] -Scope Script
        }
    }
}


<#
    .SYNOPSIS
        Update module variables from the configuration store
        
    .DESCRIPTION
        Update all module variables that are based on the PSF configuration store
        
    .EXAMPLE
        PS C:\> Update-PsfConfigVariables
        
        This will update all module variables based on the configuration store.
        
    .NOTES
        Tags: Variable, Variables
        
        Author: Mötz Jensen (@Splaxi)
#>

function Update-PsfConfigVariables {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]

    [CmdletBinding()]
    [OutputType()]
    param ()

    foreach ($config in Get-PSFConfig -FullName "d365fo.integrations.azure.*") {
        $item = $config.FullName.Replace("d365fo.integrations.", "")
        $name = (Get-Culture).TextInfo.ToTitleCase($item).Replace(".","")
        
        Write-PSFMessage -Level Verbose -Message "$name" -Target $($config.Value)
        Set-Variable -Name $name -Value $config.Value -Scope Script
    }
    
    foreach ($config in Get-PSFConfig -FullName "d365fo.integrations.dmf.*") {
        $item = $config.FullName.Replace("d365fo.integrations.", "")
        $name = (Get-Culture).TextInfo.ToTitleCase($item).Replace(".","")
        
        Write-PSFMessage -Level Verbose -Message "$name" -Target $($config.Value)
        Set-Variable -Name $name -Value $config.Value -Scope Script
    }
}


<#
    .SYNOPSIS
        Save an OData config
        
    .DESCRIPTION
        Adds an OData config to the configuration store
        
    .PARAMETER Name
        The logical name of the OData configuration you are about to register in the configuration store
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Temporary
        Instruct the cmdlet to only temporarily add the OData configuration in the configuration store
        
    .PARAMETER Force
        Instruct the cmdlet to overwrite the OData configuration with the same name
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Add-D365ODataConfig -Name "UAT" -Tenant "e674da86-7ee5-40a7-b777-1111111111111" -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -ClientId "dea8d7a9-1602-4429-b138-111111111111" -ClientSecret "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522"
        
        This will create an new OData configuration with the name "UAT".
        It will save "e674da86-7ee5-40a7-b777-1111111111111" as the Azure Active Directory guid.
        It will save "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the D365FO environment.
        It will save "dea8d7a9-1602-4429-b138-111111111111" as the ClientId.
        It will save "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522" as ClientSecret.
        
    .NOTES
        Tags: Integrations, Integration, Bearer Token, Token, OData, Configuration
        
        Author: Mötz Jensen (@Splaxi)
        
    .LINK
        Clear-D365ActiveBroadcastMessageConfig
        
    .LINK
        Get-D365ActiveBroadcastMessageConfig
        
    .LINK
        Get-D365BroadcastMessageConfig
        
    .LINK
        Remove-D365BroadcastMessageConfig
        
    .LINK
        Send-D365BroadcastMessage
        
    .LINK
        Set-D365ActiveBroadcastMessageConfig
#>

function Add-D365ODataConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Alias('$AADGuid')]
        [string] $Tenant,

        [Alias('Uri')]
        [Alias('AuthenticationUrl')]
        [string] $Url,

        [string] $SystemUrl,

        [string] $ClientId,

        [string] $ClientSecret,

        [switch] $Temporary,

        [switch] $Force,

        [switch] $EnableException
    )

    Write-PSFMessage -Level Verbose -Message "Testing if configuration with the name already exists or not." -Target $configurationValue

    if (((Get-PSFConfig -FullName "d365fo.integrations.odata.*.name").Value -contains $Name) -and (-not $Force)) {
        $messageString = "An OData configuration with <c='em'>$Name</c> as name <c='em'>already exists</c>. If you want to <c='em'>overwrite</c> the current configuration, please supply the <c='em'>-Force</c> parameter."
        Write-PSFMessage -Level Host -Message $messageString
        Stop-PSFFunction -Message "Stopping because an OData configuration already exists with that name." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', '')))
        return
    }

    if ([System.String]::IsNullOrEmpty($SystemUrl) -and (-not [System.String]::IsNullOrEmpty($Url))) {
        Write-PSFMessage -Level Verbose -Message "You didn't fill in the SystemUrl parameter, which is needed. Expecting that you are working against D365FO and using the Url parameter value." -Target $Url
        $PSBoundParameters.Add("SystemUrl", $Url)
        $SystemUrl = $Url
    }

    if (![System.String]::IsNullOrEmpty($Url)) {
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    }

    if (![System.String]::IsNullOrEmpty($SystemUrl)) {
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }
    }
    
    $configName = $Name.ToLower()

    #The ':keys' label is used to have a continue inside the switch statement itself
    :keys foreach ($key in $PSBoundParameters.Keys) {
        
        $configurationValue = $PSBoundParameters.Item($key)
        $configurationName = $key.ToLower()
        $fullConfigName = ""

        Write-PSFMessage -Level Verbose -Message "Working on $key with $configurationValue" -Target $configurationValue
        
        switch ($key) {
            "Name" {
                $fullConfigName = "d365fo.integrations.odata.$configName.name"
            }

            { "Temporary", "Force" -contains $_ } {
                continue keys
            }
            
            Default {
                $fullConfigName = "d365fo.integrations.odata.$configName.$configurationName"
            }
        }

        Write-PSFMessage -Level Verbose -Message "Setting $fullConfigName to $configurationValue" -Target $configurationValue
        
        Set-PSFConfig -FullName $fullConfigName -Value $configurationValue
        
        if (-not $Temporary) { Register-PSFConfig -FullName $fullConfigName -Scope UserDefault }
    }
}


<#
    .SYNOPSIS
        Enable exceptions to be thrown
        
    .DESCRIPTION
        Change the default exception behavior of the module to support throwing exceptions
        
        Useful when the module is used in an automated fashion, like inside Azure DevOps pipelines and large PowerShell scripts
        
    .EXAMPLE
        PS C:\>Enable-D365ExceptionIntegrations
        
        This will for the rest of the current PowerShell session make sure that exceptions will be thrown.
        
    .NOTES
        Tags: Exception, Exceptions, Warning, Warnings
        
        Author: Mötz Jensen (@Splaxi)
#>

function Enable-D365ExceptionIntegrations {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    param ()

    Write-PSFMessage -Level Verbose -Message "Enabling exception across the entire module." -Target $configurationValue
    Set-PSFFeature -Name 'PSFramework.InheritEnableException' -Value $true -ModuleName "d365fo.integrations"
    Set-PSFFeature -Name 'PSFramework.InheritEnableException' -Value $true -ModuleName "PSOAuthHelper"

    $PSDefaultParameterValues['*:EnableException'] = $true
}


<#
    .SYNOPSIS
        Export a DMF package from Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Exports a DMF package from the DMF endpoint of the Dynamics 365 Finance & Operations
        
    .PARAMETER Path
        Path where you want the cmdlet to save the exported file to
        
    .PARAMETER JobId
        JobId of the DMF job you want to export from
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through DMF
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through DMF
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Export-D365DmfPackage -Path "c:\temp\d365fo.tools\dmfpackage.zip" -JobId "db5e719a-8db3-4fe5-9c78-7be479ce85a2"
        
        This will export a package from the 123456789 job through the DMF endpoint.
        It will use "c:\temp\d365fo.tools\dmfpackage.zip" as the location to save the file.
        It will use "db5e719a-8db3-4fe5-9c78-7be479ce85a2" as the jobid parameter passed to the DMF endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Export-D365DmfPackage -Path "c:\temp\d365fo.tools\dmfpackage.zip" -JobId "db5e719a-8db3-4fe5-9c78-7be479ce85a2" -Tenant "e674da86-7ee5-40a7-b777-1111111111111" -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -ClientId "dea8d7a9-1602-4429-b138-111111111111" -ClientSecret "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522"
        
        This will export a package from the 123456789 job through the DMF endpoint.
        It will use "c:\temp\d365fo.tools\dmfpackage.zip" as the location to save the file.
        It will use "db5e719a-8db3-4fe5-9c78-7be479ce85a2" as the jobid parameter passed to the DMF endpoint.
        It will use "e674da86-7ee5-40a7-b777-1111111111111" as the Azure Active Directory guid.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the base D365FO environment url.
        It will use "dea8d7a9-1602-4429-b138-111111111111" as the ClientId.
        It will use "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522" as ClientSecret.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: Export, Download, DMF, Package, Packages, JobId
        
        Author: Mötz Jensen (@Splaxi)
#>

function Export-D365DmfPackage {
    [CmdletBinding()]
    [OutputType('System.String')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('File')]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [String] $JobId,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [switch] $EnableException

    )

    begin {
        $bearerParms = @{
            Url          = $Url
            ClientId     = $ClientId
            ClientSecret = $ClientSecret
            Tenant       = $Tenant
        }

        $bearer = New-BearerToken @bearerParms
    }

    process {
        Invoke-TimeSignal -Start

        $dmfParms = @{
            JobId               = $JobId
            Url                 = $Url
            AuthenticationToken = $bearer
        }

        $dmfDetails = Get-DmfDequeuePackageDetails @dmfParms -EnableException:$EnableException
        
        if (Test-PSFFunctionInterrupt) { return }

        if ([string]::IsNullOrWhiteSpace($dmfDetails)) {
            $messageString = "There was no file ready to be downloaded."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        $dmfDetailsJson = $dmfDetails | ConvertFrom-Json

        if ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
            Write-PSFMessage -Level Verbose -Message "$dmfDetails" -Target $dmfDetailsJson
        }

        $dmfDetailsJson | Get-DmfFile -Path $Path -AuthenticationToken $bearer

        if (Test-PSFFunctionInterrupt) {
            Stop-PSFFunction -Message "Downloading the DMF Package file failed." -Exception $([System.Exception]::new("Unable to download the DMF package file."))
            return
        }

        Invoke-DmfAcknowledge -JsonMessage $dmfDetails @dmfParms
        
        if (Test-PSFFunctionInterrupt) {
            Stop-PSFFunction -Message "Acknowledgement of the DMF Package failed." -Exception $([System.Exception]::new("Unable to acknowledge the DMF package file."))
            return
        }

        Get-Item -Path $Path | Select-PSFObject "Name as Filename", @{Name = "Size"; Expression = {[PSFSize]$_.Length}}, "LastWriteTime as LastModified", "Fullname as File"

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get the active OData configuration
        
    .DESCRIPTION
        Get the active OData configuration from the configuration store
        
    .PARAMETER OutputAsHashtable
        Instruct the cmdlet to return a hashtable object
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Get-D365ActiveODataConfig
        
        This will get the active OData configuration.
        
    .NOTES
        Tags: OData, Environment, Config, Configuration, ClientId, ClientSecret
        
        Author: Mötz Jensen (@Splaxi)
        
    .LINK
        Add-D365BroadcastMessageConfig
        
    .LINK
        Clear-D365ActiveBroadcastMessageConfig
        
    .LINK
        Get-D365BroadcastMessageConfig
        
    .LINK
        Remove-D365BroadcastMessageConfig
        
    .LINK
        Send-D365BroadcastMessage
        
    .LINK
        Set-D365ActiveBroadcastMessageConfig
#>

function Get-D365ActiveODataConfig {
    [CmdletBinding()]
    [OutputType()]
    param (
        [switch] $OutputAsHashtable,

        [switch] $EnableException
    )

    $configName = (Get-PSFConfig -FullName "d365fo.integrations.active.odata.config.name").Value

    if ($configName -eq "") {
        $messageString = "It looks like there <c='em'>isn't configured</c> an active OData configuration."
        Write-PSFMessage -Level Host -Message $messageString
        Stop-PSFFunction -Message "Stopping because an active OData configuration wasn't found." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>','')))
        return
    }

    Get-D365ODataConfig -Name $configName -OutputAsHashtable:$OutputAsHashtable
}


<#
    .SYNOPSIS
        Get public DMF Data Entity and their metadata
        
    .DESCRIPTION
        Get a list with all the public available DMF Data Entities,and their metadata, that are exposed through the DMF endpoint of the Dynamics 365 Finance & Operations environment
        
        The cmdlet will search across the singular names for the Data Entities and across the collection names (plural)
        
    .PARAMETER EntityName
        Name of the Data Entity you are searching for
        
        The parameter is Case Insensitive, to make it easier for the user to locate the correct Data Entity
        
    .PARAMETER EntityNameContains
        Name of the Data Entity you are searching for, but instructing the cmdlet to use search logic
        
        Using this parameter enables you to supply only a portion of the name for the entity you are looking for, and still a valid result back
        
        The parameter is Case Insensitive, to make it easier for the user to locate the correct Data Entity
        
    .PARAMETER ODataQuery
        Valid OData query string that you want to pass onto the D365 OData endpoint while retrieving data
        
        Important note:
        If you are using -EntityName or -EntityNameContains along with the -ODataQuery, you need to understand that the "$filter" query is already started. Then you need to start with -ODataQuery ' and XYZ eq XYZ', e.g. -ODataQuery ' and IsReadOnly eq false'
        If you are using the -ODataQuery alone, you need to start the OData Query string correctly. -ODataQuery '$filter=IsReadOnly eq false'
        
        OData specific query options are:
        $filter
        $expand
        $select
        $orderby
        $top
        $skip
        
        Each option has different characteristics, which is well documented at: http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part2-url-conventions.html
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to include the outer structure of the response received from DMF endpoint
        
        The output will still be a PSCustomObject
        
    .PARAMETER OutNamesOnly
        Instructs the cmdlet to only display the DataEntityName and the EntityName from the response received from DMF endpoint
        
        DataEntityName is the (logical) name of the entity from a code perspective.
        EntityName is the public DMF endpoint name of the entity.
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365DmfDataEntity -EntityName customersv3
        
        This will get Data Entities from the DMF endpoint.
        This will search for the Data Entities that are named "customersv3".
        
    .EXAMPLE
        PS C:\> (Get-D365DmfDataEntity -EntityName customersv3).Value
        
        This will get Data Entities from the DMF endpoint.
        This will search for the Data Entities that are named "customersv3".
        This will output the content of the "Value" property directly and list all found Data Entities and their metadata.
        
    .EXAMPLE
        PS C:\> Get-D365DmfDataEntity -EntityNameContains customers
        
        This will get Data Entities from the DMF endpoint.
        It will use the search string "customers" to search for any entity in their singular & plural name contains that search term.
        
    .EXAMPLE
        PS C:\> Get-D365DmfDataEntity -EntityNameContains customer -ODataQuery ' and IsReadOnly eq true'
        
        This will get Data Entities from the DMF endpoint.
        It will use the search string "customer" to search for any entity in their singular & plural name contains that search term.
        It will utilize the OData Query capabilities to filter for Data Entities that are "IsReadOnly = $true".
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365ODataPublicEntity -EntityName customersv3 -Token $token
        
        This will get Data Entities from the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        This will search for the Data Entities that are named "customersv3".
        
    .NOTES
        The OData standard is using the $ (dollar sign) for many functions and features, which in PowerShell is normally used for variables.
        
        Whenever you want to use the different query options, you need to take the $ sign and single quotes into consideration.
        
        Example of an execution where I want the top 1 result only, from a specific legal entity / company.
        This example is using single quotes, to help PowerShell not trying to convert the $ into a variable.
        Because the OData standard is using single quotes as text qualifiers, we need to escape them with multiple single quotes.
        
        -ODataQuery '$top=1&$filter=EntityCategory eq ''Master'''
        
        Tags: DMF, Data, Entity, Query
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365DmfDataEntity {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (

        [Parameter(Mandatory = $false, ParameterSetName = "Default")]
        [string] $EntityName,

        [Parameter(Mandatory = $true, ParameterSetName = "NameContains")]
        [string] $EntityNameContains,

        [Parameter(Mandatory = $false, ParameterSetName = "Default")]
        [Parameter(Mandatory = $false, ParameterSetName = "NameContains")]
        [Parameter(Mandatory = $true, ParameterSetName = "Query")]
        [string] $ODataQuery,

        [Alias('$AADGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [Alias('AuthenticationUrl')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [switch] $RawOutput,
        
        [switch] $OutNamesOnly,

        [switch] $OutputAsJson
    )


    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the DMF endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }

        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }
        
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "metadata/DataEntities"
        }
        else {
            $odataEndpoint.Path += "/metadata/DataEntities"
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-TimeSignal -Start

        $odataEndpoint.Query = ""
        
        if (-not ([string]::IsNullOrEmpty($EntityName))) {
            Write-PSFMessage -Level Verbose -Message "Building request for the Metadata DMF endpoint for entity named: $EntityName." -Target $EntityName

            $searchEntityName = $EntityName
            $odataEndpoint.Query = "`$filter=(tolower(Name) eq tolower('$EntityName') or tolower(PublicEntityName) eq tolower('$EntityName')) or tolower(PublicCollectionName) eq tolower('$EntityName'))"
        }
        elseif (-not ([string]::IsNullOrEmpty($EntityNameContains))) {
            Write-PSFMessage -Level Verbose -Message "Building request for the Metadata DMF endpoint for entity that contains: $EntityNameContains." -Target $EntityNameContains

            $searchEntityName = $EntityNameContains
            $odataEndpoint.Query = "`$filter=(contains(tolower(Name), tolower('$EntityNameContains')) or contains(tolower(PublicEntityName), tolower('$EntityNameContains')) or contains(tolower(PublicCollectionName), tolower('$EntityNameContains')))"
        }

        if (-not ([string]::IsNullOrEmpty($ODataQuery))) {
            $odataEndpoint.Query = $($odataEndpoint.Query + "$ODataQuery").Replace("?", "")
        }

        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the Metadata DMF endpoint." -Target $($DMFEndpoint.Uri.AbsoluteUri)
            $res = Invoke-RestMethod -Method Get -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType 'application/json'

            if (-not ($RawOutput)) {
                $res = $res.Value | Sort-Object -Property Name

                if ($OutNamesOnly) {
                    $res = $res | Select-PSFObject "Name as DataEntityName", "PublicEntityName as EntityName", "PublicCollectionName as CollectionName"
                }
            }

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch {
            $messageString = "Something went wrong while searching the Metadata DMF endpoint for the entity: $searchEntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get Message Status from the DMF
        
    .DESCRIPTION
        Get the Message Status based on the MessageId from the DMF Endpoint of the Dynamics 365 for Finance & Operations environment
        
    .PARAMETER MessageId
        MessageId of the message that you want to query the status for
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through DMF
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through DMF
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER WaitForCompletion
        Instruct the cmdlet to wait until the Message Status is in a terminating state
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Get-D365DmfMessageStatus -MessageId "84a383c8-336d-45e4-9933-0c3e8bfb734a"
        
        This will get the message status through the DMF endpoint.
        It will use "84a383c8-336d-45e4-9933-0c3e8bfb734a" as the MessageId parameter passed to the DMF endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365DmfMessageStatus -MessageId "84a383c8-336d-45e4-9933-0c3e8bfb734a" -Tenant "e674da86-7ee5-40a7-b777-1111111111111" -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -ClientId "dea8d7a9-1602-4429-b138-111111111111" -ClientSecret "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522"
        
        This will import a package into the 123456789 job through the DMF endpoint.
        It will use "84a383c8-336d-45e4-9933-0c3e8bfb734a" as the MessageId parameter passed to the DMF endpoint.
        It will use "e674da86-7ee5-40a7-b777-1111111111111" as the Azure Active Directory guid.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the base D365FO environment url.
        It will use "dea8d7a9-1602-4429-b138-111111111111" as the ClientId.
        It will use "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522" as ClientSecret.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365DmfMessageStatus -MessageId "84a383c8-336d-45e4-9933-0c3e8bfb734a" -Token $token
        
        This will get the message status through the DMF endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        It will use "84a383c8-336d-45e4-9933-0c3e8bfb734a" as the MessageId parameter passed to the DMF endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Import-D365DmfPackage
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: Import, Upload, DMF, Package, Packages, Message, MessageId, Message Status
        
        Author: Mötz Jensen (@Splaxi)
#>

function Get-D365DmfMessageStatus {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $MessageId,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [switch] $WaitForCompletion,

        [string] $Token,

        [switch] $EnableException
    )

    begin {
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the Message Status OData endpoint."

        $payload = "{'messageId':'$MessageId'}"

        [System.UriBuilder] $odataEndpoint = $URL
        
        $odataEndpoint.Path = "data/DataManagementDefinitionGroups/Microsoft.Dynamics.DataEntities.GetMessageStatus"

        try {
            do {
                $res = $null
                
                if ($WaitForCompletion) {
                    Start-Sleep -Seconds 60
                }
                
                Write-PSFMessage -Level Verbose -Message "Executing http request against the Message Status OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)
                
                $res = Invoke-RestMethod -Method Post -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType 'application/json' -Body $payload

                Write-PSFMessage -Level Verbose -Message "Message Status is: $($res.Value) - MessageId: $MessageId" -Target $res.Value
            }
            while ((($res.Value -ne "Processed") -and ($res.Value -ne "PreProcessingError") -and ($res.Value -ne "ProcessedWithErrors") -and ($res.Value -ne "PostProcessingFailed")) -and $WaitForCompletion)

            $res | Add-Member -NotePropertyName "MessageId" -NotePropertyValue $MessageId
            
            $res | Select-PSFObject "Value as MessageStatus", "MessageId", "@odata.context"
        }
        catch {
            $messageString = "Something went wrong while retrieving data from the Message Status OData endpoint for MessageId: $MessageId"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $MessageId
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    
    }

    end {
    }
}


<#
    .SYNOPSIS
        Get OData configs
        
    .DESCRIPTION
        Get all OData configuration objects from the configuration store
        
    .PARAMETER Name
        The name of the OData configuration you are looking for
        
        The parameter supports wildcards. E.g. -Name "*Customer*"
        
        Default value is "*" to display all OData configs
        
    .PARAMETER OutputAsHashtable
        Instruct the cmdlet to return a hashtable object
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Get-D365ODataConfig
        
        This will display all OData configurations on the machine.
        
    .EXAMPLE
        PS C:\> Get-D365ODataConfig -OutputAsHashtable
        
        This will display all OData configurations on the machine.
        Every object will be output as a hashtable, for you to utilize as parameters for other cmdlets.
        
    .EXAMPLE
        PS C:\> Get-D365ODataConfig -Name "UAT"
        
        This will display the OData configuration that is saved with the name "UAT" on the machine.
        
    .NOTES
        Tags: OData, Environment, Config, Configuration, ClientId, ClientSecret
        
        Author: Mötz Jensen (@Splaxi)
        
    .LINK
        Add-D365BroadcastMessageConfig
        
    .LINK
        Clear-D365ActiveBroadcastMessageConfig
        
    .LINK
        Get-D365ActiveBroadcastMessageConfig
        
    .LINK
        Remove-D365BroadcastMessageConfig
        
    .LINK
        Send-D365BroadcastMessage
        
    .LINK
        Set-D365ActiveBroadcastMessageConfig
#>

function Get-D365ODataConfig {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param (
        [string] $Name = "*",

        [switch] $OutputAsHashtable,

        [switch] $EnableException
    )
    
    Write-PSFMessage -Level Verbose -Message "Fetch all configurations based on $Name" -Target $Name

    $Name = $Name.ToLower()
    $configurations = Get-PSFConfig -FullName "d365fo.integrations.odata.$Name.name"

    if($($configurations.count) -lt 1) {
        $messageString = "No configurations found <c='em'>with</c> the name."
        Write-PSFMessage -Level Host -Message $messageString
        Stop-PSFFunction -Message "Stopping because no configuration found." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>','')))
        return
    }

    foreach ($configName in $configurations.Value.ToLower()) {
        Write-PSFMessage -Level Verbose -Message "Working against the $configName configuration" -Target $configName
        $res = @{}

        $configName = $configName.ToLower()

        foreach ($config in Get-PSFConfig -FullName "d365fo.integrations.odata.$configName.*") {
            $propertyName = $config.FullName.ToString().Replace("d365fo.integrations.odata.$configName.", "")
            $res.$propertyName = $config.Value
        }
        
        if($OutputAsHashtable) {
            $res
        } else {
            [PSCustomObject]$res
        }
    }
}


<#
    .SYNOPSIS
        Get data from an Data Entity using OData
        
    .DESCRIPTION
        Get data from an Data Entity using the OData endpoint of the Dynamics 365 Finance & Operations
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER EntitySetName
        Name of the Data Entity you want to work against
        
        The parameter is created specifically to be used when piping from Get-D365ODataPublicEntity
        
    .PARAMETER Top
        Number of records that you want returned from the OData endpoint
        
        Setting this will override anything in the OData parameter
        
    .PARAMETER Filter
        Filter statements to limit the records outputted from the OData endpoint
        
        Supports an array of filter statements, so you don't need to know the syntax of combining filter statements
        
        Setting this will override anything in the OData parameter
        
    .PARAMETER Select
        List of properties/columns that you want to return for the records outputted from the OData endpoint
        
        Setting this will override anything in the OData parameter
        
    .PARAMETER Expand
        List of navigation properties/related properties that you want to include for the records outputted from the OData endpoint
        
        Setting this will override anything in the OData parameter
        
    .PARAMETER ODataQuery
        Valid OData query string that you want to pass onto the D365 OData endpoint while retrieving data
        
        OData specific query options are:
        $filter
        $expand
        $select
        $orderby
        $top
        $skip
        
        Each option has different characteristics, which is well documented at: http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part2-url-conventions.html
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will search across all companies
        
    .PARAMETER RetryTimeout
        The retry timeout, before the cmdlet should quit retrying based on the 429 status code
        
        Needs to be provided in the timspan notation:
        "hh:mm:ss"
        
        hh is the number of hours, numerical notation only
        mm is the number of minutes
        ss is the numbers of seconds
        
        Each section of the timeout has to valid, e.g.
        hh can maximum be 23
        mm can maximum be 59
        ss can maximum be 59
        
        Not setting this parameter will result in the cmdlet to try for ever to handle the 429 push back from the endpoint
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER TraverseNextLink
        Instruct the cmdlet to keep traversing the NextLink if the result set from the OData endpoint is larger than what one round trip can handle
        
        The system default is 10,000 (10 thousands) at the time of writing this feature in December 2020
        
    .PARAMETER ThrottleSeed
        Instruct the cmdlet to invoke a thread sleep between 1 and ThrottleSeed value
        
        This is to help to mitigate the 429 retry throttling on the OData / Custom Service endpoints
        
        It will only be available in combination with the TraverseNextLink parameter
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to include the outer structure of the response received from OData endpoint
        
        The output will still be a PSCustomObject
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityData -EntityName CustomersV3 -ODataQuery '$top=1'
        
        This will get Customers from the OData endpoint.
        It will use the CustomerV3 entity, and its EntitySetName / CollectionName "CustomersV3".
        It will get the top 1 results from the list of customers.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityData -EntityName CustomersV3 -ODataQuery '$top=10' -CrossCompany
        
        This will get Customers from the OData endpoint.
        It will use the CustomerV3 entity, and its EntitySetName / CollectionName "CustomersV3".
        It will get the top 10 results from the list of customers.
        It will make sure to search across all legal entities / companies inside the D365FO environment.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityData -EntityName CustomersV3 -ODataQuery '$top=10&$filter=dataAreaId eq ''Comp1''' -CrossCompany
        
        This will get Customers from the OData endpoint.
        It will use the CustomerV3 entity, and its EntitySetName / CollectionName "CustomersV3".
        It will get the top 10 results from the list of customers.
        It will make sure to search across all legal entities / companies inside the D365FO environment.
        It will search the customers inside the "Comp1" legal entity / company.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityData -EntityName CustomersV3 -TraverseNextLink
        
        This will get Customers from the OData endpoint.
        It will use the CustomerV3 entity, and its EntitySetName / CollectionName "CustomersV3".
        It will traverse all NextLink that will occur while fetching data from the OData endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityData -EntityName CustomersV3 -TraverseNextLink -ThrottleSeed 2
        
        This will get Customers from the OData endpoint, and sleep/pause between 1 and 2 seconds.
        It will use the CustomerV3 entity, and its EntitySetName / CollectionName "CustomersV3".
        It will traverse all NextLink that will occur while fetching data from the OData endpoint.
        It will use the ThrottleSeed 2 to sleep/pause the execution, to mitigate the 429 pushback from the endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365ODataEntityData -EntityName CustomersV3 -ODataQuery '$top=1' -Token $token
        
        This will get Customers from the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        It will use the CustomerV3 entity, and its EntitySetName / CollectionName "CustomersV3".
        It will get the top 1 results from the list of customers.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityData -EntityName CustomersV3 -ODataQuery '$top=1' -RetryTimeout "00:01:00"
        
        This will get Customers from the OData endpoint, and try for 1 minute to handle 429.
        It will use the CustomerV3 entity, and its EntitySetName / CollectionName "CustomersV3".
        It will get the top 1 results from the list of customers.
        It will only try to handle 429 retries for 1 minute, before failing.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        The OData standard is using the $ (dollar sign) for many functions and features, which in PowerShell is normally used for variables.
        
        Whenever you want to use the different query options, you need to take the $ sign and single quotes into consideration.
        
        Example of an execution where I want the top 1 result only, from a specific legal entity / company.
        This example is using single quotes, to help PowerShell not trying to convert the $ into a variable.
        Because the OData standard is using single quotes as text qualifiers, we need to escape them with multiple single quotes.
        
        -ODataQuery '$top=1&$filter=dataAreaId eq ''Comp1'''
        
        Tags: OData, Data, Entity, Query
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365ODataEntityData {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Specific")]
        [Parameter(ParameterSetName = "NextLink")]
        [Alias('Name')]
        [string] $EntityName,

        [Parameter(Mandatory = $true, ParameterSetName = "Default", ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "NextLink", ValueFromPipelineByPropertyName = $true)]
        [Alias('CollectionName')]
        [string] $EntitySetName,

        [int] $Top,

        [string[]] $Filter,

        [string[]] $Select,

        [string[]] $Expand,

        [string] $ODataQuery,

        [switch] $CrossCompany,

        [Timespan] $RetryTimeout = "00:00:00",

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [Parameter(Mandatory = $true, ParameterSetName = "NextLink")]
        [switch] $TraverseNextLink,

        [Parameter(ParameterSetName = "NextLink")]
        [int] $ThrottleSeed,

        [string] $Token,
        
        [switch] $EnableException,

        [Parameter(ParameterSetName = "Specific")]
        [Parameter(ParameterSetName = "Default")]
        [switch] $RawOutput,

        [switch] $OutputAsJson

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        $odataAppend = "&"

        $sbODataQuery = [System.Text.StringBuilder]::new()
        if ($Top -gt 0) {
            [void]$sbODataQuery.AppendFormat("`$top={0}", $top)
        }

        if (-not [System.String]::IsNullOrEmpty($Filter)) {
            if ($sbODataQuery.Length -gt 0) {
                $odataFilterAppend = $odataAppend
            }

            [void]$sbODataQuery.AppendFormat("{0}`$filter={1}", $odataFilterAppend, $($Filter -join " and "))
        }
        
        if (-not [System.String]::IsNullOrEmpty($Select)) {
            if ($sbODataQuery.Length -gt 0) {
                $odataSelectAppend = $odataAppend
            }

            [void]$sbODataQuery.AppendFormat("{0}`$select={1}", $odataSelectAppend, $($Select -join ","))
        }

        if (-not [System.String]::IsNullOrEmpty($Expand)) {
            if ($sbODataQuery.Length -gt 0) {
                $odataExpandAppend = $odataAppend
            }

            [void]$sbODataQuery.AppendFormat("{0}`$expand={1}", $odataExpandAppend, $($Expand -join ","))
        }

        if ($sbODataQuery.Length -gt 0) {
            $ODataQuery = $sbODataQuery.ToString()
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the OData endpoint for entity: $entity." -Target $entity

        #A simple hack to select either names as the name going forward
        $entity = "$EntityName$EntitySetName"

        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "data/$entity"
        }
        else {
            $odataEndpoint.Path += "/data/$entity"
        }

        if (-not ([string]::IsNullOrEmpty($ODataQuery))) {
            $odataEndpoint.Query = "$ODataQuery"
        }
        
        if ($CrossCompany) {
            $odataEndpoint.Query = $($odataEndpoint.Query + "&cross-company=true").Replace("?", "")
        }

        try {
            [System.Collections.Generic.List[System.Object]] $resArray = @()

            $localUri = $odataEndpoint.Uri.AbsoluteUri
            do {
                Write-PSFMessage -Level Verbose -Message "Executing http request against the OData endpoint." -Target $localUri
                $resGet = Invoke-RequestHandler -Method Get -Uri $localUri -Headers $headers -ContentType 'application/json' -RetryTimeout $RetryTimeout
                
                if (Test-PSFFunctionInterrupt) { return }
                
                if (-not $RawOutput) {
                    $resArray.AddRange($resGet.Value)
                }
                else {
                    $res = $resGet
                }
                
                if ($($resGet.'@odata.nextLink') -match ".*(/data/.*)") {
                    $localUri = "$SystemUrl$($Matches[1])"
                }

                if ($ThrottleSeed) {
                    Start-Sleep -Seconds $(Get-Random -Minimum 1 -Maximum $ThrottleSeed)
                }
            } while ($TraverseNextLink -and $resGet.'@odata.nextLink')

            if ($resArray.Count -gt 0) {
                $res = $resArray.ToArray()
            }

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch {
            $messageString = "Something went wrong while retrieving data from the OData endpoint for the entity: $entity"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entity
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get data from an Data Entity using OData, providing a key
        
    .DESCRIPTION
        Get data from an Data Entity, by providing a key, using the OData endpoint of the Dynamics 365 Finance & Operations
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER Key
        A string value that contains all needed fields and value to be a valid OData key
        
        The key needs to be a valid http encoded value and each datatype needs to handled appropriately
        
    .PARAMETER ODataQuery
        Valid OData query string that you want to pass onto the D365 OData endpoint while retrieving data
        
        OData specific query options are:
        $filter
        $expand
        $select
        $orderby
        $top
        $skip
        
        Each option has different characteristics, which is well documented at: http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part2-url-conventions.html
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will search across all companies
        
    .PARAMETER RetryTimeout
        The retry timeout, before the cmdlet should quit retrying based on the 429 status code
        
        Needs to be provided in the timspan notation:
        "hh:mm:ss"
        
        hh is the number of hours, numerical notation only
        mm is the number of minutes
        ss is the numbers of seconds
        
        Each section of the timeout has to valid, e.g.
        hh can maximum be 23
        mm can maximum be 59
        ss can maximum be 59
        
        Not setting this parameter will result in the cmdlet to try for ever to handle the 429 push back from the endpoint
        
    .PARAMETER ThrottleSeed
        Instruct the cmdlet to invoke a thread sleep between 1 and ThrottleSeed value
        
        This is to help to mitigate the 429 retry throttling on the OData / Custom Service endpoints
        
        It makes most sense if you are running things a outer loop, where you will hit the OData / Custom Service endpoints with a burst of calls in a short time
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityDataByKey -EntityName CustomersV3 -Key "dataAreaId='DAT',CustomerAccount='123456789'"
        
        This will get the specific Customer from the OData endpoint.
        It will use the "CustomerV3" entity, and its EntitySetName / CollectionName "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        It will NOT look across companies.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityDataByKey -EntityName CustomersV3 -Key "dataAreaId='DAT',CustomerAccount='123456789'"
        
        This will get the specific Customer from the OData endpoint.
        It will use the "CustomerV3" entity, and its EntitySetName / CollectionName "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        It will make sure to search across all legal entities / companies inside the D365FO environment.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365ODataEntityDataByKey -EntityName CustomersV3 -Key "dataAreaId='DAT',CustomerAccount='123456789'" -Token $token
        
        This will get the specific Customer from the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        It will use the "CustomerV3" entity, and its EntitySetName / CollectionName "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        It will NOT look across companies.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityDataByKey -EntityName CustomersV3 -Key "dataAreaId='DAT',CustomerAccount='123456789'" -RetryTimeout "00:01:00"
        
        This will get the specific Customer from the OData endpoint, and try for 1 minute to handle 429.
        It will use the "CustomerV3" entity, and its EntitySetName / CollectionName "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        It will NOT look across companies.
        It will only try to handle 429 retries for 1 minute, before failing.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityDataByKey -EntityName CustomersV3 -Key "dataAreaId='DAT',CustomerAccount='123456789'" -ThrottleSeed 2
        
        This will get the specific Customer from the OData endpoint, and sleep/pause between 1 and 2 seconds.
        It will use the "CustomerV3" entity, and its EntitySetName / CollectionName "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        It will NOT look across companies.
        It will use the ThrottleSeed 2 to sleep/pause the execution, to mitigate the 429 pushback from the endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        The OData standard is using the $ (dollar sign) for many functions and features, which in PowerShell is normally used for variables.
        
        Whenever you want to use the different query options, you need to take the $ sign and single quotes into consideration.
        
        Example of an execution where I want the top 1 result only, from a specific legal entity / company.
        This example is using single quotes, to help PowerShell not trying to convert the $ into a variable.
        Because the OData standard is using single quotes as text qualifiers, we need to escape them with multiple single quotes.
        
        -ODataQuery '$top=1&$filter=dataAreaId eq ''Comp1'''
        
        Tags: OData, Data, Entity, Query
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365ODataEntityDataByKey {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Specific")]
        [Alias('Name')]
        [string] $EntityName,

        [Parameter(Mandatory = $true, ParameterSetName = "Specific")]
        [string] $Key,

        [string] $ODataQuery,

        [switch] $CrossCompany,

        [Timespan] $RetryTimeout = "00:00:00",

        [int] $ThrottleSeed,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [switch] $OutputAsJson
    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }

        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }
        
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the OData endpoint for entity: $entity." -Target $entity

        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "data/$EntityName($Key)"
        }
        else {
            $odataEndpoint.Path += "/data/$EntityName($Key)"
        }

        if (-not ([string]::IsNullOrEmpty($ODataQuery))) {
            $odataEndpoint.Query = "$ODataQuery"
        }
        
        if ($CrossCompany) {
            $odataEndpoint.Query = $($odataEndpoint.Query + "&cross-company=true").Replace("?", "")
        }

        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)
            $res = Invoke-RequestHandler -Method Get -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType 'application/json' -RetryTimeout $RetryTimeout

            if (Test-PSFFunctionInterrupt) { return }

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch [System.Net.WebException] {
            $webException = $_.Exception
            
            if (($webException.Status -eq [System.Net.WebExceptionStatus]::ProtocolError) -and (-not($null -eq $webException.Response))) {
                $resp = [System.Net.HttpWebResponse]$webException.Response

                if ($resp.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {
                    $messageString = "It seems that the OData endpoint was unable to locate the desired entity: $EntityName, based on the key: <c='em'>$key</c>. Please make sure that the key is <c='em'>valid</c> or try using the <c='em'>-CrossCompany</c> parameter."
                    Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
                    Stop-PSFFunction -Message "Stopping because of HTTP error 404." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
                    return
                }
                else {
                    $messageString = "Something went wrong while retrieving data from the OData endpoint for the entity: $EntityName"
                    Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
                    Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
                    return
                }
            }
        }
        catch {
            $messageString = "Something went wrong while retrieving data from the OData endpoint for the entity: $EntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        if ($ThrottleSeed) {
            Start-Sleep -Seconds $(Get-Random -Minimum 1 -Maximum $ThrottleSeed)
        }
        
        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get key field(s) from Data Entity
        
    .DESCRIPTION
        Get the key field(s) from a Data Entity and its meta data
        
    .PARAMETER Name
        Name of the Data Entity
        
    .PARAMETER Properties
        The properties value from the meta data object
        
    .PARAMETER OutputSample
        Instruct the cmdlet to output a sample of the key
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEntity -EntityName CustomersV3 | Get-D365ODataEntityKey | Format-List
        
        This will extract all the relevant key fields from the Data Entity.
        The "CustomersV3" value is used to get the desired Data Entity.
        The output from Get-D365ODataPublicEntity is piped into Get-D365ODataEntityKey.
        All key fields will be extracted and displayed.
        The output will be formatted as a list.
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEntity -EntityName CustomersV3 | Get-D365ODataEntityKey
        
        This will output a sample of the key from the Data Entity.
        The "CustomersV3" value is used to get the desired Data Entity.
        The output from Get-D365ODataPublicEntity is piped into Get-D365ODataEntityKey.
        All key fields will be concatenated and displayed.
        
    .LINK
        Get-D365ODataPublicEntity
        
    .NOTES
        Tags: OData, Data, Entity, MetaData, Meta, Key, Keys
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365ODataEntityKey {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Name,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCustomObject] $Properties,

        [switch] $OutputSample
    )

    process {
        $filteredRes = $Properties | Where-Object IsKey -eq $true

        $formattedRes = $filteredRes | Select-PSFObject "Name as FieldName", DataType
        
        if (-not $OutputSample) {
            [PSCustomObject]@{
                Name = $Name
                Keys = $formattedRes
            }
        }
        else {
            $res = ""

            foreach ($item in $filteredRes) {
                
                if ($item.DataType -eq "String") {
                    $res += "$($item.Name)='',"
                }
                else {
                    $res += "$($item.Name)=,"
                }
            }

            $res.Substring(0,$res.Length -1)
        }
    }
}


<#
    .SYNOPSIS
        Get mandatory field(s) from Data Entity
        
    .DESCRIPTION
        Get the mandatory field(s) from a Data Entity and its meta data
        
    .PARAMETER Name
        Name of the Data Entity
        
    .PARAMETER Properties
        The properties value from the meta data object
        
    .PARAMETER OutputSample
        Instruct the cmdlet to output a sample of the mandatory fields/properties
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEntity -EntityName CustomersV3 | Get-D365ODataEntityMandatoryField | Format-List
        
        This will extract all the relevant mandatory fields from the Data Entity.
        The "CustomersV3" value is used to get the desired Data Entity.
        The output from Get-D365ODataPublicEntity is piped into Get-D365ODataEntityMandatoryFields.
        All mandatory fields will be extracted and displayed.
        The output will be formatted as a list.
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEntity -EntityName CustomersV3 | Get-D365ODataEntityMandatoryField -OutputSample
        
        This will extract all the relevant mandatory fields from the Data Entity.
        The "CustomersV3" value is used to get the desired Data Entity.
        The output from Get-D365ODataPublicEntity is piped into Get-D365ODataEntityMandatoryFields.
        All mandatory fields will be extracted and displayed as a JSON sample.
        
    .LINK
        Get-D365ODataPublicEntity
        
    .NOTES
        Tags: OData, Data, Entity, MetaData, Meta, Mandatory
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365ODataEntityMandatoryField {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Name,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCustomObject] $Properties,

        [switch] $OutputSample
    )

    process {
        $filteredRes = $Properties | Where-Object IsMandatory -eq $true

        $formattedRes = $filteredRes | Select-PSFObject "Name as FieldName", DataType
        
        if (-not $OutputSample) {
            [PSCustomObject]@{
                Name = $Name
                Keys = $formattedRes
            }
        }
        else {
            [System.Collections.ArrayList] $res = New-Object -TypeName "System.Collections.ArrayList"

            foreach ($item in $filteredRes) {
                
                if ($item.DataType -eq "String") {
                    $res.Add("$($item.Name)=''") > $null
                }
                else {
                    $res.Add("$($item.Name)=''") > $null
                }
            }

            "{`r`n" + $($res.ToArray() -join ",`r`n") + "`r`n}"
        }
    }
}


<#
    .SYNOPSIS
        Get url for an Data Entity using OData
        
    .DESCRIPTION
        Get url for an Data Entity to be used with the OData endpoint of the Dynamics 365 Finance & Operations
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER EntitySetName
        Name of the Data Entity you want to work against
        
        The parameter is created specifically to be used when piping from Get-D365ODataPublicEntity
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .EXAMPLE
        PS C:\> Get-D365ODataEntityUrl -EntityName CustomersV3
        
        This will get the url for the CustomersV3 OData endpoint.
        It will use the CustomersV3 entity as the name of the entity.
        It will output a complete url for the CustomersV3 OData endpoint.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: OData, Data, Entity, Query, Url
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365ODataEntityUrl {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Specific")]
        [Alias('Name')]
        [string] $EntityName,

        [Parameter(Mandatory = $true, ParameterSetName = "Default", ValueFromPipelineByPropertyName = $true)]
        [Alias('CollectionName')]
        [string] $EntitySetName,

        [Alias('Uri')]
        [Alias('AuthenticationUrl')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl
    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Write-PSFMessage -Level Verbose -Message "Building request url for the OData endpoint for entity: $entity." -Target $entity

        #A simple hack to select either names as the name going forward
        $entity = "$EntityName$EntitySetName"

        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "data/$entity"
        }
        else {
            $odataEndpoint.Path += "/data/$entity"
        }

        $odataEndpoint.Uri.AbsoluteUri
    }
}


<#
    .SYNOPSIS
        Get public OData Data Entity and their metadata
        
    .DESCRIPTION
        Get a list with all the public available OData Data Entities,and their metadata, that are exposed through the OData endpoint of the Dynamics 365 Finance & Operations environment
        
        The cmdlet will search across the singular names for the Data Entities and across the collection names (plural)
        
    .PARAMETER EntityName
        Name of the Data Entity you are searching for
        
        The parameter is Case Insensitive, to make it easier for the user to locate the correct Data Entity
        
    .PARAMETER EntityNameContains
        Name of the Data Entity you are searching for, but instructing the cmdlet to use search logic
        
        Using this parameter enables you to supply only a portion of the name for the entity you are looking for, and still a valid result back
        
        The parameter is Case Insensitive, to make it easier for the user to locate the correct Data Entity
        
    .PARAMETER ODataQuery
        Valid OData query string that you want to pass onto the D365 OData endpoint while retrieving data
        
        Important note:
        If you are using -EntityName or -EntityNameContains along with the -ODataQuery, you need to understand that the "$filter" query is already started. Then you need to start with -ODataQuery ' and XYZ eq XYZ', e.g. -ODataQuery ' and IsReadOnly eq false'
        If you are using the -ODataQuery alone, you need to start the OData Query string correctly. -ODataQuery '$filter=IsReadOnly eq false'
        
        OData specific query options are:
        $filter
        $expand
        $select
        $orderby
        $top
        $skip
        
        Each option has different characteristics, which is well documented at: http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part2-url-conventions.html
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to include the outer structure of the response received from OData endpoint
        
        The output will still be a PSCustomObject
        
    .PARAMETER OutNamesOnly
        Instructs the cmdlet to only display the DataEntityName and the EntityName from the response received from OData endpoint
        
        DataEntityName is the (logical) name of the entity from a code perspective.
        EntityName is the public OData endpoint name of the entity.
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEntity -EntityName customersv3
        
        This will get Data Entities from the OData endpoint.
        This will search for the Data Entities that are named "customersv3".
        
    .EXAMPLE
        PS C:\> (Get-D365ODataPublicEntity -EntityName customersv3).Value
        
        This will get Data Entities from the OData endpoint.
        This will search for the Data Entities that are named "customersv3".
        This will output the content of the "Value" property directly and list all found Data Entities and their metadata.
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEntity -EntityNameContains customers
        
        This will get Data Entities from the OData endpoint.
        It will use the search string "customers" to search for any entity in their singular & plural name contains that search term.
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEntity -EntityNameContains customer -ODataQuery ' and IsReadOnly eq true'
        
        This will get Data Entities from the OData endpoint.
        It will use the search string "customer" to search for any entity in their singular & plural name contains that search term.
        It will utilize the OData Query capabilities to filter for Data Entities that are "IsReadOnly = $true".
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEntity -EntityName CustomersV3 | Get-D365ODataEntityKey | Format-List
        
        This will extract all the relevant key fields from the Data Entity.
        The "CustomersV3" value is used to get the desired Data Entity.
        The output from Get-D365ODataPublicEntity is piped into Get-D365ODataEntityKey.
        All key fields will be extracted and displayed.
        The output will be formatted as a list.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365ODataPublicEntity -EntityName customersv3 -Token $token
        
        This will get Data Entities from the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        This will search for the Data Entities that are named "customersv3".
        
    .LINK
        Get-D365ODataEntityKey
        
    .NOTES
        The OData standard is using the $ (dollar sign) for many functions and features, which in PowerShell is normally used for variables.
        
        Whenever you want to use the different query options, you need to take the $ sign and single quotes into consideration.
        
        Example of an execution where I want the top 1 result only, from a specific legal entity / company.
        This example is using single quotes, to help PowerShell not trying to convert the $ into a variable.
        Because the OData standard is using single quotes as text qualifiers, we need to escape them with multiple single quotes.
        
        -ODataQuery '$top=1&$filter=dataAreaId eq ''Comp1'''
        
        Tags: OData, Data, Entity, Query
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365ODataPublicEntity {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (

        [Parameter(Mandatory = $false, ParameterSetName = "Default")]
        [string] $EntityName,

        [Parameter(Mandatory = $true, ParameterSetName = "NameContains")]
        [string] $EntityNameContains,

        [Parameter(Mandatory = $false, ParameterSetName = "Default")]
        [Parameter(Mandatory = $false, ParameterSetName = "NameContains")]
        [Parameter(Mandatory = $true, ParameterSetName = "Query")]
        [string] $ODataQuery,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [switch] $RawOutput,
        
        [switch] $OutNamesOnly,

        [switch] $OutputAsJson
    )


    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }

        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }
        
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "metadata/PublicEntities"
        }
        else {
            $odataEndpoint.Path += "/metadata/PublicEntities"
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-TimeSignal -Start

        $odataEndpoint.Query = ""
        
        if (-not ([string]::IsNullOrEmpty($EntityName))) {
            Write-PSFMessage -Level Verbose -Message "Building request for the Metadata OData endpoint for entity named: $EntityName." -Target $EntityName

            $searchEntityName = $EntityName
            $odataEndpoint.Query = "`$filter=(tolower(Name) eq tolower('$EntityName') or tolower(EntitySetName) eq tolower('$EntityName'))"
        }
        elseif (-not ([string]::IsNullOrEmpty($EntityNameContains))) {
            Write-PSFMessage -Level Verbose -Message "Building request for the Metadata OData endpoint for entity that contains: $EntityNameContains." -Target $EntityNameContains

            $searchEntityName = $EntityNameContains
            $odataEndpoint.Query = "`$filter=(contains(tolower(Name), tolower('$EntityNameContains')) or contains(tolower(EntitySetName), tolower('$EntityNameContains')))"
        }

        if (-not ([string]::IsNullOrEmpty($ODataQuery))) {
            $odataEndpoint.Query = $($odataEndpoint.Query + "$ODataQuery").Replace("?", "")
        }

        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the Metadata OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)
            $res = Invoke-RestMethod -Method Get -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType 'application/json'

            if (-not ($RawOutput)) {
                $res = $res.Value | Sort-Object -Property Name

                if ($OutNamesOnly) {
                    $res = $res | Select-PSFObject "Name as DataEntityName", "EntitySetName as EntityName"
                }
            }

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch {
            $messageString = "Something went wrong while searching the Metadata OData endpoint for the entity: $searchEntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get public enumerations (enums) and their metadata
        
    .DESCRIPTION
        Get a list with all the public available enumerations (enums), and their metadata, that are exposed through the OData endpoint of the Dynamics 365 Finance & Operations environment
        
        The cmdlet will search across the names for the enumerations (enums) and across the labelid
        
    .PARAMETER EnumName
        Name of the enumerations (enums) you are searching for
        
        The parameter is Case Insensitive, to make it easier for the user to locate the correct enumerations (enums)
        
    .PARAMETER EnumNameContains
        Name of the enumerations (enums) you are searching for, but instructing the cmdlet to use search logic
        
        Using this parameter enables you to supply only a portion of the name for the enumerations (enums) you are looking for, and still get a valid result back
        
        The parameter is Case Insensitive, to make it easier for the user to locate the correct enumerations (enums)
        
    .PARAMETER ODataQuery
        Valid OData query string that you want to pass onto the D365 OData endpoint while retrieving data
        
        Important note:
        If you are using -EnumName or -EnumNameContains along with the -ODataQuery, you need to understand that the "$filter" query is already started. Then you need to start with -ODataQuery ' and XYZ eq XYZ', e.g. -ODataQuery ' and IsReadOnly eq false'
        If you are using the -ODataQuery alone, you need to start the OData Query string correctly. -ODataQuery '$filter=IsReadOnly eq false'
        
        OData specific query options are:
        $filter
        $expand
        $select
        $orderby
        $top
        $skip
        
        Each option has different characteristics, which is well documented at: http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part2-url-conventions.html
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through MetaData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the MetaData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to include the outer structure of the response received from MetaData endpoint
        
        The output will still be a PSCustomObject
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEnum
        
        This will list all available enumerations (enums).
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEnum -Tenant "e674da86-7ee5-40a7-b777-1111111111111" -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -ClientId "dea8d7a9-1602-4429-b138-111111111111" -ClientSecret "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522"
        
        This will list all available enumerations (enums).
        
        It will use "e674da86-7ee5-40a7-b777-1111111111111" as the Azure Active Directory guid.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the base D365FO environment url.
        It will use "dea8d7a9-1602-4429-b138-111111111111" as the ClientId.
        It will use "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522" as ClientSecret.
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEnum -EnumName VendRequestRoleType
        
        This will list the VendRequestRoleType enumerations (enums).
        
        It will use the default OData configuration details that are stored in the configuration store.
        
        Sample output:
        
        EnumName            EnumValueName EnumIntValue EnumValueLabelId
        --------            ------------- ------------ ----------------
        VendRequestRoleType None                     0 @SYS1369
        VendRequestRoleType Admin                    1 @SYS20515
        VendRequestRoleType Clerk                    2 @SYS130176
        
    .EXAMPLE
        PS C:\> Get-D365ODataPublicEnum -EnumNameContains VendRequestRole
        
        This will search for all enumerations (enums) that matches the VendRequestRole search pattern.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
        Sample output:
        
        EnumName            EnumValueName EnumIntValue EnumValueLabelId
        --------            ------------- ------------ ----------------
        VendRequestRoleType None                     0 @SYS1369
        VendRequestRoleType Admin                    1 @SYS20515
        VendRequestRoleType Clerk                    2 @SYS130176
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365ODataPublicEnum -Token $token
        
        This will list all available enumerations (enums).
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .NOTES
        The OData standard is using the $ (dollar sign) for many functions and features, which in PowerShell is normally used for variables.
        
        Whenever you want to use the different query options, you need to take the $ sign and single quotes into consideration.
        
        Example of an execution where I want the top 1 result only, from a specific legal entity / company.
        This example is using single quotes, to help PowerShell not trying to convert the $ into a variable.
        Because the OData standard is using single quotes as text qualifiers, we need to escape them with multiple single quotes.
        
        -ODataQuery '$top=1&$filter=dataAreaId eq ''Comp1'''
        
        Tags: OData, MetaData, Enum, Enumerations
        
        Author: Mötz Jensen (@Splaxi)
#>
function Get-D365ODataPublicEnum {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (

        [Parameter(Mandatory = $false, ParameterSetName = "Default")]
        [Alias('LabelId')]
        [string] $EnumName,

        [Parameter(Mandatory = $true, ParameterSetName = "NameContains")]
        [string] $EnumNameContains,

        [Parameter(Mandatory = $false, ParameterSetName = "Default")]
        [Parameter(Mandatory = $false, ParameterSetName = "NameContains")]
        [Parameter(Mandatory = $true, ParameterSetName = "Query")]
        [string] $ODataQuery,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [switch] $RawOutput,

        [switch] $OutputAsJson
    )


    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }

        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EnumName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }
        
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "metadata/PublicEnumerations"
        }
        else {
            $odataEndpoint.Path += "/metadata/PublicEnumerations"
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-TimeSignal -Start

        $odataEndpoint.Query = ""
        
        if (-not ([string]::IsNullOrEmpty($EnumName))) {
            Write-PSFMessage -Level Verbose -Message "Building request for the Metadata OData endpoint for enum named: $EnumName." -Target $EnumName

            $searchEnumName = $EnumName
            $odataEndpoint.Query = "`$filter=(tolower(Name) eq tolower('$EnumName') or tolower(LabelId) eq tolower('$EnumName'))"
        }
        elseif (-not ([string]::IsNullOrEmpty($EnumNameContains))) {
            Write-PSFMessage -Level Verbose -Message "Building request for the Metadata OData endpoint for enum that contains: $EnumNameContains." -Target $EnumNameContains

            $searchEnumName = $EnumNameContains
            $odataEndpoint.Query = "`$filter=(contains(tolower(Name), tolower('$EnumNameContains')) or contains(tolower(LabelId), tolower('$EnumNameContains')))"
        }

        if (-not ([string]::IsNullOrEmpty($ODataQuery))) {
            $odataEndpoint.Query = $($odataEndpoint.Query + "$ODataQuery").Replace("?", "")
        }

        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the Metadata OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)
            $res = Invoke-RestMethod -Method Get -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType 'application/json'

            if (-not ($RawOutput)) {
                $res = $res.Value | Sort-Object -Property Name
            }

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                foreach ($item in $res) {
                    $item.Members | Sort-Object Value | Select-PSFObject @{Name = "EnumName"; Expression = { $item.Name } }, "Name as EnumValueName", "Value as EnumIntValue", "LabelId as EnumValueLabelId"
                }
            }
        }
        catch {
            $messageString = "Something went wrong while searching the Metadata OData endpoint for the entity: $searchEnumName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EnumName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get OAuth 2.0 token to be used against OData or Custom Service
        
    .DESCRIPTION
        Get an OAuth 2.0 bearer token to be used against the OData or Custom Service endpoints of the Dynamics 365 Finance & Operations
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to be working against
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to output the raw token object and all its properties
        
    .EXAMPLE
        PS C:\> Get-D365ODataToken
        
        This will get a bearetrtoken string.
        The output will be a formal formatted bearer token, ready to be used right away.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataToken -RawOutput
        
        This will get an OAuth 2.0 token.
        It will output all properties of the token.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: OData, OAuth, Token, JWT
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365ODataToken {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [Alias('Resource')]
        [string] $Url = $Script:ODataUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [switch] $EnableException,

        [switch] $RawOutput
    )

    begin {
        if ([System.String]::IsNullOrEmpty($Url)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    }

    process {
        $bearerParms = @{
            Resource     = $Url
            ClientId     = $ClientId
            ClientSecret = $ClientSecret
        }
    
        $azureUri = $Script:AzureTenantOauthToken
        
        $bearerParms.AuthProviderUri = $azureUri -f $Tenant

        $tokenObj = Invoke-ClientCredentialsGrant @bearerParms
            
        if ($RawOutput) {
            $tokenObj
        }
        else {
            $tokenObj | Get-BearerToken
        }
    }
}


<#
    .SYNOPSIS
        Get OAuth 2.0 token to be used against OData or Custom Service, via an interactive sign-in flow
        
    .DESCRIPTION
        Get an OAuth 2.0 bearer token to be used against the OData or Custom Service endpoints of the Dynamics 365 Finance & Operations
        
        It will be running as an interactive sign-in flow, based on what is know as the device authentication flow
        
        Your clipboard will be set with a device code, and your default browser will navigate to "https://microsoft.com/devicelogin"
        You will have to paste in the device code, and complete an ordinary sign-in with your credentials
        When your sign-in is complete, it will pick up the OAuth 2.0 bearer token from the Azure AD
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to be working against
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER Timeout
        Instruct the cmdlet how long time you need to be able to complete the interactive logon
        
        The default value is: 300 seconds
        
        Note: The parameter doesn't show up in the intellisense when tabbing through all available parameters, as it shouldn't be necessary to change the value
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to output the raw token object and all its properties
        
    .EXAMPLE
        PS C:\> Get-D365ODataTokenInteractive
        
        This will start an interactive sign-in process to the Azure AD.
        It will utilize the active OData configuration for the Tenant(Id) and the Url (Resource).
        It will copy the device code into your clipboard.
        It will start the default browser and nagivate to "https://microsoft.com/devicelogin".
        It will wait the default amount of seconds for you to complete the interactive sign-in.
        
        The output will be a formal formatted bearer token, ready to be used right away.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataTokenInteractive -RawOutput
        
        This will start an interactive sign-in process to the Azure AD.
        It will utilize the active OData configuration for the Tenant(Id) and the Url (Resource).
        It will copy the device code into your clipboard.
        It will start the default browser and nagivate to "https://microsoft.com/devicelogin".
        It will wait the default amount of seconds for you to complete the interactive sign-in.
        
        It will output all properties of the token.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataTokenInteractive -Timeout 100
        
        This will start an interactive sign-in process to the Azure AD.
        It will utilize the active OData configuration for the Tenant(Id) and the Url (Resource).
        It will copy the device code into your clipboard.
        It will start the default browser and nagivate to "https://microsoft.com/devicelogin".
        It will wait 100 seconds for you to complete the interactive sign-in.
        
        The output will be a formal formatted bearer token, ready to be used right away.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365ODataTokenInteractive | Set-D365ODataTokenInSession
        
        This sets the Token parameter value for all cmdlets, for the remaining of the session.
        It gets a token from the Get-D365ODataTokenInteractive cmdlet and pipes it into Set-D365ODataTokenInSession.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: OData, OAuth, Token, JWT, DeviceAuth, Device, DeviceCode
        
        Inspiration: https://blog.simonw.se/getting-an-access-token-for-azuread-using-powershell-and-device-login-flow/
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365ODataTokenInteractive {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [Alias('Resource')]
        [string] $Url = $Script:ODataUrl,

        [Parameter(DontShow = $true)]
        [int] $Timeout = 300,
        
        [switch] $EnableException,

        [switch] $RawOutput
    )

    begin {
        if ([System.String]::IsNullOrEmpty($Url)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }

        # Known ClientId for PowerShell in Azure AD
        $clientID = '1950a258-227b-4e31-a9cf-717495945fc2'

    }

    process {
        $azureUriDeviceCode = $Script:AzureTenantOauthDevicecode
        $azureUriToken = $Script:AzureTenantOauthToken
        
        $DeviceCodeRequestParams = @{
            Method = 'POST'
            Body   = @{
                resource  = $Url
                client_id = $ClientId
            }
        }
        $DeviceCodeRequestParams.Uri = $azureUriDeviceCode -f $Tenant

        $DeviceCodeRequest = Invoke-RestMethod @DeviceCodeRequestParams

        $DeviceCodeRequest.user_code | Set-Clipboard
        Write-PSFMessage -Level Host -Message "The device code <c='em'>$($DeviceCodeRequest.user_code)</c> has been copied into your clipboard."
        Start-Sleep -Seconds 2
        Write-PSFMessage -Level Host -Message "Will start the default browser and have it open the <c='em'>$($DeviceCodeRequest.verification_url)</c> page, where you need to <c='em'>paste</c> the code in and complete sign-in with your credentials."
        Start-Sleep -Seconds 2
        Start-Process $DeviceCodeRequest.verification_url
            
        $TokenRequestParams = @{
            Method = 'POST'
            Body   = @{
                grant_type = "urn:ietf:params:oauth:grant-type:device_code"
                code       = $DeviceCodeRequest.device_code
                client_id  = $ClientId
            }
        }
        $TokenRequestParams.Uri = $azureUriToken -f $Tenant

        $TimeoutTimer = [System.Diagnostics.Stopwatch]::StartNew()
        while ([string]::IsNullOrEmpty($tokenObj.access_token)) {
            if (Test-PSFFunctionInterrupt) { return }

            if ($TimeoutTimer.Elapsed.TotalSeconds -gt $Timeout) {
                $messageString = "The login session <c='em'>timed out</c>. You have <c='em'>$Timeout seconds</c> to complete the sign-in operation."
                Write-PSFMessage -Level Host -Message $messageString
                Stop-PSFFunction -Message "Stopping because login took to long." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', '')))
                return
            }
            $tokenObj = try {
                Invoke-RestMethod @TokenRequestParams -ErrorAction Stop
            }
            catch {
                $Message = $_.ErrorDetails.Message | ConvertFrom-Json
                if ($Message.error -ne "authorization_pending") {
                    throw
                }
            }
            Start-Sleep -Seconds 1
        }

        if ($RawOutput) {
            $tokenObj
        }
        else {
            $tokenObj | Get-BearerToken
        }
    }
}


<#
    .SYNOPSIS
        Get Service Group from the Json Service endpoint
        
    .DESCRIPTION
        Get available Service Group from the Json Service endpoint of the Dynamics 365 Finance & Operations instance
        
    .PARAMETER ServiceGroupName
        Name of the Service Group that you want to be working against
        
    .PARAMETER ServiceName
        Name of the Service that you are looking for
        
        The parameter supports wildcards. E.g. -ServiceName "*Timesheet*"
        
        Default value is "*" to list all services from the specific Service Group
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the Json Service endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to include the outer structure of the response received from Json Service endpoint
        
        The output will still be a PSCustomObject
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365RestService -ServiceGroupName "DMFService"
        
        This will list all services that are available from the Service Group "DMFService", from the Dynamics 365 Finance & Operations instance.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName ServiceName
        ---------------- -----------
        DMFService       DMFDataPackager
        DMFService       DMFDefinitionGroupService
        DMFService       DMFEntityWriterService
        DMFService       DMFProcessGrpService
        DMFService       DMFStagingService
        
    .EXAMPLE
        PS C:\> Get-D365RestService -ServiceGroupName "DMFService" -ServiceName "*service*"
        
        This will list all available Services from the Service Group "DMFService", which matches the "*service*" pattern, from the Dynamics 365 Finance & Operations instance.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName ServiceName
        ---------------- -----------
        DMFService       DMFDefinitionGroupService
        DMFService       DMFEntityWriterService
        DMFService       DMFProcessGrpService
        DMFService       DMFStagingService
        
    .EXAMPLE
        PS C:\> Get-D365RestServiceGroup -Name "DMFService" | Get-D365RestService
        
        This will list all available Service Groups, which matches the "DMFService" pattern, from the Dynamics 365 Finance & Operations instance.
        It will pipe all Service Groups into the Get-D365RestService cmdlet, and have it output all Services available from the Service Group.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName ServiceName
        ---------------- -----------
        DMFService       DMFDataPackager
        DMFService       DMFDefinitionGroupService
        DMFService       DMFEntityWriterService
        DMFService       DMFProcessGrpService
        DMFService       DMFStagingService
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365RestService -ServiceGroupName "DMFService" -Token $token
        
        This will list all services that are available from the Service Group "DMFService", from the Dynamics 365 Finance & Operations instance.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName ServiceName
        ---------------- -----------
        DMFService       DMFDataPackager
        DMFService       DMFDefinitionGroupService
        DMFService       DMFEntityWriterService
        DMFService       DMFProcessGrpService
        DMFService       DMFStagingService
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: Json, Data, Service, Operations
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365RestService {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ServiceGroupName,

        [string] $ServiceName = "*",

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [switch] $RawOutput,

        [switch] $OutputAsJson

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the Json Services endpoint"
        
        [System.UriBuilder] $restEndpoint = $SystemUrl

        if ($restEndpoint.Path -eq "/") {
            $restEndpoint.Path = "api/services/$ServiceGroupName"
        }
        else {
            $restEndpoint.Path += "/api/services/$ServiceGroupName"
        }

        $params = @{ }
        $params.Uri = $restEndpoint.Uri.AbsoluteUri
        $params.Headers = $headers
        $params.ContentType = "application/json"
        $params.Method = "GET"
        
        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the REST endpoint." -Target $($restEndpoint.Uri.AbsoluteUri)
            $res = Invoke-RestMethod @params

            if (-not $RawOutput) {
                $res = $res.Services | Where-Object { $_.Name -Like $ServiceName -or $_.Name -eq $ServiceName } | Sort-Object Name
            }
            else {
                $res.Services = @($res.Services | Where-Object { $_.Name -Like $ServiceName -or $_.Name -eq $ServiceName }) | Sort-Object Name
            }
        
            $obj = [PSCustomObject]@{ ServiceGroupName = $ServiceGroupName }
            #Hack to silence the PSScriptAnalyzer
            $obj | Out-Null

            $res = $res | Select-PSFObject "ServiceGroupName from obj", "Name as ServiceName"

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch {
            $messageString = "Something went wrong while importing data through the REST endpoint for the entity: $ServiceName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $ServiceName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get Service Group from the Json Service endpoint
        
    .DESCRIPTION
        Get available Service Group from the Json Service endpoint of the Dynamics 365 Finance & Operations instance
        
    .PARAMETER Name
        Name of the Service Group that you are looking for
        
        The parameter supports wildcards. E.g. -Name "*Timesheet*"
        
        Default value is "*" to list all service groups
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the Json Service endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to include the outer structure of the response received from Json Service endpoint
        
        The output will still be a PSCustomObject
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365RestServiceGroup
        
        This will list all available Service Groups from the Dynamics 365 Finance & Operations instance.
        
        It will use the default configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Get-D365RestServiceGroup -Name "*service*"
        
        This will list all available Service Groups, which matches the "*service*" pattern, from the Dynamics 365 Finance & Operations instance.
        
        It will use the default configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365RestServiceGroup -Token $token
        
        This will list all available Service Groups from the Dynamics 365 Finance & Operations instance.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        
        It will use the default configuration details that are stored in the configuration store.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: Json, Data, Service, Operations
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365RestServiceGroup {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [string] $Name = "*",

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [switch] $RawOutput,

        [switch] $OutputAsJson

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the Json Services endpoint"
        
        [System.UriBuilder] $restEndpoint = $SystemUrl

        if ($restEndpoint.Path -eq "/") {
            $restEndpoint.Path = "api/services"
        }
        else {
            $restEndpoint.Path += "/api/services"
        }

        $params = @{ }
        $params.Uri = $restEndpoint.Uri.AbsoluteUri
        $params.Headers = $headers
        $params.ContentType = "application/json"
        $params.Method = "GET"
        
        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the REST endpoint." -Target $($restEndpoint.Uri.AbsoluteUri)
            $res = Invoke-RestMethod @params

            if (-not $RawOutput) {
                $res = $res.ServiceGroups | Where-Object { $_.Name -Like $Name -or $_.Name -eq $Name } | Sort-Object Name
            }
            else {
                $res.ServiceGroups = @($res.ServiceGroups | Where-Object { $_.Name -Like $Name -or $_.Name -eq $Name }) | Sort-Object Name
            }
        
            $res = $res | Select-PSFObject "Name as ServiceGroupName"

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch {
            $messageString = "Something went wrong while importing data through the REST endpoint for the entity: $ServiceName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $ServiceName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get Service Group from the Json Service endpoint
        
    .DESCRIPTION
        Get available Service Group from the Json Service endpoint of the Dynamics 365 Finance & Operations instance
        
    .PARAMETER ServiceGroupName
        Name of the Service Group that you want to be working against
        
    .PARAMETER ServiceName
        Name of the Service that you want to be working against
        
    .PARAMETER OperationName
        Name of the Operation that you are looking for
        
        The parameter supports wildcards. E.g. -OperationName "*Get*"
        
        Default value is "*" to list all operations from the specific Service Group and Service combination
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the Json Service endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER RawOutput
        Instructs the cmdlet to include the outer structure of the response received from Json Service endpoint
        
        The output will still be a PSCustomObject
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365RestServiceOperation -ServiceGroupName "BIServices" -ServiceName "SRSFrameworkService"
        
        This will list all available Operations from the Service Group "DMFService" and ServiceName "SRSFrameworkService" combinantion, from the Dynamics 365 Finance & Operations instance.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName ServiceName         OperationName
        ---------------- -----------         -------------
        BIServices       SRSFrameworkService addReportServerConfiguration
        BIServices       SRSFrameworkService clearReportRDLCache
        BIServices       SRSFrameworkService getAccountsForBrowserRole
        BIServices       SRSFrameworkService getAosUtcNow
        BIServices       SRSFrameworkService getApplicationObjectServers
        BIServices       SRSFrameworkService getAssemblies
        
    .EXAMPLE
        PS C:\> Get-D365RestServiceOperation -ServiceGroupName "BIServices" -ServiceName "SRSFrameworkService" -OperationName "*report*"
        
        This will list all available Operations from the Service Group "DMFService" and ServiceName "SRSFrameworkService" combinantion, which macthes the pattern "*report*", from the Dynamics 365 Finance & Operations instance.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName ServiceName         OperationName
        ---------------- -----------         -------------
        BIServices       SRSFrameworkService addReportServerConfiguration
        BIServices       SRSFrameworkService clearReportRDLCache
        BIServices       SRSFrameworkService getReportDataSources
        BIServices       SRSFrameworkService getReportDesigns
        BIServices       SRSFrameworkService getReportDetails
        BIServices       SRSFrameworkService getReportFullPath
        
    .EXAMPLE
        PS C:\> Get-D365RestServiceGroup -Name "BIServices" | Get-D365RestService | Get-D365RestServiceOperation
        
        This will list all available Service Groups, which matches the "BIServices" pattern, from the Dynamics 365 Finance & Operations instance.
        It will pipe all Service Groups into the Get-D365RestService cmdlet, and pipe all Services available into the Get-D365RestServiceOperation cmdlet.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName ServiceName         OperationName
        ---------------- -----------         -------------
        BIServices       SRSFrameworkService addReportServerConfiguration
        BIServices       SRSFrameworkService clearReportRDLCache
        BIServices       SRSFrameworkService getAccountsForBrowserRole
        BIServices       SRSFrameworkService getAosUtcNow
        BIServices       SRSFrameworkService getApplicationObjectServers
        BIServices       SRSFrameworkService getAssemblies
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365RestServiceOperation -ServiceGroupName "BIServices" -ServiceName "SRSFrameworkService" -Token $token
        
        This will list all available Operations from the Service Group "DMFService" and ServiceName "SRSFrameworkService" combinantion, from the Dynamics 365 Finance & Operations instance.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName ServiceName         OperationName
        ---------------- -----------         -------------
        BIServices       SRSFrameworkService addReportServerConfiguration
        BIServices       SRSFrameworkService clearReportRDLCache
        BIServices       SRSFrameworkService getAccountsForBrowserRole
        BIServices       SRSFrameworkService getAosUtcNow
        BIServices       SRSFrameworkService getApplicationObjectServers
        BIServices       SRSFrameworkService getAssemblies
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: OData, Data, Entity, Query
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365RestServiceOperation {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ServiceGroupName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ServiceName,

        [string] $OperationName = "*",

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [switch] $RawOutput,

        [switch] $OutputAsJson

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the Json Services endpoint"
        
        [System.UriBuilder] $restEndpoint = $SystemUrl

        if ($restEndpoint.Path -eq "/") {
            $restEndpoint.Path = "api/services/$ServiceGroupName/$ServiceName"
        }
        else {
            $restEndpoint.Path += "/api/services/$ServiceGroupName/$ServiceName"
        }

        $params = @{ }
        $params.Uri = $restEndpoint.Uri.AbsoluteUri
        $params.Headers = $headers
        $params.ContentType = "application/json"
        $params.Method = "GET"
        
        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the REST endpoint." -Target $($restEndpoint.Uri.AbsoluteUri)
            $res = Invoke-RestMethod @params

            if (-not $RawOutput) {
                $res = $res.Operations | Where-Object { $_.Name -Like $OperationName -or $_.Name -eq $OperationName } | Sort-Object Name
            }
            else {
                $res.Operations = @($res.Operations | Where-Object { $_.Name -Like $OperationName -or $_.Name -eq $OperationName }) | Sort-Object Name
            }
        
            $obj = [PSCustomObject]@{ ServiceGroupName = $ServiceGroupName; ServiceName = $ServiceName }
            #Hack to silence the PSScriptAnalyzer
            $obj | Out-Null
                        
            $res = $res | Select-PSFObject "ServiceGroupName from obj", "ServiceName from obj", "Name as OperationName"

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch {
            $messageString = "Something went wrong while importing data through the REST endpoint for the entity: $ServiceName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $ServiceName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Get Service Group from the Json Service endpoint
        
    .DESCRIPTION
        Get available Service Group from the Json Service endpoint of the Dynamics 365 Finance & Operations instance
        
    .PARAMETER ServiceGroupName
        Name of the Service Group that you want to be working against
        
    .PARAMETER ServiceName
        Name of the Service that you want to be working against
        
    .PARAMETER OperationName
        Name of the Operation that you want to be working against
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the Json Service endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .EXAMPLE
        PS C:\> Get-D365RestServiceOperationDetails -ServiceGroupName "ERWebServices" -ServiceName "ERPullSolutionFromRepositoryService" -OperationName "Execute"
        
        This will list all available Operation details from the Service Group "ERWebServices", ServiceName "ERPullSolutionFromRepositoryService" and OperationName "Execute" combinantion, from the Dynamics 365 Finance & Operations instance.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName : ERWebServices
        ServiceName      : ERPullSolutionFromRepositoryService
        OperationName    : Execute
        Parameters       : {@{Name=_request; Type=PullSolutionFromRepositoryRequest}}
        Return           : @{Name=return; Type=PullSolutionFromRepositoryResponse}
        
    .EXAMPLE
        PS C:\> Get-D365RestServiceGroup -Name "ERWebServices" | Get-D365RestService | Get-D365RestServiceOperation | Get-D365RestServiceOperationDetails
        
        This will list all available Operation details from the Service Group "ERWebServices", all available services, and all available operations for each service, from the Dynamics 365 Finance & Operations instance.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName : ERWebServices
        ServiceName      : ERPullSolutionFromRepositoryService
        OperationName    : Execute
        Parameters       : {@{Name=_request; Type=PullSolutionFromRepositoryRequest}}
        Return           : @{Name=return; Type=PullSolutionFromRepositoryResponse}
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Get-D365RestServiceOperationDetails -ServiceGroupName "ERWebServices" -ServiceName "ERPullSolutionFromRepositoryService" -OperationName "Execute" -Token $token
        
        This will list all available Operation details from the Service Group "ERWebServices", ServiceName "ERPullSolutionFromRepositoryService" and OperationName "Execute" combinantion, from the Dynamics 365 Finance & Operations instance.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        
        It will use the default configuration details that are stored in the configuration store.
        
        Sample output:
        
        ServiceGroupName : ERWebServices
        ServiceName      : ERPullSolutionFromRepositoryService
        OperationName    : Execute
        Parameters       : {@{Name=_request; Type=PullSolutionFromRepositoryRequest}}
        Return           : @{Name=return; Type=PullSolutionFromRepositoryResponse}
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        The OData standard is using the $ (dollar sign) for many functions and features, which in PowerShell is normally used for variables.
        
        Whenever you want to use the different query options, you need to take the $ sign and single quotes into consideration.
        
        Example of an execution where I want the top 1 result only, from a specific legal entity / company.
        This example is using single quotes, to help PowerShell not trying to convert the $ into a variable.
        Because the OData standard is using single quotes as text qualifiers, we need to escape them with multiple single quotes.
        
        -ODataQuery '$top=1&$filter=dataAreaId eq ''Comp1'''
        
        Tags: OData, Data, Entity, Query
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Get-D365RestServiceOperationDetails {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ServiceGroupName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ServiceName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $OperationName,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [switch] $OutputAsJson

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the Json Services endpoint"
        
        [System.UriBuilder] $restEndpoint = $SystemUrl

        if ($restEndpoint.Path -eq "/") {
            $restEndpoint.Path = "api/services/$ServiceGroupName/$ServiceName/$OperationName"
        }
        else {
            $restEndpoint.Path += "/api/services/$ServiceGroupName/$ServiceName/$OperationName"
        }

        $params = @{ }
        $params.Uri = $restEndpoint.Uri.AbsoluteUri
        $params.Headers = $headers
        $params.ContentType = "application/json"
        $params.Method = "GET"
        
        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the REST endpoint." -Target $($restEndpoint.Uri.AbsoluteUri)
            $res = Invoke-RestMethod @params
        
            $obj = [PSCustomObject]@{ ServiceGroupName = $ServiceGroupName; ServiceName = $ServiceName; OperationName = $OperationName }
            #Hack to silence the PSScriptAnalyzer
            $obj | Out-Null

            $res = $res | Select-PSFObject "ServiceGroupName from obj", "ServiceName from obj", "OperationName from obj", "Parameters", "Return"

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch {
            $messageString = "Something went wrong while importing data through the REST endpoint for the entity: $ServiceName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $ServiceName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Import a DMF package into Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Imports a DMF package into the DMF endpoint of the Dynamics 365 Finance & Operations
        
    .PARAMETER Path
        Path of the file that you want to import into D365FO
        
    .PARAMETER JobId
        JobId of the DMF job you want to import into
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through DMF
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through DMF
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Import-D365DmfPackage -Path "c:\temp\d365fo.tools\dmfpackage.zip" -JobId "db5e719a-8db3-4fe5-9c78-7be479ce85a2"
        
        This will import a package into the 123456789 job through the DMF endpoint.
        It will use "c:\temp\d365fo.tools\dmfpackage.zip" as the location to read the file from.
        It will use "db5e719a-8db3-4fe5-9c78-7be479ce85a2" as the jobid parameter passed to the DMF endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Import-D365DmfPackage -Path "c:\temp\d365fo.tools\dmfpackage.zip" -JobId "db5e719a-8db3-4fe5-9c78-7be479ce85a2" -Tenant "e674da86-7ee5-40a7-b777-1111111111111" -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -ClientId "dea8d7a9-1602-4429-b138-111111111111" -ClientSecret "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522"
        
        This will import a package into the 123456789 job through the DMF endpoint.
        It will use "c:\temp\d365fo.tools\dmfpackage.zip" as the location to read the file from.
        It will use "db5e719a-8db3-4fe5-9c78-7be479ce85a2" as the jobid parameter passed to the DMF endpoint.
        It will use "e674da86-7ee5-40a7-b777-1111111111111" as the Azure Active Directory guid.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the base D365FO environment url.
        It will use "dea8d7a9-1602-4429-b138-111111111111" as the ClientId.
        It will use "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522" as ClientSecret.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Get-D365DmfMessageStatus
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: Import, Upload, DMF, Package, Packages, JobId
        
        Author: Mötz Jensen (@Splaxi)
#>

function Import-D365DmfPackage {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('File')]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [String] $JobId,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [switch] $EnableException

    )

    begin {
        $bearerParms = @{
            Url          = $Url
            ClientId     = $ClientId
            ClientSecret = $ClientSecret
            Tenant       = $Tenant
        }

        $bearer = New-BearerToken @bearerParms
    }

    process {
        Invoke-TimeSignal -Start

        $dmfParms = @{
            JobId               = $JobId
            Url                 = $Url
            AuthenticationToken = $bearer
            Path                = $Path
        }

        $dmfDetails = Invoke-DmfEnqueuePackage @dmfParms -EnableException:$EnableException

        if ([string]::IsNullOrWhiteSpace($dmfDetails)) {
            Write-PSFMessage -Level Verbose -Message "Output object is null" -Target $Var
        }

        [PSCustomObject]@{
            MessageId = $dmfDetails.Replace('"', '')
        }
        
        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Import a Data Entity into Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Imports a Data Entity, defined as a json payload, using the OData endpoint of the Dynamics 365 Finance & Operations platform
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER Payload
        The entire string contain the json object that you want to import into the D365FO environment
        
        Remember that json is text based and can use either single quotes (') or double quotes (") as the text qualifier, so you might need to escape the different quotes in your payload before passing it in
        
    .PARAMETER PayloadCharset
        The charset / encoding that you want the cmdlet to use while importing the odata entity
        
        The default value is: "UTF8"
        
        The charset has to be a valid http charset like: ASCII, ANSI, ISO-8859-1, UTF-8
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will work across all companies
        
    .PARAMETER RetryTimeout
        The retry timeout, before the cmdlet should quit retrying based on the 429 status code
        
        Needs to be provided in the timspan notation:
        "hh:mm:ss"
        
        hh is the number of hours, numerical notation only
        mm is the number of minutes
        ss is the numbers of seconds
        
        Each section of the timeout has to valid, e.g.
        hh can maximum be 23
        mm can maximum be 59
        ss can maximum be 59
        
        Not setting this parameter will result in the cmdlet to try for ever to handle the 429 push back from the endpoint
        
    .PARAMETER ThrottleSeed
        Instruct the cmdlet to invoke a thread sleep between 1 and ThrottleSeed value
        
        This is to help to mitigate the 429 retry throttling on the OData / Custom Service endpoints
        
        It makes most sense if you are running things a outer loop, where you will hit the OData / Custom Service endpoints with a burst of calls in a short time
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Import-D365ODataEntity -EntityName "ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}'
        
        This will import a Data Entity into Dynamics 365 Finance & Operations using the OData endpoint.
        The EntityName used for the import is ExchangeRates.
        The Payload is a valid json string, containing all the needed properties.
        
    .EXAMPLE
        PS C:\> $Payload = '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}'
        PS C:\> Import-D365ODataEntity -EntityName "ExchangeRates" -Payload $Payload
        
        This will import a Data Entity into Dynamics 365 Finance & Operations using the OData endpoint.
        First the desired json data is put into the $Payload variable.
        The EntityName used for the import is ExchangeRates.
        The $Payload variable is passed to the cmdlet.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Import-D365ODataEntity -EntityName "ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' -Token $token
        
        This will import a Data Entity into Dynamics 365 Finance & Operations using the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        The EntityName used for the import is ExchangeRates.
        The Payload is a valid json string, containing all the needed properties.
        
    .EXAMPLE
        PS C:\> Import-D365ODataEntity -EntityName "ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' -RetryTimeout "00:01:00"
        
        This will import a Data Entity into Dynamics 365 Finance & Operations using the OData endpoint, and try for 1 minute to handle 429.
        The EntityName used for the import is ExchangeRates.
        The Payload is a valid json string, containing all the needed properties.
        It will only try to handle 429 retries for 1 minute, before failing.
        
    .EXAMPLE
        PS C:\> Import-D365ODataEntity -EntityName "ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' -ThrottleSeed 2
        
        This will import a Data Entity into Dynamics 365 Finance & Operations using the OData endpoint, and sleep/pause between 1 and 2 seconds.
        The EntityName used for the import is ExchangeRates.
        The Payload is a valid json string, containing all the needed properties.
        It will use the ThrottleSeed 2 to sleep/pause the execution, to mitigate the 429 pushback from the endpoint.
        
    .NOTES
        Tags: OData, Data, Entity, Import, Upload
        
        Author: Mötz Jensen (@Splaxi)
#>

function Import-D365ODataEntity {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $EntityName,

        [Parameter(Mandatory = $true)]
        [Alias('Json')]
        [string] $Payload,

        [string] $PayloadCharset = "UTF-8",

        [switch] $CrossCompany,

        [Timespan] $RetryTimeout = "00:00:00",
        
        [int] $ThrottleSeed,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException
    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
        
        $PayloadCharset = $PayloadCharset.ToLower()
        if ($PayloadCharset -like "utf*" -and $PayloadCharset -notlike "utf-*") {
            $PayloadCharset = $PayloadCharset -replace "utf", "utf-"
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the OData endpoint for entity named: $EntityName." -Target $EntityName
        
        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "data/$EntityName"
        }
        else {
            $odataEndpoint.Path += "/data/$EntityName"
        }

        if ($CrossCompany) {
            $odataEndpoint.Query = "cross-company=true"
        }

        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)
            Invoke-RequestHandler -Method POST -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType "application/json;charset=$PayloadCharset" -Payload $Payload -RetryTimeout $RetryTimeout
        
            if (Test-PSFFunctionInterrupt) { return }

        }
        catch {
            $messageString = "Something went wrong while importing data through the OData endpoint for the entity: $EntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        if ($ThrottleSeed) {
            Start-Sleep -Seconds $(Get-Random -Minimum 1 -Maximum $ThrottleSeed)
        }
        
        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Import a set of Data Entities into Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Imports a set of Data Entities, defined as a json payloads, using the OData endpoint of the Dynamics 365 Finance & Operations
        
        The entire payload will be batched into a single request against the OData endpoint
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER Payload
        The entire string contain the json objects that you want to import into the D365FO environment
        
        Payload supports multiple json objects, that needs to be batched together
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will work across all companies
        
    .PARAMETER ThrottleSeed
        Instruct the cmdlet to invoke a thread sleep between 1 and ThrottleSeed value
        
        This is to help to mitigate the 429 retry throttling on the OData / Custom Service endpoints
        
        It makes most sense if you are running things a outer loop, where you will hit the OData / Custom Service endpoints with a burst of calls in a short time
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER RawOutput
        Instructs the cmdlet to output the raw json string directly
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Import-D365ODataEntityBatchMode -EntityName "ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}','{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-04T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}'
        
        This will import a set of Data Entities into Dynamics 365 Finance & Operations using the OData endpoint.
        The EntityName used for the import is ExchangeRates.
        The Payload is an array containing valid json strings, each containing all the needed properties.
        
    .EXAMPLE
        PS C:\> $Payload = '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}','{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-04T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}'
        PS C:\> Import-D365ODataEntityBatchMode -EntityName "ExchangeRates" -Payload $Payload
        
        This will import a set of Data Entities into Dynamics 365 Finance & Operations using the OData endpoint.
        First the desired json data is put into the $Payload variable.
        The EntityName used for the import is ExchangeRates.
        The $Payload variable is passed to the cmdlet.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Import-D365ODataEntityBatchMode -EntityName "ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}','{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-04T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' -Token $token
        
        This will import a set of Data Entities into Dynamics 365 Finance & Operations using the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        The EntityName used for the import is ExchangeRates.
        The Payload is an array containing valid json strings, each containing all the needed properties.
        
    .EXAMPLE
        PS C:\> Import-D365ODataEntityBatchMode -EntityName "ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}','{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-04T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}'
        
        This will import a set of Data Entities into Dynamics 365 Finance & Operations using the OData endpoint.
        The EntityName used for the import is ExchangeRates.
        The Payload is an array containing valid json strings, each containing all the needed properties.
        
    .EXAMPLE
        PS C:\> Import-D365ODataEntityBatchMode -EntityName "ExchangeRates" -Payload '{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}','{"@odata.type" :"Microsoft.Dynamics.DataEntities.ExchangeRate", "RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-04T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}' -ThrottleSeed 2
        
        This will import a set of Data Entities into Dynamics 365 Finance & Operations using the OData endpoint, and sleep/pause between 1 and 2 seconds.
        The EntityName used for the import is ExchangeRates.
        The Payload is an array containing valid json strings, each containing all the needed properties.
        It will use the ThrottleSeed 2 to sleep/pause the execution, to mitigate the 429 pushback from the endpoint.
        
    .NOTES
        Tags: OData, Data, Entity, Import, Upload
        
        Author: Mötz Jensen (@Splaxi)
#>

function Import-D365ODataEntityBatchMode {
    [CmdletBinding()]
    [OutputType('System.String')]
    param (
        [Parameter(Mandatory = $true)]
        [string] $EntityName,

        [Parameter(Mandatory = $true)]
        [Alias('Json')]
        [string[]] $Payload,

        [switch] $CrossCompany,

        [int] $ThrottleSeed,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [switch] $RawOutput,
        
        [string] $Token,
        
        [switch] $EnableException

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }
        
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        $dataBuilder = [System.Text.StringBuilder]::new()

    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building batch request for the OData endpoint for entity named: $EntityName." -Target $EntityName

        $idbatch = $(New-Guid).ToString()
        $idchangeset = $(New-Guid).ToString()
    
        $batchPayload = "batch_$idbatch"
        $changesetPayload = "changeset_$idchangeset"
        
        $request = [System.Net.WebRequest]::Create("$SystemUrl/data/`$batch")
        $request.Headers["Authorization"] = $headers.Authorization
        $request.Method = "POST"
        $request.ContentType = "multipart/mixed; boundary=batch_$idBatch"

        $dataBuilder.Clear() > $null

        $dataBuilder.AppendLine("--$batchPayLoad ") > $null #Space is important!
        $dataBuilder.AppendLine("Content-Type: multipart/mixed; boundary=changeset_$idchangeset {0}" -f [System.Environment]::NewLine) > $null
        $dataBuilder.AppendLine("--$changeSetPayLoad ") > $null #Space is important!

        $localEntity = $EntityName
        $payLoadEnumerator = $PayLoad.GetEnumerator()
        $counter = 0
        while ($payLoadEnumerator.MoveNext()) {

            Write-PSFMessage -Level Verbose -Message "Parsing the payload for the batch request."

            $counter ++
            $localPayload = $payLoadEnumerator.Current.Trim()

            $dataBuilder.Append((New-BatchContent -Url "$SystemUrl/data/$localEntity" -Payload $LocalPayload -Count $counter)) > $null

            if ($PayLoad.Count -eq $counter) {
                $dataBuilder.AppendLine("--$changesetPayload--") > $null
            }
            else {
                $dataBuilder.AppendLine("--$changesetPayload") > $null
            }
        }
    
        $dataBuilder.Append("--$batchPayload--") > $null
        $data = $dataBuilder.ToString()

        Write-PSFMessage -Level Debug -Message "Parsing data to debug log next."

        Write-PSFMessage -Level Debug -Message $data
        
        Add-WebRequestContent -WebRequest $request -Payload $data
    
        try {
            Write-PSFMessage -Level Verbose -Message "Executing batch http request against the OData endpoint."
           
            $response = $request.GetResponse()

            $stream = $response.GetResponseStream()
    
            $streamReader = New-Object System.IO.StreamReader($stream)
            
            $res = $streamReader.ReadToEnd()
            $streamReader.Close();

            $regex = [regex] "Content-ID: (?<ContentId>[0-9]*)(?:\r\n)*HTTP/(?:1\.1|2\.0) (?<StatusCode>[0-9]*) .*"
            $matchStatus = $regex.Matches($res)

            if (($matchStatus.groups | Where-Object Name -eq "StatusCode").Value -contains "429") {
                $regex = [regex] "Retry-After: (?<RetryValue>[0-9]*)"
                $matchRetry = $regex.Matches($res).groups

                $maxRetryValue = ($matchRetry.groups | Where-Object Name -eq "RetryValue").Value | Sort-Object -Descending | Select-Object -First 1

                $matchThrottled = $matchStatus | Where-Object { $_.Groups.Name -eq "StatusCode" -and $_.Groups.Value -eq "429" }

                foreach ($item in $matchThrottled) {
                    [int]$index = $item.Groups | Where-Object Name -eq "ContentId" | Select-Object -ExpandProperty "Value"
                    $messageString = "The following payload was throttled by the system. The system stated that you should retry in: <c='em'>$maxRetryValue</c>"
                    Write-PSFMessage -Level Host -Message $messageString
                    Write-PSFHostColor -Level Host -String $Payload[$index - 1] -DefaultColor Green
                }

                $res
                
                Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
                return
            }
        }
        catch {
            $messageString = "Something went wrong while importing batch data through the OData endpoint for the entity: $EntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
    
        #Might need to be something else than OK and Created
        if ($response.StatusCode -ne [System.Net.HttpStatusCode]::Ok -and $response.StatusCode -ne [System.Net.HttpStatusCode]::Created) {
            Write-PSFMessage -Level Verbose -Message "Status code not 'Ok' and not 'Created', Description $($response.StatusDescription)"
            Stop-PSFFunction -Message "Stopping" -Exception $([System.Exception]::new("Returned status code indicates that the request was unsuccessful."))
            return
        }

        if ($RawOutput) {
            $res
        }
        else {
            $res | ConvertTo-Json
        }

        if ($ThrottleSeed) {
            Start-Sleep -Seconds $(Get-Random -Minimum 1 -Maximum $ThrottleSeed)
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Invoke DMF Initialize, which will refresh all Data Management Entities
        
    .DESCRIPTION
        Invokes the DMF initialization from the DMF Endpoint of the Dynamics 365 for Finance & Operations environment
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through DMF
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through DMF
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Invoke-D365DmfInit
        
        This will invoke the DMF initialization through the DMF endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Invoke-D365DmfInit -Tenant "e674da86-7ee5-40a7-b777-1111111111111" -Url "https://usnconeboxax1aos.cloud.onebox.dynamics.com" -ClientId "dea8d7a9-1602-4429-b138-111111111111" -ClientSecret "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522"
        
        This will invoke the DMF initialization through the DMF endpoint.
        It will use "e674da86-7ee5-40a7-b777-1111111111111" as the Azure Active Directory guid.
        It will use "https://usnconeboxax1aos.cloud.onebox.dynamics.com" as the base D365FO environment url.
        It will use "dea8d7a9-1602-4429-b138-111111111111" as the ClientId.
        It will use "Vja/VmdxaLOPR+alkjfsadffelkjlfw234522" as ClientSecret.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Invoke-D365DmfInit -Token $token
        
        This will invoke the DMF initialization through the DMF endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
        
    .NOTES
        Tags: DMF, Entities, Enitity, Init, Initialize, Refresh
        
        Author: Mötz Jensen (@Splaxi), Gert Van Der Heyden (@gertvdheyden)
#>

function Invoke-D365DmfInit {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,
        
        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,

        [switch] $EnableException
    )

    begin {
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the DMF Initialize OData endpoint."

        [System.UriBuilder] $odataEndpoint = $URL
        
        $odataEndpoint.Path = "data/DataManagementDefinitionGroups/Microsoft.Dynamics.DataEntities.InitializeDataManagement"

        try {
            
            Write-PSFMessage -Level Verbose -Message "Executing http request against the DMF Initialize OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)
                
            Invoke-RestMethod -Method Post -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType 'application/json' -Body '{}'
        }
        catch {
            $messageString = "Something went wrong while retrieving data from the DMF Initialize OData endpoint"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    
    }

    end {
    }
}


<#
    .SYNOPSIS
        Invoke a Data Entity Action in Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Invokes a Data Entity Action, supporting a json payload as the parameters, using the OData endpoint of the Dynamics 365 Finance & Operations platform
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER Action
        Name of the action that you want to execute on the desired entity
        
    .PARAMETER Payload
        The entire string contain the json object that you want to pass to the action of the desired entity
        
        Remember that json is text based and can use either single quotes (') or double quotes (") as the text qualifier, so you might need to escape the different quotes in your payload before passing it in
        
    .PARAMETER PayloadCharset
        The charset / encoding that you want the cmdlet to use while invoking the odata entity action
        
        The default value is: "UTF8"
        
        The charset has to be a valid http charset like: ASCII, ANSI, ISO-8859-1, UTF-8
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will work across all companies
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER RawOutput
        Instructs the cmdlet to include the outer structure of the response received from OData endpoint
        
        The output will still be a PSCustomObject
        
    .PARAMETER OutputAsJson
        Instructs the cmdlet to convert the output to a Json string
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Invoke-D365ODataEntityAction -EntityName DualWriteProjectConfigurations -Action ValidateCurrentUserRole
        
        This will invoke a Data Entity Action in Dynamics 365 Finance & Operations using the OData endpoint.
        The EntityName is DualWriteProjectConfigurations.
        The Action that is invoked is ValidateCurrentUserRole.
        
    .EXAMPLE
        PS C:\> Invoke-D365ODataEntityAction -EntityName BusinessEventsCatalogs -Action getBusinessEventsCatalog -Payload '{"_businessEventsCategory" : "Alerts"}'
        
        This will invoke a Data Entity Action in Dynamics 365 Finance & Operations using the OData endpoint, passing a payload to it.
        The EntityName is BusinessEventsCatalogs.
        The Action that is invoked is getBusinessEventsCatalog.
        The Payload is {"_businessEventsCategory" : "Alerts"}.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Invoke-D365ODataEntityAction -EntityName DualWriteProjectConfigurations -Action ValidateCurrentUserRole -Token $token
        
        This will invoke a Data Entity Action in Dynamics 365 Finance & Operations using the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        The EntityName used for the import is ExchangeRates.
        The Payload is a valid json string, containing all the needed properties.
        
    .NOTES
        Tags: OData, Data, Entity, Invoke, Action
        
        Author: Mötz Jensen (@Splaxi)
#>

function Invoke-D365ODataEntityAction {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $EntityName,

        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Alias('Json')]
        [string] $Payload,

        [string] $PayloadCharset = "UTF-8",

        [switch] $CrossCompany,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $RawOutput,

        [switch] $OutputAsJson,
        
        [switch] $EnableException
    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
        
        $PayloadCharset = $PayloadCharset.ToLower()
        if ($PayloadCharset -like "utf*" -and $PayloadCharset -notlike "utf-*") {
            $PayloadCharset = $PayloadCharset -replace "utf", "utf-"
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the OData endpoint for entity named: $EntityName." -Target $EntityName
        
        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "data/$EntityName/Microsoft.Dynamics.DataEntities.$Action"
        }
        else {
            $odataEndpoint.Path += "/data/$EntityName/Microsoft.Dynamics.DataEntities.$Action"
        }

        if ($CrossCompany) {
            $odataEndpoint.Query = "cross-company=true"
        }

        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)

            $parms = @{}
            $parms.Method = "POST"
            $parms.Uri = $odataEndpoint.Uri.AbsoluteUri
            $parms.Headers = $headers
            $parms.ContentType = "application/json;charset=$PayloadCharset"

            if ($Payload) {
                $parms.Body = $Payload
            }

            $res = Invoke-RestMethod @parms

            if (-not $RawOutput) {
                $res = $res.Value
            }

            if ($OutputAsJson) {
                $res | ConvertTo-Json -Depth 10
            }
            else {
                $res
            }
        }
        catch {
            $messageString = "Something went wrong while importing data through the OData endpoint for the entity: $EntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Invoke a REST Endpoint in Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Invokce any REST Endpoint available in a Dynamics 365 Finance & Operations environment
        
        It can be REST endpoints that are available out of the box or custom REST endpoints based on X++ classesrations platform
        
    .PARAMETER ServiceName
        The "name" of the REST endpoint that you want to invoke
        
        The REST endpoints consists of the following elementes:
        ServiceGroupName/ServiceName/MethodName
        
        E.g. "UserSessionService/AifUserSessionService/GetUserSessionInfo"
        
    .PARAMETER Payload
        The entire string contain the json object that you want to pass to the REST endpoint
        
        If the payload parameter is NOT null, it will trigger a HTTP POST action against the URL.
        
        But if the payload is null, it will trigger a HTTP GET action against the URL.
        
        Remember that json is text based and can use either single quotes (') or double quotes (") as the text qualifier, so you might need to escape the different quotes in your payload before passing it in
        
    .PARAMETER PayloadCharset
        The charset / encoding that you want the cmdlet to use while invoking the odata entity action
        
        The default value is: "UTF8"
        
        The charset has to be a valid http charset like: ASCII, ANSI, ISO-8859-1, UTF-8
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through REST endpoint
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through REST endpoint
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .PARAMETER TimeoutSec
        Specifies how long the request can be pending before it times out. Enter a value in seconds. The default value, 0, specifies an indefinite time-out.
        A Domain Name System (DNS) query can take up to 15 seconds to return or time out. If your request contains a host name that requires resolution, and you set TimeoutSec to a value greater than zero, but less than 15 seconds, it can take 15 seconds or more before a WebException is thrown, and your request times out.
        
    .EXAMPLE
        PS C:\> Invoke-D365RestEndpoint -ServiceName "UserSessionService/AifUserSessionService/GetUserSessionInfo" -Payload "{"RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}"
        
        This will invoke the REST endpoint in the  Dynamics 365 Finance & Operations environment.
        The ServiceName used for the import is "UserSessionService/AifUserSessionService/GetUserSessionInfo".
        The Payload is a valid json string, containing all the needed properties.
        
    .EXAMPLE
        PS C:\> $Payload = '{"RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}'
        PS C:\> Invoke-D365RestEndpoint -ServiceName "UserSessionService/AifUserSessionService/GetUserSessionInfo" -Payload $Payload
        
        This will invoke the REST endpoint in the  Dynamics 365 Finance & Operations environment.
        First the desired json data is put into the $Payload variable.
        The ServiceName used for the import is "UserSessionService/AifUserSessionService/GetUserSessionInfo".
        The $Payload variable is passed to the cmdlet.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Invoke-D365RestEndpoint -ServiceName "UserSessionService/AifUserSessionService/GetUserSessionInfo" -Payload "{"RateTypeName": "TEST", "FromCurrency": "DKK", "ToCurrency": "EUR", "StartDate": "2019-01-03T00:00:00Z", "Rate": 745.10, "ConversionFactor": "Hundred", "RateTypeDescription": "TEST"}" -Token $token
        
        This will invoke the REST endpoint in the  Dynamics 365 Finance & Operations environment.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        The ServiceName used for the import is "UserSessionService/AifUserSessionService/GetUserSessionInfo".
        The Payload is a valid json string, containing all the needed properties.
        
    .NOTES
        Tags: REST, Endpoint, Custom Service, Services
        
        Author: Mötz Jensen (@Splaxi)
#>

function Invoke-D365RestEndpoint {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ServiceName,

        [Alias('Json')]
        [string] $Payload,

        [string] $PayloadCharset = "UTF-8",

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,
        
        [string] $SystemUrl = $Script:ODataSystemUrl,

        [Parameter(Mandatory = $false)]
        [string] $ClientId = $Script:ODataClientId,

        [Parameter(Mandatory = $false)]
        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException,

        [Parameter(Mandatory = $false)]
        [int32] $TimeoutSec = 0
    )

    begin {
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        $PayloadCharset = $PayloadCharset.ToLower()
        if ($PayloadCharset -like "utf*" -and $PayloadCharset -notlike "utf-*") {
            $PayloadCharset = $PayloadCharset -replace "utf", "utf-"
        }
    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the REST endpoint for the service: $ServiceName." -Target $ServiceName
        
        [System.UriBuilder] $restEndpoint = $URL

        $restEndpoint.Path = "api/services/$ServiceName"

        $params = @{ }
        $params.Uri = $restEndpoint.Uri.AbsoluteUri
        $params.Headers = $headers
        $params.ContentType = "application/json;charset=$PayloadCharset"

        if ($null -ne $Payload) {
            $params.Method = "POST"
            $params.Body = $Payload
        }
        else {
            $params.Method = "GET"
        }

        # set timeout when specified
        if ($TimeoutSec -gt 0) {
            $params.TimeoutSec = $TimeoutSec
        }
        
        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the REST endpoint." -Target $($restEndpoint.Uri.AbsoluteUri)
            Invoke-RestMethod @params
        }
        catch {
            $messageString = "Something went wrong while importing data through the REST endpoint for the entity: $ServiceName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $ServiceName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Remove a Data Entity from Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Removes a Data Entity, defined by the EntityKey, using the OData endpoint of the Dynamics 365 Finance & Operations
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER Key
        The key that will select the desired Data Entity uniquely across the OData endpoint
        
        The key would most likely be made up from multiple values, but can also be a single value
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will work across all companies
        
    .PARAMETER RetryTimeout
        The retry timeout, before the cmdlet should quit retrying based on the 429 status code
        
        Needs to be provided in the timspan notation:
        "hh:mm:ss"
        
        hh is the number of hours, numerical notation only
        mm is the number of minutes
        ss is the numbers of seconds
        
        Each section of the timeout has to valid, e.g.
        hh can maximum be 23
        mm can maximum be 59
        ss can maximum be 59
        
        Not setting this parameter will result in the cmdlet to try for ever to handle the 429 push back from the endpoint
        
    .PARAMETER ThrottleSeed
        Instruct the cmdlet to invoke a thread sleep between 1 and ThrottleSeed value
        
        This is to help to mitigate the 429 retry throttling on the OData / Custom Service endpoints
        
        It makes most sense if you are running things a outer loop, where you will hit the OData / Custom Service endpoints with a burst of calls in a short time
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Remove-D365ODataEntity -EntityName ExchangeRates -Key "RateTypeName='TEST',FromCurrency='DKK',ToCurrency='EUR',StartDate=2019-01-13T12:00:00Z"
        
        This will remove a Data Entity from the D365FO environment through OData.
        It will use the ExchangeRate entity, and its EntitySetName / CollectionName "ExchangeRates".
        It will use the "RateTypeName='TEST',FromCurrency='DKK',ToCurrency='EUR',StartDate=2019-01-13T12:00:00Z" as the unique key for the entity.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Remove-D365ODataEntity -EntityName ExchangeRates -Key "RateTypeName='TEST',FromCurrency='DKK',ToCurrency='EUR',StartDate=2019-01-13T12:00:00Z" -Token $token
        
        This will remove a Data Entity from the D365FO environment through OData.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        It will use the ExchangeRate entity, and its EntitySetName / CollectionName "ExchangeRates".
        It will use the "RateTypeName='TEST',FromCurrency='DKK',ToCurrency='EUR',StartDate=2019-01-13T12:00:00Z" as the unique key for the entity.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Remove-D365ODataEntity -EntityName ExchangeRates -Key "RateTypeName='TEST',FromCurrency='DKK',ToCurrency='EUR',StartDate=2019-01-13T12:00:00Z" -RetryTimeout "00:01:00"
        
        This will remove a Data Entity from the D365FO environment through OData, and try for 1 minute to handle 429.
        It will use the ExchangeRate entity, and its EntitySetName / CollectionName "ExchangeRates".
        It will use the "RateTypeName='TEST',FromCurrency='DKK',ToCurrency='EUR',StartDate=2019-01-13T12:00:00Z" as the unique key for the entity.
        It will only try to handle 429 retries for 1 minute, before failing.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Remove-D365ODataEntity -EntityName ExchangeRates -Key "RateTypeName='TEST',FromCurrency='DKK',ToCurrency='EUR',StartDate=2019-01-13T12:00:00Z" -ThrottleSeed 2
        
        This will remove a Data Entity from the D365FO environment through OData, and sleep/pause between 1 and 2 seconds.
        It will use the ExchangeRate entity, and its EntitySetName / CollectionName "ExchangeRates".
        It will use the "RateTypeName='TEST',FromCurrency='DKK',ToCurrency='EUR',StartDate=2019-01-13T12:00:00Z" as the unique key for the entity.
        It will use the ThrottleSeed 2 to sleep/pause the execution, to mitigate the 429 pushback from the endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .NOTES
        Tags: OData, Data, Entity, Import, Upload
        
        Author: Mötz Jensen (@Splaxi)
#>

function Remove-D365ODataEntity {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $EntityName,

        [Parameter(Mandatory = $true)]
        [string] $Key,

        [switch] $CrossCompany,

        [Timespan] $RetryTimeout = "00:00:00",

        [int] $ThrottleSeed,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,
        
        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,
        
        [switch] $EnableException

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }

        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }
        
        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms
    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for removing data entity through the OData endpoint for entity named: $EntityName." -Target $EntityName

        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "data/$EntityName($Key)"
        }
        else {
            $odataEndpoint.Path += "/data/$EntityName($Key)"
        }

        if ($CrossCompany) {
            $odataEndpoint.Query = $($odataEndpoint.Query + "&cross-company=true").Replace("?", "")
        }

        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)
            $null = Invoke-RequestHandler -Method DELETE -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType 'application/json' -RetryTimeout $RetryTimeout
      
            if (Test-PSFFunctionInterrupt) { return }
        }
        catch {
            $messageString = $((ConvertFrom-Json $_).Error.InnerError | ConvertTo-Json -Depth 10)
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($messageString)) -ErrorRecord $_
            return
        }
        
        if ($ThrottleSeed) {
            Start-Sleep -Seconds $(Get-Random -Minimum 1 -Maximum $ThrottleSeed)
        }
        
        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Remove a set of Data Entities from Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Remove a set of Data Entities, by their keys, using the OData endpoint of the Dynamics 365 Finance & Operations
        
        The collection of keys will be batched into a single request against the OData endpoint
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER Key
        The array of keys that you want to delete from the D365FO environment
        
        Note that a key can be made up by several parts, for a given entity
        
        E.g. CustomersV3 is "dataAreaId='DAT',CustomerAccount='Customer1'"
        
        Please note the single quotes, for each key field
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will work across all companies
        
    .PARAMETER ThrottleSeed
        Instruct the cmdlet to invoke a thread sleep between 1 and ThrottleSeed value
        
        This is to help to mitigate the 429 retry throttling on the OData / Custom Service endpoints
        
        It makes most sense if you are running things a outer loop, where you will hit the OData / Custom Service endpoints with a burst of calls in a short time
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER RawOutput
        Instructs the cmdlet to output the raw json string directly
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Remove-D365ODataEntityBatchMode -EntityName "CustomersV3" -Key "dataAreaId='USMF',CustomerAccount='Customer1'","dataAreaId='USMF',CustomerAccount='Customer2'"
        
        This will delete both customers, in a single request, from the Dynamics 365 Finance & Operations using the OData endpoint.
        The EntityName used for the deletion is CustomersV3.
        The Key is an array containing valid keys, each containing referencing a single entity.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Remove-D365ODataEntityBatchMode -EntityName "CustomersV3" -Key "dataAreaId='USMF',CustomerAccount='Customer1'","dataAreaId='USMF',CustomerAccount='Customer2'" -Token $token
        
        This will delete both customers, in a single request, from the Dynamics 365 Finance & Operations using the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        The EntityName used for the deletion is CustomersV3.
        The Key is an array containing valid keys, each containing referencing a single entity.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Remove-D365ODataEntityBatchMode -EntityName "CustomersV3" -Key "dataAreaId='USMF',CustomerAccount='Customer1'","dataAreaId='USMF',CustomerAccount='Customer2'" -ThrottleSeed 2
        
        This will delete both customers, in a single request, from the Dynamics 365 Finance & Operations using the OData endpoint, and sleep/pause between 1 and 2 seconds.
        The EntityName used for the deletion is CustomersV3.
        The Key is an array containing valid keys, each containing referencing a single entity.
        It will use the ThrottleSeed 2 to sleep/pause the execution, to mitigate the 429 pushback from the endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .NOTES
        Tags: OData, Data, Entity, Delete, Remove, Batch
        
        Author: Mötz Jensen (@Splaxi)
#>

function Remove-D365ODataEntityBatchMode {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType('System.String')]
    param (
        [Parameter(Mandatory = $true)]
        [string] $EntityName,

        [Parameter(Mandatory = $true)]
        [string[]] $Key,

        [switch] $CrossCompany,

        [int] $ThrottleSeed,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [switch] $RawOutput,
        
        [string] $Token,
        
        [switch] $EnableException

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        $dataBuilder = [System.Text.StringBuilder]::new()

    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building batch request for the OData endpoint for entity named: $EntityName." -Target $EntityName

        $idbatch = $(New-Guid).ToString()
        $idchangeset = $(New-Guid).ToString()
    
        $batchPayload = "batch_$idbatch"
        $changesetPayload = "changeset_$idchangeset"
        
        $request = [System.Net.WebRequest]::Create("$SystemUrl/data/`$batch")
        $request.Headers["Authorization"] = $headers.Authorization
        $request.Method = "POST"
        $request.ContentType = "multipart/mixed; boundary=batch_$idBatch"

        $dataBuilder.Clear() > $null

        $dataBuilder.AppendLine("--$batchPayLoad ") > $null #Space is important!
        $dataBuilder.AppendLine("Content-Type: multipart/mixed; boundary=changeset_$idchangeset {0}" -f [System.Environment]::NewLine) > $null
        $dataBuilder.AppendLine("--$changeSetPayLoad ") > $null #Space is important!

        $payLoadEnumerator = $Key.GetEnumerator()
        $counter = 0
        while ($payLoadEnumerator.MoveNext()) {

            Write-PSFMessage -Level Verbose -Message "Parsing the payload for the batch request."

            $counter ++
            $localEntity = "$EntityName($($payLoadEnumerator.Current.Trim()))"
            $dataBuilder.Append((New-BatchKey -Url "$SystemUrl/data/$localEntity" -Count $counter -Method "DELETE")) > $null

            if ($Key.Count -eq $counter) {
                $dataBuilder.AppendLine("--$changesetPayload--") > $null
            }
            else {
                $dataBuilder.AppendLine("--$changesetPayload") > $null
            }
        }
    
        $dataBuilder.Append("--$batchPayload--") > $null
        $data = $dataBuilder.ToString()

        Write-PSFMessage -Level Debug -Message "Parsing data to debug log next."

        Write-PSFMessage -Level Debug -Message $data
        
        Add-WebRequestContent -WebRequest $request -Payload $data
    
        try {
            Write-PSFMessage -Level Verbose -Message "Executing batch http request against the OData endpoint."

            $response = $request.GetResponse()
        }
        catch {
            $messageString = "Something went wrong while importing batch data through the OData endpoint for the entity: $EntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
    
        #Might need to be something else than OK and Created
        if ($response.StatusCode -ne [System.Net.HttpStatusCode]::Ok -and $response.StatusCode -ne [System.Net.HttpStatusCode]::Created) {
            Write-PSFMessage -Level Verbose -Message "Status code not 'Ok' and not 'Created', Description $($response.StatusDescription)"
            Stop-PSFFunction -Message "Stopping" -Exception $([System.Exception]::new("Returned status code indicates that the request was unsuccessful."))
            return
        }

        $stream = $response.GetResponseStream()
    
        $streamReader = New-Object System.IO.StreamReader($stream)
        
        $res = $streamReader.ReadToEnd()
        $streamReader.Close();

        if ($RawOutput) {
            $res
        }
        else {
            $res | ConvertTo-Json
        }

        if ($ThrottleSeed) {
            Start-Sleep -Seconds $(Get-Random -Minimum 1 -Maximum $ThrottleSeed)
        }

        Invoke-TimeSignal -End
    }
}


<#
        
    .SYNOPSIS
        Set the active OData configuration
        
    .DESCRIPTION
        Updates the current active OData configuration with a new one
        
    .PARAMETER Name
        Name of the OData configuration you want to load into the active OData configuration
        
    .PARAMETER Temporary
        Instruct the cmdlet to only temporarily override the persisted settings in the configuration store
        
    .EXAMPLE
        PS C:\> Set-D365ActiveODataConfig -Name "UAT"
        
        This will set the OData configuration named "UAT" as the active configuration.
        
    .NOTES
        Tags: Environment, Config, Configuration, ClientId, ClientSecret
        
        Author: Mötz Jensen (@Splaxi)
#>

function Set-D365ActiveODataConfig {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Name,

        [switch] $Temporary
    )

    if($Name -match '\*') {
        $messageString = "The name cannot contain <c='em'>wildcard character</c>."
        Write-PSFMessage -Level Host -Message $messageString
        Stop-PSFFunction -Message "Stopping because the name contains wildcard character." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>','')))
        return
    }

    if (-not ((Get-PSFConfig -FullName "d365fo.integrations.odata.*.name").Value -contains $Name)) {
        $messageString = "An OData configuration with that name <c='em'>doesn't exists</c>."
        Write-PSFMessage -Level Host -Message $messageString
        Stop-PSFFunction -Message "Stopping because an OData message configuration with that name doesn't exists." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>','')))
        return
    }

    Set-PSFConfig -FullName "d365fo.integrations.active.odata.config.name" -Value $Name
    if (-not $Temporary) { Register-PSFConfig -FullName "d365fo.integrations.active.odata.config.name"  -Scope UserDefault }

    Update-ODataVariables
}


<#
    .SYNOPSIS
        Set the token for the remaing of the session
        
    .DESCRIPTION
        Sets the token for the remaing of the session, via the $PSDefaultParameterValues variable
        
        When the token expires, you will have to do a new authentication request again
        
    .PARAMETER BearerToken
        Pass the bearer token string that you want to use for the default token value across the module
        
    .EXAMPLE
        PS C:\> Set-D365ODataTokenInSession -BearerToken "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi....."
        
        This sets the Token parameter value for all cmdlets, for the remaining of the session.
        Sets the Token parameter value to "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOi.....".
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Set-D365ODataTokenInSession -BearerToken $token
        
        This sets the Token parameter value for all cmdlets, for the remaining of the session.
        It gets a token from the Get-D365ODataToken cmdlet and stores it in the $token variable.
        Sets the Token parameter value to the value of the $token variable.
        
    .EXAMPLE
        PS C:\> Get-D365ODataToken | Set-D365ODataTokenInSession
        
        This sets the Token parameter value for all cmdlets, for the remaining of the session.
        It gets a token from the Get-D365ODataToken cmdlet and pipes it into Set-D365ODataTokenInSession.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataTokenInteractive
        PS C:\> Set-D365ODataTokenInSession -BearerToken $token
        
        This sets the Token parameter value for all cmdlets, for the remaining of the session.
        It gets a token from the Get-D365ODataTokenInteractive cmdlet and stores it in the $token variable.
        Sets the Token parameter value to the value of the $token variable.
        
    .EXAMPLE
        PS C:\> Get-D365ODataTokenInteractive | Set-D365ODataTokenInSession
        
        This sets the Token parameter value for all cmdlets, for the remaining of the session.
        It gets a token from the Get-D365ODataTokenInteractive cmdlet and pipes it into Set-D365ODataTokenInSession.
        
    .NOTES
        Tags: Exception, Exceptions, Warning, Warnings
        
        Author: Mötz Jensen (@Splaxi)
#>

function Set-D365ODataTokenInSession {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $BearerToken
    )

    process {
        Write-PSFMessage -Level Verbose -Message "Setting the token value across the entire module."
    
        $Global:PSDefaultParameterValues['*:Token'] = $BearerToken
    }
}


<#
    .SYNOPSIS
        Update a Data Entity in Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Updates a Data Entity, defined as a json payload, using the OData endpoint of the Dynamics 365 Finance & Operations platform
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER Key
        The key that will select the desired Data Entity uniquely across the OData endpoint
        
        The key would most likely be made up from multiple values, but can also be a single value
        
    .PARAMETER Payload
        The entire string contain the json object that you want to import into the D365FO environment
        
        Remember that json is text based and can use either single quotes (') or double quotes (") as the text qualifier, so you might need to escape the different quotes in your payload before passing it in
        
    .PARAMETER PayloadCharset
        The charset / encoding that you want the cmdlet to use while updating the odata entity
        
        The default value is: "UTF8"
        
        The charset has to be a valid http charset like: ASCII, ANSI, ISO-8859-1, UTF-8
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will search across all companies
        
    .PARAMETER RetryTimeout
        The retry timeout, before the cmdlet should quit retrying based on the 429 status code
        
        Needs to be provided in the timspan notation:
        "hh:mm:ss"
        
        hh is the number of hours, numerical notation only
        mm is the number of minutes
        ss is the numbers of seconds
        
        Each section of the timeout has to valid, e.g.
        hh can maximum be 23
        mm can maximum be 59
        ss can maximum be 59
        
        Not setting this parameter will result in the cmdlet to try for ever to handle the 429 push back from the endpoint
        
    .PARAMETER ThrottleSeed
        Instruct the cmdlet to invoke a thread sleep between 1 and ThrottleSeed value
        
        This is to help to mitigate the 429 retry throttling on the OData / Custom Service endpoints
        
        It makes most sense if you are running things a outer loop, where you will hit the OData / Custom Service endpoints with a burst of calls in a short time
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself
        
        If you are working against a D365 Talent / HR instance, this will have to be "http://hr.talent.dynamics.com"
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Update-D365ODataEntity -EntityName "CustomersV3" -Key "dataAreaId='DAT',CustomerAccount='123456789'" -Payload '{"NameAlias": "CustomerA"}' -CrossCompany
        
        This will update a Data Entity in Dynamics 365 Finance & Operations using the OData endpoint.
        The EntityName used for the update is "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        The Payload is a valid json string, containing the needed properties that we want to update.
        It will make sure to search across all legal entities / companies inside the D365FO environment.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $Payload = '{"NameAlias": "CustomerA"}'
        PS C:\> Update-D365ODataEntity -EntityName "accounts" -Key "dataAreaId='DAT',CustomerAccount='123456789'" -Payload $Payload
        
        This will update a Data Entity in Dynamics 365 Finance & Operations using the OData endpoint.
        First the desired json data is put into the $Payload variable.
        The EntityName used for the update is "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        The $Payload variable is passed to the cmdlet.
        It will NOT look across companies.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> Update-D365ODataEntity -EntityName "CustomersV3" -Key "dataAreaId='DAT',CustomerAccount='123456789'" -Payload '{"NameAlias": "CustomerA"}' -CrossCompany -Token $token
        
        This will update a Data Entity in Dynamics 365 Finance & Operations using the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        The EntityName used for the update is "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        The Payload is a valid json string, containing the needed properties that we want to update.
        It will make sure to search across all legal entities / companies inside the D365FO environment.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Update-D365ODataEntity -EntityName "CustomersV3" -Key "dataAreaId='DAT',CustomerAccount='123456789'" -Payload '{"NameAlias": "CustomerA"}' -CrossCompany -RetryTimeout "00:01:00"
        
        This will update a Data Entity in Dynamics 365 Finance & Operations using the OData endpoint, and try for 1 minute to handle 429.
        The EntityName used for the update is "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        The Payload is a valid json string, containing the needed properties that we want to update.
        It will make sure to search across all legal entities / companies inside the D365FO environment.
        It will only try to handle 429 retries for 1 minute, before failing.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> Update-D365ODataEntity -EntityName "CustomersV3" -Key "dataAreaId='DAT',CustomerAccount='123456789'" -Payload '{"NameAlias": "CustomerA"}' -CrossCompany -ThrottleSeed 2
        
        This will update a Data Entity in Dynamics 365 Finance & Operations using the OData endpoint, and sleep/pause between 1 and 2 seconds.
        The EntityName used for the update is "CustomersV3".
        It will use the "dataAreaId='DAT',CustomerAccount='123456789'" as key to identify the unique Customer record.
        The Payload is a valid json string, containing the needed properties that we want to update.
        It will make sure to search across all legal entities / companies inside the D365FO environment.
        It will use the ThrottleSeed 2 to sleep/pause the execution, to mitigate the 429 pushback from the endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .NOTES
        Tags: OData, Data, Entity, Update, Upload
        
        Author: Mötz Jensen (@Splaxi)
        
    .LINK
        Add-D365ODataConfig
        
    .LINK
        Get-D365ActiveODataConfig
        
    .LINK
        Set-D365ActiveODataConfig
#>

function Update-D365ODataEntity {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $EntityName,

        [Parameter(Mandatory = $true)]
        [string] $Key,

        [Parameter(Mandatory = $true)]
        [Alias('Json')]
        [string] $Payload,

        [string] $PayloadCharset = "UTF-8",

        [switch] $CrossCompany,

        [Timespan] $RetryTimeout = "00:00:00",

        [int] $ThrottleSeed,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [string] $Token,

        [switch] $EnableException

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }

        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        $PayloadCharset = $PayloadCharset.ToLower()
        if ($PayloadCharset -like "utf*" -and $PayloadCharset -notlike "utf-*") {
            $PayloadCharset = $PayloadCharset -replace "utf", "utf-"
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building request for the OData endpoint for entity named: $EntityName." -Target $EntityName

        [System.UriBuilder] $odataEndpoint = $SystemUrl
        
        if ($odataEndpoint.Path -eq "/") {
            $odataEndpoint.Path = "data/$EntityName($Key)"
        }
        else {
            $odataEndpoint.Path += "/data/$EntityName($Key)"
        }

        if ($CrossCompany) {
            $odataEndpoint.Query = "cross-company=true"
        }

        try {
            Write-PSFMessage -Level Verbose -Message "Executing http request against the OData endpoint." -Target $($odataEndpoint.Uri.AbsoluteUri)
            Invoke-RequestHandler -Method Patch -Uri $odataEndpoint.Uri.AbsoluteUri -Headers $headers -ContentType "application/json;charset=$PayloadCharset" -Payload $Payload -RetryTimeout $RetryTimeout
        
            if (Test-PSFFunctionInterrupt) { return }
        }
        catch [System.Net.WebException] {
            $webException = $_.Exception
            
            if (($webException.Status -eq [System.Net.WebExceptionStatus]::ProtocolError) -and (-not($null -eq $webException.Response))) {
                $resp = [System.Net.HttpWebResponse]$webException.Response

                if ($resp.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {
                    $messageString = "It seems that the OData endpoint was unable to locate the desired entity: $EntityName, based on the key: <c='em'>$key</c>. Please make sure that the key is <c='em'>valid</c> or try using the <c='em'>-CrossCompany</c> parameter."
                    Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
                    Stop-PSFFunction -Message "Stopping because of HTTP error 404." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
                    return
                }
                else {
                    $messageString = "Something went wrong while updating the data entity through the OData endpoint for the entity: $EntityName"
                    Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
                    Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
                    return
                }
            }
        }
        catch {
            $messageString = "Something went wrong while updating the data entity through the OData endpoint for the entity: $EntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($ThrottleSeed) {
            Start-Sleep -Seconds $(Get-Random -Minimum 1 -Maximum $ThrottleSeed)
        }

        Invoke-TimeSignal -End
    }
}


<#
    .SYNOPSIS
        Update a set of Data Entities in Dynamics 365 Finance & Operations
        
    .DESCRIPTION
        Updates a set of Data Entities, defined as a json payloads, using the OData endpoint of the Dynamics 365 Finance & Operations
        
        The entire payload will be batched into a single request against the OData endpoint
        
    .PARAMETER EntityName
        Name of the Data Entity you want to work against
        
        The parameter is Case Sensitive, because the OData endpoint in D365FO is Case Sensitive
        
        Remember that most Data Entities in a D365FO environment is named by its singular name, but most be retrieve using the plural name
        
        E.g. The version 3 of the customers Data Entity is named CustomerV3, but can only be retrieving using CustomersV3
        
        Look at the Get-D365ODataPublicEntity cmdlet to help you obtain the correct name
        
    .PARAMETER Payload
        The array of PSCustomObjects that you want to update in the D365FO environment
        
        Each PSCustomObject needs to have a Key and a Payload property
        
        The Key must be a string
        The Payload must be a json string
        
    .PARAMETER PayloadCharset
        The charset / encoding that you want the cmdlet to use while updating the odata entity
        
        The default value is: "UTF8"
        
        The charset has to be a valid http charset like: ASCII, ANSI, ISO-8859-1, UTF-8
        
    .PARAMETER CrossCompany
        Instruct the cmdlet / function to ensure the request against the OData endpoint will work across all companies
        
    .PARAMETER ThrottleSeed
        Instruct the cmdlet to invoke a thread sleep between 1 and ThrottleSeed value
        
        This is to help to mitigate the 429 retry throttling on the OData / Custom Service endpoints
        
        It makes most sense if you are running things a outer loop, where you will hit the OData / Custom Service endpoints with a burst of calls in a short time
        
    .PARAMETER Tenant
        Azure Active Directory (AAD) tenant id (Guid) that the D365FO environment is connected to, that you want to access through OData
        
    .PARAMETER Url
        URL / URI for the D365FO environment you want to access through OData
        
    .PARAMETER SystemUrl
        URL / URI for the D365FO instance where the OData endpoint is available
        
        If you are working against a D365FO instance, it will be the URL / URI for the instance itself, which is the same as the Url parameter value
        
        If you are working against a D365 Talent / HR instance, this will to be full instance URL / URI like "https://aos-rts-sf-b1b468164ee-prod-northeurope.hr.talent.dynamics.com/namespaces/0ab49d18-6325-4597-97b3-c7f2321aa80c"
        
    .PARAMETER ClientId
        The ClientId obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER ClientSecret
        The ClientSecret obtained from the Azure Portal when you created a Registered Application
        
    .PARAMETER RawOutput
        Instructs the cmdlet to output the raw json string directly
        
    .PARAMETER Token
        Pass a bearer token string that you want to use for while working against the endpoint
        
        This can improve performance if you are iterating over a large collection/array
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> $payload = '{"SalesTaxGroup":"DK"}'
        PS C:\> $updates = @([PSCustomObject]@{Key = "dataAreaId='USMF',CustomerAccount='Customer1'"; Payload = $payload})
        PS C:\> $updates += [PSCustomObject]@{Key = "dataAreaId='USMF',CustomerAccount='Customer2'"; Payload = $payload}
        PS C:\> Update-D365ODataEntityBatchMode -EntityName "CustomersV3" -Payload $($updates.ToArray())
        
        This will update a set of Data Entities in Dynamics 365 Finance & Operations using the OData endpoint.
        The payload that needs to be updated for all entities is saved in the $payload variable.
        The desired customers that needs to be updated are saved into the $updates, with their unique key and the payload.
        The $updates variable is passed to the cmdlet.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $token = Get-D365ODataToken
        PS C:\> $payload = '{"SalesTaxGroup":"DK"}'
        PS C:\> $updates = @([PSCustomObject]@{Key = "dataAreaId='USMF',CustomerAccount='Customer1'"; Payload = $payload})
        PS C:\> $updates += [PSCustomObject]@{Key = "dataAreaId='USMF',CustomerAccount='Customer2'"; Payload = $payload}
        PS C:\> Update-D365ODataEntityBatchMode -EntityName "CustomersV3" -Payload $($updates.ToArray()) -Token $token
        
        This will update a set of Data Entities in Dynamics 365 Finance & Operations using the OData endpoint.
        It will get a fresh token, saved it into the token variable and pass it to the cmdlet.
        The payload that needs to be updated for all entities is saved in the $payload variable.
        The desired customers that needs to be updated are saved into the $updates, with their unique key and the payload.
        The $updates variable is passed to the cmdlet.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .EXAMPLE
        PS C:\> $payload = '{"SalesTaxGroup":"DK"}'
        PS C:\> $updates = @([PSCustomObject]@{Key = "dataAreaId='USMF',CustomerAccount='Customer1'"; Payload = $payload})
        PS C:\> $updates += [PSCustomObject]@{Key = "dataAreaId='USMF',CustomerAccount='Customer2'"; Payload = $payload}
        PS C:\> Update-D365ODataEntityBatchMode -EntityName "CustomersV3" -Payload $($updates.ToArray()) -ThrottleSeed 2
        
        This will update a set of Data Entities in Dynamics 365 Finance & Operations using the OData endpoint, and sleep/pause between 1 and 2 seconds.
        The payload that needs to be updated for all entities is saved in the $payload variable.
        The desired customers that needs to be updated are saved into the $updates, with their unique key and the payload.
        The $updates variable is passed to the cmdlet.
        It will use the ThrottleSeed 2 to sleep/pause the execution, to mitigate the 429 pushback from the endpoint.
        
        It will use the default OData configuration details that are stored in the configuration store.
        
    .NOTES
        Tags: OData, Data, Entity, Update, Upload, Batch
        
        Author: Mötz Jensen (@Splaxi)
#>

function Update-D365ODataEntityBatchMode {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType('System.String')]
    param (
        [Parameter(Mandatory = $true)]
        [string] $EntityName,

        [Parameter(Mandatory = $true)]
        [PsCustomObject[]] $Payload,

        [string] $PayloadCharset = "UTF-8",

        [switch] $CrossCompany,

        [int] $ThrottleSeed,

        [Alias('$AadGuid')]
        [string] $Tenant = $Script:ODataTenant,

        [Alias('Uri')]
        [string] $Url = $Script:ODataUrl,

        [string] $SystemUrl = $Script:ODataSystemUrl,

        [string] $ClientId = $Script:ODataClientId,

        [string] $ClientSecret = $Script:ODataClientSecret,

        [switch] $RawOutput,
        
        [string] $Token,
        
        [switch] $EnableException

    )

    begin {
        if ([System.String]::IsNullOrEmpty($SystemUrl)) {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter was empty, using the Url parameter as the OData endpoint base address." -Target $SystemUrl
            $SystemUrl = $Url
        }
        
        if ([System.String]::IsNullOrEmpty($Url) -or [System.String]::IsNullOrEmpty($SystemUrl)) {
            $messageString = "It seems that you didn't supply a valid value for the Url parameter. You need specify the Url parameter or add a configuration with the <c='em'>Add-D365ODataConfig</c> cmdlet."
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $entityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
        
        if ($Url.Substring($Url.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The Url parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
    
        if ($SystemUrl.Substring($SystemUrl.Length - 1) -eq "/") {
            Write-PSFMessage -Level Verbose -Message "The SystemUrl parameter had a tailing slash, which shouldn't be there. Removing the tailling slash." -Target $Url
            $SystemUrl = $SystemUrl.Substring(0, $SystemUrl.Length - 1)
        }

        if (-not $Token) {
            $bearerParms = @{
                Url          = $Url
                ClientId     = $ClientId
                ClientSecret = $ClientSecret
                Tenant       = $Tenant
            }

            $bearer = New-BearerToken @bearerParms
        }
        else {
            $bearer = $Token
        }
        
        $headerParms = @{
            URL         = $SystemUrl
            BearerToken = $bearer
        }

        $headers = New-AuthorizationHeaderBearerToken @headerParms

        $dataBuilder = [System.Text.StringBuilder]::new()

    }

    process {
        Invoke-TimeSignal -Start

        Write-PSFMessage -Level Verbose -Message "Building batch request for the OData endpoint for entity named: $EntityName." -Target $EntityName

        $idbatch = $(New-Guid).ToString()
        $idchangeset = $(New-Guid).ToString()
    
        $batchPayload = "batch_$idbatch"
        $changesetPayload = "changeset_$idchangeset"
        
        $request = [System.Net.WebRequest]::Create("$SystemUrl/data/`$batch")
        $request.Headers["Authorization"] = $headers.Authorization
        $request.Method = "POST"
        $request.ContentType = "multipart/mixed; boundary=batch_$idBatch"

        $dataBuilder.Clear() > $null

        $dataBuilder.AppendLine("--$batchPayLoad ") > $null #Space is important!
        $dataBuilder.AppendLine("Content-Type: multipart/mixed; boundary=changeset_$idchangeset {0}" -f [System.Environment]::NewLine) > $null
        $dataBuilder.AppendLine("--$changeSetPayLoad ") > $null #Space is important!

        $payLoadEnumerator = $PayLoad.GetEnumerator()
        $counter = 0
        while ($payLoadEnumerator.MoveNext()) {
            $key = $payLoadEnumerator.Current.Key

            $localEntity = "$EntityName($key)"

            Write-PSFMessage -Level Verbose -Message "Parsing the payload for the batch request."

            $counter ++
            $localPayload = $payLoadEnumerator.Current.Payload.Trim()

            $dataBuilder.Append((New-BatchContent -Url "$SystemUrl/data/$localEntity" -Payload $LocalPayload -Count $counter -Method "PATCH")) > $null

            if ($PayLoad.Count -eq $counter) {
                $dataBuilder.AppendLine("--$changesetPayload--") > $null
            }
            else {
                $dataBuilder.AppendLine("--$changesetPayload") > $null
            }
        }
    
        $dataBuilder.Append("--$batchPayload--") > $null
        $data = $dataBuilder.ToString()

        Write-PSFMessage -Level Debug -Message "Parsing data to debug log next."

        Write-PSFMessage -Level Debug -Message $data
        
        Add-WebRequestContent -WebRequest $request -Payload $data
    
        try {
            Write-PSFMessage -Level Verbose -Message "Executing batch http request against the OData endpoint."

            $response = $request.GetResponse()
        }
        catch {
            $messageString = "Something went wrong while importing batch data through the OData endpoint for the entity: $EntityName"
            Write-PSFMessage -Level Host -Message $messageString -Exception $PSItem.Exception -Target $EntityName
            Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($messageString -replace '<[^>]+>', ''))) -ErrorRecord $_
            return
        }
    
        #Might need to be something else than OK and Created
        if ($response.StatusCode -ne [System.Net.HttpStatusCode]::Ok -and $response.StatusCode -ne [System.Net.HttpStatusCode]::Created) {
            Write-PSFMessage -Level Verbose -Message "Status code not 'Ok' and not 'Created', Description $($response.StatusDescription)"
            Stop-PSFFunction -Message "Stopping" -Exception $([System.Exception]::new("Returned status code indicates that the request was unsuccessful."))
            return
        }

        $stream = $response.GetResponseStream()
    
        $streamReader = New-Object System.IO.StreamReader($stream)
        
        $res = $streamReader.ReadToEnd()
        $streamReader.Close();

        if ($RawOutput) {
            $res
        }
        else {
            $res | ConvertTo-Json
        }

        if ($ThrottleSeed) {
            Start-Sleep -Seconds $(Get-Random -Minimum 1 -Maximum $ThrottleSeed)
        }
        
        Invoke-TimeSignal -End
    }
}

<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'd365fo.integrations' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'd365fo.integrations' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'd365fo.integrations' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

Set-PSFConfig -FullName "d365fo.integrations.azure.tenant.oauth.token" -Value "https://login.microsoftonline.com/{0}/oauth2/token" -Initialize -Description "URI / URL for the Azure Active Directory OAuth 2.0 endpoint for tokens, prepped for the tenant value to be inserted."
Set-PSFConfig -FullName "d365fo.integrations.azure.tenant.oauth.devicecode" -Value "https://login.microsoftonline.com/{0}/oauth2/devicecode" -Initialize -Description "URI / URL for the Azure Active Directory OAuth 2.0 endpoint for devicecode, prepped for the tenant value to be inserted."

Set-PSFConfig -FullName "d365fo.integrations.dmf.download.retries" -Value 5 -Initialize -Description "Retry counter for how many times the module should try to download a given file from the DMF Package endpoint."

<#
Stored scriptblocks are available in [PsfValidateScript()] attributes.
This makes it easier to centrally provide the same scriptblock multiple times,
without having to maintain it in separate locations.

It also prevents lengthy validation scriptblocks from making your parameter block
hard to read.

Set-PSFScriptblock -Name 'd365fo.integrations.ScriptBlockName' -Scriptblock {
	
}
#>

$scriptBlock = { Get-D365ODataConfig | Sort-Object Name | Select-Object -ExpandProperty Name }

Register-PSFTeppScriptblock -Name "d365odata.config.names" -ScriptBlock $scriptBlock -Mode Simple


<#
# Example:
Register-PSFTeppScriptblock -Name "d365fo.integrations.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name d365fo.integrations.alcohol
#>

Register-PSFTeppArgumentCompleter -Command Get-D365ODataConfig -Parameter Name -Name "d365odata.config.names"
Register-PSFTeppArgumentCompleter -Command Set-D365ActiveODataConfig -Parameter Name -Name "d365odata.config.names"


New-PSFLicense -Product 'd365fo.integrations' -Manufacturer 'Motz' -ProductVersion $script:ModuleVersion -ProductType Module -Name MIT -Version "1.0.0.0" -Date (Get-Date "2019-05-16") -Text @"
Copyright (c) 2019 Motz

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

Update-ODataVariables

Update-PsfConfigVariables
#endregion Load compiled code
# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB7m57MuRkOky+C
# WVqNrzQDpbPd7S1T+2KW16X6kuAotaCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEAaEMdmoCUl
# ju63QOy2BXNlrWHpmTQSmldYJwh4Fp8QMA0GCSqGSIb3DQEBAQUABIICAJAtiVlZ
# 91tNwPr1PMHuftQCTywSB2ntGWxaX7LfHQTE+mTbQ/xaW8BgVoCEwwgLLY24tQQN
# eAmFrHYX7DqaGsdP6RItdwGV6TVuINKN7esQ1GPjNKyJusBnbFe9XJfzqOxFw2ZO
# VDk5Xx64JLuiI/NP2u7wTajbC+z6QzK495wAtvA19oraLMJY6XEf3Wnv3i1HqHkD
# LT1PSbmuyOkIWwc4MKSVdsCw0XcK4o3waIkrjs5eykYaso01TOfr15FMJ//1e3Yq
# uPL7DZ3JwQgvrhmatO6OkDMJsvyKDpEOUXf5VWCwhY+JxMXZEo0VK8VIJfW4/juU
# TFf89zvuJY1GsJCtUMEIiA+CvjmgjoSkvCbof7XwppTLDFrvF4OEfSvfRhsmDLTP
# ZveRPuUTu9s+zUabEB6jIK1XgMWfcOJl6XeFUBD3Jj0jIAy/Rdkr9dfbvtgcRLsY
# iQg2cDqpb0nIe2dTBQHDp+pxMXiu3cwbrzGQZdfzWT2c/fQVN0bwq/F9qgBfUhYX
# CRPItEOWJFtUeCQegkEFtzC30/9w5XsbhnF3Q6SJPFqGgPbtHVRrm+AuY1xeGssj
# i037I/rwwrOoGkfYd7CnnX6mZ5Hc1VW23e0elzOnR5x0CycKP4L7u4FivZcws4yJ
# CDwwtg+j4/2SfOPXB6sV1d5hcuVfIAAuXi3JoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMTAwMjQwOFowLwYJKoZIhvcNAQkEMSIEIMZaQavA2Fp0TZoF0tGqGUYEbDPV
# 229a/+XpRXCv5+s5MA0GCSqGSIb3DQEBAQUABIICAJoZANRmPqJPSXGHYK9GTbMT
# 1+C6vCArSuTnqEr+Zd98YzDAFkEsijUdmP7OxakFew6HVVFpyd+pT6328iuhwqmj
# TVu3XFsKHWow0/JgobMtcA/83MXx9s9gU4gsOshDFBNa4DnTECQnKQKz6Fpk56eL
# QCEGUU/XwevU11IM0+9H/7VFFx4Nj3aoElFlB0SoCm1KL300CCXMq0gg01T4ZLjc
# KbMLs29ke5SOlLR7stGZt8kqNLtV6xifj2Pf6movduu1sAnrXwgs5NTmC6K9nS/v
# TGtydc90utVh9qi8ZBX3unahxW+WzY3KjK3jt84g+HRvuvLIJogEWU+yfwQ2IDQP
# 2MGrhFPiIuyEFmzhhI8h6sQTbJPbzRwiEzoKyIYAKskrJTsFzIiKMkwRjMDz+vIn
# 0v276BZa767hDECamndoNsG/StjoU88azybVJxEK7Ny8eF8sd3nD1EQgiHowqaHd
# Ftlfejr8tBjZ0YRCM2tSH9HjV/ZIE2RZtrX4pZOGpeY0opFQrfhxAyUGpzhpHtxx
# nrcFo5GBJOBlI+IdNfMuTvcIaYrS+DtkGjxTKTKzcqsC7kWgDZso1iFWUjVA3xWB
# wMizvkJbiwM+JqJ1MXwKNxwxYiNbo9UoR4z9srHZZphdkSCEWARzBkr/cG0svxTR
# SoGCnLoUGgvluOc8frN1
# SIG # End signature block
