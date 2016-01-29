Param(
    [string]$dbServerName,
    [string]$databaseName,
    [string]$dacpacLocation
)

if (! $dbServerName)
{
    Write-Host "Missing required variable dbServerName" -ForegroundColor Yellow
    exit 1
}

if (! $databaseName)
{
    Write-Host "Missing required variable databaseName" -ForegroundColor Yellow
    exit 1
}

if (! $dacpacLocation)
{
    Write-Host "Missing required variable dacpacLocation" -ForegroundColor Yellow
    exit 1
}

. .\CommonAuth.psm1

$user=[Security.Principal.WindowsIdentity]::GetCurrent()

Write-Host "Deploying as " $user.Name

add-type -path "C:\Program Files (x86)\Microsoft SQL Server\120\DAC\bin\Microsoft.SqlServer.Dac.dll"

$connectionString="Data Source=$dbServerName;Integrated Security=True;"
Write-Host $connectionString
$dacService = new-object Microsoft.SqlServer.Dac.DacServices $connectionString

register-objectevent -in $dacService -eventname Message -source "msg" -action { out-host -in $Event.SourceArgs[1].Message.Message } | Out-Null

$dp = [Microsoft.SqlServer.Dac.DacPackage]::Load($dacpacLocation)
$dacpacoptions = "C:\Drops\Powershell Scripts\dbDeployOptions.publish.xml"

Write-Host $dacpac
Write-Host $dacpacoptions

$dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($dacpacoptions)

Write-Host "Deploying database $databaseName to server $dbServerName"
try{
$dacService.deploy($dp, $databaseName, $true, $dacProfile.DeployOptions) 
} catch [Microsoft.SqlServer.Dac.DacServicesException] {
   
    Resolve-Error $_
    throw ('Deployment failed: ''{0}'' Reason: ''{1}'' ''{2}''' -f $_.Exception.Message, $_.Exception.InnerException.Message, $_.Exception.InnerException.InnerException.Message)
}
unregister-event -source "msg" 
