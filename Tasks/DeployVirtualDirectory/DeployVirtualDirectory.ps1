Param(
    [string] [Parameter(Mandatory = $true)]
    [string]$parentName,
    
    [string] [Parameter(Mandatory = $true)]
    [string]$name,
    
    [string] [Parameter(Mandatory = $true)]
    [string]$path,
    
    [string] [Parameter(Mandatory = $false)]
    [string]$deployUser,
    
    [string] [Parameter(Mandatory = $false)]
    [string]$deployPass,
    
    [string] [Parameter(Mandatory = $true)]
    [string]$serverName
)

Import-Module .\CommonAuth.psm1 
 
$session = New-Deploy-Session -DeployUser $deployUser -DeployPass $deployPass -ServerName $serverName

invoke-command -session $session -scriptblock {
    Param([string]$parentName, [string]$name, [string]$path)
 
    Set-ExecutionPolicy RemoteSigned
    
    Import-Module Servermanager 
    Write-Host "Physical Path: c:\apps\$path"
        
    # Create the directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path "c:\apps\$path" 
    
    New-WebApplication -Site $parentName -Name $name -PhysicalPath "c:\apps\$path" -ApplicationPool $parentName -force

} -ArgumentList $parentName, $name, $path
 
Remove-PSSession $session





