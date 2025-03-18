<#
.SYNOPSIS
    Acquire a token using MSAL.NET library.
.DESCRIPTION
    This command will acquire OAuth tokens for both public and confidential clients. Public clients authentication can be interactive, integrated Windows auth, or silent (aka refresh token authentication).
.EXAMPLE
    PS C:\>Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -Scope 'https://graph.microsoft.com/User.Read','https://graph.microsoft.com/Files.ReadWrite'
    Get AccessToken (with MS Graph permissions User.Read and Files.ReadWrite) and IdToken using client id from application registration (public client).
.EXAMPLE
    PS C:\>Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId '00000000-0000-0000-0000-000000000000' -Interactive -Scope 'https://graph.microsoft.com/User.Read' -LoginHint user@domain.com
    Force interactive authentication to get AccessToken (with MS Graph permissions User.Read) and IdToken for specific Azure AD tenant and UPN using client id from application registration (public client).
.EXAMPLE
    PS C:\>Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -ClientSecret (ConvertTo-SecureString 'SuperSecretString' -AsPlainText -Force) -TenantId '00000000-0000-0000-0000-000000000000' -Scope 'https://graph.microsoft.com/.default'
    Get AccessToken (with MS Graph permissions .Default) and IdToken for specific Azure AD tenant using client id and secret from application registration (confidential client).
.EXAMPLE
    PS C:\>$ClientCertificate = Get-Item Cert:\CurrentUser\My\0000000000000000000000000000000000000000
    PS C:\>$MsalClientApplication = Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -ClientCertificate $ClientCertificate -TenantId '00000000-0000-0000-0000-000000000000'
    PS C:\>$MsalClientApplication | Get-MsalToken -Scope 'https://graph.microsoft.com/.default'
    Pipe in confidential client options object to get a confidential client application using a client certificate and target a specific tenant.
#>
function Get-MsalToken {
    [CmdletBinding(DefaultParameterSetName = 'PublicClient')]
    [OutputType([Microsoft.Identity.Client.AuthenticationResult])]
    param
    (
        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Interactive', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-IntegratedWindowsAuth', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Silent', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-UsernamePassword', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-DeviceCode', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ClientId,

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [securestring] $ClientSecret,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientCertificate,

        # Specifies if the x5c claim (public key of the certificate) should be sent to the STS.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf')]
        [switch] $SendX5C,

        # The authorization code received from service authorization endpoint.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode')]
        [string] $AuthorizationCode,

        # Assertion representing the user.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [string] $UserAssertion,

        # Type of the assertion representing the user.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [string] $UserAssertionType,

        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-IntegratedWindowsAuth', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Silent', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-UsernamePassword', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-DeviceCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [uri] $RedirectUri,

        # Instance of Azure Cloud
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.AzureCloudInstance] $AzureCloudInstance,

        # Tenant identifier of the authority to issue token. It can also contain the value "consumers" or "organizations".
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $TenantId,

        # Address of the authority to issue token.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $Authority,

        # Use Platform Authentication Broker
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [switch] $AuthenticationBroker,

        # Public client application
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.IPublicClientApplication] $PublicClientApplication,

        # Confidential client application
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialClientApplication,

        # Interactive request to acquire a token for the specified scopes.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Interactive')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [switch] $Interactive,

        # Non-interactive request to acquire a security token for the signed-in user in Windows, via Integrated Windows Authentication.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-IntegratedWindowsAuth')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [switch] $IntegratedWindowsAuth,

        # Attempts to acquire an access token from the user token cache.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Silent')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [switch] $Silent,

        # Acquires a security token on a device without a Web browser, by letting the user authenticate on another device.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-DeviceCode')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [switch] $DeviceCode,

        # Array of scopes requested for resource
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]] $Scopes = 'https://graph.microsoft.com/.default',

        # Array of scopes for which a developer can request consent upfront.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [string[]] $ExtraScopesToConsent,

        # Identifier of the user. Generally a UPN.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-IntegratedWindowsAuth', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Silent', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [string] $LoginHint,

        # Specifies the what the interactive experience is for the user. To force an interactive authentication, use the -Interactive switch.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter( {
                param ( $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters )
                [Microsoft.Identity.Client.Prompt].DeclaredFields | Where-Object { $_.IsPublic -eq $true -and $_.IsStatic -eq $true -and $_.Name -like "$wordToComplete*" } | Select-Object -ExpandProperty Name
            })]
        [string] $Prompt,

        # Identifier of the user with associated password.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-UsernamePassword', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [pscredential]
        [System.Management.Automation.Credential()]
        $UserCredential,

        # Correlation id to be used in the authentication request.
        [Parameter(Mandatory = $false)]
        [guid] $CorrelationId,

        # This parameter will be appended as is to the query string in the HTTP authentication request to the authority.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [hashtable] $ExtraQueryParameters,

        # Modifies the token acquisition request so that the acquired token is a Proof of Possession token (PoP), rather than a Bearer token.
        [Parameter(Mandatory = $false)]
        [System.Net.Http.HttpRequestMessage] $ProofOfPossession,

        # Ignore any access token in the user token cache and attempt to acquire new access token using the refresh token for the account if one is available.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Silent')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject')]
        [switch] $ForceRefresh,

        # Specifies if the public client application should used an embedded web browser or the system default browser
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [switch] $UseEmbeddedWebView,

        # Specifies the timeout threshold for MSAL.net operations.
        [Parameter(Mandatory = $false)]
        [timespan] $Timeout
    )

    begin {
        function CheckForMissingScopes([Microsoft.Identity.Client.AuthenticationResult]$AuthenticationResult, [string[]]$Scopes) {
            foreach ($Scope in $Scopes) {
                if ($AuthenticationResult.Scopes -notcontains $Scope) { return $true }
            }
            return $false
        }

        function Coalesce([psobject[]]$objects) { foreach ($object in $objects) { if ($object -notin $null, [string]::Empty) { return $object } } return $null }
    }

    process {
        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            "PublicClient-InputObject" {
                [Microsoft.Identity.Client.IPublicClientApplication] $ClientApplication = $PublicClientApplication
                break
            }
            "ConfidentialClient-InputObject" {
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = $ConfidentialClientApplication
                break
            }
            "PublicClient*" {
                $paramSelectMsalClientApplication = Select-PsBoundParameters $PSBoundParameters -CommandName Select-MsalClientApplication -CommandParameterSets "PublicClient"
                [Microsoft.Identity.Client.IPublicClientApplication] $PublicClientApplication = Select-MsalClientApplication @paramSelectMsalClientApplication
                [Microsoft.Identity.Client.IPublicClientApplication] $ClientApplication = $PublicClientApplication
                break
            }
            "ConfidentialClientSecret*" {
                $paramSelectMsalClientApplication = Select-PsBoundParameters $PSBoundParameters -CommandName Select-MsalClientApplication -CommandParameterSets "ConfidentialClientSecret"
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialClientApplication = Select-MsalClientApplication @paramSelectMsalClientApplication
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = $ConfidentialClientApplication
                break
            }
            "ConfidentialClientCertificate*" {
                $paramSelectMsalClientApplication = Select-PsBoundParameters $PSBoundParameters -CommandName Select-MsalClientApplication -CommandParameterSets "ConfidentialClientCertificate"
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialClientApplication = Select-MsalClientApplication @paramSelectMsalClientApplication
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = $ConfidentialClientApplication
                break
            }
        }

        [Microsoft.Identity.Client.AuthenticationResult] $AuthenticationResult = $null
        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            "PublicClient*" {
                if ($PSBoundParameters.ContainsKey("UserCredential") -and $UserCredential) {
                    $AquireTokenParameters = $PublicClientApplication.AcquireTokenByUsernamePassword($Scopes, $UserCredential.UserName, $UserCredential.Password)
                }
                elseif ($PSBoundParameters.ContainsKey("DeviceCode") -and $DeviceCode -or ($Interactive -and !$script:ModuleFeatureSupport.WebView1Support -and !$script:ModuleFeatureSupport.WebView2Support -and $PublicClientApplication.AppConfig.RedirectUri -ne 'http://localhost') -or ($Interactive -and !$script:ModuleFeatureSupport.WebView1Support -and $PublicClientApplication.AppConfig.RedirectUri -eq 'urn:ietf:wg:oauth:2.0:oob')) {
                    $AquireTokenParameters = $PublicClientApplication.AcquireTokenWithDeviceCode($Scopes, [DeviceCodeHelper]::GetDeviceCodeResultCallback())
                }
                elseif ($PSBoundParameters.ContainsKey("Interactive") -and $Interactive) {
                    $AquireTokenParameters = $PublicClientApplication.AcquireTokenInteractive($Scopes)
                    [IntPtr] $ParentWindow = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
                    if ($ParentWindow -eq [System.IntPtr]::Zero -and [System.Environment]::OSVersion.Platform -eq 'Win32NT') {
                        $Win32Process = Get-CimInstance Win32_Process -Filter ("ProcessId = '{0}'" -f [System.Diagnostics.Process]::GetCurrentProcess().Id) -Verbose:$false
                        $ParentWindow = (Get-Process -Id $Win32Process.ParentProcessId).MainWindowHandle
                    }
                    if ($ParentWindow -ne [System.IntPtr]::Zero) { [void] $AquireTokenParameters.WithParentActivityOrWindow($ParentWindow) }
                    #if ($Account) { [void] $AquireTokenParameters.WithAccount($Account) }
                    if ($extraScopesToConsent) { [void] $AquireTokenParameters.WithExtraScopesToConsent($extraScopesToConsent) }
                    if ($LoginHint) { [void] $AquireTokenParameters.WithLoginHint($LoginHint) }
                    if ($Prompt) { [void] $AquireTokenParameters.WithPrompt([Microsoft.Identity.Client.Prompt]::$Prompt) }
                    if ($PSBoundParameters.ContainsKey('UseEmbeddedWebView')) { [void] $AquireTokenParameters.WithUseEmbeddedWebView($UseEmbeddedWebView) }
                    if (!$Timeout -and (($PSBoundParameters.ContainsKey('UseEmbeddedWebView') -and !$UseEmbeddedWebView) -or $PSVersionTable.PSEdition -eq 'Core')) {
                        $Timeout = New-TimeSpan -Minutes 2
                    }
                }
                elseif ($PSBoundParameters.ContainsKey("IntegratedWindowsAuth") -and $IntegratedWindowsAuth) {
                    $AquireTokenParameters = $PublicClientApplication.AcquireTokenByIntegratedWindowsAuth($Scopes)
                    if ($LoginHint) { [void] $AquireTokenParameters.WithUsername($LoginHint) }
                }
                elseif ($PSBoundParameters.ContainsKey("Silent") -and $Silent) {
                    if ($LoginHint) {
                        $AquireTokenParameters = $PublicClientApplication.AcquireTokenSilent($Scopes, $LoginHint)
                    }
                    else {
                        [Microsoft.Identity.Client.IAccount] $Account = $PublicClientApplication.GetAccountsAsync().GetAwaiter().GetResult() | Select-Object -First 1
                        $AquireTokenParameters = $PublicClientApplication.AcquireTokenSilent($Scopes, $Account)
                    }
                    if ($PSBoundParameters.ContainsKey('ForceRefresh')) { [void] $AquireTokenParameters.WithForceRefresh($ForceRefresh) }
                }
                else {
                    $paramGetMsalToken = Select-PsBoundParameters -NamedParameter $PSBoundParameters -CommandName 'Get-MsalToken' -CommandParameterSet 'PublicClient-InputObject' -ExcludeParameters 'PublicClientApplication'
                    ## Try Silent Authentication
                    Write-Verbose ('Attempting Silent Authentication to Application with ClientId [{0}]' -f $ClientApplication.ClientId)
                    try {
                        $AuthenticationResult = Get-MsalToken -Silent -PublicClientApplication $PublicClientApplication @paramGetMsalToken
                        ## Check for requested scopes
                        if (CheckForMissingScopes $AuthenticationResult $Scopes) {
                            $AuthenticationResult = Get-MsalToken -Interactive -PublicClientApplication $PublicClientApplication @paramGetMsalToken
                        }
                    }
                    catch [Microsoft.Identity.Client.MsalUiRequiredException] {
                        Write-Debug ('{0}: {1}' -f $_.Exception.GetType().Name, $_.Exception.Message)
                        ## Try Integrated Windows Authentication
                        Write-Verbose ('Attempting Integrated Windows Authentication to Application with ClientId [{0}]' -f $ClientApplication.ClientId)
                        try {
                            $AuthenticationResult = Get-MsalToken -IntegratedWindowsAuth -PublicClientApplication $PublicClientApplication @paramGetMsalToken
                            ## Check for requested scopes
                            if (CheckForMissingScopes $AuthenticationResult $Scopes) {
                                $AuthenticationResult = Get-MsalToken -Interactive -PublicClientApplication $PublicClientApplication @paramGetMsalToken
                            }
                        }
                        catch {
                            Write-Debug ('{0}: {1}' -f $_.Exception.GetType().Name, $_.Exception.Message)
                            ## Revert to Interactive Authentication
                            Write-Verbose ('Attempting Interactive Authentication to Application with ClientId [{0}]' -f $ClientApplication.ClientId)
                            $AuthenticationResult = Get-MsalToken -Interactive -PublicClientApplication $PublicClientApplication @paramGetMsalToken
                        }
                    }
                    break
                }
            }
            "ConfidentialClient*" {
                if ($PSBoundParameters.ContainsKey("AuthorizationCode")) {
                    $AquireTokenParameters = $ConfidentialClientApplication.AcquireTokenByAuthorizationCode($Scopes, $AuthorizationCode)
                }
                elseif ($PSBoundParameters.ContainsKey("UserAssertion")) {
                    if ($UserAssertionType) { [Microsoft.Identity.Client.UserAssertion] $UserAssertionObj = New-Object Microsoft.Identity.Client.UserAssertion -ArgumentList $UserAssertion, $UserAssertionType }
                    else { [Microsoft.Identity.Client.UserAssertion] $UserAssertionObj = New-Object Microsoft.Identity.Client.UserAssertion -ArgumentList $UserAssertion }
                    $AquireTokenParameters = $ConfidentialClientApplication.AcquireTokenOnBehalfOf($Scopes, $UserAssertionObj)
                }
                else {
                    $AquireTokenParameters = $ConfidentialClientApplication.AcquireTokenForClient($Scopes)
                    if ($PSBoundParameters.ContainsKey('ForceRefresh')) { [void] $AquireTokenParameters.WithForceRefresh($ForceRefresh) }
                }
                if ($SendX5C) { [void] $AquireTokenParameters.WithSendX5C($SendX5C) }
            }
            "*" {
                if ($AzureCloudInstance -and $TenantId) { [void] $AquireTokenParameters.WithAuthority($AzureCloudInstance, $TenantId) }
                elseif ($AzureCloudInstance) { [void] $AquireTokenParameters.WithAuthority($AzureCloudInstance, 'common') }
                elseif ($TenantId) { [void] $AquireTokenParameters.WithAuthority(('https://{0}' -f $ClientApplication.AppConfig.Authority.AuthorityInfo.Host), $TenantId) }
                if ($Authority) { [void] $AquireTokenParameters.WithAuthority($Authority.AbsoluteUri) }
                if ($CorrelationId) { [void] $AquireTokenParameters.WithCorrelationId($CorrelationId) }
                if ($ExtraQueryParameters) { [void] $AquireTokenParameters.WithExtraQueryParameters((ConvertTo-Dictionary $ExtraQueryParameters -KeyType ([string]) -ValueType ([string]))) }
                if ($ProofOfPossession) { [void] $AquireTokenParameters.WithProofOfPosession($ProofOfPossession) }
                Write-Debug ('Aquiring Token for Application with ClientId [{0}]' -f $ClientApplication.ClientId)
                if (!$Timeout) { $Timeout = [timespan]::Zero }

                ## Wait for async task to complete
                $tokenSource = New-Object System.Threading.CancellationTokenSource
                try {
                    #$AuthenticationResult = $AquireTokenParameters.ExecuteAsync().GetAwaiter().GetResult()
                    $taskAuthenticationResult = $AquireTokenParameters.ExecuteAsync($tokenSource.Token)
                    try {
                        $endTime = [datetime]::Now.Add($Timeout)
                        while (!$taskAuthenticationResult.IsCompleted) {
                            if ($Timeout -eq [timespan]::Zero -or [datetime]::Now -lt $endTime) {
                                Start-Sleep -Seconds 1
                            }
                            else {
                                $tokenSource.Cancel()
                                try { $taskAuthenticationResult.Wait() }
                                catch { }
                                Write-Error -Exception (New-Object System.TimeoutException) -Category ([System.Management.Automation.ErrorCategory]::OperationTimeout) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureOperationTimeout' -TargetObject $AquireTokenParameters -ErrorAction Stop
                            }
                        }
                    }
                    finally {
                        if (!$taskAuthenticationResult.IsCompleted) {
                            Write-Debug ('Canceling Token Acquisition for Application with ClientId [{0}]' -f $ClientApplication.ClientId)
                            $tokenSource.Cancel()
                        }
                        $tokenSource.Dispose()
                    }

                    ## Parse task results
                    if ($taskAuthenticationResult.IsFaulted) {
                        Write-Error -Exception $taskAuthenticationResult.Exception -Category ([System.Management.Automation.ErrorCategory]::AuthenticationError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureAuthenticationError' -TargetObject $AquireTokenParameters -ErrorAction Stop
                    }
                    if ($taskAuthenticationResult.IsCanceled) {
                        Write-Error -Exception (New-Object System.Threading.Tasks.TaskCanceledException $taskAuthenticationResult) -Category ([System.Management.Automation.ErrorCategory]::OperationStopped) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureOperationStopped' -TargetObject $AquireTokenParameters -ErrorAction Stop
                    }
                    else {
                        $AuthenticationResult = $taskAuthenticationResult.Result
                    }
                }
                catch {
                    Write-Error -Exception (Coalesce $_.Exception.InnerException,$_.Exception) -Category ([System.Management.Automation.ErrorCategory]::AuthenticationError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'GetMsalTokenFailureAuthenticationError' -TargetObject $AquireTokenParameters -ErrorAction Stop
                }
                break
            }
        }

        return $AuthenticationResult
    }
}

# SIG # Begin signature block
# MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBn3hFm+jQLrbIY
# yrTfo3gnwpxOgzZiKNnCcEa1g5V0UqCCIS4wggWNMIIEdaADAgECAhAOmxiO+dAt
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBkxJK6eqwKW
# QzI0YLCm5Ao5wD6/pv9IkVlxAaJxWGxiMA0GCSqGSIb3DQEBAQUABIICAAKOY+wq
# E9AbBkryAVXpZIcXothsyVISt9gJogsbIWr0PL0z2Z4cuwL/BbSkymKM96PbalLK
# 5HkbVETtXukbOHdLjK/WFiNNovHWcgCCDt6C5g9Y20QxrCIUeM4APLgAlgeWQRg4
# Zff94mNiP6RyAT2vKjuEIi9rCOMMPg3MvVA9dWXXD3kmqQ6ilI0eSKQCf5mdeWjF
# yIko0H8lSLaBedsD1TC72KAidmbcnFUeJvkxytujemBKv0iFumCDm92VevNWeDZW
# IqwXUQwOfMaRRR4SFmBG8s19T4Q1YNxn+Eilu9LR6EW44kgQ9Pqg0uFNNisBCrIE
# cdHJSFUI5lVJUwcaUUrcNpbiurg6/mSSDLRbhRUczDNxdq59jZIZyHPtHSAkOG4w
# US4DexVcUx/TUFuYDiNL8/xNUhxQ3O1ZTGELEwlc+gx5ssCN4LfeqXiYcF34R4gi
# xOQF5xgduzV9xk4JOcGHovLaMP7cxTR4YSg8Pw39UE7wDmC/ahOt9+KsBuDBiYcz
# kGmCP4CF4NuZm/rmyr2Leyha2DiiwzcAGuxHfXVVMynXUX2Af0KZ9v0Sj2G7ptkG
# BItXL9haGXblCBxAe9eDHDTtjU68h/uoPE98LGi/UQHvZQv+AjLwYCLhoakcawQK
# 7dKPfAEtNOQfEh4iUXN/kGkdurqsDvWId9IOoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0
# MDUzMDA2MzI0NVowLwYJKoZIhvcNAQkEMSIEIM4bfdbGXfx4iPv901UgJqUxEJ0n
# jlsoS/zu3VPV25h5MA0GCSqGSIb3DQEBAQUABIICAH/uEDJR1YIrENULsbYlS3C3
# zqyKPhjSy1tAjuQKq2Tzx4tyJczWYTbUX5Zab5m/B6PoSNMI9joCAFev1IQRg7fv
# 88gQKtNhoXZE2wG5ich1pymAVEU1u6OosWXY8Hf/EG8qfk8QiThMe/qPr9jDXur9
# 7MUBnOWvJSRJDenfFYpvIpozQOjg91ADbrDEy8okqUDbrvmntriSm8j73XCRaUva
# PhbNAzIuzJpgynRvYgI464Il3LwzEpQI1HlwPlq+LsnJvzc5ZXw7XZkRCsdo7fb4
# bGHR/hY9HV38gA6R0qFt3w+a7ojCUYFlVHvyvGvHAA0KjGWuw7Erig4+D651FV1L
# UknRXllF68FjXU0Stq3ycdhptExwAhQpNqqcv/IH/t257ycK57uyOKMCxM+qLyb5
# 88O+EOBQ1TLw4gxO49FhTtwQyN33Cwd9ZDR1iJLpiru0vumz/BsI2JIlxFv2j1OR
# EYdqVoNbzdI2OHtJcc6mrVDhgCZLlntkNWn1V/dTOXnJjBzmIHd2eT7DlX2bklNp
# FVLvSWHiwctnC/pJ5sKAqHbb/S9f7miNAXXK1HJB7lkGtHnytSTGqJQhJ2zflQgM
# TCGF3/cLyDs0tZ7c/+ucvuPo+/4aK8l6iPYH/DtfefADVyTfxjXuznYKQ1x102de
# BTAuZ0thRQtoY/QW4Ubr
# SIG # End signature block
