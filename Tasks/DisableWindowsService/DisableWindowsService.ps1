[CmdletBinding(DefaultParameterSetName = 'None')]
Param(
    [string] [Parameter(Mandatory = $true)]
    $serviceName,
    
    [string] [Parameter(Mandatory = $true)]
    $serverName,
    
    [string] [Parameter(Mandatory = $false)]
    $deployUser,
    
    [string] [Parameter(Mandatory = $false)]
    $deployPass  
)
 
Import-Module .\CommonAuth.psm1 

$session = New-Deploy-Session -DeployUser $deployUser -DeployPass $deployPass -ServerName $serverName
 
invoke-command -session $session -scriptblock {
    Param([string]$serviceName, [string]$servicePath, [string]$serviceAccountUser, [string]$serviceAccountPass)
       
    $existingService = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"

    if ($existingService) 
    {
        "'$serviceName' exists already. Stopping."
        Stop-Service $serviceName
        "Waiting 3 seconds to allow existing service to stop."
        Start-Sleep -s 3
    } Else 
    {
        "Service does not exist."
    }    
 
} -ArgumentList $serviceName, $servicePath, $serviceAccountUser, $serviceAccountPass
 
Remove-PSSession $session





