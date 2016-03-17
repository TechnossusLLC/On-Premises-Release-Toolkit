[CmdletBinding(DefaultParameterSetName = 'None')]
Param(
    [string] [Parameter(Mandatory = $true)]
    $serviceName,
    
    [string] [Parameter(Mandatory = $true)]
    $servicePath,
    
    [string] [Parameter(Mandatory = $false)]
    $serviceAccountUser,
    
    [string] [Parameter(Mandatory = $false)]
    $serviceAccountPass,
    
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

        $existingService.Delete()
        "Waiting 5 seconds to allow service to be uninstalled."
        Start-Sleep -s 5  
    }

    "Installing the service."
    if($serviceAccountUser){
        "Using service account."
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $serviceAccountUser, $serviceAccountPass
        New-Service -BinaryPathName $servicePath -Name $serviceName -Credential $cred -DisplayName $serviceName -StartupType Automatic
    } else {
        New-Service -BinaryPathName $servicePath -Name $serviceName -DisplayName $serviceName -StartupType Automatic
    } 
    "Installed the service."
  
    "Starting the service."
    Start-Service $serviceName
    
    "Completed."
 
} -ArgumentList $serviceName, $servicePath, $serviceAccountUser, $serviceAccountPass
 
Remove-PSSession $session





