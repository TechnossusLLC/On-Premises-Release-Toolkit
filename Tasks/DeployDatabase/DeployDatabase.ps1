Param(
    [string] [Parameter(Mandatory = $true)]
    $dbServerName,
    
    [string] [Parameter(Mandatory = $true)]
    $databaseName,
    
    [string] [Parameter(Mandatory = $true)]
    $dacpacLocation,
    
    [string] [Parameter(Mandatory = $false)]
    $additionalVariables,
    
    [string] [Parameter(Mandatory = $false)]
    $allowIncompatiblePlatform,
    
    [string] [Parameter(Mandatory = $false)]
    $backupDatabaseBeforeChanges,
    
    [string] [Parameter(Mandatory = $false)]
    $blockOnPossibleDataLoss,
    
    [string] [Parameter(Mandatory = $false)]
    $createNewDatabase,
    
    [string] [Parameter(Mandatory = $false)]
    $deployDatabaseInSingleUserMode,
    
    [string] [Parameter(Mandatory = $false)]
    $generateSmartDefaults,

    [string] [Parameter(Mandatory = $false)]
    $specifyConfiguration,

    [string] [Parameter(Mandatory = $false)]
    $configLocation
)

if (! $dbServerName)
{
    Write-Host "Missing required variable dbServerName" -ForegroundColor Red
    exit 1
}

if (! $databaseName)
{
    Write-Host "Missing required variable databaseName" -ForegroundColor Red
    exit 1
}

if (! $dacpacLocation)
{
    Write-Host "Missing required variable dacpacLocation" -ForegroundColor Red
    exit 1
}

Function Add-SqlCommandVariables($VariableDictionary,$KeyValuePairString){
    $varArray = $KeyValuePairString.Split(":");
    
    $key = $varArray[0].Replace("`"","").Replace("'","")
    $value = $varArray[1].Replace("`"","").Replace("'","")
    Write-Host "Processing Key: $key" 
    
    $VariableDictionary.Add($key, $value);
}

Import-Module .\CommonAuth.psm1

$user=[Security.Principal.WindowsIdentity]::GetCurrent()

Write-Host "Deploying as " $user.Name

add-type -path "C:\Program Files (x86)\Microsoft SQL Server\120\DAC\bin\Microsoft.SqlServer.Dac.dll"

$connectionString="Data Source=$dbServerName;Integrated Security=True;"
Write-Host $connectionString
$dacService = new-object Microsoft.SqlServer.Dac.DacServices $connectionString

register-objectevent -in $dacService -eventname Message -source "msg" -action { out-host -in $Event.SourceArgs[1].Message.Message } | Out-Null

$dp = [Microsoft.SqlServer.Dac.DacPackage]::Load($dacpacLocation, [Microsoft.SqlServer.Dac.DacSchemaModelStorageType]::File)

Write-Host "Configuration Specified: $specifyConfiguration"

# Check if we are building our own options or running a config file.
if ($specifyConfiguration -ne "true")
{
    $deployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions

    # Allow Incompatible Platform
    If($allowIncompatiblePlatform -eq "true"){
        $deployOptions.AllowIncompatiblePlatform = $true
    }

    # Backup Database Before Changes
    If($backupDatabaseBeforeChanges -eq "true"){
        $deployOptions.BackupDatabaseBeforeChanges = $true
    }

    # Block On Possible Data Loss
    If($blockOnPossibleDataLoss -eq "true"){
        $deployOptions.BlockOnPossibleDataLoss = $true
    } Else {
        $deployOptions.BlockOnPossibleDataLoss = $false
    }

    # Create New Database
    If($createNewDatabase -eq "true"){
        $deployOptions.CreateNewDatabase = $true
    }

    # Deploy Database In Single User Mode
    If($deployDatabaseInSingleUserMode -eq "true"){
        $deployOptions.DeployDatabaseInSingleUserMode = $true
    }

    # Generate Smart Defaults
    If($generateSmartDefaults -eq "true"){
        $deployOptions.GenerateSmartDefaults = $true
    }
} else {
    $dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($configLocation)

    $deployOptions=$dacProfile.DeployOptions
}

if($additionalVariables){
    If($additionalVariables -like '*,*'){	
        $additionalVariables.Split(",") | ForEach {
            Add-SqlCommandVariables -KeyValuePairString $_ -VariableDictionary $deployOptions.SqlCommandVariableValues
        }
    } ElseIf($additionalVariables -like '*:*'){
            Add-SqlCommandVariables -KeyValuePairString $additionalVariables -VariableDictionary $deployOptions.SqlCommandVariableValues
    }    
}

Write-Host "Deploying database $databaseName to server $dbServerName"
try{
$dacService.deploy($dp, $databaseName, $true, $deployOptions) 
} catch [Microsoft.SqlServer.Dac.DacServicesException] {
   
    Resolve-Error -Error $_
    throw ('Deployment failed: ''{0}'' Reason: ''{1}'' ''{2}''' -f $_.Exception.Message, $_.Exception.InnerException.Message, $_.Exception.InnerException.InnerException.Message)
}
unregister-event -source "msg" 
