Param(
    [string]$parentName,
    [string]$name,
    [string]$path,
    [string]$deployUser,
    [string]$deployPass,
    [string]$serverName
)

. .\CommonAuth.ps1 
 
 $session = New-Deploy-Session($deployUser, $deployPass, $serverName)

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





