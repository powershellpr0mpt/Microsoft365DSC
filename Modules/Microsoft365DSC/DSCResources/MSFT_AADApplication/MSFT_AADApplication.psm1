function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.Boolean]
        $AvailableToOtherTenants,

        [Parameter()]
        [System.String]
        $GroupMembershipClaims,

        [Parameter()]
        [System.String]
        $Homepage,

        [Parameter()]
        [System.String[]]
        $IdentifierUris,

        [Parameter()]
        [System.String]
        $LogoutURL,

        [Parameter()]
        [System.String[]]
        $KnownClientApplications,

        [Parameter()]
        [System.Boolean]
        $Oauth2AllowImplicitFlow,

        [Parameter()]
        [System.Boolean]
        $Oauth2AllowUrlPathMatching,

        [Parameter()]
        [System.Boolean]
        $Oauth2RequirePostResponse,

        [Parameter()]
        [System.Boolean]
        $PublicClient,

        [Parameter()]
        [System.String[]]
        $ReplyURLs,

        [Parameter()]
        [System.String]
        $SamlMetadataUrl,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Getting configuration of Azure AD Application"
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Platform 'AzureAD' -InboundParameters $PSBoundParameters

    $AADApp = Get-AzureADApplication -Filter "DisplayName eq '$($DisplayName)'"
    if($AADApp.Count -gt 1)
    {
        Write-Error -Message "Multiple AAD Apps with the Displayname $($DisplayName) exist in the tenant. Aborting."
    }
    if($null -eq $AADApp)
    {
        $currentValues = $PSBoundParameters
        $currentValues.Ensure = "Absent"
        return $currentValues
    }
    else
    {
        $result = @{
            DisplayName                   = $AADApp.DisplayName
            AvailableToOtherTenants       = $AADApp.AvailableToOtherTenants
            GroupMembershipClaims         = $AADApp.GroupMembershipClaims
            Homepage                      = $AADApp.Homepage
            IdentifierUris                = $AADApp.IdentifierUris
            KnownClientApplications       = $AADApp.KnownClientApplications
            LogoutURL                     = $AADApp.LogoutURL
            Oauth2AllowImplicitFlow       = $AADApp.Oauth2AllowImplicitFlow
            Oauth2AllowUrlPathMatching    = $AADApp.Oauth2AllowUrlPathMatching
            Oauth2RequirePostResponse     = $AADApp.Oauth2RequirePostResponse
            PublicClient                  = $AADApp.PublicClient
            ReplyURLs                     = $AADApp.ReplyURLs
            SamlMetadataUrl               = $AADApp.SamlMetadataUrl
            ObjectId                      = $AADApp.ObjectID
            Ensure                        = "Present"
            GlobalAdminAccount            = $GlobalAdminAccount
            ApplicationId                 = $ApplicationId
            TenantId                      = $TenantId
            CertificateThumbprint         = $CertificateThumbprint
        }
        Write-Verbose -Message "Get-TargetResource Result: `n $(Convert-M365DscHashtableToString -Hashtable $result)"
        return $result
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.Boolean]
        $AvailableToOtherTenants,

        [Parameter()]
        [System.String]
        $GroupMembershipClaims,

        [Parameter()]
        [System.String]
        $Homepage,

        [Parameter()]
        [System.String[]]
        $IdentifierUris,

        [Parameter()]
        [System.String[]]
        $KnownClientApplications,

        [Parameter()]
        [System.String]
        $LogoutURL,

        [Parameter()]
        [System.Boolean]
        $Oauth2AllowImplicitFlow,

        [Parameter()]
        [System.Boolean]
        $Oauth2AllowUrlPathMatching,

        [Parameter()]
        [System.Boolean]
        $Oauth2RequirePostResponse,

        [Parameter()]
        [System.Boolean]
        $PublicClient,

        [Parameter()]
        [System.String[]]
        $ReplyURLs,

        [Parameter()]
        [System.String]
        $SamlMetadataUrl,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Setting configuration of Azure AD Application"
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentAADApp = Get-TargetResource @PSBoundParameters
    $currentParameters = $PSBoundParameters
    $currentParameters.Remove("ApplicationId")
    $currentParameters.Remove("TenantId")
    $currentParameters.Remove("CertificateThumbprint")
    $currentParameters.Remove("GlobalAdminAccount")
    $currentParameters.Remove("Ensure")

    if($null -ne $KnownClientApplications)
    {
        Write-Verbose -Message "Checking if the known client applications already exist."
        $testedKnownClientApplications = New-Object System.Collections.Generic.List[string]
        foreach($KnownClientApplication in $KnownClientApplications)
        {
            $knownAADApp = $null
            $knownAADApp = Get-AzureADApplication -Filter "AppID eq '$($KnownClientApplication)'"
            if($null -ne $knownAADApp)
            {
                $testedKnownClientApplications.Add($knownAADApp.AppId)
            }
            else
            {
                Write-Verbose -Message "Could not find an existing app with the app ID $($KnownClientApplication)"
            }
        }
        $currentParameters.Remove("KnownClientApplications")
        $currentParameters.Add("KnownClientApplications", $testedKnownClientApplications)
    }

    # App should exist but it doesn't
    if ($Ensure -eq "Present" -and $currentAADApp.Ensure -eq "Absent")
    {
        New-AzureADApplication @currentParameters
    }
    # App should exist and will be configured to desired state
    if ($Ensure -eq 'Present' -and $currentAADApp.Ensure -eq 'Present')
    {
        Set-AzureADApplication -ObjectID $currentAADApp.ObjectID @currentParameters
    }
    # App exists but should not
    elseif ($Ensure -eq 'Absent' -and $currentAADApp.Ensure -eq 'Present')
    {
        Remove-AzureADApplication -ObjectId $currentAADApp.ObjectID
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.Boolean]
        $AvailableToOtherTenants,

        [Parameter()]
        [System.String]
        $GroupMembershipClaims,

        [Parameter()]
        [System.String]
        $Homepage,

        [Parameter()]
        [System.String[]]
        $IdentifierUris,

        [Parameter()]
        [System.String[]]
        $KnownClientApplications,

        [Parameter()]
        [System.String]
        $LogoutURL,

        [Parameter()]
        [System.Boolean]
        $Oauth2AllowImplicitFlow,

        [Parameter()]
        [System.Boolean]
        $Oauth2AllowUrlPathMatching,

        [Parameter()]
        [System.Boolean]
        $Oauth2RequirePostResponse,

        [Parameter()]
        [System.Boolean]
        $PublicClient,

        [Parameter()]
        [System.String[]]
        $ReplyURLs,

        [Parameter()]
        [System.String]
        $SamlMetadataUrl,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Testing configuration of AzureAD Application"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = $PSBoundParameters
    $ValuesToCheck.Remove('GlobalAdminAccount') | Out-Null

    $TestResult = Test-Microsoft365DSCParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $ValuesToCheck.Keys

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )
    $InformationPreference = 'Continue'
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $content = ''
    $ConnectionMode = New-M365DSCConnection -Platform 'AzureAD' -InboundParameters $PSBoundParameters
    if ($ConnectionMode -eq 'ServicePrincipal')
    {
        $params = @{
            ApplicationId          = $ApplicationId
            TenantId               = $TenantId
            CertificateThumbprint  = $CertificateThumbprint
        }
    }
    else
    {
        $params = @{
            GlobalAdminAccount = $GlobalAdminAccount
            IsSingleInstance   = 'Yes'
        }
    }

    $result = Get-TargetResource @params

    if ($result.Ensure -eq 'Present')
    {
        if ($ConnectionMode -eq 'Credential')
        {
            $result.GlobalAdminAccount = Resolve-Credentials -UserName "globaladmin"
            $result.Remove("ApplicationId") | Out-Null
            $result.Remove("TenantId") | Out-Null
            $result.Remove("CertificateThumbprint") | Out-Null
        }
        else
        {
            $result.Remove("GlobalAdminAccount") | Out-Null
        }
        $content += "        AADApplication " + (New-GUID).ToString() + "`r`n"
        $content += "        {`r`n"
        $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
        if ($ConnectionMode -eq 'Credential')
        {
            $content += Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "GlobalAdminAccount"
        }
        else
        {
            $content += $currentDSCBlock
        }
        $content += "        }`r`n"
    }

    return $content
}

Export-ModuleMember -Function *-TargetResource
