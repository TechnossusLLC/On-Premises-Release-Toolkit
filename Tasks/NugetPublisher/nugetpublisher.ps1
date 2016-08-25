param(
    [string]$searchPattern,
    [string]$nuGetFeedType,
    [string]$connectedServiceName,
    [string]$feedName,
    [string]$nuGetAdditionalArgs,
    [string]$nuGetPath
)

Write-Verbose "Importing modules"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

. $PSScriptRoot\VsoNuGetHelper.ps1

function GetEndpointData
{
	param([string][ValidateNotNullOrEmpty()]$connectedServiceName)

	$serviceEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $connectedServiceName

	if (!$serviceEndpoint)
	{
		throw "A Connected Service with name '$ConnectedServiceName' could not be found.  Ensure that this Connected Service was successfully provisioned using the services tab in the Admin UI."
	}

    return $serviceEndpoint
}

Write-Verbose "Entering script $MyInvocation.MyCommand.Name"
Write-Verbose "Parameter Values"
foreach($key in $PSBoundParameters.Keys)
{
    Write-Verbose ($key + ' = ' + $PSBoundParameters[$key])
}

Write-Host (Get-LocalizedString -Key "Check/Set nuget path")
if(!$nuGetPath)
{
    $nuGetPath = Get-ToolPath -Name 'NuGet.exe';
}

if (-not $nuGetPath)
{
    throw (Get-LocalizedString -Key "Unable to locate {0}" -ArgumentList 'nuget.exe')
}

#Setup Nuget
Write-Host (Get-LocalizedString -Key "Creating Nuget Arguments")

$useExternalFeed = $true
if($nuGetFeedType -and $nuGetFeedType.Equals("internal"))
{
    $useExternalFeed = $false
}

if($connectedServiceName -and $useExternalFeed)
{
    Write-Verbose "Using service endpoint URL"
    $serviceEndpoint = GetEndpointData $connectedServiceName

    Write-Verbose "serverUrl = $($serviceEndpoint.Url)"
    $nugetServer = $($serviceEndpoint.Url)

    Write-Verbose "serverApiKey = $($serviceEndpoint.Authorization.Parameters.Password)"
    $nugetServerKey = $($serviceEndpoint.Authorization.Parameters.Password)

    Write-Host (Get-LocalizedString -Key "Checking server url set")
    if (!$nugetServer)
    {
        throw "Server must be set"
    }

    Write-Host (Get-LocalizedString -Key "Checking server key set")
    if (!$nugetServerKey)
    {
        throw "Server Key must be set, set the password on the generic service"
    }
}
elseif($feedName -and (-not $useExternalFeed))
{
    Write-Verbose "Using provided feed URL"
    $nugetServer = $feedName

    #check if nuget config exists
    if(-not (Test-Path -Path $tempNuGetConfigPath))
    {
        Write-Verbose "Creating NuGet.config file"
        # Create basic NuGet config file if it doesn't exist
        [System.Xml.XmlDocument] $nuGetConfig = New-Object System.Xml.XmlDocument

        $configurationSection = $nuGetConfig.CreateElement("configuration")
        [void]$nuGetConfig.AppendChild($configurationSection)
    }
    else
    {
        Write-Verbose "Loading existing NuGet.config file"
        $nuGetConfig = [xml](Get-Content $tempNuGetConfigPath)
        $configurationSection = $nuGetConfig.configuration
    }

    $packageSourcesSection = $nuGetConfig.SelectSingleNode("configuration/packageSources")
    if($packageSourcesSection -eq $null)
    {
        Write-Verbose "Creating package sources section"
        $packageSourcesSection = $nuGetConfig.CreateElement("packageSources")
        [void]$configurationSection.AppendChild($packageSourcesSection)   
    }
    
    #check if URL in packageSources
    $nuGetSources = $nuGetConfig.SelectNodes("configuration/packageSources/add")
    $sourceExists = $false

    foreach($source in $nuGetSources)
    {
        $lowerTrimmedSource = ([string]$source.value).ToLowerInvariant().Trim('/')
        $lowerTrimmedTargetSource = $nugetServer.ToLowerInvariant().Trim('/')
        if($lowerTrimmedSource.Equals($lowerTrimmedTargetSource))
        {
            Write-Verbose "Source exists in NuGet.config file"
            $sourceExists = $true
            break
        }   
    }

    if(-not $sourceExists)
    {
        Write-Verbose "Adding source to NuGet.config file"
        $alphanumericSource = $nugetServer -replace "[^a-zA-Z0-9]", ""
        $nuGetSource = $nuGetConfig.CreateElement("add")
        $nuGetSource.SetAttribute("key", $alphanumericSource)
        $nuGetSource.SetAttribute("value", $nugetServer)
        [void]$packageSourcesSection.AppendChild($nuGetSource) 
    }

    $endpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name SystemVssConnection
    if($endpoint.Authorization.Scheme -eq 'OAuth')
    {
        Write-Host (Get-LocalizedString -Key "Getting credentials for {0}" -ArgumentList $endpoint)
        $accessToken = $endpoint.Authorization.Parameters['AccessToken']
    }
    else
    {
        Write-Warning (Get-LocalizedString -Key "Could not determine credentials to use for NuGet")
        $accessToken = ""
    }

    
    SetCredentialsNuGetConfigAndSaveTemp $nuGetConfig $accessToken $nugetServer
}
else
{
    throw ((Get-LocalizedString -Key "Verify the configuration of your NuGet feed"))
}

# check for solution pattern
if ($searchPattern.Contains("*") -or $searchPattern.Contains("?"))
{
    Write-Host (Get-LocalizedString -Key "Pattern found in solution parameter.")
    Write-Host "Find-Files -SearchPattern $searchPattern"
    $packagesToPush = Find-Files -SearchPattern $searchPattern
}
else
{
    Write-Host (Get-LocalizedString -Key "No Pattern found in solution parameter.")
    $packagesToPush = ,$searchPattern
}
 
$foundCount = $packagesToPush.Count 
Write-Host (Get-LocalizedString -Key "Found files: {0}" -ArgumentList $foundCount)
foreach ($packageFile in $packagesToPush)
{
    Write-Host (Get-LocalizedString -Key "File: {0}" -ArgumentList $packageFile)
}


foreach ($packageFile in $packagesToPush)
{
    if ($env:NUGET_EXTENSIONS_PATH)
    {
        Write-Host (Get-LocalizedString -Key "Detected NuGet extensions loader path. Environment variable NUGET_EXTENSIONS_PATH is set to: {0}" -ArgumentList $env:NUGET_EXTENSIONS_PATH)
    }

    $argsUpload = "push $packageFile -s $nugetServer"

    if($useExternalFeed)
    {
        $argsUpload = $argsUpload + " $nugetServerKey"
    }
    elseif(-not $useExternalFeed)
    {
        $argsUpload = $argsUpload + "  -configFile `"$tempNuGetConfigPath`" -apiKey VssSessionKey"
    }

    if($nuGetAdditionalArgs)
    {
        $argsUpload = ($argsUpload + " " + $nuGetAdditionalArgs);
    } 

     try{
        Write-Host (Get-LocalizedString -Key "Invoking nuget with {0} on {1}" -ArgumentList $argsUpload,$packageFile)
        Invoke-Tool -Path $nugetPath -Arguments "$argsUpload"
    } catch {
        Write-Error ($Error[0].Exception)
    }
}

   
