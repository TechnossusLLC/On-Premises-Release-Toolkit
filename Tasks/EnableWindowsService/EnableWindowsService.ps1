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
    $deployPass,
    
    [string] [Parameter(Mandatory = $false)]
    $installIfNotExists,

    [string] [Parameter(Mandatory = $false)]
    $startupType,

    [string] [Parameter(Mandatory = $false)]
    $displayName,

    [string] [Parameter(Mandatory = $false)]
    $dependsOn,

    [string] [Parameter(Mandatory = $false)]
    $description
)
 
Import-Module .\CommonAuth.psm1 

$session = New-Deploy-Session -DeployUser $deployUser -DeployPass $deployPass -ServerName $serverName

invoke-command -session $session -scriptblock {
    Param([string]$serviceName, [string]$servicePath, [string]$serviceAccountUser, [string]$serviceAccountPass, [string]$startupType, [string]$displayName, [string]$dependsOn, [string]$description)

    $existingService = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"

    if($installIfNotExists -ne "false"){
        "Installing the service."

        if($existingService){
            $existingService.delete();
        }

        if($serviceAccountUser){
            "Using service account."
            
            if($serviceAccountPass)
            {
                $password = $serviceAccountPass|ConvertTo-SecureString -AsPlainText -Force
                $cred = New-Object System.Management.Automation.PSCredential($serviceAccountUser, $password)                    
            }
            else
            {
                $cred = New-Object System.Management.Automation.PSCredential($serviceAccountUser, (new-object System.Security.SecureString))                   
            }

            if($dependsOn){
                New-Service -BinaryPathName $servicePath -Name $serviceName -Credential $cred -StartupType Automatic -DependsOn $dependsOn
            } else{
                New-Service -BinaryPathName $servicePath -Name $serviceName -Credential $cred -StartupType Automatic
            }
            
            
        } else {
            if($dependsOn){
                New-Service -BinaryPathName $servicePath -Name $serviceName -StartupType Automatic -DependsOn $dependsOn
            } else{
                New-Service -BinaryPathName $servicePath -Name $serviceName -StartupType Automatic
            }
        } 
        
        "Installed the service."
    }

    if($description){
        Set-Service -Description $description
    }

    if($displayName){
        Set-Service $serviceName -DisplayName $displayName
    }

    switch($startupType){
        "automatic" { Set-Service $serviceName -StartupType Automatic }
        "none" { Set-Service $serviceName -StartupType None }
        "system" {  Set-Service $serviceName -StartupType System }
        "manual" {  Set-Service $serviceName -StartupType Manual }
        default { Set-Service $serviceName -StartupType Automatic }
        
    }
    
    "Starting the service."
    Start-Service $serviceName
    
    "Completed."
 
} -ArgumentList $serviceName, $servicePath, $serviceAccountUser, $serviceAccountPass, $startupType, $displayName, $dependsOn, $description
 
Remove-PSSession $session





